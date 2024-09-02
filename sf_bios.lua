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

debug.getregistry = debug.getregistry or function() end

local function mkdir()
    return {
        t = "d",
        f = {},
    }
end

local pt = printTable
local function printTable( t )
    local as = _G.print
    _G.print = print
    pt( t )
    _G.print = as
end

local fsys = mkdir()
local scripts = ...

function require( a )
    local d = scripts["libs/" .. tostring(a) .. ".lua"]
    if d then
        return assert( loadstring( d ) )() or true
    end
    error( "lib " .. tostring( a ) .. " not found!" )
end

local reqexpect = require( "expect" )
local expect = reqexpect.expect
local field = reqexpect.field

require( "colors" )

-- assert( loadstring( scripts["libs/framebuffer.lua"], "libs/framebuffer.lua" ) )( scripts )
_G.term = { native = function()
    return setmetatable( {}, { __index = function( self, key )
        setmetatable( self, { __index = term } )
        return term[key]
    end } )
end }
local framebuffer = require( "framebuffer" )
local term = framebuffer.buffer( framebuffer.empty( true, 51, 19 ) )

require = nil
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
-- printTable( fsys )

local function CLOSED_FILE()
    error( "attempt to use a closed file" )
end
local sub = string.sub

local snp = string.normalizePath
local fs = {}
function fs.open( file, mode )
    expect( 1, file, "string" )
    file = snp( file )
    expect( 2, mode, "string" )
    if mode ~= "r" and mode ~= "rb" and mode ~= "w" and mode ~= "wb" then
        return nil, "Unsupported mode"
    end
    if s_bw( file, "rom/" ) and mode ~= "r" and mode ~= "rb" then return nil, "/" .. tostring( file ) .. ": Access denied" end
    if mode == "w" or mode == "wb" then
        local ks = spt( file, "/" )
        local last = fsys
        for i = 1, #ks - 1 do
            if not last.f[ks[i]] then
                return
            end
            last = last.f[ks[i]]
        end

        last.f[ks[#ks]] = last.f[ks[#ks]] or { d = "", t = "f" }
        last = last.f[ks[#ks]]
        local f = ss( "" )
        local t = {}
        function t.close()
            t.close = CLOSED_FILE
            t.write = CLOSED_FILE
            t.writeLine = CLOSED_FILE
            t.seek = CLOSED_FILE
            t.flush = CLOSED_FILE

            last.d = f:getString()
        end
        function t.flush()
            last.d = f:getString()
        end
        function t.write( ... )
            local t, n = { ... }, select( "#", ... )
            f:write( tostring( d ) )
        end
        function t.writeLine( d )
            f:write( tostring( d ) .. "\n" )
        end
        function t.seek( mode, n )
            if mode == "set" then
                f:seek( n + 1 )
                return n
            elseif mode == "cur" or mode == nil then
                n = f:tell() + n
                f:seek( n + 1 )
                return n
            elseif mode == "end" then
                n = f:size() - n
                f:seek( n + 1 )
                return n
            end
        end

        return t
    end
    if mode == "a" or mode == "ab" then
        local ks = spt( file, "/" )
        local last = fsys
        for i = 1, #ks - 1 do
            if not last.f[ks[i]] then
                return
            end
            last = last.f[ks[i]]
        end

        last.f[ks[#ks]] = last.f[ks[#ks]] or { d = "", t = "f" }
        last = last.f[ks[#ks]]
        local f = ss( last.d or "" )
        f:seek( f:size() + 1 )
        local t = {}
        function t.close()
            t.close = CLOSED_FILE
            t.write = CLOSED_FILE
            t.writeLine = CLOSED_FILE
            t.seek = CLOSED_FILE
            t.flush = CLOSED_FILE

            last.d = f:getString()
        end
        function t.flush()
            last.d = f:getString()
        end
        function t.write( ... )
            local t, n = { ... }, select( "#", ... )
            f:write( tostring( d ) )
        end
        function t.writeLine( d )
            f:write( tostring( d ) .. "\n" )
        end

        return t
    end
    if mode == "r" or mode == "rb" then
        local ks = spt( file, "/" )
        local last = fsys
        for i = 1, #ks do
            if not last.f[ks[i]] then
                return nil, "/" .. tostring( file ) .. ": No such file"
            end
            -- print( ks[i] )
            last = last.f[ks[i]]
        end
        if not last then return nil, "/" .. tostring( file ) .. ": No such file" end
        if last.t ~= "f" then return nil, "/" .. tostring( file ) .. ": Not a file" end

        local f = ss( last.d or "" )
        local t = {}
        function t.close()
            t.close = CLOSED_FILE
            t.read = CLOSED_FILE
            t.readLine = CLOSED_FILE
            t.readAll = CLOSED_FILE
            t.seek = CLOSED_FILE
        end
        function t.read( n )
            local r = f:read( n )
            return #r ~= 0 and r or nil
        end
        function t.readLine( trail )
            local r = f:readUntil( 0x0A )
            if not trail then
                r = sub( r, 1, #r - 1 )
            end
            return #r ~= 0 and r or nil
        end
        function t.readAll( d )
            f:seek( f:size() + 1 )
            return f:getString()
        end
        function t.seek( mode, n )
            if mode == "set" then
                f:seek( n + 1 )
                return n
            elseif mode == "cur" or mode == nil then
                n = f:tell() + n
                f:seek( n + 1 )
                return n
            elseif mode == "end" then
                n = f:size() - n
                f:seek( n + 1 )
                return n
            end
        end
        return t
    end

    return nil, "/" .. tostring( file ) .. ": No such file"
end
function fs.combine( ... )
    for i = 1, select( "#", ... ) do
        expect( i, select( i, ... ), "string" )
    end
    return snp( t_concat( { ... }, "/" ) )
end
fs.getName = string.getFileFromFilename
fs.getDir = string.getPathFromFilename

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

function fs.exists( pth )
    expect( 1, pth, "string" )
    pth = snp( pth )
    local ks = spt( pth, "/" )
    local last = fsys
    for i = 1, #ks do
        if not last.f[ks[i]] then
            return false
        end
        last = last.f[ks[i]]
    end
    return last ~= nil
end
function fs.isDir( pth )
    expect( 1, pth, "string" )
    pth = snp( pth )
    local ks = spt( pth, "/" )
    local last = fsys
    for i = 1, #ks do
        if not last.f[ks[i]] then
            return false
        end
        last = last.f[ks[i]]
        -- print( ks[i] )
    end
    return last.t == "d"
end
function fs.list( pth )
    expect( 1, pth, "string" )
    pth = snp( pth )
    local ks = spt( pth, "/" )
    local last = fsys
    for i = 1, #ks do
        if not last.f[ks[i]] then
            return nil
        end
        last = last.f[ks[i]]
    end
    local t = {}
    for k, v in pairs( last.f ) do
        t[#t + 1] = k
    end

    -- printTable( t )
    return t
end
local settings = {}

local _sets = {}
local _usets = {}

function settings.define( name, opt )
    expect( 1, name, "string" )
    expect( 2, opt, "table", "nil" )
    opt = opt or {}
    if opt.type ~= nil then
        field( opt, "type", "string" )
        -- if type( opt.type ) ~= "string" then
        --     error( "bad field 'type' (string expected, got " .. type( opt.type ) .. ")", 2 )
        -- end
        if opt.type ~= "string" and
           opt.type ~= "number" and
           opt.type ~= "table" and
           opt.type ~= "boolean" then error( "Unknown type \"" .. tostring( opt.type ) .. "\"", 2 ) end
    end
    _sets[name] = opt
end
function settings.undefine( name )
    expect( 1, name, "string" )
    _sets[name] = nil
end
function settings.set( name, val )
    expect( 1, name, "string" )
    expect( 2, val, "string", "table", "boolean", "number" )
    _usets[name] = textutils.serialize( val )
end
function settings.unset( name )
    expect( 1, name, "string" )
    _usets[name] = ( _sets[name] and _sets[name].default ) or nil
end
function settings.get( name, def )
    expect( 1, name, "string" )
    local x = _usets[name] or def or ( _sets[name] and _sets[name].default ) or nil
    if x then
        x = textutils.deserialize( x )
    end
    return x
end
function settings.getDetails( name )
    expect( 1, name, "string" )
    local t = _sets[name] and t_cpy( _sets[name] ) or {}
    t.value = _usets[name] or def or ( _sets[name] and _sets[name].default ) or nil
    return t
end
function settings.clear()
    for k, name in pairs( _usets ) do
        _usets[name] = _sets[name] and _sets[name].default or nil
    end
end
function settings.getNames()
    return t_gk( _sets )
end
function settings.save( pth )
    expect( 1, name, "string", "nil" )
    pth = pth or ".settings"
    
    local f = fs.open( pth, "w" )
    if not f then return false end
    f.write( textutils.serialize( _usets ) )
    f:close()
    return true
end

_G.fs = fs
_G.os = os
_G.bit32 = bit
_G.settings = settings
_G.term = term
term.native = function() return term end
_G.PRINT = print

local rs_in  = { right = 0, left = 0, top = 0, bottom = 0, front = 0, back = 0 }
local rs_out = t_cpy( rs_in )

local rs = {}
_G.redstone = rs
_G.rs = rs

local VALID_SIDES = { top = true, bottom = true, left = true, right = true, front = true, back = true }
local function SIDE( s )
    if not VALID_SIDES[s] then error( "bad argument #1 (unknown option " .. s .. ")" ) end
end

function rs.setOutput( side, on )
    expect( 1, side, "string" )
    expect( 2, on, "boolean" )
    SIDE( side )

    rs_out[side] = on and 15 or 0
end
function rs.getOutput( side )
    expect( 1, side, "string" )
    SIDE( side )

    return rs_out[side] > 0
end
function rs.setAnalogOutput( side, strength )
    expect( 1, side, "string" )
    range( strength, 0, 15 )
    SIDE( side )

    rs_out[side] = strength
end
function rs.getAnalogOutput( side )
    expect( 1, side, "string" )
    SIDE( side )

    return rs_out[side]
end

rs.getAnalogueOutput = rs.getAnalogOutput
rs.setAnalogueOutput = rs.setAnalogOutput

function rs.getInput( side )
    expect( 1, side, "string" )
    SIDE( side )

    return rs_in[side] > 0
end
function rs.getAnalogInput( side )
    expect( 1, side, "string" )
    SIDE( side )

    return rs_in[side]
end

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

function term.getPaletteColor( clr )
    expect( 1, clr, "number" )
    local c = clrs[toBlit( clr )]
    return c.r / 255, c.g / 255, c.b / 255
end
term.getPaletteColour = term.getPaletteColor

local h_run = hook.run
local band = bit.band
local rshift = bit.rshift

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

rs.getAnalogueInput = rs.getAnalogInput

-- too lazy to implement bundled cables
local function nopnil() end
local function nopzero() return 0 end
rs.setBundledOutput = nopnil
rs.getBundledOutput = nopzero
rs.getBundledInput = nopzero
rs.testBundledInput = nopzero

table.unpack = unpack
function table.pack( ... )
    local t = { ... }
    t.n = select( "#", ... )
    return t
end

function rs.getSides()
    return {
        "bottom", "top",
        "left", "right",
        "front", "back",
    }
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

local t_sim = timer.simple

-- function coroutine.resume( ... )
--     local stk
--     local r = { xpcall( c_res, function( _, st )
--         stk = st
--     end, ... ) }
--     if not r[1] then
--         return false, stk
--     end
--     return unpack( r )
-- end
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
    expect( 1, n, "number" )
    local x = { off = math.round( n / 0.05 ) * 0.05, bgn = curtime() }
    local y = rnd( 0, 0xFFFFFF )
    timers[y] = x
end
local pairs = pairs
hook.add( "tick", "CC:T.Timers", function()
    local n = curtime()
    for k, v in pairs( timers ) do
        if v.bgn + v.off < n then
            h_run( "CC:T.QUEUE", "timer", k )
            timers[k] = nil
        end
    end
end )

local t_empty = table.empty
local t_rem = table.remove
local powered = false
local MAIN = off

timer.create( "evqueue", 0.05, 0, function()
    if not powered then return end
    local n = t_rem( evQueue, 1 )
    if not n then return end

    local ret = { coroutine.resume( MAIN, unpack( n, 1, n.n ) ) }
    hook.run( "CC:T.EXEC", ret, term.serialise() )
    if coroutine.status( MAIN ) ~= "dead" then return end

    hook.run( "CC:T.SHUTDOWN", false )
    hook.run( "CC:T.STATUS", false, "DEAD" )
end )

local off = coroutine.create( function()
    while true do
        coroutine.yield( "Not booted!" )
    end
end )
local bios = assert( loadstring( scripts["bios.lua"], "bios.lua" ) )


hook.add( "CC:T.RUN", "", function( ... )
    if not powered then return false end

    local ret = { coroutine.resume( MAIN, ... ) }
    hook.run( "CC:T.EXEC", ret, term.serialise() )

    if coroutine.status( MAIN ) ~= "dead" then return end
    hook.run( "CC:T.SHUTDOWN", false )
    hook.run( "CC:T.STATUS", false, "DEAD" )
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
