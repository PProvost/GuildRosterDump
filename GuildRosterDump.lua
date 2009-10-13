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

local delim = ","
local rosterData 

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

table.insert(UISpecialFrames, "GuildInfoDumpFrame")
f:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("GUILD_ROSTER_UPDATE")

f:SetScript("OnShow", function()
	local csvData = strjoin(delim,"Name","Rank","Level","Class","Zone","Note","OfficerNote","LastOnline","Status") .. "\n"
	for i = 1,#rosterData do csvData = csvData .. rosterData[i] .. "\n" end
	scrollEdit:SetText(csvData)
end)

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
function f:GUILD_ROSTER_UPDATE()
	local name, rank, rankIndex, level, class, zone, note, officernote, online, status
	local years, months, days, hours
	local lastOnline

	--csvData = "Name","Rank","Level","Class","Zone","Note","OfficerNote","LastOnline","Status"
	rosterData = {}
	for index = 1,GetNumGuildMembers(true) do
		name, rank, rankIndex, level, class, zone, note, officernote, online, status = GetGuildRosterInfo(index)
		years, months, days, hours = GetGuildRosterLastOnline(index)

		if not online then
			lastOnline = ""
			if years then lastOnline = lastOnline .. string.format("%d years ", years) end
			if months then lastOnline = lastOnline .. string.format("%d months ", months) end
			if days then lastOnline = lastOnline .. string.format("%d days ", days) end
			if hours then lastOnline = lastOnline .. string.format("%d hours ", hours) end
		else
			lastOnline = "Now"
		end

		table.insert(rosterData, strjoin(delim, name,rank,level,class,zone,note,(officernote or ""),lastOnline,status))
	end
end

-- Slash command to force the scan
SLASH_GUILDINFODUMP1 = "/gdump"
SlashCmdList.GUILDINFODUMP = function(msg)
	GuildRoster()
	f:Show()
end

