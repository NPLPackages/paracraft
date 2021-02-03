--[[
Title: MovieClipComponent 
Author(s): leio
Date: 2021/1/7
Desc: 
use the lib:
------------------------------------------------------------
local MovieClipComponent = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/Components/MovieClipComponent.lua");
------------------------------------------------------------
--]]
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/AllContext.lua");
local AllContext = commonlib.gettable("MyCompany.Aries.Game.AllContext");
local VisualSceneLogic = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/VisualSceneLogic.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityMovieClip.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
local BaseComponent = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/BaseComponent.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
NPL.load("(gl)script/ide/timer.lua");

local MovieClipComponent = commonlib.inherit(BaseComponent, NPL.export());

MovieClipComponent:Property({"ComponentName", "MovieClipComponent", auto = true,  camelCase = true, });
MovieClipComponent:Property({"BlockPosition", {0,0,0}, auto = true,  camelCase = true, });
MovieClipComponent:Property({"Assetfile", "character/CC/02human/paperman/girl04.x", auto = true,  camelCase = true, });

function MovieClipComponent:ctor()
    self.blockid = 228;
    self.default_Assetfile = "character/CC/02human/paperman/girl04.x";
end

function MovieClipComponent:processCode()
    -- install methods
end
function MovieClipComponent:onAddedToNode(node)
    node.MovieClipComponent = self;
end
function MovieClipComponent:onRemovedFromNode(node)
    node.MovieClipComponent = nil;
end
function MovieClipComponent:reload()
    self:createEntity();
end
function MovieClipComponent:getEntity()
    local x = self.BlockPosition[1];
    local y = self.BlockPosition[2];
    local z = self.BlockPosition[3];
    local entity = BlockEngine:GetBlockEntity(x,y,z);
    if(entity and entity.class_name == "EntityMovieClip")then
        return entity;
    end
end
function MovieClipComponent:createGetActor()
	if(not self.actor) then
		local movieEntity = self:getEntity();
		if(movieEntity) then
            movieEntity:CreateNPC();
			local itemStack = movieEntity:GetFirstActorStack();
			if(itemStack) then
				local item = itemStack:GetItem();
				if(item and item.CreateActorFromItemStack) then
					local actor = item:CreateActorFromItemStack(itemStack, movieEntity, false, "ActorForMovieClipComponent_");
					if(actor) then
						self.actor = actor;
						self.actor:SetTime(0);
						self.actor:FrameMove(0);
						local entity = self.actor:GetEntity();
						if(entity) then
							entity:SetSkipPicking(true)
						end
					end
				end
			end
		end
	end
	return self.actor;
end
function MovieClipComponent:changeAssetFile(assetfile)
    if(not self.actor)then
        return
    end
	self.actor:AddKeyFrameByName("assetfile", 0, assetfile);
    self.actor:FrameMovePlaying(0);
end
function MovieClipComponent:createEntity()
    local entity = self:getEntity();
    if(not entity)then
        -- clear actor
        self.actor = nil;
        local x = self.BlockPosition[1];
        local y = self.BlockPosition[2];
        local z = self.BlockPosition[3];
        BlockEngine:SetBlock(x,y,z, self.blockid);
        entity = self:getEntity();
        if(entity)then
            self:createGetActor();
            if(self.actor)then
                local assetfile = self.Assetfile or self.default_Assetfile;
				self.actor:AddKeyFrameByName("assetfile", 0, assetfile);
            end
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
function MovieClipComponent:onAddedToScene(scene)
    self:createEntity();
end
function MovieClipComponent:onRemovedFromScene(scene)
    local entity = self:getEntity();
    if(entity)then
        entity:Detach();
    end
    if(self.timer)then
        self.timer:Change()
    end

    self.actor = nil;
end
function MovieClipComponent:toJson()
    local object = self._super:toJson();
    object.ComponentName = self.ComponentName;
    object.BlockPosition = { self.BlockPosition[1], self.BlockPosition[2], self.BlockPosition[3], };
    object.Assetfile = self.Assetfile;
    return object;
end





