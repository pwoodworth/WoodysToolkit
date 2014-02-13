ViewportOverlay = WorldFrame:CreateTexture(nil, "BACKGROUND")
ViewportOverlay:SetTexture(0, 0, 0, 1)
ViewportOverlay:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -1, 1)
ViewportOverlay:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 1, -1)

-- Configuration
local top = 0 -- Pixels from top
local bottom = 200 -- Pixels from bottom
local left = 0 -- Pixels from left
local right = 0 -- Pixels from right

local curResString = ({GetScreenResolutions()})[GetCurrentResolution()]
print('The current screen resolution is ' .. curResString)
for token in string.gmatch(curResString, "[^x]+") do
    print(token)
end

for k, v in string.gmatch(curResString, "(%w+)x(%w+)") do
    print("w="..k.." h="..v)
end

-- Your current Y resolution (e.g. 1920x1080, Y = 1080)
local currentYResolution = 1200
-- End configuration

local scaling = 768 / currentYResolution

WorldFrame:SetPoint("TOPLEFT", (left * scaling), -(top * scaling))
WorldFrame:SetPoint("BOTTOMRIGHT", -(right * scaling), (bottom * scaling))
