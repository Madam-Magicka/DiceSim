local DiceSim = _G.DiceSim

function DiceSim:RollDiceExpression(diceType)
    local count, sides = string.match(string.lower(diceType or "d20"), "^(%d*)d(%d+)$")
    count = tonumber(count) or 1
    sides = tonumber(sides) or 20

    local total = 0
    local rolls = {}

    for index = 1, count do
        local roll = math.random(1, sides)
        total = total + roll
        rolls[index] = roll
    end

    return total, sides, count, rolls
end

function DiceSim:GetSignedNumber(value)
    value = tonumber(value) or 0

    if value >= 0 then
        return "+" .. value
    end

    return tostring(value)
end

function DiceSim:FormatDiceRoll(diceType, total, rolls)
    if rolls and #rolls > 1 then
        return diceType .. " = " .. total .. " (" .. table.concat(rolls, ", ") .. ")"
    end

    return diceType .. " = " .. total
end

function DiceSim:IsInitiativeAction(action)
    return string.find(string.lower(action or ""), "initiative", 1, true) ~= nil
end

function DiceSim:RollDice()
    local diceType = self.DiceTypeField and self.DiceTypeField.Value or "D20"
    local actionData = self.ActionField and self:GetActionDataByValue(self.ActionField.Value, self.ActionField.SelectedOption) or nil
    local action = actionData and actionData.label or "STR"
    local target = self.DiceTargetField and self.DiceTargetField.Value or "None"
    local modifier = 0

    if self.ModifierInput then
        modifier = tonumber(self.ModifierInput:GetText()) or 0
    end

    if self.CustomActionInput and self.CustomActionInput:GetText() ~= "" then
        action = self.CustomActionInput:GetText()
    end

    local roll, _, _, rolls = self:RollDiceExpression(diceType)
    local affectModifier = self:CollectAffectRollModifier(self:GetPlayerRollContext(), action)
    local total = roll + modifier + affectModifier.total
    local playerName = UnitName and UnitName("player") or "Player"
    local _, modifierAttribute = self:CalculateActionModifier(actionData)
    local modifierText = self:GetSignedNumber(modifier)
    if modifierAttribute then
        modifierText = modifierText .. " " .. modifierAttribute
    end
    local targetName = target or "None"
    local lines = {
        playerName .. " -> " .. targetName,
        "Action: " .. action,
        "Roll: " .. self:FormatDiceRoll(diceType, roll, rolls),
        "Modifier: " .. modifierText,
    }

    if affectModifier.total ~= 0 then
        table.insert(lines, "Buff/Debuff: " .. self:GetSignedNumber(affectModifier.total) .. " (" .. table.concat(affectModifier.parts, ", ") .. ")")
    end

    table.insert(lines, "Roll Total: " .. total)

    if self:IsInitiativeAction(action) then
        self:AddInitiativeEntry(playerName, total, roll, modifier + affectModifier.total)
    end

    local effectDice = self.EffectDiceField and self.EffectDiceField.Value or "None"
    if effectDice and effectDice ~= "None" then
        local effectRoll, _, _, effectRolls = self:RollDiceExpression(effectDice)
        table.insert(lines, "Effect: " .. self:FormatDiceRoll(effectDice, effectRoll, effectRolls))
    end

    self:RecordRoll(table.concat(lines, "\n"), true)
end
