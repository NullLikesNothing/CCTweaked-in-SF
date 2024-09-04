-- DO NOT PLACE THIS ON IT'S OWN!
local print = print

local bit_compress = bit.compress
hook.add( "CC:T.FRAME", "", function( buff )
    -- h_once( "RenderOffScreen", "CC:T", drawTerm )

    net.start( "termBuffer" )
    local comp = bit_compress( buff )
    net.writeUInt( #comp, 16 )
    net.writeData( comp, #comp )
    net.send()

    -- seri = json.decode( buff )
end )

local seri = { cursorBlink = true, cursorX = 1, cursorY = 1, text = { "NO SIGNAL" }, fore = { "eeeeeeeee" }, back = { "fffffffff" }, palette = json.decode( '{"0":15790320,"1":15905331,"2":15040472,"3":10072818,"4":14605932,"5":8375321,"6":15905484,"7":5000268,"8":10066329,"9":5020082,"f":1118481,"e":13388876,"d":5744206,"c":8349260,"b":3368652,"a":11691749}' ) }
local function makeProgress( txt )
    seri.text = txt:split( "\n" )
    seri.fore = table.copy( seri.text )
    seri.back = table.copy( seri.text )

    local width, height = 1, #seri.text
    for i, v in pairs( seri.fore ) do
        width = math.max( width, #v )
        seri.fore[i] = string.rep( "e", #v )
        seri.back[i] = string.rep( "f", #v )
    end
    seri.width, seri.height = width, height

    local buf = bit.compress( json.encode( seri ) )

    net.start( "termBuffer" )
    net.writeUInt( #buf, 16 )
    net.writeData( buf, #buf )
    net.send()
end

local PKG = ""
hook.add( "net", "CC:Tweaked.PKG", function( name, _, ply )
    if name ~= "CC:Tweaked.PKG" then return end
    if ply ~= owner() then return end

    if net.readBool() then
        makeProgress( "CC:Tweaked Package status: 100%\nDecompressing" )
        timer.simple( 1, function()
            setUserdata( "CC:T-" .. PKG )
            PKG = bit.decompress( PKG )
            makeProgress( "CC:Tweaked Package status: 100%\nDecompressing - Done\nMake FS" )
            timer.simple( 1, function()
                local files = bit.stringToTable( PKG )
                local errored = false
                local errorStr = "Critical error!\n"
                local function chkFile( n )
                    if files[n] then return end
                    errorStr = string.trim( errorStr .. "\n" .. "- No " .. n )
                    errored = true
                end
                chkFile( "sf_bios.lua" )
                chkFile( "bios.lua" )
                
                if errored then
                    makeProgress( errorStr )
                    error( errorStr )
                    return
                end

                assert( loadstring( files["sf_bios.lua"], "sf_bios.lua" ) )( files )
                makeProgress( "Decompressing - Done\nMake FS - Done\nWaiting for boot signal." )
            end )
        end )
        return
    end
    local progress = net.readFloat()

    PKG = PKG .. net.readData( net.readUInt( NET_BITS ) )

    makeProgress( ( "CC:Tweaked Package status: %.2f%%" ):format( progress ) )
end )
do
    local dta = getUserdata()
    if dta and dta:sub( 1, 5 ) == "CC:T-" then
        print( "Asking for ROM hash" )
        net.start( "CC:T.SendROM" )
        net.writeBool( false )
        net.send( owner() )

        local hash = bit.md5( dta:sub( 6 ) )
        hook.add( "net", "CC:T.CheckHash", function( name, _, ply )
            if name ~= "CC:T.Hash" then return end
            if ply ~= owner() then return end

            hook.remove( "net", "CC:T.CheckHash" )

            local hasHash = net.readBool()
            if not hasHash then return end

            if net.readString() == hash then
                print( "Hashes match!" )
                local _nb = net.readBool
                PKG = dta:sub( 6 )
                net.readBool = function() return true end
                hook.run( "net", "CC:Tweaked.PKG", nil, owner() )
                net.readBool = _nb1
                return
            end

            print( "Hashes don't match" )
            net.start( "CC:T.SendROM" )
            net.writeBool( true )
            net.send( ply )
        end )
    else
        print( "Asking for full ROM" )
        net.start( "CC:T.SendROM" )
        net.writeBool( true )
        net.send( owner() )
    end
end

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
    ["4"] = "four",
    ["5"] = "five",
    ["6"] = "six",
    ["7"] = "seven",
    ["8"] = "eight",
    ["9"] = "nine",

    ["key0"] = "zero",
    ["key1"] = "one",
    ["key2"] = "two",
    ["key3"] = "three",
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
PRINTABLE.SPACE        = { " ", " " }
PRINTABLE.SEMICOLON    = { ";", ":" }
PRINTABLE.APOSTROPHE   = { "'", '"' }
PRINTABLE.SLASH        = { "/", "?" }
PRINTABLE.COMMA        = { ",", "<" }
PRINTABLE.PERIOD       = { ".", ">" }
PRINTABLE.LEFTBRACKET  = { "[", "{" }
PRINTABLE.RIGHTBRACKET = { "]", "}" }
PRINTABLE.BACKSLASH    = { "\\", "|" }
PRINTABLE.MINUS        = { "-", "_" }
PRINTABLE.EQUALS       = { "=", "+" }
PRINTABLE.GRAVE        = { "`", "~" }

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

for k, v in pairs( PRINTABLE ) do
    rebind[v[1]] = k:lower()
    rebind[v[2]] = k:lower()
end

local PRESSED = {}
local power = false
hook.add( "CC:T.STATUS", "_INTERNAL", function( b )
    power = b
    print( "new status is ", b )
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

local IS_INPUT = false
local s_spl = string.split
local sub = string.sub
local h_run = hook.run
local ipairs = ipairs
local low, UPP = string.lower, string.upper
local function upp( s )
    print( s, rebind[low( s )] )
    local t = PRINTABLE[UPP( rebind[low( s )] or "" )]
    if t then
        return t
    end
    return UPP( s )
end

hook.add( "PlayerSay", "", function( ply, txt )
    if ply ~= owner() then return end
    if not IS_INPUT and txt ~= "cc.quick" then return end

    if IS_INPUT then
        IS_INPUT = false
        local k = ""
        local isSpecial = false
        for i = 1, #txt do
            local j = sub( txt, i, i )
            if isSpecial then
                if j == "\\" then
                    isSpecial = false
                    if #k == 0 then
                        h_run( "CC:T.QUEUE", "key", keys.backslash, false )
                        h_run( "CC:T.QUEUE", "char", "\\" )
                        h_run( "CC:T.QUEUE", "key_up", keys.backslash )
                    else
                        k = low( k )
                        if rebind[k] then k = rebind[k] end
                        local cck = keys[k]
                        if cck then
                            h_run( "CC:T.QUEUE", "key", cck, false )
                            if PRINTABLE[k] or #k == 1 then
                                h_run( "CC:T.QUEUE", "char", ( PRINTABLE[k] or {} )[k == low( k ) and 1 or 2] or k )
                            end
                            h_run( "CC:T.QUEUE", "key_up", cck )
                        end
                    end
                    print( k )
                    k = ""
                else
                    k = k .. j
                end
            else
                if j == "\\" then
                    isSpecial = true
                else
                    if rebind[low(j)] then j = rebind[low(j)] end
                    local cck = keys[low( j )]
                    if cck then
                        h_run( "CC:T.QUEUE", "key", cck, false )
                        h_run( "CC:T.QUEUE", "char", ( PRINTABLE[upp( j )] or {} )[upp( j ) == j and 2 or 1] or j )
                        h_run( "CC:T.QUEUE", "key_up", cck )
                    end
                end
            end
        end
        print( txt )
        return ""
    else
        print( "Next message will be sent directly to CC:Tweaked" )
        IS_INPUT = true
        return ""
    end
end )

local print = print
local unpack = unpack

local net = table.copy( net )
local bit = table.copy( bit )

net.receive( "CC:T.QUEUE", function( _, ply )
    if ply ~= owner() then return end
    
    local num = net.readUInt( 10 )
    for _ = 1, num do
        local q = net.readData( net.readUInt( 10 ) )
        hook.run( unpack( bit.stringToTable( q ), 1, q.n ) )
    end
end )

local onl = false
net.receive( "CC:T.STATUS", function( _, ply )
    if ply ~= owner() then return end
    local b = net.readBool()

    if onl == b then return end
    if b then
        print( "boot her up" )
        makeProgress( "Starting computer..." )
        hook.run( "CC:T.STATUS", true, "Manual" )
        print( hook.run( "CC:T.BOOT" ) )
    else
        print( "shut her down" )
        print( hook.run( "CC:T.SHUTDOWN", false ) )
        hook.run( "CC:T.STATUS", false, "Forced" )
        -- makeProgress( "Computer offline: forced" )
    end
end )
hook.add( "CC:T.STATUS", "main", function( b, rsn )
    onl = b
    if b then return end
    makeProgress( "Computer offline: " .. tostring( rsn ) )
end )

-- net.receive( "termBuffer", function( _, ply )
--     if ply ~= owner() then return end

--     local len = net.readUInt( 16 )

--     net.start( "termBuffer" )
--     net.writeUInt( len, 16 )
--     net.writeData( net.readData( len ), len )
--     net.send()
-- end )