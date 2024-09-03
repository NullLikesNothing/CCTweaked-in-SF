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
rs.getAnalogueInput = rs.getAnalogInput

-- too lazy to implement bundled cables
local function nopnil() end
local function nopzero() return 0 end
rs.setBundledOutput = nopnil
rs.getBundledOutput = nopzero
rs.getBundledInput = nopzero
rs.testBundledInput = nopzero

function rs.getSides()
    return {
        "bottom", "top",
        "left", "right",
        "front", "back",
    }
end

return rs
