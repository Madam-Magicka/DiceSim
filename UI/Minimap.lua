local DiceSim = _G.DiceSim

local MINIMAP_BUTTON_SIZE = 28
local MINIMAP_RADIUS = 104
local LOGO_TEXTURE = "Interface\\AddOns\\DiceSim\\UI\\BLPs\\DiceSimLogo.blp"

local function GetMinimapStore()
    DiceSimDB = DiceSimDB or {}
    DiceSimDB.Minimap = DiceSimDB.Minimap or {}
    if type(DiceSimDB.Minimap.angle) ~= "number" then
        DiceSimDB.Minimap.angle = 225
    end
    return DiceSimDB.Minimap
end

function DiceSim:SetMinimapButtonPosition(angle)
    local button = self.MinimapButton
    if not button or not Minimap then
        return
    end

    local store = GetMinimapStore()
    store.angle = angle or store.angle or 225

    local radians = math.rad(store.angle)
    local x = math.cos(radians) * MINIMAP_RADIUS
    local y = math.sin(radians) * MINIMAP_RADIUS

    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function DiceSim:UpdateMinimapButtonDragPosition()
    if not Minimap then
        return
    end

    local cursorX, cursorY = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    local centerX, centerY = Minimap:GetCenter()
    cursorX = cursorX / scale
    cursorY = cursorY / scale

    local angle = math.deg((math.atan2 or math.atan)(cursorY - centerY, cursorX - centerX))
    self:SetMinimapButtonPosition(angle)
end

function DiceSim:CreateMinimapButton()
    if self.MinimapButton or not Minimap then
        return self.MinimapButton
    end

    local button = CreateFrame("Button", "DiceSimMinimapButton", Minimap)
    button:SetSize(MINIMAP_BUTTON_SIZE, MINIMAP_BUTTON_SIZE)
    button:SetFrameStrata("MEDIUM")
    button:SetMovable(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(26, 26)
    icon:SetPoint("CENTER")
    icon:SetTexture(LOGO_TEXTURE)
    button.Icon = icon

    local mask = button:CreateMaskTexture()
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(icon)
    icon:AddMaskTexture(mask)

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetSize(30, 30)
    highlight:SetPoint("CENTER")
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    highlight:SetBlendMode("ADD")

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            if DiceSim.SettingsPanel then
                DiceSim:ToggleSettingsPanel()
            end
            return
        end

        DiceSim:Toggle()
    end)

    button:SetScript("OnDragStart", function()
        button.IsDragging = true
        button:SetScript("OnUpdate", function()
            DiceSim:UpdateMinimapButtonDragPosition()
        end)
    end)

    button:SetScript("OnDragStop", function()
        button.IsDragging = false
        button:SetScript("OnUpdate", nil)
        DiceSim:UpdateMinimapButtonDragPosition()
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("DiceSim")
        GameTooltip:AddLine("Left-click to toggle DiceSim.", 1, 1, 1)
        GameTooltip:AddLine("Right-click for settings.", 1, 1, 1)
        GameTooltip:AddLine("Drag to move.", 0.75, 0.75, 0.75)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    self.MinimapButton = button
    self:SetMinimapButtonPosition(GetMinimapStore().angle)
    return button
end
