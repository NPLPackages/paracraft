--[[
Title: 
Author(s): Leio
Date: 2009/11/8
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/CreatorNodeProcessor.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/commonlib.lua");
NPL.load("(gl)script/ide/Display3D/SceneNodeProcessor.lua");
NPL.load("(gl)script/ide/Display3D/SceneManager.lua");
NPL.load("(gl)script/ide/Display3D/SceneNode.lua");

local CreatorNodeProcessor = commonlib.inherit(CommonCtrl.Display3D.SceneNodeProcessor, {
	canvas = nil,-- it is a SceneCanvas instance
	parent_canvas = nil, -- it is a HomeLandCanvas_New instance

}, function(o)
		
end)

commonlib.setfield("MyCompany.Aries.Creator.CreatorNodeProcessor",CreatorNodeProcessor);

function CreatorNodeProcessor:DoMouseDown(event)
	--commonlib.echo("===========DoMouseDown");
end
function CreatorNodeProcessor:DoMouseUp(event)
	--event.canReturn.value = false;--½Ø¶ÏÊó±êÊÂ¼þ
	--commonlib.echo("===========DoMouseUp");
	--commonlib.echo(event.msg);
end
function CreatorNodeProcessor:DoMouseMove(event)
	--commonlib.echo("===========DoMouseMove");
end
--[[
event.msg = {
  IsComboKeyPressed=false,
  IsMouseDown=false,
  MouseDragDist={ x=0, y=0 },
  dragDist=269,
  lastMouseDown={ x=782, y=488 },
  lastMouseUpButton="right",
  lastMouseUpTime=6699.6712684631,
  lastMouseUp_x=789,
  lastMouseUp_y=496,
  mouse_button="right",
  mouse_x=559,
  mouse_y=196,
  virtual_key=242,
  wndName="mouse_move" 
}
--]]
function CreatorNodeProcessor:DoMouseOver(event)
	
end
function CreatorNodeProcessor:DoMouseOut(event)
	
end
function CreatorNodeProcessor:DoChildSelected(event)
	
end
function CreatorNodeProcessor:DoChildUnSelected(event)
	
end
function CreatorNodeProcessor:DoMouseDown_Stage(event)
	commonlib.echo("===========DoMouseDown_Stage");
end
function CreatorNodeProcessor:DoMouseUp_Stage(event)
	commonlib.echo("===========DoMouseUp_Stage");
	event.canReturn.value = false;
end
function CreatorNodeProcessor:DoMouseMove_Stage(event)
	
end
