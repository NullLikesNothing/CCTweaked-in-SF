--@name ComputerCraft pre-bios
--@author Lumi

-- This sets up the environment to allow `bios.lua` to boot.

local setmetatable = setmetatable
local ss = bit.stringstream
local spt = string.split
local s_bw = string.startWith
local t_cpy, t_gk = table.copy, table.getKeys
local tostring = tostring
local print = print
local type = type
local error = error
local loadstring = loadstring
local assert = assert
local t_concat = table.concat
local select = select

local function mkdir()
    return {
        t = "d",
        f = {},
    }
end

local scripts = ...

function require( a )
    local d = scripts["libs/" .. tostring( a ) .. ".lua"]
    if d then
        return assert( loadstring( d, "libs/" .. tostring( a ) .. ".lua" ) )() or true
    end
    error( "lib " .. tostring( a ) .. " not found!" )
end

local function doStub( name, ... )
    local d = scripts["stubs/" .. tostring( name ) .. ".lua"]
    if d then
        return assert( loadstring( d, "stubs/" .. tostring( name ) .. ".lua" ) )( ... ) or true
    end
    error( "stub " .. tostring( name ) .. " is missing!" )
end

doStub( "simple_fixes" )

local reqexpect = require( "expect" )
local expect = reqexpect.expect
local field = reqexpect.field

require( "colors" )

local clrs = {}
clrs["0"] = Color( 240, 240, 240 )
clrs["1"] = Color( 242, 178, 51 )
clrs["2"] = Color( 229, 127, 216 )
clrs["3"] = Color( 153, 178, 242 )
clrs["4"] = Color( 222, 222, 108 )
clrs["5"] = Color( 127, 204, 25  )
clrs["6"] = Color( 242, 178, 204 )
clrs["7"] = Color( 76, 76, 76  )
clrs["8"] = Color( 153, 153, 153 )
clrs["9"] = Color( 76, 153, 178 )

clrs["a"] = Color( 178, 102, 229 )
clrs["b"] = Color( 51, 102, 204 )
clrs["c"] = Color( 127, 102, 76 )
clrs["d"] = Color( 87, 166, 78 )
clrs["e"] = Color( 204, 76, 76 )
clrs["f"] = Color( 17, 17, 17 )

local nativeClrs = table.copy( clrs )

local color_hex_lookup = {}
for i = 0, 15 do
    color_hex_lookup[2 ^ i] = string.format("%x", i)
end
local function toBlit(color)
    expect(1, color, "number")
    return color_hex_lookup[color] or string.format("%x", math.floor(math.log(color, 2)))
end

local term = {}
function term.getPaletteColor( clr )
    expect( 1, clr, "number" )
    local c = clrs[toBlit( clr )]
    return c.r / 255, c.g / 255, c.b / 255
end
term.getPaletteColour = term.getPaletteColor

function term.setPaletteColor( clr, r, g, b )
    expect( 1, clr, "number" )
    expect( 2, r, "number" )
    expect( 3, g, "number", "nil" )
    expect( 4, b, "number", "nil" )

    local c = clrs[toBlit( clr )]

    if g == nil and b == nil then
        local rgb = r
        r = band( rshift( rgb, 16 ), 0xFF ) / 255
        g = band( rshift( rgb, 8 ), 0xFF ) / 255
        b = band( rgb, 0xFF ) / 255
    end
    c.r = r * 255
    c.g = g * 255
    c.b = b * 255

    h_run( "CC:T.GUI.PALETTE_CHANGE", toBlit( clr ), c, clrs )
end
term.setPaletteColour = term.setPaletteColor

function term.nativePaletteColor( clr )
    expect( 1, clr, "number" )
    local c = nativeClrs[toBlit( clr )]
    return c.r / 255, c.g / 255, c.b / 255
end
term.nativePaletteColour = term.nativePaletteColor
function term.native()
    return term
end
setmetatable( colors, { __index = function( _, key )
    print( "colors.__index", key )
end } )
_G.term = term

local framebuffer = require( "framebuffer" )
term = framebuffer.buffer( framebuffer.empty( true, 51, 19 ) )

local fsys = { t = "d", f = {} }
local function recursive_mkdir( pth )
    local ks = spt( pth, "/" )
    local last = fsys
    for i = 1, #ks do
        local v = ks[i]
        if not last.f[v] then
            last.f[v] = mkdir()
            if i == #ks then
                last.f[v].t = "f"
                last.f[v].f = nil
            end
        end
        last = last.f[v]
    end
end

for k, v in pairs( scripts ) do
    if k:startWith( "rom/" ) then
        recursive_mkdir( k )
        local ks = spt( k, "/" )
        local last = fsys
        for i = 1, #ks - 1 do
            if not last.f[ks[i]] then
                return
            end
            last = last.f[ks[i]]
        end

        last.f[ks[#ks]] = { d = v, t = "f" }
    end
end

_G.fs = doStub( "fs", fsys )
_G.settings = doStub( "settings" )

_G.bit32 = bit
_G.term = term
term.native = function() return term end
_G.PRINT = print

local h_run = hook.run
local band = bit.band
local rshift = bit.rshift

_G.rs = doStub( "redstone" )
_G.redstone = _G.rs

_G.peripheral = doStub( "peripheral" )

table.unpack = unpack
function table.pack( ... )
    local t = { ... }
    t.n = select( "#", ... )
    return t
end

function _G.loadstring( chunk, id, env )
    if type( id ) == "table" and env == nil then
        id, env = nil, id
    end
    if not env then
        env = _G
    end
    env._ENV = env
    return loadstring( chunk, id, env )
end
local mod_ldst = _G.loadstring
function _G.load( chunk, id, _, env )
    return mod_ldst( chunk, id, env )
end

local pcall = pcall
local c_res = coroutine.resume
local c_cre = coroutine.create
local c_yie = coroutine.yield
local c_sta = coroutine.status

function coroutine.resume( ... )
    return pcall( c_res, ... )
end


local evQueue = {}
function os.queueEvent( ... )
    local t = { ... }
    t.n = select( "#", ... )
    evQueue[#evQueue + 1] = t
end

function os.shutdown()
    h_run( "CC:T.SHUTDOWN", false )
    h_run( "CC:T.STATUS", false, "os.shutdown()" )
end

local t_sim = timer.simple
function os.reboot()
    h_run( "CC:T.SHUTDOWN", true )
    h_run( "CC:T.STATUS", false, "os.reboot()" )
    if h_run( "CC:T.BLOCK_REBOOT" ) == true then return end

    t_sim( 0.5, function()
        h_run( "CC:T.STATUS", true, "BOOT" )
        h_run( "CC:T.BOOT" )
    end )
end

local curtime = timer.curtime
local rnd = math.random
local timers = {}
function os.startTimer( n )
    if n == math.huge then error( "time cannot be infinite" ) end
    expect( 1, n, "number", "nil" )
    local x = { off = math.round( n / 0.05 ) * 0.05, bgn = curtime() }
    local y = rnd( 0, 0xFFFFFF )
    timers[y] = x
    return y
end

local t_empty = table.empty
local t_rem = table.remove
local powered = false
local MAIN = off

require = nil

local pairs = pairs
local hasFrameUpdate = false
local cpuAverage, cpuMax = cpuAverage, cpuMax
timer.create( "evqueue", 0.05, 0, function()
    if not powered then return end
    if cpuAverage() > cpuMax() * 0.5 then return end

    local n = curtime()
    for k, v in pairs( timers ) do
        if v.bgn + v.off < n then
            evQueue[#evQueue + 1] = { "timer", k }
            timers[k] = nil
        end
    end

    local n = t_rem( evQueue, 1 )
    if not n then return end

    local ret = { c_res( MAIN, unpack( n, 1, n.n ) ) }
    hasFrameUpdate = true
    hook.run( "CC:T.EXEC", ret )
    if c_sta( MAIN ) ~= "dead" then return end

    hook.run( "CC:T.SHUTDOWN", false )
    hook.run( "CC:T.STATUS", false, "DEAD" )
end )
timer.create( "CC:T.UpdateFrame", 0.5, 0, function()
    if not hasFrameUpdate then return end
    if cpuAverage() > cpuMax() * 0.5 then return end
    hasFrameUpdate = false
    hook.run( "CC:T.FRAME", term.serialise() )
end )

local off = coroutine.create( function()
    while true do
        c_yie( "Not booted!" )
    end
end )
local bios = assert( loadstring( scripts["bios.lua"], "bios.lua" ) )


hook.add( "CC:T.RUN", "", function( ... )
    if not powered then return false end

    local ret = { c_res( MAIN, ... ) }
    hasFrameUpdate = true
    h_run( "CC:T.EXEC", ret )

    if c_sta( MAIN ) ~= "dead" then return end
    h_run( "CC:T.SHUTDOWN", false )
    h_run( "CC:T.STATUS", false, "DEAD" )
end )
hook.add( "CC:T.QUEUE", "", function( ... )
    if not powered then return false end

    local t = { ... }
    t.n = select( "#", ... )
    evQueue[#evQueue + 1] = t
end )

hook.add( "CC:T.BOOT", "", function()
    if powered then return false end
    t_empty( evQueue )
    t_empty( timers )

    MAIN = c_cre( bios )
    powered = true
    h_run( "CC:T.RUN" )
end )

hook.add( "CC:T.SHUTDOWN", "", function()
    if not powered then return false end
    t_empty( evQueue )
    t_empty( timers )

    MAIN = off
    powered = false
end )
