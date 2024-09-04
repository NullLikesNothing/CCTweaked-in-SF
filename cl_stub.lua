local function pack( ... )
    local t = { ... }
    t.n = select( "#", ... )
    return t
end

local NET_QUEUE = {}
local pressed = {}
hook.add( "inputPressed", "", function( key )
    if not input.isControlLocked() then return end
    pressed[key] = true
    NET_QUEUE[#NET_QUEUE + 1] = { "inputPressed", key, n = 2 }
end )
hook.add( "inputReleased", "", function( key )
    if not pressed[key] then return end
    pressed[key] = nil
    NET_QUEUE[#NET_QUEUE + 1] = { "inputReleased", key, n = 2 }
end )

hook.add( "CC:T.SHUTDOWN", "CC:T.CL_STUB", function()
    print( "net shutdown" )
    net.start( "CC:T.STATUS" )
    net.writeBool( false )
    net.send()
end )
hook.add( "CC:T.BOOT", "CC:T.CL_STUB", function()
    print( "net boot" )
    net.start( "CC:T.STATUS" )
    net.writeBool( true )
    net.send()
end )

timer.create( "NET_QUEUE", 0.05, 0, function()
    if #NET_QUEUE < 1 then return end
    local canSend = {}
    local avail = net.getBytesLeft() - 100

    for i, v in ipairs( NET_QUEUE ) do
        if type( v ) == "table" then
            v.n = v.n or #v
            v = bit.tableToString( v )
            NET_QUEUE[i] = v
        end
        if avail < #v then break end
        avail = avail - #v
        canSend[#canSend + 1] = v
        table.remove( NET_QUEUE, 1 )
    end
    if #canSend < 1 then return end

    -- print( "net queue", unpack( canSend ) )
    net.start( "CC:T.QUEUE" )
    net.writeUInt( #canSend, 10 )
    for i = 1, #canSend do
        net.writeUInt( #canSend[i], 10 )
        net.writeData( canSend[i], #canSend[i] )
    end
    net.send()
end )