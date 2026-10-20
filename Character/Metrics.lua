local DiceSim = _G.DiceSim

local METRIC_TEXTURES = {
    hp = "Interface\\AddOns\\DiceSim\\Interface\\Common\\widgetstatusbar-fill-red.blp",
    energy = "Interface\\AddOns\\DiceSim\\Interface\\Common\\widgetstatusbar-fill-yellow.blp",
    armor = "Interface\\AddOns\\DiceSim\\Interface\\Common\\widgetstatusbar-fill-blue.blp",
}

local function Clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end

    if value > maximum then
        return maximum
    end

    return value
end

local function UpdateMetricBar(bar)
    if not bar then
        return
    end

    local maximum = math.max(0, tonumber(bar.MetricMax) or 100)
    local current = maximum > 0 and Clamp(tonumber(bar.MetricValue) or maximum, 0, maximum) or 0
    bar.MetricValue = current
    bar.MetricMax = maximum
    bar:SetMinMaxValues(0, math.max(1, maximum))
    bar:SetValue(current)

    if bar.Text then
        bar.Text:SetText(math.floor(current + 0.5) .. "/" .. math.floor(maximum + 0.5))
    end

    if bar.LinkedMetricBars then
        for _, linkedBar in ipairs(bar.LinkedMetricBars) do
            linkedBar.MetricValue = current
            linkedBar.MetricMax = maximum
            UpdateMetricBar(linkedBar)
        end
    end
end

local function GetMetricTexture(color)
    if color and color.r and color.g and color.b then
        if color.r > 0.7 and color.g > 0.5 then
            return METRIC_TEXTURES.energy
        end

        if color.r > color.g and color.r > color.b then
            return METRIC_TEXTURES.hp
        end

        if color.b > color.r and color.b > color.g then
            return METRIC_TEXTURES.armor
        end
    end

    return METRIC_TEXTURES.energy
end

function DiceSim:CreateMetricBar(parent, color)
    local theme = self.Theme
    local bar = CreateFrame("StatusBar", nil, parent, "BackdropTemplate")
    bar:SetHeight(16)
    local metricTexture = GetMetricTexture(color)
    bar:SetStatusBarTexture(metricTexture)
    bar:SetStatusBarColor(1, 1, 1, 1)
    bar:SetMinMaxValues(0, 100)
    bar:SetValue(100)
    self:ApplyBackdrop(bar, theme.colors.insetBg, theme.colors.insetBorder, 1)

    local text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("CENTER")
    text:SetText("100")
    self:SetFontColor(text, theme.colors.text)
    bar.Text = text
    bar.Color = color
    bar.MetricTexture = metricTexture
    bar.MetricValue = 100
    bar.MetricMax = 100
    bar.MetricStep = 1
    return bar
end

function DiceSim:SetMetricBar(bar, value, maximum)
    if not bar then
        return
    end

    bar.MetricMax = maximum or bar.MetricMax or 100
    bar.MetricValue = value
    UpdateMetricBar(bar)
end

function DiceSim:AdjustMetricBar(bar, delta)
    if not bar then
        return
    end

    local step = bar.MetricStep or 1
    self:SetMetricBar(bar, (bar.MetricValue or bar.MetricMax or 0) + (delta * step), bar.MetricMax or 0)

    if self.ScheduleSessionSnapshot then
        self:ScheduleSessionSnapshot()
    end
end

function DiceSim:LinkMetricBars(primary, secondary)
    if not primary or not secondary then
        return
    end

    primary.LinkedMetricBars = primary.LinkedMetricBars or {}
    table.insert(primary.LinkedMetricBars, secondary)
    secondary.MetricValue = primary.MetricValue
    secondary.MetricMax = primary.MetricMax
    secondary.MetricStep = primary.MetricStep
    UpdateMetricBar(secondary)
end
