-- Party and raid frames at full opacity (his ask, 2026-11-07: "the bars are not lit up when I am
-- within range of them").
-- Cause, found in his imported Edit Mode layout (RetailImport/Data.lua): Party and Raid carry
-- setting 20 (Opacity) = raw 1, which this client reads as 50 + 1 = 51 %
-- (EditModeSettingDisplayInfo.lua, ConvertValueDefault, minValue 50). Blizzard's
-- EditModeUnitFrameSystemMixin:UpdateSystemSettingOpacity puts that on PartyFrame and
-- CompactRaidFrameContainer, so every member drew at half strength, and Blizzard's own range
-- fade (0.5) came on top for those out of range. Blizzard's range fade is left as it is; only
-- the container goes back to 1, after Blizzard sets it. SetAlpha is not protected.
local ADDON, ns = ...

local function Full(frame)
	if frame and not frame:IsForbidden() and frame:GetAlpha() < 1 then frame:SetAlpha(1) end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
	-- a frame later: no work of ours in the client's own login run (taint lesson 2026-10-19)
	C_Timer.After(0, function()
		for _, frame in ipairs({ PartyFrame, CompactRaidFrameContainer }) do
			if frame and frame.UpdateSystemSettingOpacity then
				hooksecurefunc(frame, "UpdateSystemSettingOpacity", Full)
			end
			Full(frame)
		end
		-- power bar on every party/raid member, not only healers (his ask, 2026-11-07: his own
		-- warlock bar was missing). The CVar callback in Blizzard_CUFProfiles applies it to the frames.
		if not InCombatLockdown() and C_CVar.GetCVar("raidFramesDisplayOnlyHealerPowerBars") == "1" then
			C_CVar.SetCVar("raidFramesDisplayOnlyHealerPowerBars", "0")
		end
	end)
end)
