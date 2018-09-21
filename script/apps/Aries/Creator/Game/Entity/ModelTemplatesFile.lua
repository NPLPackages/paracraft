--[[
Title: Player Asset files
Author(s): Cheng Yuanchu
Date: 2018/9/21
Desc: buildin asset file.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/ModelTemplatesFile.lua");
local ModelTemplatesFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.ModelTemplatesFile")
ModelTemplatesFile:Init();
ModelTemplatesFile:GetTemplates();
-------------------------------------------------------
]]

local ModelTemplatesFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.ModelTemplatesFile")

local model_template_files;

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
		LOG.std(nil, "info", "ModelTemplatesFile", "load xml 888");
		model_template_files = {};	
		local function ProcessNode(parentNode)
			for _, node in ipairs(parentNode) do
				if(node.name == "model") then
					local attr = node.attr;
					if(attr and attr.filename) then
						table.insert(model_template_files, attr.filename);
						LOG.std(nil, "info", "ModelTemplatesFile", "add template %s", attr.filename);
					end
				end
				ProcessNode(node);
			end
		end	
		ProcessNode(root);
	end
end

function ModelTemplatesFile:GetTemplates()
	return model_template_files;
end
