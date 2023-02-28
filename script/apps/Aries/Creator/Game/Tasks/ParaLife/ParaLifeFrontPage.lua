--[[
Title: Paralife Front Page
Author(s): LiXizhi
Date: 2022/2/1
Desc: if there is file called "frontpage.png" or "frontpage.jpg" under world directory, we will use it as background.
Following events are fired and can be handled in code block. 
- /sendevent paralife.OnClickPlay
- /sendevent paralife.OnClickCreate
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeFrontPage.lua");
local ParaLifeFrontPage = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeFrontPage")
if(ParaLifeFrontPage.GetFrontPageImageFilename()) then
	ParaLifeFrontPage.ShowPage(true)
end
------------------------------------------------------------
]]
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ParaLifeFrontPage = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeFrontPage")

local page;
local self = ParaLifeFrontPage;
function ParaLifeFrontPage.OnInit()
	page = document:GetPageCtrl();
	GameLogic:Connect("WorldUnloaded", ParaLifeFrontPage, ParaLifeFrontPage.OnWorldUnload, "UniqueConnection");

	local ParalifeLiveModel = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParalifeLiveModel.lua");
	ParalifeLiveModel.ClosePage()

	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeHomeButton.lua");
	local ParaLifeHomeButton = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeHomeButton")
	ParaLifeHomeButton.ShowPage(false)

	GameLogic.GetFilters():add_filter("OnWillUnloadWorld", ParaLifeFrontPage.OnWillUnloadWorld);
end

function ParaLifeFrontPage.OnWillUnloadWorld(param)
	ParaLifeFrontPage.SaveExternalRegion()
	return param
end

function ParaLifeFrontPage.ShowPage(bShow)
	if(not page and bShow==false) then
		return
	end
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeFrontPage.html", 
			name = "ParaLifeFrontPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			zorder = 100;
			bShow = bShow~=false,
			click_through = true, 
			cancelShowAnimation = true,
			directPosition = true,
				align = "_fi",
				x = 0,
				y = 0,
				width = 0,
				height = 0,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	params._page.OnClose = ParaLifeFrontPage.OnClosed;
end

function ParaLifeFrontPage.OnClosed()
	page = nil
end

function ParaLifeFrontPage:RefreshPage()
	if page then
		page:Refresh(0)
	end
end

function ParaLifeFrontPage.SaveExternalRegion()
	if(self.externalRegion) then
		self.externalRegion:Save()
	end
end

function ParaLifeFrontPage.OnWorldUnload()
	self.lastPlayLocation = nil;
	self.lastCreateLocation = nil;
	self.externalRegion = nil;
end

function ParaLifeFrontPage.OnClickShowMoreApps()
	-- _guihelper.MessageBox([[This is NOT the official ParaLife App. <br/>
	-- This app is user generated content created by Paracraft. Paracraft is an open source 3d animation and world builder.<br/>
	-- Download paracraft to create and publish your own Paralife apps at <br/>https://paracraft.cn]])
	local tipStr = L[[该应用非官方Paralife应用。<br/>
		该应用是用户通过Paracraft软件自主创作的，Paracaft是一款开源的3D动画制作软件。<br/>
		请前往https://paracraft.cn 下载Paracraft，创造并发布你的Paralife 应用吧！<br/>
	]]
	if System.os.GetPlatform()~="ios" and System.os.GetPlatform()~="android" then
		tipStr = L"请使用手机打开，进入应用商店搜索应用进行下载使用"
	end
	_guihelper.MessageBox(tipStr)
end

function ParaLifeFrontPage.GetCurrentLocation()
	local player = EntityManager.GetPlayer()
	local x, y, z = player:GetPosition()
	local facing = player:GetFacing()
	local cameraYaw = GameLogic.RunCommand("/camerayaw")
	return {x=x, y=y, z=z, facing=facing, cameraYaw = cameraYaw}
end

function ParaLifeFrontPage.Close()
	if(page) then
		page:CloseWindow()
		page = nil;
	end

	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeHomeButton.lua");
	local ParaLifeHomeButton = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeHomeButton")
	ParaLifeHomeButton.ShowPage(true)

	if(not GameLogic.GameMode:IsEditor()) then
		local ParalifeLiveModel = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParalifeLiveModel.lua");
		ParalifeLiveModel.ShowView()
	end
end

function ParaLifeFrontPage.GotoLocation(location)
	if(location) then
		local player = EntityManager.GetPlayer()
		player:SetPosition(location.x, location.y, location.z)
		player:SetFacing(location.facing or 0)
		GameLogic.RunCommand("/camerayaw "..tostring(location.cameraYaw));
	end
end


function ParaLifeFrontPage.GetLastPlayLocation()
	if(not self.lastPlayLocation) then
		self.lastPlayLocation = ParaLifeFrontPage.GetCurrentLocation()
	end
	return self.lastPlayLocation;
end

function ParaLifeFrontPage.GetLastCreateLocation()
	if(not self.lastCreateLocation) then
		local regionX, regionZ = 35,35;
		local x, y, z = BlockEngine:real_bottom((regionX+0.5)*512, 12, (regionZ+0.5)*512);
		self.lastCreateLocation = {x=x, y=y, z=z, facing=0, cameraYaw = 0}
	end
	return self.lastCreateLocation;
end

function ParaLifeFrontPage.OnClickPlay()
	ParaLifeFrontPage.Close()

	local posPlay = ParaLifeFrontPage.GetLastPlayLocation()
	local posCreate = ParaLifeFrontPage.GetLastCreateLocation()

	if(GameLogic.GameMode:IsEditor() or not GameLogic.IsReadOnly()) then
		ParaLifeFrontPage.SaveExternalRegion()
		self.lastCreateLocation = ParaLifeFrontPage.GetCurrentLocation()
		ParaLifeFrontPage.GotoLocation(posPlay)
		GameLogic.RunCommand("/mode game")
		GameLogic.RunCommand("/sendevent paralife.OnClickPlay")
	end
end

function ParaLifeFrontPage.OnClickCreate()
	ParaLifeFrontPage.Close()
	local posPlay = ParaLifeFrontPage.GetLastPlayLocation()
	local posCreate = ParaLifeFrontPage.GetLastCreateLocation()

	if(not GameLogic.GameMode:IsEditor() or not GameLogic.IsReadOnly()) then
		self.lastPlayLocation = ParaLifeFrontPage.GetCurrentLocation()
		if(GameLogic.IsReadOnly()) then
			-- if world is editable, we will only load external region
			local bx, by, bz = BlockEngine:block(posCreate.x, posCreate.y, posCreate.z)
			ParaLifeFrontPage.CheckLoadExternalRegion(math.floor(bx/512), math.floor(bz/512))
		end
		ParaLifeFrontPage.GotoLocation(posCreate)
		GameLogic.RunCommand("/mode edit")
		GameLogic.RunCommand("/sendevent paralife.OnClickCreate")
	end
end

-- @param regionX, regionY: default to 35, 35
function ParaLifeFrontPage.CheckLoadExternalRegion(regionX, regionY)
	if(self.externalRegion~=nil) then
		return
	end
	regionX = regionX or 35
	regionY = regionY or 35
	self.externalRegion = false
	local regionFile = ParaIO.GetWritablePath().."temp/paralife_shared_region";
	if not ParaIO.DoesFileExist(regionFile) then
		ParaIO.CreateDirectory(regionFile);
	end
	local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
	regionFile = regionFile.."/"..(WorldCommon.GetWorldTag("kpProjectId") or WorldCommon.GetWorldTag("name") or "")
	NPL.load("(gl)script/apps/Aries/Creator/Game/World/ExternalRegion.lua");
	local ExternalRegion = commonlib.gettable("MyCompany.Aries.Game.World.ExternalRegion");
	self.externalRegion = ExternalRegion:new():Init(regionFile, regionX, regionY, true)
	self.externalRegion:LoadIfExistOrCurrent();
end

function ParaLifeFrontPage.OnClickExit()

end

-- this function may return nil, if no "frontpage.png" or "frontpage_32bits.png" or "frontpage.jpg" under world directory
function ParaLifeFrontPage.GetFrontPageImageFilename()
	local filename = Files.GetWorldFilePath("frontpage.png") or Files.GetWorldFilePath("frontpage_32bits.png") or Files.GetWorldFilePath("frontpage.jpg")
	if(filename) then
		local texture = ParaAsset.LoadTexture("", filename, 1)
		local width = texture:GetWidth();
		local height = texture:GetHeight();

		local Screen = commonlib.gettable("System.Windows.Screen");
		if(width and width > 0) then
			local newWidth = math.floor(height / Screen:GetHeight() *Screen:GetWidth() + 0.5)
			if(newWidth < width) then
				local left = math.floor((width - newWidth) / 2)
				filename = format("%s#%d 0 %d %d", filename, left, newWidth, height)
			end
		end
	end
	return filename;
end
