local function FavoritesFirst(a, b)
    local favorited_a = Profile:IsModFavorited(a)
    local favorited_b = Profile:IsModFavorited(b)
    return favorited_a and not favorited_b
end

local function Alphabetical(a, b)
    return KnownModIndex:GetModFancyName(a) < KnownModIndex:GetModFancyName(b)
end

local function AlphabeticalReversed(a, b) return Alphabetical(b, a) end

local function Author(a, b)
    local author_a = ""
    if KnownModIndex and KnownModIndex.GetModInfo and KnownModIndex:GetModInfo(a) and KnownModIndex:GetModInfo(a)["author"] then
        author_a = KnownModIndex:GetModInfo(a)["author"]
    end
    local author_b = ""
    if KnownModIndex and KnownModIndex.GetModInfo and KnownModIndex:GetModInfo(b) and KnownModIndex:GetModInfo(b)["author"] then
        author_b = KnownModIndex:GetModInfo(b)["author"]
    end
    return author_a < author_b
end

local function AuthorReversed(a, b) return Author(b, a) end

local function EnabledFirst(a, b)
    local enabled_a = KnownModIndex:IsModEnabledAny(a)
    local enabled_b = KnownModIndex:IsModEnabledAny(b)
    return enabled_a and not enabled_b
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
