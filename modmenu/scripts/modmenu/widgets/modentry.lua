local Widget = require "widgets.widget"

local ModEntryToggleRow = require "modmenu.widgets.modentry_togglerow"
local ModEntryImageButton = require "modmenu.widgets.modentry_imagebutton"
local ModEntryImageButtonToggle = require "modmenu.widgets.modentry_imagebutton_toggle"
local ModConfiguratorScreen = require "modmenu.screens.modconfiguratorscreen"

-- always assume KnownModIndex is available at the time this widget is used
-- (so no basic nil checks needed)
-- some functions below are just wrappers to return exactly what KnownModIndex
-- or Profile returns, though i still prefer to keep them in case we need to
-- implement anything extra later

local function IsModEnabled(modname)
    -- make sure to always return a bool cuz KnownModIndex:IsModEnabledAny can
    -- return nil
    return KnownModIndex:IsModEnabledAny(modname) or false
end

local function IsModFavorited(modname)
    -- always return a bool, never nil
    return Profile:IsModFavorited(modname)
end

local function GetModFancyName(modname)
    -- returns modname if no fancy name is found,, never nil
    return KnownModIndex:GetModFancyName(modname)
end

local function GetModInfoValue(modname, key)
    local info = KnownModIndex:GetModInfo(modname)
    if not info or info[key] == nil then
        return nil
    end

    return info[key]
end

local function ModHasConfigurations(modname)
    -- KnownModIndex:HasModConfigurationOptions always return a bool even if
    -- mod does not exist, never nil
    return KnownModIndex:HasModConfigurationOptions(modname)
end

local SIDEBUTTONS_WIDTH = 200
local ModEntry = Class(Widget, function(self, modname, rowWidth)
    Widget._ctor(self, "ModEntry")
    self.rowWidth = rowWidth
    self.info = {
        modname = modname,
        enabled = IsModEnabled(modname),
        favorited = IsModFavorited(modname),
        modname_fancy = GetModFancyName(modname),
        description = GetModInfoValue(modname, "description") or "",
        author = GetModInfoValue(modname, "author") or "",
        version = GetModInfoValue(modname, "version") or "",
        bypass_modicon_mask = GetModInfoValue(modname, "modmenu_bypass_modicon_mask") or false,
        has_configs = ModHasConfigurations(modname),
    }

    self.root = self:AddChild(Widget("root"))

    -- main area: contains icon, title, and various descriptions about mod,
    -- can toggle on or off mod
    local pretty_desc = self:BuildPrettyDescription()
    self.main_btn = self.root:AddChild(ModEntryToggleRow(self.rowWidth - SIDEBUTTONS_WIDTH - 10, nil, self.info.bypass_modicon_mask))
        :SetName("main button")
        :SetText(self.info.modname_fancy)
        :SetValues({
            { desc = pretty_desc, data = true},
            { desc = pretty_desc, data = false},
        })
        :_SetValue(self.info.enabled and 1 or 2)
        :SetOnValueChangeFn(function(data)
            if data then
                KnownModIndex:Enable(modname)
            else
                KnownModIndex:Disable(modname)
            end
        end)
        
    local iconpath = GetModInfoValue(modname, "iconpath")
    if iconpath then
        -- SetTexture will freak out if provided with a nil tex path lol
        -- (empty strings are fien tho)
        self.main_btn:SetModIcon(iconpath)
    end
    
    self.sidebuttons_container = self.root:AddChild(Widget("side buttons"))
    local sidebutton_height = self.info.has_configs
        and(self.main_btn.height / 2 - 10) or self.main_btn.height
    self.favorite_btn = self.sidebuttons_container:AddChild(ModEntryImageButtonToggle(
        "images/icons_ftf/stat_health.tex", SIDEBUTTONS_WIDTH, sidebutton_height))
        :SetName("favorite button")
        :SetImageOffset(4, 4)
        :SetValues({
            { data = true },
            { data = false },
        })
        :_SetValue(self.info.favorited and 1 or 2)
        :OnFocusChange(false) -- manually update the button's image color after setting its values manually
        :SetOnValueChangeFn(function(data)
            Profile:SetModFavorited(modname, data)
            Profile.dirty = true
            Profile:Save()
            if self.onfavoriteupdated_fn then
                self.onfavoriteupdated_fn()
            end
        end)
    
    if self.info.has_configs then
        self.config_btn = self.sidebuttons_container:AddChild(ModEntryImageButton(
            "images/ui_ftf_dialog/ic_options.tex", SIDEBUTTONS_WIDTH, sidebutton_height))
            :SetName("config button")
            :SetImageOffset(4, 4)
            :SetOnClickFn(function()
                TheFrontEnd:PushScreen(ModConfiguratorScreen(self.info.modname))
            end)
    end

    self.sidebuttons_container:LayoutChildrenInColumn(10)
    self.root:LayoutChildrenInRow(10)
end)

function ModEntry:BuildPrettyDescription()
    return self.info.description..
        "\n<i>Author: "..self.info.author..
        "\nVersion: "..self.info.version..
        "\nDirectory: "..self.info.modname.."</i>"
end

function ModEntry:SetOnFavoriteUpdatedFn(fn)
    self.onfavoriteupdated_fn = fn
    
    return self
end

return ModEntry
