--[[
Title: ToolBar
Author(s): LiXizhi
Date: 2014/11/28
Desc: Referenced part of QToolBar interface in QT. 
The ToolBar class provides an abstract user interface ToolBar that can be inserted into tools.
In applications many common commands can be invoked via menus, toolbar buttons, and keyboard shortcuts. 
Since the user expects each command to be performed in the same way, regardless of the user interface used, 
it is useful to represent each command as an ToolBar.

Once a QToolBar has been created it should be added to the relevant menu and toolbar, 
then connected to the slot which will perform the ToolBar. 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tools/ToolBar.lua");
local ToolBar = commonlib.gettable("MyCompany.Aries.Game.Tools.ToolBar");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");

local ToolBar = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Tools.ToolBar"));

ToolBar:Property("Name", "ToolBar");
ToolBar:Property("Icon");
ToolBar:Property("Text");
ToolBar:Property("ToolTip");
ToolBar:Property("StatusTip");
ToolBar:Property("Shortcut");

function ToolBar:ctor()
end
