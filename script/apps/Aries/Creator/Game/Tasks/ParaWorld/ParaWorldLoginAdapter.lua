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
NPL.load("(gl)script/apps/Aries/Creator/Game/GameDesktop.lua");
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local MainLogin = commonlib.gettable("MyCompany.Aries.Game.MainLogin");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local ParaWorldLoginAdapter = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldLoginAdapter");

-- paraWorld
-- { id, name, objectId, objectType, cover, commitId, projectId ... }

-- projectId
ParaWorldLoginAdapter.MainWorldId = nil;
-- id
ParaWorldLoginAdapter.ParaWorldId = nil;

ParaWorldLoginAdapter.ids = {
    ONLINE = { 
        19759, -- paracraft 主城
        -- 18355, -- 精彩佛山
        --18626, --希望空间 
    },
    STAGE = { 1296, },
    RELEASE = { 
        1296, -- paracraft 主城
        -- 1192, -- 精彩佛山
        --1236, --希望空间
    },
    LOCAL = {
        1412, -- paracraft 主城
    },
}

ParaWorldLoginAdapter.campIds = {
    ONLINE = 41570,
    RELEASE = 1471,
}

ParaWorldLoginAdapter.SchoolWorldId = 20576;

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
    local http_env = HttpWrapper.GetDevVersion();
    if (System.User.isVipSchool) then
        if(callback)then
            callback(self.campIds[http_env]);
        end
        return;
    end
    --[[
        {
          {
            commitId="31d04",
            createdAt="2020-09-02T17:00:00.000Z",
            favorite=0,
            id=1,
            lastFavorite=0,
            lastStar=0,
            name="甯屾湜绌洪棿",
            objectId=272928,
            objectType="school",
            projectId=1236,
            regionId=1894,
            settleCount=0,
            star=0,
            status="audited",
            updatedAt="2020-09-02T17:00:00.000Z" 
          } 
        }
    ]]
    keepwork.world.mylist({
    },function(err, msg, data)
        local world_id = ParaWorldLoginAdapter.GetDefaultWorldID();
        if(err == 200)then
            -- the first item is right world
            if (data and data[1]) then
                local world_info = data[1];
                if (world_info.projectId and world_info.projectId ~= ParaWorldLoginAdapter.SchoolWorldId) then
                    world_id = world_info.projectId;
                end
            end
        end
        if(callback)then
            callback(world_id);
        end
    end)
    
end
-- enter offline world
function ParaWorldLoginAdapter:EnterOfflineWorld()
	ParaWorldLoginAdapter.MainWorldId = ParaWorldLoginAdapter.GetDefaultWorldID();
    NPL.load("(gl)script/apps/Aries/Creator/Game/Login/InternetLoadWorld.lua");
	local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld");
	InternetLoadWorld.ShowPage();
end
function ParaWorldLoginAdapter:EnterWorld(close)
	if (close) then
		if (not GameLogic.GetFilters():apply_filters('is_signed_in') and not GameLogic.GetFilters():apply_filters('store_get', 'user/token')) then
			Desktop.ForceExit(true);
		end
	end
    if(System.options.loginmode == "offline" and not GameLogic.GetFilters():apply_filters('is_signed_in'))then
        ParaWorldLoginAdapter:EnterOfflineWorld();
        return
    end
    if (not GameLogic.GetFilters():apply_filters('is_signed_in') and not GameLogic.GetFilters():apply_filters('store_get', 'user/token')) then
        GameLogic.GetFilters():apply_filters('login_with_token', function()
            ParaWorldLoginAdapter:EnterWorld();
        end)
		return;
    end
    
    ParaWorldLoginAdapter:SearchWorldID(function(world_id)
	    LOG.std(nil, "info", "ParaWorldLoginAdapter", " found world_id:%s", tostring(world_id));
        if(not world_id)then
            ParaWorldLoginAdapter:EnterOfflineWorld();
            return
        end
        ParaWorldLoginAdapter.MainWorldId = world_id;
        GameLogic.RunCommand(format('/loadworld -s -force -failed %d', world_id));
    end)
    
end

function ParaWorldLoginAdapter.ShowExitWorld(restart)
    local DockExitPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/DockExitPage.lua")
    DockExitPage.ShowPage(function()
        _guihelper.MessageBox(L"是否离开当前世界，返回登录界面？", function(res)
            if(res and res == _guihelper.DialogResult.Yes)then
                ParaWorldLoginAdapter.MainWorldId = nil;
                ParaWorldLoginAdapter.ParaWorldId = nil;
                Desktop.is_exiting = true;			
    
                GameLogic.GetFilters():apply_filters('logout', nil, function()
                    GameLogic.GetFilters():apply_filters("OnKeepWorkLogout", true);
                end);
    
                Desktop.ForceExit(restart);
            end
        end, _guihelper.MessageBoxButtons.YesNo);        
    end)    
end


function ParaWorldLoginAdapter.CheckAndReset()
	commonlib.TimerManager.SetTimeout(function()
		ParaWorldLoginAdapter.MainWorldId = ParaWorldLoginAdapter.GetDefaultWorldID();
		ParaWorldLoginAdapter.ParaWorldId = nil;
		local projectId = GameLogic.options:GetProjectId();
		keepwork.world.mylist(nil, function(err, msg, data)
			if (err == 200 and data) then
				for i = 1, #data do
					if (data[i].projectId == tonumber(projectId)) then
						ParaWorldLoginAdapter.MainWorldId = data[i].projectId;
						ParaWorldLoginAdapter.ParaWorldId = data[i].id;
						local ParaWorldSites = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldSites.lua");
						if (data[i].isFilling == 1) then
							ParaWorldSites.LoadAdvertisementWorld();
						end
						return;
					end
				end
			end

			keepwork.world.list(nil, function(err, msg, data)
				if (data and data.rows) then
					for i = 1, #(data.rows) do
						if (data.rows[i].projectId == tonumber(projectId)) then
							ParaWorldLoginAdapter.MainWorldId = data.rows[i].projectId;
							ParaWorldLoginAdapter.ParaWorldId = data.rows[i].id;
							local ParaWorldSites = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldSites.lua");
							if (data.rows[i].isFilling == 1) then
								ParaWorldSites.LoadAdvertisementWorld();
							end
							break;
						end
					end
				end
			end);
		end);
	end, 1000);
end