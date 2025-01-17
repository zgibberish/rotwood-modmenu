Assets = {
    Asset("IMAGE", "images/modicon_frame.png"),
    Asset("IMAGE", "images/modicon_mask.png"),
}

local KnownModIndex = GLOBAL.KnownModIndex

local Widget = require "widgets.widget"
local fmodtable = require "defs.sound.fmodtable"

local OptionScreenModMenuReloadButton = require "modmenu.widgets.optionsscreen_modmenu_reloadbutton"
local ModEntry = require "modmenu.widgets.modentry"
local OptionsScreenCategoryTitle = require "modmenu.widgets.optionsscreencategorytitle"
local OptionsScreenSpinnerRow = require "modmenu.widgets.optionsscreenspinnerrow"
local ModSortingComparators = require "modmenu.modsortingcomparators"

local DEFAULT_SORTING_METHOD <const> = 1 --FavoritesFirst
local SELECTED_SORTING_METHOD = DEFAULT_SORTING_METHOD

-- set up modmenu persist data util
local MMPersistDataUtil = require "modmenu.util.mmpersistdatautil"
MMPersistDataUtil.Init()

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

local function SortMods(modtable, sort_fn_index) 
    --NOTE (favorites first sorting): if you select sort by favorited first,
        -- the list will be sorted alphabetically first, then favorites first
        -- on top of that.
    -- mods shown are sorted by their fancy name (the name defined in modinfo),
    -- if there is no fancy name, the moddir name is used

    -- using 
    -- everything is sorted alphabetically first before sorting with
    -- any other comparators
    table.sort(modtable, ModSortingComparators[2]) --Alphabetical
    if sort_fn_index ~= 2 then -- anything other than Alphabetical
        table.sort(modtable, ModSortingComparators[sort_fn_index])
    end
end

AddClassPostConstruct("screens.optionsscreen", function(self)
    if self.nav_tabs == nil or self.tabs == nil or self.scrollContents == nil then
        print("modmenu optionsscreen postconstruct failed?")
        print("->    self.nav_tabs == nil or self.tabs == nil or self.scrollContents == nil")
        return
    end
    
    --NOTE: this is only the definition, LayoutModEntries gets called last
    local function LayoutModEntries() 
        self.pages.mods.mod_entries:RemoveAllChildren()

        --NOTE: there are basically no differences between client and server
        -- mods, its just a thing left behind from the DST modding system,
        -- we dont have server/client hosting in rotwood so it doesn't matter
        -- but you can still set that property in your mod and it will be
        -- categorized based on that because why not.

        local function onfavoriteupdated()
            if SELECTED_SORTING_METHOD == 1 then --FavoritesFirst
                LayoutModEntries()
            end
        end

        -- CLIENT MODS
        self.pages.mods.mod_entries:AddChild(OptionsScreenCategoryTitle(self.rowWidth, "Client Mods"))
        local list_client = KnownModIndex:GetClientModNames()
        SortMods(list_client, SELECTED_SORTING_METHOD)
        for _, modname in ipairs(list_client) do
            PrepareModIcon(modname)
            self.pages.mods.mod_entries:AddChild(ModEntry(modname, self.rowWidth))
                :SetOnFavoriteUpdatedFn(onfavoriteupdated)
        end

        -- SERVER MODS
        self.pages.mods.mod_entries:AddChild(OptionsScreenCategoryTitle(self.rowWidth, "Server Mods"))
        local list_server = KnownModIndex:GetServerModNames()
        SortMods(list_server, SELECTED_SORTING_METHOD)
        for _, modname in ipairs(list_server) do
            PrepareModIcon(modname)
            self.pages.mods.mod_entries:AddChild(ModEntry(modname, self.rowWidth))
                :SetOnFavoriteUpdatedFn(onfavoriteupdated)
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
        :SetText("Sort by", "Show mods in this order")
        :SetValues({ -- only number data works right (i tried)
            { name = "Favorites First",   data = 1 }, --FavoritesFirst
            { name = "Name",              data = 2 }, --Alphabetical
            { name = "Name Descending",   data = 3 }, --AlphabeticalReversed
            { name = "Author",            data = 4 }, --Author
            { name = "Author Descending", data = 5 }, --AuthorReversed
            { name = "Enabled First",     data = 6 }, --EnabledFirst
            { name = "Disabled First",    data = 7 }, --DisabledFirst
        })
        :_SetValue(SELECTED_SORTING_METHOD)
        :SetOnValueChangeFn(function(data)
            SELECTED_SORTING_METHOD = data
            LayoutModEntries()
        end)

    self.pages.mods.mod_entries = self.pages.mods:AddChild(Widget("Mod Entries"))
    LayoutModEntries()
end)
