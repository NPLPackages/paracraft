--[[
Title: ItemLight
Author(s): LiXizhi
Date: 2016/9/23
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemLight.lua");
local ItemLight = commonlib.gettable("MyCompany.Aries.Game.Items.ItemLight");
local item = ItemLight:new({icon,});
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemToolBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");

local ItemLight = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.ItemToolBase"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemLight"));

block_types.RegisterItemClass("ItemLight", ItemLight);


-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemLight:ctor()
	self:SetOwnerDrawIcon(true);
end

function ItemLight:GetModelFileName(itemStack)
	return itemStack and itemStack:GetDataField("tooltip");
end

-- virtual: draw icon with given size at current position (0,0)
-- @param width, height: size of the icon
-- @param itemStack: this may be nil. or itemStack instance. 
function ItemLight:DrawIcon(painter, width, height, itemStack)
	ItemLight._super.DrawIcon(self, painter, width, height, itemStack);
	local filename = self:GetModelFileName(itemStack);
	if(filename and filename~="") then
		filename = filename:match("[^/]+$"):gsub("%..*$", "");
		filename = filename:sub(1, 6);
		painter:SetPen("#33333380");
		painter:DrawRect(0,0, width, 14);
		painter:SetPen("#ffffff");
		painter:DrawText(1,0, filename);
	end
end

-- virtual function: 
function ItemLight:CreateTask(itemStack)
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditLight/EditLightTask.lua");
	local EditLightTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditLightTask");
	EditLightTask:SetItemInHand(itemStack)
	return EditLightTask:new();
end

function ItemLight:OnSelect(itemStack)
	ItemLight._super.OnSelect(self, itemStack);
	local nRenderMethod = ParaTerrain.GetBlockAttributeObject():GetField("BlockRenderMethod", 1)
	if(nRenderMethod<2) then
		-- make sure deferred shading is enabled
		GameLogic.RunCommand("/shader 2")
	end
	if(System.os.GetPlatform() ~= "win32") then
		_guihelper.MessageBox(L"目前只有windows系统支持动态光源渲染")
	end
end


function ItemLight:PickItemFromPosition(x,y,z)
	local entity = self:GetBlock():GetBlockEntity(x,y,z);
	if(entity) then
		if(entity:isa(EntityManager.EntityLight)) then
			local attr = {}
			
			local function setNumberField(name)
				attr[name] = entity:GetField(name);
			end
			attr.modelFilepath = entity:GetField("modelFilepath");
			setNumberField("modelOffsetPos")
			setNumberField("modelScale")
			setNumberField("modelYaw")
			setNumberField("modelPitch")
			setNumberField("modelRoll")
			setNumberField("LightType")
			setNumberField("offsetPos")
			setNumberField("Yaw")
			setNumberField("Pitch")
			setNumberField("Roll")
			setNumberField("Diffuse")
			setNumberField("Specular")
			setNumberField("Ambient")
			setNumberField("Attenuation0")
			setNumberField("Attenuation1")
			setNumberField("Attenuation2")
			setNumberField("Theta")
			setNumberField("Phi")
			setNumberField("Range")
			setNumberField("Falloff")

			local node = {attr = attr};
			local itemStack = ItemStack:new():Init(self.id, 1);
			itemStack:SetData(node);
			-- transfer filename from entity to item stack. 
			return itemStack;
		end
	end
end

function ItemLight:TryCreate(itemStack, entityPlayer, x,y,z, side, data, side_region)
	local res = ItemLight._super.TryCreate(self, itemStack, entityPlayer, x,y,z, side, data, side_region);
	if(res) then
		local node = itemStack:GetData();
		local entity = EntityManager.GetBlockEntity(x, y, z);
		if(entity and entity:isa(EntityManager.EntityLight)) then
			local attr = node and node.attr
			if(attr) then
				local function setNumbersField(name, value)
					local t = type(value)
					if(t == "string" and value:match("^%{.*%}$")) then
						entity:SetField(name, NPL.LoadTableFromString(value))	
					elseif(t == "table") then
						entity:SetField(name, value)	
					else
						value = tonumber(value)
						if(value) then
							entity:SetField(name, value)	
						end
					end
				end

				if(attr.modelFilepath) then
					entity:SetField("modelFilepath", attr.modelFilepath)
				end
				setNumbersField("modelOffsetPos", attr.modelOffsetPos)
				setNumbersField("modelScale", attr.modelScale)
				setNumbersField("modelRoll", attr.modelRoll)
				setNumbersField("modelYaw", attr.modelYaw)
				setNumbersField("modelPitch", attr.modelPitch)

				setNumbersField("LightType", attr.LightType)
				setNumbersField("offsetPos", attr.offsetPos)
				setNumbersField("Yaw", attr.Yaw)
				setNumbersField("Pitch", attr.Pitch)
				setNumbersField("Roll", attr.Roll)
				setNumbersField("Diffuse", attr.Diffuse)
				setNumbersField("Specular", attr.Specular)
				setNumbersField("Ambient", attr.Ambient)
				setNumbersField("Theta", attr.Theta)
				setNumbersField("Phi", attr.Phi)
				setNumbersField("Range", attr.Range)
				setNumbersField("Falloff", attr.Falloff)
				setNumbersField("Attenuation0", attr.Attenuation0)
				setNumbersField("Attenuation1", attr.Attenuation1)
				setNumbersField("Attenuation2", attr.Attenuation2)
			end
		end
	end
	return res;
end