--[[
Title: game test page
Author(s): LiXizhi
Date: 2012/10/27
Desc:  script/apps/Aries/Creator/Game/Test/GameTestPage.html
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Test/GameTestPage.lua");
local GameTestPage = commonlib.gettable("MyCompany.Aries.Creator.Game.GameTestPage");
GameTestPage.ShowPage()
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Test/test_block_engine.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/block_engine.lua");
BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")

NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
GameLogic.Init();

local GameTestPage = commonlib.gettable("MyCompany.Aries.Creator.Game.GameTestPage");

function GameTestPage.OnInit()
	GameLogic.Init();
	BlockEngine:Connect();
end

function GameTestPage.ShowPage()
end