local DiceSim = _G.DiceSim

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_ENTERING_WORLD")
loader:RegisterEvent("UNIT_HEALTH")
loader:RegisterEvent("UNIT_MAXHEALTH")
loader:RegisterEvent("UNIT_PORTRAIT_UPDATE")
loader:RegisterEvent("GROUP_ROSTER_UPDATE")
loader:RegisterEvent("CHAT_MSG_ADDON")
loader:SetScript("OnEvent", function(_, event, arg1, ...)
    if event == "ADDON_LOADED" and arg1 ~= DiceSim.AddonName then
        return
    end

    if event == "ADDON_LOADED" then
        DiceSim:InitializeSettings()
        DiceSim:InitializePermissions()
        DiceSim:InitializeSessions()
        DiceSim:CreateMinimapButton()
        DiceSim:RegisterSlashCommands()
        return
    end

    if event == "CHAT_MSG_ADDON" then
        local payload, channel, sender = ...
        DiceSim:HandleSessionMessage(arg1, payload, channel, sender)
        return
    end

    if arg1 == "player" or event == "PLAYER_ENTERING_WORLD" or event == "GROUP_ROSTER_UPDATE" then
        if DiceSim.Frame then
            DiceSim:RefreshCharacterTabs()
            DiceSim:RefreshDiceTargets()
        end
    end
end)
