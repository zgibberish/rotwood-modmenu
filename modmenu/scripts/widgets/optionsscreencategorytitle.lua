local Widget = require "widgets.widget"
local Panel = require "widgets.panel"
local Text = require "widgets.text"
local Image = require "widgets.image"

------------------------------------------------------------------------------------------
--- Displays a title widget for the controls panel, for cate gory separation
----
local OptionsScreenCategoryTitle = Class(Widget, function(self, width, text)
	Widget._ctor(self, "OptionsScreenCategoryTitle")

	self.hitbox = self:AddChild(Image("images/global/square.tex"))
		:SetMultColorAlpha(0)

	self.background = self:AddChild(Panel("images/ui_ftf_options/titlerow_bg.tex"))
		:SetNineSliceCoords(30, 0, 370, 100)
		:SetMultColor(UICOLORS.LIGHT_TEXT)
	self.title = self:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.OPTIONS_ROW_TITLE, text, UICOLORS.BACKGROUND_LIGHT))

	-- Resize the background to the text
	local w, h = self.title:GetSize()
	self.hitbox:SetSize(width, h + 40)
	self.background:SetSize(w + 120, h + 40)
		:LayoutBounds("left", "center", self.hitbox)
		:Offset(20, 0)
	self.title:LayoutBounds("center", "center", self.background)
		:Offset(-4, 0)

end)

return OptionsScreenCategoryTitle