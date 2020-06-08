--[[
Title: TerrainBrush Task/Command
Author(s): LiXizhi
Date: 2016/7/16
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TerrainBrush/PaintBrushTask.lua");
local PaintBrushTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.PaintBrushTask");
local task = PaintBrushTask:new();
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TerrainBrush/TerrainBrushTask.lua");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local PaintBrushTask = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Tasks.TerrainBrushTask"), commonlib.gettable("MyCompany.Aries.Game.Tasks.PaintBrushTask"));

PaintBrushTask.default_toolname = "paint";
PaintBrushTask.last_blockid = 56;

PaintBrushTask.tools = {
    {name="paint", tooltip=L"添加随机地表, 按住Shift使用替换模式", icon="Texture/blocks/items/brush.png"},
	{name="flood_paint", tooltip=L"按住左键并拖动填充方块", icon="Texture/blocks/items/waterfeet.png"},
}

function PaintBrushTask:ctor()
end

function PaintBrushTask:ShowPage()
	NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
	local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
	local viewport = ViewportManager:GetSceneViewport();
	local parent = viewport:GetUIObject(true)

	local window = self:CreateGetToolWindow();
	window:Show({
		name="PaintBrushTask", 
		url="script/apps/Aries/Creator/Game/Tasks/TerrainBrush/PaintBrushTask.html",
		alignment="_ctb", left=0, top=-55, width = 256, height = 64, parent = parent
	});
end
