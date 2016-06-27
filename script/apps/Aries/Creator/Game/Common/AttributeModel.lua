--[[
Title: attribute model
Author(s): LiXizhi
Date: 2014/8/7
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/AttributeModel.lua");
local AttributeModel = commonlib.gettable("MyCompany.Aries.Game.Common.AttributeModel");
local attrModel = AttributeModel:new():init(ParaEngine.GetAttributeObject());
attrModel:dump();
-------------------------------------------------------
]]
local AttributeModel = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Common.AttributeModel"));

function AttributeModel:ctor()
end

function AttributeModel:init(attr)
	self.attr = attr;
	return self;
end

-- dump summary to log.txt file
function AttributeModel:dump()
	if(self.attr) then
		NPL.load("(gl)script/ide/LuaXML.lua");
		local xmlNode = self:SerializeToXMLNode(self.attr);
		commonlib.log.log_long(commonlib.Lua2XmlString(xmlNode, true));
	end
end

-- serialize attr summary information to xmlNode
-- only output attribute class and all child nodes recursively, it does not print data fields. 
-- @return xmlNode;
function AttributeModel:SerializeToXMLNode(attr, xmlNode)
	xmlNode = xmlNode or {};
	xmlNode.name = attr:GetField("ClassName", "unknown");
	xmlNode.attr = xmlNode.attr or {};
	xmlNode.attr.classid = attr:GetField("ClassID", 0);
	xmlNode.attr.id = attr:GetField("id", "");
	xmlNode.attr.name = attr:GetField("name", "");
	
	local nColCount = attr:GetColumnCount();
	for cols=0, nColCount-1 do
		local nRowCount = attr:GetChildCount(cols);
		if(nRowCount > 0) then
			local node = xmlNode;
			if(nColCount > 1) then
				node = {name="child", attr={cols_index=cols, row_count=nRowCount}};
				xmlNode[#xmlNode+1] = node;
			end
			for rows = 0, nRowCount-1  do
				local child = attr:GetChildAt(rows, cols);
				if(child:IsValid()) then
					local childNode = self:SerializeToXMLNode(child);
					childNode.attr.index = format("%d,%d", rows, cols);
					node[#node+1] = childNode;
				end
			end
		end
	end
	return xmlNode;
end

