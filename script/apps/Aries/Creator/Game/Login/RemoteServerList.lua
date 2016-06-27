--[[
Title: RemoteServerList
Author(s): LiXizhi
Date: 2014/1/23
Desc: a wiki page containing description of server list (collection of remoteworld). 

---++ how values in html page is parsed. 
---+++ page
	###title=default title
	###pid=default portrait id
---+++ world
	href="filename#server=1000#text=text#revision=1#pid=1"

---++ example
	http://cc.paraengine.com/twiki/bin/view/CCWeb/PECraft

Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/RemoteServerList.lua");
local RemoteServerList = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteServerList");
RemoteServerList:new():Init(url, function(bSucceed, serverlist)
	if(serverlist:IsValid()) then
		echo(serverlist.text);
		echo(serverlist.icon);
		echo(serverlist.worlds);
	end
end);

echo(RemoteServerList.LoadAllServerListForUser());
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/API/FileDownloader.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/RemoteWorld.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/API/UserProfile.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/WorldUploadPage.lua");
local WorldUploadPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.WorldUploadPage");
local UserProfile = commonlib.gettable("MyCompany.Aries.Creator.Game.API.UserProfile");
local RemoteWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteWorld");
local FileDownloader = commonlib.gettable("MyCompany.Aries.Creator.Game.API.FileDownloader");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local ItemManager = commonlib.gettable("Map3DSystem.Item.ItemManager");

NPL.load("(gl)script/apps/Aries/Creator/Game/GameMarket/OtherPeopleWorlds.lua");
local OtherPeopleWorlds = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.OtherPeopleWorlds");

local RemoteServerList = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteServerList"));

function RemoteServerList:ctor()
	self:LoadFromTable(self);
end

-- @param url: web page containing the world server list information. or nid, or begins with "local"
-- @param callbackFunc: function (bSucceed, serverList) end
function RemoteServerList:Init(url, name, callbackFunc)
	self.url = url;
	self.name = name;
	self.callbackFunc = callbackFunc;
		
	if( string.match(url,"^http") ) then
		self:LoadFromHttpURL();
	elseif( string.match(url,"^%d+$") ) then
		self:LoadFromPlayerNid();
	elseif( string.match(url,"^local")) then
		self:LoadFromLocalDisk();
	elseif( string.match(url,"^online")) then
		self:LoadFromPlayerNid();
	else
		return;
	end
	return self;
end

function RemoteServerList:IsLocalDisk()
	if(string.match(self.url,"^local")) then
		return true;
	end
end

local portait_icons = {
	"Texture/blocks/Portait/Portait1.png", 
	"Texture/blocks/Portait/Portait2.png", 
	"Texture/blocks/Portait/Portait3.png", 
	"Texture/blocks/Portait/Portait4.png", 
	"Texture/blocks/Portait/Portait5.png", 
	"Texture/blocks/Portait/Portait6.png", 
	"Texture/blocks/Portait/Portait7.png", 
	"Texture/blocks/Portait/Portait8.png", 
	"Texture/blocks/Portait/Portait9.png", 
	"Texture/blocks/Portait/Portait10.png", 
	"Texture/blocks/Portait/Portait11.png", 
	"Texture/blocks/Portait/Portait12.png", 
};
local readonly_file_icon = "Texture/blocks/items/grassdirt.png";

-- @param text: number or string. 
function RemoteServerList:SetIconByText(text)
	local index
	if(type(text) == "string") then
		index = (mathlib.GetHash(text) % (#portait_icons)) + 1
	elseif(type(text) == "number") then
		index = text;
	end
	if(index) then
		self.icon = portait_icons[index];
	end
end

function RemoteServerList:IsValid()
	return self.is_valid;
end

function RemoteServerList:SaveToTable(node)
	node = node or {};
	node.url = self.url;
	node.icon = self.icon;
	node.text = self.text;
	node.pid = self.pid;
	node.player_nid = self.player_nid;
	return node;
end

function RemoteServerList:LoadFromTable(node)
	self.url = node.url;
	self.text = node.text;
	self.icon = node.icon;
	self.pid = node.pid;
	self.player_nid = node.player_nid;
	if(not self.icon and self.text) then
		self:SetIconByText(self.text);
	end
end



-- load from local world.
function RemoteServerList:LoadFromLocalDisk()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Login/LocalLoadWorld.lua");
	local LocalLoadWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.LocalLoadWorld")
	local dsWorlds = LocalLoadWorld.BuildLocalWorldList(true);
	local worlds = {};
	self.worlds = worlds;

	if(dsWorlds) then
		for i, world in ipairs(dsWorlds) do
			worlds[#worlds+1] = {
				server = "local",
				gs_nid = "",
				ws_id = "",
				remotefile = "local://"..world.worldpath,
				revision = world.writedate,
				tooltip = format("%s: %s", world.writedate or "", commonlib.Encoding.DefaultToUtf8(world.worldpath or "")),
				text = world.Title,
				author = world.nid or 0,
				icon = if_else(world.IsFolder, RemoteWorld.GetIconFromText(world.Title or ""), readonly_file_icon),
				force_nid = 0,
				world_mode = if_else(world.IsFolder, "edit", "game"),
				foldername = world.foldername,
				is_zip = (world.IsFolder==false),
			};
		end
	end
	self.is_valid = true;
	if(self.callbackFunc) then
		self.callbackFunc(true, self);
	end
end

-- in case url is nid
function RemoteServerList:LoadFromPlayerNid()
	local url = self.url;
	-- for user nid based URL. 
	self.player_nid = url;
	self.text = self.player_nid or "";
	local player_nid = tonumber(self.player_nid);
	if(player_nid and player_nid>0) then
		System.App.profiles.ProfileManager.GetUserInfo(player_nid, "UpdateUserInfo", function(msg)
				local user = msg.users[1]; 
				if(msg) then
					local nickname = user.nickname;
					self.text = nickname or url or "";

					NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/WorldUploadPage.lua");
					local WorldUploadPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.WorldUploadPage");
							
					local gsItem = ItemManager.GetGlobalStoreItemInMemory(WorldUploadPage.RecordGsid);
					if(gsItem) then
						local bag = gsItem.template.bagfamily;
						ItemManager.GetItemsInOPCBag(player_nid, bag, "OtherPeopleWorlds", function(msg)
							self:SetIconByText(self.text);
							
							if(self.player_nid) then
								local nid = self.player_nid;
								local worlds = self.GetPlayerWorldList(nid)
								self.worlds = worlds;
								self.is_valid = true;
								if(self.callbackFunc) then
									self.callbackFunc(true, self);
								end
								return;
							end
						end, "access plus 15 minutes");
					end

				end	
			end, "access plus 1 day");
	end
end

-- load all server list form HTTP url
function RemoteServerList:LoadFromHttpURL()
	local url = self.url;
	self.text = url:match("[^/]+$");	
	self:SetIconByText(self.text);
	if(not url:match("%?")) then
		url = format("%s?skin=plain", url);
	end
	NPL.load("(gl)script/kids/3DMapSystemApp/localserver/URLResourceStore.lua");

	local ls = System.localserver.CreateStore(nil, 3, "userdata");
	if(ls) then
		local mytimer;
		local function get_url_(retry_count)
			local res = ls:GetURL(System.localserver.CachePolicy:new("access plus 10 minutes"), url,
				function(msg)
					if(type(msg) == "table" and msg.rcode == 200) then
						self:LoadFromHTMLText(msg.data);
						-- flush it 
						ls:Flush();
					else
						self:LoadFromHTMLText(nil);
					end
				end);
			if(not res) then
				-- retry 5 times before give up. 
				if(retry_count < 5) then
					if(not mytimer) then
						mytimer = commonlib.Timer:new({callbackFunc = function(timer)
							get_url_(retry_count+1);
						end})
					end
					-- 1 second per time. 
					mytimer:Change(1000, nil);
				else
					self:LoadFromHTMLText(nil);
				end
			end
		end
		get_url_(0);
	end
end

-- obsoleted function: 
function RemoteServerList:LoadFromHttpURLByFile()
	local url = self.url;
	self.text = url:match("[^/]+$");	
	self:SetIconByText(self.text);
		
	self.FileDownloader = self.FileDownloader or FileDownloader:new();
	local url = self.url;
	if(not url:match("%?")) then
		url = format("%s?skin=plain", url);
	end
	self.FileDownloader:Init("服务器列表", url, nil, function(bSucceed, filename)
		local text;
		if(bSucceed and filename) then
			local src = ParaIO.open(filename, "r")
			if(src:IsValid()) then
				text = src:GetText();
				src:close();
			end
		end
		self:LoadFromHTMLText(text);
	end, "access plus 5 mins");
end

--[[ load from HTML text
search for href="..."
	href="filename#server=1000#text=text#revision=1#pid=1"
search for text:
	###title=Demo World			default title
	###pid=1					default portrait id
]]
local film_types = {
	["featurefilm"] = "longfilm",
	["microfilm"]	= "shortfilm",
	["tutorial"]	= "tutorial",
	["other"]		= "other",
};

function RemoteServerList:LoadFromHTMLText(text)
	local worlds = {};
	local bSucceed;
	if(text) then
		bSucceed = true;
		for href in text:gmatch('href%s*=%s*"([^"]+)"') do
			local worldserver = RemoteWorld.LoadFromHref(href);
			if(worldserver) then
				local meetCondition = true;
				local type,platform,recommend = string.match(worldserver.tag,"([^,]*),?([^,]*),?([^,]*),?");
				if(self.name == "recommend" and (not System.options.IsMobilePlatform)) then

				else
					if(film_types[type] ~= self.name and self.name ~= "recommend") then
						meetCondition = false;
					end
					if(platform == "pc" and System.options.IsMobilePlatform) then
						meetCondition = false;
					elseif(platform == "mobile") then
					
					end
					if(self.name == "recommend") then
						if(not recommend) then
							meetCondition = false;
						elseif(recommend ~= "recommend") then
							meetCondition = false;
						end
					end
				end
				if(meetCondition) then
					worlds[#worlds+1] = worldserver;
				end
			end
		end

		for name, value in text:gmatch('###(%w+)=([^<\r\n]+)') do
			LOG.std(nil, "debug", "RemoteServerList", "%s=%s", name, value);
			if(name == "title") then
				self.text = value;
			elseif(name == "pid") then
				-- portrait id. 
				self.pid = tonumber(value);
				self:SetIconByText(self.pid);
			end
		end
		self.is_valid = true;
	else
		bSucceed = false;
		self.is_valid = false;
	end
	self.worlds = worlds;
	if(self.callbackFunc) then
		self.callbackFunc(bSucceed, self);
	end
end

---------------------------------------------
-- server list 
---------------------------------------------

-- load all server list for current user 
function RemoteServerList.LoadAllServerListForUser()
	local ds = {};
	for i = 1,4 do
		local type_ds = {};
		if(i == 1) then
			local MyWorld_ds = {
				{text=L"本地世界", name="localworld", readonly=true, ds=nil, url="local", },
				{text=L"在线世界", name="onlineworld", readonly=true, ds=nil, url="online", },
			}
			
			local lists = UserProfile:LoadLocalData("ServerPage_ds", {}, false);
			for i = 1, #MyWorld_ds do
				local list = MyWorld_ds[i];
				if(list.url == "online") then					
					list.player_nid = System.User.nid;
				end
				--if(not RemoteServerList.IsUrlInList(lists, list.url)) then
				--end
				type_ds[#type_ds+1] = list;
			end
			for _, list in ipairs(lists) do
				if(list.url ~= "http://www.paraengine.com/twiki/bin/view/CCWeb/RecommendedServerListData" and list.url ~= "http://www.paraengine.com/twiki/bin/view/CCWeb/DemoServerListData" and list.url ~= "local" and list.url ~= "online") then
					type_ds[#type_ds+1] = list;
				end
			end

			for _, list in ipairs(type_ds) do
				list.isFetching = false;
				list = RemoteServerList:new(list);	
			end
		elseif(i == 2) then
			local DefaultServerPage_ds = {
				--{text="本地世界", name="localworld", readonly=true, ds=nil, url="local", },
				{text=L"推荐列表", name="recommend", readonly=true, ds=nil, url="http://www.paraengine.com/twiki/bin/view/CCWeb/RecommendedServerListData", },
				{text=L"长篇电影", name="longfilm", readonly=true, ds=nil, url="http://www.paraengine.com/twiki/bin/view/CCWeb/RecommendedServerListData", },
				{text=L"短篇电影", name="shortfilm", readonly=true, ds=nil, url="http://www.paraengine.com/twiki/bin/view/CCWeb/RecommendedServerListData", },
				{text=L"教学电影", name="tutorial", readonly=true, ds=nil, url="http://www.paraengine.com/twiki/bin/view/CCWeb/RecommendedServerListData", },
				{text=L"其他电影", name="other", readonly=true, ds=nil, url="http://www.paraengine.com/twiki/bin/view/CCWeb/RecommendedServerListData", },

				--{text="推荐列表", name="recommended", readonly=true, ds=nil, url="http://www.paraengine.com/twiki/bin/view/CCWeb/RecommendedServerListData", },
				--{text="Demo世界", name="myworld", readonly=true, ds=nil, url="http://www.paraengine.com/twiki/bin/view/CCWeb/DemoServerListData", },
			}

			for i = 1, #DefaultServerPage_ds do
				local list = DefaultServerPage_ds[i];
				type_ds[#type_ds+1] = list;
			end
			for _, list in ipairs(type_ds) do
				list.isFetching = false;
				list = RemoteServerList:new(list);	
			end
		end
		ds[i] = type_ds;
	end
	return ds;
end

-- 加载哈奇中玩家的分享的世界
function RemoteServerList.GetPlayerWorldList(nid)
	local is_self = (tonumber(nid) == tonumber(System.App.profiles.ProfileManager.GetNID()));
	local worlds = {};
	local save_records = OtherPeopleWorlds.LoadRecordData(nid);
	local save_slot_count = 0;
	if(is_self) then
		if(System.options.version == "teen") then
			WorldUploadPage.ExtendedSlotCountGsid = 17394;
		end

		local beHas,_,_,copies = ItemManager.IfOwnGSItem(WorldUploadPage.ExtendedSlotCountGsid);
		if(not beHas) then
			copies = 0;
		end
		if(System.options.mc) then
			WorldUploadPage.FreeSlotCount = 3;
		end
		save_slot_count = save_slot_count + WorldUploadPage.FreeSlotCount;
		if(copies > 0) then
			save_slot_count = save_slot_count + WorldUploadPage.FreeSlotCountBonus + copies;
		end
	end

	local i;
	for i = 1,#save_records do
		local record = save_records[i];
		local world = {};
		world.revision = record.revision;
		world.date = record.date;
		world.text = record.worldname;
		world.tooltip = string.format("存档日期：%s",record.date);
		world.not_pc_world = true;
		world.world_mode = "read";
		--world.world_mode = if_else(is_self,"edit","read");
		world.worldname = record.worldname;
		world.url = record.url;
		world.slot_id = record.slot_id;
		if(world.slot_id) then
			world.is_empty_slot = false;
			world.is_buy_slot = false;
			worlds[#worlds + 1] = world;
		else
			if(is_self) then
				world.is_empty_slot = true;
				world.is_buy_slot = false;
				worlds[#worlds + 1] = world;
			end
		end
	end
	if(is_self) then
		--NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/WorldUploadPage.lua");
		--local WorldUploadPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.WorldUploadPage");
		--if(System.options.version == "teen") then
			--WorldUploadPage.ExtendedSlotCountGsid = 17394;
		--end
--
		--local beHas,_,_,copies = ItemManager.IfOwnGSItem(WorldUploadPage.ExtendedSlotCountGsid);
		--if(not beHas) then
			--copies = 0;
		--end
		--local save_slot_count = 0;
		--save_slot_count = save_slot_count + WorldUploadPage.FreeSlotCount;
		--if(copies > 0) then
			--save_slot_count = save_slot_count + WorldUploadPage.FreeSlotCountBonus + copies;
		--end
		--local empty_slot_count = save_slot_count - #worlds;
		for i = 1,(save_slot_count - (#worlds)) do
			local world = {};
			world.is_empty_slot = true;
			world.is_buy_slot = false;
			world.slot_id = #worlds + 1;
			worlds[#worlds + 1] = world;
		end
		local world = {};
		world.is_empty_slot = false;
		world.is_buy_slot = true;
		worlds[#worlds + 1] = world;

	end
	return worlds;
end

-- whether a given url is inside the list. 
function RemoteServerList.IsUrlInList(ds, url)
	for _, list in ipairs(ds) do
		if(list.url == url) then
			return true;
		end
	end
end

function RemoteServerList.SaveAllServerListForUser(ds)
	local listData = {};
	for _, list in ipairs(ds) do
		listData[#listData+1] = {
			icon = list.icon,
			url = list.url,
			text = list.text,
			player_nid = list.player_nid,
		};
	end
	UserProfile:SaveLocalData("ServerPage_ds", listData, false);
end