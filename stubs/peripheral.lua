local peripheral = {}

local expect = require( "expect" ).expect

-- in the future
local peripherals = {}

local t_getKeys = table.getKeys
local pairs = pairs

function peripheral.getNames()
    return t_getKeys( peripherals )
end
function peripheral.isPresent( name )
    expect( 1, name, "string" )
    return peripherals[name] ~= nil
end

return peripheral