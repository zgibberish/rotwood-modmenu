local function FavoritesFirst(a, b)
    local favorited_a = Profile:IsModFavorited(a)
    local favorited_b = Profile:IsModFavorited(b)
    if favorited_a and not favorited_b then
        return true
    end
    return false
end

local function Alphabetical(a, b)
    return KnownModIndex:GetModFancyName(a) < KnownModIndex:GetModFancyName(b)
end

local function AlphabeticalReversed(a, b) return Alphabetical(b, a) end

local function Author(a, b)
    local author_a = "unknown"
    if KnownModIndex and KnownModIndex.GetModInfo and KnownModIndex:GetModInfo(a) and KnownModIndex:GetModInfo(a)["author"] then
        author_a = KnownModIndex:GetModInfo(a)["author"]
    end
    local author_b = "unknown"
    if KnownModIndex and KnownModIndex.GetModInfo and KnownModIndex:GetModInfo(b) and KnownModIndex:GetModInfo(b)["author"] then
        author_b = KnownModIndex:GetModInfo(b)["author"]
    end
    return author_a < author_b
end

local function AuthorReversed(a, b) return Author(b, a) end

local function EnabledFirst(a, b)
    local enabled_a = KnownModIndex.savedata.known_mods[a].enabled
    local enabled_b = KnownModIndex.savedata.known_mods[b].enabled
    if enabled_a and not enabled_b then
        return true
    end
    return false
end

local function DisabledFirst(a, b) return EnabledFirst(b, a) end

local ModSortingComparators = {
    FavoritesFirst, -- favs first should be the default selected sorting order
    Alphabetical,
    AlphabeticalReversed,
    Author,
    AuthorReversed,
    EnabledFirst,
    DisabledFirst,
}

return ModSortingComparators
