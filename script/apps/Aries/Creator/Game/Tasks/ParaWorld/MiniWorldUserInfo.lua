--[[
Title: paraworld user info panel
Author(s): chenjinxian
Date: 2020/11/18
Desc: 
use the lib:
------------------------------------------------------------
local MiniWorldUserInfo = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/MiniWorldUserInfo.lua");
MiniWorldUserInfo.ShowPage();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.user.lua");
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.world.lua");
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local MiniWorldUserInfo = NPL.export();

local page;
local worldParams;
local currentId;
local isStared = false;
local starCount = 0;
local isFavorited= false;
local favoriteCount = 0;
local asset = "character/CC/02human/paperman/boy01.x";
local updatedAt;

function MiniWorldUserInfo.OnInit()
	page = document:GetPageCtrl();
end

function MiniWorldUserInfo.ShowInMiniWorld()
	local id = GameLogic.options:GetProjectId();
	id = tonumber(id);
	if (not id) then return end

	if (page) then
		page:CloseWindow();
	end

	keepwork.world.detail({router_params = {id = id}}, function(err, msg, data)
		if (data and data.userId) then
			local name = WorldCommon.GetWorldTag("name");
			local world = {projectName = name, projectId = id, userId = data.userId};
			MiniWorldUserInfo.ShowPage(world);
		end
	end);
end

function MiniWorldUserInfo.ShowPage(world)
	worldParams = world;
	local params = {
		url = "script/apps/Aries/Creator/Game/Tasks/ParaWorld/MiniWorldUserInfo.html",
		name = "MiniWorldUserInfo.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = false,
		bShow = true,
		enable_esc_key = false,
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		directPosition = true,
		align = "_lt",
		x = 20,
		y = 10,
		width = 305,
		height = 70,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	MiniWorldUserInfo.Refresh(worldParams.userId);
end

function MiniWorldUserInfo.Refresh(userId)
	currentId = userId;
	page:Refresh(0);

	keepwork.world.detail({router_params = {id = worldParams.projectId}}, function(err, msg, data)
		if (data) then
			starCount = data.star or 0;
			favoriteCount = data.favorite or 0;
			updatedAt = data.updatedAt;
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
					end
					page:CallMethod("UserPlayer", "SetAssetFile", asset);
				end);
			end);
		end);
	end);
end

function MiniWorldUserInfo.GetProjectName()
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

function MiniWorldUserInfo.GetUpdatedTime()
	function formatTime(datetime)
		local year,month,day,hour,min,sec = string.match(datetime, "(%d+)%D(%d+)%D(%d+)%D+(%d+)%D(%d+)%D(%d+)");
		local dateTime = string.format("%s-%s-%s %s:%s:%s", year,month,day,hour,min,sec);
		local date,time = commonlib.timehelp.GetLocalTime();
		local curDateTime = string.format("%s %s", date, string.gsub(time, "-", ":"));
		local day,hours,minutes,seconds,time_str = commonlib.GetTimeStr_BetweenToDate(curDateTime, dateTime);
		local year = math.floor(day / 365);
		local month = math.floor(day / 30);
		if (year > 0) then return tostring(year) .. L" 年前" end
		if (month > 0) then return tostring(month) .. L" 月前" end
		if (day > 0) then return tostring(day) .. L" 天前" end
		if (hours > 0) then return tostring(hours) .. L" 小时前" end 
		if (minutes > 0) then return tostring(minutes) .. L" 分钟前" end 
		if (seconds > 0) then return tostring(seconds) .. L" 秒前" end 
		return time_str;
	end
	if (updatedAt) then
		local date = formatTime(updatedAt);
		return L"更新时间："..date;
	else
		return L"更新时间：".."...";
	end
end

function MiniWorldUserInfo.IsStared()
	return isStared;
end

function MiniWorldUserInfo.IsFavorited()
	return isFavorited;
end

function MiniWorldUserInfo.GetStarCount()
	return string.format("%d", starCount);
end

function MiniWorldUserInfo.GetFavoritesCount()
	return string.format("%d", favoriteCount);
end

function MiniWorldUserInfo.OnClickStar()
	keepwork.world.star({router_params = {id = worldParams.projectId}}, function(err, msg, data)
		if (err == 200) then
			isStared = true;
			starCount = starCount + 1;
			page:Refresh(0);
			page:CallMethod("UserPlayer", "SetAssetFile", asset);

			GameLogic.QuestAction.SetDailyTaskValue("40012_1", nil, 1)
		end
	end);
end

function MiniWorldUserInfo.OnClickFavorite()
	keepwork.world.favorite({objectId = worldParams.projectId, objectType = 5}, function(err, msg, data)
		if (err == 200) then
			isFavorited = true;
			favoriteCount = favoriteCount + 1;
			page:Refresh(0);
			page:CallMethod("UserPlayer", "SetAssetFile", asset);
		end
	end);
end

function MiniWorldUserInfo.OnClickUnFavorite()
	keepwork.world.unfavorite({objectId = worldParams.projectId, objectType = 5}, function(err, msg, data)
		if (err == 200) then
			isFavorited = false;
			favoriteCount = favoriteCount - 1;
			page:Refresh(0);
			page:CallMethod("UserPlayer", "SetAssetFile", asset);
		end
	end);
end

function MiniWorldUserInfo.OnClickUserInfo()
	local page = NPL.load("Mod/GeneralGameServerMod/App/ui/page.lua");
	page.ShowUserInfoPage({userId = currentId});
end
