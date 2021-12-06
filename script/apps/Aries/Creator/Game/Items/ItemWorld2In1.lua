--[[
Title: ItemWorld2In1
Author(s): yangguiyi
Date: 2021/8/11
Desc: 用于二合一世界工具箱，具体实现功能根据配置而定
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemWorld2In1.lua");
local ItemWorld2In1 = commonlib.gettable("MyCompany.Aries.Game.Items.ItemWorld2In1");
local item = ItemWorld2In1:new({icon,});
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemToolBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");

local ItemWorld2In1 = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.ItemToolBase"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemWorld2In1"));

block_types.RegisterItemClass("ItemWorld2In1", ItemWorld2In1);

local default_inhand_offset = {0.15, 0.3, 0}
local groupindex_wrong = 3;
local groupindex_hint_auto = 6; -- auto selected block
-- @param template: icon
-- @param radius: the half radius of the object. 

local template_type = {
	["templates"] = 1,
	["movie"] = 1,
	["agent"] = 1,
}

function ItemWorld2In1:ctor()
	--self:SetOwnerDrawIcon(true);
	self.target_file_path = self:GetTargetFilePath()
	self.is_template_type = template_type[self.type]
end

function ItemWorld2In1:FrameMove()
	ParaTerrain.DeselectAllBlock(groupindex_hint_auto);
	ParaTerrain.DeselectAllBlock(groupindex_wrong);
	
	if self.show_template_blocks then
		local blocks = self.show_template_blocks
		local x,y,z = ParaScene.GetPlayer():GetPosition();
		local bx, by, bz = BlockEngine:block(x, y+0.1, z);
		self.need_sure = false
		for i=1, #(blocks) do
			local block = blocks[i];
			local target_x,target_y,target_z = bx + block[1], by + block[2], bz + block[3]
			local dest_id = ParaTerrain.GetBlockTemplateByIdx(target_x,target_y,target_z); 
			local color = dest_id ~= 0 and groupindex_wrong or groupindex_hint_auto
			if dest_id ~= 0 then
				self.need_sure = true
			end
			
			ParaTerrain.SelectBlock(target_x,target_y,target_z, true, color);
		end
	end
end

function ItemWorld2In1:GetTargetFilePath()
	local path
	if self.type == "model" then
		local model_path = Files.GetWorldFilePath(string.format("items/%s/%s.x", self.type, self.filename))
		if not model_path then
			model_path = Files.GetWorldFilePath(string.format("items/%s/%s.bmax", self.type, self.filename))
		end
		
		path = model_path
		
	elseif self.type == "resource" then
		local model_path = Files.GetWorldFilePath(string.format("items/%s/%s", self.type, self.filename))
		path = model_path
	else
		local template_path = Files.GetWorldFilePath(string.format("items/%s/%s.blocks.xml", self.type, self.filename))
		path = template_path
	end

	path = commonlib.Encoding.DefaultToUtf8(path)
	return path
end

function ItemWorld2In1:TryCreate(itemStack, entityPlayer, x,y,z, side, data, side_region)
	if self.type == "model" then
		local entity_data = {tooltip=self.target_file_path}
		local block_id = self.obstruction and 254 or 22
		self:CreateBlock(x,y,z, block_id, nil, entity_data)
	elseif self.type == "resource" then
		-- 判断是否铁轨
		local block_id = BlockEngine:GetBlockIdAndData(math.floor(x), math.floor(y-1), math.floor(z));
		if block_id == 103 or block_id == 250 then
			local item = ItemClient.GetItem(20012);
			if(item) then
				local result, entity = item:TryCreate(nil, nil, x,y-1,z)
				if result and entity then
					entity:ReSetAssetFile(self.target_file_path)
				end
	
			end
		else
			local entity_data = {tooltip=self.target_file_path}
			local block_id = self.obstruction and 254 or 22
			self:CreateBlock(x,y,z, block_id, nil, entity_data)
		end
	-- event.ctrl_pressed
	elseif self.is_template_type then
		if self.target_file_path then
			local entity_data = {tooltip=self.target_file_path}
			local x,y,z = ParaScene.GetPlayer():GetPosition();
			local bx, by, bz = BlockEngine:block(x, y+0.1, z);
			self:CreateBlock(bx, by, bz, 254, nil, entity_data)
			self:ClearShowTemplate()
		end
	end

	if self.use_teacher_tip then
		GameLogic.HideTipText("<player>")
	end
end

function ItemWorld2In1:OnSelect(itemStack)
	self:CreatShowTemplate()
	ItemWorld2In1._super.OnSelect(self, itemStack)
end

function ItemWorld2In1:OnDeSelect()
	self:ClearShowTemplate()
	ItemWorld2In1._super.OnDeSelect(self)
end

function ItemWorld2In1:CreatShowTemplate()
	if self.frame_timer then
		return
	end

	if not template_type[self.type] then
		return
	end

	local template_path = self.target_file_path
	if not template_path then
		return
	end

	self:LoadTemplateFile(template_path)
	self.frame_timer = self.frame_timer or commonlib.Timer:new({callbackFunc = function()
		self:FrameMove()
	end})
	self.frame_timer:Change(200,200);

	local create_desc = self.create_desc or L"按【鼠标右键】键确认建造位置, 【W,A,S,D】键可以移动"
	if self.use_teacher_tip then
		GameLogic.SetTipText(create_desc, "<player>", nil, nil);
	else
		GameLogic.AddBBS("desktop", create_desc);
	end
	
end

function ItemWorld2In1:ClearShowTemplate()
	if self.frame_timer then
		ParaTerrain.DeselectAllBlock(groupindex_hint_auto);
		ParaTerrain.DeselectAllBlock(groupindex_wrong);
		
		self.show_template_blocks = nil
		self.frame_timer:Change();
		self.frame_timer = nil
	end
end

function ItemWorld2In1:CreateBlock(x,y,z, blockId, blockData, entity_data)
	if(type(blockId) == "string") then
		local id, data = blockId:match("^(%d+):?(%d*)");
		if(id) then
			blockId = tonumber(id)
			if(data and data~="") then
				blockData = tonumber(data);
			end
		else
			return
		end
	end
	--local task = MyCompany.Aries.Game.Tasks.CreateBlock:new({blockX = x,blockY = y, blockZ = z, blocks = {{0,0,0,blockId, blockData, entity_data}}})
	local task = MyCompany.Aries.Game.Tasks.CreateBlock:new({blockX = x,blockY = y, blockZ = z, block_id = blockId, data = blockData, itemStack = ItemStack:new():Init(blockId, 1, entity_data)})
	task:Run();
end

function ItemWorld2In1:LoadTemplateFile(filename)
	local xmlRoot = ParaXML.LuaXML_ParseFile(filename or "");
	if(not xmlRoot) then
		xmlRoot = ParaXML.LuaXML_ParseFile(commonlib.Encoding.Utf8ToDefault(filename));
	end
	if(xmlRoot) then
		local template_node = commonlib.XPath.selectNode(xmlRoot, "/pe:blocktemplate");

		local node = commonlib.XPath.selectNode(xmlRoot, "/pe:blocktemplate/pe:blocks");
		if(node and node[1]) then
			local blocks = NPL.LoadTableFromString(node[1]) or {};

			self.show_template_blocks = blocks;
		end
	end
end

function ItemWorld2In1:keyPressEvent(event)

end

function ItemWorld2In1:OnClick()
	self:CreatShowTemplate()
	ItemWorld2In1._super.OnClick(self)
end

function ItemWorld2In1:OnClickInHand(itemStack, entityPlayer)
	self:CreatShowTemplate()
	ItemWorld2In1._super.OnClick(self, itemStack, entityPlayer)
end