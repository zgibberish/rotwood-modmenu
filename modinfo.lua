name = "Mod Menu"
description = "GUI to view and manage installed mods, adds a \"Mods\" tab to the options screen."
author = "gibberish"
version = "2.0.0-beta1c"
api_version = 10

dst_compatible = false
forge_compatible = false
gorge_compatible = false
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false
rotwood_compatible = true

client_only_mod = true
all_clients_require_mod = false

icon_atlas = "modicon.png"
icon = "modicon.png"

--[[
MODDERS PLEASE READ

# Compatibility:
- I highly recommend you to update your mods to work with ModWrangler if needed,
the old modloader will become deprecated very soon after Mod Menu 1.4 release.
- (ModWrangler) Have "rotwood_compatible = true" in your modinfo.lua


# Mod Icons (refer to this for gibberish's Mod Menu's implementation only):
- For mod icons, you'll need to have both icon_atlas and icon, example:
        icon_atlas = "modicon.png"
        icon = "modicon.png"
- There's no restriction on modicon resolution, though the standard (and recommended)
size is 256x256.
- The default icon frame is applied to all mod icons with a mask, if you prefer
having a custom icon + frame, specify "modmenu_bypass_modicon_mask = true" in
your modinfo.lua. (an empty frame + mask template and layered GIMP file can be
found in Mod Menu's images folder if you wanna start from that :3)
- Please please avoid using too large mod icons if you chose to disable the default
frame mask, they may obstruct other elements on screen (recommended size is still
256x256).
]]--
