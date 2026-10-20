local DiceSim = _G.DiceSim

DiceSim.Utils = DiceSim.Utils or {}

local function Clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end

    if value > maximum then
        return maximum
    end

    return value
end

DiceSim.Utils.Clamp = Clamp

function DiceSim:GetPlayerRollContext()
    if self.SheetPanel and (self.SheetPanel.Unit == "player" or not self.SheetPanel.Unit) then
        return self.SheetPanel
    end

    return nil
end

function DiceSim:CreatePlaceholderIcon(parent, index)
    local icon = CreateFrame("Button", nil, parent, "BackdropTemplate")
    icon:SetSize(26, 26)
    self:ApplyBackdrop(icon, self.Theme.colors.controlBg, self.Theme.colors.controlBorder, 1)

    local texture = icon:CreateTexture(nil, "ARTWORK")
    texture:SetPoint("CENTER")
    texture:SetSize(20, 20)
    texture:SetTexture(index % 2 == 0 and "Interface\\Icons\\Spell_Holy_Renew" or "Interface\\Icons\\Spell_Shadow_CurseOfTounges")
    icon.Texture = texture

    return icon
end

function CreatePlaceholderIcon(...)
    return DiceSim:CreatePlaceholderIcon(...)
end

function DiceSim:GetMacroIconLabel(icon, data)
    if type(data) == "table" then
        local label = data.name or data.label or data.text or data.tooltip or data.iconName
        if label and label ~= "" then
            return tostring(label)
        end
    end

    if type(icon) == "number" and C_Texture and C_Texture.GetFilenameFromFileDataID then
        local ok, path = pcall(C_Texture.GetFilenameFromFileDataID, icon)
        if ok and path and path ~= "" then
            local basename = string.match(path, "([^\\/]+)$") or path
            basename = string.gsub(basename, "%.%w+$", "")
            basename = string.gsub(basename, "[_%-%s]+", " ")
            return basename
        end
    end

    if type(icon) == "string" then
        local basename = string.match(icon, "([^\\/]+)$") or icon
        basename = string.gsub(basename, "%.%w+$", "")
        basename = string.gsub(basename, "[_%-%s]+", " ")
        return basename
    end

    return tostring(icon)
end

function DiceSim:GetMacroIconList(limit)
    if self.MacroIconCatalog and not limit then
        return self.MacroIconCatalog
    end

    local options = {}
    local seen = {}
    local maximum = limit or 5000

    local function addIcon(icon, data)
        if not icon or seen[icon] or #options >= maximum then
            return
        end

        seen[icon] = true
        local label = self:GetMacroIconLabel(icon, data)
        table.insert(options, {
            label = label,
            keywords = string.lower(label .. " " .. tostring(icon)),
            icon = icon,
            value = icon,
        })
    end

    local function extractIcon(value)
        if type(value) == "number" or type(value) == "string" then
            return value
        end

        if type(value) ~= "table" then
            return nil
        end

        return value.icon
            or value.iconFileID
            or value.iconFileId
            or value.iconID
            or value.iconId
            or value.fileDataID
            or value.fileDataId
            or value.fileID
            or value.fileId
            or value.texture
            or value.textureFileID
            or value.textureFileId
            or value.iconTexture
            or value.iconTextureFileID
            or value.iconTextureFileId
    end

    local function appendIcons(value, depth)
        if #options >= maximum then
            return
        end

        local icon = extractIcon(value)
        if icon then
            addIcon(icon, value)
            return
        end

        if type(value) ~= "table" or (depth or 0) > 4 then
            return
        end

        for _, child in pairs(value) do
            appendIcons(child, (depth or 0) + 1)
            if #options >= maximum then
                return
            end
        end
    end

    local icons
    if C_Macro and C_Macro.GetMacroIcons then
        local ok, result = pcall(C_Macro.GetMacroIcons)
        if ok then
            icons = result
        end
    elseif GetMacroIcons then
        local ok, result = pcall(function()
            return { GetMacroIcons() }
        end)
        if ok then
            icons = result
        end
    end

    appendIcons(icons)

    if #options < maximum then
        local itemIcons
        if C_Macro and C_Macro.GetMacroItemIcons then
            local ok, result = pcall(C_Macro.GetMacroItemIcons)
            if ok then
                itemIcons = result
            end
        elseif GetMacroItemIcons then
            local ok, result = pcall(function()
                return { GetMacroItemIcons() }
            end)
            if ok then
                itemIcons = result
            end
        end

        appendIcons(itemIcons)
    end

    if #options == 0 then
        for index, option in ipairs(FALLBACK_AFFECT_ICON_OPTIONS) do
            if #options >= maximum then
                break
            end

            table.insert(options, {
                label = option.label,
                icon = option.icon,
                value = option.icon,
            })
        end
    end

    if not limit then
        self.MacroIconCatalog = options
    end

    return options
end

function DiceSim:GetTargetOptions()
    local options = { { label = "None", value = nil } }
    local seen = {}

    local function addTarget(label, value)
        if not label or seen[label] then
            return
        end

        seen[label] = true
        table.insert(options, { label = label, value = value or label })
    end

    local playerName = UnitName and UnitName("player") or "Player"
    addTarget(playerName, playerName)

    if IsInRaid and IsInRaid() then
        for index = 1, 40 do
            local unit = "raid" .. index
            if UnitExists and UnitExists(unit) and UnitName then
                local name = UnitName(unit)
                addTarget(name, name)
            end
        end
    elseif IsInGroup and IsInGroup() then
        for index = 1, 4 do
            local unit = "party" .. index
            if UnitExists and UnitExists(unit) and UnitName then
                local name = UnitName(unit)
                addTarget(name, name)
            end
        end
    end

    if self.CharacterTabs then
        for _, tab in ipairs(self.CharacterTabs) do
            if tab:IsShown() then
                local unit = tab.Unit or "player"
                local name = UnitName and UnitName(unit) or unit
                addTarget(name, name)
            end
        end
    end

    if self.CanvasObjects then
        for _, object in ipairs(self.CanvasObjects) do
            if object:IsShown() and object.TargetName then
                addTarget(object.TargetName, object.TargetName)
            end
        end
    end

    return options
end

function DiceSim:RefreshDiceTargets()
    if not self.DiceTargetField then
        return
    end

    self.DiceTargetField.Options = self:GetTargetOptions()
end

function DiceSim:GetAttributeCost(value)
    value = Clamp(tonumber(value) or CHARACTER_STAT_MIN, CHARACTER_STAT_MIN, CHARACTER_STAT_MAX)
    return value
end

function DiceSim:GetDefaultSheetMetric(metric)
    local defaults = self.DEFAULT_SHEET_METRICS or DEFAULT_SHEET_METRICS or {}
    local config = defaults[metric] or {}
    local value = tonumber(config.value or config.current or config.default) or 0
    local maximum = tonumber(config.max or config.maximum or config.defaultMax) or value
    return value, maximum
end

function DiceSim:GetSheetPointBudget()
    DiceSimDB = DiceSimDB or {}
    if not DiceSimDB.ImportedDiceSystem and DiceSimDB.DefaultSheetVersion ~= DEFAULT_SHEET_VERSION then
        local savedBudget = tonumber(DiceSimDB.SheetPointBudget)
        if savedBudget == nil or savedBudget <= 27 then
            DiceSimDB.SheetPointBudget = CHARACTER_POINT_BUDGET
        end
        DiceSimDB.DefaultSheetVersion = DEFAULT_SHEET_VERSION
    end

    local budget = CHARACTER_POINT_BUDGET
    if DiceSimDB and DiceSimDB.SheetPointBudget then
        budget = tonumber(DiceSimDB.SheetPointBudget) or budget
    end
    return Clamp(math.floor(budget), 0, 999)
end

function DiceSim:SetSheetPointBudget(value)
    DiceSimDB = DiceSimDB or {}
    DiceSimDB.SheetPointBudget = Clamp(math.floor(tonumber(value) or CHARACTER_POINT_BUDGET), 0, 999)
    return DiceSimDB.SheetPointBudget
end

function DiceSim:AdjustSheetPointBudget(delta)
    if not self:CanEditSheet(self.SheetPanel and self.SheetPanel.Unit or "player") then
        return
    end
    self:SetSheetPointBudget(self:GetSheetPointBudget() + (tonumber(delta) or 0))
    self:RefreshSheetMath()
end

local function ParseSheetMetricValue(value, fallbackMax)
    local text = tostring(value or "")
    local currentText, maxText = string.match(text, "^%s*(%-?%d+)%s*/%s*(%d+)%s*$")
    local current = tonumber(currentText or text) or 0
    local maximum = tonumber(maxText) or tonumber(fallbackMax) or 100

    maximum = Clamp(math.floor(maximum), 0, 999)
    current = maximum > 0 and Clamp(math.floor(current), 0, maximum) or 0

    return current, maximum
end

function DiceSim:GetSheetMetricValue(metric)
    if not self.SheetPanel or not self.SheetPanel.MetricCounters then
        local value = self:GetDefaultSheetMetric(metric)
        return value
    end
    local counter = self.SheetPanel.MetricCounters[metric]
    if counter then
        return counter.Value
    end
    local value = self:GetDefaultSheetMetric(metric)
    return value
end

function DiceSim:GetSheetMetricMax(metric)
    if not self.SheetPanel or not self.SheetPanel.MetricCounters then
        local _, maximum = self:GetDefaultSheetMetric(metric)
        return maximum
    end
    local counter = self.SheetPanel.MetricCounters[metric]
    if counter then
        return counter.Max
    end
    local _, maximum = self:GetDefaultSheetMetric(metric)
    return maximum
end

function DiceSim:SetSheetMetricValue(metric, value, maximum)
    if not self.SheetPanel or not self.SheetPanel.MetricCounters then
        return
    end
    local counter = self.SheetPanel.MetricCounters[metric]
    if not counter then
        return
    end
    local current, parsedMax = ParseSheetMetricValue(value, maximum or counter.Max)
    counter.Value = current
    counter.Max = parsedMax
    if counter.Input then
        counter.Input:SetText(counter.Value .. "/" .. counter.Max)
    elseif counter.Text then
        counter.Text:SetText(counter.Value .. "/" .. counter.Max)
    end

    if metric == "hp" and self.RefreshCharacterTabs then
        self:RefreshCharacterTabs()
    end
    if self.SaveCurrentSheetData then
        self:SaveCurrentSheetData()
    end
end

function DiceSim:AdjustSheetMetric(metric, delta)
    if not self:CanEditSheet(self.SheetPanel and self.SheetPanel.Unit or "player") then
        return
    end
    self:SetSheetMetricValue(metric, self:GetSheetMetricValue(metric) + (tonumber(delta) or 0))
end

function DiceSim:RefreshSheetMath()
    if not self.SheetPanel then
        return
    end
    local stats = {}
    local spent = 0
    for _, row in ipairs(self.SheetPanel.StatRows or {}) do
        local statName = row.NameInput and row.NameInput:GetText() or ""
        local input = row.ValueInput
        local value = Clamp(tonumber(input and input:GetText()) or CHARACTER_STAT_MIN, CHARACTER_STAT_MIN, CHARACTER_STAT_MAX)
        if statName ~= "" then
            stats[statName] = value
        end
        spent = spent + self:GetAttributeCost(value)
    end
    local pointBudget = self:GetSheetPointBudget()
    local remaining = pointBudget - spent
    if remaining >= 0 then
        for _, row in ipairs(self.SheetPanel.StatRows or {}) do
            if row.ValueInput then
                row.ValueInput.LastValidValue = tostring(tonumber(row.ValueInput:GetText()) or CHARACTER_STAT_MIN)
            end
        end
    end
    if self.SheetPanel.PointBudgetText then
        local color = remaining < 0 and "|cffff6060" or "|cff9ee8a5"
        self.SheetPanel.PointBudgetText:SetText(color .. "Points: " .. remaining .. "/" .. pointBudget .. "|r")
    end
    self.SheetPanel.CurrentStats = stats
    self.SheetPanel.PointsSpent = spent
    if self.SaveCurrentSheetData then
        self:SaveCurrentSheetData()
    end
    if self.ScheduleSheetBroadcast then
        self:ScheduleSheetBroadcast()
    end
end

