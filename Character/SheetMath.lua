local DiceSim = _G.DiceSim

local CHARACTER_STATS = DiceSim.CharacterStats or { "STR", "DEX", "CON", "INT", "WIS", "CHA" }
local CHARACTER_STAT_MIN = DiceSim.CharacterStatMin or 0
local CHARACTER_DEFAULT_STAT = DiceSim.CHARACTER_DEFAULT_STAT or 0

local function IsArrayStats(stats)
    return type(stats) == "table" and type(stats[1]) == "table"
end

local function IsNeutralDefaultSheet(data)
    if not data or (data.diceSystem and data.diceSystem ~= "Default") then
        return false
    end

    if not IsArrayStats(data.stats) or #data.stats == 0 then
        return true
    end

    for _, statData in ipairs(data.stats) do
        local value = tonumber(statData.value) or 0
        if value ~= 0 and value ~= 10 then
            return false
        end
    end

    return true
end

local function ApplyDefaultStats(data)
    data.stats = {}
    for _, stat in ipairs(CHARACTER_STATS) do
        table.insert(data.stats, {
            name = stat,
            value = CHARACTER_DEFAULT_STAT,
        })
    end
end

function DiceSim:GetSheetProfileStore()
    DiceSimDB = DiceSimDB or {}
    DiceSimDB.SheetProfiles = DiceSimDB.SheetProfiles or {}

    local key = self.GetPlayerKey and self:GetPlayerKey() or "player"
    DiceSimDB.SheetProfiles[key] = DiceSimDB.SheetProfiles[key] or {}
    return DiceSimDB.SheetProfiles[key]
end

function DiceSim:GetCurrentSheetStore()
    DiceSimDB = DiceSimDB or {}
    DiceSimDB.CurrentSheets = DiceSimDB.CurrentSheets or {}

    local key = self.GetPlayerKey and self:GetPlayerKey() or "player"
    return DiceSimDB.CurrentSheets, key
end

function DiceSim:SaveCurrentSheetData()
    if not self.SheetPanel or self.SheetPanel.Unit ~= "player" or self.IsApplyingRemoteSheet or self.IsLoadingCurrentSheet then
        return
    end

    local store, key = self:GetCurrentSheetStore()
    store[key] = self:GetSheetData()
end

function DiceSim:LoadCurrentSheetData()
    if not self.SheetPanel then
        return false
    end

    local store, key = self:GetCurrentSheetStore()
    local data = store[key]
    if not data then
        return false
    end

    if IsNeutralDefaultSheet(data) then
        ApplyDefaultStats(data)
        local hp, hpMax = self:GetDefaultSheetMetric("hp")
        local energy, energyMax = self:GetDefaultSheetMetric("energy")
        local armor, armorMax = self:GetDefaultSheetMetric("armor")
        data.metrics = {
            hp = hp,
            hpMax = hpMax,
            energy = energy,
            energyMax = energyMax,
            armor = armor,
            armorMax = armorMax,
        }
        store[key] = data
    end

    self.IsLoadingCurrentSheet = true
    self:ApplySheetData(data)
    self.IsLoadingCurrentSheet = false
    return true
end

function DiceSim:GetSheetProfileOptions()
    local options = {}

    for name in pairs(self:GetSheetProfileStore()) do
        table.insert(options, { label = name, value = name })
    end

    table.sort(options, function(a, b)
        return a.label < b.label
    end)

    return options
end

function DiceSim:GetSheetData()
    local data = {
        characterName = self.SheetPanel.CharacterNameInput and self.SheetPanel.CharacterNameInput:GetText() or "",
        className = self.SheetPanel.ClassInput and self.SheetPanel.ClassInput:GetText() or "",
        biography = self.SheetPanel.BiographyInput and self.SheetPanel.BiographyInput:GetText() or "",
        portraitRing = self.GetSheetPortraitRing and self:GetSheetPortraitRing() or "hud-PlayerFrame-portraitring-large",
        metrics = {
            hp = self:GetSheetMetricValue("hp"),
            hpMax = self:GetSheetMetricMax("hp"),
            energy = self:GetSheetMetricValue("energy"),
            energyMax = self:GetSheetMetricMax("energy"),
            armor = self:GetSheetMetricValue("armor"),
            armorMax = self:GetSheetMetricMax("armor"),
        },
        affects = {
            buffs = self:GetAffectStripData(self.SheetPanel.BuffStrip),
            debuffs = self:GetAffectStripData(self.SheetPanel.DebuffStrip),
        },
        diceSystem = self:GetImportedDiceSystemName() and ("Imported: " .. self:GetImportedDiceSystemName()) or "Default",
        stats = {},
    }

    for _, row in ipairs(self.SheetPanel.StatRows or {}) do
        table.insert(data.stats, {
            name = row.NameInput and row.NameInput:GetText() or "",
            value = tonumber(row.ValueInput and row.ValueInput:GetText()) or CHARACTER_STAT_MIN,
        })
    end

    return data
end

function DiceSim:ApplySheetData(data)
    if not data or not self.SheetPanel then
        return
    end

    if self.SheetPanel.CharacterNameInput then
        self.SheetPanel.CharacterNameInput:SetText(data.characterName or "")
    end

    if self.SheetPanel.ClassInput then
        self.SheetPanel.ClassInput:SetText(data.className or "")
    end

    if self.SheetPanel.BiographyInput then
        self.SheetPanel.BiographyInput:SetText(data.biography or "")
    end

    if data.portraitRing and self.SheetPanel.PortraitRing then
        if self.SheetPanel.Unit == "player" and self.SetSheetPortraitRing then
            self:SetSheetPortraitRing(data.portraitRing)
        else
            if self.ApplyPortraitRingTexture then
                self:ApplyPortraitRingTexture(self.SheetPanel.PortraitRing, data.portraitRing, 112)
            else
                self:ApplyTextureOrAtlas(self.SheetPanel.PortraitRing, data.portraitRing)
                self.SheetPanel.PortraitRing:SetSize(112, 112)
            end
        end
    end

    if self.SheetPanel.ClearAttributeRows then
        self.SheetPanel:ClearAttributeRows()
    end

    if IsArrayStats(data.stats) then
        for _, statData in ipairs(data.stats) do
            if self.SheetPanel.AddAttributeRow then
                self.SheetPanel:AddAttributeRow(statData.name or "", tonumber(statData.value) or CHARACTER_DEFAULT_STAT)
            end
        end
    else
        for _, stat in ipairs(CHARACTER_STATS) do
            if self.SheetPanel.AddAttributeRow then
                self.SheetPanel:AddAttributeRow(stat, data.stats and data.stats[stat] or CHARACTER_DEFAULT_STAT)
            end
        end
    end

    local defaultHp, defaultHpMax = self:GetDefaultSheetMetric("hp")
    local defaultEnergy, defaultEnergyMax = self:GetDefaultSheetMetric("energy")
    local defaultArmor, defaultArmorMax = self:GetDefaultSheetMetric("armor")
    self:SetSheetMetricValue("hp", data.metrics and data.metrics.hp or defaultHp, data.metrics and data.metrics.hpMax or defaultHpMax)
    self:SetSheetMetricValue("energy", data.metrics and data.metrics.energy or defaultEnergy, data.metrics and data.metrics.energyMax or defaultEnergyMax)
    self:SetSheetMetricValue("armor", data.metrics and data.metrics.armor or defaultArmor, data.metrics and data.metrics.armorMax or defaultArmorMax)

    if self.ApplyAffectsToContext then
        self:ApplyAffectsToContext(self.SheetPanel, data.affects)
    end

    self.SheetPanel.RemoteSheetSystem = data.diceSystem
    if self.RefreshSheetSystemStatus then
        self:RefreshSheetSystemStatus()
    end

    self:RefreshSheetMath()
end

function DiceSim:SaveSheetProfile()
    if not self:CanEditSheetIdentity(self.SheetPanel.Unit or "player") then
        return
    end

    local profileName = self.SheetPanel.ProfileNameInput and self.SheetPanel.ProfileNameInput:GetText() or ""
    profileName = string.match(profileName, "^%s*(.-)%s*$")

    if profileName == "" then
        print("DiceSim: enter a profile name first.")
        return
    end

    self:GetSheetProfileStore()[profileName] = self:GetSheetData()
    self:SaveCurrentSheetData()
    self.SheetPanel.ProfileDropdown.Value = profileName
    self.SheetPanel.ProfileDropdown.Label:SetText(profileName)
    self.SheetPanel.ProfileDropdown.Options = self:GetSheetProfileOptions()
    self:AddEventLogEntry("Saved sheet profile: " .. profileName)
    if self.BroadcastSheetState then
        self:BroadcastSheetState()
    end
end

function DiceSim:RemoveSheetProfile()
    if not self:CanEditSheetIdentity(self.SheetPanel.Unit or "player") then
        return
    end

    local profileName = self.SheetPanel.ProfileNameInput and self.SheetPanel.ProfileNameInput:GetText() or ""
    profileName = string.match(profileName, "^%s*(.-)%s*$")

    if profileName == "" and self.SheetPanel.ProfileDropdown then
        profileName = self.SheetPanel.ProfileDropdown.Value or ""
    end

    if profileName == "" or not self:GetSheetProfileStore()[profileName] then
        print("DiceSim: choose a saved profile to remove.")
        return
    end

    self:GetSheetProfileStore()[profileName] = nil
    self.SheetPanel.ProfileDropdown.Value = "Profiles"
    self.SheetPanel.ProfileDropdown.Label:SetText("Profiles")
    self.SheetPanel.ProfileDropdown.Options = self:GetSheetProfileOptions()

    if self.SheetPanel.ProfileNameInput then
        self.SheetPanel.ProfileNameInput:SetText("")
    end

    self:AddEventLogEntry("Removed sheet profile: " .. profileName)
end

function DiceSim:LoadSheetProfile(name)
    local data = self:GetSheetProfileStore()[name]
    if not data then
        return
    end

    if self.SheetPanel.ProfileNameInput then
        self.SheetPanel.ProfileNameInput:SetText(name)
    end

    self:ApplySheetData(data)
    self:SaveCurrentSheetData()
    if self.BroadcastSheetState then
        self:BroadcastSheetState()
    end
end

function DiceSim:SetSheetEditable(isEditable)
    if not self.SheetPanel then
        return
    end

    for _, input in ipairs(self.SheetPanel.EditableInputs or {}) do
        input:EnableMouse(isEditable)
        if input.EnableKeyboard then
            input:EnableKeyboard(isEditable)
        end
    end

    for _, control in ipairs(self.SheetPanel.EditableControls or {}) do
        if control.SetEnabled then
            control:SetEnabled(isEditable)
        end
        control:EnableMouse(isEditable)
        control:SetAlpha(isEditable and 1 or 0.45)
    end

    local identityEditable = self.CanEditSheetIdentity and self:CanEditSheetIdentity(self.SheetPanel.Unit or "player") or isEditable
    for _, input in ipairs(self.SheetPanel.IdentityInputs or {}) do
        input:EnableMouse(identityEditable)
        if input.EnableKeyboard then
            input:EnableKeyboard(identityEditable)
        end
    end

    for _, control in ipairs(self.SheetPanel.ProfileControls or {}) do
        if control.SetEnabled then
            control:SetEnabled(identityEditable)
        end
        control:EnableMouse(identityEditable)
        control:SetAlpha(identityEditable and 1 or 0.45)
    end

    if self.SheetPanel.ImportButton then
        local canImport = self.CanImportDiceSystem and self:CanImportDiceSystem(self.SheetPanel.Unit or "player")
        self.SheetPanel.ImportButton:EnableMouse(canImport)
        self.SheetPanel.ImportButton:SetAlpha(canImport and 1 or 0.45)
    end
end
