local ModSortingComparators = {
    function(a, b) -- 1: alphabetical
        return KnownModIndex:GetModFancyName(a) < KnownModIndex:GetModFancyName(b)
    end,
    
    function(a, b) -- 1: reversed alphabetical
        return KnownModIndex:GetModFancyName(a) > KnownModIndex:GetModFancyName(b)
    end,

    function(a, b) -- 3: author
        local author_a = "unknown"
        if KnownModIndex and KnownModIndex.GetModInfo and KnownModIndex:GetModInfo(a) and KnownModIndex:GetModInfo(a)["author"] then
            author_a = KnownModIndex:GetModInfo(a)["author"]
        end
        local author_b = "unknown"
        if KnownModIndex and KnownModIndex.GetModInfo and KnownModIndex:GetModInfo(b) and KnownModIndex:GetModInfo(b)["author"] then
            author_b = KnownModIndex:GetModInfo(b)["author"]
        end
        return author_a < author_b
    end,

    function(a, b) -- 4: reversed author
        local author_a = "unknown"
        if KnownModIndex and KnownModIndex.GetModInfo and KnownModIndex:GetModInfo(a) and KnownModIndex:GetModInfo(a)["author"] then
            author_a = KnownModIndex:GetModInfo(a)["author"]
        end
        local author_b = "unknown"
        if KnownModIndex and KnownModIndex.GetModInfo and KnownModIndex:GetModInfo(b) and KnownModIndex:GetModInfo(b)["author"] then
            author_b = KnownModIndex:GetModInfo(b)["author"]
        end
        return author_a > author_b
    end,

    function(a, b) -- 5: enabled first
        local enabled_a = KnownModIndex.savedata.known_mods[a].enabled
        local enabled_b = KnownModIndex.savedata.known_mods[b].enabled
        if enabled_a and not enabled_b then
            return true
        end
        return false
    end,

    function(a, b) -- 6: disabled first
        local enabled_a = KnownModIndex.savedata.known_mods[a].enabled
        local enabled_b = KnownModIndex.savedata.known_mods[b].enabled
        if enabled_b and not enabled_a then
            return true
        end
        return false
    end,

    function(a, b) -- 7: favorites first
        local favorited_a = Profile:IsModFavorited(a)
        local favorited_b = Profile:IsModFavorited(b)
        if favorited_a and not favorited_b then
            return true
        end
        return false
    end,
}

return ModSortingComparators