local DiceSim = _G.DiceSim

DiceSim.Tutorials = {
    general = {
        title = "DiceSim",
        lines = {
            "DiceSim is a tabletop-style sandbox for dice rolls, character sheets, canvas panels, buffs, debuffs, initiative, and lightweight multiplayer sessions.",
            "The default setup is intentionally neutral. Attributes, points, HP, Energy, Armor, and modifiers start at zero so your group can shape the rules instead of being pushed toward one dice system.",
            "Use the bottom tray to open the main tools. Most floating panels can be moved, resized, and closed independently.",
            "Admins manage shared canvas tools and sessions. Assistant admins can help with most table-management tasks. Players control their own identity, profiles, imports, and local settings.",
        },
    },
    add = {
        title = "Add Panel",
        lines = {
            "The Add panel places shared objects on the main canvas.",
            "Raid markers and number symbols are simple canvas symbols for positioning, notes, turn order, or encounter planning. Enemy, Friendly, and Neutral panels create full canvas actors with portrait, name, HP, Energy, Armor, buffs, debuffs, and roll actions.",
            "Backgrounds changes the shared canvas backdrop for the active session.",
            "Only admins and assistant admins can add canvas objects. In a hosted session, canvas changes are saved into the session snapshot and broadcast to players who have joined.",
            "Use the exit button to close the Add panel when you are done placing objects.",
        },
    },
    dice = {
        title = "Dice Panel",
        lines = {
            "The Dice panel is for player-side rolls.",
            "Choose a dice type, action, target, manual modifier, and optional effect dice. The final roll total is the dice result plus the modifier plus any matching buffs or debuffs.",
            "Default actions are placeholders and do not calculate automatic modifiers. Imported actions can calculate modifiers if the imported JSON defines modifier rules.",
            "The Action dropdown is split into Default and Imported groups. Default contains the built-in placeholder actions by attribute. Imported contains actions from your local dice-system JSON.",
            "Buffs and debuffs apply when their Applies To value matches the selected action, or when they apply to All Rolls.",
            "Choosing an Initiative action adds the roller to the initiative tracker automatically.",
            "Effect Dice is separate from the main roll total. It is useful for damage, healing, or secondary outcomes.",
        },
    },
    sheet = {
        title = "Sheet Panel",
        lines = {
            "The Sheet panel stores your character identity, profiles, attributes, resources, portrait ring, buffs, debuffs, and imported dice-system state.",
            "Profiles let you save and reload different character sheets. The profile name controls are yours only: admins cannot select, create, remove, or rename your profiles.",
            "Attributes start as neutral placeholders. You can rename them, add rows, remove rows, and set values. Points show how much of your current point budget remains.",
            "HP, Energy, and Armor use a current/max format. Type values with a slash, such as 7/20, 0/0, or 15/15. The number before the slash is the current value; the number after the slash is the maximum. The plus and minus buttons change the current value.",
            "Click your portrait to choose a portrait ring. The selected ring appears on your Sheet portrait and on your compact character panel around the main container.",
            "Buffs and debuffs on your sheet can modify your rolls. They appear as icons with hover tooltips.",
            "Use the folder button near the top right to import or reset your local dice system JSON.",
            "Admins can help edit sheet mechanics and buffs for players, but they cannot change character name, class, biography, profile controls, or dice-system imports.",
            "Other players can see the sheet state you broadcast, including whether you are using the default sheet or an imported system.",
        },
    },
    diceSystemImport = {
        title = "Dice System Import",
        lines = {
            "The import panel lets you paste dice-system JSON for your own character sheet.",
            "Imported JSON can define attributes, imported actions, modifier rules, point budget, HP, Energy, and Armor defaults.",
            "Metric defaults can use current/max-style values through JSON fields like value and max. Once imported, they appear in the Sheet as HP, Energy, and Armor counters.",
            "Imported actions appear under the Imported group in action dropdowns. If the JSON includes modifier rules, those imported actions can auto-fill the modifier box from your sheet attributes.",
            "Reset clears the imported data and returns the Sheet to DiceSim's neutral placeholder defaults: zero points, zero attributes, and 0/0 metrics.",
            "Imports are player-side. Other players see your resulting sheet state and imported-system label, not the full JSON rules text.",
            "If a JSON import fails, check commas, quotation marks, and top-level object structure first.",
            "Example:\n{\n  \"name\": \"Arena Rules\",\n  \"points\": 22,\n  \"hp\": { \"value\": 10, \"max\": 20 },\n  \"energy\": { \"value\": 5, \"max\": 12 },\n  \"armor\": { \"value\": 2, \"max\": 8 },\n  \"attributes\": [\n    { \"id\": \"might\", \"label\": \"Might\", \"default\": 2 }\n  ],\n  \"actions\": [\n    { \"id\": \"smash\", \"label\": \"Smash\", \"attribute\": \"might\", \"dice\": \"D20\" }\n  ]\n}",
        },
    },
    dm = {
        title = "DM Panel",
        lines = {
            "The DM panel gathers table-management tools for admins and assistant admins.",
            "Raid Announce sends a visible announcement to the group and records it in the event log.",
            "Add/Remove Player controls whether a player's compact portrait is shown around the main container. This is visibility only; it does not kick them from the hosted DiceSim session.",
            "Promote/Demote controls assistant admin status. Assistants can help manage tools, but self-promotion and self-demotion are hidden.",
            "The initiative list is filled automatically when a player or canvas actor rolls an Initiative action.",
            "Rounds opens the round tracker. Round state is part of the active session snapshot.",
            "Session invite and kick controls live in the Session panel. They use the current party or raid roster.",
        },
    },
    session = {
        title = "Session Panel",
        lines = {
            "The Session panel controls multiplayer sync.",
            "Host Session creates a shared DiceSim session. Session data includes canvas panels, symbols, backgrounds, initiative, rounds, event log entries, hidden character portraits, and roster state.",
            "Invite Player sends an invite prompt to a party or raid member. Players must accept before joining, which prevents forced invites.",
            "Kick Player removes a joined player from the DiceSim session. Kicking does not remove them from the World of Warcraft party or raid.",
            "Restore Saved reapplies the latest local session snapshot for the active session.",
            "Wipe Local Session clears your local saved session data after confirmation. It should not wipe the host's session for other players.",
            "Invite, pending, and joined states use different icons in roster dropdowns so you can see who is not invited, waiting, or active.",
        },
    },
    eventLog = {
        title = "Event Log",
        lines = {
            "The Event Log records roll results, announcements, session changes, and other table activity.",
            "Roll entries include the actor, target, action, dice result, modifier, buff/debuff contribution, and final total.",
            "The log is useful for checking what happened after several rolls or session changes.",
            "In a hosted session, relevant log entries can be included in session snapshots so joined players stay aligned.",
        },
    },
    settings = {
        title = "Settings",
        lines = {
            "Settings are local to your client.",
            "Font Scale adjusts DiceSim text size across panels. This helps if tutorial text, sheet fields, or compact controls feel too small.",
            "Window Scale adjusts the overall DiceSim frame size without changing the actual session data.",
            "Reset restores the default display scaling.",
            "These settings do not affect other players in a multiplayer session.",
        },
    },
    buffDebuff = {
        title = "Buffs and Debuffs",
        lines = {
            "Buffs and debuffs are reusable roll modifiers attached to a player sheet or a canvas panel.",
            "Choose an icon, name, details, Applies To action, and modifier. Positive modifiers usually act like buffs; negative modifiers usually act like debuffs.",
            "Applies To can target All Rolls, a Default action, or an Imported action. The dropdown uses the same Default and Imported action groups as the Dice panel.",
            "When a matching action is rolled, the modifier is added to the final total and listed in the roll output.",
            "Icons appear in rows and show their name, details, Applies To target, and modifier when hovered.",
            "Use the remove controls near a row to delete icons from that row.",
        },
    },
    canvasActions = {
        title = "Canvas Actions",
        lines = {
            "Canvas Actions rolls from an enemy, friendly, or neutral panel's point of view.",
            "Choose an action, target, modifier, and optional effect dice. The dropdown uses the same Default and Imported action lists as the player Dice panel.",
            "Default actions are neutral placeholders. Imported actions can use imported JSON rules when your local sheet has a dice system loaded.",
            "Buffs and debuffs attached to that canvas panel can modify matching canvas rolls.",
            "Rolling Initiative from a canvas panel adds that panel to the initiative tracker.",
        },
    },
    canvasPanel = {
        title = "Canvas Panel",
        lines = {
            "Canvas panels represent enemies, allies, neutral characters, objects, or anything else the table wants to track.",
            "Each panel has a name, portrait, HP, Energy, Armor, buffs, debuffs, and an action button.",
            "HP, Energy, and Armor use current/max values. Click a metric bar while editing to type a value with a slash, such as 4/12 or 0/0. Plus and minus controls adjust the current value.",
            "Use the edit button to change name, portrait, metrics, buffs, and debuffs.",
            "Use the action button to roll from that panel's point of view. Initiative rolls add the panel to the initiative tracker.",
            "Admins and assistant admins can move and edit canvas panels. Players can see the resulting session state after sync.",
        },
    },
    iconPicker = {
        title = "Icon Picker",
        lines = {
            "The Icon Picker chooses artwork for buffs and debuffs.",
            "Search by typing at least a few characters. Matching macro icons appear as selectable buttons.",
            "If macro icon data is unavailable, DiceSim shows fallback effect icons so buffs and debuffs can still be created.",
            "The selected icon is saved with the buff or debuff and appears in tooltip rows.",
        },
    },
    portraitPicker = {
        title = "Portrait Picker",
        lines = {
            "The Portrait Picker chooses artwork for enemy, friendly, and neutral canvas panels.",
            "Use Jump, Previous, and Next to move through the portrait list.",
            "Choosing a portrait updates the canvas panel immediately and is saved in the session snapshot.",
            "Player sheet portraits use your character portrait and portrait ring instead of this picker.",
        },
    },
    portraitRingPicker = {
        title = "Portrait Ring Picker",
        lines = {
            "The Portrait Ring Picker changes the decorative ring around your player portrait.",
            "Click your Sheet portrait to open it. Hovering the portrait glow indicates it is clickable.",
            "The selected ring appears on your Sheet portrait and compact character panel around the main container.",
            "Ring sizes are normalized where possible, with special handling for rings that need to sit behind or around the portrait.",
            "Your ring choice is saved with your sheet data and syncs to other players.",
        },
    },
}

function DiceSim:CreateTutorialPanel(parent)
    local panel = CreatePanel(parent, "DiceSimTutorialPanel", 390, 430)
    panel:SetPoint("CENTER", parent, "CENTER", 0, 0)

    if panel.InfoButton then
        panel.InfoButton:Hide()
    end

    local closeButton = CreateTrayButton(panel, "DiceSimTutorialPanelCloseButton", "Interface\\Buttons\\UI-StopButton", "Exit")
    closeButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -10)
    WireCloseButton(closeButton, function()
        panel:Hide()
    end)

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    title:SetPoint("TOP", panel, "TOP", 0, -20)
    title:SetWidth(320)
    title:SetJustifyH("CENTER")
    panel.Title = title

    local scrollBox = CreateScrollBox(panel)
    scrollBox:SetPoint("TOPLEFT", panel, "TOPLEFT", 24, -64)
    scrollBox:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -24, 24)
    panel.ScrollBox = scrollBox

    local text = scrollBox.Content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("TOPLEFT", scrollBox.Content, "TOPLEFT", 4, -4)
    text:SetWidth(310)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetNonSpaceWrap(true)
    panel.BodyText = text

    self.TutorialPanel = panel
    panel:Hide()
    return panel
end

function DiceSim:OpenTutorial(key)
    local tutorial = self.Tutorials[key or "general"] or self.Tutorials.general
    if not self.TutorialPanel then
        self:CreateTutorialPanel(self.Frame)
    end

    self.TutorialPanel.Title:SetText(tutorial.title or "DiceSim")
    self.TutorialPanel.BodyText:SetText(table.concat(tutorial.lines or {}, "\n\n"))
    local height = math.max(260, self.TutorialPanel.BodyText:GetStringHeight() + 16)
    self.TutorialPanel.ScrollBox.Content:SetSize(310, height)
    self.TutorialPanel:Show()
    self:BringWindowToFront(self.TutorialPanel)
end
