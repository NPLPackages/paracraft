--[[
Title: Code Block Entity
Author(s): LiXizhi
Date: 2018/5/16
Desc: Code block 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityCode.lua");
local EntityCode = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCode")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlock.lua");
local CodeBlock = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlock");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockBase"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityCode"));

-- class name
Entity.class_name = "EntityCode";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
Entity.is_persistent = true;
-- always serialize to 512*512 regional entity file
Entity.is_regional = true;

function Entity:ctor()
end

function Entity:Destroy()
	Entity._super.Destroy(self);
end

function Entity:OnRemoved()
	if(self.codeBlock) then
		self.codeBlock:Destroy();
		self.codeBlock = nil;
	end
end

function Entity:OnNeighborChanged(x,y,z, from_block_id)
	if(not GameLogic.isRemote) then
		self:ScheduleRefresh(x,y,z);
	end
end

function Entity:SaveToXMLNode(node, bSort)
	node = Entity._super.SaveToXMLNode(self, node, bSort);
	node.attr.allowGameModeEdit = self:IsAllowGameModeEdit();
	node.attr.isPowered = self.isPowered;
end

function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);
	self:SetAllowGameModeEdit(node.attr.allowGameModeEdit == "true");
	local isPowered = node.attr.isPowered == "true";
	if(isPowered) then
		self:ScheduleRefresh();
	end
end

function Entity:ScheduleRefresh(x,y,z)
	if(not x) then
		x,y,z = self:GetBlockPos();
	end
	GameLogic.GetSim():ScheduleBlockUpdate(x, y, z, self:GetBlockId(), 1);
end

-- Ticks the block if it's been scheduled
function Entity:updateTick(x,y,z)
	local isPowered = BlockEngine:isBlockIndirectlyGettingPowered(x,y,z);
	self:SetPowered(isPowered);	
end

-- turn code on and off
function Entity:SetPowered(isPowered)
	if(self.isPowered and not isPowered) then
		self.isPowered = isPowered;
		local codeBlock = self:GetCodeBlock()
		if(codeBlock) then
			codeBlock:Unload();
		end
	elseif(not self.isPowered and isPowered) then
		self.isPowered = isPowered;
		local codeBlock = self:GetCodeBlock(true)
		if(codeBlock) then
			codeBlock:CompileCode(self:GetCommand());
			codeBlock:Run();
		end
	end
end

function Entity:Refresh()
	local codeBlock = self:GetCodeBlock()
	if(codeBlock) then
		codeBlock:CompileCode(self:GetCommand());
		if(self.isPowered) then
			codeBlock:Run();
		end
	end
end

function Entity:FindMovieBlockEntity()
	BlockEngine:GetBlockId(self.bx, self.by, self.bz)
end


function Entity:FindNearByMovieEntity()
	local cx, cy, cz = self.bx, self.by, self.bz;
	for side = 0, 5 do
		local dx, dy, dz = Direction.GetOffsetBySide(side);
		local x,y,z = cx+dx, cy+dy, cz+dz;
		local blockTemplate = BlockEngine:GetBlock(x,y,z);
		if(blockTemplate and blockTemplate.id == names.MovieClip) then
			local movieEntity = BlockEngine:GetBlockEntity(x,y,z);
			if(movieEntity) then
				return movieEntity;
			end
		end
	end
end

function Entity:GetCodeBlock(bCreateIfNotExist)
	if(not self.codeBlock and bCreateIfNotExist) then
		self.codeBlock = CodeBlock:new():Init(self);
	end
	return self.codeBlock;
end

-- the title text to display (can be mcml)
function Entity:GetCommandTitle()
	return L"输入代码"
end

function Entity:HasBag()
	return false;
end

function Entity:SetAllowGameModeEdit(bAllow)
	self.allowGameModeEdit = bAllow;
end

function Entity:IsAllowGameModeEdit()
	return self.allowGameModeEdit;
end

-- called when the user clicks on the block
-- @return: return true if it is an action block and processed . 
function Entity:OnClick(x, y, z, mouse_button, entity, side)
	if(GameLogic.isRemote) then
		if(mouse_button == "left") then
			-- GameLogic.GetPlayer():AddToSendQueue(GameLogic.Packets.PacketClickEntity:new():Init(entity or GameLogic.GetPlayer(), self, mouse_button, x, y, z));
		end
		return true;
	else
		if(self:IsAllowGameModeEdit()) then
			self:OpenEditor("entity", entity);
		elseif(mouse_button=="right" and GameLogic.GameMode:CanEditBlock()) then
			self:OpenEditor("entity", entity);
		end
	end
	return true;
end

function Entity:OpenEditor(editor_name, entity)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
	local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
    CodeBlockWindow.Show(true);
	CodeBlockWindow.SetCodeEntity(self);
end