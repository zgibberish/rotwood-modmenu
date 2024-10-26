local OptionsScreenBaseRow = require "screens.options.optionsscreenbaserow"

local DEFAULT_HIGHLIGHT_COLOR = { r = 247, g = 182, b = 87 }

local OptionScreenModMenuReloadButton = Class(OptionsScreenBaseRow, function(self, width, rightColumnWidth, highlightColor)
    OptionsScreenBaseRow._ctor(self, width, rightColumnWidth)
    self:SetName("OptionScreenModMenuReloadButton")
    self.highlightColor = highlightColor or DEFAULT_HIGHLIGHT_COLOR

    self:SetText(
        "Confirm options and Reload",
        "Click here to save mod config changes and reload the game.\n<i>ANY UNSAVED IN-GAME PROGRESS WILL BE LOST!</i>"
    )
    self:SetOnClickFn(function()
        KnownModIndex:Save()
        c_reset()
    end)

    self.bgSelectedColor = RGB(self.highlightColor.r, self.highlightColor.g, self.highlightColor.b)
    self.bgUnselectedColor = RGB(self.highlightColor.r, self.highlightColor.g, self.highlightColor.b, 0)
end)

return OptionScreenModMenuReloadButton
