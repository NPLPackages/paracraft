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
NPL.load("(gl)script/ide/timer.lua");

local BaseComponent = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/BaseComponent.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local CodeComponent = commonlib.inherit(BaseComponent, NPL.export());

CodeComponent:Property({"ComponentName", "CodeComponent", auto = true,  camelCase = true, });
CodeComponent:Property({"BlockPosition", {0,0,0}, auto = true,  camelCase = true, });
CodeComponent:Property({"Code", "", auto = true,  camelCase = true, });
CodeComponent:Property({"CodeFileName", "", auto = true,  camelCase = true, });

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
    local entity = self:getEntity()
    if(entity)then
        local txt = self.Code;
        if(self.CodeFileName and self.CodeFileName ~= "")then
            txt = string.format('include("%s")',self.CodeFileName);
        end
        entity:SetNPLCode(txt);
        entity:Restart()
    end
end
function CodeComponent:stop()
    local entity = self:getEntity()
    if(entity)then
        entity:Stop();
    end
end
function CodeComponent:reload()
    self:createEntity();
end
function CodeComponent:getEntity()
    local x = self.BlockPosition[1];
    local y = self.BlockPosition[2];
    local z = self.BlockPosition[3];
    local entity = BlockEngine:GetBlockEntity(x,y,z);
    if(entity and entity.class_name == "EntityCode")then
        return entity;
    end
end
function CodeComponent:createEntity()
    local entity = self:getEntity();
    if(not entity)then
        local x = self.BlockPosition[1];
        local y = self.BlockPosition[2];
        local z = self.BlockPosition[3];
        BlockEngine:SetBlock(x,y,z, self.blockid);
        entity = self:getEntity();
        if(entity)then
            entity:SetDisplayName(self.Name);
        else
            if(not self.timer)then
                self.timer = commonlib.Timer:new({callbackFunc = function(timer)
                    self:createEntity();
                end})
                self.timer:Change(0, 1000)
            end
        end
        
    else
        if(self.timer)then
            self.timer:Change()
        end
    end
end
function CodeComponent:onAddedToScene(scene)
    self:createEntity();
end
function CodeComponent:onRemovedFromScene(scene)
    local entity = self:getEntity();
    if(entity)then
        entity:Detach();
    end
    if(self.timer)then
        self.timer:Change()
    end
end
function CodeComponent:toJson()
    local object = self._super:toJson();
    object.ComponentName = self.ComponentName;
    object.BlockPosition = { self.BlockPosition[1], self.BlockPosition[2], self.BlockPosition[3], };
    object.Code = self.Code;
    return object;
end





