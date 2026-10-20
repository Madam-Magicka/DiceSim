local DiceSim = _G.DiceSim

function DiceSim:RegisterSlashCommands()
    SLASH_DICESIM1 = "/dicesim"
    SLASH_DICESIM2 = "/dsim"
    SlashCmdList.DICESIM = function(message)
        DiceSim:HandleSlash(message)
    end
end

local ROLE_ALIASES = {
    admin = "admin",
    dm = "admin",
    assistant = "assistant",
    assist = "assistant",
    helper = "assistant",
    user = "user",
    player = "user",
}

function DiceSim:HandleSlash(message)
    local command, value = string.match(message or "", "^(%S*)%s*(.-)$")
    command = string.lower(command or "")
    value = string.lower(value or "")

    if command == "role" then
        self:SetRole(ROLE_ALIASES[value] or value)
        return
    end

    if ROLE_ALIASES[command] then
        self:SetRole(ROLE_ALIASES[command])
        return
    end

    if command == "perms" or command == "permissions" then
        print("DiceSim role: " .. (self.RoleLabels[self:GetRole()] or self:GetRole()))
        print("Switch with: /dicesim admin, /dicesim assistant, /dicesim player")
        print("Also works: /dicesim role admin, /dicesim role assistant, /dicesim role user")
        return
    end

    if command == "help" or command == "?" then
        print("DiceSim: /dicesim toggles the window.")
        print("DiceSim: /dicesim admin, assistant, or player changes your local role.")
        print("DiceSim: /dicesim perms shows your current local role.")
        return
    end

    self:Toggle()
end
