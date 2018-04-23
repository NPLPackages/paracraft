--[[
Title: Power Item Service (A GSL module)
Author(s): Andy
Date: 2010/9/2
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemItem/PowerItemService.lua");
------------------------------------------------------------
]]
local PowerItemService = {};
PowerItemService.src = "script/kids/3DMapSystemItem/PowerItemService.lua";
Map3DSystem.GSL.system:AddService("PowerItemService", PowerItemService)

NPL.load("(gl)script/kids/3DMapSystemItem/PowerItemManager.lua");
NPL.load("(gl)script/kids/3DMapSystemItem/PowerExtendedCost.lua");
local PowerExtendedCost = commonlib.gettable("Map3DSystem.Item.PowerExtendedCost");
local tostring = tostring;
local PowerItemManager = commonlib.gettable("Map3DSystem.Item.PowerItemManager");
local PowerAPI_server = commonlib.gettable("Map3DSystem.GSL.PowerAPI_server");
local gateway = commonlib.gettable("Map3DSystem.GSL.gateway");

PowerItemService.state = "";

-- virtual: this function must be provided. This function will be called every frame move until it returns true. 
-- @param system: one can call system:GetService("module_name") to get other service for init dependency.
-- @return: true if loaded, otherwise this function will be called every tick until it returns true. 
function PowerItemService:Init(system)
	---- One can wait until some other modules have been loaded. 
	--local dependent_module = system:GetService("PowerItemService");
	--if(not dependent_module or not dependent_module:IsLoaded() ) then 
		--return 
	--end
	
	local options = Map3DSystem.GSL.config:FindModuleBySrc(self.src);
	if(options and options.version) then
		-- teen version is marked here
		PowerItemManager.version = options.version;
	end

	if(PowerItemService.state == "") then
		NPL.load("(gl)script/apps/Aries/GoldRankingList/ranking_server.lua");
		local RankingServer = commonlib.gettable("MyCompany.Aries.GoldRankingList.RankingServer");
		RankingServer.Init();

		-- One can register system events or events of other modules like this
		system:AddEventListener("OnUserDisconnect", self.OnUserDisconnect, self);
		system:AddEventListener("OnUserLoginWorld", self.OnUserLoginWorld, self);
		LOG.std(nil, "system", "PowerItemService", "PowerItemService is starting...");
		PowerItemService.state = "unloaded";
		PowerItemManager.Proc_GameServerLogin(function()
			LOG.std(nil, "system", "PowerItemService", "PowerItemService is loaded");
			PowerItemService.state = "loaded";
		end);

		self.timer = self.timer or commonlib.Timer:new({callbackFunc = function(timer)
			self:OnTimer(timer);
		end})
		self.timer:Change(100,300);
	end
	
	-- init excost
	PowerExtendedCost.LoadFromConfig();

	return self:IsLoaded();
	--return false;
end

function PowerItemService:OnTimer()
	if(PowerAPI_server.CheckInformBags) then
		PowerAPI_server.CheckInformBags();
	end
end

-- virtual: this function must be provided. 
function PowerItemService:IsLoaded()
	return PowerItemService.state == "loaded";
end

-- event callback: only called when TCP connection is closed
function PowerItemService:OnUserDisconnect(msg)
	-- proc user logout
	PowerItemManager.Proc_UserLogout(tonumber(msg.nid));
end

-- event callback: This will be called when user logins or switches different worlds during game play, hence it maybe called multiple times. 
function PowerItemService:OnUserLoginWorld(msg)
	LOG.std(nil, "system", "PowerItemService", "we see a user %s login a GSL world %s", msg.nid, tostring(msg.worldpath));

	local worldpath = tostring(msg.worldpath);
	
	local delay_reply = msg.delay_reply or {};
	delay_reply.pending_count = (delay_reply.pending_count or 0) + 1;
	msg.delay_reply = delay_reply;

	local function OnReply()
		-- One can delay sending the reply message by setting the delay_reply to msg;

		if(delay_reply.Func_DoQuestReply) then
			delay_reply.Func_DoQuestReply();
		end
		if(delay_reply.Func_DoCombatReply) then
			delay_reply.Func_DoCombatReply();
		end

		-- we only send out the reply after
		if(delay_reply.pending_count) then
			delay_reply.pending_count = delay_reply.pending_count - 1;
			if(delay_reply.pending_count == 0) then
				if(delay_reply.DoReply) then
					LOG.std(nil, "system", "PowerItemService", "finished with %s 's login procedure", msg.nid);
					delay_reply.DoReply();
				end
			end
		end
	end
	
	local bImmediate = true;
	local function Do_Proc_UserLoginfunction(msg)
		if(msg.issuccess == true) then
			LOG.std(nil, "system", "PowerItemService", "user login process complete\n");
			OnReply();
		elseif(msg.isskipped == true) then
			LOG.std(nil, "system", "PowerItemService", "user login process skipped due to mutiple login\n");
			OnReply();
		else
			LOG.std(nil, "error", "PowerItemService", "user login process encounter some error\n");
		end
	end
	-- proc user login
	PowerItemManager.Proc_UserLogin(tonumber(msg.nid), worldpath, function(msg)
		if(not bImmediate) then
			Do_Proc_UserLoginfunction(msg);
		else
			local mytimer = commonlib.Timer:new({callbackFunc = function()
				Do_Proc_UserLoginfunction(msg);
			end})
			mytimer:Change(10, nil);
		end
	end, function()
		LOG.std(nil, "error", "PowerItemService", "user login process fail\n");
	end);

	bImmediate = false;
end
