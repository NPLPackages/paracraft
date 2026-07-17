--[[
Title: EasyBuilder Task Verification Functions
Author(s): LiXizhi
Date: 2025/10/21
Desc: Provides verification functions for EasyBuilder tasks including:
- Cloud slot checking
- Entity and block counting in regions
- Block type verification
- Model existence checking
- Environment state checking (day/night time)

Use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyBuilderTaskVerify.lua");
local EasyVerify = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.EasyVerify");

echo(EasyVerify.EditableWorld.hasCloudSlot(subTag))
echo(EasyVerify.EditableWorld.getLiveEntityCount())
echo(EasyVerify.EditableWorld.getLiveEntityCountWithModelFile("model_file_name", bRegularExpMatch))
echo(EasyVerify.EditableWorld.getLiveEntityCountWithModelFile("light", true))
echo(EasyVerify.EditableWorld.getBlocksCount())
echo(EasyVerify.EditableWorld.getBlocksCountOf(blockId, blockData))
-- "MovieClip", "CodeBlock", "Sign_Post", "Painting"
echo(EasyVerify.EditableWorld.getBlocksCountOf("CodeBlock"))
echo(EasyVerify.Env.isAtNight())
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");

local EasyVerify = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.EasyVerify");

-- EditableWorld verification functions
EasyVerify.EditableWorld = EasyVerify.EditableWorld or {};

-- Check if a cloud slot exists for a given subtag
-- @param subTag: string, the subtag to check for
-- @return: boolean, true if a cloud slot exists with this subtag
function EasyVerify.EditableWorld.hasCloudSlot(subTag)
    local editableWorld = GameLogic.CreateGetEditableWorld();
    if not editableWorld then
        return false;
    end
    
    local slots = editableWorld:GetLocalWorldSlots(nil, subTag);
    if slots and #slots > 0 then
        return true;
    end
end

-- get live entity count in currently loaded editable world
function EasyVerify.EditableWorld.getLiveEntityCount()
    local editableWorld = GameLogic.CreateGetEditableWorld();
    local count = editableWorld:GetLiveEntityCount();
    return count;
end

-- get live entity count with specific model file in currently loaded editable world
-- @param filename: string, the model file name to match
-- @param bRegularExpMatch: boolean, if true, treat filename as a regular expression
function EasyVerify.EditableWorld.getLiveEntityCountWithModelFile(filename, bRegularExpMatch)
    local editableWorld = GameLogic.CreateGetEditableWorld();
    local count = 0;
    if(editableWorld.liveEntityNames) then
		for name, _ in pairs(editableWorld.liveEntityNames) do
			local entity = EntityManager.GetEntity(name);
			if(entity and entity.isFromEditableWorld) then
				if(bRegularExpMatch) then
                    if(string.match(entity:GetModelFile() or "", filename)) then
                        count = count + 1;
                    end
                else
                    if(entity:GetModelFile() == filename) then
                        count = count + 1;
                    end
                end
			end
		end
	end
    return count;
end

-- get total blocks count in currently loaded editable world
function EasyVerify.EditableWorld.getBlocksCount()
    local editableWorld = GameLogic.CreateGetEditableWorld();
	local totalBlocks = 0
	local bx, by, bz;
	for k, v in pairs(editableWorld.blocksMap) do    
		bx,by,bz = BlockEngine:FromSparseIndex(k)
		local blockId, blockData = BlockEngine:GetBlockIdAndData(bx, by, bz);
		if(blockId and blockId ~= 0) then
			totalBlocks = totalBlocks + 1;
		end
	end
    return totalBlocks;
end

function EasyVerify.EditableWorld.getBlocksCountOf(blockIdOrName, blockData)
    local editableWorld = GameLogic.CreateGetEditableWorld();
    local blockId = blockIdOrName;
    if(type(blockIdOrName) == "string") then
        blockIdOrName = block_types.names[blockIdOrName];
    end
    local totalBlocks = 0
    local bx, by, bz;
    for k, v in pairs(editableWorld.blocksMap) do    
        bx,by,bz = BlockEngine:FromSparseIndex(k)
        local bId, bData = BlockEngine:GetBlockIdAndData(bx, by, bz);
        if(bId == blockId and (not blockData or bData == blockData)) then
            totalBlocks = totalBlocks + 1;
        end
    end
    return totalBlocks;
end


-- Environment verification functions
EasyVerify.Env = EasyVerify.Env or {};

-- Check if the current time is nighttime
-- @param threshold: optional number, the TimeOfDaySTD threshold for night (default: 0.5)
--                   TimeOfDaySTD ranges from -1 to 1, where:
--                   - Around 0 is noon
--                   - Around 0.5 to 1.0 is evening/night
--                   - Around -0.5 to -1.0 is also night (before dawn)
-- @return: boolean, true if it's currently nighttime
function EasyVerify.Env.isAtNight(threshold)
    threshold = threshold or 0.5;
    local timeOfDay = EasyVerify.Env.getTimeOfDay()
    -- Night is when absolute value of TimeOfDaySTD is greater than threshold
    return math.abs(timeOfDay) > threshold;
end


-- Get the current time of day value
-- @return: number, the TimeOfDaySTD value (-1 to 1)
function EasyVerify.Env.getTimeOfDay()
    local sunLight = ParaScene.GetAttributeObjectSunLight();
    if not sunLight or not sunLight:IsValid() then
        return 0;
    end
    return sunLight:GetField("TimeOfDaySTD", 0);
end

-- Check if time is within a specific range
-- @param minTime: number, minimum TimeOfDaySTD value (-1 to 1)
-- @param maxTime: number, maximum TimeOfDaySTD value (-1 to 1)
-- @return: boolean, true if current time is within the range
function EasyVerify.Env.isTimeInRange(minTime, maxTime)
    local currentTime = EasyVerify.Env.getTimeOfDay();
    return currentTime >= minTime and currentTime <= maxTime;
end
