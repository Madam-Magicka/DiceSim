local DiceSim = _G.DiceSim

local PREFIX = "DiceSim"
local CHUNK_SIZE = 160
local BROADCAST_THROTTLE_SECONDS = 1
local HOST_HEARTBEAT_SECONDS = 12
local GUEST_REQUEST_SECONDS = 12

local function Escape(value)
    value = tostring(value or "")
    value = string.gsub(value, "\\", "\\\\")
    value = string.gsub(value, "\n", "\\n")
    value = string.gsub(value, "|", "\\p")
    value = string.gsub(value, ";", "\\s")
    value = string.gsub(value, ",", "\\c")
    value = string.gsub(value, "=", "\\e")
    return value
end

local function Unescape(value)
    value = tostring(value or "")
    local output = {}
    local index = 1

    while index <= #value do
        local character = string.sub(value, index, index)
        if character == "\\" then
            local nextCharacter = string.sub(value, index + 1, index + 1)
            if nextCharacter == "n" then
                table.insert(output, "\n")
            elseif nextCharacter == "p" then
                table.insert(output, "|")
            elseif nextCharacter == "s" then
                table.insert(output, ";")
            elseif nextCharacter == "c" then
                table.insert(output, ",")
            elseif nextCharacter == "e" then
                table.insert(output, "=")
            elseif nextCharacter == "\\" then
                table.insert(output, "\\")
            else
                table.insert(output, nextCharacter)
            end
            index = index + 2
        else
            table.insert(output, character)
            index = index + 1
        end
    end

    return table.concat(output)
end

local function Split(value, delimiter)
    local result = {}
    local pattern = "([^" .. delimiter .. "]*)"

    for item in string.gmatch(value or "", pattern .. delimiter .. "?") do
        if item == "" and #result > 0 and string.sub(value, -1) ~= delimiter then
            break
        end
        table.insert(result, item)
    end

    return result
end

local function JoinEscaped(fields)
    local escaped = {}

    for index, field in ipairs(fields) do
        escaped[index] = Escape(field)
    end

    return table.concat(escaped, ",")
end

local function DecodeFields(value)
    local fields = Split(value, ",")

    for index, field in ipairs(fields) do
        fields[index] = Unescape(field)
    end

    return fields
end

local function EncodeAffectList(affects)
    local records = {}

    for _, affect in ipairs(affects or {}) do
        table.insert(records, JoinEscaped({
            affect.type,
            affect.icon,
            affect.name,
            affect.details,
            affect.appliesTo,
            affect.modifier,
        }))
    end

    return table.concat(records, ";")
end

local function DecodeAffectList(value)
    local affects = {}

    for _, item in ipairs(Split(value or "", ";")) do
        if item ~= "" then
            local fields = DecodeFields(item)
            table.insert(affects, {
                type = fields[1],
                icon = fields[2],
                name = fields[3],
                details = fields[4],
                appliesTo = fields[5],
                modifier = tonumber(fields[6]) or 0,
            })
        end
    end

    return affects
end

function DiceSim:InitializeSessions()
    DiceSimDB = DiceSimDB or {}
    DiceSimDB.Sessions = DiceSimDB.Sessions or {}
    DiceSimDB.RemoteSheets = DiceSimDB.RemoteSheets or {}

    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
    end

    self.ActiveSessionId = DiceSimDB.ActiveSessionId
    self.SessionMode = DiceSimDB.SessionMode
end

local function NormalizeSenderKey(sender)
    sender = tostring(sender or "")
    if Ambiguate then
        sender = Ambiguate(sender, "short") or sender
    end
    return sender
end

local function SessionKeysMatch(left, right)
    left = NormalizeSenderKey(left)
    right = NormalizeSenderKey(right)
    return left ~= "" and right ~= "" and left == right
end

local function HasSessionKey(store, key)
    if not store then
        return false
    end

    if store[key] or store[NormalizeSenderKey(key)] then
        return true
    end

    for storedKey, active in pairs(store) do
        if active and SessionKeysMatch(storedKey, key) then
            return true
        end
    end

    return false
end

local function ClearSessionKey(store, key)
    if not store then
        return
    end

    store[key] = nil
    store[NormalizeSenderKey(key)] = nil
    for storedKey in pairs(store) do
        if SessionKeysMatch(storedKey, key) then
            store[storedKey] = nil
        end
    end
end

function DiceSim:GetUnitSheetSyncKey(unit)
    if unit == "player" or not unit then
        return NormalizeSenderKey(UnitName and UnitName("player") or self.PlayerKey or "player")
    end

    return NormalizeSenderKey(UnitName and UnitName(unit) or unit)
end

function DiceSim:GetRemoteSheetStore()
    DiceSimDB = DiceSimDB or {}
    DiceSimDB.RemoteSheets = DiceSimDB.RemoteSheets or {}
    return DiceSimDB.RemoteSheets
end

function DiceSim:SerializeSheetState(data)
    data = data or self:GetSheetData()

    local sections = {
        "b=" .. JoinEscaped({
            data.characterName,
            data.className,
            data.diceSystem or "Default",
            data.biography,
            data.portraitRing,
        }),
        "m=" .. JoinEscaped({
            data.metrics and data.metrics.hp,
            data.metrics and data.metrics.hpMax,
            data.metrics and data.metrics.energy,
            data.metrics and data.metrics.energyMax,
            data.metrics and data.metrics.armor,
            data.metrics and data.metrics.armorMax,
        }),
    }

    local stats = {}
    for _, stat in ipairs(data.stats or {}) do
        table.insert(stats, JoinEscaped({ stat.name, stat.value }))
    end
    table.insert(sections, "a=" .. table.concat(stats, ";"))

    local buffs = {}
    for _, affect in ipairs((data.affects and data.affects.buffs) or {}) do
        table.insert(buffs, JoinEscaped({ affect.icon, affect.name, affect.details, affect.appliesTo, affect.modifier }))
    end
    table.insert(sections, "bf=" .. table.concat(buffs, ";"))

    local debuffs = {}
    for _, affect in ipairs((data.affects and data.affects.debuffs) or {}) do
        table.insert(debuffs, JoinEscaped({ affect.icon, affect.name, affect.details, affect.appliesTo, affect.modifier }))
    end
    table.insert(sections, "db=" .. table.concat(debuffs, ";"))

    return table.concat(sections, "|")
end

function DiceSim:DeserializeSheetState(payload)
    local defaultHp, defaultHpMax = self:GetDefaultSheetMetric("hp")
    local defaultEnergy, defaultEnergyMax = self:GetDefaultSheetMetric("energy")
    local defaultArmor, defaultArmorMax = self:GetDefaultSheetMetric("armor")
    local data = {
        characterName = "",
        className = "",
        diceSystem = "Default",
        metrics = {
            hp = defaultHp,
            hpMax = defaultHpMax,
            energy = defaultEnergy,
            energyMax = defaultEnergyMax,
            armor = defaultArmor,
            armorMax = defaultArmorMax,
        },
        affects = {
            buffs = {},
            debuffs = {},
        },
        stats = {},
    }

    for _, section in ipairs(Split(payload or "", "|")) do
        local key, value = string.match(section, "^(.-)=(.*)$")
        if key == "b" then
            local fields = DecodeFields(value)
            data.characterName = fields[1] or ""
            data.className = fields[2] or ""
            data.diceSystem = fields[3] or "Default"
            data.biography = fields[4] or ""
            data.portraitRing = fields[5] or "hud-PlayerFrame-portraitring-large"
        elseif key == "m" then
            local fields = DecodeFields(value)
            data.metrics = {
                hp = tonumber(fields[1]) or defaultHp,
                hpMax = tonumber(fields[2]) or defaultHpMax,
                energy = tonumber(fields[3]) or defaultEnergy,
                energyMax = tonumber(fields[4]) or defaultEnergyMax,
                armor = tonumber(fields[5]) or defaultArmor,
                armorMax = tonumber(fields[6]) or defaultArmorMax,
            }
        elseif key == "a" and value ~= "" then
            for _, item in ipairs(Split(value, ";")) do
                local fields = DecodeFields(item)
                table.insert(data.stats, {
                    name = fields[1] or "",
                    value = tonumber(fields[2]) or CHARACTER_DEFAULT_STAT,
                })
            end
        elseif (key == "bf" or key == "db") and value ~= "" then
            local target = key == "bf" and data.affects.buffs or data.affects.debuffs
            local affectType = key == "bf" and "buff" or "debuff"
            for _, item in ipairs(Split(value, ";")) do
                local fields = DecodeFields(item)
                table.insert(target, {
                    type = affectType,
                    icon = fields[1],
                    name = fields[2],
                    details = fields[3],
                    appliesTo = fields[4],
                    modifier = tonumber(fields[5]) or 0,
                })
            end
        end
    end

    return data
end

function DiceSim:SendSheetPayload(command, payload)
    if #payload <= CHUNK_SIZE then
        self:SendSessionMessage(command .. ":" .. payload)
        return
    end

    local total = math.ceil(#payload / CHUNK_SIZE)
    local sequence = tostring(time()) .. tostring(math.random(100, 999))
    for index = 1, total do
        local chunk = string.sub(payload, ((index - 1) * CHUNK_SIZE) + 1, index * CHUNK_SIZE)
        self:SendSessionMessage(command .. "C:" .. sequence .. ":" .. index .. ":" .. total .. ":" .. chunk)
    end
end

function DiceSim:BroadcastSheetState()
    if not self.SheetPanel then
        return
    end

    local payload = self:SerializeSheetState(self:GetSheetData())
    if self.SheetPanel.Unit == "player" then
        self:SendSheetPayload("SHEET", payload)
        return
    end

    if self:IsAdmin() then
        local targetKey = self:GetUnitSheetSyncKey(self.SheetPanel.Unit)
        if targetKey and targetKey ~= "" then
            self:SendSheetPayload("SHEETA", targetKey .. ":" .. payload)
        end
    end
end

function DiceSim:ScheduleSheetBroadcast()
    if not self.SheetPanel or self.IsApplyingRemoteSheet then
        return
    end

    if self.SaveCurrentSheetData then
        self:SaveCurrentSheetData()
    end

    if C_Timer and C_Timer.After then
        if self.SheetBroadcastQueued then
            return
        end

        self.SheetBroadcastQueued = true
        C_Timer.After(0.8, function()
            DiceSim.SheetBroadcastQueued = false
            DiceSim:BroadcastSheetState()
        end)
        return
    end

    self:BroadcastSheetState()
end

function DiceSim:StoreRemoteSheetState(sender, payload, targetKey)
    local key = NormalizeSenderKey(targetKey or sender)
    if key == "" then
        return
    end

    local data = self:DeserializeSheetState(payload)
    data.updated = time()
    self:GetRemoteSheetStore()[key] = data

    local playerKey = self:GetUnitSheetSyncKey("player")
    if key == playerKey and sender ~= self.PlayerKey then
        self.IsApplyingRemoteSheet = true
        if self.SheetPanel then
            self:ApplySheetData(data)
            self:SetSheetEditable(self:CanEditSheet("player"))
        end
        self.IsApplyingRemoteSheet = false
        return
    end

    if self.SheetPanel and self.SheetPanel:IsShown() and self.SheetPanel.Unit ~= "player" then
        local activeKey = self:GetUnitSheetSyncKey(self.SheetPanel.Unit)
        if activeKey == key then
            self.IsApplyingRemoteSheet = true
            self:ApplySheetData(data)
            self.IsApplyingRemoteSheet = false
            self:SetSheetEditable(false)
        end
    end
end

function DiceSim:ReceiveSheetChunk(sequence, index, total, chunk, sender, isAdminSheet)
    self.SheetChunks = self.SheetChunks or {}
    local key = tostring(sender or "unknown") .. ":" .. tostring(isAdminSheet and "admin" or "sheet") .. ":" .. tostring(sequence or "")
    local buffer = self.SheetChunks[key] or { chunks = {}, total = tonumber(total) or 1, sender = sender }
    self.SheetChunks[key] = buffer
    buffer.chunks[tonumber(index) or 1] = chunk or ""

    for chunkIndex = 1, buffer.total do
        if not buffer.chunks[chunkIndex] then
            return
        end
    end

    self.SheetChunks[key] = nil
    local payload = table.concat(buffer.chunks, "")
    if isAdminSheet then
        local targetKey, sheetPayload = string.match(payload, "^([^:]+):(.*)$")
        if targetKey and sheetPayload then
            self:StoreRemoteSheetState(sender, sheetPayload, targetKey)
        end
        return
    end

    self:StoreRemoteSheetState(sender, payload)
end

function DiceSim:ApplyRemoteSheetForUnit(unit)
    local key = self:GetUnitSheetSyncKey(unit)
    local data = key and self:GetRemoteSheetStore()[key]
    if not data then
        return false
    end

    self.IsApplyingRemoteSheet = true
    self:ApplySheetData(data)
    self.IsApplyingRemoteSheet = false
    self:SetSheetEditable(false)
    return true
end

function DiceSim:GenerateSessionId()
    local name = self.GetPlayerKey and self:GetPlayerKey() or "player"
    name = string.gsub(name, "%W+", "")
    return string.upper(string.sub(name, 1, 5)) .. "-" .. time() .. "-" .. math.random(100, 999)
end

function DiceSim:GetActiveSession()
    if not self.ActiveSessionId then
        return nil
    end

    DiceSimDB = DiceSimDB or {}
    DiceSimDB.Sessions = DiceSimDB.Sessions or {}
    return DiceSimDB.Sessions[self.ActiveSessionId]
end

function DiceSim:HostSession()
    DiceSimDB = DiceSimDB or {}
    DiceSimDB.Sessions = DiceSimDB.Sessions or {}

    local sessionId = self:GenerateSessionId()
    local host = self.GetPlayerKey and self:GetPlayerKey() or "player"

    DiceSimDB.Sessions[sessionId] = {
        id = sessionId,
        host = host,
        created = time(),
        updated = time(),
        snapshot = {},
    }

    self.ActiveSessionId = sessionId
    self.SessionMode = "host"
    self.CurrentRole = "admin"
    self.SessionPlayers = {}
    self.SessionAssistants = {}
    self.SessionHiddenPlayers = {}
    self.SessionPendingInvites = {}
    self.SessionRosterLocked = false
    self.LastAppliedRemoteSessionRevision = nil
    self.SessionChunks = {}
    DiceSimDB.ActiveSessionId = sessionId
    DiceSimDB.SessionMode = "host"
    self:SaveSessionSnapshot()
    self:AddEventLogEntry("Started DiceSim session: " .. sessionId)
    self:RefreshSessionPanel()
    self:RefreshMinimizedStatus()
    self:RefreshPermissions()
end

function DiceSim:JoinSession(sessionId)
    sessionId = string.match(sessionId or "", "^%s*(.-)%s*$")
    if sessionId == "" then
        return
    end

    DiceSimDB = DiceSimDB or {}
    DiceSimDB.Sessions = DiceSimDB.Sessions or {}
    DiceSimDB.Sessions[sessionId] = DiceSimDB.Sessions[sessionId] or {
        id = sessionId,
        host = "Unknown",
        created = time(),
        updated = time(),
        snapshot = {},
    }

    self.ActiveSessionId = sessionId
    self.SessionMode = "guest"
    self.SessionJoinGraceUntil = (time and time() or 0) + 20
    self.CurrentRole = "user"
    self.SessionPlayers = {}
    self.SessionAssistants = {}
    self.SessionHiddenPlayers = {}
    self.SessionPendingInvites = {}
    self.SessionRosterLocked = false
    self.LastAppliedRemoteSessionRevision = nil
    DiceSimDB.ActiveSessionId = sessionId
    DiceSimDB.SessionMode = "guest"
    self:SendSessionMessage("JOIN:" .. sessionId)
    self:SendSessionMessage("REQ:" .. sessionId)
    self:AddEventLogEntry("Joined DiceSim session: " .. sessionId)
    self:RefreshSessionPanel()
    self:RefreshMinimizedStatus()
    self:RefreshPermissions()
end

function DiceSim:WipeSession()
    if not self.ActiveSessionId then
        return
    end

    DiceSimDB = DiceSimDB or {}
    DiceSimDB.Sessions = DiceSimDB.Sessions or {}
    DiceSimDB.Sessions[self.ActiveSessionId] = nil
    DiceSimDB.ActiveSessionId = nil
    DiceSimDB.SessionMode = nil
    self.ActiveSessionId = nil
    self.SessionMode = nil
    self.SessionPlayers = nil
    self.SessionAssistants = nil
    self.SessionHiddenPlayers = nil
    self.SessionPendingInvites = nil
    self.SessionRosterLocked = nil
    self.CurrentRole = "admin"
    self.LastAppliedRemoteSessionRevision = nil
    self.WipeSessionConfirmArmed = nil
    self.SessionJoinGraceUntil = nil
    self.LastSessionRequest = nil
    self:ClearLocalSessionView()
    self:AddEventLogEntry("Wiped local DiceSim session data.")
    self:RefreshSessionPanel()
    self:RefreshMinimizedStatus()
    self:RefreshPermissions()
end

function DiceSim:ClearLocalSessionView()
    for _, object in ipairs(self.CanvasObjects or {}) do
        object:Hide()
        if object.EditOverlay then
            object.EditOverlay:Hide()
        end
        if object.ActionPanel then
            object.ActionPanel:Hide()
        end
    end
    self.CanvasObjects = {}

    for _, symbol in pairs(self.CanvasSymbols or {}) do
        symbol:Hide()
    end
    self.CanvasSymbols = {}

    self.InitiativeEntries = {}
    self.RoundNumber = 1
    self.EventLogEntries = {}
    self.CanvasBackground = "default"
    self.CanvasBackgroundLabel = "Default"
    if self.CanvasBackgroundTexture then
        self.CanvasBackgroundTexture:Hide()
    end
    if self.AddPanel and self.AddPanel.BackgroundDropdown then
        self.AddPanel.BackgroundDropdown.Value = "default"
        self.AddPanel.BackgroundDropdown.Label:SetText("Default")
    end
    if self.RoundsTracker then
        self.RoundsTracker:Hide()
    end
    if self.BuffDebuffPanel then
        self.BuffDebuffPanel:Hide()
    end
    if self.RefreshInitiativeList then
        self:RefreshInitiativeList()
    end
    if self.RefreshEventLog then
        self:RefreshEventLog()
    end
    if self.RefreshDiceTargets then
        self:RefreshDiceTargets()
    end
    if self.RefreshCharacterTabs then
        self:RefreshCharacterTabs()
    end
    if self.RefreshCanvas then
        self:RefreshCanvas()
    end
end

function DiceSim:SaveSessionSnapshot()
    if self.IsApplyingSessionSnapshot then
        return
    end

    local session = self:GetActiveSession()
    if not session then
        return
    end

    local snapshot = {
        canvas = {
            zoom = self.Zoom,
            x = self.CanvasX,
            y = self.CanvasY,
            background = self.CanvasBackground or "default",
            backgroundLabel = self.CanvasBackgroundLabel or "Default",
        },
        panels = {},
        symbols = {},
        initiative = self.InitiativeEntries or {},
        eventLog = self.EventLogEntries or {},
        players = self.SessionPlayers or {},
        assistants = self.SessionAssistants or {},
        hiddenPlayers = self.SessionHiddenPlayers or {},
        rosterLocked = self.SessionRosterLocked and true or false,
        round = {
            number = self.RoundNumber or 1,
            shown = self.RoundsTracker and self.RoundsTracker:IsShown() and true or false,
        },
        savedAt = time(),
    }
    snapshot.revision = ((session.snapshot and session.snapshot.revision) or 0) + 1

    for _, object in ipairs(self.CanvasObjects or {}) do
        if object:IsShown() and object.PanelType then
            table.insert(snapshot.panels, {
                panelType = object.PanelType,
                number = object.PanelNumber,
                name = object.TargetName,
                x = object.CanvasObjectX or 0,
                y = object.CanvasObjectY or 0,
                portrait = object.Portrait and object.Portrait:GetTexture() or nil,
                hp = object.HPBar and object.HPBar.MetricValue or nil,
                hpMax = object.HPBar and object.HPBar.MetricMax or nil,
                energy = object.EnergyBar and object.EnergyBar.MetricValue or nil,
                energyMax = object.EnergyBar and object.EnergyBar.MetricMax or nil,
                armor = object.ArmorBar and object.ArmorBar.MetricValue or nil,
                armorMax = object.ArmorBar and object.ArmorBar.MetricMax or nil,
                buffs = self:GetAffectStripData(object.BuffStrip),
                debuffs = self:GetAffectStripData(object.DebuffStrip),
            })
        end
    end

    for label, symbol in pairs(self.CanvasSymbols or {}) do
        if symbol:IsShown() then
            table.insert(snapshot.symbols, {
                label = label,
                icon = symbol.IconPath,
                x = symbol.CanvasObjectX or 0,
                y = symbol.CanvasObjectY or 0,
            })
        end
    end

    session.snapshot = snapshot
    session.updated = time()
    self.SessionBroadcastQueued = true
end

function DiceSim:SerializeSessionSnapshot(snapshot)
    snapshot = snapshot or {}

    local sections = {}
    table.insert(sections, "v=" .. JoinEscaped({ snapshot.savedAt or time(), snapshot.revision or 0 }))

    if snapshot.canvas then
        table.insert(sections, "c=" .. JoinEscaped({
            snapshot.canvas.zoom,
            snapshot.canvas.x,
            snapshot.canvas.y,
            snapshot.canvas.background,
            snapshot.canvas.backgroundLabel,
        }))
    end

    local panels = {}
    for _, panel in ipairs(snapshot.panels or {}) do
        table.insert(panels, JoinEscaped({
            panel.panelType,
            panel.number,
            panel.name,
            panel.x,
            panel.y,
            panel.portrait,
            panel.hp,
            panel.hpMax,
            panel.energy,
            panel.energyMax,
            panel.armor,
            panel.armorMax,
            EncodeAffectList(panel.buffs),
            EncodeAffectList(panel.debuffs),
        }))
    end
    table.insert(sections, "p=" .. table.concat(panels, ";"))

    local symbols = {}
    for _, symbol in ipairs(snapshot.symbols or {}) do
        table.insert(symbols, JoinEscaped({ symbol.label, symbol.x, symbol.y, symbol.icon }))
    end
    table.insert(sections, "s=" .. table.concat(symbols, ";"))

    local initiative = {}
    for _, entry in pairs(snapshot.initiative or {}) do
        table.insert(initiative, JoinEscaped({ entry.actor, entry.total, entry.roll, entry.modifier }))
    end
    table.insert(sections, "i=" .. table.concat(initiative, ";"))

    local eventLog = {}
    local entries = snapshot.eventLog or {}
    local startIndex = math.max(1, #entries - 24)
    for index = startIndex, #entries do
        local entry = entries[index]
        if entry and entry.text then
            table.insert(eventLog, JoinEscaped({ entry.time or "00:00:00", entry.text }))
        end
    end
    table.insert(sections, "e=" .. table.concat(eventLog, ";"))

    if snapshot.round then
        table.insert(sections, "r=" .. JoinEscaped({
            snapshot.round.number,
            snapshot.round.shown and "1" or "0",
        }))
    end

    local players = {}
    for name, active in pairs(snapshot.players or {}) do
        if active then
            table.insert(players, JoinEscaped({ name }))
        end
    end
    table.insert(sections, "pl=" .. table.concat(players, ";"))
    table.insert(sections, "rl=" .. (snapshot.rosterLocked and "1" or "0"))

    local hiddenPlayers = {}
    for name, active in pairs(snapshot.hiddenPlayers or {}) do
        if active then
            table.insert(hiddenPlayers, JoinEscaped({ name }))
        end
    end
    table.insert(sections, "hp=" .. table.concat(hiddenPlayers, ";"))

    local assistants = {}
    for name, active in pairs(snapshot.assistants or {}) do
        if active then
            table.insert(assistants, JoinEscaped({ name }))
        end
    end
    table.insert(sections, "as=" .. table.concat(assistants, ";"))

    return table.concat(sections, "|")
end

function DiceSim:DeserializeSessionSnapshot(payload)
    local snapshot = {
        panels = {},
        symbols = {},
        initiative = {},
        eventLog = {},
        players = {},
        assistants = {},
        hiddenPlayers = {},
        rosterLocked = false,
        round = {},
    }

    for _, section in ipairs(Split(payload or "", "|")) do
        local key, value = string.match(section, "^(.-)=(.*)$")

        if key == "v" then
            local fields = DecodeFields(value)
            snapshot.savedAt = tonumber(fields[1]) or time()
            snapshot.revision = tonumber(fields[2]) or 0
        elseif key == "c" then
            local fields = DecodeFields(value)
            snapshot.canvas = {
                zoom = tonumber(fields[1]),
                x = tonumber(fields[2]),
                y = tonumber(fields[3]),
                background = fields[4],
                backgroundLabel = fields[5],
            }
        elseif key == "p" and value ~= "" then
            for _, item in ipairs(Split(value, ";")) do
                local fields = DecodeFields(item)
                table.insert(snapshot.panels, {
                    panelType = fields[1],
                    number = tonumber(fields[2]),
                    name = fields[3],
                    x = tonumber(fields[4]) or 0,
                    y = tonumber(fields[5]) or 0,
                    portrait = fields[6],
                    hp = tonumber(fields[7]),
                    hpMax = tonumber(fields[8]),
                    energy = tonumber(fields[9]),
                    energyMax = tonumber(fields[10]),
                    armor = tonumber(fields[11]),
                    armorMax = tonumber(fields[12]),
                    buffs = DecodeAffectList(fields[13]),
                    debuffs = DecodeAffectList(fields[14]),
                })
            end
        elseif key == "s" and value ~= "" then
            for _, item in ipairs(Split(value, ";")) do
                local fields = DecodeFields(item)
                table.insert(snapshot.symbols, {
                    label = fields[1],
                    x = tonumber(fields[2]) or 0,
                    y = tonumber(fields[3]) or 0,
                    icon = fields[4],
                })
            end
        elseif key == "i" and value ~= "" then
            for _, item in ipairs(Split(value, ";")) do
                local fields = DecodeFields(item)
                snapshot.initiative[fields[1]] = {
                    actor = fields[1],
                    total = tonumber(fields[2]) or 0,
                    roll = tonumber(fields[3]) or 0,
                    modifier = tonumber(fields[4]) or 0,
                }
            end
        elseif key == "e" and value ~= "" then
            for _, item in ipairs(Split(value, ";")) do
                local fields = DecodeFields(item)
                if fields[1] and fields[2] then
                    table.insert(snapshot.eventLog, {
                        time = fields[1],
                        text = fields[2],
                    })
                end
            end
        elseif key == "r" then
            local fields = DecodeFields(value)
            snapshot.round = {
                number = tonumber(fields[1]) or 1,
                shown = fields[2] == "1",
            }
        elseif key == "pl" and value ~= "" then
            for _, item in ipairs(Split(value, ";")) do
                local fields = DecodeFields(item)
                if fields[1] and fields[1] ~= "" then
                    snapshot.players[fields[1]] = true
                end
            end
        elseif key == "rl" then
            snapshot.rosterLocked = value == "1"
        elseif key == "hp" and value ~= "" then
            for _, item in ipairs(Split(value, ";")) do
                local fields = DecodeFields(item)
                if fields[1] and fields[1] ~= "" then
                    snapshot.hiddenPlayers[fields[1]] = true
                end
            end
        elseif key == "as" and value ~= "" then
            for _, item in ipairs(Split(value, ";")) do
                local fields = DecodeFields(item)
                if fields[1] and fields[1] ~= "" then
                    snapshot.assistants[fields[1]] = true
                end
            end
        end
    end

    return snapshot
end

function DiceSim:ApplyRemoteSessionSnapshot(sessionId, payload, sender)
    if sessionId ~= self.ActiveSessionId then
        return
    end

    local session = self:GetActiveSession()
    if not session then
        return
    end

    local snapshot = self:DeserializeSessionSnapshot(payload)
    if self.SessionMode == "guest" and snapshot.rosterLocked then
        local playerName = UnitName and UnitName("player") or self.PlayerKey
        local playerKey = self:GetUnitSheetSyncKey("player")
        if not HasSessionKey(snapshot.players, playerName) and not HasSessionKey(snapshot.players, playerKey) then
            if self.SessionJoinGraceUntil and (time and time() or 0) <= self.SessionJoinGraceUntil then
                self:SendSessionMessage("REQ:" .. sessionId)
                return
            end
            self:WipeSession()
            print("DiceSim: you were removed from the session.")
            return
        end
    end

    local lastRevision = self.LastAppliedRemoteSessionRevision or -1
    local nextRevision = tonumber(snapshot.revision) or 0
    if nextRevision > 0 and nextRevision <= lastRevision then
        return
    end

    session.host = sender or session.host
    session.snapshot = snapshot
    session.updated = time()
    self.SessionJoinGraceUntil = nil
    self.LastAppliedRemoteSessionRevision = nextRevision
    self.IsApplyingRemoteSessionSnapshot = true
    self:RestoreSessionSnapshot()
    self.IsApplyingRemoteSessionSnapshot = false
    self:RefreshSessionPanel()
end

function DiceSim:RestoreSessionSnapshot()
    local session = self:GetActiveSession()
    if not session or not session.snapshot or not self.Canvas then
        return
    end

    local snapshot = session.snapshot
    self.IsApplyingSessionSnapshot = true

    for _, object in ipairs(self.CanvasObjects or {}) do
        object:Hide()
    end
    self.CanvasObjects = {}

    for _, symbol in pairs(self.CanvasSymbols or {}) do
        symbol:Hide()
    end
    self.CanvasSymbols = {}

    for _, data in ipairs(snapshot.panels or {}) do
        local panel = self:CreateCanvasPanel(data.panelType or "Neutral")
        if panel then
            panel.PanelNumber = data.number or panel.PanelNumber
            panel.TargetName = data.name or panel.TargetName
            if panel.NumberLabel then
                panel.NumberLabel:SetText("#" .. panel.PanelNumber)
            end
            if panel.NameLabel then
                panel.NameLabel:SetText(panel.TargetName)
            end
            if panel.Portrait and data.portrait then
                panel.Portrait:SetTexture(data.portrait)
            end
            local defaultHp, defaultHpMax = self:GetDefaultSheetMetric("hp")
            local defaultEnergy, defaultEnergyMax = self:GetDefaultSheetMetric("energy")
            local defaultArmor, defaultArmorMax = self:GetDefaultSheetMetric("armor")
            self:SetMetricBar(panel.HPBar, data.hp or defaultHp, data.hpMax or defaultHpMax)
            self:SetMetricBar(panel.EnergyBar, data.energy or defaultEnergy, data.energyMax or defaultEnergyMax)
            self:SetMetricBar(panel.ArmorBar, data.armor or defaultArmor, data.armorMax or defaultArmorMax)
            self:ApplyAffectsToContext(panel, {
                buffs = data.buffs,
                debuffs = data.debuffs,
            })
            self:SetCanvasObjectPosition(panel, data.x or 0, data.y or 0)
        end
    end

    for _, data in ipairs(snapshot.symbols or {}) do
        local markerList = self.RAID_MARKERS or RAID_MARKERS or {}
        local restored = false
        for _, marker in ipairs(markerList) do
            if marker.label == data.label then
                local symbol = self:CreateCanvasSymbol(marker)
                if symbol then
                    self:SetCanvasObjectPosition(symbol, data.x or 0, data.y or 0)
                end
                restored = true
                break
            end
        end
        if not restored and data.label and data.icon then
            local symbol = self:CreateCanvasSymbol({ label = data.label, icon = data.icon })
            if symbol then
                self:SetCanvasObjectPosition(symbol, data.x or 0, data.y or 0)
            end
        end
    end

    if snapshot.canvas then
        self:SetCanvasBackground(snapshot.canvas.background or "default", snapshot.canvas.backgroundLabel or "Default")
    end

    if not self.IsApplyingRemoteSessionSnapshot and snapshot.canvas then
        self.Zoom = snapshot.canvas.zoom or self.Zoom
        self.CanvasX = snapshot.canvas.x or self.CanvasX
        self.CanvasY = snapshot.canvas.y or self.CanvasY
        self:RefreshCanvas()
    end

    self.InitiativeEntries = snapshot.initiative or self.InitiativeEntries
    self.EventLogEntries = snapshot.eventLog or self.EventLogEntries
    self.SessionPlayers = snapshot.players or self.SessionPlayers
    self.SessionAssistants = snapshot.assistants or self.SessionAssistants
    self.SessionHiddenPlayers = snapshot.hiddenPlayers or self.SessionHiddenPlayers
    self.SessionRosterLocked = snapshot.rosterLocked and true or false
    if snapshot.round then
        self.RoundNumber = math.max(1, math.floor(tonumber(snapshot.round.number) or 1))
        if self.RoundsTracker then
            self.RoundsTracker:SetShown(snapshot.round.shown and true or false)
            self:RefreshRoundsTracker()
        end
    end
    self:RefreshInitiativeList()
    self:RefreshEventLog()
    self:RefreshDiceTargets()
    self:RefreshPermissions()
    if self.RefreshCharacterTabs then
        self:RefreshCharacterTabs()
    end
    self.IsApplyingSessionSnapshot = false
end

function DiceSim:SendSessionMessage(payload)
    if not payload or payload == "" then
        return
    end

    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
        if IsInRaid and IsInRaid() then
            C_ChatInfo.SendAddonMessage(PREFIX, payload, "RAID")
        elseif IsInGroup and IsInGroup() then
            C_ChatInfo.SendAddonMessage(PREFIX, payload, "PARTY")
        end
    end
end

function DiceSim:SendSessionMessageTo(payload, target)
    if not payload or payload == "" or not target then
        return
    end

    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
        C_ChatInfo.SendAddonMessage(PREFIX, payload, "WHISPER", target)
    end
end

function DiceSim:SendChunkedSessionPayload(command, sessionId, serializedSnapshot, target)
    if not serializedSnapshot or serializedSnapshot == "" then
        return
    end

    local total = math.ceil(#serializedSnapshot / CHUNK_SIZE)
    local sequence = tostring(time()) .. tostring(math.random(100, 999))

    for index = 1, total do
        local chunk = string.sub(serializedSnapshot, ((index - 1) * CHUNK_SIZE) + 1, index * CHUNK_SIZE)
        local payload = command .. ":" .. sessionId .. ":" .. sequence .. ":" .. index .. ":" .. total .. ":" .. chunk

        if target then
            self:SendSessionMessageTo(payload, target)
        else
            self:SendSessionMessage(payload)
        end
    end
end

function DiceSim:BroadcastSessionSnapshot(target)
    if self.SessionMode ~= "host" or self.IsApplyingSessionSnapshot then
        return
    end

    local session = self:GetActiveSession()
    if not session or not session.snapshot then
        return
    end

    self:SendChunkedSessionPayload("SNAP", session.id, self:SerializeSessionSnapshot(session.snapshot), target)
    self.LastSessionBroadcast = time()
    self.SessionBroadcastQueued = false
end

function DiceSim:ProcessSessionSync()
    if not self.ActiveSessionId then
        return
    end

    local now = time()

    if self.SessionMode == "host" then
        if self.SessionBroadcastQueued and (not self.LastSessionBroadcast or now - self.LastSessionBroadcast >= BROADCAST_THROTTLE_SECONDS) then
            self:BroadcastSessionSnapshot()
        elseif not self.LastSessionHeartbeat or now - self.LastSessionHeartbeat >= HOST_HEARTBEAT_SECONDS then
            self.LastSessionHeartbeat = now
            self:BroadcastSessionSnapshot()
        end
    elseif self.SessionMode == "guest" then
        if not self.LastSessionRequest or now - self.LastSessionRequest >= GUEST_REQUEST_SECONDS then
            self.LastSessionRequest = now
            self:SendSessionMessage("REQ:" .. self.ActiveSessionId)
        end
    end
end

function DiceSim:ReceiveSessionChunk(command, sessionId, sequence, index, total, chunk, sender)
    if sessionId ~= self.ActiveSessionId then
        return
    end

    self.SessionChunks = self.SessionChunks or {}
    local key = sender .. ":" .. sequence
    local buffer = self.SessionChunks[key] or { chunks = {}, total = tonumber(total) or 1, command = command, sessionId = sessionId, sender = sender }
    self.SessionChunks[key] = buffer
    buffer.chunks[tonumber(index) or 1] = chunk or ""

    for chunkIndex = 1, buffer.total do
        if not buffer.chunks[chunkIndex] then
            return
        end
    end

    local payload = table.concat(buffer.chunks, "")
    self.SessionChunks[key] = nil

    if command == "SNAP" then
        self:ApplyRemoteSessionSnapshot(sessionId, payload, sender)
    end
end

function DiceSim:HandleSessionMessage(prefix, payload, channel, sender)
    if prefix ~= PREFIX or not payload then
        return
    end

    sender = sender or "unknown"

    local announcement = string.match(payload, "^ANN:(.*)$")
    if announcement then
        local playerName = UnitName and UnitName("player") or nil
        if sender == self.PlayerKey or sender == playerName then
            return
        end

        self.LastRemoteAnnouncement = {
            text = announcement,
            sender = sender,
            time = time(),
        }
        self:ShowAnnouncementPopup(announcement)
        self:AddEventLogEntry("Raid Announce: " .. announcement)
        return
    end

    local roundNumber, roundShown = string.match(payload, "^RND:(%d+):([01])$")
    if roundNumber then
        self.RoundNumber = math.max(1, math.floor(tonumber(roundNumber) or 1))
        if self.RoundsTracker then
            self.RoundsTracker:SetShown(roundShown == "1")
            self:RefreshRoundsTracker()
        end
        self:AddEventLogEntry("Round set to " .. self.RoundNumber .. ".")
        return
    end

    local sheetPayload = string.match(payload, "^SHEET:(.*)$")
    if sheetPayload then
        local playerName = UnitName and UnitName("player") or nil
        if sender == self.PlayerKey or NormalizeSenderKey(sender) == NormalizeSenderKey(playerName) then
            return
        end

        self:StoreRemoteSheetState(sender, sheetPayload)
        return
    end

    local adminSheetTarget, adminSheetPayload = string.match(payload, "^SHEETA:([^:]+):(.*)$")
    if adminSheetTarget then
        self:StoreRemoteSheetState(sender, adminSheetPayload, adminSheetTarget)
        return
    end

    local sheetSequence, sheetIndex, sheetTotal, sheetChunk = string.match(payload, "^SHEETC:([^:]+):(%d+):(%d+):(.*)$")
    if sheetSequence then
        local playerName = UnitName and UnitName("player") or nil
        if sender == self.PlayerKey or NormalizeSenderKey(sender) == NormalizeSenderKey(playerName) then
            return
        end

        self:ReceiveSheetChunk(sheetSequence, sheetIndex, sheetTotal, sheetChunk, sender)
        return
    end

    local adminSheetSequence, adminSheetIndex, adminSheetTotal, adminSheetChunk = string.match(payload, "^SHEETAC:([^:]+):(%d+):(%d+):(.*)$")
    if adminSheetSequence then
        self:ReceiveSheetChunk(adminSheetSequence, adminSheetIndex, adminSheetTotal, adminSheetChunk, sender, true)
        return
    end

    local snapSession, sequence, index, total, chunk = string.match(payload, "^SNAP:([^:]+):([^:]+):(%d+):(%d+):(.*)$")
    if snapSession then
        self:ReceiveSessionChunk("SNAP", snapSession, sequence, index, total, chunk, sender)
        return
    end

    local kickSession, kickTarget = string.match(payload, "^KICK:([^:]+):(.+)$")
    if kickSession and kickSession == self.ActiveSessionId then
        local playerName = UnitName and UnitName("player") or nil
        if NormalizeSenderKey(kickTarget) == NormalizeSenderKey(playerName) or NormalizeSenderKey(kickTarget) == NormalizeSenderKey(self.PlayerKey) then
            if self.SessionJoinGraceUntil and (time and time() or 0) <= self.SessionJoinGraceUntil then
                self:SendSessionMessage("REQ:" .. kickSession)
                return
            end
            self:WipeSession()
            print("DiceSim: you were removed from the session.")
        end
        return
    end

    local inviteSession, inviteTarget = string.match(payload, "^INVITE:([^:]+):(.+)$")
    if inviteSession then
        local playerName = UnitName and UnitName("player") or nil
        if NormalizeSenderKey(inviteTarget) == NormalizeSenderKey(playerName) or NormalizeSenderKey(inviteTarget) == NormalizeSenderKey(self.PlayerKey) then
            self:PromptSessionInvite(inviteSession, sender)
        end
        return
    end

    local hideSession, hideTarget, hideState = string.match(payload, "^HIDE:([^:]+):(.+):([01])$")
    if hideSession and hideSession == self.ActiveSessionId then
        self.SessionHiddenPlayers = self.SessionHiddenPlayers or {}
        self.SessionHiddenPlayers[NormalizeSenderKey(hideTarget)] = hideState == "1" or nil
        self.SessionHiddenPlayers[hideTarget] = hideState == "1" or nil
        if self.RefreshCharacterTabs then
            self:RefreshCharacterTabs()
        end
        return
    end

    local acceptSession, acceptTarget = string.match(payload, "^ACCEPT:([^:]+):(.+)$")
    if acceptSession and self.SessionMode == "host" and acceptSession == self.ActiveSessionId then
        local senderKey = NormalizeSenderKey(sender)
        local targetKey = NormalizeSenderKey(acceptTarget)
        self.SessionPlayers = self.SessionPlayers or {}
        self.SessionPlayers[senderKey] = true
        self.SessionPlayers[targetKey] = true
        ClearSessionKey(self.SessionPendingInvites, senderKey)
        ClearSessionKey(self.SessionPendingInvites, targetKey)
        self:SaveSessionSnapshot()
        self:RefreshSessionPanel()
        self:BroadcastSessionSnapshot(sender)
        return
    end

    local command, value = string.match(payload, "^(%S+):?(.*)$")
    if (command == "JOIN" or command == "REQ") and self.SessionMode == "host" and value == self.ActiveSessionId then
        local senderKey = NormalizeSenderKey(sender)
        if self.SessionRosterLocked and self.SessionPlayers and not HasSessionKey(self.SessionPlayers, senderKey) and not HasSessionKey(self.SessionPlayers, sender) then
            if HasSessionKey(self.SessionPendingInvites, senderKey) or HasSessionKey(self.SessionPendingInvites, sender) then
                self.SessionPlayers[senderKey] = true
                ClearSessionKey(self.SessionPendingInvites, senderKey)
                ClearSessionKey(self.SessionPendingInvites, sender)
                self:SaveSessionSnapshot()
                self:RefreshSessionPanel()
            else
                self:SendSessionMessageTo("KICK:" .. self.ActiveSessionId .. ":" .. sender, sender)
                return
            end
        elseif command == "JOIN" then
            self.SessionPlayers = self.SessionPlayers or {}
            self.SessionPlayers[senderKey] = true
            self:SaveSessionSnapshot()
            self:RefreshSessionPanel()
        end

        self:AddEventLogEntry((sender or "A player") .. " requested session state for " .. value .. ".")
        self:BroadcastSessionSnapshot(sender)
    end
end
