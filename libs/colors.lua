-- Basic color library for `framebuffer`
colors = {}
colors.white     = 1
colors.orange    = 2
colors.magenta   = 4
colors.lightBlue = 8
colors.yellow    = 16
colors.lime      = 32
colors.pink      = 64
colors.gray      = 128
colors.lightGray = 256
colors.cyan      = 512
colors.purple    = 1024
colors.blue      = 2048
colors.brown     = 4096
colors.green     = 8192
colors.red       = 16384
colors.black     = 32768
colours = colors

function expect() end

local bit = table.copy( bit )
function colors.packRGB(r, g, b)
    expect(1, r, "number")
    expect(2, g, "number")
    expect(3, b, "number")
    return
        bit.band(r * 255, 0xFF) * 2 ^ 16 +
        bit.band(g * 255, 0xFF) * 2 ^ 8 +
        bit.band(b * 255, 0xFF)
end

function colors.unpackRGB(rgb)
    expect(1, rgb, "number")
    return
        bit.band(bit.arshift(rgb, 16), 0xFF) / 255,
        bit.band(bit.arshift(rgb, 8), 0xFF) / 255,
        bit.band(rgb, 0xFF) / 255
end

local packRGB = colors.packRGB
local unpackRGB = colors.unpackRGB
function colors.rgb8(r, g, b)
    if g == nil and b == nil then
        return unpackRGB(r)
    else
        return packRGB(r, g, b)
    end
end