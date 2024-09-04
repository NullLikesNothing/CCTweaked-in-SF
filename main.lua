--@name ComputerCraft
--@author SquidDev - CC: Tweaked, Lumi - porting to SF
--@shared
--@xowneronly

if SERVER then
    net.receive( "termBuffer", function( _, ply )
        if ply ~= owner() then return end

        local len = net.readUInt( 16 )

        net.start( "termBuffer" )
        net.writeUInt( len, 16 )
        net.writeData( net.readData( len ), len )
        net.send()
    end )
    return
end

-- this should speed up load times as you only have to send these lines vs sending the entire `cl_fragment.lua` file to the server
if player() == owner() then
    assert( loadstring( file.readInGame( "data/starfall/computercraft/cl_fragment.lua" ), "cl_fragment.lua" ) )()
end

local dcmp = bit.decompress

local print = print
local NOSIGNAL = { cursorBlink = true, cursorX = 1, cursorY = 1, text = { "NO SIGNAL" }, fore = { "eeeeeeeee" }, back = { "fffffffff" } }
local seri = NOSIGNAL

local drawRect = render.drawRectFast
local drawText = render.drawText
local setClr = render.setColor
local sub = string.sub

local cursorBlink = false
local cblink = 0

local termx, termy = 0, 0
local fnt = render.createFont("DejaVu Sans Mono",16,500,false,false,false,false,0,false,0)

local clrs = {}
local bit = table.copy( bit )
local function unpackRGB(rgb)
    return
        bit.band(bit.rshift(rgb, 16), 0xFF) / 255,
        bit.band(bit.rshift(rgb, 8), 0xFF) / 255,
        bit.band(rgb, 0xFF) / 255
end

render.createRenderTarget( "CC:T" )
local function drawTerm()
    render.selectRenderTarget( "CC:T" )
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
hook.once( "RenderOffScreen", "CC:T.DrawRT", drawTerm )
net.receive( "termBuffer", function()
    local dlen = net.readUInt( 16 )
    local data = net.readData( dlen )

    seri = json.decode( dcmp( data ) )
    termx, termy = seri.width, seri.height
    -- clrs = seri.palette
    for k, v in pairs( seri.palette ) do
        local r, g, b = unpackRGB( v )
        r, g, b = r * 255, g * 255, b * 255
        clrs[tostring(k)] = Color( r, g, b )
    end

    hook.once( "RenderOffScreen", "CC:T.DrawRT", drawTerm )
end )

local DEF_CLR = Color( 255, 0, 0, 127 )
local function drawrt()
    render.setRenderTargetTexture( "CC:T" )
    local w, h = termx * 8, termy * 16
    render.drawTexturedRectUV( 0, 0, w, h, 0, 0, w / 1024, h / 1024 )

    local n = timer.curtime()
    if cblink < n then
        cblink = n + 0.25
        cursorBlink = not cursorBlink
    end

    if not ( seri and seri.cursorBlink and cursorBlink ) then return end

    render.setColor( clrs["0"] or DEF_CLR )
    render.drawRect( ( seri.cursorX - 1 ) * 8, ( seri.cursorY - 1 ) * 16 + 12, 8, 4 )
end

hook.add( "render", "CC:T.Terminal", drawrt )
