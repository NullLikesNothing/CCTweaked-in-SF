--@name CC: Tweaked implementation testing
--@author Lumi
--@client
--@owneronly

local TESTS = {}
local FAIL_COLOR = Color( 255, 120, 120 )
local SUCCESS_COLOR = Color( 120, 255, 120 )
local TEST_PRINT = Color( 200, 200, 200 )
local TEST_PRINT_NAME = Color( 100, 200, 200 )

local TEST_ENV = setmetatable( {}, { __index = _G } )
local scripts = {}
local print = print

local function failed( name, reason )
    reason = reason or "No reason specified"
    table.insert( TESTS, { name = name, result = "FAILED", message = reason } )
    printConsole( FAIL_COLOR, name .. " failed!" )
    printConsole( FAIL_COLOR, "Reason: " .. reason )
end
local function success( name, msg )
    table.insert( TESTS, { name = name, result = "SUCCESS", message = msg or "No message included" } )
    printConsole( SUCCESS_COLOR, name .. " passed!" )
    if msg then
        printConsole( SUCCESS_COLOR, "Attached message: " .. msg )
    end
end

local function includeStub( name )
    local f, err = loadstring( file.readInGame( string.format( "data/starfall/computercraft/stubs/%s.lua", name ) ) )
    if not f then
        failed( "STUB: " .. name, err )
        return
    end

    local x = { xpcall( f, function( err )
        failed( "STUB: " .. name, err )
    end ) }
    table.remove( x, 1 )
    return unpack( x )
end
local function doTest( name )
    local function envPrint( ... )
        printConsole( TEST_PRINT_NAME, "[Test " .. name .. "] ", TEST_PRINT, ... )
    end
    local f, err = loadstring( file.readInGame( string.format( "data/starfall/computercraft/tests/%s.lua", name ) ) )
    if not f then
        failed( "TEST: " .. name, err )
        return
    end
    local env = setmetatable( {}, { __index = TEST_ENV } )
    env._G = env
    env.print = envPrint
    env.printConsole = envPrint
    env._NAME = name

    setfenv( f, env )

    xpcall( f, function( err )
        failed( "TEST: " .. name, err )
    end )
end

function require( a )
    a = "libs/" .. tostring( a ) .. ".lua"
    local d = scripts[a]
    if not d then
        d = file.readInGame( "data/starfall/computercraft/" .. a )
        scripts[a] = d
    end
    if d then
        return assert( loadstring( d, a ) )() or true
    end
    error( "lib " .. a .. " not found!" )
end

local VALID_TYPES = {
    ["string"]   = true,
    ["number"]   = true,
    ["table"]    = true,
    ["nil"]      = true,
    ["function"] = true,
    ["boolean"]  = true,
}
function TEST_ENV.expectType( ret, ... )
    local valid = { ... }
    local tret = type( ret )

    for k, v in pairs( valid ) do
        if not VALID_TYPES[v] then
            error( "Expected type at argument " .. ( k + 1 ) .. " to be string. Got " .. tostring( v ) )
        end
        if tret == v then
            return true
        end
    end

    local self = getfenv( 2 )
    failed( self._NAME, string.format( "Expected %s to be of type(s) { %s }, it was %s", name, table.concat( tret, ", " ), tret ) )
    return false
end
function TEST_ENV.shouldExist( name, val )
    local self = getfenv( 2 )
    if val == nil then
        failed( self._NAME, string.format( "Expected %s to exist, it does not.", name ) )
        return false
    end

    return true
end
function TEST_ENV.shouldBe( name, ret, should )
    local self = getfenv( 2 )
    if ret ~= should then
        failed( self._NAME, string.format( "Expected %s to be %s, it is %s", name, tostring( should ), tostring( ret ) ) )
        return false
    end

    return true
end
TEST_ENV.success = success
TEST_ENV.failed  = failed

includeStub( "simple_fixes" )

fs = includeStub( "fs" )
peripheral = includeStub( "peripheral" )
rs = includeStub( "redstone" )
redstone = rs
settings = includeStub( "settings" )

local IGNORE = {}
IGNORE["/unused"] = true
IGNORE["/main.lua"] = true
IGNORE["/sv_main.lua"] = true

IGNORE["/test.lua"] = true
IGNORE["/tests"] = true

IGNORE["/cl_fragment.lua"] = true
IGNORE["/cl_stub.lua"] = true

IGNORE["/readme.md"] = true
IGNORE["/todo.md"] = true
IGNORE["/.gitignore"] = true

local BASE = "data/starfall/computercraft/"
local function recursiveFind( dir, dirname )
    dirname = dirname or ""
    local x, y = file.findInGame( BASE .. dir .. "*" )
    for _, v in ipairs( y ) do
        if not IGNORE[dirname .. "/" .. v] then
            local ret = recursiveFind( dir .. v .. "/", v )
            table.add( x, ret )
        end
    end
    for i = #x, 1, -1 do
        local v = x[i]
        if not IGNORE[dirname .. "/" .. v] then
            x[i] = string.normalizePath( dirname .. "/" .. v )
        else
            table.remove( x, i )
        end
    end
    
    return x
end

local x = recursiveFind( "" )
for _, v in ipairs( x ) do
    scripts[v] = file.readInGame( BASE .. v )
end

assert( loadstring( file.readInGame( "data/starfall/computercraft/sf_bios.lua" ), "sf_bios.lua" ) )( scripts )
hook.run( "CC:T.BOOT" )
hook.run( "CC:T.SHUTDOWN" )
_G.print = print

local testFiles = file.findInGame( "data/starfall/computercraft/tests/*.lua" )
if #testFiles == 0 then
    print( "No tests to run!" )
    return
end

for _, v in ipairs( testFiles ) do
    v = v:gsub( "%.lua", "" )
    print( "Running test " .. v )
    doTest( v )
end

print( "Test results printed in console " )

