--[[
Title: Code Actor Item Stack
Author(s): LiXizhi
Date: 2019/2/12
Desc: this is a temporary object for setting and getting data from code block's inventory code actor

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeActorItemStack.lua");
local CodeActorItemStack = commonlib.gettable("MyCompany.Aries.Game.Code.CodeActorItemStack");
local item = CodeActorItemStack:new():Init(entityCode, itemStack, slotIndex)
-------------------------------------------------------
]]
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")

local CodeActorItemStack = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Code.CodeActorItemStack"));
CodeActorItemStack:Property("Name", "CodeActorItemStack");
-- whenever the current time is changed or any key is modified. 
CodeActorItemStack:Signal("valueChanged");

function CodeActorItemStack:ctor()
	self.key_array = {};
	self.key_index_map = {};
end

-- @param entityCode: the parent code entity
-- @param itemStack: the code actor instance's inventory itemstack
-- @param slotIndex: the slot index in the inventory. 
function CodeActorItemStack:Init(entityCode, itemStack, slotIndex)
	self.entityCode = entityCode;
	self.itemStack = itemStack;
	self.slotIndex = slotIndex;
	self:AddField("name")
	self:AddField("pos")
	self:AddField("yaw")
	self:AddField("pitch")
	self:AddField("roll")
	self:AddField("scaling")
	self:AddField("startTime")
	self:AddField("userData")
	return self;
end

function CodeActorItemStack:GetItemStack()
	return self.itemStack
end

function CodeActorItemStack:GetSlotIndex()
	return self.slotIndex;
end


function CodeActorItemStack:AddField(name)
	self.key_array[#(self.key_array)+1] = name;
	self.key_index_map[name] = #(self.key_array);
end

-------------------------------------
-- reimplement attribute field 
-------------------------------------
function CodeActorItemStack:GetFieldNum()
	return #(self.key_array);
end

function CodeActorItemStack:GetFieldIndex(name)
	return self.key_index_map[name];
end

function CodeActorItemStack:GetFieldName(valueIndex)
	return self.key_array[valueIndex]
end

function CodeActorItemStack:GetFieldType(nIndex)
	return "";
end

function CodeActorItemStack:SetField(name, value)
	local oldValue = self:GetField(name);
	-- skip equal values
	if(type(oldValue)== "table") then
		if(commonlib.partialcompare(oldValue, value)) then
			return;
		end
	elseif(oldValue == value) then
		return;
	end

	self.itemStack:SetDataField(name, value);
	self.entityCode:OnInventoryChanged(self.slotIndex);
	self:valueChanged();
end

function CodeActorItemStack:GetField(name, defaultValue)
	return self.itemStack:GetDataField(name) or defaultValue
end

function CodeActorItemStack:GetMovieEntity()
	return self.entityCode:FindNearByMovieEntity();
end

function CodeActorItemStack:OnClickActorEntity(actor, mouse_button)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditCodeActor/EditCodeActor.lua");
	local EditCodeActor = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditCodeActor");
	if(not EditCodeActor.GetInstance()) then
		local task = EditCodeActor:new():Init(self.entityCode);
		task:Run();
		EditCodeActor.SetFocusToItemStack(self:GetItemStack());
	end
end

-- create a movie actor based on this inventory item stack. 
-- only used in an editor
-- return movie actor created
function CodeActorItemStack:CreateMovieActor()
	local movieEntity = self:GetMovieEntity();
	if(movieEntity) then
		local itemStack = movieEntity:GetFirstActorStack();
		local item = itemStack:GetItem();
		if(item and item.CreateActorFromItemStack) then
			local actor = item:CreateActorFromItemStack(itemStack, movieEntity, false, "ActorForEditor_");
			if(actor) then
				-- keep a week reference here for EditCodeActor's right click scene picking
				actor.codeActorItemStack = self;
				self:ApplyInitParams(actor);
				local entity = actor:GetEntity();
				if(entity) then
					entity.OnClick = function(entity, x, y, z, mouse_button)
						return self:OnClickActorEntity(actor, mouse_button);
					end
				end
				return actor;
			end
		end
	end
end

-- apply this inventory item data to the given movie actor. Usually called automatically when item stack is changed by an editor. 
function CodeActorItemStack:ApplyInitParams(actor)
	actor:SetTime(self:GetField("startTime") or 0);
	actor:FrameMove(0);
	local entity = actor:GetEntity();
	if(not entity) then
		return;
	end
	local pos = self:GetField("pos")
	if(pos and pos[1]) then
		local x, y, z = BlockEngine:real_min(pos[1]+0.5, pos[2], pos[3]+0.5)
		entity:SetPosition(x, y, z);
	end
	local yaw = self:GetField("yaw")
	if(yaw) then
		entity:SetFacing(yaw*3.14/180);
	end
	local pitch = self:GetField("pitch")
	if(pitch) then
		entity:SetPitch(pitch*3.14/180);
	end
	local roll = self:GetField("roll")
	if(roll) then
		entity:SetRoll(roll*3.14/180);
	end

	local scaling = self:GetField("scaling")
	if(scaling) then
		entity:SetScaling(scaling/100);
	end
end