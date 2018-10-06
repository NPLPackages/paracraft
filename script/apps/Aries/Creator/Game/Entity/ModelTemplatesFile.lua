--[[
Title: all models for auto animations
Author(s): Cheng Yuanchu, LiXizhi
Date: 2018/9/21
Desc: singleton class
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/ModelTemplatesFile.lua");
local ModelTemplatesFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.ModelTemplatesFile")
ModelTemplatesFile:GetTemplates();
-------------------------------------------------------
]]

local ModelTemplatesFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.ModelTemplatesFile")

local model_template_files = {};

function ModelTemplatesFile:Init()
	if(self.isInited) then
		return 
	end
	self.isInited = true;
	self:LoadFromXMLFile();
end

-- @param filename: default to "config/Aries/creator/ModelTemplatesFile.xml"
function ModelTemplatesFile:LoadFromXMLFile(filename)
	filename = filename or "config/Aries/creator/ModelTemplatesFile.xml";
	local root = ParaXML.LuaXML_ParseFile(filename);
	if(root) then
		-- clear asset files: 
		LOG.std(nil, "info", "ModelTemplatesFile", "loading auto animation model templates from %s", filename);
		model_template_files = {};	
		local function ProcessNode(parentNode)
			for _, node in ipairs(parentNode) do
				if(node.name == "model") then
					local attr = node.attr;
					if(attr and attr.filename) then
						table.insert(model_template_files, attr);
						attr.name = attr.name and L(attr.name);
						LOG.std(nil, "info", "ModelTemplatesFile", "add template %s", attr.filename);
					end
				end
				ProcessNode(node);
			end
		end	
		ProcessNode(root);
	else
		LOG.std(nil, "warn", "ModelTemplatesFile", "failed to open %s", filename);
	end
end

function ModelTemplatesFile:GetTemplates()
	self:Init();
	return model_template_files;
end

-- return template table or nil
function ModelTemplatesFile:GetTemplateByFilename(filename)
	for _, template in ipairs(self:GetTemplates()) do
		if(template.filename == filename) then
			return template;
		end
	end
end