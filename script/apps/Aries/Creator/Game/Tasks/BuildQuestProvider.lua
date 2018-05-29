--[[
Title: Build quest data provider
Author(s): LiXizhi
Date: 2013/11/13
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildQuestProvider.lua");
local BuildQuestProvider =  commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildQuestProvider");
BuildQuestProvider.Init();
local step = BuildQuestProvider.GetStep(1, 1, 1);
step:GetBom():PrintParts();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/API/UserProfile.lua");
local UserProfile = commonlib.gettable("MyCompany.Aries.Creator.Game.API.UserProfile");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")

local BuildQuestProvider = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildQuestProvider");
local categoryPaths = {
	["template"]  = "worlds/DesignHouse/blocktemplates/",
	["tutorial"]  = "config/Aries/creator/blocktemplates/buildingtask/",
	["blockwiki"] = "config/Aries/creator/blocktemplates/blockwiki/",
}

-- themesType: 记录本地模板文件夹，在保持模板时供选择
local categoryDS = {
	["template"] = {
		themes = {},themesDS = {},themesType = {},beOfficial = false,
	},
	["tutorial"] = {
		themes = {},themesDS = {},themesType = {},beOfficial = true,
	},
	["blockwiki"] = {
		themes = {},themesDS = {},themesType = {},beOfficial = true,
	},
};
local block_wiki_tasks = {};
local themes = {};
local tasks = {};
local themesDS = {};

function BuildQuestProvider.Init()
	BuildQuestProvider.LoadFromFile();
	if(BuildQuestProvider.is_inited) then
		return
	end
	BuildQuestProvider.is_inited = true;
end


------------------------
-- bom class
------------------------
local bom_class = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildQuestProvider.bom_class"));
function bom_class:ctor()
	-- array of {x,y,z,block_id}
	self.blocks = {};
	self.block_map = {};
	-- mapping from block_id to {block_id, count, indices = {array of indices to self.blocks}}
	self.parts = {};
	-- array of part from more count to less count
	self.sorted_parts = {};
end

local function GetBlockIndex(x,y,z)
	return x+y*1000+z*1000000;
end

function bom_class:AddPart(block_id, index)
	local part = self.parts[block_id];
	if(not part) then
		part = {block_id = block_id, count=0, indices = {}}
		self.parts[block_id] = part;
	end
	part.count = part.count + 1;
	part.indices[part.count] = index;
	local block = self.blocks[index];
	if(block) then
		self.block_map[GetBlockIndex(block[1], block[2], block[3])] = block;
	end
end

function bom_class:FindBlock(x,y,z)
	return self.block_map[GetBlockIndex(x,y,z)];
end

function bom_class:GetMaxBlockCount()
	return #(self.blocks);
end

function bom_class:GetFinishedCount()
	return self.finished_count or 0;
end

function bom_class:IsFinished()
	return self:GetFinishedCount() == self:GetMaxBlockCount();
end

local builder_orders;

function bom_class:GetBuildOrder()
	if(builder_orders) then
		return build_orders;
	else
		build_orders = {
			[block_types.names.Lever] = 900,
			[block_types.names.Stone_Button] = 901,
			[block_types.names.Wooden_Pressure_Plate] = 911,
			[block_types.names.Stone_Pressure_Plate] = 912,
			[block_types.names.Electric_Torch] = 950,
			[block_types.names.Electric_Torch_On] = 951,
			[block_types.names.PowerBlock] = 952,
			[block_types.names.IronTrapdoor] = 971,
			[block_types.names.IronTrapdoor_On] = 972,
			[block_types.names.Wire] = 980,
			[block_types.names.Repeater] = 981,
			[block_types.names.Repeater_On] = 982,
			[block_types.names.StickyPiston] = 1000,
			[block_types.names.Piston] = 1001,
			[block_types.names.PistonHead] = 1002,
		}
		return build_orders;
	end
end

-- call this function to sort block array according to following criteria. 
--  normal cube, wire, power source, piston, etc. 
function bom_class:SortBlocks()	
	local orders = self:GetBuildOrder();
	table.sort(self.blocks, function(a,b)
		return (orders[a[4]] or 0) < (orders[b[4]] or 0);
	end);
end

function bom_class:PrintBlocks()
	for idx, block in ipairs(self.blocks) do
		echo({block_types.get(block[4]).name, idx});
	end
end

-- get the number of connected object count in the given direction. 
-- @param side: 0,1,2,3, 4,5
-- @max_count: default to 10.
-- @return count, first_block;
function bom_class:GetConnectedBlockCount(x,y,z, side, max_count)
	local count = 0;
	local first_block;
	local block = self:FindBlock(x,y,z);
	if(block) then
		max_count = max_count or 10;

		local block_id = block[4];
		for i=1, max_count do
			x,y,z = BlockEngine:GetBlockIndexBySide(x,y,z, side);
			block = self:FindBlock(x,y,z);
			if(block and block[4] == block_id) then
				count = count + 1;
				if(not first_block) then
					first_block = block;
				end
			else
				break;
			end
		end
	end
	return count, first_block;
end

function bom_class:FinishBlock(index)
	local block = self.blocks[index];
	if(block and not self.finished) then
		block.finished = true;
		self.finished_count = (self.finished_count or 0) + 1;
	end
end

function bom_class:GetTask()
	return self.parent.parent;
end

function bom_class:GetTitle()
	return (self.parent.parent.name or "").."|"..(self.parent.name or "");
end

function bom_class:Reset()
	self.finished_count = 0;
	for i, block in ipairs(self.blocks) do
		block.finished = nil;
	end
end

function bom_class:GetPart(block_id)
	return self.parts[block_id];
end

function bom_class:GetBlocks()
	return self.blocks;
end

function bom_class:GetBlocks_AbsolutePos()
	if(not self.blocks_absolute_pos) then
		self.blocks_absolute_pos = {};
		local blocks = self.blocks_absolute_pos;
		local pivot_x, pivot_y, pivot_z = string.match(self.pivot,"(%d*),(%d*),(%d*)");
		for k,v in pairs(self.blocks) do
			blocks[k] = {
				pivot_x + v[1],pivot_y + v[2],pivot_z + v[3],
			}
		end
	end
	return self.blocks_absolute_pos;
	--return self.blocks;
end

function bom_class:SortParts()
	local sorted_parts = self.sorted_parts;
	if(#sorted_parts == 0) then
		for block_id, part in pairs(self.parts) do
			sorted_parts[#(sorted_parts)+1] = part;
		end
		table.sort(self.sorted_parts, function(a,b)
			return a.count>b.count;
		end)
		self.sorted_parts = sorted_parts;
	end
end

function bom_class:PrintParts()
	for idx, part in ipairs(self.sorted_parts) do
		echo({block_id = part.block_id, count = part.count, part.indices});
	end
end

function bom_class:Init(filename, parent)
	self.parent = parent;
	local xmlRoot = ParaXML.LuaXML_ParseFile(filename or "");
	if(not xmlRoot) then
		xmlRoot = ParaXML.LuaXML_ParseFile(commonlib.Encoding.Utf8ToDefault(filename));
	end
	if(xmlRoot) then
		local template_node = commonlib.XPath.selectNode(xmlRoot, "/pe:blocktemplate");
		self.player_pos = template_node.attr.player_pos;
		self.pivot = template_node.attr.pivot;
		self.name = template_node.attr.name;

		local node = commonlib.XPath.selectNode(xmlRoot, "/pe:blocktemplate/pe:blocks");
		if(node and node[1]) then
			local blocks = NPL.LoadTableFromString(node[1]) or {};

			local offset_x, offset_y, offset_z = parent:GetOffset();
			if(offset_x or offset_y or offset_z) then
				offset_x = offset_x or 0;
				offset_y = offset_y or 0;
				offset_z = offset_z or 0;
				for i=1, #(blocks) do
					local block = blocks[i];
					block[1] = block[1] + offset_x;
					block[2] = block[2] + offset_y;
					block[3] = block[3] + offset_z;
				end
			end

			self.blocks = blocks;
			for i=1, #(blocks) do
				local block = blocks[i];
				self:AddPart(block[4], i);
			end

			self:SortParts();
		end
	else
		LOG.std(nil, "error", "bom_class", "can not open file %s", filename or "");
	end
	return self;
end

------------------------
-- step class
------------------------
local step_class = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildQuestProvider.step_class"));
function step_class:ctor()
	self.tips = self.tips or {};
end

function step_class:Init(xml_node, parent)
	local tips = self.tips;
	self.parent = parent;
	-- whether auto delete block
	self.auto_delete = xml_node.attr.auto_delete ~= "false";
	self.auto_create = xml_node.attr.auto_create == "true";
	self.invert_create = xml_node.attr.invert_create == "true";
	if(xml_node.attr.auto_sort_blocks) then
		self.auto_sort_blocks = xml_node.attr.auto_sort_blocks == "true";
	end
	if(self.invert_create) then
		self.auto_delete = false;
	end

	self.player_offset_x = tonumber(xml_node.attr.player_offset_x);
	self.player_offset_y = tonumber(xml_node.attr.player_offset_y);
	self.player_offset_z = tonumber(xml_node.attr.player_offset_z);

	self.offset_x = tonumber(xml_node.attr.offset_x);
	self.offset_y = tonumber(xml_node.attr.offset_y);
	self.offset_z = tonumber(xml_node.attr.offset_z);

	if(type(xml_node.attr.auto_prebuild_blocks) == "string") then
		local auto_prebuild_blocks = {};
		for id in string.gmatch(xml_node.attr.auto_prebuild_blocks, "%d+") do
			auto_prebuild_blocks[tonumber(id)] = true;
		end
		self.auto_prebuild_blocks = auto_prebuild_blocks;
		if(self.auto_sort_blocks == nil) then
			self.auto_sort_blocks = true;
		end
	end

	local last_to = 0;
	for node in commonlib.XPath.eachNode(xml_node, "/tip") do
		tips[#tips+1] = node;
		local from, to = node.attr.block:match("^(%d+)%-(%d+)$");
		if(to) then
			to = tonumber(to);
			from = tonumber(from);
		else
			from = node.attr.block:match("^(%d+)$");
			if(from) then
				from = tonumber(from);
			end
		end
		from = math.max(from or 0, last_to);
		to = math.max(from, to or 0);
		node.attr.block_from = from;
		node.attr.block_to = to;
		last_to = to + 1;
	end
	return self;
end

function step_class:IsAutoPrebuildBlock(block_id)
	if(self.auto_prebuild_blocks) then
		return self.auto_prebuild_blocks[block_id];
	end
end

function step_class:Reset()
	self.is_accelerating = nil;
	if(self.template) then
		self.template:Reset();
	end
end

-- @param nCount: if nil, we will be accelerating to the end. otherwise it will only accelerate up to the block count specified. 
function step_class:SetAccelerating(nCount)
	self.is_accelerating = true;
	self.acceleration_count = nCount;
end

-- whether to auto delete blocks.
function step_class:isAutoDelete()
	return self.auto_delete;
end

-- get bom offset. only used internally when loading bom from file. 
function step_class:GetOffset()
	return self.offset_x, self.offset_y, self.offset_z;
end

-- get offset relative to 0,0,0 of the bom. nil maybe returned for any of the component. 
function step_class:GetPlayerOffset()
	return self.player_offset_x,self.player_offset_y, self.player_offset_z;
end

-- whether to auto create blocks.
-- @param bAutoDecreaseCount: if true, it will decrease acceleration_count if any. 
function step_class:isAutoCreate(bAutoDecreaseCount)
	if(self.auto_create) then
		return true;
	elseif(self.is_accelerating) then
		if(bAutoDecreaseCount and self.acceleration_count) then
			self.acceleration_count = self.acceleration_count - 1;
			if(self.acceleration_count <= 0) then
				self.is_accelerating = nil;
				self.acceleration_count = nil;
			end
		end
		return true;
	end
end

-- whether to invert create.
function step_class:isInvertCreate()
	return self.invert_create;
end

function step_class:GetBom()
	if(not self.template) then
		self.template = bom_class:new():Init(self:GetTemplateFilename(), self);
	end
	return self.template;
end

-- get disk file regardless of file encoding. 
-- just in case default encoding differs when deploying task files to a foreign operating system (Utf8ToDefault failed), 
-- we will guest it according to parent task filename
function step_class:GetTemplateFilename()
	if(not self.src_disk and self.parent) then
		local task = self.parent;
		local default_src = self.src;
		if(self.src == "") then
			default_src  = (task.filepath or self.src):gsub("%.xml$", ".blocks.xml");
		else
			default_src  = commonlib.Encoding.Utf8ToDefault(self.src);
			local default_dir  = task.dir;
			if(not ParaIO.DoesFileExist(default_src, true)) then
				default_src = string.format("%s%s",default_dir,default_src);
				if(not ParaIO.DoesFileExist(default_src, true)) then
					default_src = task.filepath:gsub("%.xml$", ".blocks.xml");
					LOG.std(nil, "info", "task_class", "try fixing filename encoding for %s", self.src);
				end
			end
		end
		
		self.src_disk = default_src;
	end
	return self.src_disk;
end
	
function step_class:ClickOnceDeploy(bUseAbsolutePos)
	local TeleportPlayer;
	local bx, by, bz;
	if(bUseAbsolutePos) then
		TeleportPlayer = true;
	else
		local x, y, z = ParaScene.GetPlayer():GetPosition();
		bx, by, bz = BlockEngine:block(x, y+0.1, z);
	end
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockTemplateTask.lua");
	local BlockTemplate = commonlib.gettable("MyCompany.Aries.Game.Tasks.BlockTemplate");
	local task = BlockTemplate:new({operation = BlockTemplate.Operations.Load, filename = self:GetTemplateFilename(),
		blockX=bx,blockY=by, blockZ=bz, bSelect=false,TeleportPlayer=TeleportPlayer, UseAbsolutePos=bUseAbsolutePos,
		})
	task:Run();
end

-- get tip inner text
function step_class:GetTipText(i)
	i = i or 0;
	for k= 1, #(self.tips) do
		local tip = self.tips[k];
		if(tip.attr.block_from<=i and i<=tip.attr.block_to) then
			return tip[1];
		end
	end
end

------------------------
-- task class
------------------------
local task_class = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildQuestProvider.task_class"));
function task_class:ctor()
	self.steps = self.steps or {};
end

local next_id = 1;
function task_class:AddID()
	if(self.id) then
		tasks[tostring(self.id)] = self;
		next_id = math.max(tonumber(self.id) or 0, next_id + 1);
	else
		tasks[tostring(next_id)] = self;
		next_id = next_id + 1;
	end
end

function task_class:Init(xml_node, theme, task_index, category)
	self.UseAbsolutePos = if_else(self.UseAbsolutePos == "true" or self.beAbsolutePos == "true",true,false);
	self.click_once_deploy = self.click_once_deploy == "true";
	self:AddID()
	self.task_index = task_index;
	self.category =  category;
	--if(themeKey == "blockwiki") then
		--local task_name = string.match(self.name,"%d*_(.*)");
		--self.name = task_name;
	--end
	
	local steps = self.steps;
	local default_src,default_name,default_dir;
	for node in commonlib.XPath.eachNode(xml_node, "/Step") do
		--if(category == "blockwiki") then
			--local src = string.format("%s%s.blocks.xml",commonlib.Encoding.DefaultToUtf8(self.dir),self.name);
			--node.attr.src = src;
		--end
		steps[#steps+1] = step_class:new(node.attr):Init(node, self);
	end
	self.theme = theme;
	return self;
end

-- @param step_id: if nil the current step is returned.
function task_class:GetStep(step_id)
	return self.steps[step_id or self.current_step or 1];
end

-- whether using absolute position. 
function task_class:IsUseAbsolutePos()
	return self.UseAbsolutePos;
end

function task_class:IsClickOnceDeploy()
	return self.click_once_deploy;
end

-- just create everything using the template. 
function task_class:ClickOnceDeploy(bUseAbsolutePos)
	bUseAbsolutePos = bUseAbsolutePos or self:IsUseAbsolutePos()
	for _, step in pairs(self.steps) do
		step:ClickOnceDeploy(bUseAbsolutePos);
	end
	local profile = UserProfile.GetUser();
	profile:FinishBuilding(self:GetThemeID(), self:GetIndex(),self.category or "template");
end

-- reset task
function task_class:Reset()
	for _, step in pairs(self.steps) do
		step:Reset();
	end
end

-- get description
function task_class:GetDesc()
	return self.desc;
end

-- get theam id
function task_class:GetThemeID()
	if(self.theme) then
		return self.theme.id or 1;
	else
		return 1;
	end
end

-- get shadow blocks on ground in x,z plane 
function task_class:GetProjectionBlocks()
	if(not self.proj_blocks ) then
		local blocks = {};
		self.proj_blocks = blocks;
		for _, step in pairs(self.steps) do
			for i, block in ipairs(step:GetBom():GetBlocks()) do
				local block_index = GetBlockIndex(block[1], 0, block[3]);
				local last_block = blocks[block_index];
				if(not last_block or last_block[2]>block[2]) then
					-- always store the lowest y. 
					blocks[block_index] = block;
				end
			end
		end
	end
	return self.proj_blocks;
end

-- get all blocks in cube 
function task_class:GetProjectionAllBlocksWithAbsolutePos()
	if(not self.all_proj_blocks ) then
		local blocks = {};
		self.all_proj_blocks = blocks;
		for _, step in pairs(self.steps) do
			for i, block in ipairs(step:GetBom():GetBlocks_AbsolutePos()) do
				local block_index = GetBlockIndex(block[1], block[2], block[3]);
				if(not blocks[block_index]) then
					blocks[block_index] = block;
				end
			end
		end
	end
	return self.all_proj_blocks;
end

-- reset projection scene when use absolute position
function task_class:ResetProjectionScene()
	local blocks = self:GetProjectionAllBlocksWithAbsolutePos();
	for k,v in pairs(blocks) do
		local block = v;
		local x,y,z = block[1],block[2],block[3];
		BlockEngine:SetBlockToAir(x,y,z);
	end
	for _, step in pairs(self.steps) do
		local bom = step:GetBom();
		bom.palyerGotoOriginPos = nil;
	end
end

function task_class:GetIndex()
	return self.task_index;
end

-- get all block types in this task
function task_class:GetBlockTypes()
	local function insertblock_type(blocks,block_type,min_index,max_index)
		--local min_index = 1;
		local min_block_type = blocks[min_index];
		--local max_index = #blocks;
		local max_block_type = blocks[max_index];
		if(max_index - min_index == 1) then
			table.insert(blocks,min_index,block_type);
		else
			local new_index = math.floor(max_index/2);
			local new_block_type = blocks[new_index];
			if(block_type < new_block_type) then
				insertblock_type(blocks,block_type,min_index,new_index);
			else
				insertblock_type(blocks,block_type,new_index,max_index);
			end
		end
	end

	if(not self.block_types ) then
		local appear_blocks = {};
		local blocks = {};
		self.block_types = blocks;

		for _, step in pairs(self.steps) do
			for i, block in ipairs(step:GetBom():GetBlocks()) do
				local block_type = tonumber(block[4]);
				if(not appear_blocks[block_type]) then
					appear_blocks[block_type] = true;
					table.insert(blocks,{block_id = block_type});
				end
				--if(not next(blocks)) then
					--table.insert(blocks,block_type);
				--else
					--local min_index = 1;
					--local min_block_type = blocks[1];
					--local max_index = #blocks;
					--local max_block_type = blocks[#blocks];
					--if(min_index == max_index) then
						--if(block_type < max_block_type) then
							--table.insert(blocks,max_index,block_type);
						--else
							--table.insert(blocks,(max_index + 1),block_type);
						--end
					--else
						--insertblock_type(blocks,block_type,min_index,max_index);
					--end
				--end
				--local block_index = GetBlockIndex(block[1], 0, block[3]);
				--local last_block = blocks[block_index];
				--if(not last_block or last_block[2]>block[2]) then
					---- always store the lowest y. 
					--blocks[block_index] = block;
				--end
			end
		end
	end
	return self.block_types;
end

------------------------
-- theme class
------------------------
local theme_class = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildQuestProvider.theme_class"));
function theme_class:ctor()
	self.tasks = self.tasks or {};
	self.tasksDS = self.tasksDS or {};
end

-- load from xml node
function theme_class:Init(xml_node, theme_index, themeKey)
	self.id = theme_index;
	local tasks = self.tasks;
	local tasksDS = self.tasksDS;
	for node in commonlib.XPath.eachNode(xml_node, "/Task") do
		tasksDS[#tasksDS+1] = {};
		commonlib.partialcopy(tasksDS[#tasksDS],node.attr);
		local task_index = #tasks+1;
		tasks[task_index] = task_class:new(node.attr):Init(node, self, task_index, themeKey);
	end
	return self;
end

function theme_class:GetTask(task_id)
	return self.tasks[task_id or 1];
end

------------------------
-- provider 
------------------------
local localthemesDS = {};
local myThemePath = "worlds/DesignHouse/blocktemplates/";
local myThemeIndex;
local myTaskMap = {};

local string_byte = string.byte;
BuildQuestProvider.NeedRefreshDS = true;
local function GetFiles(path,filter,zipfile)
	local output = commonlib.Files.Find({}, path,0, 10000, filter, zipfile);
	table.sort(output, function(a, b)
		-- sort by filename
		local filename1 = a.filename;
		local filename2 = b.filename;
		for i=1, math.min(#filename1, #filename2) do
			local c1 = string_byte(filename1, i);
			local c2 = string_byte(filename2, i);
			if(c1 < c2) then
				return true;
			elseif(c1 > c2) then
				return false;
			end
		end
		return (#filename1) < (#filename2);

--		local a_date = a.createdate;
--		local b_date = b.createdate;
--		if(a_date == b_date) then
--			return false;
--		end
--		local a_year,a_month,a_day,a_hour,a_minute = string.match(a_date,"(%d*)-(%d*)-(%d*)-(%d*)-(%d*)");
--		a_year = tonumber(a_year);
--		a_month = tonumber(a_month);
--		a_day = tonumber(a_day);
--		a_hour = tonumber(a_hour);
--		a_minute = tonumber(a_minute);
--		local b_year,b_month,b_day,b_hour,b_minute = string.match(b_date,"(%d*)-(%d*)-(%d*)-(%d*)-(%d*)");
--		b_year = tonumber(b_year);
--		b_month = tonumber(b_month);
--		b_day = tonumber(b_day);
--		b_hour = tonumber(b_hour);
--		b_minute = tonumber(b_minute);
--		if(a_year ~= b_year) then
--			return a_year < b_year;
--		elseif(a_month ~= b_month) then
--			return a_month < b_month;
--		elseif(a_day ~= b_day) then
--			return a_day < b_day;
--		elseif(a_hour ~= b_hour) then
--			return a_hour < b_hour;
--		elseif(a_minute ~= b_minute) then
--			return a_minute < b_minute;
--		end
--		return false;
	end);
	local out = {};
	for i = 1,#output do
		out[i] = output[i]["filename"];
	end
	return out or {};
end

local global_template_name_utf8 = L"全局模板";
local global_dir_utf8 = myThemePath..global_template_name_utf8.."/";
local global_dir_default = commonlib.Encoding.Utf8ToDefault(global_dir_utf8);

function BuildQuestProvider.PrepareGlobalTemplateDir()
	if(not System.options.IsMobilePlatform) then
		ParaIO.CreateDirectory(global_dir_default);
	end
	
end

-- to be compatible with old file structure. we will need to move from old template position. 
-- @param bDeleteOldFile: whether we will delete old files
function BuildQuestProvider.TranslateGlobalTemplateToBuildingTask(bDeleteOldFile)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BlockTemplatePage.lua");
	local BlockTemplatePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BlockTemplatePage");
	--local allTemplate = BlockTemplatePage.GetAllTemplatesDS();
	local globalTemplate = GetFiles(myThemePath, function (msg)
		return string.match(msg.filename,"%.blocks%.xml$") ~= nil;
	end);

	LOG.std(nil, "info", "TranslateGlobalTemplateToBuildingTask", "%d files translated", #globalTemplate);
	
	for i = 1,#globalTemplate do
		--local file = globalTemplate[i];
		local filename = string.gsub(globalTemplate[i],".blocks.xml","");
		
		local srcpath = string.format("%s%s.blocks.xml",myThemePath,filename);
		local despath = string.format("%s/%s.blocks.xml",global_dir_default..filename,filename);
		if(not ParaIO.DoesFileExist(despath, false)) then
			ParaIO.CopyFile(srcpath, despath, true);
			local taskfilename = string.format("%s/%s.xml",global_dir_default..filename,filename);
			local blocksfilename = string.format("%s/%s.blocks.xml",global_dir_utf8..commonlib.Encoding.DefaultToUtf8(filename),commonlib.Encoding.DefaultToUtf8(filename));

			local xmlRoot = ParaXML.LuaXML_ParseFile(commonlib.Encoding.Utf8ToDefault(blocksfilename));
			if(xmlRoot) then
				local node = commonlib.XPath.selectNode(xmlRoot, "/pe:blocktemplate/pe:blocks");
				if(node and node[1]) then
					local blocks = NPL.LoadTableFromString(node[1]);
					if(blocks and #blocks > 0) then
						blocksNum = #blocks;
						BlockTemplatePage.CreateBuildingTaskFile(taskfilename, blocksfilename, commonlib.Encoding.DefaultToUtf8(filename), blocks)
					end
				end
			end
		end
		if(bDeleteOldFile) then
			ParaIO.DeleteFile(srcpath);
		end
	end
	if(bDeleteOldFile) then
		ParaIO.DeleteFile(myThemePath.."*.jpg");
	end
end

function BuildQuestProvider.LoadFromTemplate(themeKey,themePath)

	if(themeKey == "template") then
		categoryDS[themeKey]["themes"] = themes;
		categoryDS[themeKey]["themesDS"] = themesDS;
	end

	local cur_themes = categoryDS[themeKey]["themes"];
	local cur_themesDS = categoryDS[themeKey]["themesDS"];
	local cur_themesType = categoryDS[themeKey]["themesType"];
	local beOfficial = categoryDS[themeKey]["beOfficial"];

	BuildQuestProvider.PrepareGlobalTemplateDir();
	local hasOldGlobalFiles;
	local output = GetFiles(themePath,function (msg)
		if(msg.filesize == 0 or string.match(msg.filename,"%.zip$")) then
			-- folder or zip file
			return true;
		elseif(string.match(msg.filename,"blocks%.xml$")) then
			-- never execute here
			hasOldGlobalFiles = true;
		end
	end, "*.*");
	if(hasOldGlobalFiles and themeKey == "template") then
		BuildQuestProvider.TranslateGlobalTemplateToBuildingTask();
	end

	for i = 1,#output do
		local theme_name = string.match(output[i],"^(.*).zip$");
		local isThemeZipFile = false;
		if(theme_name) then
			local filename = themePath..output[i];
			ParaAsset.OpenArchive(filename, true);
			isThemeZipFile = true;
		else
			theme_name = output[i];
		end
		
		local theme_path = themePath..theme_name.."/";
		local theme_name_utf8 = commonlib.Encoding.DefaultToUtf8(theme_name);
		local order = 10;
		if(not isThemeZipFile) then
			local theme_info_file = theme_path.."info.xml";
			local xmlRoot = ParaXML.LuaXML_ParseFile(theme_info_file)
			if(xmlRoot) then
				for node in commonlib.XPath.eachNode(xmlRoot, "/Theme") do
					local attr = node.attr;
					if(attr and attr.name) then
						theme_name_utf8 = L(attr.name);
						if(attr.order) then
							order = tonumber(attr.order) or order;
						end
						break;
					end
				end
			end
		end

		local insert_index;
		for i=1, #cur_themesDS do
			local item = cur_themesDS[i];
			if( (item.order or 10 )>order) then
				insert_index = i;
				break;
			end
		end
		cur_themesDS[#cur_themesDS+1] = {name = theme_name_utf8, foldername=theme_name, order = order, unlock_coins = "0",image = "",icon = "",official = false,};
		local theme_index =  #cur_themes+1;
		cur_themes[theme_index] = theme_class:new({name = theme_name_utf8, foldername=theme_name, unlock_coins = "0",image = "",icon = "",official = false, themeKey = themeKey});

		localthemesDS[#localthemesDS + 1] = {value = theme_name_utf8};
		if(not isThemeZipFile) then
			local next_theme_type_index = #cur_themesType + 1;
			cur_themesType[next_theme_type_index] = {text = theme_name_utf8, value = theme_name};
		end
		if(insert_index) then
			table.insert(cur_themesDS, insert_index, cur_themesDS[theme_index]); cur_themesDS[theme_index+1] = nil;
			table.insert(cur_themes, insert_index, cur_themes[theme_index]); cur_themes[theme_index+1] = nil;
			table.insert(localthemesDS, insert_index, localthemesDS[theme_index]); localthemesDS[theme_index+1] = nil;
			theme_index = insert_index;
		end

		--local theme_path = themePath..theme_name.."/";
		local tasks_output;
		if(isThemeZipFile) then
			tasks_output = GetFiles(theme_path,"*.","*.zip");
		else
			-- echo({"11111111111111", commonlib.Encoding.DefaultToUtf8(theme_path)})
			tasks_output = GetFiles(theme_path,function (msg)
				-- folder or zip
				return msg.filesize == 0 or string.match(msg.filename,".zip");
			end, "*.*");
			-- echo({"2222222222", #tasks_output});
		end

		local theme = cur_themes[theme_index];
		local tasksDS = theme.tasksDS;
		local tasks = theme.tasks;
		for j = 1,#tasks_output do
			local taskname;
			if(isThemeZipFile) then
				taskname = string.match(tasks_output[j],"^(.*)/$")
			else
				taskname = string.match(tasks_output[j],"^(.*).zip$")
				if(taskname) then
					local filename = theme_path..tasks_output[j];
					ParaAsset.OpenArchive(filename, true);
				else
					taskname = tasks_output[j];
				end
			end
			
			local taskpath = theme_path..taskname.."/"..taskname..".xml";
			local task_dir = theme_path..taskname.."/";
			local taskXmlRoot = ParaXML.LuaXML_ParseFile(taskpath);
			for node in commonlib.XPath.eachNode(taskXmlRoot, "/Task") do
				node.attr.filepath = taskpath;
				node.attr.dir = task_dir;
				tasksDS[#tasksDS+1] = {};
				
				commonlib.partialcopy(tasksDS[#tasksDS],node.attr);
				tasksDS[#tasksDS].task_index = #tasksDS;
				local task_index = #tasks+1;
				local task = task_class:new(node.attr):Init(node, theme, task_index, themeKey);
				tasks[task_index] = task;
				
				if(themeKey == "blockwiki") then
					local block_id,task_name = string.match(tasksDS[#tasksDS].name,"(%d*)_(.*)");
					tasksDS[#tasksDS].block_id = tonumber(block_id);
					--tasksDS[#tasksDS].name = task_name;
				end

				--myTaskMap[node.attr.name] = {task_index = task_index, task_ds_index = #myTasksDS};
			end
		end
	end
	for i=1, #cur_themes do
		cur_themes[i].id = i;
	end

	if (#localthemesDS == 0) then
		localthemesDS[#localthemesDS + 1] = {value = global_template_name_utf8};
	end
	if(not beOfficial) then
		cur_themesDS[#cur_themesDS+1] = {name = "empty",official = false};
	end
	BuildQuestProvider.NeedRefreshDS = false;
end

function BuildQuestProvider.GetCategoryDS()
	return categoryDS;
end

function BuildQuestProvider.RefreshDataSource()
	BuildQuestProvider.NeedRefreshDS = true;
	BuildQuestProvider.LoadFromFile();
end

-- loading from file. 
function BuildQuestProvider.LoadFromFile(filename)
	if(not BuildQuestProvider.NeedRefreshDS) then
		return;
	end

	themesDS = {};
	themes = {};
	localthemesDS = {};
	-- BuildingTasks.xml文件内容转换到 creator\blocktemplates\buildingtask 文件夹中，不用在读取该文件内容  -- 2015.1.19
	if(false) then
		filename = filename or "config/Aries/creator/BuildingTasks.xml";
		local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
		if(xmlRoot) then
			for node in commonlib.XPath.eachNode(xmlRoot, "/Themes/Theme") do
				node.attr.official = true;
				themesDS[#themesDS+1] = {};
				commonlib.partialcopy(themesDS[#themesDS],node.attr);
				local theme_index =  #themes+1;
				themes[theme_index] = theme_class:new(node.attr):Init(node, theme_index, "template");
			end
		end
	end

	for k,v in pairs(categoryPaths) do
		categoryDS[k]["themes"] = {};
		categoryDS[k]["themesDS"] = {};
		categoryDS[k]["themesType"] = {};
		BuildQuestProvider.LoadFromTemplate(k,v);
	end
end

function BuildQuestProvider.GetTheme(theme_id,category)
	local cur_themes;
	if(category) then
		cur_themes = categoryDS[category]["themes"];
	else
		cur_themes = themes;
	end
	return cur_themes[theme_id or 1];
end

function BuildQuestProvider.GetTask(theme_id, task_id,category)
	local theme = BuildQuestProvider.GetTheme(theme_id,category);
	if(theme) then
		return theme:GetTask(task_id);
	end
end

function BuildQuestProvider.GetBlockWikiTask(block_id)
	if(not next(block_wiki_tasks)) then
		BuildQuestProvider.Init();
	end
	return block_wiki_tasks[block_id];
end

-- @param task_id: this is string like '1_1'
function BuildQuestProvider.GetTaskByID(task_id)
	BuildQuestProvider.Init();
	return tasks[task_id];
end

-- get the current step. 
function BuildQuestProvider.GetStep(theme_id, task_id, step_id)
	local task = BuildQuestProvider.GetTask(theme_id, task_id)
	if(task) then
		return task:GetStep(step_id);
	end
end

-- get the themes information. 
function BuildQuestProvider.GetThemes_DS(themeKey)
	if(not next(themesDS)) then
		BuildQuestProvider.Init();
	end
	local ds;
	if(themeKey) then
		ds = categoryDS[themeKey]["themesDS"]
	else
		ds = themesDS;
	end
	return ds;
end

-- get the themes type information. 
function BuildQuestProvider.GetThemesType_DS(themeKey)
	if(not next(themesDS)) then
		BuildQuestProvider.Init();
	end
	local ds = categoryDS[themeKey or "template"]["themesType"];
	return ds;
end

function BuildQuestProvider.GetLastSelectedTemplateName()
	if(not self.selectedTemplateName) then
		self.selectedTemplateName = UserProfile:LoadData("selectedTemplateName", "");
	end
	return self.selectedTemplateName;
end

-- get the local themes information. 
function BuildQuestProvider.GetLocalThemes_DS()
	if(not next(localthemesDS)) then
		BuildQuestProvider.Init();
	end
	local beSelected = false;

	
	local selectedTemplateName = BuildQuestProvider.GetLastSelectedTemplateName();

	if(selectedTemplateName ~= "") then
		for i = 1,#localthemesDS do
			if(localthemesDS[i].value == selectedTemplateName) then
				localthemesDS[i].selected = true;
				beSelected = true;
			else
				localthemesDS[i].selected = nil;
			end
		end
	end
	

	if(not beSelected) then
		localthemesDS[1].selected = true;
	end
	return localthemesDS;
end

function BuildQuestProvider.Reset()
end

-- get the tasks information. 
function BuildQuestProvider.GetTasks_DS(theme_id,category)
	BuildQuestProvider.Init();
	local theme = BuildQuestProvider.GetTheme(theme_id,category);
	if(not theme) then
		return;
	end
	return theme.tasksDS;
end

function BuildQuestProvider.OnSaveTaskDesc(theme_index,task_index,desc)
	local task = BuildQuestProvider.GetTask(theme_index,task_index);
    if(task) then
        task.desc = desc;

		NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BlockTemplatePage.lua");
		local BlockTemplatePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BlockTemplatePage");

		local step = task:GetStep(1);
		local taskfilename = task.filepath;
		local taskname = task.name;
		local blocksfilename = step.src;
		local xmlRoot = ParaXML.LuaXML_ParseFile(commonlib.Encoding.Utf8ToDefault(blocksfilename));
		if(xmlRoot) then
			local node = commonlib.XPath.selectNode(xmlRoot, "/pe:blocktemplate/pe:blocks");
			if(node and node[1]) then
				local blocks = NPL.LoadTableFromString(node[1]);
				if(blocks and #blocks > 0) then
					blocksNum = #blocks;
					BlockTemplatePage.CreateBuildingTaskFile(taskfilename, blocksfilename, taskname, blocks, desc)
				end
			end
		end
    end
end
