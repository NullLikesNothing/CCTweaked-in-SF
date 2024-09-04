-- This file used to be for running on server-side

local HEADROOM = 1000

local IGNORE = {}
IGNORE["/unused"] = true
IGNORE["/main.lua"] = true
IGNORE["/readme.md"] = true
IGNORE["/todo.md"] = true
IGNORE["/.gitignore"] = true
IGNORE["/cl_fragment.lua"] = true
IGNORE["/cl_stub.lua"] = true
IGNORE["/sv_main.lua"] = true

local MAX_NET_BYTES = net.getBytesLeft()
local _print = _G.print

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

local files = {}
local fstr = ""
local frem = ""

local coro = coroutine.create( function()
    local x = recursiveFind( "" )
    for _, v in ipairs( x ) do
        files[v] = file.readInGame( BASE .. v )
        coroutine.yield( v, files[v] )
    end
    return bit.tableToString( files )
end )

local prog = 0
local ttl = 0

local MAX_NET_BYTES = net.getBytesLeft()
local function chkmax()
    local cur = net.getBytesLeft()
    if cur > MAX_NET_BYTES then MAX_NET_BYTES = cur end
    return MAX_NET_BYTES, cur
end

local function sendPackage()
    local _, bytes = chkmax()
    if bytes >= MAX_NET_BYTES - 200 then
        local s = frem:sub( 1, math.min( bytes - 200, #frem ) )
        frem = frem:sub( #s + 1 )
        prog = prog + #s + 1

        net.start( "CC:Tweaked.PKG" )
        net.writeBool( false )
        net.writeFloat( prog / ttl * 100 )
        net.writeUInt( #s, NET_BITS )
        net.writeData( s, #s )
        net.send()

        if prog > ttl then
            hook.remove( "PostDrawHUD", "" )

            net.start( "CC:Tweaked.PKG" )
            net.writeBool( true )
            net.send()
            
            hook.remove( "PostDrawHUD", "" )
            return
        end
    else
        render.drawText( 200, 250, "Waiting for net bytes to recover..." )
    end

    render.drawText( 200, 200, string.format( "Package status:\nBytes: %s out of %s (%.2f%%)\nNet usage: %s/%s (%.2f%%)", prog, ttl, prog / ttl * 100, bytes, MAX_NET_BYTES, 100 - bytes / MAX_NET_BYTES * 100 ) )
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

local power = false
local cursorBlink = false

local t_ct = timer.curtime
local cblink = t_ct()
local NOSIGNAL = { cursorBlink = true, cursorX = 1, cursorY = 1, text = { "NO SIGNAL" }, fore = { "eeeeeeeee" }, back = { "fffffffff" } }
local seri = NOSIGNAL

local drawRect = render.drawRectFast
local drawText = render.drawText
local setClr = render.setColor
local sub = string.sub

local print = print
local termx, termy = 0, 0
local fnt = render.createFont("DejaVu Sans Mono",16,500,false,false,false,false,0,false,0)
local function drawTerm()
    render.selectRenderTarget( "CC:Tweaked" )
    local w, h = render.getResolution()

    render.setFont( fnt )
    render.clear( clrs.b )

    if not seri then return end
    local fg = seri.fore
    local bg = seri.back

    for i = 1, #seri.text do
        local t = seri.text[i]
        for j = 1, #t do
            local s, e = pcall( setClr, clrs[ sub( bg[i], j, j ) ] )
            if not s then
                -- print( "BG", e, #bg[i], bg[i], sub( bg[i], j, j ) )
            end
            drawRect( ( j - 1 ) * 8, ( i - 1 ) * 16, 8, 16 )

            s, e = pcall( setClr, clrs[ sub( fg[i], j, j ) ] )
            if not s then
                -- print( "FG", e, #fg[i], fg[i], sub( fg[i], j, j ) )
            end
            drawText( ( j - 1 ) * 8, ( i - 1 ) * 16, sub( t, j, j ) )
        end
    end

end
function hook.once( name, un, fn )
    hook.add( name, un, function( ... )
        hook.remove( name, un )
        return fn( ... )
    end )
end
local h_once = hook.once
local print = print

render.createRenderTarget( "CC:Tweaked" )
hook.once( "RenderOffScreen", "CC:T", drawTerm )

hook.add( "CC:T.STATUS", "", function( powered, reason )
    power = powered
    print( "Computer is ", power and "ON" or "OFF", reason )
end )
hook.add( "CC:T.EXEC", "", function( success, ... )
    if success then return end
    print( "exec fail", ... )
end )

local bit_compress = bit.compress
hook.add( "CC:T.FRAME", "", function( buff )
    h_once( "RenderOffScreen", "CC:T", drawTerm )

    net.start( "termBuffer" )
    local comp = bit_compress( buff )
    net.writeUInt( #comp, 16 )
    net.writeData( comp, #comp )
    net.send()

    seri = json.decode( buff )
end )

local key_lookup = {}
for k, v in pairs( KEY ) do
    key_lookup[v] = k
end
local rebind = {
    ctrl = "leftCtrl",
    shift = "leftShift",
    rcontrol = "rightCtrl",
    rshift = "rightShift",
    ["0"] = "zero",
    ["1"] = "one",
    ["2"] = "two",
    ["3"] = "three",
    ["key4"] = "four",
    ["key5"] = "five",
    ["key6"] = "six",
    ["key7"] = "seven",
    ["key8"] = "eight",
    ["key9"] = "nine",
    ["="] = "equals",
    [","] = "comma",
    ["."] = "period",
    backquote = "grave",
    uparrow = "up",
    downarrow = "down",
}
local PRINTABLE = {}
PRINTABLE.SPACE      = { " ", " " }
PRINTABLE.SEMICOLON  = { ";", ":" }
PRINTABLE.APOSTROPHE = { "'", '"' }
PRINTABLE.SLASH      = { "/", "?" }
PRINTABLE.COMMA      = { ",", "<" }
PRINTABLE.PERIOD     = { ".", ">" }
PRINTABLE.LBRACKET   = { "[", "{" }
PRINTABLE.RBRACKET   = { "]", "}" }
PRINTABLE.BACKSLASH  = { "\\", "|" }
PRINTABLE.MINUS      = { "-", "_" }
PRINTABLE.EQUALS     = { "=", "+" }
PRINTABLE.GRAVE      = { "`", "~" }

PRINTABLE.ONE   = { "1", "!" }
PRINTABLE.TWO   = { "2", "@" }
PRINTABLE.THREE = { "3", "#" }
PRINTABLE.FOUR  = { "4", "$" }
PRINTABLE.FIVE  = { "5", "%" }
PRINTABLE.SIX   = { "6", "^" }
PRINTABLE.SEVEN = { "7", "&" }
PRINTABLE.EIGHT = { "8", "*" }
PRINTABLE.NINE  = { "9", "(" }
PRINTABLE.ZERO  = { "0", ")" }

local PRESSED = {}
local shift = false
local ctrl = false
hook.add( "playerchat", "", function( p, t )
    if p ~= player() then return end

    if t == "cc.lock" then
        if not input.canLockControls() then return print("can't lock") end
        timer.simple( 0, function()
            input.lockControls( true )
        end )
        print( "note: you cannot use ALT!" )
    elseif t == "cc.reboot" then
        hook.run( "CC:T.SHUTDOWN", false )
        hook.run( "CC:T.STATUS", false, "User forced reboot" )
        timer.simple( 0.5, function()
            hook.run( "CC:T.STATUS", true, "User forced reboot" )
            hook.run( "CC:T.BOOT" )
        end )
    elseif t == "cc.boot" then
        print( "run boot hook" )
        hook.run( "CC:T.BOOT" )
    elseif t == "cc.shutdown" then
        print( "run shutdown hook" )
        hook.run( "CC:T.BOOT", false )
    end
end )

hook.add( "inputPressed", "", function( key )
    if not power then return end
    if not keys then return end

    local k = key_lookup[key]
    if not k then return end
    k = k:lower()
    if rebind[k] then k = rebind[k] end

    if k == "leftShift" or k == "rightShift" then
        PRESSED[k] = true
        shift = true
    end
    if k == "leftCtrl" or k == "rightCtrl" then
        PRESSED[k] = true
        ctrl = true
    end
    if not input.isControlLocked() then return end
    PRESSED[k] = true
    if ctrl and k == "t" then
        hook.run( "CC:T.QUEUE", "terminate" )
        return
    end

    local cck = keys[k]
    if not cck then return end
    hook.run( "CC:T.QUEUE", "key", cck, false )
    if PRINTABLE[k:upper()] or #k == 1 then
        hook.run( "CC:T.QUEUE", "char", ( PRINTABLE[k:upper()] or {} )[shift and 2 or 1] or ( shift and k:upper() or k ) )
    end
end )
hook.add( "inputReleased", "", function( key )
    if not power then return end
    if not keys then return end

    local k = key_lookup[key]
    if not k then return end
    k = k:lower()
    if rebind[k] then k = rebind[k] end
    if not PRESSED[k] then return end
    PRESSED[k] = nil

    if k == "leftShift" or k == "rightShift" then
        shift = PRESSED.leftShift or PRESSED.rightShift or false
    end
    if k == "leftCtrl" or k == "rightCtrl" then
        ctrl = PRESSED.leftCtrl or PRESSED.rightCtrl or false
    end

    local cck = keys[k]
    if not cck then return end
    hook.run( "CC:T.QUEUE", "key_up", cck )
end )

local function drawTermRT()
    render.setRenderTargetTexture( "CC:Tweaked" )
    local w, h = termx * 8, termy * 16
    render.drawTexturedRectUV( 32, 32, w, h, 0, 0, w / 1024, h / 1024 )

    local n = t_ct()
    if cblink < n then
        cblink = n + 0.25
        cursorBlink = not cursorBlink
    end

    if not ( seri and seri.cursorBlink and cursorBlink ) then return end

    render.setColor( clrs["0"] )
    render.drawRect( 32 + ( seri.cursorX - 1 ) * 8, 28 + ( seri.cursorY - 1 ) * 16 + 16, 8, 4 )
end

-- hook.add( "DrawHUD", "Terminal", drawTermRT )

net.start( "CC:T.INIT" )
net.writeStream( file.readInGame( "data/starfall/computercraft/sv_main.lua" ) )
net.send()

net.receive( "CC:T.SendROM", function()
    local sendROM = net.readBool()
    enableHud( nil, true )
    
    local hashExists = file.exists( "cc_tweaked.rom.hash.txt" )
    if sendROM or not hashExists then
        if not sendROM then
            print( "Server requests ROM hash, but we don't have it" )
        end
        net.start( "CC:T.Hash" )
        net.writeBool( false )
        net.send()

        hook.add( "Think", "", function()
            chkmax()
            for i = 1, 5 do
                local x = coroutine.resume( coro )
                if coroutine.status( coro ) == "dead" then
                    fstr = bit.compress( x )
                    file.write( "cc_tweaked.rom.hash.txt", bit.md5( fstr ) )
                    frem = fstr
                    ttl = #fstr
                    prog = 0
        
                    hook.remove( "Think", "" )
                    print( "Sending ROM" )
                    hook.add( "PostDrawHUD", "", sendPackage )
        
                    break
                end
            end
        end )
    elseif hashExists then
        local hash = file.read( "cc_tweaked.rom.hash.txt" )
        net.start( "CC:T.Hash" )
        net.writeBool( hash ~= nil )
        if hash ~= nil then
            net.writeString( hash )
        end
        net.send()
    end
end )

assert( loadstring( file.readInGame( "data/starfall/computercraft/cl_stub.lua" ), "cl_stub.lua" ) )()
hook.add( "Think", "", chkmax )
