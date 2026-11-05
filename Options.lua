-- Options page (game Options > AddOns > Deno Retail Frames, or /drf).
--
-- Always Show XP Bar Text (his ask, 2026-11-05: "there no xp bar text, can you add that?").
-- Forever's XP bar writes its numbers only while the mouse is over it. The game's own switch for
-- always is the setting xpBarText (Blizzard_StatusTrackingBar/Shared/StatusTrackingBar.lua reads
-- it), but Forever's Options have no checkbox for it. This is that checkbox. The game's own value
-- from before is kept and put back when the option is switched off. The setting is written only
-- when it differs, out of combat, a frame after login: a game setting written by addon code
-- makes the game's code that reads it afterwards run tainted (Deno Nameplate, 2026-10-19).
local ADDON, ns = ...

local DEFAULTS = { xpText = true }

local function ApplyXPText()
	local db = DenoRetailFramesDB
	local now = C_CVar.GetCVar("xpBarText")
	if db.xpText then
		if db.xpTextBefore == nil then db.xpTextBefore = now or "0" end
		if now ~= "1" then C_CVar.SetCVar("xpBarText", "1") end
	elseif db.xpTextBefore ~= nil then
		if now ~= db.xpTextBefore then C_CVar.SetCVar("xpBarText", db.xpTextBefore) end
		db.xpTextBefore = nil
	end
end

local function BuildOptions()
	local category = Settings.RegisterVerticalLayoutCategory("Deno Retail Frames")
	ns.category = category
	local variable = "DenoRetailFrames_xpText"
	local setting = Settings.RegisterAddOnSetting(category, variable, "xpText", DenoRetailFramesDB,
		Settings.VarType.Boolean, "Always Show XP Bar Text", DEFAULTS.xpText)
	Settings.SetOnValueChangedCallback(variable, function() ns.OutOfCombat(ApplyXPText) end)
	Settings.CreateCheckbox(category, setting,
		"On (default): the experience bar shows its numbers all the time, not only under the mouse. "
		.. "Off: the game's own setting as it was before. Applied out of combat.")
	Settings.RegisterAddOnCategory(category)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(_, event, name)
	if event == "ADDON_LOADED" then
		if name ~= ADDON then return end
		DenoRetailFramesDB = DenoRetailFramesDB or {}
		for key, value in pairs(DEFAULTS) do
			if DenoRetailFramesDB[key] == nil then DenoRetailFramesDB[key] = value end
		end
	else
		-- a frame later: no work of ours in the client's own login run (taint lesson 2026-10-19)
		C_Timer.After(0, function()
			BuildOptions()
			ns.OutOfCombat(ApplyXPText)
		end)
	end
end)

SLASH_DENORETAILFRAMES1 = "/drf"
SlashCmdList.DENORETAILFRAMES = function()
	if ns.category then Settings.OpenToCategory(ns.category:GetID()) end
end
