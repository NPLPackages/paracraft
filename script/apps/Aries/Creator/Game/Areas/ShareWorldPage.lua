--[[
Title: Save World Page
Author(s): LiXizhi
Date: 2013/6/30
Desc: save world
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ShareWorldPage.lua");
local ShareWorldPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.Areas.ShareWorldPage");
ShareWorldPage.ShowPage()
-------------------------------------------------------
]]

local ShareWorldPage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.Areas.ShareWorldPage");

local page;
function ShareWorldPage.OnInit()
	page = document:GetPageCtrl();
end

function ShareWorldPage.ShowPage()
	-- FIXME World share mod take control of the share actions
	-- GameLogic.GetFilters():apply_filters("user_event_stat", "world", "share."..tostring(GameLogic.world.seed), 10, nil);

	if(not GameLogic.GetFilters():apply_filters("SaveWorldPage.ShowSharePage", true)) then
		return false;
	end

	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Areas/ShareWorldPage.html",
			name = "ShareWorldPage.ShowSharePage",
			isShowTitleBar = false,
			DestroyOnClose = true,
			enable_esc_key = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			isTopLevel = true,
			directPosition = true,
				align = "_ct",
				x = -310/2,
				y = -270/2,
				width = 310,
				height = 270,
		});
	local filepath = ShareWorldPage.GetPreviewImagePath();
	if(not ParaIO.DoesFileExist(filepath)) then
		ShareWorldPage.TakeSharePageImage();
	else
		ShareWorldPage.UpdateImage();
	end
end

function ShareWorldPage.GetPreviewImagePath()
	return ParaWorld.GetWorldDirectory().."preview.jpg";
end

function ShareWorldPage.UpdateImage(bRefreshAsset)
	if(page) then
		local filepath = ShareWorldPage.GetPreviewImagePath();
		page:SetUIValue("ShareWorldImage", filepath);
		if(bRefreshAsset) then
			ParaAsset.LoadTexture("",filepath,1):UnloadAsset();
		end
	end
end

function ShareWorldPage.TakeSharePageImage()
	NPL.load("(gl)script/kids/3DMapSystemUI/ScreenShot/SnapshotPage.lua");	
	local filepath = ShareWorldPage.GetPreviewImagePath();
	if(MyCompany.Apps.ScreenShot.SnapshotPage.TakeSnapshot(filepath,300,200, false)) then
		ShareWorldPage.UpdateImage(true);
	end
end
