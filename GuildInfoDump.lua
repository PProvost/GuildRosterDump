--[[
Copyright 2009 Quaiche of Dragonblight

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
]]

local FREQUENCY = 5 * 60 -- 5 mins
local defaults, db = {}

local function Print(...) print("|cFF33FF99GuildInfoDump|r:", ...) end
local debugf = tekDebug and tekDebug:GetFrame("GuildInfoDump")
local function Debug(...) if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end end

local f = CreateFrame("frame")
f:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("GUILD_ROSTER_UPDATE")

function f:ADDON_LOADED(event, addon)
	if addon:lower() ~= "guildinfodump" then return end
	GuildInfoDumpDB = setmetatable(GuildInfoDumpDB or {}, {__index = defaults})
	db = GuildInfoDumpDB
	LibStub("tekKonfig-AboutPanel").new(nil, "GuildInfoDump") -- Make first arg nil if no parent config panel
	self:UnregisterEvent("ADDON_LOADED"); self.ADDON_LOADED = nil
	if IsLoggedIn() then self:PLAYER_LOGIN() else self:RegisterEvent("PLAYER_LOGIN") end
end

function f:PLAYER_LOGIN()
	GuildRoster()
	self:UnregisterEvent("PLAYER_LOGIN"); self.PLAYER_LOGIN = nil
end

-- We've got data!
function f:GUILD_ROSTER_UPDATE()
	local guildName, guildRankName, guildRankIndex = GetGuildInfo("player")
	db.GuildInfo = {
		Name = select(1, GetGuildInfo("player")),
		GuildInfo = GetGuildInfoText(),
		MOTD = GetGuildRosterMOTD(),
	}

	local name, rank, rankIndex, level, class, zone, note, officernote, online, status
	local years, months, days, hours

	db.Roster = {}
	for index = 1,GetNumGuildMembers(true) do
		name, rank, rankIndex, level, class, zone, note, officernote, online, status = GetGuildRosterInfo(index)
		years, months, days, hours = GetGuildRosterLastOnline(index)

		local lastOnline = "Now"
		if not online then
			lastOnline = string.format("%d years, %d months, %d days, %d hours", years, months, days, hours)
		end

		db.Roster[name] = {
			Rank = rank,
			Level = level,
			Class = class,
			Zone = zone,
			Note = note,
			OfficerNote = officernote,
			LastOnline = lastOnline,
			Status = status
		}
	end
end

-- Mini-timer to rescan periodically
--[[
local total = 0
local function OnUpdate(self, elapsed)
	total = total + elapsed
	if total >= FREQUENCY then
		GuildRoster()
	end
end
f:SetScript("OnUpdate", onUpdate)
]]

-- Slash command to force the scan
SLASH_ADDONTEMPLATE1 = "/gdump"
SlashCmdList.ADDONTEMPLATE = function(msg)
	GuildRoster()
end

