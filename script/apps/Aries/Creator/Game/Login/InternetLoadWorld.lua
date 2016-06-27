--[[
Title: InternetLoadWorld
Author(s): LiXizhi
Date: 2014/1/13
Desc:  The very first page shown to the user. It asks the user to create or load or download a game from game market. 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/InternetLoadWorld.lua");
local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld");
InternetLoadWorld.ShowPage(true)
InternetLoadWorld.LoadWorld(world);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/main.lua");
NPL.load("(gl)script/apps/Aries/Partners/PartnerPlatforms.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/RemoteWorld.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/RemoteServerList.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/WorldUploadPage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/TextureModPage.lua");
local TextureModPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.TextureModPage");
local WorldUploadPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.WorldUploadPage");
local RemoteServerList = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteServerList");
local RemoteWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteWorld");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local Platforms = commonlib.gettable("MyCompany.Aries.Partners.Platforms");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local MainLogin = commonlib.gettable("MyCompany.Aries.Game.MainLogin");
local InternetLoadWorld = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.InternetLoadWorld");
local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
local ItemManager = commonlib.gettable("Map3DSystem.Item.ItemManager");
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");


NPL.load("(gl)script/apps/Aries/Creator/Game/GameMarket/OtherPeopleWorlds.lua");
local OtherPeopleWorlds = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.OtherPeopleWorlds");

local page;


InternetLoadWorld.ServerPage_index = 1;
InternetLoadWorld.ServerPage_ds = {};
--local DefaultServerPage_ds = {
	--{text="推荐列表", name="recommend", ds=nil, url="http://www.paraengine.com/twiki/bin/view/CCWeb/RecommendedServerListData", },
	--{text="长篇电影", name="longfilm", ds=nil, url="http://www.paraengine.com/twiki/bin/view/CCWeb/RecommendedServerListData", },
	--{text="短篇电影", name="shortfilm", ds=nil, url="http://www.paraengine.com/twiki/bin/view/CCWeb/RecommendedServerListData", },
	--{text="教学电影", name="tutorial", ds=nil, url="http://www.paraengine.com/twiki/bin/view/CCWeb/RecommendedServerListData", },
	--{text="其他电影", name="other", ds=nil, url="http://www.paraengine.com/twiki/bin/view/CCWeb/RecommendedServerListData", },
--
    ----{text="推荐列表", name="recommended", ds=nil, url="http://www.paraengine.com/twiki/bin/view/CCWeb/RecommendedServerListData", },
    ----{text="Demo世界", name="myworld", ds=nil, url="http://www.paraengine.com/twiki/bin/view/CCWeb/DemoServerListData", },
--}

local is_testing = false;
if(is_testing) then
	InternetLoadWorld.ServerPage_ds[1].ds = {
		{text = "1001:1 默认内网", server="1001:1"},
		{text = "1001:2 默认内网", server="1001:2"},
		{text = "1003:1 Xizhi", server="1003:1"},
	}
end
InternetLoadWorld.selected_world_index = 1;

InternetLoadWorld.type_index = 1;

function InternetLoadWorld.OnInit()
	page = document:GetPageCtrl();
	InternetLoadWorld.changedName = false;
	InternetLoadWorld.changedQQ = false;
	InternetLoadWorld.OnStaticInit();
end

function InternetLoadWorld.OnStaticInit()
	if(InternetLoadWorld.inited) then
		return;
	end
	InternetLoadWorld.inited = true;

	InternetLoadWorld.type_world = {
		{text=L"我的世界", name="mine",  enabled=true,},
		{text=L"官方推荐", name="official", enabled=true},
		--{text="热门世界", name="popular",  enabled=true},
		--{text="活动专区", name="activity",     enabled=true},
		}

	--WorldUploadPage.CheckLoadRecordGsid();
	InternetLoadWorld.type_ds = InternetLoadWorld.type_world;
	InternetLoadWorld.ds_collection = RemoteServerList.LoadAllServerListForUser();
	InternetLoadWorld.ServerPage_ds = InternetLoadWorld.ds_collection[InternetLoadWorld.type_index];

	--TextureModPage.DownloadOfficialTexturePack();
end

function InternetLoadWorld.ShowPage(bShow)
	System.App.Commands.Call("File.MCMLWindowFrame", {
		url = "script/apps/Aries/Creator/Game/Login/InternetLoadWorld.html", 
		name = "LoadMainWorld", 
		isShowTitleBar = false,
		DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
		style = CommonCtrl.WindowFrame.ContainerStyle,
		zorder = 0,
		allowDrag = false,
		bShow = bShow,
		directPosition = true,
			align = "_ct",
			x = -860/2,
			y = -470/2,
			width = 860,
			height = 470,
		cancelShowAnimation = true,
	});
	-- just refresh
	InternetLoadWorld.OnClose= function() 
		InternetLoadWorld.isSearching = false;
	end;
	InternetLoadWorld.OnChangeType(InternetLoadWorld.type_index,InternetLoadWorld.ServerPage_index);
	InternetLoadWorld.OnChangeServerPage(InternetLoadWorld.ServerPage_index);
	if(InternetLoadWorld.IsShowingLocalWorld()) then
		InternetLoadWorld.RefreshCurrentServerList();
	end
end



-- @param callbackFunc: callbackFunc(bSuccess)
function InternetLoadWorld.SwitchWorldServer(gs_nid, ws_id, callbackFunc)
	local rest_client = GameServer.rest.client;
	if(true) then
		local rest_client = GameServer.rest.client;
		Map3DSystem.GSL_client:LogoutServer();
		-- disconnect first
		Map3DSystem.GSL_client:Disconnect();
		--if(rest_client:get_current_server_nid() ~= gs_nid) then
			--GameServer.rest.client:disconnect();
		--end
		_guihelper.MessageBox(L"正在切换服务器请稍候", nil, _guihelper.MessageBoxButtons.Nothing);


		local function ConnectFail(reasonText)
			LOG.std(nil, "warn", "InternetLoadWorld", "failed to connect to %s", gs_nid);
			_guihelper.MessageBox(reasonText or L"无法连接这台服务器, 请试试其他服务器")
			if(callbackFunc) then
				callbackFunc(false);
			end
		end

		-- here we will wait 2 seconds before proceeding. 
		-- if target is on a different game server, diconnect old and connect to the new one and sign in using the same account. 
		local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
			GameServer.rest.client:connect({nid=gs_nid, world_id=ws_id,}, nil, function(msg) 
				if(msg.connected) then
					LOG.std(nil, "system", "ServerSelect", "connection with game server %s is established", gs_nid)
					
					-- authenticate again with the new game server using existing account. 
					paraworld.auth.AuthUser(System.User.last_login_msg or {username = tostring(System.User.username), password = System.User.Password,}, "login", function (msg)
						if(msg==nil) then
							ConnectFail(L"这台服务器无法认证, 请试试其他服务器");
						elseif(msg.issuccess) then	
							_guihelper.CloseMessageBox();
							if(callbackFunc) then
								callbackFunc(true);
							end
						else
							ConnectFail(L"服务器认证失败了, 请重新登录");
						end
					end, nil, 20000, function(msg)
						-- timeout request
						LOG.std(nil, "system", "ServerSelect", "Proc_Authentication timed out %s ", gs_nid)
						ConnectFail(L"用户验证超时了, 可能服务器太忙了, 或者您的网络质量不好.");
					end);
				else
					ConnectFail(L"无法连接这台服务器, 请试试其他服务器");
				end
			end)
		end})
		mytimer:Change(2000,nil);
	end
end

-- this is a public file
-- @param world: this is table containing {remotefile, url, etc}
-- @param homeserver_nid: nil or nid, we will run the instance in the home server of this nid.
-- @param refreshMode: nil|"auto"|"never"|"force".  
function InternetLoadWorld.LoadWorld(world, homeserver_nid, refreshMode)
	if( world.remotefile and world.remotefile:match("^local://")) then
		NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
		local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
		local worldpath = world.remotefile:gsub("^(local://)", "");
		WorldCommon.OpenWorld(worldpath, true)
		return;
	elseif(homeserver_nid) then
		-- home world
		local cur_svr_page = InternetLoadWorld.GetCurrentServerPage() or {};
		local params = {nid = cur_svr_page.player_nid, type="creativespace", world = world};
		OtherPeopleWorlds.OnHandleGotoHomeLandCmd(params);
		--System.App.Commands.Call("Profile.Aries.GotoHomeLand", {nid = cur_svr_page.player_nid, type="creativespace", world = world});
		return;
	end

	local name = world.text;
	local server = world.server or "";

	NPL.load("(gl)script/apps/Aries/Creator/Game/main.lua");
	local Game = commonlib.gettable("MyCompany.Aries.Game")

	local force_nid = world.force_nid;
	local gs_nid, ws_id = world.gs_nid, world.ws_id;

	if(not world.DownloadRemoteFile) then
		return;
	end
	world:DownloadRemoteFile(function(bSucceed, msg)
		if(bSucceed and world.worldpath) then
			if(page) then
				page:CloseWindow();
			end

			if(not gs_nid or not ws_id or System.User.nid == 0) then
				Game.Start(world.worldpath);
			else
				InternetLoadWorld.SwitchWorldServer(gs_nid, ws_id, function(bSuccess)
					if(bSuccess) then
						Game.Start(world.worldpath, nil, force_nid, gs_nid, ws_id);
					else
						InternetLoadWorld.ReturnLastStep();
					end
				end);
			end
		else
			_guihelper.MessageBox(msg);
		end
	end, refreshMode)	
end

function InternetLoadWorld.OnClickSelectedWorld()
	if(mouse_button == "right") then
		InternetLoadWorld.DeleteSelectedWorld();
	end
end

function InternetLoadWorld.RefreshAll()
	if(page) then
		page:Refresh(0.01);
	end
end

function InternetLoadWorld.IsShowingLocalWorld()
	if(InternetLoadWorld.type_index == 1 and InternetLoadWorld.ServerPage_index==1) then
		return true
	end
end

function InternetLoadWorld.DeleteSelectedWorld()
	local world = InternetLoadWorld:GetCurrentWorld();
	if(not world) then
		_guihelper.MessageBox(L"请先选择世界")
		return;
	end
	_guihelper.MessageBox(format(L"确定删除世界:%s?", world.text or ""), function(res)
		LOG.std(nil, "info", "InternetLoadWorld", "ask to delete world %s", world.text or "");
		if(res and res == _guihelper.DialogResult.Yes) then
			if(world.RemoveLocalFile and world:RemoveLocalFile()) then
				InternetLoadWorld.RefreshAll();
			elseif(world.remotefile) then
				-- local world, delete all files in folder and the folder itself.
				local targetDir = world.remotefile:gsub("^local://", "");
				if(GameLogic.RemoveWorldFileWatcher) then
					-- file watcher may make folder deletion of current world directory not working. 
					GameLogic.RemoveWorldFileWatcher();
				end
				if(commonlib.Files.DeleteFolder(targetDir)) then  
					LOG.std(nil, "info", "LocalLoadWorld", "world dir deleted: %s ", targetDir);
					InternetLoadWorld.RefreshCurrentServerList();
				else
					_guihelper.MessageBox(L"无法删除可能您没有足够的权限"); 
				end
			end
		end
	end, _guihelper.MessageBoxButtons.YesNo);
end

-- enter current selection. 
function InternetLoadWorld.EnterWorld(name)
	local world;
	if(not name or name == "") then
		world = InternetLoadWorld:GetCurrentWorld();
	else
		local index = tonumber(name);
		if(index) then
			world = InternetLoadWorld.cur_ds[index];
		end
	end
	if(not world) then
		_guihelper.MessageBox(L"请先选择世界")
		return;
	end
	local cur_svr_page = InternetLoadWorld.GetCurrentServerPage() or {};

	if(mouse_button == "left") then
		InternetLoadWorld.LoadWorld(world, cur_svr_page.player_nid);
	elseif(mouse_button == "right") then
		InternetLoadWorld.DeleteSelectedWorld();
	end
end

function InternetLoadWorld.OnClickOpenWiki()
    local serverPage = InternetLoadWorld.GetCurrentServerPage()
	if(serverPage and serverPage.url) then
		ParaGlobal.ShellExecute("open", serverPage.url, "", "", 1);
	end
end

function InternetLoadWorld.ReturnLastStep()
	if(page) then
		page:CloseWindow();
	end
    if(not GameLogic.IsStarted) then
        MainLogin:next_step({IsLoginModeSelected = false});
    end
end

function InternetLoadWorld.CreateNewWorld()
	page:CloseWindow();

	NPL.load("(gl)script/apps/Aries/Creator/Game/Login/CreateNewWorld.lua");
	local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")
	CreateNewWorld.ShowPage();
end


function InternetLoadWorld.OnChangeServerPage(index)
	if(System.options.loginmode == "local" and index and InternetLoadWorld.type_index == 1) then

		local ServerPage = InternetLoadWorld.ServerPage_ds[index or 1] or {};
		local url = ServerPage.url;
		if(url and string.match(url,"^%d+$") or string.match(url,"^online")) then
			_guihelper.MessageBox(L"只有登录后才能查看自己在线世界和他人世界。");
			return;
		end
	end
    InternetLoadWorld.ServerPage_index = index or InternetLoadWorld.ServerPage_index;
	InternetLoadWorld.cur_ds = InternetLoadWorld.GetCurrentServerPage().ds;
	InternetLoadWorld.selected_world_index = 1;
	local cur_svr = InternetLoadWorld.GetCurrentServerPage();
	cur_svr["addmark"] = false;
	if(page) then
		page:Refresh(0.01);
	end
end

function InternetLoadWorld.GetCurrentServerPage()
	return InternetLoadWorld.ServerPage_ds[InternetLoadWorld.ServerPage_index] or {};
end

function InternetLoadWorld:GetCurrentWorld()
	if(InternetLoadWorld.cur_ds) then
		return InternetLoadWorld.cur_ds[InternetLoadWorld.selected_world_index];
	end
end

function InternetLoadWorld:GetDownloadPercent(index)
	if(index) then
		local world = InternetLoadWorld.cur_ds[index];
		if(world and world.GetDownloadPercentage) then
			return world:GetDownloadPercentage();
		else
			return 100; -- maybe local world
		end
	end
	return -1;
end

local last_url;
function InternetLoadWorld.OnAddSearchPage()
	local url = page:GetValue("content","");
	
	NPL.load("(gl)script/apps/Aries/Creator/Game/Login/RemoteUrl.lua");
	local RemoteUrl = commonlib.gettable("MyCompany.Aries.Creator.Game.Login.RemoteUrl");
	local urlObj = RemoteUrl:new():Init(url);
	if(urlObj:IsRemoteServer()) then
		-- TODO: for Lipeng: add this to list as a remote server.
		LOG.std(nil, "debug", "OnAddSearchPage", {urlObj:GetHost(), urlObj:GetPort()});
		NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandManager.lua");
		local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
		CommandManager:Init()
		CommandManager:RunCommand("connect", urlObj:GetHost().." "..(urlObj:GetPort() or ""));
		return
	end
	
	url = url:gsub("^[^%dh]*", "");

	if(not url or url == "") then
		_guihelper.MessageBox(L"服务器地址不能为空")
	else
		if(RemoteServerList.IsUrlInList(InternetLoadWorld.ServerPage_ds, url)) then
			_guihelper.MessageBox(L"服务器列表中已存在该服务器");
		elseif(last_url ~= url) then
			last_url = url;

			local page = RemoteServerList:new():Init(url,nil, function(bSucceed, serverlist)
				if(serverlist:IsValid()) then
					local new_page = serverlist:SaveToTable();
					table.insert(InternetLoadWorld.ServerPage_ds,new_page);
					RemoteServerList.SaveAllServerListForUser(InternetLoadWorld.ServerPage_ds);
					InternetLoadWorld.OnChangeServerPage(#(InternetLoadWorld.ServerPage_ds));
				else
					_guihelper.MessageBox(L"无法打开服务器页面");
				end
			end);
			if(not page) then
				_guihelper.MessageBox(L"请输入合法的HTTP地址或用户ID");
			end		
		end
	end
end

function InternetLoadWorld.Refresh()
	if(page) then
		page:Refresh(0.01);
	end
end

function InternetLoadWorld.DeleteSvr()
	local index = InternetLoadWorld.ServerPage_index;
	local del_svr = InternetLoadWorld.GetCurrentServerPage();
	table.remove(InternetLoadWorld.ServerPage_ds,index);
	--local node = page:GetNode("gwSvrPageList");
	--pe_gridview.DataBind(node, "gwSvrPageList", false);
	--_guihelper.MessageBox(string.format("服务器【%s】已从服务器列表删除",del_svr["remark"] or del_svr["text"]));
	RemoteServerList.SaveAllServerListForUser(InternetLoadWorld.ServerPage_ds);
	InternetLoadWorld.Refresh();
end

function InternetLoadWorld.RenameSvr()
	local cur_svr = InternetLoadWorld.GetCurrentServerPage();
	cur_svr.addmark = true;
	local node = page:GetNode("gwSvrPageList");
	pe_gridview.DataBind(node, "gwSvrPageList", false);
end

function InternetLoadWorld.SaveSvrMark()
	local cur_svr = InternetLoadWorld.GetCurrentServerPage();
	local svr_remark_obj = ParaUI.GetUIObject("svr_remark_obj");
	
	cur_svr.text = svr_remark_obj.text;

	cur_svr.addmark = false;
	local node = page:GetNode("gwSvrPageList");
	pe_gridview.DataBind(node, "gwSvrPageList", false);
	RemoteServerList.SaveAllServerListForUser(InternetLoadWorld.ServerPage_ds);
end

function InternetLoadWorld.GetIconByName(name, seed)
	return "Texture/blocks/items/grassdirt.png"
end

function InternetLoadWorld.DS_Func_ServerPages(index)
	if(index) then
		return InternetLoadWorld.ServerPage_ds[index];
	else
		return #InternetLoadWorld.ServerPage_ds;
	end
end

function InternetLoadWorld.DS_Func_Worlds(index)
	if(InternetLoadWorld.cur_ds) then
		if(not index) then
			return #(InternetLoadWorld.cur_ds);
		else
			return InternetLoadWorld.cur_ds[index];
		end
	else
		local ServerPage = InternetLoadWorld.GetCurrentServerPage();
		if(not ServerPage.isFetching) then
			InternetLoadWorld.FetchServerPage(ServerPage);
		end
	end
end

function InternetLoadWorld.DownLoadWorld(name, mcmlNode)
	local index = tonumber(name);
	local world = (InternetLoadWorld.cur_ds)[index];
	if(not world.DownloadRemoteFile) then
		return;
	end
	local ui_obj = mcmlNode:GetControl();
	if(ui_obj) then
		ui_obj:SetText(L"下载中");
	end
	world:DownloadRemoteFile(function(bSucceed, msg)
		if(bSucceed and world.worldpath) then
			if(page) then
				page:Refresh(0.01);
			end		
		else
			_guihelper.MessageBox(msg);
		end
	end)
end

function InternetLoadWorld.FetchServerPage(ServerPage)
	if(not ServerPage.isFetching) then
		ServerPage.isFetching = true;
		-- fetching from url. 
		local url = ServerPage.url;
		if(url == "online") then
			url = ServerPage.player_nid;
		end	
		RemoteServerList:new():Init(url, ServerPage.name, function(bSucceed, serverlist)
			ServerPage.isFetching = false;
			if(not serverlist:IsValid()) then
				BroadcastHelper.PushLabel({id="userworlddownload", label = L"无法下载服务器列表, 请检查网络连接", max_duration=10000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
			end
			ServerPage.ds = serverlist.worlds or {};
			-- refresh page when ds is ready
			InternetLoadWorld.OnChangeServerPage();
		end);
	end
end

-- update again from the remote server
function InternetLoadWorld.RefreshCurrentServerList()
	local ServerPage = InternetLoadWorld.GetCurrentServerPage();
	if(not ServerPage.isFetching) then
		InternetLoadWorld.FetchServerPage(ServerPage);
	end
end

function InternetLoadWorld.OnSwitchWorld(index)
	-- clear the last world selected status
	InternetLoadWorld.selected_world_index = index or 1;
	InternetLoadWorld.Refresh();
end

function InternetLoadWorld.SvrMoveUp()
	local index = InternetLoadWorld.ServerPage_index
	if(index <= 2) then
		--_guihelper.MessageBox("该服务器已经在第一位了");
		return;
	end
	InternetLoadWorld.SvrChangePosition(index,index-1);
end

function InternetLoadWorld.SvrMoveDown()
	local svr_num = table.getn(InternetLoadWorld.ServerPage_ds);
	local index = InternetLoadWorld.ServerPage_index
	if(index >= svr_num) then
		--_guihelper.MessageBox("该服务器已经在最后一位了");
		return;
	end
	InternetLoadWorld.SvrChangePosition(index,index+1);
end

function InternetLoadWorld.SvrChangePosition(fromindex,toindex)
	InternetLoadWorld.ServerPage_index = toindex;
	local svr = InternetLoadWorld.ServerPage_ds[fromindex];
	InternetLoadWorld.ServerPage_ds[fromindex] = InternetLoadWorld.ServerPage_ds[toindex];
	InternetLoadWorld.ServerPage_ds[toindex] = svr;
	InternetLoadWorld.Refresh()
end

function InternetLoadWorld.OnChangeType(type_index,ServerPage_index,bRefreshPage)
	if(type_index and (type_index == 3 or type_index == 4) and System.options.loginmode == "local") then
		_guihelper.MessageBox(L"暂未开放敬请期待");
		return;
	end
	InternetLoadWorld.type_index = type_index or InternetLoadWorld.type_index;
	InternetLoadWorld.ServerPage_index = ServerPage_index or 1;

	InternetLoadWorld.ServerPage_ds = InternetLoadWorld.ds_collection[InternetLoadWorld.type_index];
	InternetLoadWorld.cur_ds = InternetLoadWorld.GetCurrentServerPage().ds;
	InternetLoadWorld.selected_world_index = 1;
	if(bRefreshPage~=false and page) then
		page:Refresh(0.01);
	end
end

function InternetLoadWorld.OnSaveToSlot(slot_id)
	local worldpath = ParaWorld.GetWorldDirectory();
	if(worldpath == "_emptyworld/") then
		_guihelper.MessageBox(L"你还没有登录世界 不能进行上传");
		return;
	end
	NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/WorldUploadPage.lua");
	local WorldUploadPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.WorldUploadPage");
	WorldUploadPage.ClickOncePublish(slot_id,function()
		local ServerPage = InternetLoadWorld.GetCurrentServerPage();
		ServerPage.isFetching = false;
		InternetLoadWorld.FetchServerPage(ServerPage);
	end);
	
end

function InternetLoadWorld.GetLocalWorldByWorldName(worldname)
	local local_world_list = (InternetLoadWorld.ds_collection)[1][1]["ds"] or {};
	for i = 1,#local_world_list do
		local world = local_world_list[i];
		local foldername = world.foldername;
		if(foldername and foldername == worldname) then
			return world;
		end
	end
	return;
end

function InternetLoadWorld.OnCopyFormSlot()
	--local user_world_zip_dir = "worlds/DesignHouse/userworlds/";
	local world = InternetLoadWorld:GetCurrentWorld();
	if(not world) then
		_guihelper.MessageBox(L"请先选择世界")
		return;
	end
	local cur_svr_page = InternetLoadWorld.GetCurrentServerPage() or {};

	--InternetLoadWorld.LoadWorld(world, cur_svr_page.player_nid);
	local nid = cur_svr_page.player_nid;
	if(tonumber(nid) ~= System.User.nid) then
		_guihelper.MessageBox(L"不能把别人的世界备份到本地。")
		return;
	end

	local worldname = world.worldname;
	local localworld = InternetLoadWorld.GetLocalWorldByWorldName(worldname);
	if(localworld) then
		local record_date = world.save_date or string.match(world.date,"^([^_]*)_%d+$");
		local words = string.format(L"本地已存在该世界。你确定要用服务器版本：%s【最后保存时间：%s】覆盖本地版本：%s【最后保存时间：%s】吗？",worldname,record_date,worldname,localworld.revision);
		_guihelper.MessageBox(words,function(result)
			if(result and result == _guihelper.DialogResult.Yes) then
				InternetLoadWorld.GenerateWorldFileAccordingOnlineRecord(world);
			end
		end,_guihelper.MessageBoxButtons.YesNo);
	else
		InternetLoadWorld.GenerateWorldFileAccordingOnlineRecord(world);
	end
end

function InternetLoadWorld.GenerateWorldFileAccordingOnlineRecord(world)
	local nid = System.User.nid;
	local dest = format("worlds/DesignHouse/userworlds/%s_%d_%d.zip", tostring(nid), world.slot_id, world.revision);
	local zipPath = dest;
	local tarPath = "worlds/DesignHouse/";
	local zipFolderName = world.worldname;
	if(ParaIO.DoesFileExist(dest)) then
		InternetLoadWorld.ExtractFile(zipPath, tarPath, nil, zipFolderName)
		return;
	end

	local ls = Map3DSystem.localserver.CreateStore(nil, 1);
	if(not ls) then
		return 
	end

	local src = world.url;

	BroadcastHelper.PushLabel({id="userworlddownload", label = format(L"世界%s: 正在下载中,请耐心等待", world.worldname), max_duration=20000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
	ls:GetFile(Map3DSystem.localserver.CachePolicy:new("access plus 5 mins"),
		src,
		function (entry)
			if(ParaIO.CopyFile(entry.payload.cached_filepath, dest, true)) then
				--  download complete
				LOG.std(nil, "info", "OtherPeopleWorlds", "successfully downloaded file from %s to %s", src, dest);
				--OnLoadWorld(dest);
				InternetLoadWorld.ExtractFile(zipPath, tarPath, nil, zipFolderName)
			else
				LOG.std(nil, "info", "OtherPeopleWorlds", "failed file from %s to %s", src, dest);
			end	
		end,
		nil,
		function (msg, url)
			local text;
			if(msg.DownloadState == "") then
				text = L"下载中..."
				if(msg.totalFileSize) then
					text = string.format(L"下载中: %d/%dKB", math.floor(msg.currentFileSize/1024), math.floor(msg.totalFileSize/1024));
				end
			elseif(msg.DownloadState == "complete") then
				text = L"下载完毕";
			elseif(msg.DownloadState == "terminated") then
				text = L"下载终止了";
			end
			if(text) then
				BroadcastHelper.PushLabel({id="userworlddownload", label = format(L"世界%s: %s", world.worldname, text), max_duration=10000, color = "255 0 0", scaling=1.1, bold=true, shadow=true,});
			end	
		end
	);
end

function InternetLoadWorld.ResetDataSource()
	InternetLoadWorld.ds_collection = RemoteServerList.LoadAllServerListForUser();
	for i = 1,#(InternetLoadWorld.ds_collection) do
		local svrPageDS = InternetLoadWorld.ds_collection[i];
		for j = 1,#svrPageDS do
			local svr_page = svrPageDS[j];
			svr_page.isFetching = false;
		end
	end
	InternetLoadWorld.ServerPage_ds = InternetLoadWorld.ds_collection[InternetLoadWorld.type_index];
	InternetLoadWorld.cur_ds = InternetLoadWorld.GetCurrentServerPage().ds;
	InternetLoadWorld.Refresh();
end

function InternetLoadWorld.QQLogin()
	--_guihelper.MessageBox("暂停使用 谢谢关注");
	--return;
	System.options.loginmode = "internet";	
	MyCompany.Aries.Game.MainLogin:user_login_next_step();
end

function InternetLoadWorld.ExtractFile(zipPath, tarPath, beCurDirectory, _zipFolderName)
	local zipFolderName;
	if(_zipFolderName) then
		zipFolderName = commonlib.Encoding.Utf8ToDefault(_zipFolderName);
	end
	local tar_parent_folder;
	local zip_parent_folder,zip_file_name = string.match(zipPath,"^(.*)/([^/]*)%.zip$");
	--local zip_file_name = string.match(zipPath,"^.*/[^/]*$");
	if(tarPath) then
		tar_parent_folder = tarPath;
	else
		if(beCurDirectory == nil or beCurDirectory) then
			tar_parent_folder = zip_parent_folder.."/";
		else
			return;
		end
	end

	if(zipFolderName) then
		--source_parent_folder = zip_parent_folder.."/"..zipFolderName.."/";
		tar_parent_folder = tar_parent_folder..zipFolderName.."/";
	else
		--source_parent_folder = zip_parent_folder.."/"..zip_file_name.."/";
		tar_parent_folder = tar_parent_folder..zip_file_name.."/";
	end

	ParaAsset.OpenArchive(zipPath, true);

	--local source_parent_folder = if_else(zipFolderName,zip_parent_folder..zipFolderName.."/",zip_parent_folder..zip_file_name.."/" )
	--tar_parent_folder = tar_parent_folder

	local function readFiles(sourceDir,targetDir,addBlockworld)
		ParaIO.CreateDirectory(targetDir);
		local filesout = {}
		commonlib.Files.SearchFiles(filesout, sourceDir, "*.*", 0, 1000, true, nil, "*.zip");
		if(next(filesout)) then
			for i = 1,#filesout do
				local filename = filesout[i];
				local source_filepath = sourceDir..filename;
				local target_filepath = targetDir..filename;
				ParaIO.CopyFile(source_filepath,target_filepath,true);
			end
		end
		local foldersout = {}
		commonlib.Files.SearchFiles(foldersout, sourceDir, "*.*", 0, 1000, nil, true, "*.zip");
		if(addBlockworld) then
			table.insert(foldersout,"blockWorld.lastsave/");
		end
		if(next(foldersout)) then
			for i = 1,#foldersout do
				local foldername = foldersout[i];
				local source_folderpath = sourceDir..foldername;
				local target_folderpath = targetDir..foldername;
				readFiles(source_folderpath,target_folderpath);
			end
		end

	end
	
	local zipFiles = {};
	commonlib.Files.SearchFiles(zipFiles, zip_parent_folder, "*.*", 0, 1000, nil, true, "*.zip");

	local source_parent_folder = zip_parent_folder.."/"..zipFiles[1];

	readFiles(source_parent_folder,tar_parent_folder,true)

	ParaAsset.CloseArchive(zipPath);
	_guihelper.MessageBox(L"下载完成")
end

local function DoesOnlineWorldExist(worldname)
	local first_empty_slot_index;
	local online_world_list = (InternetLoadWorld.ds_collection)[1][2]["ds"] or {};
	for i = 1,#online_world_list do
		local world = local_world_list[i];
		if(not first_empty_slot_index) then
			if(world.is_empty_slot) then
				first_empty_slot_index = i;
			end
		end
		if(world.worldname == worldname) then
			return i;
		end
	end
	return first_empty_slot_index or 1;
end

function InternetLoadWorld.ShowUploadPage(worldname)
	local onlineWorldIndex = DoesOnlineWorldExist(worldname);
	InternetLoadWorld.type_index = 1;
	InternetLoadWorld.ServerPage_index = 2;
	InternetLoadWorld.selected_world_index = onlineWorldIndex;

	InternetLoadWorld.ShowPage();
end

function InternetLoadWorld.ChangeNickName()
	local self = InternetLoadWorld;
	local nickname = page:GetValue("nickname","");
	if(System.User.NickName == nickname or not nickname) then
		if(page)then
			self.changedName = false;
			page:Refresh(0.1);
		end
		return;
	end
	nickname = string.gsub(nickname," ","");
	if(string.len(nickname) == 0)then
		_guihelper.MessageBox(L"名字不能全部为空");
		return
	end
	local count_charCN = math.floor((string.len(nickname) - ParaMisc.GetUnicodeCharNum(nickname))/2);
	local count_weight = ParaMisc.GetUnicodeCharNum(nickname) + count_charCN;
	
	local certified_nickname = MyCompany.Aries.Chat.BadWordFilter.FilterStringForUserName(nickname);
	if(certified_nickname ~= nickname) then
		_guihelper.MessageBox(format(L"你的昵称中包含非法语言:%s", certified_nickname));
		return;
	elseif(nickname == "") then
		_guihelper.MessageBox(L"你还没有名字呢 不能保存！");
		return
	elseif(count_weight > 16) then
		_guihelper.MessageBox(L"你的昵称太长了 请挑选一个短点的吧。");
		return
	end
	local function ChangeName_()
		commonlib.echo("=======before change name");
		commonlib.echo(nickname);
		paraworld.users.ChangeNickname({nname = nickname, }, "SetInfoInFullProfile", function(msg)
			commonlib.echo("=======after change name");
			commonlib.echo(msg);
			if(not msg)then return end
			if(msg.issuccess)then
				---- user name changed
				--local hook_msg = { aries_type = "UserNameChanged", changed_name = nickname, wndName = "main"};
				--CommonCtrl.os.hook.Invoke(CommonCtrl.os.hook.HookType.WH_CALLWNDPROCRET, 0, "Aries", hook_msg);
				---- auto refresh the user self info in memory
				--System.App.profiles.ProfileManager.GetUserInfo();
				---- send nickname update to chat channel
				--MyCompany.Aries.BBSChatWnd.SendUserNicknameUpdate();
				
				if(page)then
					--self.is_edit_name = nil;
					--page:SetValue("FullProfileUserName", nickname);
					--page:Refresh(0.1);
					System.User.NickName = nickname;
					self.changedName = false;
					page:Refresh(0.1);
				end
				--ItemManager.GetItemsInBag(0, "", function(msg)end, "access plus 0 minutes");
				_guihelper.MessageBox(L"改名成功");
			else
				if(msg.errorcode == 418)then
					_guihelper.MessageBox(L"这个名称已经存在 换一个其他的吧。");
				elseif(msg.errorcode == 443)then
					_guihelper.MessageBox(L"金币不足 修改名称失败");
				else
					_guihelper.MessageBox(format(L"暂时无法改名. 错误码%s", tostring(msg.errorcode)));
				end
			end
		end);
	end
	ChangeName_();
end