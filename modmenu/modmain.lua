Assets = {
    Asset("IMAGE", "images/modicon_frame.png"),
    Asset("IMAGE", "images/modicon_mask.png"),
}

local KnownModIndex = GLOBAL.KnownModIndex

local Widget = require "widgets.widget"
local fmodtable = require "defs.sound.fmodtable"

local OptionScreenModMenuReloadButton = require "modmenu/widgets/optionsscreen_modmenu_reloadbutton"
local ModEntry = require "modmenu/widgets/modentry"
local OptionsScreenCategoryTitle = require "modmenu/widgets/optionsscreencategorytitle"
local OptionsScreenSpinnerRow = require "modmenu/widgets/optionsscreenspinnerrow"
local ModSortingComparators = require "modmenu/modsortingcomparators"

local DEFAULT_SORTING_METHOD = 1
local SELECTED_SORTING_METHOD = DEFAULT_SORTING_METHOD

local function PrepareModIcon(modname)
    local info = KnownModIndex:GetModInfo(modname)
    if info ~= nil and info.iconpath ~= nil then
        local modiconassets = {
            Asset("IMAGE", info.iconpath),
        }
        
        GLOBAL.RegisterPrefabs(Prefab("MODMENU_"..modname, nil, modiconassets, nil, true))
        GLOBAL.TheSim:LoadPrefabs({"MODMENU_"..modname})
    end
end

AddClassPostConstruct("screens/optionsscreen", function(self)
    if self.nav_tabs == nil or self.tabs == nil or self.scrollContents == nil then
        return
    end
    
    local function LayoutModEntries()
        self.pages.mods.mod_entries:RemoveAllChildren()

        --NOTE: there are basically no differences between client and server
        -- mods, its just a thing left behind from the DST modding system,
        -- we dont have server/client hosting in rotwood so it doesn't matter
        -- but you can still set that property in your mod and it will be
        -- categorized based on that because why not.

        --NOTE (favorites first sorting): if you select sort by favorited first,
        -- the list will be sorted alphabetically first, then favorites first on
        -- top of that

        -- mods are shown sorted by their fancy name (the name defined in modinfo), if there is no fancy name, the moddir name is used

        -- CLIENT MODS
        self.pages.mods.mod_entries:AddChild(OptionsScreenCategoryTitle(self.rowWidth, "Client Mods"))
        local list_client = KnownModIndex:GetClientModNames()
        if SELECTED_SORTING_METHOD == 7 then
            table.sort(list_client, ModSortingComparators[1])
            table.sort(list_client, ModSortingComparators[7])
        else
            table.sort(list_client, ModSortingComparators[SELECTED_SORTING_METHOD])
        end
        for _, modname in ipairs(list_client) do
            PrepareModIcon(modname)
            self.pages.mods.mod_entries:AddChild(ModEntry(modname, self.rowWidth))
                :SetOnFavoriteUpdatedFn(function()
                    if SELECTED_SORTING_METHOD == 7 then
                        LayoutModEntries()
                    end
                end)
        end

        -- SERVER MODS
        self.pages.mods.mod_entries:AddChild(OptionsScreenCategoryTitle(self.rowWidth, "Server Mods"))
        local list_server = KnownModIndex:GetServerModNames()
        if SELECTED_SORTING_METHOD == 7 then
            table.sort(list_server, ModSortingComparators[1])
            table.sort(list_server, ModSortingComparators[7])
        else
            table.sort(list_server, ModSortingComparators[SELECTED_SORTING_METHOD])
        end
        for _, modname in ipairs(list_server) do
            PrepareModIcon(modname)
            self.pages.mods.mod_entries:AddChild(ModEntry(modname, self.rowWidth))
                :SetOnFavoriteUpdatedFn(function()
                    if SELECTED_SORTING_METHOD == 7 then
                        LayoutModEntries()
                    end
                end)
        end

        self.pages.mods.mod_entries:LayoutChildrenInColumn(self.rowSpacing * 0.5)
        self.pages.mods:LayoutChildrenInColumn(self.rowSpacing * 0.5)
    end

    self.tabs.mods = self.nav_tabs:AddIconTextTab("images/icons_ftf/stat_luck.tex", "Mods")
    self.tabs.mods:SetGainFocusSound(fmodtable.Event.hover)

    -- refresh the nav bar again
    local icon_size = GLOBAL.FONTSIZE.OPTIONS_SCREEN_TAB * 1.1
    self.nav_tabs
        :SetTabSize(nil, icon_size)
        :Layout() -- For the cycle icons
        :LayoutBounds("center", "top", self.panel_bg)
        :Offset(0, -90)

    self.pages.mods = self.scrollContents:AddChild(Widget("Page Mods"))
    self.tabs.mods.page = self.pages.mods

    -- reload entry (click to reload the game)
    self.pages.mods.reload_row = self.pages.mods:AddChild(OptionScreenModMenuReloadButton(self.rowWidth, 0))

    -- sort method spinner option (sort by.../.../...)
    self.pages.mods:AddChild(OptionsScreenSpinnerRow(self.rowWidth, self.rowRightColumnWidth))
        :SetText("Sort by", "Sort mods by this method.")
        :SetValues({
            { name = "Name",              data = 1 },
            { name = "Name Descending",   data = 2 },
            { name = "Author",            data = 3 },
            { name = "Author Descending", data = 4 },
            { name = "Enabled First",     data = 5 },
            { name = "Disabled First",    data = 6 },
            { name = "Favorites First",   data = 7 },
        })
        :_SetValue(SELECTED_SORTING_METHOD)
        :SetOnValueChangeFn(function(data)
            SELECTED_SORTING_METHOD = data
            LayoutModEntries()
        end)

    self.pages.mods.mod_entries = self.pages.mods:AddChild(Widget("Mod Entries"))
    LayoutModEntries()
end)
