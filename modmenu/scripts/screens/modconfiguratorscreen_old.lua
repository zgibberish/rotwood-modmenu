local ConfirmDialog = require "screens.dialogs.confirmdialog"
local Image = require "widgets.image"
local Panel = require "widgets.panel"
local Screen = require "widgets.screen"
local ScrollPanel = require "widgets.scrollpanel"
local TabGroup = require "widgets.tabgroup"
local Text = require "widgets.text"
local Widget = require "widgets.widget"
local easing = require "util.easing"
local fmodtable = require "defs.sound.fmodtable"
local lume = require "util.lume"
local templates = require "widgets.ftf.templates"
local ImageButton = require "widgets.imagebutton"

local OptionsScreenCategoryTitle = require "widgets/optionsscreencategorytitle"
local OptionsScreenBaseRow = require "widgets/optionsscreenbaserow"
local OptionsScreenSpinnerRow = require "widgets/optionsscreenspinnerrow"
local ModEntryImageButton = require "widgets/modentry_imagebutton"

local MOD_ENTRY_BUTTON_WIDTH = 200

------------------------------------------------------------------------------------------
--- Modified optionsscreen designed to only show 1 page (the config page of the selected mod)
--- most functionalities have been removed
----
local ModConfiguratorScreen = Class(Screen, function(self, modname)
	Screen._ctor(self, "ModConfiguratorScreen")

	self.modname = modname

	local mod_is_client = false
    if KnownModIndex.savedata.known_mods[modname] and KnownModIndex.savedata.known_mods[modname] and KnownModIndex.savedata.known_mods[modname].modinfo and KnownModIndex.savedata.known_mods[modname].modinfo.client_only_mod and KnownModIndex.savedata.known_mods[modname].modinfo.client_only_mod == true then
        mod_is_client = true
    end
    self.configuration_options = KnownModIndex:LoadModConfigurationOptions(modname, mod_is_client)
	self.configuration_options_backup = deepcopy(self.configuration_options)

	--sound
	self:SetAudioCategory(Screen.AudioCategory.s.Fullscreen)
	self:SetAudioExitOverride(nil)

	-- Setup sizings
	self.rowWidth = 2520
	self.rowRightColumnWidth = 880
	self.rowSpacing = 120

	-- Add background
	self.bg = self:AddChild(templates.BackgroundImage("images/ui_ftf_options/optionsscreen_bg.tex"))

	-- And panel background
	self.panel_bg = self:AddChild(Panel("images/bg_bottom_panel/bottom_panel.tex"))
		:SetName("Panel background")
		:SetNineSliceCoords(200, 350, 300, 1950)
		:SetSize(2400, 2100)

	-- Add nav header
	self.navbarWidth = RES_X - 160
	self.navbarHeight = 180
	local icon_size = FONTSIZE.OPTIONS_SCREEN_TAB * 1.1

	self.nav_tabs = self:AddChild(TabGroup())
		:SetTheme_DarkOnLight(nil, UICOLORS.BACKGROUND_LIGHT, nil, nil)
		:SetTabSpacing(100)
		:SetFontSize(FONTSIZE.OPTIONS_SCREEN_TAB)

	-- Add navbar options
	self.tabs = {}
	local mod_fancyname = KnownModIndex:GetModFancyName(modname)
	self.tabs.main = self.nav_tabs:AddIconTextTab("images/ui_ftf_dialog/ic_options.tex", mod_fancyname)
	self.tabs.main:SetGainFocusSound(fmodtable.Event.hover)

	local tab_count = lume.count(self.tabs)

	-- Add back button
	self.backButton = self:AddChild(ImageButton("images/ui_ftf/HeaderClose.tex"))
		:SetName("Back button")
		:SetSize(BUTTON_SQUARE_SIZE, BUTTON_SQUARE_SIZE)
		:SetFocusScale(1.2)
		:SetNormalScale(1.1)
		:SetScale(1.1)
		:SetNavFocusable(false)
		:SetOnClick(function() self:OnClickClose() end)

	-- Add save button
	self.saveButtonBg = self:AddChild(Image("images/ui_ftf/small_panel.tex"))
		:SetName("Panel")
		:SetSize(500, 190)
		:SetMultColor(UICOLORS.LIGHT_BACKGROUNDS_DARK)
	self.saveButton = self:AddChild(templates.AcceptButton(STRINGS.UI.OPTIONSSCREEN.SAVE_BUTTON))
		:SetNormalScale(0.8)
		:SetFocusScale(0.85)
		:SetScale(0.8)
		:SetPrimary()
		:SetOnClick(function() self:OnClickSave() end)
		:Hide()
		:SetControlUpSound(fmodtable.Event.ui_input_up_confirm_save)

	-- Add a confirmation label to be displayed when the options are saved
	self.saveConfirmationLabel = self:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.OPTIONS_SCREEN_TAB))
		:SetGlyphColor(UICOLORS.LIGHT_TEXT)
		:SetAutoSize(600)
		:SetText(STRINGS.UI.OPTIONSSCREEN.SAVED_OPTIONS_LABEL)
		:SetMultColorAlpha(0)

	-- Add scrolling panel below the navbar
	self.scroll = self:AddChild(ScrollPanel())
		:SetSize(RES_X - 400, RES_Y)
		:SetVirtualMargin(140)
		:SetVirtualBottomMargin(1000)
		:SetBarInset(200)
		:LayoutBounds("center", "bottom", self.bg)
		:SetFocusableChildrenFn(function()
			return self.currentPage:GetChildren()
		end)
	self.scrollContents = self.scroll:AddScrollChild(Widget())
	self.scrollBar = self.scroll:GetScrollBar()

	-- Add tab-specific views
	self.pages = {}
	self.pages.main = self.scrollContents:AddChild(Widget("Page Main (mod configs)"))
	-- Fill up all the pages with content!
	self:_BuildMainPage()
	self.tabs.main.page = self.pages.main

	self.scroll:RefreshView()

	dbassert(not self:IsDirty(), "Shouldn't be dirty before making changes. Are we clamping? (Should migrate save data in gamesettings.)")

	-- Add a gradient fading out the options at the bottom of the screen
	self.bottomGradientFade = self:AddChild(Image("images/ui_ftf_options/bottom_gradient.tex"))
		:SetSize(RES_X, 600)
		:LayoutBounds("center", "bottom", self.bg)
	-- Move the gradient into the scroll panel, so I can place the scroll bar on top
	self.bottomGradientFade:Reparent(self.scroll)
	self.scroll.scroll_bar:SendToFront()

	-- Position navbar in front of the scroll panel
	self.navbar:SendToFront()

	self.default_focus = self.pages.main.default_focus or self.backButton
	self.default_focus:SetFocus()
end)

ModConfiguratorScreen.CONTROL_MAP =
{
	{
		control = Controls.Digital.MENU_SCREEN_ADVANCE,
		hint = function(self, left, right)
			table.insert(right, loc.format(LOC"UI.CONTROLS.ACCEPT", Controls.Digital.MENU_SCREEN_ADVANCE))
		end,
		fn = function(self)
			self:OnClickClose()
			TheFrontEnd:GetSound():PlaySound(fmodtable.Event.ui_simulate_click)
			return true
		end,
	},
	{
		control = Controls.Digital.CANCEL,
		hint = function(self, left, right)
			table.insert(right, loc.format(LOC"UI.CONTROLS.CANCEL", Controls.Digital.CANCEL))
		end,
		fn = function(self)
			self:OnClickClose()
			TheFrontEnd:GetSound():PlaySound(fmodtable.Event.ui_simulate_click)
			return true
		end,
	},
}

function ModConfiguratorScreen:OnOpen()
	ModConfiguratorScreen._base.OnOpen(self)

	self:EnableFocusBracketsForGamepad()
	self.nav_tabs:SelectTab(1)
end

function ModConfiguratorScreen:Layout()
	self.bg:SetSize(RES_X, RES_Y)
	self.panel_bg:SetSize(RES_X-600, RES_Y-150)
		:LayoutBounds("center", "bottom", self.bg)
	local _, panel_h = self.panel_bg:GetSize()

	-- Position tabs
	self.nav_tabs
		:Layout() -- For the cycle icons
		:LayoutBounds("center", "top", self.panel_bg)
		:Offset(0, -90)

	-- Update scroll panel
	self.scroll:SetSize(RES_X - 400, panel_h - 238)
		:RefreshView()
		:LayoutBounds("center", "bottom", self.panel_bg)

	-- Position scroll bar
	self.scrollBar:SetRotation(0)
		:LayoutBounds("right", "center", self.panel_bg)
		:Offset(-190, -140)
		:SetRotation(-0.6)

	-- And buttons
	self.backButton:LayoutBounds("right", "top", self.panel_bg)
		:Offset(-80, 20)

	-- Save button
	self.saveButtonBg:SetScale(1, 1)
		:LayoutBounds("center", "bottom", self.bg)
		:Offset(0, -10)
		:SetScale(1, -1)
		:SendToFront()
	self.saveButton:LayoutBounds("center", "bottom", self.bg)
		:Offset(0, 40)
		:SendToFront()

	-- Display focus brackets on top of the save button
	self:SendFocusBracketsToFront()

	-- Confirmation-label
	self.saveConfirmationLabel:LayoutBounds("center", "above", self.panel_bg)
		:Offset(0, 20)
	self.labelX, self.labelY = self.saveConfirmationLabel:GetPosition()

	return self
end

function ModConfiguratorScreen:_BuildMainPage()
	local function ModConfigSpinnerRow(setting, setting_index)
		local function _indexOf_options(array, value)
			for i,v in ipairs(array) do
				if v.data == value then
					return i
				end
			end
			return nil
		end
		
		local setting_selected = setting.saved or setting.default
		local spinner_selected_index  = _indexOf_options(setting.options, setting_selected) or 1

		local spinner_values = {}
		for _,option in ipairs(setting.options) do
			table.insert(spinner_values, {
				name = option.description,
				data = option.data
			})
		end

		local opt = Widget("Mod Config Row Container")
		opt.main = opt:AddChild(OptionsScreenSpinnerRow(self.rowWidth - MOD_ENTRY_BUTTON_WIDTH - 10, self.rowRightColumnWidth))
            :SetText(setting.label, setting.hover)
            :SetValues(spinner_values)
            :_SetValue(spinner_selected_index)
            :SetOnValueChangeFn(function(data)
				self.configuration_options[setting_index].saved = data
				self:MakeDirty()
            end)
		opt.reset_btn = opt:AddChild(ModEntryImageButton("images/ui_ftf_icons/restart.tex", MOD_ENTRY_BUTTON_WIDTH, opt.main.height))
			:SetImageOffset(4, 4)
			:SetOnClickFn(function()
				self.configuration_options[setting_index].saved = nil
				opt.main:_SetValue(setting.default)
				self:MakeDirty()
			end)

		opt
			:LayoutChildrenInRow(10)
			:Offset(-MOD_ENTRY_BUTTON_WIDTH/2, 0) -- for some reason spinner rows with side buttons have to be offset like this to make them look aligned like normal rows

		return opt
	end

	local function _LayoutModConfigRows()
		self.pages.main.mod_config_rows_container:RemoveAllChildren()

		for setting_index,setting in ipairs(self.configuration_options) do
			if #setting.options > 1 then
				local spinner_row = ModConfigSpinnerRow(setting, setting_index)
				self.pages.main.mod_config_rows_container:AddChild(spinner_row)
			else
				self.pages.main.mod_config_rows_container:AddChild(OptionsScreenCategoryTitle(self.rowWidth, setting.label))
			end
		end

		self.pages.main.mod_config_rows_container:LayoutChildrenInColumn(self.rowSpacing * 0.5)
	end

	-- add "reset all to default values" row
	local reset_row = self.pages.main:AddChild(OptionsScreenBaseRow(self.rowWidth, 0))
            :SetText(
                "<p img='images/ui_ftf_icons/restart.tex' color=0 scale=1> Reset All",
                "Click here to reset all config optoins to their default values (your changes won't get saved until you press Save)."
            )
            :SetOnClickFn(function()
                for setting_index,setting in ipairs(self.configuration_options) do
					setting.saved = nil
				end
				_LayoutModConfigRows()
				self:MakeDirty()
            end)

	self.pages.main.mod_config_rows_container = self.pages.main:AddChild(Widget("Mod Config Rows Container"))
	_LayoutModConfigRows()

	self.pages.main:LayoutChildrenInColumn(self.rowSpacing * 0.5)

	self.pages.main.default_focus = reset_row

	return self
end

--- Called when an option was edited by the player
function ModConfiguratorScreen:MakeDirty()
	-- Check if something actually changed compared to the stored settings
	if self:IsDirty() then
		-- Show the save button
		self.saveButton:Show()
	else
		-- Hide the save button
		self.saveButton:Hide()
	end
end

function ModConfiguratorScreen:IsDirty()
	local matches_saved = deepcompare(self.configuration_options_backup, self.configuration_options)
	return not matches_saved
end

function ModConfiguratorScreen:_SaveChanges()
	-- placeholder: save mod configs and update self.configuration_options to match the saved data
	KnownModIndex:SaveConfigurationOptions(function() end, self.modname, self.configuration_options, self.mod_is_client)
	self.configuration_options_backup = deepcopy(self.configuration_options)
	self:MakeDirty() -- update dirty status
	return false
end

function ModConfiguratorScreen:OnClickClose()
	local ExitScreen = function(success)
		self:_AnimateOut() -- will pop our dialog
	end

	local function CreateConfirm(title, subtitle, text, confirm_yes, confirm_no)
		return ConfirmDialog(
			self:GetOwningPlayer(),
			self.backButton,
			true,
			title,
			subtitle,
			text
		)
			:SetYesButtonText(confirm_yes)
			:SetNoButtonText(confirm_no)
			:SetArrowUp()
			:SetArrowXOffset(20) -- extra right shift looks more centred
			:SetAnchorOffset(305, 0)
	end

	if self:IsDirty() then
		-- Show confirmation to save the changes or reject them
		local dialog = CreateConfirm(
			STRINGS.UI.OPTIONSSCREEN.CONFIRM_TITLE,
			STRINGS.UI.OPTIONSSCREEN.CONFIRM_SUBTITLE,
			STRINGS.UI.OPTIONSSCREEN.CONFIRM_TEXT,
			STRINGS.UI.OPTIONSSCREEN.CONFIRM_OK,
			STRINGS.UI.OPTIONSSCREEN.CONFIRM_NO)

		-- Set its callback
		dialog:SetOnDoneFn(function(confirm_save)
			if confirm_save then
				self:_SaveChanges()
			end
			self:_AnimateOut()
			TheFrontEnd:PopScreen(self)
		end)

		-- Show the popup
		TheFrontEnd:PushScreen(dialog)

		-- And animate it in!
		dialog:AnimateIn()
	else
		self:Close() --go back
	end
end

function ModConfiguratorScreen:OnClickSave()
	if self:IsDirty() then
		self:_SaveChanges()
		-- Animate confirmation label and button
		self.saveConfirmationLabel:RunUpdater(Updater.Series({

			-- Fade button out
			Updater.Ease(function(v) self.saveButton:SetMultColorAlpha(v) end, 1, 0, 0.2, easing.inOutQuad),
			Updater.Do(function()
				self.saveButton:Hide()
					:SetMultColorAlpha(1)
			end),

			-- Animate in label
			Updater.Parallel({
				Updater.Ease(function(v) self.saveConfirmationLabel:SetMultColorAlpha(v) end, 0, 1, 0.3, easing.inOutQuad),
				Updater.Ease(function(v) self.saveConfirmationLabel:SetPosition(self.labelX, v) end, self.labelY - 10, self.labelY, 0.8, easing.outQuad),
			}),

			Updater.Wait(0.8),

			-- Animate label out
			Updater.Parallel({
				Updater.Ease(function(v) self.saveConfirmationLabel:SetMultColorAlpha(v) end, 1, 0, 0.8, easing.inOutQuad),
				Updater.Ease(function(v) self.saveConfirmationLabel:SetPosition(self.labelX, v) end, self.labelY, self.labelY + 10, 0.8, easing.inQuad),
			}),

		}))
	end
end

function ModConfiguratorScreen:Close()
	self:_AnimateOut()
end

function ModConfiguratorScreen:OnBecomeActive()
	ModConfiguratorScreen._base.OnBecomeActive(self)
	-- Hide the topfade, it'll obscure the pause menu if paused during fade. Fade-out will re-enable it
	TheFrontEnd:HideTopFade()

	self:Layout()

	if not self.animatedIn then
		-- Select first tab
		self.tabs.main:Click()

		self:_AnimateIn()
		self.animatedIn = true
	end
end

function ModConfiguratorScreen:_AnimateIn()
	self:_AnimateInFromDirection(Vector2.unit_y)
end

function ModConfiguratorScreen:_AnimateOut()
	self:_AnimateOutToDirection(Vector2.unit_y)
end

return ModConfiguratorScreen