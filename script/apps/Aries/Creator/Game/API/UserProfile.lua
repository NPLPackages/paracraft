--[[
Title: User Profile Manager
Author(s): LiXizhi
Date: 2013/11/20
Desc:  API wrapper emulation networking api. but it is local db backed up. 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/API/UserProfile.lua");
local UserProfile = commonlib.gettable("MyCompany.Aries.Creator.Game.API.UserProfile");
local profile = UserProfile.GetUser();
profile:SaveToDB()
profile:GetEvents():AddEventListener("OnExpChanged", GoalTracker.OnExpChanged, GoalTracker, "GoalTracker");
profile:GetStat("blocks_created"):AddValue(1);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/API/UserStat.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/API/ExpTable.lua");
local ExpTable = commonlib.gettable("MyCompany.Aries.Creator.Game.API.ExpTable");
local UserStat = commonlib.gettable("MyCompany.Aries.Creator.Game.API.UserStat");

local UserProfile = commonlib.gettable("MyCompany.Aries.Creator.Game.API.UserProfile");

-- every 30 blocks will gain 5 exp and use up 1 stanima
local create_blocks_per_stanima = 30;
local exp_gain_per_stanima = 5;

-- mapping from nid to user profile
local users = {};

function UserProfile.OnInit()
	UserProfile.timer = UserProfile.timer or commonlib.Timer:new({callbackFunc = UserProfile.OnTimer});
	UserProfile.timer:Change(3000, 10000);
end

-- create get a user's profile. 
-- @param nid: nil for current user. 
function UserProfile.GetUser(nid)
	nid = tonumber(nid or System.User.nid) or 0;
	local user = users[nid];
	if(not user) then
		user = UserProfile:new({nid = nid});
		users[nid] = user;

		user:Init();
	end
	return user;
end


-- create a new profile. the profile's filename must not be nil. 
function UserProfile:new(o)
	o = o or {}; -- create object if user does not provide one
	
	setmetatable(o, self);
	self.__index = self;

	return o;
end

function UserProfile:Init()
	self.stats = self.stats or {};
	UserProfile.OnInit();
end

-- create a new user 
function UserProfile:InitNewUser()
	self.Name = "ParaEngineTest";
	self.Level = 0;	
	self.Exp = 0;
	self.Water = 30;
	self.MaxWater = 30;
	self.Stamina = 30;
	self.MaxStamina = 30;
		
	self.Feed = 0;
	self.Fertilizer = 0;
	self.Gold = 0;
	self.total_gold = 10;
	self.Money = 0;	
	self.BuildProgress = {};
end


-- sync basic information from local db
-- @param server: if nil, we will use the local server. 
function UserProfile:Login(server, callbackFunc)
	if(not self.has_signed) then
		self.is_local_server = true;

		self.nid = tonumber(self.nid) or System.User.nid or 0;
		LOG.std(nil, "info", "UserProfile", "UserLoginProcess for nid %d", self.nid);

		self:InitNewUser();

		self.Name = self:LoadData("Name", "Test");
		self.Exp = self:LoadData("Exp", 0);
		self.Level = ExpTable.GetLevel(self.Exp);
		self.Water = self:LoadData("Water", self.MaxWater);
		self.Stamina = self:LoadData("Stamina", self.MaxStamina);
		self.Feed = self:LoadData("Feed", 0);
		self.Fertilizer = self:LoadData("Fertilizer", 0);
		self.Gold = self:LoadData("Gold", 0);
		self.BuildProgress = self:LoadData("BuildProgress", {});
	end
	
	if(callbackFunc) then
		self.has_signed = true;
		callbackFunc({is_success=true});
	end
end

-- get events
function UserProfile:GetEvents()
	if(not self.events) then
		self.events = commonlib.EventSystem:new();
	end
	return self.events;
end

function UserProfile:GetName()
	return self.Name;
end

function UserProfile:GetLevel()
	return self.Level;
end

function UserProfile:GetWater()
	return self.Water;
end

function UserProfile:GetExp()
	return self.Exp;
end

function UserProfile:GetGold()
	return self.Gold;
end

function UserProfile:GetFeed()
	return self.Feed;
end

function UserProfile:GetStamina()
	return self.Stamina;
end

function UserProfile:GetFertilizer()
	return self.Fertilizer;
end

-- return the finished theme for the given theme_index
-- @param theme_index: the theme name or id. if nil, the entire self.BuildProgress is returned. 
-- @return may return nil if theme not found or not finished.
function UserProfile:GetBuildProgress(theme_index,category)
	if(category) then
		local category_ds = self.BuildProgress[category];
		if(category_ds) then
			if(theme_index) then
				local theme = category_ds[theme_index];
				if(theme) then
					return theme.count;
				end
			end
		end
	end	
end

function UserProfile:FinishBuilding(theme_index, task_index,category)
	local category_ds = self.BuildProgress[category];
	if(not category_ds) then
		category_ds = {};
		self.BuildProgress[category] = category_ds;
	end
	local theme = category_ds[theme_index];
	if(not theme) then
		theme = {};
		category_ds[theme_index] = theme;
	end
	if(task_index) then
		if(not theme.count or theme.count < task_index) then
			theme.count = task_index;
		end
	else
		theme.count = (theme.count or 0) + 1;
	end
	self:SaveData("BuildProgress", self.BuildProgress);
	self:GetEvents():DispatchEvent({type = "BuildProgressChanged", theme = theme_index, category = category, value = self.BuildProgress,});
end

-- @param theme_name: nil to reset all. 
function UserProfile:ResetBuildProgress(theme_index,category)
	if(category) then
		local category_ds = self.BuildProgress[category];
		if(category_ds) then
			if(theme_index) then
				local theme = category_ds[theme_index];
				if(theme) then
					if(theme.count) then
						theme.count = 0;
						self:SaveData("BuildProgress", self.BuildProgress);
					end
				end
			end
		end
	else
		self.BuildProgress = {};
		self:SaveData("BuildProgress", self.BuildProgress);
	end
end

-- automatically update level
function UserProfile:AddExp(value)
	self.Exp = self.Exp + value;
	if(self.Exp < 0) then
		self.Exp = 0;
	end
	self:SaveData("Exp", self.Exp);
	self:GetEvents():DispatchEvent({type = "OnExpChanged", value = self.Exp, delta=value});

	local level = ExpTable.GetLevel(self.Exp);
	if(self.Level ~= level) then
		self.Level = level;
		self:GetEvents():DispatchEvent({type = "OnLevelChanged", value = self.Level, });
	end
end

function UserProfile:SetTotalGold(value)
	self.total_gold = value;
end

function UserProfile:AddGold(value)
	self.Gold = self.Gold + value;
	if(self.Gold < 0) then
		self.Gold = 0;
	end
	self:SaveData("Gold", self.Gold);
	self:GetEvents():DispatchEvent({type = "OnGoldChanged", value = self.Gold, delta=value});
end

function UserProfile:AddWater(value)
	self.Water = self.Water + value;
	if(self.Water < 0) then
		self.Water = 0;
	end
	if(self.Water > self.MaxWater) then
		self.Water = self.MaxWater;
	end
	self:SaveData("Water", self.Water);
	self:GetEvents():DispatchEvent({type = "OnWaterChanged", value = self.Water, delta=value});
end

function UserProfile:AddStamina(value)
	self.Stamina = self.Stamina + value;
	if(self.Stamina < 0) then
		self.Stamina = 0;
	end
	if(self.Stamina > self.MaxStamina) then
		self.Stamina = self.MaxStamina;
	end
	self:SaveData("Stamina", self.Stamina);
	self:GetEvents():DispatchEvent({type = "OnStaminaChanged", value = self.Stamina, delta=value});
end

function UserProfile:AddCreateBlock(count)
	count = count or 1;
	local stat = self:GetStat("blocks_created");
	if(stat) then
		self.last_created_block = self.last_created_block or stat:GetValue();
		stat:AddValue(count);
		local cur_value = stat:GetValue();
		-- every 30 blocks will gain 5 exp
		if((cur_value - self.last_created_block ) > create_blocks_per_stanima) then
			self.last_created_block  = self.last_created_block + create_blocks_per_stanima;
			self:AddExp(exp_gain_per_stanima);
			self:AddStamina(-1);
		end
	end
end

-- save data
function UserProfile:SaveData(name, value, bIsGlobal)
	return self:SaveLocalData(name, value, bIsGlobal, true);
end

-- flush local data
function UserProfile:FlushLocalData()
	return self:SaveLocalData("last_save_time", (ParaGlobal.GetDateFormat("yyyy-M-d").." "..ParaGlobal.GetTimeFormat("H:mm:ss")));
end

-- save a name, value pair to local disk file per user in config/creator_profile.db
-- please note that if user changes computer, data is not preserved. 
-- This function is IO heavy, do not call it very frequently. 
-- @param name: this is a name (url) such as "AppName.FieldName". This function ensures that user nid is automatically encoded to name when saving to disk. 
-- @param value: it can be string, number or table. 
-- @param bIsGlobal: if true, we will save to database without appending current nid to the key. One can set this to true for data that is global to all users on the local computer. 
-- @param bDeferSave: if true, we will defer flushing to database. default to nil, where changes will be flushed to disk. 
-- @return true if succeed
function UserProfile:SaveLocalData(name, value, bIsGlobal, bDeferSave)
	local ls = System.localserver.CreateStore(nil, 3, "creator_profile");
	if(not ls) then
		return;
	end
	-- make url
	local url;
	if(not bIsGlobal) then
		url = NPL.EncodeURLQuery(name, {"nid", self.nid})
	else
		url = name;
	end
	
	-- make entry
	local item = {
		entry = System.localserver.WebCacheDB.EntryInfo:new({
			url = url,
		}),
		payload = System.localserver.WebCacheDB.PayloadInfo:new({
			status_code = System.localserver.HttpConstants.HTTP_OK,
			data = {value = value},
		}),
	}
	-- save to database entry
	local res = ls:PutItem(item, not bDeferSave);
	if(res) then 
		LOG.std("", "debug","UserProfile", "%s is saved to local server", tostring(url));
		return true;
	else	
		LOG.std("", "warn","UserProfile", "failed saving %s to local server", tostring(url))
	end
end

function UserProfile:LoadData(name, default_value, bIsGlobal)
	return self:LoadLocalData(name, default_value, bIsGlobal);
end

-- load a given value from local disk file. 
-- @param name: the key to retrieve the data
-- @param default_value: the default value if no value is stored
-- @return the value
function UserProfile:LoadLocalData(name, default_value, bIsGlobal)
	local ls = System.localserver.CreateStore(nil, 3, "creator_profile");
	if(not ls) then
		LOG.std(nil, "warn", "UserProfile", "UserProfile %s failed because db is not valid", name)
		return default_value;
	end
	local url;
	-- make url
	if(not bIsGlobal) then
		url = NPL.EncodeURLQuery(name, {"nid", self.nid})
	else
		url = name;
	end
	
	local item = ls:GetItem(url)
			
	if(item and item.entry and item.payload) then
		local output_msg = commonlib.LoadTableFromString(item.payload.data);
		if(output_msg) then
			return output_msg.value;
		end
	end
	return default_value;
end

-- get the stat object. 
function UserProfile:GetStat(name)
	local stat = self.stats[name];
	if(not stat) then
		stat = UserStat:new():Init(self, name, default_value);
		self.stats[name] = stat;
	end
	return stat;
end

-- save to database
function UserProfile:SaveToDB()
	-- TODO: everything is saved on call. 
	self:FlushLocalData();
end

-- called every 10 seconds. 
function UserProfile.OnTimer()
	local profile = UserProfile.GetUser();
	if(not profile) then
		return
	end
	if(profile.is_local_server) then
		profile:OnTimer_LocalServer()
	else
		-- TODO: poll the server for update. 
	end
end

-- only called for locally simulated server
-- all local server logics are here
function UserProfile:OnTimer_LocalServer()
	local cur_time = commonlib.TimerManager.GetCurrentTime();	

	-- recover 1 Stamina every 3 mins.
	if( (cur_time - (self.LastStaminaRecoverTime or 0)) > 180000 ) then
		self.LastStaminaRecoverTime = cur_time;
		if(self.Stamina < self.MaxStamina) then
			self:AddStamina(1);
		end
	end

	-- recover 10 Water every 30 mins.
	if( (cur_time - (self.LastWaterRecoverTime or 0)) > 1800000 ) then
		self.LastWaterRecoverTime = cur_time;
		if(self.Water < self.MaxWater) then
			self:AddWater(math.min(10,self.MaxWater-self.Water));
		end
	end
end
