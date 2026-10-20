local DiceSim = _G.DiceSim

local ICON_SIZE = 58
local ICON_GAP = 8
local COLUMN_COUNT = 5
local DEFAULT_RING = "hud-PlayerFrame-portraitring-large"

local NORMAL_SIZE_RINGS = {
    [DEFAULT_RING] = true,
    ["communities-ring-gold"] = true,
    ["communities-ring-blue"] = true,
    ["majorfaction-celebration-content-ring"] = true,
    ["CovenantChoice-Offering-Ability-Ring-Kyrian"] = true,
    ["CovenantChoice-Offering-Ability-Ring-Necrolord"] = true,
    ["CovenantChoice-Offering-Ability-Ring-NightFae"] = true,
    ["CovenantChoice-Offering-Ability-Ring-Venthyr"] = true,
    ["Azerite-Trait-Ring-Open"] = true,
    ["Talent-RingWithDot"] = true,
}

function DiceSim:GetPortraitRingDisplaySize(atlas, baseSize)
    atlas = tostring(atlas or "")
    baseSize = baseSize or 48

    if string.find(atlas, "UI%-Frame%-jailerstower%-Portrait") then
        return math.floor(baseSize * 1.50)
    end

    if string.find(atlas, "pet%-list_") then
        return math.floor(baseSize * 1.25)
    end

    if string.find(atlas, "footer_") then
        return math.floor(baseSize * 1.20)
    end

    if NORMAL_SIZE_RINGS[atlas] then
        return baseSize
    end

    return math.floor(baseSize * 1.60)
end

function DiceSim:IsPortraitRingBehindPortrait(atlas)
    atlas = tostring(atlas or "")
    return string.find(atlas, "UI%-Frame%-jailerstower%-Portrait") ~= nil
end

function DiceSim:ApplyPortraitRingTexture(texture, atlas, baseSize)
    if not texture then
        return
    end

    atlas = atlas or DEFAULT_RING
    self:ApplyTextureOrAtlas(texture, atlas)
    local size = self:GetPortraitRingDisplaySize(atlas, baseSize)
    texture:SetSize(size, size)
    if texture.SetDrawLayer then
        texture:SetDrawLayer(self:IsPortraitRingBehindPortrait(atlas) and "BORDER" or "OVERLAY")
    end
end

function DiceSim:GetSheetPortraitRing()
    if self.SheetPanel and self.SheetPanel.Unit ~= "player" then
        local key = self.GetUnitSheetSyncKey and self:GetUnitSheetSyncKey(self.SheetPanel.Unit)
        local remote = key and self.GetRemoteSheetStore and self:GetRemoteSheetStore()[key]
        return remote and remote.portraitRing or DEFAULT_RING
    end

    DiceSimDB = DiceSimDB or {}
    return DiceSimDB.SheetPortraitRing or DEFAULT_RING
end

function DiceSim:SetSheetPortraitRing(atlas, shouldBroadcast)
    atlas = atlas or DEFAULT_RING
    DiceSimDB = DiceSimDB or {}
    DiceSimDB.SheetPortraitRing = atlas

    if self.SheetPanel and self.SheetPanel.PortraitRing then
        self:ApplyPortraitRingTexture(self.SheetPanel.PortraitRing, atlas, 112)
    end

    if self.RefreshCharacterTabs then
        self:RefreshCharacterTabs()
    end

    if self.SaveCurrentSheetData then
        self:SaveCurrentSheetData()
    end

    if shouldBroadcast and self.BroadcastSheetState then
        self:BroadcastSheetState()
    end
end

function DiceSim:CreatePortraitRingPickerPanel(parent)
    local panel = CreatePanel(parent, "DiceSimPortraitRingPickerPanel", 430, 560)
    panel.TutorialKey = "portraitRingPicker"
    panel:SetPoint("CENTER", parent, "CENTER", 0, 0)

    local closeButton = CreateTrayButton(panel, "DiceSimPortraitRingPickerCloseButton", "Interface\\Buttons\\UI-StopButton", "Exit")
    closeButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -10)
    WireCloseButton(closeButton, function()
        panel:Hide()
    end)

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    title:SetPoint("TOP", panel, "TOP", 0, -18)
    title:SetText("Choose Portrait Ring")

    local grid = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    grid:SetPoint("TOP", title, "BOTTOM", 0, -18)
    local rowCount = math.ceil(#(PORTRAIT_RING_OPTIONS or {}) / COLUMN_COUNT)
    grid:SetSize((ICON_SIZE * COLUMN_COUNT) + (ICON_GAP * (COLUMN_COUNT - 1)) + 16, (ICON_SIZE * rowCount) + (ICON_GAP * math.max(0, rowCount - 1)) + 16)
    DiceSim:ApplyBackdrop(grid, DiceSim.Theme.colors.insetBg, DiceSim.Theme.colors.insetBorder, 1)
    panel.Grid = grid
    panel.Buttons = {}

    for index, option in ipairs(PORTRAIT_RING_OPTIONS or {}) do
        local button = CreateFrame("Button", nil, grid, "BackdropTemplate")
        button:SetSize(ICON_SIZE, ICON_SIZE)
        DiceSim:ApplyBackdrop(button, DiceSim.Theme.colors.controlBg, DiceSim.Theme.colors.controlBorder, 1)

        local texture = button:CreateTexture(nil, "ARTWORK")
        texture:SetPoint("CENTER")
        DiceSim:ApplyPortraitRingTexture(texture, option.value, ICON_SIZE - 10)
        button.Icon = texture
        button.RingAtlas = option.value
        button.RingLabel = option.label

        local column = (index - 1) % COLUMN_COUNT
        local row = math.floor((index - 1) / COLUMN_COUNT)
        button:SetPoint("TOPLEFT", grid, "TOPLEFT", 8 + (column * (ICON_SIZE + ICON_GAP)), -8 - (row * (ICON_SIZE + ICON_GAP)))

        button:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(unpack(DiceSim.Theme.colors.controlBorderHover))
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(self.RingLabel or "Portrait Ring")
            GameTooltip:Show()
        end)

        button:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(unpack(DiceSim.Theme.colors.controlBorder))
            GameTooltip:Hide()
        end)

        button:SetScript("OnClick", function(self)
            DiceSim:SetSheetPortraitRing(self.RingAtlas, true)
            panel:Hide()
        end)

        panel.Buttons[index] = button
    end

    self.PortraitRingPickerPanel = panel
    return panel
end

function DiceSim:OpenPortraitRingPicker()
    if not self.PortraitRingPickerPanel then
        self:CreatePortraitRingPickerPanel(self.Frame)
    end

    self.PortraitRingPickerPanel:Show()
    self:BringWindowToFront(self.PortraitRingPickerPanel)
end
