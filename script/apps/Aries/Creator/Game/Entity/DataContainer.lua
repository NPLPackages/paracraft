--[[
Title: Data Container
Author(s): LiXizhi
Date: 2013/12/25
Desc: a container of serializable container. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/DataContainer.lua");
local DataContainer = commonlib.gettable("MyCompany.Aries.Game.EntityManager.DataContainer")
local data = DataContainer:new();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemStack.lua");
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local DataContainer = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.EntityManager.DataContainer"));


function DataContainer:ctor()
	self.datafields = {};
end

function DataContainer:IsEmpty()
	if(not next(self.datafields)) then
		return true;
	end
end

function DataContainer:LoadFromXMLNode(node)
	for _, node in ipairs(node) do
		-- df is data field
		local data_type = node.name;
		if(data_type == "number") then
			local name = node.attr.name;
			self.datafields[name] = tonumber(node.attr.value);
		elseif(data_type == "string") then
			self.datafields[name] = node.attr.value;	
		elseif(data_type == "table") then
			self.datafields[name] = NPL.LoadTableFromString(node.attr.value);
		elseif(data_type == "itemstack") then
			self.datafields[name] = ItemStack:new():Init(tonumber(node.attr.id), tonumber(node.attr.count), node.attr.serverdata);
		end
	end
end

function DataContainer:SaveToXMLNode(node)
	for name, value in pairs(self.datafields) do
		local data_type = type(value);
		if(data_type == "number") then
			node[#node+1] = {name="number", attr={value=value}};
		elseif(data_type == "string") then
			node[#node+1] = {name="string", attr={value=value}};
		elseif(data_type == "table") then
			if(value.class_name == "ItemStack") then
				node[#node+1] = {name="itemstack", attr={id=value.id, count=value.count, serverdata = value.serverdata}};
			else
				node[#node+1] = {name="table", attr={value=commonlib.serialize_compact(value)}};
			end
			
		end
	end
end

function DataContainer:GetField(name, default_value)
	return self.datafields[name] or default_value;
end

function DataContainer:SetField(name, value)
	self.datafields[name] = value;
end
