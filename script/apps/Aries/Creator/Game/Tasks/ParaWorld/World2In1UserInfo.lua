--[[
Title: paraworld user info panel
Author(s): chenjinxian
Date: 2020/11/18
Desc: 
use the lib:
------------------------------------------------------------
local World2In1UserInfo = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/World2In1UserInfo.lua");
World2In1UserInfo.ShowPage();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/World/generators/ParaWorldChunkGenerator.lua");
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.user.lua");
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.world.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local ParaWorldChunkGenerator = commonlib.gettable("MyCompany.Aries.Game.World.Generators.ParaWorldChunkGenerator");
local World2In1UserInfo = NPL.export();

local page;
local currentId;
local worldParams;
local isStared = false;
local starCount = 0;
local isFavorited= false;
local favoriteCount = 0;
local asset = "character/CC/02human/paperman/boy01.x";
local skin = nil;
local timer;

function World2In1UserInfo.OnInit()
	page = document:GetPageCtrl();
end

function World2In1UserInfo.ShowPage(world)
	worldParams = world;
	local bShow = (worldParams ~= nil) and (worldParams.userId ~= nil)
	if (page) then
		if (bShow and page:IsVisible()) then
			World2In1UserInfo.Refresh(worldParams.userId);
			return;
		end
		if ((not bShow) and (not page:IsVisible())) then
			return;
		end
	end
	
	local params = {
		url = "script/apps/Aries/Creator/Game/Tasks/ParaWorld/World2In1UserInfo.html",
		name = "World2In1UserInfo.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = false,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = false,
		bShow = bShow,
		enable_esc_key = false,
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		directPosition = true,
		align = "_lt",
		x = 20,
		y = 10,
		width = 310,
		height = 70,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	if (bShow) then
		World2In1UserInfo.Refresh(worldParams.userId);
	end
end

function World2In1UserInfo.Refresh(userId)
	if (userId == currentId) then
		return;
	end

	if (timer) then
		timer:Change(nil, nil)
		timer = nil;
	end

	local times = 0
	if worldParams == nil then
		return
	end
	timer = commonlib.Timer:new(
		{
			callbackFunc = function()
				if (times > 20) then
					GameLogic.GetFilters():apply_filters(
						"user_behavior",
						1,
						"click.world.visit_user_home",
						{
							homeUserId = worldParams.userId or 0,
							userHomeName = worldParams.projectName or '',
							userHomeProjectId = worldParams.projectId or 0
						}
					);

					timer:Change(nil, nil);
					return;
				end

				times = times + 1;
			end
		}
	)

	timer:Change(0, 1000)

	currentId = userId;
	page:Refresh(0);

	keepwork.world.detail({router_params = {id = worldParams.projectId}}, function(err, msg, data)
		if (data) then
			starCount = data.star or 0;
			favoriteCount = data.favorite or 0;
		end

		keepwork.world.is_stared({router_params = {id = worldParams.projectId}}, function(err, msg, data)
			if (err == 200) then
				isStared = data == true;
			end

			keepwork.world.is_favorited({objectId = worldParams.projectId, objectType = 5}, function(err, msg, data)
				if (err == 200) then
					isFavorited = data == true;
				end
				page:Refresh(0);

				local id = "kp"..commonlib.Encoding.base64(commonlib.Json.Encode({userId = userId}));
				keepwork.user.getinfo({router_params = {id = id}}, function(err, msg, data)
					if (data and data.extra and data.extra.ParacraftPlayerEntityInfo and data.extra.ParacraftPlayerEntityInfo.asset) then
						asset = data.extra.ParacraftPlayerEntityInfo.asset;
						skin = data.extra.ParacraftPlayerEntityInfo.skin;
					end
					page:CallMethod("UserPlayer", "SetAssetFile", asset);
					page:CallMethod("UserPlayer", "SetCustomGeosets", skin);
				end);
			end);
		end);
	end);
end

function World2In1UserInfo.GetProjectName()
	if (_guihelper.GetTextWidth(worldParams.projectName, "System;16") > 132) then
		if (string.find(worldParams.projectName, L"的家园") or string.find(worldParams.projectName, "_main")) then
			local text = commonlib.utf8.sub(worldParams.projectName, 1, 8);
			return string.format(L"%s...的家园", text);
		else
			return commonlib.utf8.sub(worldParams.projectName, 1, 8);
		end
	else
		return worldParams.projectName;
	end
end

function World2In1UserInfo.IsStared()
	return isStared;
end

function World2In1UserInfo.IsFavorited()
	return isFavorited;
end

function World2In1UserInfo.GetStarCount()
	return string.format("%d", starCount);
end

function World2In1UserInfo.GetFavoritesCount()
	return string.format("%d", favoriteCount);
end

function World2In1UserInfo.OnClickStar()
	keepwork.world.star({router_params = {id = worldParams.projectId}}, function(err, msg, data)
		if (err == 200) then
			isStared = true;
			starCount = starCount + 1;
			page:Refresh(0);
			page:CallMethod("UserPlayer", "SetAssetFile", asset);
			page:CallMethod("UserPlayer", "SetCustomGeosets", skin);

			GameLogic.QuestAction.SetDailyTaskValue("40012_1", nil, 1)
		end
	end);
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.home.thumbs_up");
end

function World2In1UserInfo.OnClickFavorite()
	keepwork.world.favorite({objectId = worldParams.projectId, objectType = 5}, function(err, msg, data)
		if (err == 200) then
			isFavorited = true;
			favoriteCount = favoriteCount + 1;
			page:Refresh(0);
			page:CallMethod("UserPlayer", "SetAssetFile", asset);
			page:CallMethod("UserPlayer", "SetCustomGeosets", skin);
		end
	end);
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.home.favorited");
end

function World2In1UserInfo.OnClickUnFavorite()
	keepwork.world.unfavorite({objectId = worldParams.projectId, objectType = 5}, function(err, msg, data)
		if (err == 200) then
			isFavorited = false;
			favoriteCount = favoriteCount - 1;
			page:Refresh(0);
			page:CallMethod("UserPlayer", "SetAssetFile", asset);
			page:CallMethod("UserPlayer", "SetCustomGeosets", skin);
		end
	end);
end

function World2In1UserInfo.OnClickUserInfo()
	local page = NPL.load("Mod/GeneralGameServerMod/App/ui/page.lua");
	page.ShowUserInfoPage({userId = currentId});
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.home.click_avatar");
end
