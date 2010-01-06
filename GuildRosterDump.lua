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

local delim = ";"
local rosterData 

local function Print(...) print("|cFF33FF99GuildRosterDump|r:", ...) end
local debugf = tekDebug and tekDebug:GetFrame("GuildRosterDump")
local function Debug(...) if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end end

-- Setup the main frame
local f = CreateFrame("frame", "GuildRosterDumpFrame", UIParent)

f:SetBackdrop({
	bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
	tile = true, tileSize = 16, edgeSize = 16, 
	insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
f:SetBackdropColor(0,0,0,1)
f:SetHeight(350)
f:SetWidth(500)
f:SetPoint("CENTER", UIParent, "CENTER")
f:SetMovable(true)
f:EnableMouse(true)
f:SetFrameStrata("DIALOG")
f:SetScript("OnMouseDown", function(self) self:StartMoving() end)
f:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() end)

local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
closeBtn:SetWidth(32); closeBtn:SetHeight(32);
closeBtn:SetPoint("TOPRIGHT", -2, -2)
closeBtn:SetScript("OnClick", function(self) f:Hide() end)

local scrollEdit = LibStub("QScrollingEditBox"):New("GuildRosterDumpEditBox", f)
scrollEdit:SetPoint("TOPLEFT", 4, -40)
scrollEdit:SetPoint("BOTTOMRIGHT", -30, 8)
f:Hide()

local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 8, -8)
title:SetText("GuildRosterDump")

local description = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
description:SetPoint("TOPLEFT", title, "BOTTOMLEFT")
description:SetPoint("BOTTOMRIGHT", scrollEdit, "TOPRIGHT")
description:SetJustifyH("LEFT"); description:SetJustifyV("TOP")
description:SetText("Copy the following text to the clipboard and paste it into your external program (e.g. Excel).")

table.insert(UISpecialFrames, "GuildRosterDumpFrame")
f:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("GUILD_ROSTER_UPDATE")

f:SetScript("OnShow", function()
	local csvData = strjoin(delim,"Name","Rank","RankIndex","Level","Class","Zone","Note","OfficerNote","LastOnline","Status") .. "\n"
	for i = 1,#rosterData do csvData = csvData .. rosterData[i] .. "\n" end
	scrollEdit:SetText(csvData)
end)

function f:ADDON_LOADED(event, addon)
	if addon:lower() ~= "guildrosterdump" then return end
	LibStub("tekKonfig-AboutPanel").new(nil, "GuildRosterDump") -- Make first arg nil if no parent config panel
	self:UnregisterEvent("ADDON_LOADED"); self.ADDON_LOADED = nil
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
			if months then lastOnline = lastOnline .. string.format("%02d months ", months) end
			if days then lastOnline = lastOnline .. string.format("%02d days ", days) end
			if hours then lastOnline = lastOnline .. string.format("%02d hours ", hours) end
		else
			lastOnline = "Now"
		end

		table.insert(rosterData, strjoin(delim, name or "", rank or "", rankIndex or 99, level or 0, class or "", zone or "", note or "", officernote or "", lastOnline, status or ""))
	end
end

-- Slash command to force the scan
SLASH_GUILDROSTERDUMP1 = "/gdump"
SlashCmdList.GUILDROSTERDUMP = function(msg)
	GuildRoster()
	f:Show()
end

