--[[
Title: ItemCodeActor
Author(s): LiXizhi
Date: 2019/1/28
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemCodeActor.lua");
local ItemCodeActor = commonlib.gettable("MyCompany.Aries.Game.Items.ItemCodeActor");
local item_ = ItemCodeActor:new({});
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/ActorNPC.lua");
local ActorNPC = commonlib.gettable("MyCompany.Aries.Game.Movie.ActorNPC");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemCodeActor = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.ItemToolBase"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemCodeActor"));

block_types.RegisterItemClass("ItemCodeActor", ItemCodeActor);

-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemCodeActor:ctor()
	self:SetOwnerDrawIcon(true);
end

function ItemCodeActor:GetActorName(itemStack)
	return itemStack and itemStack:GetDataField("tooltip");
end

function ItemCodeActor:SetActorName(itemStack, name)
	itemStack:SetDataField("tooltip", name);
end

function ItemCodeActor:GetDisplayName(itemStack)
	return self:GetTooltipFromItemStack(itemStack);
end

function ItemCodeActor:SetCodeBlock(itemStack, codeblock)
	if(codeblock) then
		local x, y, z = codeblock:GetBlockPos()
		itemStack:SetDataField("codeblock", {x, y, z});
		local codeblock = self:GetCodeBlock(itemStack);
		if(codeblock) then
			self:SetActorName(itemStack, codeblock:GetBlockName() or "");
		end
	else
		itemStack:SetDataField("codeblock", nil);
	end
end

function ItemCodeActor:GetTooltipFromItemStack(itemStack)
	local tooltip = self:GetTooltip();
	if(tooltip) then
		local name = self:GetActorName(itemStack)
		if(name) then
			tooltip = tooltip.."\n"..name;
		end
	end
	return tooltip;
end

function ItemCodeActor:GetCodeBlock(itemStack)
	local pos = itemStack:GetDataField("codeblock");
	if(pos and pos[1] and pos[2] and pos[3]) then
		local blockEntity = EntityManager.GetBlockEntity(pos[1], pos[2], pos[3]);
		if(blockEntity and blockEntity.GetCodeBlock) then
			return blockEntity:GetCodeBlock(true);
		end
	end
end

function ItemCodeActor:FindCodeBlock(itemStack)
	local codeblock = self:GetCodeBlock(itemStack)
	if(codeblock) then
		return codeblock;
	end

	local actorName = self:GetActorName(itemStack);
	if(not actorName) then
		return
	end
	local actor = GameLogic.GetCodeGlobal():GetActorByName(actorName)
	if(actor) then
		local codeblock = actor:GetCodeBlock()
		if(codeblock) then
			return codeblock;
		end
	else
		LOG.std(nil, "info", "ItemCodeActor", "code actor %s can not be found in the scene", actorName);
	end
end

function ItemCodeActor:TryCreate(itemStack, entityPlayer, x,y,z, side, data, side_region)
	local codeblock = self:FindCodeBlock(itemStack)
	if(codeblock and codeblock:GetEntity()) then
		local entityCode = codeblock:GetEntity();
		self:CreateActorInstance(entityCode, x, y, z)
	else
		self:SelectActor(itemStack)
	end
end

-- @param entityCode: the parent code entity 
-- @param x,y,z,facing: can all be nil.  in real coordinate system. 
function ItemCodeActor:CreateActorInstance(entityCode, x, y, z, facing)
	if(not entityCode) then
		return
	end
	local item = entityCode:CreateActorItemStack();
	if(item) then
		if(not x) then
			x, y, z = EntityManager.GetPlayer():GetPosition();
		end
		x, y, z = BlockEngine:block_float(x-0.5, y, z-0.5);
		item:SetField("pos", {x, y, z});

		if(not facing) then
			facing = Direction.directionTo3DFacing[Direction.GetDirection2DFromCamera()]-3.14;
		end
		item:SetField("yaw", math.floor(facing*180/3.14 + 0.5));

		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditCodeActor/EditCodeActor.lua");
		local EditCodeActor = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditCodeActor");
		EditCodeActor.SetFocusToItemStack(item:GetItemStack())
	end
end

function ItemCodeActor:TeleportPlayerToCodeBlock(itemStack)
	local codeblock = self:GetCodeBlock(itemStack)
	if(codeblock) then
		local x, y, z = codeblock:GetBlockPos()
		if(x and y and z) then
			GameLogic.RunCommand(format("/goto %d %d %d", x, y+1, z));
		end
	end
end

-- virtual: draw icon with given size at current position (0,0)
-- @param width, height: size of the icon
-- @param itemStack: this may be nil. or itemStack instance. 
function ItemCodeActor:DrawIcon(painter, width, height, itemStack)
	ItemCodeActor._super.DrawIcon(self, painter, width, height, itemStack);
	local name = self:GetActorName(itemStack);
	if(name and name~="") then
		painter:SetPen("#33333380");
		painter:DrawRect(0,0, width, 14);
		painter:SetPen("#ffffff");
		painter:DrawText(1,0, name);
	end
end

-- called whenever this item is clicked on the user interface when it is holding in hand of a given player (current player). 
function ItemCodeActor:OnClickInHand(itemStack, entityPlayer)
	-- if there is selected blocks, we will replace selection with current block in hand. 
	if(GameLogic.GameMode:IsEditor() and entityPlayer == EntityManager.GetPlayer()) then
		local codeblock = self:GetCodeBlock(itemStack)
		if(codeblock) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditCodeActor/EditCodeActor.lua");
			local EditCodeActor = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditCodeActor");
			if(EditCodeActor.GetInstance() and EditCodeActor.GetInstance():GetEntityCode()==codeblock:GetEntity()) then
				return;
			end
			local task = EditCodeActor:new():Init(codeblock:GetEntity());
			task:Run();
		else
			self:SelectActor(itemStack);
		end
	end
end

-- display a list for user to select a code actor	
function ItemCodeActor:SelectActor(itemStack)
	local options = {};
	for name, _ in pairs(GameLogic.GetCodeGlobal().actors) do
		if(name ~= "") then
			options[#options+1] = {value = name, text = name}	
		end
	end
					
	local old_value = self:GetActorName(itemStack);
	NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
	local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
	EnterTextDialog.ShowPage(L"演员名字", function(result)
		if(result and result ~= "" and result~=old_value) then
			self:SetActorName(itemStack, result);
			self:SetCodeBlock(itemStack, nil)
		end
	end,old_value, "select", options);
end

-- both codeblock and tooltip should match
function ItemCodeActor:CompareItems(left, right)
	if(ItemCodeActor._super.CompareItems(self, left, right)) then
		if(left and right) then
			local name1 = left:GetDataField("tooltip");
			local name2 = right:GetDataField("tooltip");
			if(name1 == name2) then
				local pos1 = left:GetDataField("codeblock");
				local pos2 = right:GetDataField("codeblock");
				if(pos1 and pos2) then
					if(pos1[1] == pos2[1] and pos1[2] == pos2[2] and pos1[3] == pos2[3]) then
						return true;
					end
				elseif(not pos1 and not pos2) then
					return true;
				end
			end
		end
	end
end

function ItemCodeActor:OnSelect(itemStack)
	ItemCodeActor._super.OnSelect(self, itemStack);
end

function ItemCodeActor:OnDeSelect()
	ItemCodeActor._super.OnDeSelect(self);
end

-- virtual function: 
function ItemCodeActor:CreateTask(itemStack)
	local codeblock = self:GetCodeBlock(itemStack)
	if(codeblock) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditCodeActor/EditCodeActor.lua");
		local EditCodeActor = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditCodeActor");
		if(EditCodeActor.GetInstance() and EditCodeActor.GetInstance():GetEntityCode()==codeblock:GetEntity()) then
			return;
		end
		return EditCodeActor:new():Init(codeblock:GetEntity());
	end
end

