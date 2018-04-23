--[[
Title: 
Author(s): Leio
Date: 2008/9/3
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/minigame/paraworld.minigame.test.lua");
minigame.rank_test()
-------------------------------------------------------
]]
NPL.load("(gl)script/kids/3DMapSystemApp/API/minigame/paraworld.minigame.lua");

-- %TESTCASE{"SubmitRank", func = "paraworld.minigame.SubmitRank_Test", input ={gamename = "beats" ,score = 100}}%
function paraworld.minigame.SubmitRank_Test(input)
	local msg = {
		gamename = input.gamename,
		score = input.score,
	}
	paraworld.minigame.SubmitRank(msg,"minigame",function(msg)	
		log(commonlib.serialize(msg));
	end);
end
-- %TESTCASE{"GetRank", func = "paraworld.minigame.GetRank_Test", input ={gamename = "beats"}}%
function paraworld.minigame.GetRank_Test(input)
	local msg = {
		gamename = input.gamename,
	}
	paraworld.minigame.GetRank(msg,"minigame",function(msg)	
		log(commonlib.serialize(msg));
	end);
end