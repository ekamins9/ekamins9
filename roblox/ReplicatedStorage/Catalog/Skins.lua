--[[ WEAPON SKINS — looks for a weapon; never stats. Each weapon gets a
     "Default" skin automatically (its Tool as built), so list only extras.
       weapon   the weapon id       name    unique within the weapon
       rarity   Common | Rare | Epic | Legendary
       crate    which crate rolls it ("Bladesmith"), "earned" for kill-count
                skins, or nil = sold in the shop for `marks` / `crowns`
       kills    for crate = "earned": kills with that weapon that unlock it
       blade / grip   Color3 tints used when there is no skin model: parts in
                the Tool with attribute SkinPart = "Blade" or "Grip" are recolored
       model    a Model in Cosmetics ▸ Skins ▸ <weapon> ▸ <model or name>:
                its parts replace the Tool's visible parts (welded by their
                offset from the model's own Handle part). Optional. ]]
return {
	{weapon = "Greatsword", name = "Blackened", rarity = "Rare",      crate = "Bladesmith", blade = Color3.fromRGB(58, 61, 68),   grip = Color3.fromRGB(42, 42, 42)},
	{weapon = "Greatsword", name = "Gilded",    rarity = "Legendary", crate = "Bladesmith", blade = Color3.fromRGB(242, 226, 176), grip = Color3.fromRGB(201, 154, 72)},
	{weapon = "Greatsword", name = "Veteran",   rarity = "Epic",      crate = "earned", kills = 100, blade = Color3.fromRGB(184, 192, 200), grip = Color3.fromRGB(106, 42, 42)},
	{weapon = "Shortsword", name = "Pitted",    rarity = "Common",    crate = "Bladesmith", blade = Color3.fromRGB(154, 154, 138), grip = Color3.fromRGB(74, 58, 42)},
	{weapon = "Shortsword", name = "Bluesteel", rarity = "Rare",      crate = "Bladesmith", blade = Color3.fromRGB(138, 168, 216), grip = Color3.fromRGB(42, 42, 74)},
	{weapon = "Shortsword", name = "Crowfeather", rarity = "Epic",    crate = "Bladesmith", blade = Color3.fromRGB(42, 42, 48),   grip = Color3.fromRGB(201, 154, 72)},
	{weapon = "Pitchfork",  name = "Ember",     rarity = "Rare",      crate = "Hafted",     blade = Color3.fromRGB(216, 106, 58), grip = Color3.fromRGB(58, 42, 26)},
	{weapon = "Hammer",     name = "Bronze",    rarity = "Epic",      crate = "Hafted",     blade = Color3.fromRGB(200, 138, 74), grip = Color3.fromRGB(74, 42, 26)},
}
