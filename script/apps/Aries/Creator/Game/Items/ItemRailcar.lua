--[[
Title: item railcar
Author(s): LiXizhi
Date: 2014/6/8
Desc: rail cars 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemRailcar.lua");
local ItemRailcar = commonlib.gettable("MyCompany.Aries.Game.Items.ItemRailcar");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/ModelTextureAtlas.lua");
local ModelTextureAtlas = commonlib.gettable("MyCompany.Aries.Game.Common.ModelTextureAtlas");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local BlockRailBase = commonlib.gettable("MyCompany.Aries.Game.blocks.BlockRailBase")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemRailcar = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.ItemToolBase"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemRailcar"));

block_types.RegisterItemClass("ItemRailcar", ItemRailcar);


function ItemRailcar:ctor()
	self:SetOwnerDrawIcon(true);
end


-- virtual function: use the item. 
function ItemRailcar:OnUse()
end

-- virtual function: when selected in right hand
-- function ItemRailcar:OnSelect()
-- end

-- virtual function: when deselected in right hand
-- function ItemRailcar:OnDeSelect()
-- end

-- Returns true if the given Entity can be placed on the given side of the given block position.
-- @param x,y,z: this is the position where the block should be placed
-- @param side: this is the OPPOSITE of the side of contact. 
function ItemRailcar:CanPlaceOnSide(x,y,z,side, data, side_region, entityPlayer, itemStack)
    if (not EntityManager.HasNonPlayerEntityInBlock(x,y,z) and not BlockEngine:isBlockNormalCube(x,y,z)) then
        return true;
    end
end

function ItemRailcar:SelectModelFile(itemStack)
	if(itemStack) then
		local local_filename = itemStack:GetDataField("tooltip");
		local_filename = commonlib.Encoding.Utf8ToDefault(local_filename)
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenRailCarFileDialog.lua");
		local OpenRailCarFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenRailCarFileDialog");
		OpenRailCarFileDialog.ShowPage(L"请输入bmax, x或fbx文件的相对路径, <br/>你也可以随时将外部文件拖入窗口中", function(result)
			if(result and result~="" and result~=local_filename) then
				result = commonlib.Encoding.DefaultToUtf8(result)
				self:SetModelFileName(itemStack, result);
			end
		end, local_filename, L"选择模型文件", "model", nil, nil)
	end
end

function ItemRailcar:SetModelFileName(itemStack, filename)
	if(itemStack) then
		itemStack:SetDataField("tooltip", filename);
		local task = self:GetTask();
		-- if(task) then
		-- 	task:SetItemInHand(itemStack);
		-- 	task:RefreshPage();
		-- end
	end
end

-- virtual function:
function ItemRailcar:TryCreate(itemStack, entityPlayer, x,y,z, side, data, side_region)
	local file_name = self.models and self.models[1].assetfile
	if not file_name then
		file_name = itemStack:GetDataField("tooltip");
	end
	if not file_name then
		self:SelectModelFile(itemStack);
		return
	end

	self.filename = file_name
	
	local facing;
	if(self:HasFacing()) then
		facing =  ParaScene.GetPlayer():GetFacing();
	end
	local bCreated, entityCreated = self:OnCreate({blockX = x, blockY = y, blockZ = z, facing = facing, side=side, itemStack = itemStack});
	if(bCreated and itemStack) then
		itemStack.count = itemStack.count - 1;
	end
	return true, entityCreated;
end

-- virtual function:
-- @param result: picking result. {side, blockX, blockY, blockZ}
-- @return: return true if created
function ItemRailcar:OnCreate(result)
	if(result.blockX) then
		-- local bx,by,bz = BlockEngine:GetBlockIndexBySide(result.blockX,result.blockY,result.blockZ,result.side);
		local bx, by, bz = result.blockX, result.blockY, result.blockZ;
		local block = BlockEngine:GetBlock(bx, by, bz);
		
		if(not BlockRailBase.isRailBlockAt(bx, by, bz)) then
			local side = BlockEngine:GetOppositeSide(result.side);
			bx, by, bz = BlockEngine:GetBlockIndexBySide(bx, by, bz,side)
			
			if(not BlockRailBase.isRailBlockAt(bx, by, bz)) then
				return;
			end
		end

		if(not EntityManager.HasNonPlayerEntityInBlock(bx,by,bz)) then 
			local x, y, z = BlockEngine:real(bx,by,bz);
			if(GameLogic.isRemote) then
				local clientMP = EntityManager.GetPlayer();
				if(clientMP and clientMP.AddToSendQueue) then
					clientMP:AddToSendQueue(Packets.PacketEntityMobSpawn:new():Init({x=x,y=y,z=z, item_id = self.block_id}, 10));
					return true;
				end
				
			else
				local entity = MyCompany.Aries.Game.EntityManager.EntityRailcar:Create({x=x,y=y,z=z, item_id = self.block_id});
				entity:Attach();
				return true, entity;
			end
		end	
	end
end

-- called every frame
function ItemRailcar:FrameMove(deltaTime)
end

function ItemRailcar:GetModelFileName(itemStack)
	return itemStack and itemStack:GetDataField("tooltip");
end

-- virtual: draw icon with given size at current position (0,0)
-- @param width, height: size of the icon
-- @param itemStack: this may be nil. or itemStack instance. 
function ItemRailcar:DrawIcon(painter, width, height, itemStack)
	local filename = self:GetModelFileName(itemStack);
	if(filename and filename~="") then
		itemStack.renderedTexturePath = ModelTextureAtlas:CreateGetModel(commonlib.Encoding.Utf8ToDefault(filename))
		
		if(itemStack.renderedTexturePath) then
			painter:SetPen("#ffffff");
			painter:DrawRectTexture(0, 0, width, height, itemStack.renderedTexturePath);
		else
			ItemRailcar._super.DrawIcon(self, painter, width, height, itemStack);
		end
		filename = filename:match("[^/]+$"):gsub("%..*$", "");
		filename = filename:sub(1, 6);
		
		painter:SetPen("#33333380");
		painter:DrawRect(0,0, width, 14);
		painter:SetPen("#ffffff");
		painter:SetFont("System;12")
		painter:DrawText(1,0, filename);

		if(itemStack) then
			if(itemStack.count>1) then
				-- draw count at the corner: no clipping, right aligned, single line
				painter:SetPen("#000000");	
				painter:DrawText(0, height-15+1, width, 15, tostring(itemStack.count), 0x122);
				painter:SetPen("#ffffff");	
				painter:DrawText(0, height-15, width-1, 15, tostring(itemStack.count), 0x122);
			end
		end
	else
		ItemRailcar._super.DrawIcon(self, painter, width, height, itemStack);
	end
end

-- virtual function: 
function ItemRailcar:CreateTask(itemStack)
	if not self.models or not self.models[1] then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditModel/EditModelTask.lua");
		local EditModelTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditModelTask");
		EditModelTask:SetItemInHand(itemStack)
		local task = EditModelTask:new()
		task:SetDragBtVisible(false)
		return task;
	end
end