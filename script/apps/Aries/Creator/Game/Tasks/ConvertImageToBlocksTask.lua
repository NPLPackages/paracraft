--[[
Title: convert any image to blocks
Author(s): LiXizhi
Date: 2014/6/19
Desc: transparent pixel is mapped to air. creating in any plane one likes. 
TODO: support depth texture in future. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ConvertImageToBlocksTask.lua");
local Tasks = commonlib.gettable("MyCompany.Aries.Game.Tasks");
local task = Tasks.ConvertImageToBlocks:new({filename = filename,blockX, blockY, blockZ, height})
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemColorBlock.lua");
NPL.load("(gl)script/ide/System/Core/Color.lua");
local Color = commonlib.gettable("System.Core.Color");
local ItemColorBlock = commonlib.gettable("MyCompany.Aries.Game.Items.ItemColorBlock");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")

local ConvertImageToBlocks = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.ConvertImageToBlocks"));

-- operations enumerations
ConvertImageToBlocks.Operations = {
	-- load to scene
	Load = 1,
	-- only load into memory
	InMem = 2,
}
-- current operation
ConvertImageToBlocks.operation = ConvertImageToBlocks.Operations.Load;
-- how many concurrent creation point allowed: currently this must be 1
ConvertImageToBlocks.concurrent_creation_point_count = 1;
-- the color schema. can be 1, 2, 16. where 1 is only a single color. 
ConvertImageToBlocks.colors = 16;

--RGB, block_id
local block_colors = {
	{221, 221, 221,	block_types.names.White_Wool},
	{219,125,62,	block_types.names.Orange_Wool},
	{179,80, 188,	block_types.names.Magenta_Wool},
	{107, 138, 201,	block_types.names.Light_Blue_Wool},
	{177,166,39,	block_types.names.Yellow_Wool},
	{65, 174, 56,	block_types.names.Lime_Wool},
	{208, 132, 153,	block_types.names.Pink_Wool},
	{64, 64, 64,	block_types.names.Gray_Wool},
	{154, 161, 161,	block_types.names.Light_Gray_Wool},
	{46, 110, 137,	block_types.names.Cyan_Wool},
	{126,61,181,	block_types.names.Purple_Wool},
	{46,56,141,		block_types.names.Blue_Wool},
	{79,50,31,		block_types.names.Brown_Wool},
	{53,70,27,		block_types.names.Green_Wool},
	{150, 52, 48,	block_types.names.Red_Wool},
	{25, 22, 22,	block_types.names.Black_Wool},
}

-- Calculates distance between two RGB colors
local function GetColorDist(colorRGB, blockRGB)
	return math.max(math.abs(colorRGB[1]-blockRGB[1]), math.abs(colorRGB[2]-blockRGB[2]), math.abs(colorRGB[3]-blockRGB[3]));
end

local function GetColorDistBGR(colorBGR, blockRGB)
	return math.max(math.abs(colorBGR[3]-blockRGB[1]), math.abs(colorBGR[2]-blockRGB[2]), math.abs(colorBGR[1]-blockRGB[3]));
end

-- square distance
local function GetColorDist2(colorRGB, blockRGB)
	return ((colorRGB[1]-blockRGB[1])^2) + ((colorRGB[2]-blockRGB[2])^2) + ((colorRGB[3]-blockRGB[3])^2);
end

-- square distance
local function GetColorDist2BGR(colorRGB, blockRGB)
	return ((colorRGB[3]-blockRGB[1])^2) + ((colorRGB[2]-blockRGB[2])^2) + ((colorRGB[1]-blockRGB[3])^2);
end

-- find the closest color
local function FindClosetBlockColor(pixelRGB)
	local closest_block_color;
	local smallestDist = 100000;
	local smallestDistIndex = -1;
	for i = 1, #block_colors do
		local curDist = GetColorDistBGR(pixelRGB, block_colors[i]);
		-- local curDist = GetColorDist2BGR(pixelRGB, block_colors[i]);

		if (curDist < smallestDist) then
			smallestDist = curDist
			smallestDistIndex = i;
		end
	end
	return block_colors[smallestDistIndex];
end

function ConvertImageToBlocks:ctor()
	self.step = 1;
	self.history = {};
end

function ConvertImageToBlocks:Run()
	self.finished = true;

	if(GameLogic.GameMode:CanAddToHistory()) then
		self.add_to_history = true;
	end

	if(self.operation == ConvertImageToBlocks.Operations.Load) then
		return self:LoadToScene();
	elseif(self.operation == ConvertImageToBlocks.Operations.InMem) then
		return self:LoadToMemory();
	end
end

-- @param pixel: {r,g,b,a}
-- @param colors: 1, 2, 3, 16
local function GetBlockIdFromPixel(pixel, colors)
	if(colors == 1) then
		return block_types.names.White_Wool;
	elseif(colors == 2) then
		if((pixel[1]+pixel[2]+pixel[3]) > 128) then
			return block_types.names.White_Wool;
		else
			return block_types.names.Black_Wool;
		end
	elseif(colors == 3) then
		local total = pixel[1]+pixel[2]+pixel[3];
		if(total > 400) then
			return block_types.names.White_Wool;
		elseif(total > 128) then
			return block_types.names.Brown_Wool;
		else
			return block_types.names.Black_Wool;
		end
	elseif(colors == 4) then
		local total = pixel[1]+pixel[2]+pixel[3];
		if(total > 500) then
			return block_types.names.White_Wool;
		elseif(total > 400) then
			return block_types.names.Light_Gray_Wool;
		elseif(total > 128) then
			return block_types.names.Brown_Wool;
		elseif(total > 64) then
			return block_types.names.Gray_Wool;
		else
			return block_types.names.Black_Wool;
		end
	elseif(colors <= 16) then
		local block_color = FindClosetBlockColor(pixel);
		return block_color[4];
	else  -- for 65535 colors, use color block
		return block_types.names.ColorBlock, ItemColorBlock:ColorToData(Color.RGBA_TO_DWORD(pixel[3],pixel[2],pixel[1], 0));
	end
end

-- Load To Memory
function ConvertImageToBlocks:LoadToMemory()
	-- TODO:
end

function ConvertImageToBlocks:AddBlock(x,y,z, block_id, block_data)
	if(self.add_to_history) then
		local from_id = BlockEngine:GetBlockId(x,y,z);
		local from_data, from_entity_data;
		if(from_id and from_id>0) then
			from_data = BlockEngine:GetBlockData(x,y,z);
			from_entity_data = BlockEngine:GetBlockEntityData(x,y,z);
		end
		self.history[#(self.history)+1] = {x,y,z, block_id, from_id, from_data, from_entity_data};
	end
	local block_template = block_types.get(block_id);
	if(block_template) then
		block_template:Create(x,y,z, false, block_data);
	end
end

-- Load template using a coroutine, 100 blocks per second. 
-- @param self.blockX, self.blockY, self.blockZ
-- @param self.colors: 1 | 2 | 16 | 65535   how many colors to use
-- @param self.options: {xy=true, yz=true, xz=true}
function ConvertImageToBlocks:LoadToScene()
	local filename = self.filename;
	if(not filename) then
		return;
	end
	local colors = self.colors;
	local px, py, pz = self.blockX, self.blockY, self.blockZ;
	if(not px) then
		return
	end

	local plane = "xy";
	if(self.options) then
		if(self.options.xz) then
			plane = "xz";
		elseif(self.options.yz) then
			plane = "yz";
		end
	end

	local file = ParaIO.open(filename, "image");
	if(file:IsValid()) then
		local ver = file:ReadInt();
		local width = file:ReadInt();
		local height = file:ReadInt();
		local bytesPerPixel = file:ReadInt();
		LOG.std(nil, "info", "ConvertImageToBlocks", {filename, ver, width, height, bytesPerPixel});

		local block_world = GameLogic.GetBlockWorld();
		local function CreateBlock_(x, y, block_id, block_data)
			local z;
			if(plane == "xy") then
				x, y, z = px+x, py+y, pz;
			elseif(plane == "yz") then
				x, y, z = px, py+y, pz+x;
			elseif(plane == "xz") then
				x, y, z = px+x, py, pz+y;
			end
			ParaBlockWorld.LoadRegion(block_world, x, y, z);
			self:AddBlock(x, y, z, block_id, block_data);
		end

		-- array of {r,g,b,a}
		local pixel = {}; 
		if(bytesPerPixel >= 3) then
			local block_per_tick = 100;
			local count = 0;
			local row_padding_bytes = (bytesPerPixel*width)%4;
			if(row_padding_bytes >0) then
				row_padding_bytes = 4-row_padding_bytes;
			end
			local worker_thread_co = coroutine.create(function ()
				for y=1, height do
					for x=1, width do
						pixel = file:ReadBytes(bytesPerPixel, pixel);
						if(pixel[4]~=0) then
							-- transparent pixel does not show up. 
							local block_id, block_data = GetBlockIdFromPixel(pixel, colors);
							if(block_id) then
								CreateBlock_(x,y, block_id, block_data);
								count = count + 1;
								if((count%block_per_tick) == 0) then
									coroutine.yield(true);
								end
							end
						end
					end
					if(row_padding_bytes > 0) then
						file:ReadBytes(row_padding_bytes, pixel);
					end
				end	
				return;
			end)

			local timer = commonlib.Timer:new({callbackFunc = function(timer)
				local status, result = coroutine.resume(worker_thread_co);
				if not status then
					LOG.std(nil, "info", "ConvertImageToBlocks", "finished with %d blocks: %s ", count, tostring(result));
					timer:Change();
					file:close();
				end
			end})
			timer:Change(30,30);

			UndoManager.PushCommand(self);
		else
			LOG.std(nil, "error", "ConvertImageToBlocks", "format not supported");
			file:close();
		end
	end
end

function ConvertImageToBlocks:FrameMove()
	self.finished = true;
end

function ConvertImageToBlocks:Redo()
	if((#self.history)>0) then
		for _, b in ipairs(self.history) do
			BlockEngine:SetBlock(b[1],b[2],b[3], b[4]);
		end
	end
end

function ConvertImageToBlocks:Undo()
	if((#self.history)>0) then
		for _, b in ipairs(self.history) do
			BlockEngine:SetBlock(b[1],b[2],b[3], b[5] or 0, b[6], b[7]);
		end
	end
end