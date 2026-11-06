-- Party and raid frame range fade, as on retail (his ask, 2026-11-07: "the bars are not lit up
-- when I am within range of them, like 40 yards").
-- Blizzard's CompactUnitFrame_UpdateInRange compares UnitInRange's answer in Lua. On Forever that
-- answer is always secret to addons (UnitDocumentation: SecretReturns), so once the frames run
-- tainted the fade sticks at half alpha. This sets the alpha the secret-safe way:
-- frame:SetAlphaFromBoolean(inRange, 1, 0.55) lets the client read the answer, our code never
-- does. Same pattern as BetterBlizzFrames' forever build (HookAndUpdatePartyFrameRangeAlpha).
-- SetAlpha is not a protected action, so this runs in combat too.
local ADDON, ns = ...

local IN_RANGE_ALPHA = 1
local OUT_OF_RANGE_ALPHA = 0.55   -- retail's value

local function Fade(frame)
	if not frame or frame:IsForbidden() or not frame:IsShown() then return end
	local unit = frame.displayedUnit
	if type(unit) ~= "string" or unit:find("^nameplate") then return end
	if unit == "player" then
		frame:SetAlpha(IN_RANGE_ALPHA)   -- you are always in range of yourself
		return
	end
	local inRange = UnitInRange(unit)
	frame:SetAlphaFromBoolean(inRange, IN_RANGE_ALPHA, OUT_OF_RANGE_ALPHA)
end

local function FadeAll()
	for i = 1, 5 do Fade(_G["CompactPartyFrameMember" .. i]) end
	if IsInRaid() then
		for i = 1, 40 do Fade(_G["CompactRaidFrame" .. i]) end
	end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
	-- a frame later: no work of ours in the client's own login run (taint lesson 2026-10-19)
	C_Timer.After(0, function()
		-- Blizzard sets the frame alpha in here; ours comes right after it.
		if CompactUnitFrame_UpdateCenterStatusIcon then
			hooksecurefunc("CompactUnitFrame_UpdateCenterStatusIcon", Fade)
		end
		-- Blizzard only calls that when its own (stuck) idea of range changes, so also follow
		-- range changes ourselves, plus a light poll for units the event misses.
		local watcher = CreateFrame("Frame")
		watcher:RegisterEvent("UNIT_IN_RANGE_UPDATE")
		watcher:RegisterEvent("GROUP_ROSTER_UPDATE")
		watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
		watcher:SetScript("OnEvent", FadeAll)
		C_Timer.NewTicker(0.5, function()
			if IsInGroup() then FadeAll() end
		end)
		FadeAll()
	end)
end)
