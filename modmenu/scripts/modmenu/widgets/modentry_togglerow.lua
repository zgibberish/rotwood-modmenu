local Widget = require "widgets.widget"
local Image = require "widgets.image"
local OptionsScreenToggleRow = require "modmenu.widgets.optionsscreentogglerow"

local DEFAULT_LEFT_PADDING = 260
local ModEntryToggleRow = Class(OptionsScreenToggleRow, function(self, width, rightColumnWidth, bypassModiconMask)
    OptionsScreenToggleRow._ctor(self, width, rightColumnWidth)    

    self.modicon_container = self:AddChild(Widget("modicon container"))
    self.modicon_container.frame = self.modicon_container:AddChild(Image("images/modicon_frame.png"))
    self.modicon_container.mask = self.modicon_container:AddChild(Image("images/modicon_mask.png"))
        :SetScale(1.01)
        :SetMask()
    self.modicon_container.icon = self.modicon_container:AddChild(Image())
        :SetMasked(not bypassModiconMask)
end)

function ModEntryToggleRow:SetModIcon(tex)
    self.modicon_container.icon
        :SetTexture(tex)
        :SetSize(256, 256)
end

function ModEntryToggleRow:Layout()
    ModEntryToggleRow._base.Layout(self)

    self.modicon_container:LayoutBounds("left", "center", self.bg)
        :Offset(DEFAULT_LEFT_PADDING-224, 0)

    self.title:SetAutoSize(self.textWidth - DEFAULT_LEFT_PADDING + 224)
	self.subtitle:SetAutoSize(self.textWidth - DEFAULT_LEFT_PADDING + 224)
		:LayoutBounds("left", "below", self.title)
		:Offset(0, 2)
    self.textContainer:Offset(DEFAULT_LEFT_PADDING, 0)
end

return ModEntryToggleRow
