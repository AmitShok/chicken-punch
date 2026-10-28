-- Crops one sprite from the UI layer of the Travel Book Lite Aseprite source.
-- The pack's source contains sprites (such as Banner) that it does not ship as PNGs.
-- aseprite -b assets/ui/travel_book/Aseprite/TravelBookLite.aseprite --script-param x=60 --script-param y=200
--   --script-param w=235 --script-param h=45 --script-param out=assets/ui/travel_book/Derived/UI_TravelBook_Banner01a.png
--   --script tools/art/extract_travel_book.lua
local spr = app.activeSprite
local p = app.params
local rx, ry, rw, rh = tonumber(p.x), tonumber(p.y), tonumber(p.w), tonumber(p.h)
local img = Image(spr.width, spr.height, spr.colorMode)
for _, layer in ipairs(spr.layers) do
  if layer.name == "UI" then
    local cel = layer:cel(1)
    if cel then img:drawImage(cel.image, cel.position) end
  end
end
local minx, miny, maxx, maxy = 1e9, 1e9, -1, -1
for y = ry, ry + rh - 1 do
  for x = rx, rx + rw - 1 do
    if app.pixelColor.rgbaA(img:getPixel(x, y)) > 0 then
      if x < minx then minx = x end
      if y < miny then miny = y end
      if x > maxx then maxx = x end
      if y > maxy then maxy = y end
    end
  end
end
local out = Image(maxx - minx + 1, maxy - miny + 1, spr.colorMode)
out:drawImage(img, Point(-minx, -miny))
out:saveAs(p.out)
print(minx, miny, maxx - minx + 1, maxy - miny + 1)
