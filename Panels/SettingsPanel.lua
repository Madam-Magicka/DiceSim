local DiceSim = _G.DiceSim
local Clamp = DiceSim.Utils.Clamp

local DEFAULT_FONT_SCALE = 1.00
local MIN_FONT_SCALE = 0.90
local MAX_FONT_SCALE = 1.20
local FONT_SCALE_STEP = 0.05
local MIN_FONT_SIZE = 8
local MAX_FONT_SIZE = 22

local DEFAULT_WINDOW_SCALE = 1.00
local MIN_WINDOW_SCALE = 0.85
local MAX_WINDOW_SCALE = 1.20
local WINDOW_SCALE_STEP = 0.05

local function RoundToStep(value, step)
    step = step or 1
    return math.floor((tonumber(value) or 0) / step + 0.5) * step
end

local function FormatPercent(value)
    return tostring(math.floor((tonumber(value) or 1) * 100 + 0.5)) .. "%"
end

function DiceSim:GetSettings()
    DiceSimDB = DiceSimDB or {}
    DiceSimDB.Settings = DiceSimDB.Settings or {}

    local settings = DiceSimDB.Settings
    settings.fontScale = Clamp(tonumber(settings.fontScale) or DEFAULT_FONT_SCALE, MIN_FONT_SCALE, MAX_FONT_SCALE)
    settings.windowScale = Clamp(tonumber(settings.windowScale) or DEFAULT_WINDOW_SCALE, MIN_WINDOW_SCALE, MAX_WINDOW_SCALE)
    return settings
end

function DiceSim:InitializeSettings()
    self:GetSettings()
end

function DiceSim:ApplyFontStringScale(fontString)
    if not fontString then
        return
    end

    if fontString.SetScale then
        fontString:SetScale(1)
    end

    if not fontString.GetFont or not fontString.SetFont then
        return
    end

    if not fontString.DiceSimBaseFont then
        local fontFile, fontSize, fontFlags = fontString:GetFont()
        if fontFile and fontSize then
            fontString.DiceSimBaseFont = {
                file = fontFile,
                size = fontSize,
                flags = fontFlags,
            }
        end
    end

    local base = fontString.DiceSimBaseFont
    if not base then
        return
    end

    local scale = self:GetSettings().fontScale or DEFAULT_FONT_SCALE
    local scaledSize = Clamp(math.floor((base.size * scale) + 0.5), MIN_FONT_SIZE, MAX_FONT_SIZE)
    pcall(fontString.SetFont, fontString, base.file, scaledSize, base.flags)
end

local function ApplyFontScaleToRegions(owner, frame, visited)
    if not frame or visited[frame] then
        return
    end

    visited[frame] = true
    if frame.SetScale then
        frame:SetScale(1)
    end

    if frame.GetRegions then
        for _, region in ipairs({ frame:GetRegions() }) do
            if region and region.GetObjectType and region:GetObjectType() == "FontString" then
                owner:ApplyFontStringScale(region)
            end
        end
    end

    if frame.GetChildren then
        for _, child in ipairs({ frame:GetChildren() }) do
            ApplyFontScaleToRegions(owner, child, visited)
        end
    end
end

function DiceSim:ApplyFontScale()
    local visited = {}

    for _, frame in ipairs({
        self.AddPanel,
        self.SessionPanel,
        self.DicePanel,
        self.SheetPanel,
        self.DMPanel,
        self.EventLogPanel,
        self.BuffDebuffPanel,
        self.IconPickerPanel,
        self.PortraitPickerPanel,
        self.PortraitRingPickerPanel,
        self.TutorialPanel,
        self.TutorialTour,
        self.SettingsPanel,
        self.RoundsTracker,
        self.DropdownMenu,
        self.DMRosterMenu,
    }) do
        ApplyFontScaleToRegions(self, frame, visited)
    end
end

function DiceSim:ApplyFontScaleToFrame(frame)
    ApplyFontScaleToRegions(self, frame, {})
end

function DiceSim:ApplyWindowScale()
    if self.Frame then
        self.Frame:SetScale(self:GetSettings().windowScale or DEFAULT_WINDOW_SCALE)
    end
end

function DiceSim:ApplySettings()
    self:ApplyWindowScale()
    self:ApplyFontScale()
    self:RefreshSettingsPanel()
end

function DiceSim:SetFontScale(value)
    local settings = self:GetSettings()
    settings.fontScale = Clamp(RoundToStep(value, FONT_SCALE_STEP), MIN_FONT_SCALE, MAX_FONT_SCALE)
    self:ApplySettings()
end

function DiceSim:SetWindowScale(value)
    local settings = self:GetSettings()
    settings.windowScale = Clamp(RoundToStep(value, WINDOW_SCALE_STEP), MIN_WINDOW_SCALE, MAX_WINDOW_SCALE)
    self:ApplySettings()
end

function DiceSim:ResetSettings()
    local settings = self:GetSettings()
    settings.fontScale = DEFAULT_FONT_SCALE
    settings.windowScale = DEFAULT_WINDOW_SCALE
    self:ApplySettings()
end

local function CreateSettingsSlider(panel, name, labelText, yOffset, minValue, maxValue, stepValue, formatter, onChanged)
    local label = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", panel, "TOPLEFT", 22, yOffset)
    label:SetText(labelText)

    local valueText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    valueText:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -22, yOffset)
    valueText:SetText(formatter(minValue))

    local slider = CreateFrame("Slider", name, panel, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", panel, "TOPLEFT", 28, yOffset - 28)
    slider:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -28, yOffset - 28)
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(stepValue)
    if slider.SetObeyStepOnDrag then
        slider:SetObeyStepOnDrag(true)
    end

    local sliderText = _G[name .. "Text"]
    local sliderLow = _G[name .. "Low"]
    local sliderHigh = _G[name .. "High"]
    if sliderText then sliderText:SetText("") end
    if sliderLow then sliderLow:SetText("") end
    if sliderHigh then sliderHigh:SetText("") end

    slider:SetScript("OnValueChanged", function(self, value)
        valueText:SetText(formatter(value))
        if self.DiceSimUpdating then
            return
        end
        onChanged(value)
    end)

    slider.ValueText = valueText
    return slider
end

function DiceSim:RefreshSettingsPanel()
    local panel = self.SettingsPanel
    if not panel then
        return
    end

    local settings = self:GetSettings()

    if panel.FontScaleSlider and not panel.FontScaleSlider.DiceSimUpdating then
        panel.FontScaleSlider.DiceSimUpdating = true
        panel.FontScaleSlider:SetValue(settings.fontScale)
        panel.FontScaleSlider.ValueText:SetText(FormatPercent(settings.fontScale))
        panel.FontScaleSlider.DiceSimUpdating = false
    end

    if panel.WindowScaleSlider and not panel.WindowScaleSlider.DiceSimUpdating then
        panel.WindowScaleSlider.DiceSimUpdating = true
        panel.WindowScaleSlider:SetValue(settings.windowScale)
        panel.WindowScaleSlider.ValueText:SetText(FormatPercent(settings.windowScale))
        panel.WindowScaleSlider.DiceSimUpdating = false
    end
end

function DiceSim:ToggleSettingsPanel()
    if self.IsMinimized then
        self:Expand()
    end

    self.SettingsPanel:SetShown(not self.SettingsPanel:IsShown())
    if self.SettingsPanel:IsShown() then
        self:RefreshSettingsPanel()
        self:BringWindowToFront(self.SettingsPanel)
    end
end

function DiceSim:CreateSettingsPanel(parent, anchor)
    local panel = CreatePanel(parent, "DiceSimSettingsPanel", 340, 250)
    panel.TutorialKey = "settings"
    panel:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -8)

    local closeButton = CreateTrayButton(panel, "DiceSimSettingsPanelCloseButton", "Interface\\Buttons\\UI-StopButton", "Exit")
    closeButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -10)
    WireCloseButton(closeButton, function()
        panel:Hide()
    end)

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    title:SetPoint("TOP", panel, "TOP", 0, -20)
    title:SetText("Settings")

    panel.FontScaleSlider = CreateSettingsSlider(
        panel,
        "DiceSimFontScaleSlider",
        "Font Size",
        -66,
        MIN_FONT_SCALE,
        MAX_FONT_SCALE,
        FONT_SCALE_STEP,
        FormatPercent,
        function(value)
            DiceSim:SetFontScale(value)
        end
    )

    panel.WindowScaleSlider = CreateSettingsSlider(
        panel,
        "DiceSimWindowScaleSlider",
        "Window Scale",
        -126,
        MIN_WINDOW_SCALE,
        MAX_WINDOW_SCALE,
        WINDOW_SCALE_STEP,
        FormatPercent,
        function(value)
            DiceSim:SetWindowScale(value)
        end
    )

    local resetButton = CreatePanelButton(panel, "Reset")
    resetButton:SetSize(82, 26)
    resetButton:SetPoint("BOTTOM", panel, "BOTTOM", 0, 18)
    FitPanelButtonLabel(resetButton)
    resetButton:SetScript("OnClick", function()
        DiceSim:ResetSettings()
    end)
    panel.ResetButton = resetButton

    self.SettingsPanel = panel
    panel:Hide()
    self:RefreshSettingsPanel()
    return panel
end
