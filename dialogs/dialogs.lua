----------------------------------------------------------------------------------
--  Storyline
--  Dialogs API
--	---------------------------------------------------------------------------
--	Copyright 2016 Morgane "Ellypse" Parize <ellypse@totalrp3.info> @EllypseCelwe
--
--	Licensed under the Apache License, Version 2.0 (the "License");
--	you may not use this file except in compliance with the License.
--	You may obtain a copy of the License at
--
--		http://www.apache.org/licenses/LICENSE-2.0
--
--	Unless required by applicable law or agreed to in writing, software
--	distributed under the License is distributed on an "AS IS" BASIS,
--	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--	See the License for the specific language governing permissions and
--	limitations under the License.
----------------------------------------------------------------------------------

---------------------------------------------
--- Dialog choices
---------------------------------------------

Storyline_API.dialogs = {};
local API = Storyline_API.dialogs;

local BUCKET_TYPE = {
	COMPLETED_QUEST   = 1,
	AVAILABLE_QUEST   = 2,
	GOSSIP            = 3,
	UNCOMPLETED_QUEST = 4
}
API.BUCKET_TYPE = BUCKET_TYPE;

local EVENT_TYPES = {
	GOSSIP_SHOW = "GOSSIP_SHOW",
	QUEST_GREETING = "QUEST_GREETING"
}
API.EVENT_TYPES = EVENT_TYPES;

local function getGossipChoices()
	local gossipChoices = {};

	for i, optionInfo in ipairs(C_GossipInfo.GetOptions()) do
		gossipChoices[i] = {
			title      = optionInfo.name,
			gossipType = optionInfo.type
		};
	end
	return gossipChoices;
end

local function getGossipAvailableQuestsChoices()
	local availableQuestsChoices = {};

	for i, questInfo in ipairs( C_GossipInfo.GetAvailableQuests()) do
		availableQuestsChoices[i] = {
			title        = questInfo.title,
			lvl          = questInfo.questLevel,
			isTrivial    = questInfo.isTrivial,
			frequency    = questInfo.frequency,
			isRepeatable = questInfo.repeatable,
			isLegendary  = questInfo.isLegendary,
			isIgnored    = questInfo.isIgnored
		};
	end
	return availableQuestsChoices;
end

local function getGossipActiveQuestsChoices()
	-- We will have two buckets: one for the completed quests and one for the non completed ones
	local activeCompletedQuestsChoices = {};
	local activeUncompletedQuestsChoices = {};

	for i, questInfo in ipairs( C_GossipInfo.GetActiveQuests()) do
		local questData = {
			title        = questInfo.title,
			lvl          = questInfo.questLevel,
			isTrivial    = questInfo.isTrivial,
			isCompleted  = questInfo.isComplete,
			isLegendary  = questInfo.isLegendary,
			isIgnored    = questInfo.isIgnored
		};
		-- Place the choice in the appropriate bucket
		if  questData.isCompleted then
			activeCompletedQuestsChoices[i] = questData;
		else
			activeUncompletedQuestsChoices[i] = questData;
		end
	end

	return activeCompletedQuestsChoices, activeUncompletedQuestsChoices;
end

local function getAvailableQuestsChoices()
	local numberOfAvailableQuests = GetNumAvailableQuests();

	local availableQuestsChoices = {};

	for i = 1, numberOfAvailableQuests do
		local title = GetAvailableTitle(i);
		local isTrivial, frequency, isRepeatable, isLegendary, isIgnored = GetAvailableQuestInfo(i);
		availableQuestsChoices[i] = {
			title        = title,
			isTrivial    = isTrivial,
			frequency    = frequency,
			isRepeatable = isRepeatable,
			isLegendary  = isLegendary,
			isIgnored    = isIgnored
		};
	end
	return availableQuestsChoices;
end

local function getActiveQuestsChoices()

	local numberOfActiveQuests = GetNumActiveQuests();

	-- We will have two buckets: one for the completed quests and one for the non completed ones
	local activeCompletedQuestsChoices = {};
	local activeUncompletedQuestsChoices = {};

	for i = 1, numberOfActiveQuests do
		local title, isComplete = GetActiveTitle(i);
		local isTrivial, frequency, isRepeatable, isLegendary = GetAvailableQuestInfo(i);
		local questData = {
			title        = title,
			isTrivial    = isTrivial,
			isCompleted  = isComplete,
			isRepeatable = isRepeatable,
			isIgnored    = isLegendary
		};
		-- Place the choice in the appropriate bucket
		if  questData.isCompleted then
			activeCompletedQuestsChoices[i] = questData;
		else
			activeUncompletedQuestsChoices[i] = questData;
		end
	end

	return activeCompletedQuestsChoices, activeUncompletedQuestsChoices;
end

function API.getChoices(eventType)
	local choices = {};

	if eventType == EVENT_TYPES.GOSSIP_SHOW then
		choices[BUCKET_TYPE.COMPLETED_QUEST], choices[BUCKET_TYPE.UNCOMPLETED_QUEST] = getGossipActiveQuestsChoices();
		choices[BUCKET_TYPE.AVAILABLE_QUEST] = getGossipAvailableQuestsChoices();
		choices[BUCKET_TYPE.GOSSIP] = getGossipChoices()
	elseif eventType == EVENT_TYPES.QUEST_GREETING then
		choices[BUCKET_TYPE.COMPLETED_QUEST], choices[BUCKET_TYPE.UNCOMPLETED_QUEST] = getActiveQuestsChoices();
		choices[BUCKET_TYPE.AVAILABLE_QUEST] = getAvailableQuestsChoices();
	end

	return choices;
end

--- Returns the first dialog choice for the given event type
-- @param eventType The name of the event to use to retrieve data (GOSSIP_SHOW, QUEST_GREETING)
--
function API.getFirstChoice(eventType)
	local firstChoice, bucketType, index;
	local dialogChoices = API.getChoices(eventType);
	for _, choicesBag in pairs(dialogChoices) do
		bucketType = _;
		for _, choice in pairs(choicesBag) do
			index = _;
			firstChoice = choice;
			break
		end
		if firstChoice then break end
	end
	return firstChoice, bucketType, index;
end

local DIALOG_CHOICES_SELECTORS = {
	[API.EVENT_TYPES.GOSSIP_SHOW] = {
		[API.BUCKET_TYPE.AVAILABLE_QUEST]   = C_GossipInfo.SelectAvailableQuest,
		[API.BUCKET_TYPE.COMPLETED_QUEST]   = C_GossipInfo.SelectActiveQuest,
		[API.BUCKET_TYPE.UNCOMPLETED_QUEST] = C_GossipInfo.SelectActiveQuest,
		[API.BUCKET_TYPE.GOSSIP]            = C_GossipInfo.SelectOption,
	},
	[API.EVENT_TYPES.QUEST_GREETING] = {
		[API.BUCKET_TYPE.AVAILABLE_QUEST]   = SelectAvailableQuest,
		[API.BUCKET_TYPE.COMPLETED_QUEST]   = SelectActiveQuest,
		[API.BUCKET_TYPE.UNCOMPLETED_QUEST] = SelectActiveQuest
	}
}

function API.getDialogChoiceSelectorForEventType(eventType, bucketType)
	assert(DIALOG_CHOICES_SELECTORS[eventType], ("No dialog choice selector for event type %s!"):format(tostring(eventType)));
	assert(DIALOG_CHOICES_SELECTORS[eventType][bucketType], ("No dialog choice selector for bucket type %s in event type %s."):format(tostring(bucketType), tostring(eventType)));
	return DIALOG_CHOICES_SELECTORS[eventType][bucketType];
end