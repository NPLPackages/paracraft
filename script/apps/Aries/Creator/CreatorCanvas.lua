--[[
Title: CreatorCanvas
Author(s): Leio
Date: 2010/01/23
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/CreatorCanvas.lua");
local canvas = MyCompany.Aries.Creator.CreatorCanvas:new();
canvas:BuildNodes();
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/Display3D/SceneCanvas.lua");
NPL.load("(gl)script/ide/Display3D/SceneManager.lua");
NPL.load("(gl)script/ide/Display3D/SceneNode.lua");
NPL.load("(gl)script/apps/Aries/Creator/CreatorNodeProcessor.lua");
local CreatorCanvas = commonlib.inherit({
	
}, commonlib.gettable("MyCompany.Aries.Creator.CreatorCanvas"))

--constructor
function CreatorCanvas:ctor()
	local sceneManager = CommonCtrl.Display3D.SceneManager:new();
	local rootNode = CommonCtrl.Display3D.SceneNode:new{
		root_scene = sceneManager,
	}
	local canvas = CommonCtrl.Display3D.SceneCanvas:new{
		rootNode = rootNode,
		sceneManager = sceneManager,
	}
	local nodeProcessor = MyCompany.Aries.Creator.CreatorNodeProcessor:new{
		canvas = canvas,
		parent_canvas = self,
	};
	self.sceneManager = sceneManager;
	self.rootNode = rootNode;
	self.canvas = canvas;
	self.nodeProcessor = nodeProcessor;
	
	canvas:AddEventListener("mouse_over",CreatorCanvas.DoMouseOver,self);
	canvas:AddEventListener("mouse_out",CreatorCanvas.DoMouseOut,self);
	canvas:AddEventListener("mouse_down",CreatorCanvas.DoMouseDown,self);
	canvas:AddEventListener("mouse_up",CreatorCanvas.DoMouseUp,self);
	canvas:AddEventListener("mouse_move",CreatorCanvas.DoMouseMove,self);
	canvas:AddEventListener("stage_mouse_down",CreatorCanvas.DoMouseDown_Stage,self);
	canvas:AddEventListener("stage_mouse_up",CreatorCanvas.DoMouseUp_Stage,self);
	canvas:AddEventListener("stage_mouse_move",CreatorCanvas.DoMouseMove_Stage,self);
	canvas:AddEventListener("child_selected",CreatorCanvas.DoChildSelected,self);
	canvas:AddEventListener("child_unselected",CreatorCanvas.DoChildUnSelected,self);
end
function CreatorCanvas.DoMouseOver(self,event)
	self.nodeProcessor:DoMouseOver(event);
end
function CreatorCanvas.DoMouseOut(self,event)
	self.nodeProcessor:DoMouseOut(event);
end
function CreatorCanvas.DoMouseDown(self,event)
	self.nodeProcessor:DoMouseDown(event);
end
function CreatorCanvas.DoMouseUp(self,event)
	self.nodeProcessor:DoMouseUp(event);
end
function CreatorCanvas.DoMouseMove(self,event)
	self.nodeProcessor:DoMouseMove(event);
end
function CreatorCanvas.DoChildSelected(self,event)
	self.nodeProcessor:DoChildSelected(event);
end
function CreatorCanvas.DoChildUnSelected(self,event)
	self.nodeProcessor:DoChildUnSelected(event);
end
function CreatorCanvas.DoMouseDown_Stage(self,event)
	self.nodeProcessor:DoMouseDown_Stage(event);
end
function CreatorCanvas.DoMouseUp_Stage(self,event)
	self.nodeProcessor:DoMouseUp_Stage(event);
end
function CreatorCanvas.DoMouseMove_Stage(self,event)
	self.nodeProcessor:DoMouseMove_Stage(event);
end
function CreatorCanvas:BuildNodes()
	local k;
	local node;
	for k = 1, 10 do
		node = CommonCtrl.Display3D.SceneNode:new{
			x = 255,
			y = 0,
			z = 255 + k * 3,
			assetfile = "model/06props/shared/pops/muzhuang.x",
		};
		self.rootNode:AddChild(node);
	end
end