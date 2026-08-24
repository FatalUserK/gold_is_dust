--Temporary config file for feature control

local settings = {
	--PERKS:
	--Gold Is Dust perk, replaces Gold Is Forever
	-- Alternative that doesn't flood your game with physics entities.
	gold_is_dust = true,

	--Spells Materialised perk, replaces Bombs Materialised.
	-- Makes it so the perk now works with (nearly) all spells.
	spells_materialised = true,

	--Wand Whisperer
	-- Gives TWWE and also randomly charms wands not held by you to fight alongside you.
	wand_whisperer = true,

	--Switch Teams, replaces More Love
	-- Perk is unfinished, will align you with a random faction.
	switch_teams = false,


	--QOL:

	--More Status Indicators QOL
	-- Adds more status indicators to effects inflicted by spells and such
	status_icons = true,
	meat_curse_status = false, --Show a status indicator for meat realm antiheal?
	cessation_status = false, --Show a status indicator when cessated? (requires polymorph_gui=true)

	--Show GUI While Polymorphed
	-- Honestly this is super fun imo, only displays relevant information.
	polymorph_gui = true,

	--Generic Perk QOL
	-- Some minor tweaks to Extra Capacity and High Mana, Low Capacity perks.
	--  Extra Capacity now guarantees 2-3 increase on held wand
	--  High Mana, Low Capacity now only takes 1-3 + 10% of capacity rounded down slots
	--   That's 3-5 slots on a 20+ wand, else a 2-4 on a 10+ wand, else 1-3 if lower
	--   Also slightly tweaked mana numbers
	generic_perk_qol = true,
}

return settings