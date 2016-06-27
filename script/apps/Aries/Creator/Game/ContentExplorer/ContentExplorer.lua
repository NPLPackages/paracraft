--[[
Title: Content Explorer
Author(s): LiXizhi
Date: 2015/5/4
Desc: Like solution explorer in visual studio, it provides following ways to manage content in the current world. 
1. listing of named entities by category, such as waypoints, entities, templates, models, textures, sounds, custom items, etc. 
2. selection of a given block and listing of its child content
3. add/remove content from the world. 
4. misc per item functions like go to position, show property, etc. 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/ContentExplorer/ContentExplorer.lua");
local ContentExplorer = commonlib.gettable("Paracraft.IDE.ContentExplorer")
ContentExplorer:Show();
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Window.lua");
local ContentExplorer = commonlib.inherit(commonlib.gettable("System.Windows.Window"), commonlib.gettable("Paracraft.IDE.ContentExplorer"));

function ContentExplorer:ctor()
end