--[[
Title: visit other people's world
Author(s): LiXizhi
Date: 2013/3/24
Desc: Player can visit other people's home land and creative space if any. 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GameMarket/OtherPeopleWorlds.lua");
local OtherPeopleWorlds = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.OtherPeopleWorlds");
OtherPeopleWorlds.OnHandleGotoHomeLandCmd(params);
OtherPeopleWorlds.ShowPage(nid, slot_id); -- set slot_id to 0 will hide home land
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/main.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/WorldUploadPage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GameMarket/EnterGamePage.lua");
local EnterGamePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.EnterGamePage");
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local WorldUploadPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.WorldUploadPage");
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local OtherPeopleWorlds = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.OtherPeopleWorlds");
local ItemManager = commonlib.gettable("Map3DSystem.Item.ItemManager");

OtherPeopleWorlds.save_records = {
    -- {worldname="AAAAA", type="save", date="2013/3/24"},
    {type="empty"},
    {type="empty"},
    {type="empty"},
    {type="empty"},
    {type="empty"},
    {type="empty"},
    {type="empty"},
    {type="empty"},
}

OtherPeopleWorlds.empty_records = {};

function OtherPeopleWorlds.OnInit()
end

-- @param slot_id: if not nil, it will highlight a given world record
function OtherPeopleWorlds.ShowPage(nid, slot_id, exclusive_mode)
	nid = tonumber(nid);
	slot_id = tonumber(slot_id);

	local is_self = not nid or (nid == System.App.profiles.ProfileManager.GetNID());

	local ItemManager = System.Item.ItemManager;
	if(not is_self) then
		local gsItem = ItemManager.GetGlobalStoreItemInMemory(WorldUploadPage.RecordGsid);
		if(gsItem) then
			local bag = gsItem.template.bagfamily;
			ItemManager.GetItemsInOPCBag(nid, bag, "OtherPeopleWorlds", function(msg)
				OtherPeopleWorlds.ShowPage_imp(nid, slot_id, exclusive_mode);
			end, "access plus 15 minutes");
		end
	else
		OtherPeopleWorlds.ShowPage_imp(nid, slot_id, exclusive_mode);
	end
end

-- @param slot_id: if 0 if it will hide old home land
-- @param exclusive_mode: if true, we will hide all GUI and then show this window
function OtherPeopleWorlds.ShowPage_imp(nid, slot_id, exclusive_mode)
	local width, height = 400, 320;

	local url = format("script/apps/Aries/Creator/Game/GameMarket/OtherPeopleWorlds.html?nid=%s", tostring(nid or 0));

	if(exclusive_mode) then
		MyCompany.Aries.Desktop.HideAllAreas();
	end

	OtherPeopleWorlds.last_slot_id = slot_id;
	if(slot_id) then
		url = format("%s&slot_id=%d", url, slot_id);
		EnterGamePage.ForceEnterBlockWorld = true;
	end

	local params = {
			url = url, 
			name = "OtherPeopleWorlds.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			bShow = true,
			zorder = 10,
			directPosition = true,
				align = "_ct",
				x = -width/2,
				y = -height/2,
				width = width,
				height = height,
	}
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	params._page.OnClose = function()
		if(OtherPeopleWorlds.last_slot_id) then
			EnterGamePage.ForceEnterBlockWorld = nil;
			OtherPeopleWorlds.last_slot_id = nil;
		end
		if(exclusive_mode) then
			MyCompany.Aries.Desktop.ShowAllAreas();
		end
	end
end

-- the OPC must have its bag fetched into memory before calling this function. 
function OtherPeopleWorlds.LoadRecordData(nid)
	nid = tonumber(nid);
	local bOwn, guid, bag, copies;
	local is_self = not nid or (nid == System.App.profiles.ProfileManager.GetNID());
	if(is_self) then
		bOwn, guid, bag, copies = ItemManager.IfOwnGSItem(WorldUploadPage.RecordGsid);	
	else
		bOwn, guid, bag, copies = ItemManager.IfOPCOwnGSItem(nid, WorldUploadPage.RecordGsid);
	end
	
	if(bOwn) then
		local item;
		if(is_self) then
			item = ItemManager.GetItemByGUID(guid);
		else
			item = ItemManager.GetOPCItemsByGUID(nid, guid);
		end

		if(item) then
			local clientdata;
			if(item.clientdata and item.clientdata~="") then
				LOG.std(nil, "debug", "OtherPeopleWorlds", item.clientdata);
				clientdata = NPL.LoadTableFromString(item.clientdata);
			end
			clientdata = clientdata or {};
			local save_records = {};
			local i, _;
			-- TODO: overriden and trust client data, this may be replaced by a robust server item count as in WorldUploadPage. 
			max_slot_id = 0; 
			for i, _ in pairs(clientdata) do
				if(i>max_slot_id) then
					max_slot_id = i;
				end	
			end
			copies = max_slot_id; 

			for i = 1, copies do
				local record = {};
				local record_svr = clientdata[i];
				record.type = "save";
				if(record_svr) then
					record.worldname = record_svr.worldname or "空";
					record.revision = record_svr.revision or 0;
					record.url = record_svr.url;
					record.date = record_svr.date;
					record.slot_id = i;
				else
					record.worldname = "空";
					record.revision = 0;
				end
				save_records[i] = record;
			end
			return save_records;
		end
	end
	return OtherPeopleWorlds.empty_records;
end

-- @param world: a table containing information of the world to enter
-- {index = number, date, worldpath, }
function OtherPeopleWorlds.EnterCreativeSpace(nid, world)
	-- enter creative space
	LOG.std(nil, "info", "OtherPeopleWorlds", "EnterCreativeSpace: %s", commonlib.serialize(world) or "");

	if(world and world.url and world.slot_id and world.revision) then
		
		local src = world.url;
		local dest = format("worlds/DesignHouse/userworlds/%s_%d_%d.zip", tostring(nid), world.slot_id, world.revision);

		local function OnLoadWorld(dest)
			NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
			local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
			WorldCommon.OpenWorld(dest, true);
		end

		if(ParaIO.DoesFileExist(dest)) then
			LOG.std(nil, "info", "OtherPeopleWorlds", "userworld %s already exist", src, dest);
			OnLoadWorld(dest);
			return;
		end

		local ls = Map3DSystem.localserver.CreateStore(nil, 1);
		if(not ls) then
			return 
		end
		BroadcastHelper.PushLabel({id="userworlddownload", label = format("世界%s: 正在下载中,请耐心等待", world.worldname), max_duration=20000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
		ls:GetFile(Map3DSystem.localserver.CachePolicy:new("access plus 5 mins"),
			src,
			function (entry)
				if(ParaIO.CopyFile(entry.payload.cached_filepath, dest, true)) then
					--  download complete
					LOG.std(nil, "info", "OtherPeopleWorlds", "successfully downloaded file from %s to %s", src, dest);
					OnLoadWorld(dest);
				else
					LOG.std(nil, "info", "OtherPeopleWorlds", "failed file from %s to %s", src, dest);
				end	
			end,
			nil,
			function (msg, url)
				local text;
				if(msg.DownloadState == "") then
					text = "下载中..."
					if(msg.totalFileSize) then
						text = string.format("下载中: %d/%dKB", math.floor(msg.currentFileSize/1024), math.floor(msg.totalFileSize/1024));
					end
				elseif(msg.DownloadState == "complete") then
					text = "下载完毕";
				elseif(msg.DownloadState == "terminated") then
					text = "下载终止了";
				end
				if(text) then
					BroadcastHelper.PushLabel({id="userworlddownload", label = format("世界%s: %s", world.worldname, text), max_duration=10000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
				end	
			end
		);
	end
end

function OtherPeopleWorlds.OnHandleGotoHomeLandCmd(params)
	NPL.load("(gl)script/kids/3DMapSystemUI/HomeLand/HomeLandGateway.lua");
	if(type(params) == "string") then
		local nid, slot_id = params:match("^(%d+)@?(.*)$");
		params = {nid = nid, slot_id=slot_id, };
	end
	local nid = params.nid;
	if(nid) then
		if( params.type == "homeland") then
			System.App.HomeLand.HomeLandGateway.Gohome(tonumber(nid));
		elseif( params.type == "creativespace") then
			OtherPeopleWorlds.EnterCreativeSpace(nid, params.world)
		else
			-- let the user select
			OtherPeopleWorlds.ShowPage(nid, params.slot_id, params.exclusive_mode);
		end
	else
		LOG.std(nil, "error", "OtherPeopleWorlds", "nil userid or nid specified in command call Profile.Aries.GotoHomeLand.");
	end
end