--[[
Title: all global scene context used
Author(s): LiXizhi
Date: 2015/8/5
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/AllContext.lua");
local AllContext = commonlib.gettable("MyCompany.Aries.Game.AllContext");
AllContext:Init();
AllContext:GetContext("editor");
------------------------------------------------------------
]]
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local AllContext = commonlib.gettable("MyCompany.Aries.Game.AllContext");

local contexts;

-- init all scene context
function AllContext:Init()
	if(contexts) then
		return;
	end
	
	contexts = {};
	local context;
	NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/BaseContext.lua");
	local BaseContext = commonlib.gettable("MyCompany.Aries.Game.SceneContext.BaseContext");
	context = BaseContext:new():Register("base");
	contexts["base"] = context;

	NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/PlayContext.lua");
	local PlayContext = commonlib.gettable("MyCompany.Aries.Game.SceneContext.PlayContext");
	context = PlayContext:new():Register("play");
	contexts["play"] = context;

	NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/EditContext.lua");
	local EditContext = commonlib.gettable("MyCompany.Aries.Game.SceneContext.EditContext");
	context = EditContext:new():Register("edit");
	contexts["edit"] = context;

	NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/EditMovieContext.lua");
	local EditMovieContext = commonlib.gettable("MyCompany.Aries.Game.SceneContext.EditMovieContext");
	context = EditMovieContext:new():Register("movie");
	contexts["movie"] = context;
	
	NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/TutorialContext.lua");
	local TutorialContext = commonlib.gettable("MyCompany.Aries.Game.SceneContext.TutorialContext");
	context = TutorialContext:new():Register("tutorial");
	contexts["tutorial"] = context;

	NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/RedirectContext.lua");

	-- LOG.std(nil, "debug", "AllContext", "registering all context");
end

function AllContext:GetContext(name)
	return contexts[name];
end

