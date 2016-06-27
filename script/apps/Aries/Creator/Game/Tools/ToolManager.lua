--[[
Title: Tool Manager
Author(s): LiXizhi
Date: 2014/11/25
Desc: a singleton class to load tool class on demand. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tools/ToolManager.lua");
local ToolManager = commonlib.gettable("MyCompany.Aries.Game.Tools.ToolManager");
local tool = ToolManager:GetTool(name);
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
NPL.load("(gl)script/ide/System/Core/Action.lua");
NPL.load("(gl)script/ide/System/Core/ActionGroup.lua");
local ActionGroup = commonlib.gettable("System.Core.ActionGroup");
local Action = commonlib.gettable("System.Core.Action");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local ToolManager = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Tools.ToolManager"));

ToolManager:Signal("SelectedToolChanged", function(tool) end);
ToolManager:Signal("StatusInfoChanged", function(strInfo) end);

function ToolManager:ctor()
	self.actionGroup = ActionGroup:new();
	self.actionGroup:SetExclusive(true);
	self.Connect(self.actionGroup, "triggered", self, "actionTriggered");
end

-- call this function to register a new tool. 
-- @return the tool actions. 
function ToolManager:RegisterTool(tool)
	local toolAction = Action:new();

	toolAction:SetData(tool);
	toolAction:SetCheckable(true);
	toolAction:SetToolTip(format("%s (%s)", tool:GetName(), tool:GetShortcut()));
	toolAction:SetEnabled(tool:IsEnabled());
	self.actionGroup:AddAction(toolAction);
	tool.Connect(tool, "EnabledChanged", self, "ToolEnabledChanged");
	return toolAction;
end

function ToolManager:ToolEnabledChanged()
end

-- public: select a tool by name or tool instance
-- @param tool_or_name: 
function ToolManager:SelectTool(tool)
	-- Refuse to select disabled tools
	if (tool and not tool:IsEnabled()) then 
		return;
	end
	
	if(tool) then
		for _, action in ipairs(self.actionGroup:actions()) do
			if (action:GetData() == tool) then
				action:trigger();
				return;
			end
		end
	end

	-- The given tool was not found. Don't select any tool.
	for _, action in ipairs(self.actionGroup:actions()) do
		action:SetChecked(false);
	end
	self:SetSelectedTool(nil);
	return tool;
end

function ToolManager:actionTriggered(action)
	self:SetSelectedTool(action:GetData());
end

function ToolManager:SetSelectedTool(tool)
	if(tool~=self.selectedTool) then
		if(self.selectedTool) then
			self.selectedTool:OnDeselect();
			self.Disconnect(self.selectedTool, "StatusInfoChanged", self, "StatusInfoChanged");
			self.selectedTool = nil;
		end

		if(tool) then
			self.selectedTool = tool;
			self.selectedTool:OnSelect();
			self.Connect(tool, "StatusInfoChanged", self, "StatusInfoChanged");
		end
		-- signal
		self:SelectedToolChanged(self.selectedTool);
	end
	return tool;
end

function ToolManager:GetCurrentTool()
	return self.selectedTool;
end
