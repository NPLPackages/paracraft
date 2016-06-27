--[[
Title: Share world to web
Author(s): LiXizhi
Date: 2013/5/31
Desc: share current world to web. 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GameMarket/ShareWorldToWeb.lua");
local ShareWorldToWeb = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.ShareWorldToWeb");
ShareWorldToWeb.ShowPage(nid, slot_id)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/main.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/WorldUploadPage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GameMarket/OtherPeopleWorlds.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/UrlHelper.lua");
local OtherPeopleWorlds = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.OtherPeopleWorlds");
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local WorldUploadPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.WorldUploadPage");
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local ShareWorldToWeb = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.ShareWorldToWeb");
local ItemManager = commonlib.gettable("Map3DSystem.Item.ItemManager");


ShareWorldToWeb.empty_records = {};

function ShareWorldToWeb.OnInit()
end

-- @param slot_id: if not nil, it will highlight a given world record
function ShareWorldToWeb.ShowPage(nid, slot_id)
	nid = nid or System.App.profiles.ProfileManager.GetNID();
	local is_self = (nid == System.App.profiles.ProfileManager.GetNID());

	local ItemManager = System.Item.ItemManager;
	if(not is_self) then
		local gsItem = ItemManager.GetGlobalStoreItemInMemory(WorldUploadPage.RecordGsid);
		local bag = gsItem.template.bagfamily;
		ItemManager.GetItemsInOPCBag(nid, bag, "ShareWorldToWeb", function(msg)
			ShareWorldToWeb.ShowPage_imp(nid, slot_id);
		end, "access plus 1 day");
	else
		ShareWorldToWeb.ShowPage_imp(nid, slot_id);
	end
end

function ShareWorldToWeb.GetWebUrl()
	return ShareWorldToWeb.url;
end

function ShareWorldToWeb.ShowPage_imp(nid, slot_id)
	local width, height = 400, 320;

	local url = format("script/apps/Aries/Creator/Game/GameMarket/ShareWorldToWeb.html?nid=%s", tostring(nid or 0));
	if(slot_id) then
		url = format("%s&slot_id=%d", url, slot_id);
	end

	local params = {visit_url=format("%s@%d", nid, slot_id or 1)}
	if(System.options.version == "kids") then
		-- TODO: make this url from ParaEngine.com
		local root_url = "http://haqi.61.com/";
		ShareWorldToWeb.url = Map3DSystem.localserver.UrlHelper.BuildURLQuery(root_url, params);
	else
		ShareWorldToWeb.url = "此功能暂未开放";
	end

	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = url, 
			name = "ShareWorldToWeb.ShowPage", 
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
		});
end

-- the OPC must have its bag fetched into memory before calling this function. 
function ShareWorldToWeb.LoadRecordData(nid)
	return OtherPeopleWorlds.LoadRecordData(nid);
end
