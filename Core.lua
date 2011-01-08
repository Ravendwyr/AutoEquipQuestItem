local _, AEQI = ...

_G['AEQI'] = AEQI
AEQI.eventframe = CreateFrame('frame')
AEQI.eventframe:SetScript("OnEvent", function(self, event, ...) if AEQI[event] then return AEQI[event](AEQI, event, ...) end end)
function AEQI:RegisterEvent(...) return AEQI.eventframe:RegisterEvent(...) end
function AEQI:UnregisterEvent(...) return AEQI.eventframe:UnregisterEvent(...) end

AEQI:RegisterEvent("QUEST_COMPLETE")

local itemequip = ""

local button = AEQI:GetWidget("button", QuestFrameRewardPanel)
	button:SetPoint("LEFT", QuestFrameCompleteQuestButton, "RIGHT", 5, 0)
	button:SetPoint("TOP", QuestFrameCompleteQuestButton, "TOP")
	button:SetWidth(200)
	button:SetText("Complete Quest & Equip Item")
	button:SetScript("OnClick", function(...)
		itemequip = GetQuestItemLink("choice", QuestInfoFrame.itemChoice)
		QuestRewardCompleteButton_OnClick()
		AEQI:RegisterEvent("BAG_UPDATE")
	end)
	
function AEQI:QUEST_COMPLETE()
	button:Hide()
	--print("button Hide")
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
	local equiped
	for bagID=0, NUM_BAG_SLOTS do
		for slot=1, GetContainerNumSlots(bagID) do
			if itemequip == GetContainerItemLink(bagID, slot) then
				local invSlot = self:BestSlot(bagID,slot)
				PickupContainerItem(bagID, slot)
				if not InCombatLockdown then
					EquipCursorItem(invSlot)
					itemequip = ""
				else
					self:RegisterEvent("PLAYER_REGEN_ENABLED")
				end
				self:UnregisterEvent("BAG_UPDATE")
				break
			end
		end
		if equiped then
			break
		end
	end
	ClearCursor()
end

function AEQI:PLAYER_REGEN_ENABLED()
	local equiped
	for bagID=0, NUM_BAG_SLOTS do
		for slot=1, GetContainerNumSlots(bagID) do
			if itemequip == GetContainerItemLink(bagID, slot) then
				local invSlot = self:BestSlot(bagID,slot)
				PickupContainerItem(bagID, slot)
				EquipCursorItem(invSlot)
				itemequip = ""
				self:UnregisterEvent("PLAYER_REGEN_ENABLED")
				equiped = true
				break
			end
		end
		if equiped then
			break
		end
	end
	ClearCursor()
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

