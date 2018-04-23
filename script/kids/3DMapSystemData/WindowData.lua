--[[
Title: window data to windows manager
Author(s): WangTian
Date: 2007/9/20
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemData/WindowData.lua");
------------------------------------------------------------
]]

commonlib.setfield("Map3DSystem.UI.Windows.Style", {})

Map3DSystem.UI.Windows.Style[1] = {
	frameBG = "Texture/3DMapSystem/WindowFrameStyle/1/frame.png: 4 25 4 24",
	topHeight = 24,
	bottomHeight = 24,
	leftBorderWidth = 4,
	rightBorderWidth = 4,
	min = "Texture/3DMapSystem/WindowFrameStyle/1/min.png; 0 0 20 20",
	max = "Texture/3DMapSystem/WindowFrameStyle/1/max.png; 0 0 20 20",
	autoHide = "Texture/3DMapSystem/WindowFrameStyle/1/autohide.png; 0 0 20 20",
	close = "Texture/3DMapSystem/WindowFrameStyle/1/close.png; 0 0 20 20",
	boxSize = 20,
	resizer = "Texture/3DMapSystem/WindowFrameStyle/1/resizer.png",
	resizerSize = 16,
	minPos = {-85, 2},
	maxPos = {-64, 2},
	autoHidePos = {-43, 2},
	closePos = {-22, 2},
	resizerPos = {-16, -16},
	textAlignment = "_mt",
	textPosXAdd = 10,
	textPosY = 5,
	};
	
Map3DSystem.UI.Windows.Style[2] = {
	frameBG = "Texture/3DMapSystem/WindowFrameStyle/2/frame2.png: 32 32 32 32",
	topHeight = 32,
	bottomHeight = 32,
	leftBorderWidth = 8,
	rightBorderWidth = 8,
	min = "Texture/3DMapSystem/WindowFrameStyle/2/min.png",
	max = "Texture/3DMapSystem/WindowFrameStyle/2/max.png",
	autoHide = "Texture/3DMapSystem/WindowFrameStyle/2/autohide.png",
	close = "Texture/3DMapSystem/WindowFrameStyle/2/close.png",
	boxSize = 16,
	resizer = "Texture/3DMapSystem/WindowFrameStyle/2/resizer.png",
	resizerSize = 16,
	minPos = {-90, 10},
	maxPos = {-70, 10},
	autoHidePos = {-50, 10},
	closePos = {-30, 10},
	resizerPos = {-16, -16},
	textAlignment = "_mt",
	textPosXAdd = 10,
	textPosY = 10,
	};

-- for chat main window
Map3DSystem.UI.Windows.Style[3] = {
	frameBG = "Texture/3DMapSystem/WindowFrameStyle/3/frame.png: 16 96 16 28",
	topHeight = 24,
	bottomHeight = 16,
	leftBorderWidth = 1,
	rightBorderWidth = 1,
	min = "Texture/3DMapSystem/WindowFrameStyle/3/min.png",
	max = "Texture/3DMapSystem/WindowFrameStyle/3/max.png",
	autoHide = "Texture/3DMapSystem/WindowFrameStyle/3/autohide.png",
	close = "Texture/3DMapSystem/WindowFrameStyle/3/close.png",
	boxSize = 16,
	resizer = "Texture/3DMapSystem/WindowFrameStyle/3/resizer.png",
	resizerSize = 16,
	minPos = {-85, 2},
	maxPos = {-64, 2},
	autoHidePos = {-43, 2},
	closePos = {-22, 2},
	resizerPos = {-16, -16},
	textAlignment = "_mt",
	textPosXAdd = 10,
	textPosY = 5,
	};
	
-- for chat conversation window
Map3DSystem.UI.Windows.Style[4] = {
	frameBG = "Texture/3DMapSystem/WindowFrameStyle/4/frame.png: 16 75 16 8",
	topHeight = 55,
	bottomHeight = 16,
	leftBorderWidth = 1,
	rightBorderWidth = 1,
	min = "Texture/3DMapSystem/WindowFrameStyle/4/min.png",
	max = "Texture/3DMapSystem/WindowFrameStyle/4/max.png",
	autoHide = "Texture/3DMapSystem/WindowFrameStyle/4/autohide.png",
	close = "Texture/3DMapSystem/WindowFrameStyle/4/close.png",
	boxSize = 16,
	resizer = "Texture/3DMapSystem/WindowFrameStyle/4/resizer.png",
	resizerSize = 16,
	minPos = {-85, 2},
	maxPos = {-64, 2},
	autoHidePos = {-43, 2},
	closePos = {-22, 2},
	resizerPos = {-16, -16},
	textAlignment = "_mt",
	textPosXAdd = 10,
	textPosY = 5,
	};

