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
local SceneContextManager = commonlib.gettable("System.Core.SceneContextManager");
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

	NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/EditCodeBlockContext.lua");
	local EditCodeBlockContext = commonlib.gettable("MyCompany.Aries.Game.SceneContext.EditCodeBlockContext");
	context = EditCodeBlockContext:new():Register("code");
	contexts["code"] = context;

	NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/NullContext.lua");
	local NullContext = commonlib.gettable("MyCompany.Aries.Game.SceneContext.NullContext");
	context = NullContext:new():Register("null");
	contexts["null"] = context;

	NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/RolePlayMode/RolePlayMovieContext.lua");
	local RolePlayMovieContext = commonlib.gettable("MyCompany.Aries.Game.SceneContext.RolePlayMovieContext")
	context = RolePlayMovieContext:new():Register("roleplay");
	contexts["roleplay"] = context

	NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/RedirectContext.lua");

	-- LOG.std(nil, "debug", "AllContext", "registering all context");
end

function AllContext:GetContext(name)
    if(contexts)then
	    return contexts[name];
    end
end

-- set or replace the given context, if the context is currently selected, we will replace it and activate the new context
-- @return the last context
function AllContext:SetContext(name, context)
	local lastContext = self:GetContext(name)
	if(lastContext ~= context) then
		if(lastContext and lastContext == SceneContextManager:GetCurrentContext()) then
			if(not SceneContextManager:Select(context)) then
				return
			end
		end
		contexts[name] = context;
	end
	return lastContext;
end