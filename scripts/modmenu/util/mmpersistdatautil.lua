local SaveData = require "savedata.savedata"
-- NOTE: prepending fav_ to the modname to distinguish them from other
-- keys like version, etc. a bit hacky but works :p
local FAV_PREFIX <const> = "fav_"

local MMPersistDatUtil = {}

-- we made sure to call init in modmain before anything else, 
-- so we can assume everything is set up and registered correctly
-- by the time we need to use it, but still use MMPersistDatUtil.UsableSaveData()
-- just in case
function MMPersistDatUtil.Init()
    -- this is safe, TheSaveSystem is already initialized
    -- before all mods are loaded!
    TheSaveSystem.gbj_modmenufavs = SaveData("gbj_modmenu_favs", "GBJModMenuFavs")
    MMPersistDatUtil.Load()
end

function MMPersistDatUtil.Load()
    local loader = MultiCallback()
    TheSaveSystem.gbj_modmenufavs:Load(loader)
    loader:WhenAllComplete(function(loader_success)
        TheSaveSystem.gbj_modmenufavs.loader_success = loader_success

        if not loader_success then return end -- huh

        -- clean up unused fav flags for mods that have been removed
        local modnames = {}
        for i,name in ipairs(TheSim:GetModDirectoryNames()) do
            modnames[name] = true
        end
        local saved_favs = TheSaveSystem.gbj_modmenufavs.persistdata
        
        -- this looks so messy i hate it
        for k,v in pairs(saved_favs) do
            if string.find(k, '^'..FAV_PREFIX) ~= nil then
                local modname = string.sub(k, string.len(FAV_PREFIX)+1)
                if modnames[modname] == nil then
                    TheSaveSystem.gbj_modmenufavs:SetValue(k, nil)
                end
            end
        end
        MMPersistDatUtil.Save()
    end)
end

function MMPersistDatUtil.UsableSaveData()
    local res = true
    if TheSaveSystem.gbj_modmenufavs == nil then res = false end
    if not TheSaveSystem.gbj_modmenufavs.loader_success then res = false end
    
    if not res then
        print("WARNING (Mod Menu): gbj_modmenufavs corrupted or failed to load. Please submit an issue about this!")
    end

    return res
end

function MMPersistDatUtil.Save()
    if not MMPersistDatUtil.UsableSaveData() then return end;
    TheSaveSystem.gbj_modmenufavs:Save()
end

function MMPersistDatUtil.SetModFavorited(modname, favorited)
    if not MMPersistDatUtil.UsableSaveData() then return end;
    TheSaveSystem.gbj_modmenufavs:SetValue(FAV_PREFIX..modname, favorited)
end
function MMPersistDatUtil.IsModFavorited(modname)
    if not MMPersistDatUtil.UsableSaveData() then return end;
    return TheSaveSystem.gbj_modmenufavs:GetValue(FAV_PREFIX..modname) or false
end

return MMPersistDatUtil
