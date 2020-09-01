--[[
Title: 
Author(s): leio
Date: 2020/9/1
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldLoginAdapter.lua");
local ParaWorldLoginAdapter = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldLoginAdapter");
ParaWorldLoginAdapter:EnterWorld();

NOTE: 
How to config cmd line:
seeing script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua 
-------------------------------------------------------
]]
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local ParaWorldLoginAdapter = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldLoginAdapter");


ParaWorldLoginAdapter.ids = {
    ONLINE = { 18355, },
    STAGE = { 1192, },
    RELEASE = { 1192, },
    LOCAL = {},
}
function ParaWorldLoginAdapter.GetDefaultWorldID()
    local httpwrapper_version = HttpWrapper.GetDevVersion();
    local ids = ParaWorldLoginAdapter.ids[httpwrapper_version];
    if(ids)then
        local len = #ids;
        local index = math.random(len);
        local id = ids[index];
        return id;
    end
end
-- search a world id to login
function ParaWorldLoginAdapter:SearchWorldID(callback)
    keepwork.world.mylist({
    },function(err, msg, data)
        commonlib.echo("==========world.mylist");
        commonlib.echo(err);
        commonlib.echo(msg);
        commonlib.echo(data,true);
    end)
    local world_id = ParaWorldLoginAdapter.GetDefaultWorldID();
    if(callback)then
        callback(world_id);
    end
end
-- enter offline world
function ParaWorldLoginAdapter:EnterOfflineWorld()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Login/InternetLoadWorld.lua");
	local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld");
	InternetLoadWorld.ShowPage();
end
function ParaWorldLoginAdapter:EnterWorld()
    if(System.options.loginmode == "offline")then
        ParaWorldLoginAdapter:EnterOfflineWorld();
        return
    end

    ParaWorldLoginAdapter:SearchWorldID(function(world_id)
	    LOG.std(nil, "info", "ParaWorldLoginAdapter", " found world_id:%s", tostring(world_id));
        if(not world_id)then
            ParaWorldLoginAdapter:EnterOfflineWorld();
            return
        end
        local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
	    UserConsole:HandleWorldId(world_id, "force");
    end)
    
end
