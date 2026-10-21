-- Deno Retail Frames for WoW: Forever (interface 16001).
-- Forever's player and target frames are the retail frames with the same art (byte for byte,
-- checked 2026-10-18), only re-laid out by Blizzard_UnitFrame/Camelot: the level in a small
-- circle, the name centred, a shorter health bar. This puts the retail layout back, with the
-- values from Blizzard_UnitFrame/Mainline. Blizzard's own frames stay: clicks, menus and
-- Edit Mode are untouched. Everything goes through hooksecurefunc, nothing is replaced.
local ADDON, ns = ...

local GOLD_R, GOLD_G, GOLD_B = 1.0, 0.82, 0.0

-- Moving a protected region in combat is refused; such work waits for the fight to end.
local pending = {}
local waiter = CreateFrame("Frame")
waiter:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	for fn in pairs(pending) do
		pending[fn] = nil
		fn()
	end
end)

local function OutOfCombat(fn)
	if InCombatLockdown() then
		pending[fn] = true
		waiter:RegisterEvent("PLAYER_REGEN_ENABLED")
	else
		fn()
	end
end

------------------------------------------------------------------------------------------
-- Player frame
------------------------------------------------------------------------------------------
local function PlayerMain()
	return PlayerFrame and PlayerFrame.PlayerFrameContent and PlayerFrame.PlayerFrameContent.PlayerFrameContentMain
end

local function InVehicle()
	return PlayerFrame.unit == "vehicle"
end

-- Name and level, as PlayerFrame.xml and PlayerFrameTemplates.xml (Mainline).
local function PlayerText()
	local main = PlayerMain()
	if not main or not PlayerName or not PlayerLevelText or InVehicle() then return end
	PlayerName:SetJustifyH("LEFT")
	PlayerName:SetWidth(96)
	PlayerName:ClearAllPoints()
	PlayerName:SetPoint("TOPLEFT", 88, -27)

	if main.LevelBackgroundCircle then main.LevelBackgroundCircle:Hide() end
	PlayerLevelText:SetFontObject(GameNormalNumberFont)
	PlayerLevelText:SetJustifyH("RIGHT")
	PlayerLevelText:ClearAllPoints()
	PlayerLevelText:SetPoint("TOPRIGHT", -24.5, -28)
end

-- Health and mana bars, as PlayerFrame_UpdateHealthBarVisuals / ManaBarVisuals (Mainline).
local function PlayerBars()
	if not PlayerMain() or InVehicle() then return end
	local container, health, mana = PlayerFrame_GetHealthBarContainer(), PlayerFrame_GetHealthBar(), PlayerFrame_GetManaBar()
	if not (container and health and mana) then return end
	-- the target frame's bar slots, mirrored; the target's masks (mirrored) cut the bar ends to the ring
	container:SetWidth(126)
	container:SetHeight(20)
	container:SetPoint("TOPLEFT", 83, -40)
	health:SetHeight(20)
	health:ClearAllPoints()
	health:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
	-- the target's health mask, mirrored: 128 x 32 at TOPLEFT -1,6 becomes TOPRIGHT +1,6
	local hmask = container.HealthBarMask
	hmask:SetAtlas("UI-HUD-UnitFrame-Player-PortraitOn-Bar-Health-Mask")
	hmask:SetSize(128, 32)
	hmask:ClearAllPoints()
	hmask:SetPoint("TOPRIGHT", container, "TOPRIGHT", 1, 6)

	mana:SetHeight(10)
	mana:SetWidth(134)
	mana:SetPoint("TOPLEFT", 75, -61)
	-- the target's mana mask, mirrored: 256 x 16 at TOPLEFT -61,3 becomes TOPRIGHT +61,3
	local mmask = mana.ManaBarMask
	if mmask then
		mmask:SetAtlas("UI-HUD-UnitFrame-Player-PortraitOn-Bar-Mana-Mask")
		mmask:SetSize(256, 16)
		mmask:ClearAllPoints()
		mmask:SetPoint("TOPRIGHT", mana, "TOPRIGHT", 61, 3)
	end

	-- round portrait in the target's spot, mirrored
	local portrait = PlayerFrame.PlayerFrameContainer.PlayerPortrait
	local mask = PlayerFrame.PlayerFrameContainer.PlayerPortraitMask
	if portrait then
		portrait:SetSize(58, 58)
		portrait:ClearAllPoints()
		portrait:SetPoint("TOPLEFT", 26, -19)
	end
	if mask and portrait then
		mask:ClearAllPoints()
		mask:SetAllPoints(portrait)
	end
end

local function PlayerLayout()
	OutOfCombat(PlayerText)
	OutOfCombat(PlayerBars)
end

-- Forever colours the level white; retail colours it gold (green while scaled).
local function PlayerLevelColor()
	if not PlayerLevelText then return end
	local r, g, b = PlayerLevelText:GetVertexColor()
	if canaccessvalue(r) and canaccessvalue(g) and canaccessvalue(b) and r == 1 and g == 1 and b == 1 then
		PlayerLevelText:SetVertexColor(GOLD_R, GOLD_G, GOLD_B, 1)
	end
end

------------------------------------------------------------------------------------------
-- Target and focus frames
------------------------------------------------------------------------------------------
-- Name, level, reputation strip and mana bar, as TargetFrame.xml / TargetFrameTemplates.xml (Mainline).
local function TargetText(frame)
	local main = frame.TargetFrameContent and frame.TargetFrameContent.TargetFrameContentMain
	if not (main and main.ReputationColor and main.Name and main.LevelText and main.ManaBar) then return end
	local rep, name, level = main.ReputationColor, main.Name, main.LevelText

	rep:ClearAllPoints()
	rep:SetPoint("TOPRIGHT", main, "TOPRIGHT", -75, -25)
	name:SetJustifyH("LEFT")
	name:SetWidth(90)
	name:ClearAllPoints()
	name:SetPoint("TOPLEFT", rep, "TOPRIGHT", -106, -1)

	if main.LevelBackgroundCircle then main.LevelBackgroundCircle:Hide() end
	level:SetFontObject(GameNormalNumberFont)
	level:SetJustifyH("CENTER")
	level:ClearAllPoints()
	level:SetPoint("TOPLEFT", rep, "TOPRIGHT", -133, -2)

	local contextual = frame.TargetFrameContent.TargetFrameContentContextual
	if contextual and contextual.HighLevelTexture then
		contextual.HighLevelTexture:ClearAllPoints()
		contextual.HighLevelTexture:SetPoint("TOPLEFT", level, "TOPLEFT", 4, 2)
	end

	local mana = main.ManaBar
	mana:SetWidth(134)
	mana:ClearAllPoints()
	mana:SetPoint("TOPRIGHT", main.HealthBarsContainer, "BOTTOMRIGHT", 8, -1)

	local flash = frame.TargetFrameContainer and frame.TargetFrameContainer.Flash
	if flash then
		flash:ClearAllPoints()
		flash:SetPoint("CENTER", frame.TargetFrameContainer, "CENTER", 0, 2)
	end
end

-- As TargetFrameMixin:UpdateHealthBarVisuals (Mainline), normal mobs only; Forever's own
-- layout is kept for the small "minus" mobs.
local function TargetBars(frame, classification)
	if classification == "minus" then return end
	local main = frame.TargetFrameContent and frame.TargetFrameContent.TargetFrameContentMain
	local container = main and main.HealthBarsContainer
	local health = container and container.HealthBar
	if not health then return end
	health:ClearAllPoints()
	health:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
	health:SetHeight(20)
	container:SetHeight(20)
	container:SetWidth(126)
	container:SetPoint("BOTTOMRIGHT", frame.TargetFrameContainer, "LEFT", 149, -10)
	container.HealthBarMask:SetPoint("TOPLEFT", -1, 6)
end

-- The strip behind a player's name in their class colour (his ask, 2026-10-18), instead of
-- the blue the game gives every friendly player. NPCs keep the game's reaction colour.
local function ClassStrip(frame)
	local unit = frame.unit
	local strip = frame.TargetFrameContent and frame.TargetFrameContent.TargetFrameContentMain.ReputationColor
	if not unit or not strip then return end
	local isPlayer = UnitIsPlayer(unit)
	if not canaccessvalue(isPlayer) or not isPlayer then return end
	local _, class = UnitClass(unit)
	if not canaccessvalue(class) or not class then return end
	local color = C_ClassColor.GetClassColor(class)
	if color then strip:SetVertexColor(color:GetRGB()) end
end

local function HookTarget(frame)
	if not frame or not frame.UpdateHealthBarVisuals then return end
	if frame.CheckFaction then hooksecurefunc(frame, "CheckFaction", ClassStrip) end
	OutOfCombat(function() TargetText(frame) end)
	hooksecurefunc(frame, "UpdateHealthBarVisuals", function(self, classification)
		OutOfCombat(function() TargetBars(self, classification) end)
	end)
	OutOfCombat(function() TargetBars(frame, nil) end)
end

------------------------------------------------------------------------------------------
-- Retail art (his picture, 2026-10-18). Forever answers every frame atlas from its own "-c60" set
-- (UiTextureAtlasSetID 1, sheet 8036209: square boxes, bronze edge); retail's set 0 is still in the
-- client. Measured in his client: PortraitOn drew file 8036209. Each piece Blizzard sets by atlas
-- name is pointed back at the retail file and coordinates (UiTextureAtlasMember, build 70450).
------------------------------------------------------------------------------------------
local SHEET, SW, SH = 4642466, 2048, 1024   -- interface/hud/uiunitframe2x.blp
local ART = {
	-- The player frame wears the target frame's art mirrored: a round portrait ring like the target's
	-- instead of the teardrop with its square corner (his ask, 2026-10-18, with a picture of the target).
	["ui-hud-unitframe-player-portraiton"] = { 1, 385, 451, 585, mirror = true, w = 192, h = 67 },
	["ui-hud-unitframe-player-portraiton-incombat"] = { 1, 377, 859, 993, mirror = true, w = 188, h = 67 },
	["ui-hud-unitframe-player-portraiton-status"] = { 1, 377, 859, 993, mirror = true, w = 188, h = 67 },
	["ui-hud-unitframe-player-portraiton-cornerembellishment"] = { hide = true },
	["ui-hud-unitframe-player-portraiton-classresource"] = { 1607, 2003, 1, 149 },
	["ui-hud-unitframe-player-portraiton-classresource-incombat"] = { 793, 1177, 171, 313 },
	["ui-hud-unitframe-target-portraiton"] = { 1, 385, 451, 585 },
	["ui-hud-unitframe-target-portraiton-incombat"] = { 1, 377, 859, 993 },
	["ui-hud-unitframe-target-portraiton-type"] = { 887, 1157, 461, 497 },
	["ui-hud-unitframe-targetoftarget-portraiton"] = { 1113, 1353, 315, 413 },
	["ui-hud-unitframe-targetoftarget-portraiton-incombat"] = { 1597, 1825, 315, 409 },
	["ui-hud-unitframe-targetoftarget-portraiton-status"] = { 1355, 1595, 315, 413 },
}
-- the masks that cut the bars and the portrait to shape are whole files of their own (2x)
local MASKS = {
	["ui-hud-unitframe-player-portrait-mask"] = "circle",
	["ui-hud-unitframe-player-portraiton-bar-health-mask"] = 5321215,
	["ui-hud-unitframe-player-portraiton-bar-mana-mask"] = 5321218,
	["ui-hud-unitframe-target-portraiton-bar-health-mask"] = 5321212,
	["ui-hud-unitframe-target-portraiton-bar-mana-mask"] = 5321221,
}

-- Bar fills: Forever's fill art has an empty margin round the green (his picture: "it doesnt fill
-- out my HP color ... got some gaps"). A status bar cannot take part of a sheet, so retail's fills
-- were cut from the retail sheet into Media/*.tga, one whole file per bar.
local MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\Media\\"
local FILLS = {}
for unit, prefix in pairs({ player = "ui-hud-unitframe-player-portraiton-bar-",
		target = "ui-hud-unitframe-target-portraiton-bar-", tot = "ui-hud-unitframe-targetoftarget-portraiton-bar-" }) do
	for _, kind in ipairs({ "health", "mana", "rage", "energy", "focus", "runicpower" }) do
		FILLS[prefix .. kind] = MEDIA .. unit .. "-" .. kind .. ".tga"
	end
end

-- The player bars sit in the target's mirrored slots, so they take the target's masks mirrored
-- (Media/player-*-mask.tga, flipped from files 5321212 and 5321221): the bar ends then tuck under
-- the ring as on the target frame (his picture of the target: "it looks perfect").
MASKS["ui-hud-unitframe-player-portraiton-bar-health-mask"] = MEDIA .. "player-health-mask.tga"
MASKS["ui-hud-unitframe-player-portraiton-bar-mana-mask"] = MEDIA .. "player-mana-mask.tga"

local function Retail(region, atlas)
	-- an atlas name Blizzard picked from secret unit state comes in secret: no reading it, the game's piece stays
	if issecretvalue and issecretvalue(atlas) then return end
	if type(atlas) ~= "string" then return end
	atlas = atlas:lower()
	if FILLS[atlas] and region:IsObjectType("Texture") then
		region:SetTexture(FILLS[atlas])
		return
	end
	if region:IsObjectType("MaskTexture") then
		local file = MASKS[atlas]
		if file == "circle" then
			region:SetAtlas("CircleMaskScalable")
		elseif file then
			region:SetTexture(file, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
		end
		return
	end
	local c = ART[atlas]
	if not c then return end
	if c.hide then
		region:SetAlpha(0)
		return
	end
	region:SetTexture(SHEET)
	if c.mirror then
		region:SetTexCoord(c[2] / SW, c[1] / SW, c[3] / SH, c[4] / SH)
	else
		region:SetTexCoord(c[1] / SW, c[2] / SW, c[3] / SH, c[4] / SH)
	end
	if c.w then region:SetSize(c.w, c.h) end
end

local hooked = {}
local function Watch(region)
	if hooked[region] then return end
	hooked[region] = true
	Retail(region, region:GetAtlas())
	hooksecurefunc(region, "SetAtlas", Retail)
end

local function WatchAll(frame, depth)
	if not frame or depth > 8 then return end
	for _, region in ipairs({ frame:GetRegions() }) do
		if region:IsObjectType("Texture") or region:IsObjectType("MaskTexture") then Watch(region) end
	end
	for _, child in ipairs({ frame:GetChildren() }) do
		if child:IsObjectType("StatusBar") and not hooked[child] then
			hooked[child] = true
			local fill = child:GetStatusBarTexture()
			if fill then Watch(fill) end
			hooksecurefunc(child, "SetStatusBarTexture", function(bar, asset)
				local tex = bar:GetStatusBarTexture()
				if tex then
					Watch(tex)
					Retail(tex, asset)
				end
			end)
		end
		WatchAll(child, depth + 1)
	end
end

------------------------------------------------------------------------------------------
-- White absorb shields (his choice, 2026-10-21). The game's own player, target and focus frames
-- already draw incoming heals and shields (UnitFrame_Initialize hands them MyHealPredictionBar,
-- TotalAbsorbBar ...; BetterBlizzFrames' forever/modules/overshields.lua hooks the same fields).
-- Only the colour changes: fill and stripes white as on Deno Nameplate. Blizzard sets the fill
-- colour once at load (StatusBarOverlaySegmentMixin:OnLoad), so one SetVertexColor holds; no
-- SetFillColor, which would hand Blizzard's code a colour object our addon made.
------------------------------------------------------------------------------------------
local function WhiteShield(frame)
	local bar = frame and frame.totalAbsorbBar
	if not bar then return end
	if bar.Fill then
		bar.Fill:SetDesaturated(true)
		bar.Fill:SetVertexColor(1, 1, 1, 0.35)
	end
	if bar.TiledFillOverlay then
		-- the stripe art itself is tinted blue; grey it so white stays white
		bar.TiledFillOverlay:SetDesaturated(true)
		bar.TiledFillOverlay:SetVertexColor(1, 1, 1, 0.8)
	end
end

------------------------------------------------------------------------------------------
local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
	if PlayerFrame and PlayerFrame_GetHealthBarContainer then
		hooksecurefunc("PlayerFrame_ToPlayerArt", PlayerLayout)
		hooksecurefunc("PlayerFrame_UpdateLevel", PlayerLevelColor)
		PlayerLayout()
		PlayerLevelColor()
	end
	HookTarget(TargetFrame)
	HookTarget(FocusFrame)
	for _, frame in ipairs({ PlayerFrame, TargetFrame, FocusFrame, TargetFrame and TargetFrame.totFrame, FocusFrame and FocusFrame.totFrame }) do
		WatchAll(frame, 0)
	end
	-- a frame later: no work of ours in the client's own login run (taint lesson 2026-10-19)
	C_Timer.After(0, function()
		for _, frame in ipairs({ PlayerFrame, TargetFrame, FocusFrame }) do WhiteShield(frame) end
	end)
end)
