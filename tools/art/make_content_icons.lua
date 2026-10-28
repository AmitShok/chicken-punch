-- Generates icons for the October 2026 content update into assets/Coop/.
-- Each icon is saved as an editable .aseprite and an exported .png.
-- Run from the project root:
--   aseprite -b --script tools/art/make_content_icons.lua

local PACK = "assets/Ninja Adventure - Asset Pack/"
local OUT = "assets/Coop/"
local pc = app.pixelColor

local function rgb(hex)
  return pc.rgba(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16), 255)
end

local function save(img, name)
  local spr = Sprite(img.width, img.height, ColorMode.RGB)
  spr.cels[1].image = img
  spr:saveAs(OUT .. name .. ".aseprite")
  spr:saveCopyAs(OUT .. name .. ".png")
  spr:close()
end

local function load_image(path, x, y, w, h)
  local spr = app.open(path)
  local full = Image(spr.width, spr.height, ColorMode.RGB)
  full:drawSprite(spr, 1)
  spr:close()
  local img = Image(w or full.width, h or full.height, ColorMode.RGB)
  img:drawImage(full, Point(-(x or 0), -(y or 0)))
  return img
end

-- Tomes reuse the existing book template: outline, brown border, coloured cover, cream symbol.
local TOME = {
  "................",
  "...AAAAAAAAAA...",
  "..ABBBBBBBBBA...",
  "..ABCCCCCCCBA...",
  "..ABCCCCCCCBA...",
  "..ABCCCCCCCBA...",
  "..ABCCCCCCCBA...",
  "..ABCCCCCCCBA...",
  "..ABCCCCCCCBA...",
  "..ABCCCCCCCBA...",
  "..ABBBBBBBBBA...",
  "..AADDDDDDDAA...",
  "..ADDDDDDDDDA...",
  "...AAAAAAAAAA...",
  "................",
  "................",
}
local SYMBOLS = {
  luck = { ".DDD.", "D...D", "D...D", "D...D", "D...D" },     -- horseshoe
  thorns = { "D.D.D", ".DDD.", "DDDDD", ".DDD.", "D.D.D" },   -- bramble
  evasion = { "....D", "...DD", "..DD.", ".DD..", "D...." }, -- feather stroke
  greed = { ".DDD.", "D.D..", ".DDD.", "..D.D", ".DDD." },    -- coin mark
}
local COVERS = { luck = "4f9a4a", thorns = "6f4a7a", evasion = "4a86b8", greed = "c9902b" }

for key, symbol in pairs(SYMBOLS) do
  local img = Image(16, 16, ColorMode.RGB)
  local palette = { A = rgb("49352f"), B = rgb("986040"), C = rgb(COVERS[key]), D = rgb("f4d892") }
  for y = 1, 16 do
    for x = 1, 16 do
      local ch = TOME[y]:sub(x, x)
      if palette[ch] then img:drawPixel(x - 1, y - 1, palette[ch]) end
    end
  end
  for y = 1, 5 do
    for x = 1, 5 do
      if symbol[y]:sub(x, x) == "D" then img:drawPixel(4 + x, 3 + y, palette.D) end
    end
  end
  save(img, "tome_" .. key)
end

-- Stink Cloud: a green cloud with stink lines, drawn from overlapping circles.
local function cloud(fill, light, shade, outline)
  local img = Image(16, 16, ColorMode.RGB)
  local blobs = { { 6, 10, 3.2 }, { 9.5, 8, 3.6 }, { 11.5, 10.5, 2.6 }, { 4.5, 11, 2.4 } }
  local inside = function(x, y)
    for _, b in ipairs(blobs) do
      if (x - b[1]) ^ 2 + (y - b[2]) ^ 2 <= b[3] ^ 2 then return true end
    end
    return false
  end
  for y = 0, 15 do
    for x = 0, 15 do
      if inside(x, y) then
        local edge = not (inside(x - 1, y) and inside(x + 1, y) and inside(x, y - 1) and inside(x, y + 1))
        if edge then img:drawPixel(x, y, outline)
        elseif y >= 12 then img:drawPixel(x, y, shade)
        elseif y <= 7 and x <= 9 then img:drawPixel(x, y, light)
        else img:drawPixel(x, y, fill) end
      end
    end
  end
  for _, p in ipairs({ { 4, 1 }, { 5, 2 }, { 4, 3 }, { 5, 4 }, { 12, 2 }, { 13, 3 }, { 12, 4 } }) do
    img:drawPixel(p[1], p[2], light)
  end
  return img
end
save(cloud(rgb("6fa043"), rgb("a8d36a"), rgb("4b7a2e"), rgb("2c3a22")), "stink")

-- Evolved icons: recolour the base art and add a sparkle, like the existing evo_ icons.
local function recolour(img, hue, saturation)
  local out = Image(16, 16, ColorMode.RGB)
  local ox = math.floor((16 - img.width) / 2)
  local oy = math.floor((16 - img.height) / 2)
  for y = 0, img.height - 1 do
    for x = 0, img.width - 1 do
      local c = img:getPixel(x, y)
      if pc.rgbaA(c) > 0 then
        local col = Color(pc.rgbaR(c), pc.rgbaG(c), pc.rgbaB(c))
        -- Keep dark outlines; shift everything else to the evolution colour.
        if col.value > 0.3 then
          col = Color { hue = hue, saturation = saturation, value = math.min(1, col.value * 1.05) }
        end
        out:drawPixel(ox + x, oy + y, pc.rgba(col.red, col.green, col.blue, 255))
      end
    end
  end
  local spark = rgb("fff7df")
  for _, p in ipairs({ { 13, 1 }, { 12, 2 }, { 13, 2 }, { 14, 2 }, { 13, 3 } }) do
    out:drawPixel(p[1], p[2], spark)
  end
  return out
end
save(recolour(load_image(PACK .. "Items/Weapons/Fork/Sprite.png"), 2, 0.75), "evo_pitchfork")
save(recolour(load_image(PACK .. "Items/Food/SeedBig1.png"), 45, 0.7), "evo_carrot")
save(recolour(cloud(rgb("6fa043"), rgb("a8d36a"), rgb("4b7a2e"), rgb("2c3a22")), 285, 0.45), "evo_stink")
print("icons written")
