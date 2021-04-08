--[[
Title: ParametricNode 
Author(s): leio
Date: 2021/3/18
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParametricMake/ParametricNode.lua");
local ParametricNode = commonlib.gettable("ParametricMake.ParametricNode");
------------------------------------------------------------
--]]
local ParametricNode = commonlib.gettable("ParametricMake.ParametricNode");

function ParametricNode:new (o)
	o = o or {}  
	setmetatable(o, self)
	self.__index = self
	return o
end
function ParametricNode:project(name,options)
	if(not self.is_created)then
		self.is_created = true;
		self.name = name;
		self.options = options or {};
		self.raw_props = {};
	
		self.props = self:createProps();
		self.enums = {};
		self.bounds = {};
		self.run_main_func = nil;
	end
end
function ParametricNode:clearDynamicProps()
	if(self.raw_props)then
		local len = #self.raw_props;
		while(len > 0)do
			local p = self.raw_props[len];
			if(p and p.dynamic)then
				table.remove(self.raw_props,len);
			end
			len = len - 1;
		end
	end
end
function ParametricNode:createProps()
	local props = {};
	local meta_table = {};
	meta_table.__index = function(__, key)
		for k,property in ipairs(self.raw_props) do
			if(property.name == key)then
				return property.value;
			end
		end
		
	end
	meta_table.__newindex = function(__, key, value)
		for k,property in ipairs(self.raw_props) do
			if(property.name == key)then
				property.value = value;
			end
		end
	end
	setmetatable(props, meta_table)
	return props;
end
-- TODO
function ParametricNode:include(filename)
end
function ParametricNode:defineBounds(name, values)

end
function ParametricNode:getEnumValue(fullname)
	if(not fullname)then
		return
	end
	local name, key = string.match(fullname,"(.+)%.(.+)");
	if(name and key)then
		local enum = self:getDefineEnum(name);
		if(enum and enum.values)then
			for k,v in ipairs(enum.values) do
				if(v.key == key)then
					if(v.value == nil)then
						return v.key;
					end
					return v.value;
				end
			end
		end
	end
end
function ParametricNode:getDefineEnum(name)
	if(not name)then
		return
	end
	for k,v in ipairs(self.enums) do
		if(v.name == name)then
			return v;
		end
	end
end
function ParametricNode:defineEnum(name, values)
	if(not name or not values)then
		return 
	end
	if(not self:getDefineEnum(name))then
		table.insert(self.enums,{
			name = name,
			values = values,
		});
	end
end
function ParametricNode:getProperty(name)
	if(not name)then
		return
	end
	for k,v in ipairs(self.raw_props) do
		if(v.name == name)then
			return v;
		end
	end
end
function ParametricNode:addProperty(value)
	if(value and value.name and type(value) == "table")then
		if(not self:getProperty(value.name))then
			table.insert(self.raw_props,value);	
		end
	end
end

function ParametricNode:toJson()
	local object = {};
	object.name = self.name;
	object.options = commonlib.copy(self.options);
	object.enums = commonlib.copy(self.enums);
	object.raw_props = commonlib.copy(self.raw_props);
    return object;
end
-- run at last line
function ParametricNode:setAction(function_)
	self.run_main_func = function_;
end
function ParametricNode:doAction(props)
	if(self.run_main_func)then
		self.run_main_func(props);
	end
end
-- https://scriptinghelpers.org/questions/63005/how-to-combine-two-tables-where-table-a-overwrites-table-b#viewSource
function ParametricNode:mergeTables(Mergee, Merger, IsMergerOverwriter)
	if(not Mergee or not Merger)then
		return Mergee or {};
	end
    local Merged = {}

    for MergeeKey, MergeeValue in pairs(Mergee) do
        Merged[MergeeKey] = MergeeValue
    end

    for MergerKey, MergerValue in pairs(Merger) do
        local MergeeValue = Mergee[MergerKey]

        if type(MergeeValue) == "table" and type(MergerValue) == "table" then
            Merged[MergerKey] = self:mergeTables(MergeeValue, MergerValue, IsMergerOverwriter)
        elseif Merged[MergerKey] or IsMergerOverwriter then
            Merged[MergerKey] = MergerValue
        end
    end

    return Merged
end
function ParametricNode:isNumber(name)
	local p = self:getProperty(name);
	if(p)then
		if(p.type == "number")then
			return true;
		end
	end
end
function ParametricNode:isString(name)
	local p = self:getProperty(name);
	if(p)then
		if(p.type == "string")then
			return true;
		end
	end
end
function ParametricNode:isEnum(name)
	local p = self:getProperty(name);
	if(p and p.type)then
		for k,v in ipairs(self.enums) do
			if(p.type == v.name)then
				return true;
			end
		end
	end
end
