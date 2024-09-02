local HEADROOM = 1000

local IGNORE = {}
IGNORE["/unused"] = true
IGNORE["/main.lua"] = true
IGNORE["/main_og.lua"] = true

IGNORE["/includes.lua"] = true
IGNORE["/coroutine_von.lua"] = true

IGNORE["/cl_fragment.lua"] = true
IGNORE["/old_cl_frag.lua"] = true

local MAX_NET_BYTES = net.getBytesLeft()
local _print = _G.print

local BASE = "data/starfall/computercraft/"
local function recursiveFind( dir, dirname )
    dirname = dirname or ""
    local x, y = file.findInGame( BASE .. dir .. "*" )
    for _, v in ipairs( y ) do
        if IGNORE[dirname .. "/" .. v] then
            _print( "ignoring", dirname .. "/" .. v )
        else
            local ret = recursiveFind( dir .. v .. "/", v )
            table.add( x, ret )
        end
    end
    for i = #x, 1, -1 do
        local v = x[i]
        if not IGNORE[dirname .. "/" .. v] then
            x[i] = string.normalizePath( dirname .. "/" .. v )
        else
            _print( "ignoring", dirname .. "/" .. v )
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
    return files
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

        net.start( "CC:Tweaked" )
        net.writeBool( false )
        net.writeUInt( #s, NET_BITS )
        net.writeData( s, #s )
        net.send()

        if prog > ttl then
            hook.remove( "PostDrawHUD", "" )

            net.start( "CC:Tweaked" )
            net.writeBool( true )
            net.send()
        end
    else
        render.drawText( 200, 250, "Waiting for net bytes to recover..." )
    end

    render.drawText( 200, 200, string.format( "Package status:\nBytes: %s out of %s (%.2f%%)\nNet usage: %s/%s (%.2f%%)", prog, ttl, prog / ttl * 100, bytes, MAX_NET_BYTES, 100 - bytes / MAX_NET_BYTES * 100 ) )
end

-- CC:Tweaked.Event
concmd( "paint_decal \"\"")
timer.create( "evt", 0.1, 0, function()
    local val = convar.getString( "paint_decal" )
    if val == "" then return end
    -- val = val:gsub("::SEMICOLON::",";")
    concmd( "paint_decal \"\"" )

    hook.run( "CC:T.RUN" )
    do return end
    local s = pcall( function()
        von.deserialize( val )
    end )
    if not s then
        print( "Invalid vON!")
        return
    end

    net.start( "CC:Tweaked.Event" )
    net.writeString( val )
    net.send()
end )

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

local termx, termy = 0, 0
local fnt = render.createFont("DejaVu Sans Mono",16,500,false,false,false,false,0,false,0)
local function drawTerm()
    render.selectRenderTarget( "CC:Tweaked" )
    local w, h = render.getResolution()

    render.setFont( fnt )
    render.clear( clrs.b )

    if not seri then return end
    for i = 1, #seri.text do
        local t = seri.text[i]
        for j = 1, #t do
            render.setColor( clrs[ seri.back[i]:sub( j, j ) ] )
            render.drawRectFast( ( j - 1 ) * 8, ( i - 1 ) * 16, 8, 16 )

            render.setColor( clrs[ seri.fore[i]:sub( j, j ) ] )
            render.drawText( ( j - 1 ) * 8, ( i - 1 ) * 16, t:sub( j, j ) )
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
hook.add( "CC:T.EXEC", "", function( ret, sTerm )
    print( "exec", unpack( ret ) )
    h_once( "RenderOffScreen", "CC:T", drawTerm )
    seri = json.decode( sTerm )
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

hook.add( "DrawHUD", "Terminal", drawTermRT )

hook.add( "Think", "", function()
    chkmax()
    for i = 1, 5 do
        local x = coroutine.resume( coro )
        if coroutine.status( coro ) == "dead" then
            enableHud( nil, true )
            assert( loadstring( files["sf_bios.lua"], "sf_bios.lua" ) )( files )
            termx, termy = term.getSize()

            timer.simple( 0, function()
                hook.run( "CC:T.STATUS", true, "BOOT" )
                hook.run( "CC:T.BOOT" )
            end )
            -- RUN( "key", keys.enter, false )

            -- fstr = bit.compress( x )
            -- frem = fstr
            -- ttl = #fstr
            -- prog = 0

            hook.remove( "Think", "" )

            -- enableHud( nil, true )
            -- hook.add( "PostDrawHUD", "", sendPackage )

            break
        end
    end
end )
