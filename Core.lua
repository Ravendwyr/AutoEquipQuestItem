local _, AEQI = ...

--_G['AEQI'] = AEQI --debug code
AEQI.eventframe = CreateFrame('frame')
AEQI.eventframe:SetScript("OnEvent", function(self, event, ...) if AEQI[event] then return AEQI[event](AEQI, event, ...) end end)
function AEQI:RegisterEvent(...) return AEQI.eventframe:RegisterEvent(...) end
function AEQI:UnregisterEvent(...) return AEQI.eventframe:UnregisterEvent(...) end

AEQI:RegisterEvent("QUEST_COMPLETE")

AEQI.itemequip = ""

local button = AEQI:GetWidget("button", QuestFrameRewardPanel)
	button:SetPoint("LEFT", QuestFrameCompleteQuestButton, "RIGHT", 5, 0)
	button:SetPoint("TOP", QuestFrameCompleteQuestButton, "TOP")
	button:SetWidth(200)
	button:SetText("Complete Quest & Equip Item")
	button:SetScript("OnClick", function(...)
		AEQI.itemequip = tonumber(GetQuestItemLink("choice", QuestInfoFrame.itemChoice):match("item:(%d+)"))
		QuestRewardCompleteButton_OnClick()
		AEQI:RegisterEvent("BAG_UPDATE")
	end)
	
function AEQI:QUEST_COMPLETE()
	button:Hide()
end

function AEQI:BestSlot(bagID,slot)
	local invSlot, invLevel
	PickupContainerItem(bagID, slot)
	for i=0,23 do
		if CursorCanGoInSlot(i) then
			local level = GetInventoryItemLink("player", i) and select(4, GetItemInfo(GetInventoryItemLink("player", i))) or 0
			if (not invSlot or invLevel > level) then
				invSlot = i
				invLevel = level
			end
		end
	end
	ClearCursor()
	return invSlot
end

function AEQI:BAG_UPDATE()
	if not InCombatLockdown() then
		local equiped
		for bagID=0, NUM_BAG_SLOTS do
			for slot=1, GetContainerNumSlots(bagID) do
				local link = GetContainerItemLink(bagID, slot) or ""
				if link and (AEQI.itemequip == tonumber(link:match("item:(%d+)"))) then
					local invSlot = self:BestSlot(bagID,slot)
					PickupContainerItem(bagID, slot)
					PickupInventoryItem(invSlot)
					AEQI.itemequip = ""
					self:UnregisterEvent("BAG_UPDATE")
					break
				end
			end
			if equiped then
				break
			end
		end
		ClearCursor()
	else
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
	end
end

function AEQI:PLAYER_REGEN_ENABLED()
	local equiped
	for bagID=0, NUM_BAG_SLOTS do
		for slot=1, GetContainerNumSlots(bagID) do
			if itemequip == GetContainerItemLink(bagID, slot):match("item:(%d+)") then
				local invSlot = self:BestSlot(bagID,slot)
				PickupContainerItem(bagID, slot)
				PickupInventoryItem(invSlot)
				itemequip = ""
				self:UnregisterEvent("BAG_UPDATE") -- just in case a borderline case happens when combat ends right as the bags update
				equiped = true
				break
			end
		end
		if equiped then
			break
		end
	end
	ClearCursor()
	self:UnregisterEvent("PLAYER_REGEN_ENABLED") -- only run this once
end

local QuestInfoItem_OnClick_old = QuestInfoItem_OnClick
function QuestInfoItem_OnClick(self, ...)
	QuestInfoItem_OnClick_old(self, ...)
	if ( self.type == "choice" ) then
		if QuestInfoFrame.itemChoice > 0 and select(5, GetQuestItemInfo("choice", QuestInfoFrame.itemChoice)) then
			button:Show()
		else
			button:Hide()
		end
	end
end
