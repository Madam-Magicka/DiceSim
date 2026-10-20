local DiceSim = _G.DiceSim

local DEFAULT_ATTRIBUTE_IDS = {
    STRENGTH = "str",
    DEXTERITY = "dex",
    CONSTITUTION = "con",
    INTELLIGENCE = "int",
    WISDOM = "wis",
    CHARISMA = "cha",
}

local function Trim(value)
    return string.match(tostring(value or ""), "^%s*(.-)%s*$")
end

local function LowerKey(value)
    value = Trim(value)
    if value == "" then
        return nil
    end

    return string.lower(value)
end

local function DecodeJson(text)
    text = tostring(text or "")
    local index = 1
    local length = #text

    local function fail(message)
        error(message .. " at character " .. index, 0)
    end

    local function peek()
        return string.sub(text, index, index)
    end

    local function skipWhitespace()
        while index <= length and string.match(peek(), "%s") do
            index = index + 1
        end
    end

    local parseValue

    local function parseString()
        if peek() ~= '"' then
            fail("Expected string")
        end

        index = index + 1
        local parts = {}

        while index <= length do
            local char = peek()
            if char == '"' then
                index = index + 1
                return table.concat(parts)
            elseif char == "\\" then
                index = index + 1
                local escaped = peek()
                local replacements = {
                    ['"'] = '"',
                    ["\\"] = "\\",
                    ["/"] = "/",
                    b = "\b",
                    f = "\f",
                    n = "\n",
                    r = "\r",
                    t = "\t",
                }
                if replacements[escaped] then
                    table.insert(parts, replacements[escaped])
                    index = index + 1
                elseif escaped == "u" then
                    local code = string.sub(text, index + 1, index + 4)
                    if not string.match(code, "^%x%x%x%x$") then
                        fail("Invalid unicode escape")
                    end
                    table.insert(parts, "?")
                    index = index + 5
                else
                    fail("Invalid escape")
                end
            else
                table.insert(parts, char)
                index = index + 1
            end
        end

        fail("Unterminated string")
    end

    local function parseNumber()
        local startIndex = index
        if peek() == "-" then
            index = index + 1
        end
        while index <= length and string.match(peek(), "%d") do
            index = index + 1
        end
        if peek() == "." then
            index = index + 1
            while index <= length and string.match(peek(), "%d") do
                index = index + 1
            end
        end
        local exponent = peek()
        if exponent == "e" or exponent == "E" then
            index = index + 1
            local sign = peek()
            if sign == "+" or sign == "-" then
                index = index + 1
            end
            while index <= length and string.match(peek(), "%d") do
                index = index + 1
            end
        end

        local number = tonumber(string.sub(text, startIndex, index - 1))
        if number == nil then
            fail("Invalid number")
        end

        return number
    end

    local function parseArray()
        index = index + 1
        local value = {}
        skipWhitespace()

        if peek() == "]" then
            index = index + 1
            return value
        end

        while true do
            table.insert(value, parseValue())
            skipWhitespace()
            local char = peek()
            if char == "]" then
                index = index + 1
                return value
            elseif char ~= "," then
                fail("Expected comma or closing bracket")
            end
            index = index + 1
        end
    end

    local function parseObject()
        index = index + 1
        local value = {}
        skipWhitespace()

        if peek() == "}" then
            index = index + 1
            return value
        end

        while true do
            skipWhitespace()
            local key = parseString()
            skipWhitespace()
            if peek() ~= ":" then
                fail("Expected colon")
            end
            index = index + 1
            value[key] = parseValue()
            skipWhitespace()
            local char = peek()
            if char == "}" then
                index = index + 1
                return value
            elseif char ~= "," then
                fail("Expected comma or closing brace")
            end
            index = index + 1
        end
    end

    function parseValue()
        skipWhitespace()
        local char = peek()

        if char == '"' then
            return parseString()
        elseif char == "{" then
            return parseObject()
        elseif char == "[" then
            return parseArray()
        elseif char == "-" or string.match(char, "%d") then
            return parseNumber()
        elseif string.sub(text, index, index + 3) == "true" then
            index = index + 4
            return true
        elseif string.sub(text, index, index + 4) == "false" then
            index = index + 5
            return false
        elseif string.sub(text, index, index + 3) == "null" then
            index = index + 4
            return nil
        end

        fail("Unexpected value")
    end

    local value = parseValue()
    skipWhitespace()
    if index <= length then
        fail("Unexpected trailing text")
    end

    return value
end

local function NormalizeAttribute(attribute, index)
    if type(attribute) == "string" then
        attribute = { label = attribute }
    elseif type(attribute) ~= "table" then
        return nil
    end

    local label = Trim(attribute.label or attribute.name or attribute.id or ("Attribute " .. index))
    if label == "" then
        return nil
    end

    return {
        id = LowerKey(attribute.id or attribute.key or label),
        label = label,
        default = tonumber(attribute.default or attribute.value) or CHARACTER_DEFAULT_STAT,
    }
end

local function NormalizeAction(action, index)
    if type(action) == "string" then
        action = { label = action }
    elseif type(action) ~= "table" then
        return nil
    end

    local label = Trim(action.label or action.name or action.id or ("Action " .. index))
    if label == "" then
        return nil
    end

    return {
        id = LowerKey(action.id or action.key or label) or ("action_" .. index),
        label = label,
        attribute = action.attribute or action.stat or action.ability,
        dice = action.dice or action.roll or action.diceType,
        effectDice = action.effectDice or action.effect or action.damage,
        modifier = action.modifier,
        imported = true,
    }
end

function DiceSim:GetDefaultActionOptions()
    local children = {}

    for _, attribute in ipairs(self.ATTRIBUTE_ACTION_TREE or {}) do
        local label = attribute.shortLabel or string.upper(DEFAULT_ATTRIBUTE_IDS[attribute.label] or attribute.label or "")
        if label ~= "" then
            local actionChildren = {}

            for _, action in ipairs(attribute.actions or {}) do
                table.insert(actionChildren, {
                    label = action,
                    value = "default:" .. string.lower(label) .. ":" .. string.lower(string.gsub(action, "%s+", "_")),
                    actionData = {
                        id = string.lower(string.gsub(action, "%s+", "_")),
                        label = action,
                        attribute = label,
                        dice = "D20",
                        imported = false,
                    },
                })
            end

            table.insert(children, {
                label = label,
                value = "default:" .. string.lower(label),
                children = actionChildren,
            })
        end
    end

    return children
end

function DiceSim:GetImportedDiceSystem()
    if not DiceSimDB then
        return nil
    end

    return DiceSimDB.ImportedDiceSystem
end

function DiceSim:GetImportedAttributes()
    local system = self:GetImportedDiceSystem()
    local attributes = {}

    if not system or type(system.attributes) ~= "table" then
        return attributes
    end

    for index, attribute in ipairs(system.attributes) do
        local normalized = NormalizeAttribute(attribute, index)
        if normalized then
            table.insert(attributes, normalized)
        end
    end

    return attributes
end

function DiceSim:GetImportedActions()
    local system = self:GetImportedDiceSystem()
    local actions = {}

    if not system then
        return actions
    end

    if type(system.actions) == "table" then
        for index, action in ipairs(system.actions) do
            local normalized = NormalizeAction(action, index)
            if normalized then
                table.insert(actions, normalized)
            end
        end
    end

    if type(system.attributes) == "table" then
        for _, attribute in ipairs(system.attributes) do
            if type(attribute) == "table" and type(attribute.actions) == "table" then
                local parent = NormalizeAttribute(attribute, 1)
                for _, action in ipairs(attribute.actions) do
                    local normalized = NormalizeAction(action, #actions + 1)
                    if normalized then
                        normalized.attribute = normalized.attribute or (parent and (parent.id or parent.label))
                        table.insert(actions, normalized)
                    end
                end
            end
        end
    end

    return actions
end

function DiceSim:GetActionOptions()
    local options = {
        {
            label = "Default",
            value = "default",
            children = self:GetDefaultActionOptions(),
        },
    }

    local importedChildren = {}
    for _, action in ipairs(self:GetImportedActions()) do
        table.insert(importedChildren, {
            label = action.label,
            value = "imported:" .. action.id,
            actionData = action,
        })
    end

    table.insert(options, {
        label = "Imported",
        value = "imported",
        children = importedChildren,
    })

    return options
end

function DiceSim:GetAffectAppliesOptions()
    local options = {
        {
            label = "General",
            value = "general",
            children = {
                { label = "All Rolls", value = "All Rolls" },
            },
        },
    }

    for _, group in ipairs(self:GetActionOptions()) do
        table.insert(options, group)
    end

    return options
end

function DiceSim:GetActionDataByValue(value, selectedOption)
    if type(selectedOption) == "table" and selectedOption.actionData then
        return selectedOption.actionData
    end

    local function findAction(options)
        for _, option in ipairs(options or {}) do
            if option.value == value then
                return option.actionData
            end
            local childAction = findAction(option.children)
            if childAction then
                return childAction
            end
        end
    end

    for _, group in ipairs(self:GetActionOptions()) do
        local actionData = findAction(group.children)
        if actionData then
            return actionData
        end
    end

    return {
        label = tostring(value or "Action"),
        attribute = value,
        dice = "D20",
    }
end

function DiceSim:GetSheetAttributeValue(attribute)
    if not attribute or not self.SheetPanel then
        return nil
    end

    local key = LowerKey(attribute)
    for _, row in ipairs(self.SheetPanel.StatRows or {}) do
        local name = row.NameInput and row.NameInput:GetText() or ""
        if LowerKey(name) == key then
            return tonumber(row.ValueInput and row.ValueInput:GetText()) or 0, name
        end
    end

    for _, importedAttribute in ipairs(self:GetImportedAttributes()) do
        if importedAttribute.id == key and importedAttribute.label then
            return self:GetSheetAttributeValue(importedAttribute.label)
        end
    end

    return nil
end

function DiceSim:CalculateActionModifier(actionData)
    if not actionData then
        return 0, nil
    end

    if actionData.modifier ~= nil then
        return tonumber(actionData.modifier) or 0, nil
    end

    local value, label = self:GetSheetAttributeValue(actionData.attribute)
    if value == nil then
        return 0, nil
    end

    if not actionData.imported then
        return 0, nil
    end

    local system = self:GetImportedDiceSystem()
    local modifier = system and system.modifier or nil
    if not modifier then
        return 0, nil
    end

    local mode = type(modifier) == "table" and modifier.mode or "raw"

    if mode == "none" then
        return 0, label
    elseif mode == "floor" then
        local subtract = tonumber(modifier.subtract) or 0
        local divide = tonumber(modifier.divide) or 1
        return math.floor((value - subtract) / divide), label
    elseif mode == "table" and type(modifier.values) == "table" then
        local mapped = modifier.values[tostring(value)] or modifier.values[value]
        return tonumber(mapped) or 0, label
    end

    return value, label
end

function DiceSim:ApplyActionSelection(field, value, option)
    local actionData = self:GetActionDataByValue(value, option)
    field.SelectedActionData = actionData

    if actionData.dice and self.DiceTypeField then
        self.DiceTypeField.Value = actionData.dice
        self.DiceTypeField.Label:SetText(actionData.dice)
    end

    if actionData.effectDice and self.EffectDiceField then
        self.EffectDiceField.Value = actionData.effectDice
        self.EffectDiceField.Label:SetText(actionData.effectDice)
    end

    local modifier = self:CalculateActionModifier(actionData)
    if self.ModifierInput then
        self.ModifierInput:SetText(tostring(modifier or 0))
    end
end

function DiceSim:RefreshDiceActionDropdowns()
    local options = self:GetActionOptions()

    if self.ActionField then
        self.ActionField.Options = options
    end

    if self.CanvasActionDropdowns then
        for _, dropdown in ipairs(self.CanvasActionDropdowns) do
            dropdown.Options = options
        end
    end
end

function DiceSim:GetImportedDiceSystemName()
    local system = self:GetImportedDiceSystem()
    if not system then
        return nil
    end

    return Trim(system.name or system.title or "Imported")
end

local function GetMetricDefault(config, fallbackValue, fallbackMax)
    if type(config) == "number" then
        return config, fallbackMax
    end

    if type(config) ~= "table" then
        return fallbackValue, fallbackMax
    end

    local value = tonumber(config.value or config.current or config.default or config.base) or fallbackValue
    local maximum = tonumber(config.max or config.maximum or config.defaultMax) or fallbackMax
    return value, maximum
end

function DiceSim:ApplyDiceSystemSheetDefaults()
    local system = self:GetImportedDiceSystem()
    local defaultHp, defaultHpMax = self:GetDefaultSheetMetric("hp")
    local defaultEnergy, defaultEnergyMax = self:GetDefaultSheetMetric("energy")
    local defaultArmor, defaultArmorMax = self:GetDefaultSheetMetric("armor")

    if system then
        self:SetSheetPointBudget(system.pointBudget or system.points or CHARACTER_POINT_BUDGET)

        local metrics = type(system.metrics) == "table" and system.metrics or system
        local hp, hpMax = GetMetricDefault(metrics.hp, defaultHp, defaultHpMax)
        local energy, energyMax = GetMetricDefault(metrics.energy, defaultEnergy, defaultEnergyMax)
        local armor, armorMax = GetMetricDefault(metrics.armor, defaultArmor, defaultArmorMax)

        self:SetSheetMetricValue("hp", hp, hpMax)
        self:SetSheetMetricValue("energy", energy, energyMax)
        self:SetSheetMetricValue("armor", armor, armorMax)
    else
        self:SetSheetPointBudget(CHARACTER_POINT_BUDGET)
        self:SetSheetMetricValue("hp", defaultHp, defaultHpMax)
        self:SetSheetMetricValue("energy", defaultEnergy, defaultEnergyMax)
        self:SetSheetMetricValue("armor", defaultArmor, defaultArmorMax)
    end

    if self.RefreshSheetSystemStatus then
        self:RefreshSheetSystemStatus()
    end

    if self.RefreshSheetMath then
        self:RefreshSheetMath()
    end
end

function DiceSim:RebuildSheetAttributesFromDiceSystem()
    if not self.SheetPanel or not self.SheetPanel.ClearAttributeRows then
        return
    end

    local existing = {}
    for _, row in ipairs(self.SheetPanel.StatRows or {}) do
        local name = row.NameInput and row.NameInput:GetText() or ""
        if name ~= "" then
            existing[LowerKey(name)] = tonumber(row.ValueInput and row.ValueInput:GetText()) or CHARACTER_STAT_MIN
        end
    end

    self.SheetPanel:ClearAttributeRows()

    local importedAttributes = self:GetImportedAttributes()
    if #importedAttributes > 0 then
        for _, attribute in ipairs(importedAttributes) do
            local value = existing[LowerKey(attribute.label)] or existing[attribute.id] or attribute.default or CHARACTER_DEFAULT_STAT
            self.SheetPanel:AddAttributeRow(attribute.label, value)
        end
    else
        for _, stat in ipairs(CHARACTER_STATS) do
            self.SheetPanel:AddAttributeRow(stat, existing[LowerKey(stat)] or CHARACTER_DEFAULT_STAT)
        end
    end

    self:RefreshSheetMath()
end

function DiceSim:ImportDiceSystemJson(text)
    local ok, data = pcall(DecodeJson, text)
    if not ok then
        return false, data
    end

    if type(data) ~= "table" then
        return false, "Top-level JSON must be an object."
    end

    DiceSimDB = DiceSimDB or {}
    DiceSimDB.ImportedDiceSystem = data

    self:RebuildSheetAttributesFromDiceSystem()
    self:ApplyDiceSystemSheetDefaults()
    if self.SaveCurrentSheetData then
        self:SaveCurrentSheetData()
    end
    self:RefreshDiceActionDropdowns()
    if self.BroadcastSheetState then
        self:BroadcastSheetState()
    end
    return true
end

function DiceSim:ResetImportedDiceSystem()
    DiceSimDB = DiceSimDB or {}
    DiceSimDB.ImportedDiceSystem = nil

    self:RebuildSheetAttributesFromDiceSystem()
    self:ApplyDiceSystemSheetDefaults()
    if self.SaveCurrentSheetData then
        self:SaveCurrentSheetData()
    end
    self:RefreshDiceActionDropdowns()
    if self.BroadcastSheetState then
        self:BroadcastSheetState()
    end
end
