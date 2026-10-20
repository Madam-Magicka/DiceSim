local DiceSim = _G.DiceSim

local ROLE_ADMIN = "admin"
local ROLE_ASSISTANT = "assistant"
local ROLE_USER = "user"

local ROLE_LABELS = {
    [ROLE_ADMIN] = "Admin",
    [ROLE_ASSISTANT] = "Assistant Admin",
    [ROLE_USER] = "User",
}

DiceSim.RoleLabels = ROLE_LABELS

function DiceSim:GetPlayerKey()
    local name, realm = UnitFullName and UnitFullName("player")

    if name and realm and realm ~= "" then
        return name .. "-" .. realm
    end

    if UnitName and UnitName("player") then
        return UnitName("player")
    end

    return "player"
end

function DiceSim:InitializePermissions()
    DiceSimDB = DiceSimDB or {}

    local playerKey = self:GetPlayerKey()

    self.PlayerKey = playerKey
    self.CurrentRole = ROLE_ADMIN
end

function DiceSim:GetRole()
    if self.ActiveSessionId then
        if self.SessionMode == "host" then
            return ROLE_ADMIN
        end

        local name = UnitName and UnitName("player") or self.PlayerKey
        if self.SessionAssistants and (self.SessionAssistants[name] or self.SessionAssistants[self.PlayerKey]) then
            return ROLE_ASSISTANT
        end

        return ROLE_USER
    end

    return self.CurrentRole or ROLE_USER
end

function DiceSim:SetRole(role)
    if role ~= ROLE_ADMIN and role ~= ROLE_ASSISTANT and role ~= ROLE_USER then
        print("DiceSim roles: admin, assistant, user")
        return
    end

    if self.ActiveSessionId and self.SessionMode ~= "host" then
        print("DiceSim: session roles are controlled by the host.")
        return
    end

    self.PlayerKey = self.PlayerKey or self:GetPlayerKey()
    self.CurrentRole = role
    self:RefreshPermissions()
    print("DiceSim role set to " .. (ROLE_LABELS[role] or role) .. ".")
end

function DiceSim:IsAdmin()
    return self:GetRole() == ROLE_ADMIN
end

function DiceSim:IsAssistantAdmin()
    return self:GetRole() == ROLE_ASSISTANT
end

function DiceSim:CanManageSession()
    return true
end

function DiceSim:CanManageTools()
    return self:IsAdmin() or self:IsAssistantAdmin()
end

function DiceSim:CanDeleteCanvasObjects()
    return self:IsAdmin()
end

function DiceSim:CanEditSheet(unit)
    unit = unit or (self.SheetPanel and self.SheetPanel.Unit) or "player"
    return unit == "player" or self:IsAdmin()
end

function DiceSim:CanEditSheetIdentity(unit)
    unit = unit or (self.SheetPanel and self.SheetPanel.Unit) or "player"
    return unit == "player"
end

function DiceSim:CanImportDiceSystem(unit)
    unit = unit or (self.SheetPanel and self.SheetPanel.Unit) or "player"
    return unit == "player"
end

function DiceSim:RefreshPermissions()
    if self.TopCloseButton then
        self.TopCloseButton:SetShown(self:CanManageSession())
    end

    if self.TopAddButton then
        self.TopAddButton:SetShown(self:CanManageTools())
    end

    if self.DMButton then
        self.DMButton:SetShown(self:CanManageTools())
    end

    if not self:CanManageTools() then
        if self.AddPanel then
            self.AddPanel:Hide()
        end

        if self.DMPanel then
            self.DMPanel:Hide()
        end
    end

    if self.SheetPanel then
        if self.SetSheetEditable then
            self:SetSheetEditable(self:CanEditSheet(self.SheetPanel.Unit or "player"))
        end
    end

    if self.CanvasObjects then
        for _, object in ipairs(self.CanvasObjects) do
            if object.DeleteButton then
                object.DeleteButton:SetShown(self:CanDeleteCanvasObjects())
            end

            if object.EditButton then
                object.EditButton:SetShown(self:CanManageTools())
            end

            if object.ActionButton then
                object.ActionButton:SetShown(self:CanManageTools())
            end
        end
    end

    if self.RefreshRoundsTracker then
        self:RefreshRoundsTracker()
    end
end
