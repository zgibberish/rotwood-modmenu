local Widget = require "widgets.widget"
local OptionsScreenCategoryTitle = require "widgets/optionsscreencategorytitle"
local OptionsScreenBaseRow = require "widgets/optionsscreenbaserow"
local OptionsScreenToggleRow = require "widgets/optionsscreentogglerow"
local OptionsScreenSpinnerRow = require "widgets/optionsscreenspinnerrow"
local ModEntryImageButton = require "widgets/modentry_imagebutton"
local ModEntryImageButtonToggle = require "widgets/modentry_imagebutton_toggle"
local ModConfiguratorScreen = require "screens/modconfiguratorscreen"
local ModSortingComparators = require "modsortingcomparators"
local fmodtable = require "defs.sound.fmodtable"

local MOD_ENTRY_BUTTON_WIDTH = 200
local RELOAD_ROW_COLOR = { r = 247, g = 182, b = 87 }
local DEFAULT_SORTING_METHOD = 1
local SELECTED_SORTING_METHOD = DEFAULT_SORTING_METHOD

local function OptionsScreen_AddModsTab(self)
    if self.nav_tabs ~= nil and self.tabs ~= nil and self.scrollContents ~= nil then
        local function AddModEntry(modname)
            local mod_fancyname = GLOBAL.KnownModIndex:GetModFancyName(modname)
            local mod_description = "No description"
            local mod_author = "unknown"
            local mod_version = "unknown"
            local mod_enabled = false
            if GLOBAL.KnownModIndex:GetModInfo(modname) and GLOBAL.KnownModIndex:GetModInfo(modname).description then
                mod_description = GLOBAL.KnownModIndex:GetModInfo(modname).description
            end
            if GLOBAL.KnownModIndex:GetModInfo(modname) and GLOBAL.KnownModIndex:GetModInfo(modname).author then
                mod_author = GLOBAL.KnownModIndex:GetModInfo(modname).author
            end
            if GLOBAL.KnownModIndex:GetModInfo(modname) and GLOBAL.KnownModIndex:GetModInfo(modname).version then
                mod_version = GLOBAL.KnownModIndex:GetModInfo(modname).version
            end
            if GLOBAL.KnownModIndex and GLOBAL.KnownModIndex.savedata and GLOBAL.KnownModIndex.savedata.known_mods and GLOBAL.KnownModIndex.savedata.known_mods[modname] and GLOBAL.KnownModIndex.savedata.known_mods[modname].enabled then
                mod_enabled = true
            end
            local entry_desc = mod_description ..
            "\n<i>Author: " .. mod_author .. "\nVersion: " .. mod_version .. "\nDirectory: " .. modname .. "</i>"
            local mod_is_favorited = GLOBAL.Profile:IsModFavorited(modname)
            local mod_has_configurations = GLOBAL.KnownModIndex:HasModConfigurationOptions(modname)

            local entry = self.pages.mods.mod_entries:AddChild(Widget("Mod Entry Row"))
            entry.entry_main = entry:AddChild(OptionsScreenToggleRow(self.rowWidth - MOD_ENTRY_BUTTON_WIDTH - 10))
                :SetText(mod_fancyname)
                :SetValues({
                    { desc = entry_desc, data = true },
                    { desc = entry_desc, data = false }
                })
                :_SetValue(mod_enabled and 1 or 2)
                :SetOnValueChangeFn(function(data)
                    if GLOBAL.KnownModIndex and GLOBAL.KnownModIndex.savedata and GLOBAL.KnownModIndex.savedata.known_mods and GLOBAL.KnownModIndex.savedata.known_mods[modname] and GLOBAL.KnownModIndex.savedata.known_mods[modname].enabled ~= nil then
                        if data then
                            GLOBAL.KnownModIndex:Enable(modname)
                        else
                            GLOBAL.KnownModIndex:Disable(modname)
                        end
                    end
                end)

            -- adding side buttons to a mod entry (the buttosn to the right)
            entry.sidebuttons_container = entry:AddChild(Widget("Mod Entry Side Buttons Container"))
            -- full height if we only need to add a favorite button, half height
            -- if we have a configs button, because they would stack on top of each other
            local sidebutton_height = mod_has_configurations and (entry.entry_main.height / 2 - 10) or
            entry.entry_main.height
            -- adding favorite button
            entry.sidebuttons_container:AddChild(ModEntryImageButtonToggle("images/icons_ftf/stat_health.tex", MOD_ENTRY_BUTTON_WIDTH, sidebutton_height))
                :SetName("Favorite Toggle Button")
                :SetImageOffset(4, 4)
                :SetValues({
                    { data = true },
                    { data = false }
                })
                :_SetValue(mod_is_favorited and 1 or 2)
                :OnFocusChange(false) -- to help the button updates its image color after setting its values manually
                :SetOnValueChangeFn(function(data)
                    GLOBAL.Profile:SetModFavorited(modname, data)
                    GLOBAL.Profile.dirty = true
                    GLOBAL.Profile:Save()

                    -- re-sort the mod list if we're selecting sort by favorites
                    if SELECTED_SORTING_METHOD == 7 then
                        LayoutModEntries()
                    end
                end)

            if mod_has_configurations then
                -- adding mod configs button
                entry.sidebuttons_container:AddChild(ModEntryImageButton("images/ui_ftf_dialog/ic_options.tex", MOD_ENTRY_BUTTON_WIDTH, sidebutton_height))
                    :SetName("Config Button")
                    :SetImageOffset(4, 4)
                    :SetOnClickFn(function()
                        local configurator_screen = ModConfiguratorScreen(modname)
                        GLOBAL.TheFrontEnd:PushScreen(configurator_screen)
                    end)
            end

            entry.sidebuttons_container:LayoutChildrenInColumn(10)
            entry:LayoutChildrenInRow(10)
        end

        local function LayoutModEntries()
            self.pages.mods.mod_entries:RemoveAllChildren()

            --NOTE: there are basically no differences between client and server
            -- mods, its just a thing left behind from the DST modding system,
            -- we dont have server/client hosting in rotwood so it doesn't matter
            -- but you can still set that property in your mod and it will be
            -- categorized based on that because why not.

            -- CLIENT MODS
            self.pages.mods.mod_entries:AddChild(OptionsScreenCategoryTitle(self.rowWidth, "Client Mods"))
            -- mods are shown sorted by their fancy name (the name defined in modinfo), if there is no fancy name, the moddir name is used
            local list_client = GLOBAL.KnownModIndex:GetClientModNames()
            if SELECTED_SORTING_METHOD == 7 then
                -- the user has chose to view favorites first, but we will also
                -- sort the list alphabetically first, then push the favorites on
                -- top after
                table.sort(list_client, ModSortingComparators[1])
                table.sort(list_client, ModSortingComparators[7])
            else
                table.sort(list_client, ModSortingComparators[SELECTED_SORTING_METHOD])
            end
            for _, modname in ipairs(list_client) do
                AddModEntry(modname)
            end

            -- SERVER MODS
            self.pages.mods.mod_entries:AddChild(OptionsScreenCategoryTitle(self.rowWidth, "Server Mods"))
            local list_server = GLOBAL.KnownModIndex:GetServerModNames()
            if SELECTED_SORTING_METHOD == 7 then
                -- the user has chose to view favorites first, but we will also
                -- sort the list alphabetically first, then push the favorites on
                -- top after
                table.sort(list_server, ModSortingComparators[1])
                table.sort(list_server, ModSortingComparators[7])
            else
                table.sort(list_server, ModSortingComparators[SELECTED_SORTING_METHOD])
            end
            for _, modname in ipairs(list_server) do
                AddModEntry(modname)
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
        local reload_row = self.pages.mods:AddChild(OptionsScreenBaseRow(self.rowWidth, 0))
            :SetText(
                "Confirm options and Reload",
                "Click here to save mod config changes and reload the game.\n<i>ANY UNSAVED IN-GAME PROGRESS WILL BE LOST!</i>"
            )
            :SetOnClickFn(function()
                GLOBAL.KnownModIndex:Save()
                GLOBAL:c_reset()
            end)
        reload_row.bgSelectedColor = GLOBAL.RGB(RELOAD_ROW_COLOR.r, RELOAD_ROW_COLOR.g, RELOAD_ROW_COLOR.b)
        reload_row.bgUnselectedColor = GLOBAL.RGB(RELOAD_ROW_COLOR.r, RELOAD_ROW_COLOR.g, RELOAD_ROW_COLOR.b, 0)

        -- sort method spinner option (sort by.../.../...)
        self.pages.mods:AddChild(OptionsScreenSpinnerRow(self.rowWidth, self.rowRightColumnWidth))
            :SetText("Sort by", "Sort the mod list by this method.")
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
    end
end

AddClassPostConstruct("screens/optionsscreen", OptionsScreen_AddModsTab)
