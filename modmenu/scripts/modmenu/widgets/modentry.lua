local Widget = require "widgets.widget"

local ModEntryToggleRow = require "modmenu.widgets.modentry_togglerow"
local ModEntryImageButton = require "modmenu.widgets.modentry_imagebutton"
local ModEntryImageButtonToggle = require "modmenu.widgets.modentry_imagebutton_toggle"
local ModConfiguratorScreen = require "modmenu.screens.modconfiguratorscreen"

local function GetModFancyName(modname)
    -- returns modname if no fancy name is found,, never nil
    return KnownModIndex:GetModFancyName(modname)
end

local function GetModDescription(modname)
    if KnownModIndex:GetModInfo(modname)
    and KnownModIndex:GetModInfo(modname).description then
        return KnownModIndex:GetModInfo(modname).description
    end
    return ''
end

local function GetModAuthor(modname)
    if KnownModIndex:GetModInfo(modname)
    and KnownModIndex:GetModInfo(modname).author then
        return KnownModIndex:GetModInfo(modname).author
    end
    return ''
end

local function GetModVersion(modname)
    if KnownModIndex:GetModInfo(modname)
    and KnownModIndex:GetModInfo(modname).version then
        return KnownModIndex:GetModInfo(modname).version
    end
    return ''
end

local function IsModEnabled(modname)
    if KnownModIndex
    and KnownModIndex.savedata
    and KnownModIndex.savedata.known_mods
    and KnownModIndex.savedata.known_mods[modname]
    and KnownModIndex.savedata.known_mods[modname].enabled then
        return true
    end
    return false
end

local function IsModFavorited(modname)
    return Profile:IsModFavorited(modname)
end

local function ModHasConfigurations(modname)
    return KnownModIndex:HasModConfigurationOptions(modname)
end

local function ModBypassesModiconMask(modname)
    if KnownModIndex:GetModInfo(modname)
    and KnownModIndex:GetModInfo(modname).modmenu_bypass_modicon_mask then
        return true
    end
    return false
end

local SIDEBUTTONS_WIDTH = 200
local ModEntry = Class(Widget, function(self, modname, rowWidth)
    Widget._ctor(self, "ModEntry")
    self.rowWidth = rowWidth
    self.info = {
        modname = modname,
        modname_fancy = GetModFancyName(modname),
        description = GetModDescription(modname),
        author = GetModAuthor(modname),
        version = GetModVersion(modname),
        enabled = IsModEnabled(modname),
        favorited = IsModFavorited(modname),
        has_configs = ModHasConfigurations(modname),
        bypass_modicon_mask = ModBypassesModiconMask(modname),
    }

    self.root = self:AddChild(Widget("root"))

    -- main area: contains icon, title, and various descriptions about mod,
    -- can toggle on or off mod
    local fancy_description = self:BuildFancyDescription()
    self.main_btn = self.root:AddChild(ModEntryToggleRow(self.rowWidth - SIDEBUTTONS_WIDTH - 10, nil, self.info.bypass_modicon_mask))
        :SetName("main button")
        :SetText(self.info.modname_fancy)
        :SetValues({
            { desc = fancy_description, data = true},
            { desc = fancy_description, data = false},
        })
        :_SetValue(self.info.enabled and 1 or 2)
        :SetOnValueChangeFn(function(data)
            if not KnownModIndex then return end

            if data then
                KnownModIndex:Enable(modname)
            else
                KnownModIndex:Disable(modname)
            end
        end)
        
    local info = KnownModIndex:GetModInfo(modname)
    if info ~= nil and info.iconpath ~= nil then
        self.main_btn:SetModIcon(info.iconpath)
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

function ModEntry:BuildFancyDescription()
    return self.info.description..
        "\n<i>Author: "..self.info.author..
        "\nVersion: "..self.info.version..
        "\nDirectory: "..self.info.modname.."</i>"
end

function ModEntry:SetOnFavoriteUpdatedFn(fn)
    self.onfavoriteupdated_fn = fn
end

return ModEntry
