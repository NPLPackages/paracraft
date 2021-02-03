--[[
Title: Editor
Author(s): leio
Date: 2021/1/7
Desc: 
use the lib:
------------------------------------------------------------
local Editor = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/UI/Editor.lua");
------------------------------------------------------------
--]]
local SkySpacePairBlock = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/BlockPositionAllocations/SkySpacePairBlock.lua");
local ComponentFactory = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/ComponentFactory.lua");
ComponentFactory.registerComponents();

local Scene = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/Scene.lua");
local SceneNode = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/VisualScene/SceneNode.lua");

NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
local Editor = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Editor:Property({"Uid", "", auto = true,  camelCase = true, });
Editor:Property({"Name", "", auto = true,  camelCase = true, });
Editor:Property({"Scene", auto = true, type = "Scene", camelCase = true, });

function Editor:ctor()
    self.Scene = Scene:new();
    self.pair_block_pos_allocation = nil
    self.selected = nil;
end
function Editor:onInit(block_pos_allocation)
    block_pos_allocation = block_pos_allocation or SkySpacePairBlock:new();
    self.pair_block_pos_allocation = block_pos_allocation;
    return self;

end
function Editor:run()
    self.Scene.RootNode:run();
end
function Editor:stop()
    self.Scene.RootNode:stop();
end
function Editor:clear()
    self.Scene:clear();
end
function Editor:reload()
    self.Scene.RootNode:reload();
end
function Editor:select(node)
    self.selected = node;
	GameLogic.GetFilters():add_filter("Editor.select", self, node);
end
function Editor:createOrGetFollowTeacher(codes)
    codes = codes or [[
local words = {
    "好好学习，天天向上。",
    "你的作品是最棒的！",
}
registerClickEvent(function()
    local index = math.random(#words)
    local word = words[index]
    say(word, 2)
end)

local p_x,p_y,p_z = getPos("@p");
setPos(p_x - 6,p_y,p_z - 6)
turnTo("@p")
anim(0)
say("hello!", 2)
while(true) do
  if(((distanceTo("@p")) > (4))) then
    turnTo("@p")
    
    local x,y,z = getPos();
    local p_x,p_y,p_z = getPos("@p");
    setPos(x,p_y,z)
    anim(4)
    moveForward(3, 0.5)
  else
    turnTo("@p")
    anim(0)
  end
end
]]
    local name = "FollowTeacher_Node"
    local code_component_name = "FollowTeacher_CodeComponent"
    local movieclip_component_name = "FollowTeacher_MovieClipComponent"
    local parent = self.Scene.RootNode;
    local node = parent:getChildByName(name);
    if(not node)then
        local node, code_component, movieclip_component = self:createBlockCodeNode(parent, name)
        if(node and code_component and movieclip_component)then
            code_component:setCode(codes)
            code_component.Name = code_component_name;
            movieclip_component.Name = movieclip_component_name;
            return node, code_component, movieclip_component;
        end
    else
        code_component = node:getComponentByName(code_component_name);
        if(code_component)then
            code_component:setCode(codes);
        end
        movieclip_component = node:getComponentByName(movieclip_component_name);
        return node, code_component, movieclip_component;
    end
end
-- follow magic for user
function Editor:createOrGetFollowMagic()
    local name = "FollowMagic_Node"
    local code_component_name = "FollowMagic_CodeComponent"
    local movieclip_component_name = "FollowMagic_MovieClipComponent"
    local parent = self.Scene.RootNode;
    local node = parent:getChildByName(name);
    if(not node)then
        local node, code_component, movieclip_component = self:createBlockCodeNode(parent, name)
        if(node and code_component and movieclip_component)then
            code_component:setCode(
[[registerClickEvent(function()
    say("hello!", 2)

end)

local p_x,p_y,p_z = getPos("@p");
setPos(p_x - 6,p_y,p_z - 6)
turnTo("@p")
anim(0)
say("hello!", 2)
while(true) do
  if(((distanceTo("@p")) > (4))) then
    turnTo("@p")
    
    local x,y,z = getPos();
    local p_x,p_y,p_z = getPos("@p");
    setPos(x,p_y,z)
    anim(4)
    moveForward(3, 0.5)
  else
    turnTo("@p")
    anim(0)
  end
end

]])
            code_component.Name = code_component_name;
            movieclip_component.Name = movieclip_component_name;
            return node, code_component, movieclip_component;
        end
    else
        code_component = node:getComponentByName(code_component_name);
        movieclip_component = node:getComponentByName(movieclip_component_name);
        return node, code_component, movieclip_component;
    end
end
function Editor:createBlockCodeNode(parent, name)
    parent = parent or self.Scene.RootNode;
    local position_code, position_movieclip = self.pair_block_pos_allocation:getNextPairPosition();
    if(not position_code or not position_movieclip)then
        return
    end
    local node = SceneNode:new();
    node.Name = name;
    parent:addChild(node);
    
    local code_component = ComponentFactory.getComponent("CodeComponent"):new()
    code_component:setBlockPosition(position_code);
    node:addComponent(code_component);

    local movieclip_component = ComponentFactory.getComponent("MovieClipComponent"):new()
    movieclip_component:setBlockPosition(position_movieclip);
    node:addComponent(movieclip_component);

	GameLogic.GetFilters():add_filter("Editor.createBlockCodeNode", self, node);

    return node, code_component, movieclip_component;
end
function Editor:toJson()
    local object = {};
    object.Uid = self.Uid;
    object.Name = self.Name;
    if(self.Scene)then
        object.Scene = self.Scene:toJson();
    end
    return object;
end
