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
local VisualSceneLogic = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/VisualSceneLogic.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityMovieClip.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
local BaseComponent = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/BaseComponent.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local MovieClipComponent = commonlib.inherit(BaseComponent, NPL.export());

MovieClipComponent:Property({"ComponentName", "MovieClipComponent", auto = true,  camelCase = true, });
MovieClipComponent:Property({"BlockPosition", {0,0,0}, auto = true,  camelCase = true, });
MovieClipComponent:Property({"Assetfile", "", auto = true,  camelCase = true, });

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
function MovieClipComponent:onAddedToScene(scene)
    local x = self.BlockPosition[1];
    local y = self.BlockPosition[2];
    local z = self.BlockPosition[3];
    BlockEngine:SetBlock(x,y,z, self.blockid);
    local entity_movieclip = BlockEngine:GetBlockEntity(x,y,z);
    if(entity_movieclip and entity_movieclip.class_name == "EntityMovieClip")then
        entity_movieclip:CreateNPC();
--	    entity_movieclip:SetMainAssetPath(self.Assetfile or self.default_Assetfile);
--        entity_movieclip:Attach();
        self.entity_movieclip = entity_movieclip;
    end
end
function MovieClipComponent:onRemovedFromScene(scene)
--    if(self.entity_movieclip)then
--        self.entity_movieclip:Detach();
--        self.entity_movieclip = nil;
--    end
end
function MovieClipComponent:toJson()
    local object = self._super:toJson();
    object.ComponentName = self.ComponentName;
    object.BlockPosition = { self.BlockPosition[1], self.BlockPosition[2], self.BlockPosition[3], };
    object.Assetfile = self.Assetfile;
    return object;
end





