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

local function Print(...) print("|cFF33FF99GuildInfoDump|r:", ...) end
local debugf = tekDebug and tekDebug:GetFrame("GuildInfoDump")
local function Debug(...) if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end end

-- Setup the main frame
local f = CreateFrame("frame", "GuildInfoDumpFrame", UIParent)

f:SetBackdrop( {
	bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
	tile = true, tileSize = 16, edgeSize = 16, 
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
f:SetBackdropColor(0,0,0,1)
f:SetHeight(300)
f:SetWidth(500)
f:SetPoint("CENTER", UIParent, "CENTER")
local scrollEdit = LibStub("QScrollingEditBox"):New("GuildInfoDumpEditBox", f)
scrollEdit:SetPoint("TOPLEFT", 5, -5)
scrollEdit:SetPoint("BOTTOMRIGHT", -5, 5)
f:Hide()

f:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("GUILD_ROSTER_UPDATE")

table.insert(UISpecialFrames, "GuildInfoDumpFrame")

function f:ADDON_LOADED(event, addon)
	if addon:lower() ~= "guildinfodump" then return end
	LibStub("tekKonfig-AboutPanel").new(nil, "GuildInfoDump") -- Make first arg nil if no parent config panel
	self:UnregisterEvent("ADDON_LOADED"); self.ADDON_LOADED = nil
	if IsLoggedIn() then self:PLAYER_LOGIN() else self:RegisterEvent("PLAYER_LOGIN") end
end

function f:PLAYER_LOGIN()
	self:UnregisterEvent("PLAYER_LOGIN"); self.PLAYER_LOGIN = nil
end

-- We've got data!
local csvData
function f:GUILD_ROSTER_UPDATE()
	if not f:IsShown() then return end

	local name, rank, rankIndex, level, class, zone, note, officernote, online, status
	local years, months, days, hours
	local lastOnline

	csvData = "Name,Rank,Level,Class,Zone,Note,OfficerNote,LastOnline,Status\n"

	for index = 1,GetNumGuildMembers(true) do
		name, rank, rankIndex, level, class, zone, note, officernote, online, status = GetGuildRosterInfo(index)
		years, months, days, hours = GetGuildRosterLastOnline(index)

		if not online then
			lastOnline = string.format("%d years %d months %d days %d hours", years, months, days, hours)
		else
			lastOnline = "Now"
		end

		csvData = csvData .. string.format("%s,%s,%s,%s,%s,%s,%s,%s,%s\n", name, rank, level, class, zone, note, officernote or "", lastOnline, status)
	end

	scrollEdit:SetText(csvData)
	csvData = ""
end

-- Slash command to force the scan
SLASH_GUILDINFODUMP1 = "/gdump"
SlashCmdList.GUILDINFODUMP = function(msg)
	f:Show()
	GuildRoster()
end

