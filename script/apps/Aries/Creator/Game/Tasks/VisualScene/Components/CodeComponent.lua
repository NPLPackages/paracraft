--[[
Title: CodeComponent 
Author(s): leio
Date: 2021/1/7
Desc: 
use the lib:
------------------------------------------------------------
local CodeComponent = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/Components/CodeComponent.lua");
------------------------------------------------------------
--]]
local VisualSceneLogic = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/VisualSceneLogic.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityMovieClip.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
local BaseComponent = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/BaseComponent.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local CodeComponent = commonlib.inherit(BaseComponent, NPL.export());

CodeComponent:Property({"ComponentName", "CodeComponent", auto = true,  camelCase = true, });
CodeComponent:Property({"BlockPosition", {0,0,0}, auto = true,  camelCase = true, });
CodeComponent:Property({"Code", "", auto = true,  camelCase = true, });
CodeComponent:Property({"CodeFileName", "", auto = true,  camelCase = true, });
CodeComponent:Property({"Runabled", true, auto = true,  camelCase = true, });

function CodeComponent:ctor()
    self.blockid = 219;
    self.cache_txt = nil;
end

function CodeComponent:onAddedToNode(node)
    node.CodeComponent = self;
end
function CodeComponent:onRemovedFromNode(node)
    node.CodeComponent = nil;
end
function CodeComponent:GetFileContent(filename)
	if(not filename)then
        return
    end
    local last_filename;
    local world_filename = GameLogic.GetWorldDirectory() .. filename;
    if(world_filename)then
        if(ParaIO.DoesFileExist(world_filename)) then
            last_filename = world_filename;
        else
	        filename = ParaIO.GetCurDirectory(0)..filename;
            if(ParaIO.DoesFileExist(filename)) then
                last_filename = filename;
            end
		end
    end
    if(last_filename)then
        local file = ParaIO.open(last_filename, "r")
		if(file:IsValid()) then
			local text = file:GetText();
			file:close();
            return text;
		end
    end
end
function CodeComponent:run()
    if(self.entity_code and self.Runabled)then
        local txt = self.Code;
        if(self.CodeFileName and self.CodeFileName ~= "")then
            txt = string.format('include("%s")',self.CodeFileName);
        end
        self.entity_code:SetNPLCode(txt);
        self.entity_code:Restart()
    end
end
function CodeComponent:stop()
    if(self.entity_code)then
        self.entity_code:Stop();
    end
end
function CodeComponent:onAddedToScene(scene)
    local x = self.BlockPosition[1];
    local y = self.BlockPosition[2];
    local z = self.BlockPosition[3];
    BlockEngine:SetBlock(x,y,z, self.blockid);
    local entity_code = BlockEngine:GetBlockEntity(x,y,z);
    if(entity_code and entity_code.class_name == "EntityCode")then
        entity_code:SetDisplayName(self.Name);
        self.entity_code = entity_code;
    end
    
end
function CodeComponent:onRemovedFromScene(scene)
    if(self.entity_code)then
        self.entity_code = nil;
    end
end
function CodeComponent:toJson()
    local object = self._super:toJson();
    object.ComponentName = self.ComponentName;
    object.BlockPosition = { self.BlockPosition[1], self.BlockPosition[2], self.BlockPosition[3], };
    object.Code = self.Code;
    object.Runabled = self.Runabled;
    return object;
end





