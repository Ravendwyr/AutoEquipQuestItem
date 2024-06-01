
local isClassic = select(4, GetBuildInfo()) <= 100200

local GetContainerNumSlots = C_Container.GetContainerNumSlots
local GetContainerItemLink = C_Container.GetContainerItemLink
local PickupContainerItem  = C_Container.PickupContainerItem
local IsEquippableItem     = C_Item.IsEquippableItem
local GetItemInfo          = C_Item.GetItemInfo


local AEQI = CreateFrame("Button", nil, QuestFrameRewardPanel, "UIPanelButtonTemplate")

local itemsToEquip = {}
local function addAllRewardsToQueue()
	for i=1, GetNumQuestRewards() do
		if select(5, GetQuestItemInfo("reward", i)) and IsEquippableItem(GetQuestItemLink("reward", i)) then
			itemsToEquip[tonumber(GetQuestItemLink("reward", i):match("item:(%d+)"))] = true
		end
	end
end


local COMPLETE_AND_EQUIP = "Complete Quest & Equip Item"
local COMPLETE_AND_EQUIP_SELECTED = "Complete & Equip Selected Item"
local COMPLETE_AND_EQUIP_ALL = "Complete & Equip All Items"
local COMPLETE_AND_GET_HIGHEST = "Complete & Get Highest Value"


AEQI:SetPoint("LEFT", QuestFrameCompleteQuestButton, "RIGHT", 5, 0)
AEQI:SetPoint("TOP", QuestFrameCompleteQuestButton, "TOP")
AEQI:SetWidth(200)
AEQI:SetText(COMPLETE_AND_EQUIP)
AEQI:SetScript("OnClick", function(self, ...)
	self:RegisterEvent("BAG_UPDATE")

	if QuestInfoFrame.itemChoice > 0 and select(5, GetQuestItemInfo("choice", QuestInfoFrame.itemChoice)) and IsEquippableItem(GetQuestItemLink("choice", QuestInfoFrame.itemChoice)) then
		itemsToEquip[tonumber(GetQuestItemLink("choice", QuestInfoFrame.itemChoice):match("item:(%d+)"))] = true

		if IsShiftKeyDown() then
			addAllRewardsToQueue()
		end
	elseif GetNumQuestChoices() > 1 then
		local slot, val = 0, 0

		for i=1, GetNumQuestChoices() do
			local _, _, _, _, _, _, _, _, _, _, tempVal = GetItemInfo(GetQuestItemLink("choice", i))

			if tempVal > val then
				slot = i
				val = tempVal
			end
		end

		QuestInfoFrame.itemChoice = slot ~= 0 and slot or 1

	elseif GetNumQuestChoices() == 1 then
		itemsToEquip[tonumber(GetQuestItemLink("choice", 1):match("item:(%d+)"))] = true
	else
		addAllRewardsToQueue()
	end

	QuestRewardCompleteButton_OnClick()
end)


local orig_QuestInfoItem_OnClick = QuestInfoItem_OnClick
function QuestInfoItem_OnClick(self, ...)
	orig_QuestInfoItem_OnClick(self, ...)

	if self.type == "choice" then
		if QuestInfoFrame.itemChoice > 0 and select(5, GetQuestItemInfo("choice", QuestInfoFrame.itemChoice)) and IsEquippableItem(GetQuestItemLink("choice", QuestInfoFrame.itemChoice)) then
			AEQI:Show()
			AEQI:SetText(COMPLETE_AND_EQUIP_SELECTED)
--		elseif QuestInfoFrame.itemChoice > 0 then
--			AEQI:Hide()
		else
			AEQI:QUEST_COMPLETE()
		end
	end
end


-- Event Functions
function AEQI:QUEST_COMPLETE()
	local numChoices = GetNumQuestChoices()
	local numRewards = GetNumQuestRewards()

--	print("GetNumQuestRewards():", numRewards, ", GetNumQuestChoices():", numChoices)

	self:Hide()
	if isClassic then QuestFrameCancelButton:Show() end

	if numChoices == 0 and numRewards == 0 then return end -- nothing of value, bail out

	-- pre-5.0 "choose your reward" quest
	if numChoices > 1 then
		self:SetText(COMPLETE_AND_GET_HIGHEST)
		self:Show()
		if isClassic then QuestFrameCancelButton:Hide() end

	-- post-5.0 "dynamic reward" quest
	elseif numChoices == 1 then
		if select(5, GetQuestItemInfo("choice", 1)) and IsEquippableItem(GetQuestItemLink("choice", 1)) then
			self:SetText(COMPLETE_AND_EQUIP)
			self:Show()
			if isClassic then QuestFrameCancelButton:Hide() end
		end

	-- rather rare "multiple guaranteed rewards" quest
	elseif numRewards > 0 then
		for i = 1, numRewards do
			if select(5, GetQuestItemInfo("reward", i)) and IsEquippableItem(GetQuestItemLink("reward", i)) then
				self:SetText(COMPLETE_AND_EQUIP)
				self:Show()
				if isClassic then QuestFrameCancelButton:Hide() end

				break
			end
		end
	end
end

function AEQI:PLAYER_REGEN_ENABLED()
	local equipped = false

	for bagID = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bagID) do
			local link = GetContainerItemLink(bagID, slot) or ""
			local itemID = tonumber(link:match("item:(%d+)"))

			if itemID and itemsToEquip[itemID] then
				PickupContainerItem(bagID, slot)
				PickupInventoryItem(1)

				itemsToEquip[itemID] = nil
			end

			if not next(itemsToEquip) then
				self:UnregisterEvent("BAG_UPDATE") -- just in case combat ends right as the bags update
				equipped = true

				break
			end
		end

		if equipped then
			break
		end
	end

	ClearCursor()

	self:UnregisterEvent("PLAYER_REGEN_ENABLED") -- don't need it until next time
end

function AEQI:BAG_UPDATE()
	if InCombatLockdown() then self:RegisterEvent("PLAYER_REGEN_ENABLED")
	else self:PLAYER_REGEN_ENABLED() end
end

function AEQI:MODIFIER_STATE_CHANGED()
	if not self:IsVisible() then return end

	if IsShiftKeyDown() then
		if QuestInfoFrame.itemChoice > 0 and select(5, GetQuestItemInfo("choice", QuestInfoFrame.itemChoice)) and IsEquippableItem(GetQuestItemLink("choice", QuestInfoFrame.itemChoice)) then
			for i=1, GetNumQuestRewards() do
				if select(5, GetQuestItemInfo("reward", i)) then
					self:SetText(COMPLETE_AND_EQUIP_ALL)
					break
				end
			end
		end
	else
		if QuestInfoFrame.itemChoice > 0 and select(5, GetQuestItemInfo("choice", QuestInfoFrame.itemChoice)) and IsEquippableItem(GetQuestItemLink("choice", QuestInfoFrame.itemChoice)) then
			self:SetText(COMPLETE_AND_EQUIP_SELECTED)
		else
			self:SetText(COMPLETE_AND_GET_HIGHEST)
		end
	end
end


AEQI:RegisterEvent("QUEST_COMPLETE")
AEQI:RegisterEvent("MODIFIER_STATE_CHANGED")
AEQI:SetScript("OnEvent", function(self, event, ...)
	if self[event] then self[event](self, event, ...) end
end)
