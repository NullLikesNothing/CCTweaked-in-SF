local settings = {}

local _sets = {}
local _usets = {}

function settings.define( name, opt )
    expect( 1, name, "string" )
    expect( 2, opt, "table", "nil" )
    opt = opt or {}
    if opt.type ~= nil then
        field( opt, "type", "string" )
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

return settings
