﻿--[[
--
-- BigWigs Strategy Module - Common Auras
--
-- Gives timer bars and raid messages about common
-- buffs and debuffs.
--
--]]

------------------------------
--      Are you local?      --
------------------------------

local name = "Common Auras"
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..name)

local shieldWallDuration = nil

-- Use for detecting instant cast target (Fear Ward)
local spellTarget = nil

local fear_ward = GetSpellInfo(6346)
local shield_wall = GetSpellInfo(871)
local challenging_shout = GetSpellInfo(1161)
local challenging_roar = GetSpellInfo(5209)
local misdirection = GetSpellInfo(34477)

------------------------------
--      Localization        --
------------------------------

L:RegisterTranslations("enUS", function() return {
	fw_cast = "%s fearwarded %s.",
	fw_bar = "%s: FW Cooldown",

	md_cast = "%s: MD on %s",
	md_bar = "%s: MD Cooldown",

	used_cast = "%s used %s.",
	used_bar = "%s: %s",

	portal_cast = "%s opened a portal to %s!",
	portal_regexp = ".*: (.*)",
	-- portal_bar is the spellname

	["Toggle %s display."] = true,
	["Portal"] = true,
	["broadcast"] = true,
	["Broadcast"] = true,
	["Toggle broadcasting the messages to the raidwarning channel."] = true,

	["Gives timer bars and raid messages about common buffs and debuffs."] = true,
	["Common Auras"] = true,
	["commonauras"] = true,
} end )

L:RegisterTranslations("zhCN", function() return {
	fw_cast = "%s防护恐惧结界%s",
	fw_bar = "%s: 防护恐惧结界冷却",
	
	md_cast = "%s: MD 于 %s",
	md_bar = "%s: MD 冷却",

	used_cast = " 对%s使用%s",
	used_bar = "%s: %s",

	portal_cast = "%s施放一传送门到%s",
	portal_regexp = ".*: (.*)",
	-- portal_bar is the spellname

	["Toggle %s display."] = "选择%s显示",
	["Portal"] = "传送门",
	["broadcast"] = "广播",
	["Broadcast"] = "广播",
	["Toggle broadcasting the messages to the raidwarning channel."] = "显示使用团队警告(RW)频道广播的消息。",

	["Gives timer bars and raid messages about common buffs and debuffs."] = "对通常的Buff和Debuff使用计时条并且发送团队信息。",
	["Common Auras"] = "普通光环",
	["commonauras"] = "普通光环",
} end )


L:RegisterTranslations("koKR", function() return {
	fw_cast = "%s님이 %s에게 공포의 수호물을 시전합니다.", --"%s|1이;가; %s에게 공포의 수호물을 시전합니다.",
	fw_bar = "%s: 공수 재사용 대기시간",

	md_cast = "%s: %s님에게 눈속임",
	md_bar = "%s: 눈속임 재사용 대기시간",

	used_cast = "%s님이 %s 사용했습니다.", --"%s|1이;가; %s|1을;를; 사용했습니다.",
	used_bar = "%s: %s",

	portal_cast = "%s님이 %s 차원문을 엽니다!", --"%s|1이;가; %s|1으로;로; 가는 차원문을 엽니다!",
	portal_regexp = ".*: (.*)",
	-- portal_bar is the spellname

	["Toggle %s display."] = "%s 표시를 전환합니다.",
	["Portal"] = "차원문",
	
	["Broadcast"] = "알림",
	["Toggle broadcasting the messages to the raidwarning channel."] = "공격대 경보 채널에 메세지 알림을 전환합니다.",

	["Gives timer bars and raid messages about common buffs and debuffs."] = "공통 버프와 디버프에 대한 공격대 메세지와 타이머 바를 제공합니다.",
	["Common Auras"] = "공통 버프",
} end )

L:RegisterTranslations("deDE", function() return {
	fw_cast = "%s sch\195\188tzt %s vor Furcht.",
	fw_bar = "%s: FS Cooldown",

	used_cast = "%s benutzt %s.",

	portal_cast = "%s \195\182ffnet ein Portal nach %s!",
	-- portal_bar is the spellname

	["Toggle %s display."] = "Aktiviert oder Deaktiviert die Anzeige von %s.",
	["Portal"] = "Portale",
	["broadcast"] = "broadcasten",
	["Broadcast"] = "Broadcast",
	["Toggle broadcasting the messages to the raidwarning channel."] = "W\195\164hle, ob Warnungen \195\188ber RaidWarning gesendet werden sollen.",

	["Gives timer bars and raid messages about common buffs and debuffs."] = "Zeigt Zeitleisten und Raidnachrichten f? kritische Spr\195\188che.",
} end )

L:RegisterTranslations("frFR", function() return {
	fw_cast = "%s a protégé contre la peur %s.",
	fw_bar = "%s : Cooldown Gardien",

	md_cast = "%s : Redirection sur %s.",
	md_bar = "%s : Cooldown Redirection",

	used_cast = "%s a utilisé %s.",
	used_bar = "%s : %s",

	portal_cast = "%s a ouvert un portail pour %s !",
	portal_regexp = ".* : (.*)",
	-- portal_bar is the spellname

	["Toggle %s display."] = "Préviens ou non quand la capacité %s est utilisée.",
	["Portal"] = "Portail",
	--["broadcast"] = true,
	["Broadcast"] = "Diffuser",
	["Toggle broadcasting the messages to the raidwarning channel."] = "Diffuse ou non les messages sur le canal Avertissement raid.",

	["Gives timer bars and raid messages about common buffs and debuffs."] = "Affiche des barres temporelles et des messages raid concernant les buffs & débuffs courants.",
	["Common Auras"] = "Auras courantes",
	--["commonauras"] = true,
} end )

------------------------------
--      Module              --
------------------------------

local mod = BigWigs:NewModule(name)
mod.synctoken = name
mod.defaultDB = {
	fearward = true,
	shieldwall = true,
	challengingshout = true,
	challengingroar = true,
	portal = true,
	misdirection = true,
	broadcast = false,
}

mod.consoleCmd = L["commonauras"]
mod.consoleOptions = {
	type = "group",
	name = L["Common Auras"],
	desc = L["Gives timer bars and raid messages about common buffs and debuffs."],
	pass = true,
	get = function(key) return mod.db.profile[key] end,
	set = function(key, value) mod.db.profile[key] = value end,
	args = {
		fearward = {
			type = "toggle",
			name = fear_ward,
			desc = L["Toggle %s display."]:format(fear_ward),
		},
		shieldwall = {
			type = "toggle",
			name = shield_wall,
			desc = L["Toggle %s display."]:format(shield_wall),
		},
		challengingshout = {
			type = "toggle",
			name = challenging_shout,
			desc = L["Toggle %s display."]:format(challenging_shout),
		},
		challengingroar = {
			type = "toggle",
			name = challenging_roar,
			desc = L["Toggle %s display."]:format(challenging_roar),
		},
		portal = {
			type = "toggle",
			name = L["Portal"],
			desc = L["Toggle %s display."]:format(L["Portal"]),
		},
		misdirection = {
			type = "toggle",
			name = misdirection,
			desc = L["Toggle %s display."]:format(misdirection),
		},
		broadcast = {
			type = "toggle",
			name = L["Broadcast"],
			desc = L["Toggle broadcasting the messages to the raidwarning channel."],
			order = -1,
		},
	}
}
mod.revision = tonumber(("$Revision$"):sub(12, -3))
mod.external = true

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	local class = select(2, UnitClass("player"))

	self:AddCombatListener("SPELL_CAST_SUCCESS", "Shout", 1161) --Challenging Shout
	self:AddCombatListener("SPELL_CAST_SUCCESS", "Roar", 5209) --Challenging Roar
	self:AddCombatListener("SPELL_CAST_SUCCESS", "FearWard", 6346) --Fear Ward
	self:AddCombatListener("SPELL_CAST_SUCCESS", "Misdirection", 34477) --Misdirection
	self:AddCombatListener("SPELL_CAST_SUCCESS", "Portals", 11419, 32266, 11416, 11417, 33691, 35717, 32267, 10059, 11420, 11425) --Portals

	if class == "WARRIOR" then
		local rank = select(5, GetTalentInfo(3 , 13))
		shieldWallDuration = 10
		if rank == 2 then
			shieldWallDuration = shieldWallDuration + 5
		elseif rank == 1 then
			shieldWallDuration = shieldWallDuration + 3
		end
		rank = select(5, GetTalentInfo(1 , 18))
		shieldWallDuration = shieldWallDuration + (rank * 2)
		self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	end

	self:RegisterEvent("BigWigs_RecvSync")
	self:Throttle(0.4, "BWCASW")
end

------------------------------
--      Events              --
------------------------------

local green = {r = 0, g = 1, b = 0}
local blue = {r = 0, g = 0, b = 1}
local orange = {r = 1, g = 0.75, b = 0.14}
local yellow = {r = 1, g = 1, b = 0}

function mod:Shout(_, spellID, nick, _, spellName)
	if (UnitInRaid(nick) or UnitInParty(nick)) and self.db.profile.challengingshout then
		self:Message(L["used_cast"]:format(nick, spellName), orange, not self.db.profile.broadcast, nil, nil, spellID)
		self:Bar(L["used_bar"]:format(nick, spellName), 6, spellID, true, 1, 0.75, 0.14)
	end
end

function mod:Roar(_, spellID, nick, _, spellName)
	if (UnitInRaid(nick) or UnitInParty(nick)) and self.db.profile.challengingroar then
		self:Message(L["used_cast"]:format(nick, spellName), orange, not self.db.profile.broadcast, nil, nil, spellID)
		self:Bar(L["used_bar"]:format(nick, spellName), 6, spellID, true, 1, 0.75, 0.14)
	end
end

function mod:FearWard(target, spellID, nick, _, spellName)
	if (UnitInRaid(nick) or UnitInParty(nick)) and self.db.profile.fearward then
		self:Message(L["fw_cast"]:format(nick, target), green, not self.db.profile.broadcast, nil, nil, spellID)
		self:Bar(L["fw_bar"]:format(nick), 180, spellID, true, 0, 1, 0)
	end
end

function mod:Misdirection(target, spellID, nick, _, spellName)
	if (UnitInRaid(nick) or UnitInParty(nick)) and self.db.profile.misdirection then
		self:Message(L["md_cast"]:format(nick, target), yellow, not self.db.profile.broadcast, nil, nil, spellID)
		self:Bar(L["md_bar"]:format(nick), 120, spellID, true, 1, 1, 0)
	end
end

function mod:Portals(_, spellID, source)
	if (UnitInRaid(nick) or UnitInParty(nick)) and self.db.profile.portal then
		local dest = GetSpellInfo(spellID)
		local zone = select(3, dest:find(L["portal_regexp"]))
		if zone then
			self:Message(L["portal_cast"]:format(nick, zone), blue, not self.db.profile.broadcast, false)
			self:Bar(rest, 60, rest, true, 0, 0, 1)
		end
	end
end

function mod:BigWigs_RecvSync(sync, rest, nick)
	if sync == "BWCASW" and self.db.profile.shieldwall then
		local swTime = tonumber(rest)
		if not swTime then swTime = 10 end -- If the tank uses an old BWCA, just assume 10 seconds.
		local spell = shield_wall
		self:Message(L["used_cast"]:format(nick,  spell), blue, not self.db.profile.broadcast, false)
		self:Bar(L["used_bar"]:format(nick, spell), swTime, 871, true, 0, 0, 1)
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(sPlayer, sName, sRank)
	if UnitIsUnit(sPlayer, "player") and sName == shield_wall then
		self:Sync("BWCASW "..shieldWallDuration)
	end
end

