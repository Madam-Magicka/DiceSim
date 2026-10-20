local DiceSim = _G.DiceSim

DiceSim.UITextures = {
    dropdownNormal = DiceSim.Theme.textures.dropdownNormal,
    dropdownDisabled = DiceSim.Theme.textures.dropdownNormal,
    dropdownHover = DiceSim.Theme.textures.dropdownHover,
    dropdownOpen = DiceSim.Theme.textures.dropdownOpen,
    dropdownPressed = DiceSim.Theme.textures.dropdownPressed,
    dropdownPressedHover = DiceSim.Theme.textures.dropdownPressedHover,
    divider = DiceSim.Theme.textures.divider,
    output = DiceSim.Theme.textures.output,
    minus = DiceSim.Theme.textures.minus,
    minusPressed = DiceSim.Theme.textures.minusHover,
    plus = DiceSim.Theme.textures.plus,
    plusPressed = DiceSim.Theme.textures.plusHover,
}

function DiceSim:SetFieldTexture(field, state)
    if not field then
        return
    end

    local theme = self.Theme
    local isLeafItem = field.IsDropdownLeafItem
    local isDropdown = field.IsDropdownField or field.IsDropdownMenuRow or isLeafItem
    local texture = isLeafItem and theme.textures.dropdownItem or theme.textures.dropdownNormal
    local bg = theme.colors.controlBg
    local border = theme.colors.controlBorder

    if state == "disabled" then
        texture = isLeafItem and theme.textures.dropdownItem or theme.textures.dropdownNormal
        bg = theme.colors.insetBg
        border = theme.colors.insetBorder
    elseif state == "hover" then
        texture = isLeafItem and theme.textures.dropdownItem or theme.textures.dropdownHover
        bg = theme.colors.controlHover
        border = theme.colors.controlBorderHover
    elseif state == "open" then
        texture = isLeafItem and theme.textures.dropdownItem or theme.textures.dropdownOpen
        bg = theme.colors.controlHover
        border = theme.colors.accent
    elseif state == "pressed" then
        texture = isLeafItem and theme.textures.dropdownItem or theme.textures.dropdownPressed
        bg = theme.colors.controlPressed
        border = theme.colors.accent
    elseif state == "pressedhover" then
        texture = isLeafItem and theme.textures.dropdownItem or theme.textures.dropdownPressedHover
        bg = theme.colors.controlPressed
        border = theme.colors.controlBorderHover
    end

    if isDropdown then
        if field.BackgroundTexture then
            field.BackgroundTexture:SetTexture(theme.textures.solid)
            field.BackgroundTexture:SetVertexColor(unpack(bg))
            field.BackgroundTexture:SetAlpha(state == "hover" and isLeafItem and 0.92 or 1)
        end

        if field.SetBackdropColor then
            field:SetBackdropColor(unpack(bg))
            field:SetBackdropBorderColor(unpack(border))
        end

        return
    end

    if field.BackgroundTexture then
        self:ApplyTextureOrAtlas(field.BackgroundTexture, texture)
        if isLeafItem and state == "hover" then
            field.BackgroundTexture:SetVertexColor(unpack(theme.colors.controlBorderHover))
        else
            field.BackgroundTexture:SetVertexColor(1, 1, 1, 1)
        end
        field.BackgroundTexture:SetAlpha(1)
    elseif field.SetBackdropColor then
        field:SetBackdropColor(unpack(bg))
        field:SetBackdropBorderColor(unpack(border))
    end
end

local PLUS_BUTTON_TEXTURE = "Interface\\Buttons\\UI-PlusButton-Up"
local MINUS_BUTTON_TEXTURE = "Interface\\Buttons\\UI-MinusButton-Up"
local GetModernButtonSymbol
local DELVE_BUTTON_EXTRA_WIDTH = 8
local DELVE_BUTTON_MIN_WIDTH = 104
local DELVE_BUTTON_HEIGHT = 30
local DELVE_BUTTON_GLOW_EXTRA_WIDTH = 4
local DELVE_BUTTON_GLOW_HEIGHT = 34
local CUSTOM_BLUE_BUTTON = {
    normal = { 0.06, 0.18, 0.34, 0.90 },
    hover = { 0.10, 0.34, 0.62, 0.68 },
    pushed = { 0.03, 0.10, 0.22, 0.96 },
    disabled = { 0.04, 0.06, 0.09, 0.56 },
    edge = { 0.84, 0.68, 0.34, 0.72 },
    edgeLow = { 0.60, 0.48, 0.24, 0.58 },
}

local function SetTextureGroupShown(textures, shown)
    if type(textures) ~= "table" then
        return
    end

    for _, texture in ipairs(textures) do
        if shown then
            texture:Show()
        else
            texture:Hide()
        end
    end
end

local function CreateChamferedFill(button, layer, color, corner)
    local pieces = {}

    local center = button:CreateTexture(nil, layer)
    center:SetPoint("TOPLEFT", button, "TOPLEFT", corner, 0)
    center:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -corner, 0)
    center:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
    table.insert(pieces, center)

    local top = button:CreateTexture(nil, layer)
    top:SetPoint("TOPLEFT", button, "TOPLEFT", corner, 0)
    top:SetPoint("TOPRIGHT", button, "TOPRIGHT", -corner, 0)
    top:SetHeight(corner)
    top:SetColorTexture(color[1] * 1.18, color[2] * 1.18, color[3] * 1.18, color[4] or 1)
    table.insert(pieces, top)

    local bottom = button:CreateTexture(nil, layer)
    bottom:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", corner, 0)
    bottom:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -corner, 0)
    bottom:SetHeight(corner)
    bottom:SetColorTexture(color[1] * 0.76, color[2] * 0.76, color[3] * 0.76, color[4] or 1)
    table.insert(pieces, bottom)

    local left = button:CreateTexture(nil, layer)
    left:SetPoint("TOPLEFT", button, "TOPLEFT", 0, -corner)
    left:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, corner)
    left:SetWidth(corner)
    left:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
    table.insert(pieces, left)

    local right = button:CreateTexture(nil, layer)
    right:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, -corner)
    right:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, corner)
    right:SetWidth(corner)
    right:SetColorTexture(color[1] * 0.86, color[2] * 0.86, color[3] * 0.86, color[4] or 1)
    table.insert(pieces, right)

    return pieces
end

local function CreateChamferedLine(button, startPoint, startX, startY, endPoint, endX, endY, alpha)
    if not button.CreateLine then
        return
    end

    local line = button:CreateLine(nil, "BORDER")
    line:SetStartPoint(startPoint, button, startX, startY)
    line:SetEndPoint(endPoint, button, endX, endY)
    line:SetThickness(1)
    line:SetColorTexture(CUSTOM_BLUE_BUTTON.edge[1], CUSTOM_BLUE_BUTTON.edge[2], CUSTOM_BLUE_BUTTON.edge[3], alpha or CUSTOM_BLUE_BUTTON.edge[4])
end

local function SkinBlueChamferedButton(button, corner)
    if not button or button.DiceSimBlueButton then
        return
    end

    corner = corner or 6
    button.DiceSimBlueButton = true

    button.NormalFill = CreateChamferedFill(button, "BACKGROUND", CUSTOM_BLUE_BUTTON.normal, corner)
    button.HoverFill = CreateChamferedFill(button, "BORDER", CUSTOM_BLUE_BUTTON.hover, corner)
    SetTextureGroupShown(button.HoverFill, false)
    button.PushedFill = CreateChamferedFill(button, "BORDER", CUSTOM_BLUE_BUTTON.pushed, corner)
    SetTextureGroupShown(button.PushedFill, false)
    button.DisabledFill = CreateChamferedFill(button, "BORDER", CUSTOM_BLUE_BUTTON.disabled, corner)
    SetTextureGroupShown(button.DisabledFill, false)

    local top = button:CreateTexture(nil, "BORDER")
    top:SetPoint("TOPLEFT", button, "TOPLEFT", corner + 1, -1)
    top:SetPoint("TOPRIGHT", button, "TOPRIGHT", -(corner + 1), -1)
    top:SetHeight(1)
    top:SetColorTexture(unpack(CUSTOM_BLUE_BUTTON.edge))

    local bottom = button:CreateTexture(nil, "BORDER")
    bottom:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", corner + 1, 1)
    bottom:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -(corner + 1), 1)
    bottom:SetHeight(1)
    bottom:SetColorTexture(unpack(CUSTOM_BLUE_BUTTON.edgeLow))

    local left = button:CreateTexture(nil, "BORDER")
    left:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -(corner + 1))
    left:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 1, corner + 1)
    left:SetWidth(1)
    left:SetColorTexture(CUSTOM_BLUE_BUTTON.edgeLow[1], CUSTOM_BLUE_BUTTON.edgeLow[2], CUSTOM_BLUE_BUTTON.edgeLow[3], 0.52)

    local right = button:CreateTexture(nil, "BORDER")
    right:SetPoint("TOPRIGHT", button, "TOPRIGHT", -1, -(corner + 1))
    right:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, corner + 1)
    right:SetWidth(1)
    right:SetColorTexture(CUSTOM_BLUE_BUTTON.edgeLow[1], CUSTOM_BLUE_BUTTON.edgeLow[2], CUSTOM_BLUE_BUTTON.edgeLow[3], 0.52)

    CreateChamferedLine(button, "TOPLEFT", 1, -corner, "TOPLEFT", corner, -1, 0.72)
    CreateChamferedLine(button, "TOPRIGHT", -corner, -1, "TOPRIGHT", -1, -corner, 0.72)
    CreateChamferedLine(button, "BOTTOMLEFT", 1, corner, "BOTTOMLEFT", corner, 1, 0.58)
    CreateChamferedLine(button, "BOTTOMRIGHT", -corner, 1, "BOTTOMRIGHT", -1, corner, 0.58)

    button:HookScript("OnEnter", function(self)
        if self:IsEnabled() then
            SetTextureGroupShown(self.HoverFill, true)
        end
    end)
    button:HookScript("OnLeave", function(self)
        SetTextureGroupShown(self.HoverFill, false)
        SetTextureGroupShown(self.PushedFill, false)
    end)
    button:HookScript("OnMouseDown", function(self)
        if self:IsEnabled() then
            SetTextureGroupShown(self.PushedFill, true)
        end
    end)
    button:HookScript("OnMouseUp", function(self)
        SetTextureGroupShown(self.PushedFill, false)
    end)
    button:HookScript("OnDisable", function(self)
        SetTextureGroupShown(self.DisabledFill, true)
    end)
    button:HookScript("OnEnable", function(self)
        SetTextureGroupShown(self.DisabledFill, false)
    end)
end

local function GetTrayButtonAtlasSet(theme, icon, tooltip)
    if tooltip == "Exit" then
        return {
            normal = theme.textures.redExit,
            hover = theme.textures.redExit,
            pressed = theme.textures.redExitPressed,
            disabled = theme.textures.redExitDisabled,
        }
    end

    if tooltip == "Minimize" then
        return {
            normal = theme.textures.redCondense,
            hover = theme.textures.redCondense,
            pressed = theme.textures.redCondensePressed,
            disabled = theme.textures.redCondenseDisabled,
        }
    end

    if tooltip == "Expand" or tooltip == "Fit Screen" then
        return {
            normal = theme.textures.redExpand,
            hover = theme.textures.redExpand,
            pressed = theme.textures.redExpandPressed,
            disabled = theme.textures.redExpandDisabled,
        }
    end

    if icon == PLUS_BUTTON_TEXTURE then
        return {
            normal = theme.textures.plus,
            hover = theme.textures.plusHover,
            pressed = theme.textures.plusHover,
            disabled = theme.textures.plusDisabled,
        }
    end

    if icon == MINUS_BUTTON_TEXTURE then
        return {
            normal = theme.textures.minus,
            hover = theme.textures.minusHover,
            pressed = theme.textures.minusHover,
            disabled = theme.textures.minusDisabled,
        }
    end

    return nil
end

local function GetTrayButtonSymbol(icon, tooltip)
    if tooltip == "Exit" or tooltip == "Remove" then
        return "x"
    end

    if tooltip == "Minimize" then
        return "minus"
    end

    if tooltip == "Expand" or tooltip == "Fit Screen" then
        return "expand"
    end

    return GetModernButtonSymbol(icon)
end

local function SetTrayButtonAtlasState(button, state)
    if not button.AtlasSet or not button.Icon then
        return false
    end

    local atlas = button.AtlasSet[state] or button.AtlasSet.normal
    DiceSim:ApplyTextureOrAtlas(button.Icon, atlas, false)
    button.Icon:SetVertexColor(1, 1, 1, 1)
    button.Icon:SetAlpha(1)
    return true
end

GetModernButtonSymbol = function(icon)
    if icon == PLUS_BUTTON_TEXTURE then
        return "plus"
    end

    if icon == MINUS_BUTTON_TEXTURE then
        return "minus"
    end

    return nil
end

local function SetTrayButtonIconColor(button, r, g, b, a)
    if button.SymbolLines then
        for _, line in ipairs(button.SymbolLines) do
            line:SetVertexColor(r, g, b, a)
        end
        return
    end

    if button.Icon then
        button.Icon:SetVertexColor(r, g, b, a)
    end
end

local function GetTrayButtonOffset(button)
    local offsetX = button and button.IconOffsetX or 0
    local offsetY = button and button.IconOffsetY or 0

    local parent = button and button:GetParent()
    while parent do
        if parent.TrayButtonIconOffsetX ~= nil or parent.TrayButtonIconOffsetY ~= nil then
            offsetX = offsetX + (parent.TrayButtonIconOffsetX or 0)
            offsetY = offsetY + (parent.TrayButtonIconOffsetY or 0)
            break
        end
        parent = parent:GetParent()
    end

    return offsetX, offsetY
end

local function LayoutTrayButtonIcon(button, offsetX, offsetY)
    local baseOffsetX, baseOffsetY = GetTrayButtonOffset(button)
    offsetX = (offsetX or 0) + baseOffsetX
    offsetY = (offsetY or 0) + baseOffsetY

    if button.SymbolLines then
        local size = button.IconSize or DiceSim.Theme.sizes.icon
        local lineLength = math.max(12, math.floor(size * 0.72))
        local lineThickness = math.max(2, math.floor(size * 0.12))

        if button.SymbolHorizontal then
            button.SymbolHorizontal:ClearAllPoints()
            button.SymbolHorizontal:SetPoint("CENTER", button, "CENTER", offsetX, offsetY)
            button.SymbolHorizontal:SetSize(lineLength, lineThickness)
        end

        if button.SymbolVertical then
            button.SymbolVertical:ClearAllPoints()
            button.SymbolVertical:SetPoint("CENTER", button, "CENTER", offsetX, offsetY)
            button.SymbolVertical:SetSize(lineThickness, lineLength)
        end

        if button.SymbolSlashA then
            button.SymbolSlashA:ClearAllPoints()
            button.SymbolSlashA:SetPoint("CENTER", button, "CENTER", offsetX, offsetY)
            button.SymbolSlashA:SetSize(lineLength, lineThickness)
            button.SymbolSlashA:SetRotation(0.785398)
        end

        if button.SymbolSlashB then
            button.SymbolSlashB:ClearAllPoints()
            button.SymbolSlashB:SetPoint("CENTER", button, "CENTER", offsetX, offsetY)
            button.SymbolSlashB:SetSize(lineLength, lineThickness)
            button.SymbolSlashB:SetRotation(-0.785398)
        end

        if button.SymbolArrowA then
            button.SymbolArrowA:ClearAllPoints()
            button.SymbolArrowA:SetPoint("CENTER", button, "CENTER", offsetX - math.floor(size * 0.11), offsetY - math.floor(size * 0.11))
            button.SymbolArrowA:SetSize(lineLength * 0.55, lineThickness)
            button.SymbolArrowA:SetRotation(0.785398)
        end

        if button.SymbolArrowB then
            button.SymbolArrowB:ClearAllPoints()
            button.SymbolArrowB:SetPoint("CENTER", button, "CENTER", offsetX + math.floor(size * 0.11), offsetY + math.floor(size * 0.11))
            button.SymbolArrowB:SetSize(lineLength * 0.55, lineThickness)
            button.SymbolArrowB:SetRotation(0.785398)
        end
        return
    end

    if button.Icon then
        button.Icon:ClearAllPoints()
        button.Icon:SetPoint("CENTER", offsetX, offsetY)
        button.Icon:SetSize(button.IconSize or DiceSim.Theme.sizes.icon, button.IconSize or DiceSim.Theme.sizes.icon)
    end
end

local function SetTrayButtonIconSize(button, size)
    button.IconSize = size
    LayoutTrayButtonIcon(button)
end

function DiceSim:CreateTrayButton(parent, name, icon, tooltip)
    local theme = self.Theme
    local button = CreateFrame("Button", name, parent, "BackdropTemplate")
    button:SetSize(theme.sizes.iconButton, theme.sizes.iconButton)
    button:SetBackdrop(nil)
    button.SetIconSize = SetTrayButtonIconSize

    local texture = button:CreateTexture(nil, "ARTWORK")
    texture:SetPoint("CENTER")
    texture:SetSize(theme.sizes.icon, theme.sizes.icon)
    button.Icon = texture
    button.IconSize = theme.sizes.icon

    local atlasSet = GetTrayButtonAtlasSet(theme, icon, tooltip)
    local symbol = not atlasSet and GetTrayButtonSymbol(icon, tooltip)

    if atlasSet then
        button.AtlasSet = atlasSet
        SetTrayButtonAtlasState(button, "normal")
    elseif symbol then
        if tooltip == "Remove" then
            SkinBlueChamferedButton(button, 6)
        end

        texture:SetTexture(theme.textures.solid)
        texture:SetAlpha(0)

        button.SymbolLines = {}

        if symbol == "plus" or symbol == "minus" then
            local horizontal = button:CreateTexture(nil, "ARTWORK")
            horizontal:SetTexture(theme.textures.solid)
            horizontal:SetVertexColor(1, 1, 1, 1)
            button.SymbolHorizontal = horizontal
            table.insert(button.SymbolLines, horizontal)
        end

        if symbol == "plus" then
            local vertical = button:CreateTexture(nil, "ARTWORK")
            vertical:SetTexture(theme.textures.solid)
            vertical:SetVertexColor(1, 1, 1, 1)
            button.SymbolVertical = vertical
            table.insert(button.SymbolLines, vertical)
        end

        if symbol == "x" then
            local slashA = button:CreateTexture(nil, "ARTWORK")
            slashA:SetTexture(theme.textures.solid)
            slashA:SetVertexColor(1, 1, 1, 1)
            local slashB = button:CreateTexture(nil, "ARTWORK")
            slashB:SetTexture(theme.textures.solid)
            slashB:SetVertexColor(1, 1, 1, 1)
            button.SymbolSlashA = slashA
            button.SymbolSlashB = slashB
            table.insert(button.SymbolLines, slashA)
            table.insert(button.SymbolLines, slashB)
        end

        if symbol == "expand" then
            local arrowA = button:CreateTexture(nil, "ARTWORK")
            arrowA:SetTexture(theme.textures.solid)
            arrowA:SetVertexColor(1, 1, 1, 1)
            local arrowB = button:CreateTexture(nil, "ARTWORK")
            arrowB:SetTexture(theme.textures.solid)
            arrowB:SetVertexColor(1, 1, 1, 1)
            button.SymbolArrowA = arrowA
            button.SymbolArrowB = arrowB
            table.insert(button.SymbolLines, arrowA)
            table.insert(button.SymbolLines, arrowB)
        end

        LayoutTrayButtonIcon(button)
    else
        self:ApplyTextureOrAtlas(texture, icon)
    end

    LayoutTrayButtonIcon(button)

    local hover = button:CreateTexture(nil, "BACKGROUND")
    hover:SetPoint("CENTER")
    hover:SetSize(theme.sizes.iconButton - 4, theme.sizes.iconButton - 4)
    hover:SetTexture(theme.textures.solid)
    hover:SetColorTexture(unpack(theme.colors.controlHover))
    hover:SetAlpha(0)
    button.HoverTexture = hover

    button:SetScript("OnEnter", function(self)
        if not self.IsAssetButton then
            if not SetTrayButtonAtlasState(self, "hover") then
                self.HoverTexture:SetAlpha(0.42)
                SetTrayButtonIconColor(self, unpack(theme.colors.accent))
            end
        end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(tooltip)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function(self)
        if not self.IsAssetButton then
            self.HoverTexture:SetAlpha(0)
            if not SetTrayButtonAtlasState(self, "normal") then
                SetTrayButtonIconColor(self, 1, 1, 1, 1)
            end
        end
        GameTooltip:Hide()
    end)

    button:SetScript("OnMouseDown", function(self)
        if self.IsAssetButton then
            return
        end

        if not SetTrayButtonAtlasState(self, "pressed") then
            LayoutTrayButtonIcon(self, 1, -1)
            self.HoverTexture:SetAlpha(0.62)
        end
    end)

    button:SetScript("OnMouseUp", function(self)
        if self.IsAssetButton then
            return
        end

        if not SetTrayButtonAtlasState(self, "hover") then
            LayoutTrayButtonIcon(self)
            self.HoverTexture:SetAlpha(0.42)
        end
    end)

    button:HookScript("OnSizeChanged", function(self, width, height)
        if self.HoverTexture then
            self.HoverTexture:SetSize(math.max(1, (width or self:GetWidth()) - 4), math.max(1, (height or self:GetHeight()) - 4))
        end
        LayoutTrayButtonIcon(self)
    end)
    button:HookScript("OnDisable", function(self)
        SetTrayButtonAtlasState(self, "disabled")
        if self.HoverTexture then
            self.HoverTexture:SetAlpha(0)
        end
    end)
    button:HookScript("OnEnable", function(self)
        SetTrayButtonAtlasState(self, "normal")
    end)

    return button
end

function DiceSim:CreateEditButton(parent, name, size)
    size = size or self.Theme.sizes.smallIconButton
    local button = self:CreateTrayButton(parent, name, self.EditIcon, "Edit")
    button:SetSize(size, size)
    SetTrayButtonIconSize(button, math.max(16, size - 8))
    if button.HoverTexture then
        button.HoverTexture:SetSize(size - 4, size - 4)
    end
    return button
end

function DiceSim:CreateContainerInfoButton(parent, tooltip)
    if parent.InfoButton then
        return parent.InfoButton
    end

    local button = self:CreateTrayButton(parent, nil, self.Theme.textures.info, tooltip or "Information")
    local buttonSize = self.Theme.sizes.smallIconButton + 8
    local iconSize = self.Theme.sizes.smallIcon + 8
    button:SetSize(buttonSize, buttonSize)
    SetTrayButtonIconSize(button, iconSize)
    if button.HoverTexture then
        button.HoverTexture:SetSize(buttonSize - 4, buttonSize - 4)
    end
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10)
    parent.InfoButton = button
    return button
end

function DiceSim:WireCloseButton(button, onClose)
    button:SetFrameLevel(button:GetParent():GetFrameLevel() + 30)
    button:SetScript("OnMouseDown", function(_, mouseButton)
        if mouseButton == "LeftButton" then
            onClose()
        end
    end)
    button:SetScript("OnClick", nil)
end

function DiceSim:CreateTray(parent, name, width, height)
    local tray = CreateFrame("Frame", name, parent, "BackdropTemplate")
    tray:SetSize(width, height)
    tray:SetBackdrop(nil)
    return tray
end

function DiceSim:CreatePanelButton(parent, text)
    local theme = self.Theme
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(110, theme.sizes.textButtonHeight)
    button:SetBackdrop(nil)

    SkinBlueChamferedButton(button, 6)

    local label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.Label = label

    if label then
        label:ClearAllPoints()
        label:SetPoint("LEFT", button, "LEFT", 8, 0)
        label:SetPoint("RIGHT", button, "RIGHT", -8, 0)
        label:SetHeight(18)
        label:SetJustifyH("CENTER")
        label:SetJustifyV("MIDDLE")
        label:SetWordWrap(false)
        label:SetText(text or "")
        self:SetFontColor(label, theme.colors.text)
    end

    button.SetText = function(self, value)
        if self.Label then
            self.Label:SetText(value or "")
        end
    end

    button:HookScript("OnDisable", function(self)
        if self.Label then
            self.Label:SetAlpha(0.65)
        end
    end)
    button:HookScript("OnEnable", function(self)
        if self.Label then
            self.Label:SetAlpha(1)
        end
    end)

    button:HookScript("OnSizeChanged", function(self)
        if self.Label then
            self.Label:ClearAllPoints()
            self.Label:SetPoint("LEFT", self, "LEFT", 8, 0)
            self.Label:SetPoint("RIGHT", self, "RIGHT", -8, 0)
            self.Label:SetHeight(18)
            self.Label:SetJustifyH("CENTER")
            self.Label:SetJustifyV("MIDDLE")
            self.Label:SetWordWrap(false)
        end
    end)

    return button
end

function DiceSim:FitPanelButtonLabel(button)
    local label = button and button.Label or button and button.GetFontString and button:GetFontString()
    if not label then
        return
    end

    label:ClearAllPoints()
    label:SetPoint("LEFT", button, "LEFT", 8, 0)
    label:SetPoint("RIGHT", button, "RIGHT", -8, 0)
    label:SetHeight(18)
    label:SetJustifyH("CENTER")
    label:SetJustifyV("MIDDLE")
    label:SetWordWrap(false)
end

function DiceSim:CreatePanel(parent, name, width, height)
    local theme = self.Theme
    local panel = CreateFrame("Frame", name, parent, "BackdropTemplate")
    panel:SetSize(width, height)
    panel:SetFrameLevel(parent:GetFrameLevel() + 12)
    panel:SetFrameStrata("DIALOG")
    panel:Hide()
    panel:SetClipsChildren(true)
    panel:SetBackdrop({
        bgFile = theme.textures.solid,
        edgeFile = theme.textures.panelBorder,
        tile = true,
        tileSize = 32,
        edgeSize = 24,
        insets = { left = 7, right = 7, top = 7, bottom = 7 },
    })
    panel:SetBackdropColor(theme.colors.panelBg[1], theme.colors.panelBg[2], theme.colors.panelBg[3], 0.76)
    panel:SetBackdropBorderColor(unpack(theme.colors.panelBorder))
    panel:HookScript("OnShow", function(self)
        if DiceSim.ApplyFontScaleToFrame then
            DiceSim:ApplyFontScaleToFrame(self)
        end
    end)

    local backgroundArt = panel:CreateTexture(nil, "BORDER")
    backgroundArt:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -8)
    backgroundArt:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -8, 8)
    backgroundArt:SetAlpha(0.46)
    backgroundArt:SetHorizTile(false)
    backgroundArt:SetVertTile(false)
    self:ApplyTextureOrAtlas(backgroundArt, theme.textures.genericPanelBg)
    panel.BackgroundArt = backgroundArt

    self:MakeWindowInteractive(panel, {
        minWidth = width,
        minHeight = height,
        maxWidth = 900,
        maxHeight = 800,
    })
    self:CreateContainerInfoButton(panel)
    panel.InfoButton:SetScript("OnClick", function()
        DiceSim:OpenTutorial(panel.TutorialKey or "general")
    end)
    return panel
end

function DiceSim:CreateLabel(parent, text)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetText(text)
    self:SetFontColor(label, self.Theme.colors.text)
    return label
end

function DiceSim:CreateBox(parent, height)
    local theme = self.Theme
    local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    box:SetHeight(height)
    self:ApplyBackdrop(box, theme.colors.insetBg, theme.colors.insetBorder, 1)
    return box
end

function DiceSim:CreateField(parent, text)
    local theme = self.Theme
    local field = CreateFrame("Button", nil, parent, "BackdropTemplate")
    field:SetHeight(theme.sizes.fieldHeight)
    field:SetBackdrop(nil)

    local background = field:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(field)
    field.BackgroundTexture = background
    self:SetFieldTexture(field, "normal")

    local label = field:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", field, "LEFT", 10, 0)
    label:SetPoint("RIGHT", field, "RIGHT", -10, 0)
    label:SetJustifyH("LEFT")
    label:SetJustifyV("MIDDLE")
    label:SetWordWrap(false)
    label:SetText(text or "")
    self:SetFontColor(label, theme.colors.text)
    field.Label = label

    return field
end

function DiceSim:CreateDropdownField(parent, text, options, onSelect)
    local field = self:CreateField(parent, text)
    local theme = self.Theme
    field.Value = text
    field.Options = options or {}
    field.OnSelect = onSelect
    field.IsDropdownField = true
    field:SetBackdrop({
        bgFile = theme.textures.solid,
        edgeFile = theme.textures.tooltipBorder,
        tile = true,
        tileSize = 16,
        edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    field:SetBackdropColor(unpack(theme.colors.controlBg))
    field:SetBackdropBorderColor(unpack(theme.colors.controlBorder))

    field.Label:ClearAllPoints()
    field.Label:SetPoint("LEFT", field, "LEFT", 10, 0)
    field.Label:SetPoint("RIGHT", field, "RIGHT", -26, 0)

    local arrow = field:CreateTexture(nil, "OVERLAY")
    arrow:SetPoint("RIGHT", field, "RIGHT", -8, 0)
    arrow:SetSize(14, 14)
    arrow:SetTexture(theme.textures.dropdownArrow)
    field.Arrow = arrow

    self:SetFieldTexture(field, "normal")
    field:EnableMouse(true)
    field:SetScript("OnEnter", function(self)
        DiceSim:SetFieldTexture(self, self.IsDropdownOpen and "open" or "hover")
    end)
    field:SetScript("OnLeave", function(self)
        DiceSim:SetFieldTexture(self, self.IsDropdownOpen and "open" or "normal")
    end)
    field:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" then
            return
        end

        DiceSim:SetFieldTexture(self, "pressed")

        if self.RefreshOptions then
            self.Options = self.RefreshOptions()
        end

        DiceSim:ToggleDropdownMenu(self)
    end)
    field:SetScript("OnMouseUp", function(self)
        DiceSim:SetFieldTexture(self, self.IsDropdownOpen and "open" or "hover")
    end)

    return field
end

local function CreateDropdownMenuRow(parent)
    local theme = DiceSim.Theme
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetHeight(theme.sizes.menuRowHeight)
    button.IsDropdownMenuRow = true
    button:SetBackdrop({
        bgFile = theme.textures.solid,
        edgeFile = theme.textures.solid,
        edgeSize = 1,
    })

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(button)
    button.BackgroundTexture = background

    DiceSim:SetFieldTexture(button, "normal")

    local label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", button, "LEFT", 10, 0)
    label:SetPoint("RIGHT", button, "RIGHT", -22, 0)
    label:SetJustifyH("LEFT")
    label:SetJustifyV("MIDDLE")
    if label.SetWordWrap then
        label:SetWordWrap(false)
    end
    label:SetTextColor(unpack(theme.colors.text))
    if DiceSim.ApplyFontStringScale then
        DiceSim:ApplyFontStringScale(label)
    end
    button.Label = label

    local arrow = button:CreateTexture(nil, "OVERLAY")
    arrow:SetPoint("RIGHT", button, "RIGHT", -7, 0)
    arrow:SetSize(10, 10)
    arrow:SetTexture(theme.textures.dropdownArrow)
    arrow:SetRotation(-1.5708)
    arrow:Hide()
    button.Arrow = arrow

    return button
end

local function HideDropdownBranch(menu)
    if not menu then
        return
    end

    if menu.Submenu then
        HideDropdownBranch(menu.Submenu)
    end

    menu:Hide()
end

function DiceSim:ToggleDropdownMenu(field)
    if self.ActiveDropdown and self.ActiveDropdown:IsShown() then
        if self.ActiveDropdown.Owner then
            self.ActiveDropdown.Owner.IsDropdownOpen = false
            self:SetFieldTexture(self.ActiveDropdown.Owner, "normal")
        end

        self.ActiveDropdown:Hide()
        HideDropdownBranch(self.ActiveDropdown.Submenu)

        if self.ActiveDropdown.Owner == field then
            return
        end
    end

    local menu = self.DropdownMenu

    if not menu then
        local theme = self.Theme
        menu = CreateFrame("Frame", "DiceSimDropdownMenu", UIParent, "BackdropTemplate")
        menu:SetFrameStrata("FULLSCREEN_DIALOG")
        menu:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        menu:SetBackdropColor(unpack(theme.colors.panelBg))
        menu:SetBackdropBorderColor(unpack(theme.colors.panelBorder))
        menu.Buttons = {}

        menu:SetScript("OnHide", function(self)
            if self.Owner then
                self.Owner.IsDropdownOpen = false
                DiceSim:SetFieldTexture(self.Owner, "normal")
            end

            HideDropdownBranch(self.Submenu)
        end)

        self.DropdownMenu = menu
    end

    HideDropdownBranch(menu.Submenu)

    for _, button in ipairs(menu.Buttons) do
        button:Hide()
    end

    local options = field.Options or {}
    local width = math.max(field:GetWidth(), 170)

    local rowHeight = self.Theme.sizes.menuRowHeight
    menu:SetSize(width, math.max(1, #options) * rowHeight + 8)
    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", field, "BOTTOMLEFT", 0, -4)
    menu:SetFrameLevel(9000)
    menu.Owner = field

    for index, option in ipairs(options) do
        local label = type(option) == "table" and option.label or option
        local value = option

        if type(option) == "table" then
            value = option.value
            if value == nil then
                value = option.label
            end
        end

        local children = type(option) == "table" and option.children or nil
        local button = menu.Buttons[index]

        if not button then
            button = CreateDropdownMenuRow(menu)
            menu.Buttons[index] = button
        end

        button.IsDropdownLeafItem = not children
        DiceSim:SetFieldTexture(button, "normal")
        button.Label:SetText(label or "")
        if button.Arrow then
            button.Arrow:SetShown(children and true or false)
        end
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", menu, "TOPLEFT", 4, -4 - ((index - 1) * rowHeight))
        button:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -4, -4 - ((index - 1) * rowHeight))

        button:SetScript("OnEnter", function(self)
            DiceSim:SetFieldTexture(self, "hover")

            if children then
                DiceSim:ShowDropdownSubmenu(menu, field, self, children)
            else
                HideDropdownBranch(menu.Submenu)
            end
        end)

        button:SetScript("OnLeave", function(self)
            DiceSim:SetFieldTexture(self, "normal")
        end)

        button:SetScript("OnClick", function()
            if children then
                DiceSim:ShowDropdownSubmenu(menu, field, button, children)
                return
            end

            field.Value = value
            field.Label:SetText(label or "")
            field.SelectedOption = option
            field.IsDropdownOpen = false
            DiceSim:SetFieldTexture(field, "normal")
            HideDropdownBranch(menu)

            if field.OnSelect then
                field.OnSelect(value, option)
            end
        end)

        button:Show()
    end

    menu:Show()
    field.IsDropdownOpen = true
    DiceSim:SetFieldTexture(field, "open")
    self.ActiveDropdown = menu
end

function DiceSim:ShowDropdownSubmenu(menu, field, ownerButton, options)
    if not menu.Submenu then
        local theme = self.Theme
        local submenu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        submenu:SetFrameStrata("FULLSCREEN_DIALOG")
        submenu:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        submenu:SetBackdropColor(unpack(theme.colors.panelBg))
        submenu:SetBackdropBorderColor(unpack(theme.colors.panelBorder))
        submenu.Buttons = {}
        menu.Submenu = submenu
    end

    local submenu = menu.Submenu

    HideDropdownBranch(submenu.Submenu)

    for _, button in ipairs(submenu.Buttons) do
        button:Hide()
    end

    local width = 180
    local rowHeight = self.Theme.sizes.menuRowHeight
    submenu:SetSize(width, math.max(1, #options) * rowHeight + 8)
    submenu:ClearAllPoints()
    submenu:SetPoint("TOPLEFT", ownerButton, "TOPRIGHT", 4, 0)
    submenu:SetFrameLevel((menu:GetFrameLevel() or 9000) + 10)

    for index, option in ipairs(options) do
        local label = type(option) == "table" and (option.label or option.value) or option
        local value = type(option) == "table" and option.value or option

        if value == nil then
            value = label
        end

        local children = type(option) == "table" and option.children or nil
        local button = submenu.Buttons[index]

        if not button then
            button = CreateDropdownMenuRow(submenu)
            submenu.Buttons[index] = button
        end

        button.IsDropdownLeafItem = not children
        DiceSim:SetFieldTexture(button, "normal")
        button.Label:SetText(label or "")
        if button.Arrow then
            button.Arrow:SetShown(children and true or false)
        end
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", submenu, "TOPLEFT", 4, -4 - ((index - 1) * rowHeight))
        button:SetPoint("TOPRIGHT", submenu, "TOPRIGHT", -4, -4 - ((index - 1) * rowHeight))

        button:SetScript("OnEnter", function(self)
            DiceSim:SetFieldTexture(self, "hover")

            if children then
                DiceSim:ShowDropdownSubmenu(submenu, field, self, children)
            else
                HideDropdownBranch(submenu.Submenu)
            end
        end)

        button:SetScript("OnLeave", function(self)
            DiceSim:SetFieldTexture(self, "normal")
        end)

        button:SetScript("OnClick", function()
            if children then
                DiceSim:ShowDropdownSubmenu(submenu, field, button, children)
                return
            end

            field.Value = value
            field.Label:SetText(label or "")
            field.SelectedOption = option
            field.IsDropdownOpen = false
            DiceSim:SetFieldTexture(field, "normal")
            HideDropdownBranch(DiceSim.DropdownMenu)

            if field.OnSelect then
                field.OnSelect(value, option)
            end
        end)

        button:Show()
    end

    submenu:Show()
end

function DiceSim:CreateInputBox(parent, width, height)
    local theme = self.Theme
    local input = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    input:SetSize(width, height)
    input:SetAutoFocus(false)
    input:SetNumeric(true)
    input:SetMaxLetters(3)
    input:SetJustifyH("CENTER")
    input:SetFontObject(GameFontHighlight)
    self:ApplyBackdrop(input, theme.colors.insetBg, theme.colors.insetBorder, 1)
    input:SetTextColor(unpack(theme.colors.text))
    input:SetText("0")
    input:SetScript("OnEscapePressed", input.ClearFocus)
    input:HookScript("OnEditFocusGained", function(self)
        self:SetBackdropBorderColor(unpack(theme.colors.controlBorderHover))
    end)
    input:HookScript("OnEditFocusLost", function(self)
        self:SetBackdropBorderColor(unpack(theme.colors.insetBorder))
    end)
    return input
end

function DiceSim:SetInputPlaceholder(input, text)
    if not input then
        return
    end

    local placeholder = input:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    placeholder:SetPoint("LEFT", input, "LEFT", 8, 0)
    placeholder:SetPoint("RIGHT", input, "RIGHT", -8, 0)
    placeholder:SetJustifyH("LEFT")
    placeholder:SetText(text or "")
    self:SetFontColor(placeholder, self.Theme.colors.textMuted)
    input.Placeholder = placeholder

    input:HookScript("OnTextChanged", function(self)
        if self.Placeholder then
            self.Placeholder:SetShown((self:GetText() or "") == "")
        end
    end)
    placeholder:SetShown((input:GetText() or "") == "")
end

function DiceSim:CreateTextInputBox(parent, width, height, maxLetters, multiLine)
    local theme = self.Theme
    local input = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    input:SetSize(width, height)
    input:SetAutoFocus(false)
    input:SetMultiLine(multiLine and true or false)
    input:SetMaxLetters(maxLetters or 64)
    input:SetFontObject(multiLine and GameFontHighlightSmall or GameFontHighlight)
    input:SetTextColor(unpack(theme.colors.text))
    input:SetText("")
    if multiLine then
        self:ApplyBackdrop(input, theme.colors.insetBg, theme.colors.insetBorder, 1)
    else
        self:ApplyBackdrop(input, theme.colors.insetBg, theme.colors.insetBorder, 1)
    end
    input:HookScript("OnEditFocusGained", function(self)
        self:SetBackdropBorderColor(unpack(theme.colors.controlBorderHover))
    end)
    input:HookScript("OnEditFocusLost", function(self)
        self:SetBackdropBorderColor(unpack(theme.colors.insetBorder))
    end)
    return input
end

function DiceSim:CreateDivider(parent)
    local divider = CreateFrame("Frame", nil, parent)
    divider:SetSize(180, 10)

    local texture = divider:CreateTexture(nil, "ARTWORK")
    texture:SetPoint("CENTER")
    texture:SetSize(290, 10)
    self:ApplyTextureOrAtlas(texture, self.Theme.textures.divider)
    texture:SetVertexColor(unpack(self.Theme.colors.accent))
    texture:SetAlpha(0.88)
    divider.Texture = texture

    return divider
end

function DiceSim:CreateScrollBox(parent)
    local border = self:CreateBox(parent, 120)

    local scrollFrame = CreateFrame("ScrollFrame", nil, border, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", border, "TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", -28, 8)
    self:ApplyScrollBarSkin(scrollFrame)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(1, 1)
    scrollFrame:SetScrollChild(content)

    border.ScrollFrame = scrollFrame
    border.Content = content
    return border
end

function DiceSim:ApplyScrollBarSkin(scrollFrame)
    local scrollBar = scrollFrame and (scrollFrame.ScrollBar or scrollFrame.Scrollbar)

    if not scrollBar then
        return
    end

    local theme = self.Theme
    local thumb = scrollBar.GetThumbTexture and scrollBar:GetThumbTexture()

    if scrollBar.SetWidth then
        scrollBar:SetWidth(theme.sizes.scrollbarWidth)
    end

    if thumb then
        if not self:ApplyTextureOrAtlas(thumb, theme.textures.scrollbarThumb, true) then
            self:ApplyTextureOrAtlas(thumb, theme.textures.scrollbarThumbFallback, true)
        end
        thumb:SetSize(theme.sizes.scrollbarThumbWidth, theme.sizes.scrollbarThumbHeight)
        thumb:SetVertexColor(1, 1, 1, 1)
        thumb:SetAlpha(0.95)
    end

    local upButton = scrollBar.ScrollUpButton or scrollBar.UpButton or scrollFrame.ScrollBarScrollUpButton
    local downButton = scrollBar.ScrollDownButton or scrollBar.DownButton or scrollFrame.ScrollBarScrollDownButton

    local function SkinArrowButton(button, atlas, fallbackAtlas)
        if not button then
            return
        end

        if button.SetSize then
            button:SetSize(theme.sizes.scrollbarArrow, theme.sizes.scrollbarArrow)
        end

        local normal = button.GetNormalTexture and button:GetNormalTexture()
        local pushed = button.GetPushedTexture and button:GetPushedTexture()
        local highlight = button.GetHighlightTexture and button:GetHighlightTexture()
        local disabled = button.GetDisabledTexture and button:GetDisabledTexture()

        if normal then
            if not DiceSim:ApplyTextureOrAtlas(normal, atlas, true) then
                DiceSim:ApplyTextureOrAtlas(normal, fallbackAtlas, true)
            end
            normal:SetVertexColor(1, 1, 1, 1)
        end

        if pushed then
            if not DiceSim:ApplyTextureOrAtlas(pushed, atlas, true) then
                DiceSim:ApplyTextureOrAtlas(pushed, fallbackAtlas, true)
            end
            pushed:SetVertexColor(1, 1, 1, 1)
        end

        if highlight then
            if not DiceSim:ApplyTextureOrAtlas(highlight, atlas, true) then
                DiceSim:ApplyTextureOrAtlas(highlight, fallbackAtlas, true)
            end
            highlight:SetVertexColor(1, 1, 1, 1)
            highlight:SetAlpha(0.95)
        end

        if disabled then
            if not DiceSim:ApplyTextureOrAtlas(disabled, atlas, true) then
                DiceSim:ApplyTextureOrAtlas(disabled, fallbackAtlas, true)
            end
            disabled:SetVertexColor(0.45, 0.45, 0.45, 0.8)
        end
    end

    SkinArrowButton(upButton, theme.textures.scrollbarArrowTop, theme.textures.scrollbarArrowTopFallback)
    SkinArrowButton(downButton, theme.textures.scrollbarArrowBottom, theme.textures.scrollbarArrowBottomFallback)

    if scrollBar.Track then
        scrollBar.Track:SetAlpha(0.35)
    end

    if scrollBar.Background then
        scrollBar.Background:SetAlpha(0.25)
    end
end

function DiceSim:CreateProfileAdjustButton(parent, icon, tooltip)
    local button = self:CreateTrayButton(parent, nil, icon, tooltip)
    button:SetSize(self.Theme.sizes.smallIconButton, self.Theme.sizes.smallIconButton)
    SetTrayButtonIconSize(button, self.Theme.sizes.smallIcon)
    if button.HoverTexture then
        button.HoverTexture:SetSize(self.Theme.sizes.smallIconButton - 4, self.Theme.sizes.smallIconButton - 4)
    end
    button:Hide()
    return button
end

function DiceSim:CreateHorizontalIconStrip(parent)
    local theme = self.Theme
    local strip = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    strip:SetSize(164, 42)
    strip:SetClipsChildren(true)
    strip:SetBackdrop(nil)

    local scrollFrame = CreateFrame("ScrollFrame", nil, strip)
    scrollFrame:SetPoint("TOPLEFT", strip, "TOPLEFT", 0, -3)
    scrollFrame:SetPoint("BOTTOMRIGHT", strip, "BOTTOMRIGHT", 0, 12)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(260, 26)
    scrollFrame:SetScrollChild(content)

    local scrollBar = CreateFrame("Slider", nil, strip, "BackdropTemplate")
    scrollBar:SetOrientation("HORIZONTAL")
    scrollBar:SetPoint("BOTTOMLEFT", strip, "BOTTOMLEFT", 3, 1)
    scrollBar:SetPoint("BOTTOMRIGHT", strip, "BOTTOMRIGHT", -3, 1)
    scrollBar:SetHeight(10)
    scrollBar:SetThumbTexture(theme.textures.solid)
    if scrollBar:GetThumbTexture() then
        scrollBar:GetThumbTexture():SetSize(28, 8)
        scrollBar:GetThumbTexture():SetVertexColor(unpack(theme.colors.accent))
        scrollBar:GetThumbTexture():SetAlpha(0.95)
    end
    self:ApplyBackdrop(scrollBar, { 0.030, 0.022, 0.014, 0.62 }, theme.colors.insetBorder, 1)
    scrollBar:SetMinMaxValues(0, 96)
    scrollBar:SetValueStep(8)
    scrollBar:SetObeyStepOnDrag(true)
    scrollBar:SetValue(0)
    scrollBar:SetScript("OnValueChanged", function(_, value)
        scrollFrame:SetHorizontalScroll(value)
    end)

    strip.ScrollFrame = scrollFrame
    strip.ScrollBar = scrollBar
    strip.Content = content
    return strip
end

function CreateTrayButton(...)
    return DiceSim:CreateTrayButton(...)
end

function CreateEditButton(...)
    return DiceSim:CreateEditButton(...)
end

function CreateContainerInfoButton(...)
    return DiceSim:CreateContainerInfoButton(...)
end

function WireCloseButton(...)
    return DiceSim:WireCloseButton(...)
end

function CreateTray(...)
    return DiceSim:CreateTray(...)
end

function CreatePanelButton(...)
    return DiceSim:CreatePanelButton(...)
end

function FitPanelButtonLabel(...)
    return DiceSim:FitPanelButtonLabel(...)
end

function CreatePanel(...)
    return DiceSim:CreatePanel(...)
end

function CreateLabel(...)
    return DiceSim:CreateLabel(...)
end

function CreateBox(...)
    return DiceSim:CreateBox(...)
end

function CreateField(...)
    return DiceSim:CreateField(...)
end

function CreateDropdownField(...)
    return DiceSim:CreateDropdownField(...)
end

function CreateInputBox(...)
    return DiceSim:CreateInputBox(...)
end

function SetInputPlaceholder(...)
    return DiceSim:SetInputPlaceholder(...)
end

function CreateTextInputBox(...)
    return DiceSim:CreateTextInputBox(...)
end

function CreateDivider(...)
    return DiceSim:CreateDivider(...)
end

function CreateScrollBox(...)
    return DiceSim:CreateScrollBox(...)
end

function ApplyScrollBarSkin(...)
    return DiceSim:ApplyScrollBarSkin(...)
end

function CreateProfileAdjustButton(...)
    return DiceSim:CreateProfileAdjustButton(...)
end

function CreateHorizontalIconStrip(...)
    return DiceSim:CreateHorizontalIconStrip(...)
end
