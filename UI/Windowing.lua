local DiceSim = _G.DiceSim

local RESIZE_GRIP_SIZE = 26
local BASE_PANEL_LEVEL = 40

function DiceSim:BringWindowToFront(frame)
    self.WindowZIndex = (self.WindowZIndex or BASE_PANEL_LEVEL) + 10
    frame:SetFrameLevel(self.WindowZIndex)

    if frame.ResizeGrip then
        frame.ResizeGrip:SetFrameLevel(self.WindowZIndex + 20)
    end

    if frame.SheetTab then
        frame.SheetTab:SetFrameLevel(self.WindowZIndex + 1)
    end
end

function DiceSim:MakeWindowInteractive(frame, options)
    options = options or {}

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton", "RightButton")
    frame:SetClampedToScreen(true)
    frame:SetScript("OnDragStart", function(self)
        DiceSim:BringWindowToFront(self)
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)
    frame:HookScript("OnMouseDown", function(self)
        DiceSim:BringWindowToFront(self)
    end)
    frame:HookScript("OnShow", function(self)
        DiceSim:BringWindowToFront(self)
    end)

    if options.resizable == false then
        return
    end

    frame:SetResizable(true)

    if frame.SetResizeBounds then
        frame:SetResizeBounds(options.minWidth or 220, options.minHeight or 160, options.maxWidth or 1200, options.maxHeight or 900)
    else
        frame:SetMinResize(options.minWidth or 220, options.minHeight or 160)
        frame:SetMaxResize(options.maxWidth or 1200, options.maxHeight or 900)
    end

    local grip = CreateFrame("Button", nil, frame)
    grip:SetSize(RESIZE_GRIP_SIZE, RESIZE_GRIP_SIZE)
    grip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)
    grip:SetFrameLevel(frame:GetFrameLevel() + 20)
    grip:EnableMouse(true)

    local texture = grip:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints()
    DiceSim:ApplyTextureOrAtlas(texture, DiceSim.Theme.textures.resizeGrip)
    texture:SetVertexColor(unpack(DiceSim.Theme.colors.accent))
    grip.Texture = texture

    grip:SetScript("OnMouseDown", function(self)
        DiceSim:BringWindowToFront(frame)
        DiceSim:ApplyTextureOrAtlas(self.Texture, DiceSim.Theme.textures.resizeGrip)
        self.Texture:SetVertexColor(unpack(DiceSim.Theme.colors.controlBorderHover))
        frame:StartSizing("BOTTOMRIGHT")
    end)

    grip:SetScript("OnMouseUp", function(self)
        DiceSim:ApplyTextureOrAtlas(self.Texture, DiceSim.Theme.textures.resizeGrip)
        self.Texture:SetVertexColor(unpack(DiceSim.Theme.colors.accent))
        frame:StopMovingOrSizing()

        if options.onResize then
            options.onResize(frame)
        end
    end)

    grip:SetScript("OnEnter", function(self)
        DiceSim:ApplyTextureOrAtlas(self.Texture, DiceSim.Theme.textures.resizeGrip)
        self.Texture:SetVertexColor(unpack(DiceSim.Theme.colors.controlBorderHover))
    end)

    grip:SetScript("OnLeave", function(self)
        DiceSim:ApplyTextureOrAtlas(self.Texture, DiceSim.Theme.textures.resizeGrip)
        self.Texture:SetVertexColor(unpack(DiceSim.Theme.colors.accent))
    end)

    frame.ResizeGrip = grip
end
