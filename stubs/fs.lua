local expect, field
do
    local exp = require( "expect" )
    expect = exp.expect
    field = exp.field
end

local function mkdir()
    return {
        t = "d",
        f = {},
    }
end

local fsys = ...
local t_concat = table.concat
local ss = bit.stringstream
local s_bw = string.startWith
local spt = string.split

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

    return t
end

return fs
