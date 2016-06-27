--[[
Title: building minimap using current player position. 
Author(s): LiXizhi
Date: 2013/1/26
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildMinimapTask.lua");
-- where callbackFunc(imagefile) is called
local task = MyCompany.Aries.Game.Tasks.BuildMinimap:new({callbackFunc})
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Assets/AssetsCommon.lua");
NPL.load("(gl)script/ide/Display3D/SceneNode.lua");
NPL.load("(gl)script/ide/Display3D/SceneManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/AI/LocalNPC.lua");
local LocalNPC = commonlib.gettable("MyCompany.Aries.Creator.AI.LocalNPC")
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
local ObjEditor = commonlib.gettable("ObjEditor");
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");

local BuildMinimap = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildMinimap"));

-- this is always a top level task. 
BuildMinimap.is_top_level = true;

-- the camera y offset relative to current player position. 
BuildMinimap.camera_y_offset = 10;
-- default image size. 
BuildMinimap.imagesize = 128;
-- default image radius in blocks
BuildMinimap.radius = 64;

local cur_instance;

function BuildMinimap:ctor()
end

function BuildMinimap.RegisterHooks()
	local self = cur_instance;
	self.sceneContext = self.sceneContext or Game.SceneContext.RedirectContext:new():RedirectInput(self);
	self.sceneContext:activate();
end

function BuildMinimap.UnregisterHooks()
	local self = cur_instance;
	if(self) then
		self.sceneContext:close();
	end
end

function BuildMinimap:Run()
	if(not TaskManager.AddTask(self)) then
		-- ignore the task if there is other top-level tasks.
		return;
	end

	cur_instance = self;

	local oldPosX, oldPosY, oldPosZ = ParaScene.GetPlayer():GetPosition();
	self.oldPosX, self.oldPosY, self.oldPosZ = oldPosX, oldPosY, oldPosZ;
	self.x, self.y, self.z = self.x or oldPosX, self.y or oldPosY, self.z or oldPosZ;
	
	
	BuildMinimap.finished = false;
	BuildMinimap.RegisterHooks();

	Desktop.HideAllAreas();
	BuildMinimap.ShowPage();

	ParaCamera.GetAttributeObject():SetField("BlockInput", true);
	ParaScene.GetAttributeObject():SetField("BlockInput", true);

	self.state = ParaScene.CaptureSceneState()
	BuildMinimap.ChangeToSatellitePos();

end

function BuildMinimap:OnExit()
	BuildMinimap.EndEditing();
end


-- @param bCommitChange: true to commit all changes made 
function BuildMinimap.EndEditing(bCommitChange)
	BuildMinimap.finished = true;
	BuildMinimap.ClosePage()
	BuildMinimap.UnregisterHooks();
	if(cur_instance) then
		local self = cur_instance;
		cur_instance = nil
		ParaScene.RestoreSceneState(self.state);

		ParaScene.GetPlayer():SetPosition(self.oldPosX, self.oldPosY, self.oldPosZ);
	end
	if(BuildMinimap.mytimer) then
		BuildMinimap.mytimer:Change();
		BuildMinimap.mytimer = nil;
	end
	Desktop.ShowAllAreas();
	ParaCamera.GetAttributeObject():SetField("BlockInput", false);
	ParaScene.GetAttributeObject():SetField("BlockInput", false);
end

function BuildMinimap:mousePressEvent(event)
end

function BuildMinimap:mouseMoveEvent(event)
end

function BuildMinimap:mouseReleaseEvent(event)
end

function BuildMinimap:keyPressEvent(event)
	local dik_key = event.keyname;

	if(dik_key == "DIK_ESCAPE")then
		-- exit editing mode without commit any changes. 
		BuildMinimap.EndEditing(false);
	end	
end

function BuildMinimap:FrameMove()
end


-- each snap shot is 128*128
-- @param x, y, z: if nil, current player position is used
function BuildMinimap.ChangeToSatellitePos(x,y,z)
	local self = cur_instance;
	if(not self) then
		return
	end 

	local center_x, center_y, center_z, radius, region_x, region_z = BuildMinimap.GetPosition()

	local world_path = ParaWorld.GetWorldDirectory();
	local imagepath = format("%sminimap/minimap_%d_%d.jpg", world_path, region_x, region_z);

	local att = ParaScene.GetAttributeObject(); 
	local max_dist = 256;
	att:SetField("FogStart", max_dist);
	att:SetField("FogEnd", max_dist); -- setting FogStart == FogEnd, will ignore min popup distance according to view angle. 
	att:SetField("EnableFog", false);
	
	ParaCamera.SwitchOrthoView(radius * 2, radius * 2)
	local att = ParaCamera.GetAttributeObject(); 
	att:SetField("FarPlane", max_dist);
	att:SetField("AspectRatio", 1);
	att:SetField("FieldOfView", 1.57);
	ParaCamera.SetLookAtPos(center_x, center_y - 5, center_z);
	ParaCamera.SetEyePos(5, 1.57, -1.57);
	att:CallField("FrameMove");
	
	self.imagepath = imagepath;
end

-- return satellite camera eye position and region pos
function BuildMinimap.GetPosition()
	local self = cur_instance;
	if(not self) then
		return
	end 
	
	local x, y, z = self.x, self.y, self.z;

	local b_x, b_y, b_z = BlockEngine:block(x, y, z);

	local imagepath,radius,height;

	local blocksize = BlockEngine.blocksize;

	-- block radius
	radius = self.radius;
	-- 128 blocks per image. 
	local width = radius * 2;
	-- converting to real cordinates
	radius = radius * blocksize;

	local region_x = math.floor(b_x/width);
	local region_z = math.floor(b_z/width);

	local center_x = region_x * width + radius;
	local center_y = b_y + self.camera_y_offset;
	local center_z = region_z * width + radius;
	center_x, center_y, center_z =  BlockEngine:real(center_x,center_y,center_z);

	return center_x, center_y, center_z, radius, region_x, region_z;
end

function BuildMinimap.TakeSnapshot()
	local self = cur_instance;
	if(not self) then
		return
	end 

	ParaUI.GetUIObject("root").visible = false;
	ParaUI.ShowCursor(false);
	ParaScene.EnableMiniSceneGraph(false);
		
	ParaEngine.ForceRender();ParaEngine.ForceRender();
	ParaMovie.TakeScreenShot(self.imagepath, self.imagesize, self.imagesize);
	
	ParaUI.GetUIObject("root").visible = true;
	ParaScene.EnableMiniSceneGraph(true);
	ParaUI.ShowCursor(true);

	if(self.callbackFunc) then
		self.callbackFunc(self.imagepath)
	end

	BroadcastHelper.PushLabel({id="BuildMinimap", label = "生成成功！", max_duration=5000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
end


------------------------
-- page function 
------------------------
local page;
function BuildMinimap.ShowPage()
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Tasks/BuildMinimapTask.html", 
			name = "BuildMinimapTask.ShowPage", 
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			isShowTitleBar = false, 
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = 1,
			allowDrag = false,
			click_through = true,
			directPosition = true,
				align = "_lt",
				x = 0,
				y = 80,
				width = 128,
				height = 512,
		});
	MyCompany.Aries.Creator.ToolTipsPage.ShowPage(false);
end

function BuildMinimap.ClosePage()
	if(page) then
		page:CloseWindow();
	end
end

function BuildMinimap.OnInit()
	page = document:GetPageCtrl();
end

function BuildMinimap.RefreshPage()
	BuildMinimap.ChangeToSatellitePos();
	if(page) then
		page:Refresh(0.01);
	end
end

function BuildMinimap.DoClick(name)
	local self = cur_instance;
	if(not self) then
		return
	end 

	if(name == "camera_up") then
		self.camera_y_offset = self.camera_y_offset + 1;
		BuildMinimap.RefreshPage();
	elseif(name == "camera_down") then
		self.camera_y_offset = self.camera_y_offset - 1;
		BuildMinimap.RefreshPage();
	end
end

function BuildMinimap.OnGenMinimap()
	local self = cur_instance;
	if(not self) then
		return
	end 

	local radius = page:GetUIValue("radius", BuildMinimap.radius)
	radius = tonumber(radius) or BuildMinimap.radius;

	if(radius == BuildMinimap.radius) then
		BuildMinimap.TakeSnapshot();
	else
		local step_width = BuildMinimap.radius*2;
		local step = math.floor(radius / step_width);

		local last_x, last_y, last_z = self.x, self.y, self.z

		if(BuildMinimap.mytimer) then
			return;
		end

		local count = 0;
		local total_count = (2*step+1)*(2*step+1);

		BroadcastHelper.PushLabel({id="BuildMinimap1", label = format("共要生成%d个切图, 请耐心等待", total_count), max_duration=10000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});

		BuildMinimap.mytimer = commonlib.Timer:new({callbackFunc = function(timer)
			count = count + 0.5;
			local x,y,z;
			local i=0;
			for x = -step, step do
				for z = -step, step do
					i = i+1;
					if(i == count) then
						BuildMinimap.TakeSnapshot();
						timer:Change(100, nil);
					elseif((i-0.5) == count ) then
						self.x, self.y, self.z = last_x + x * step_width * BlockEngine.blocksize, last_y, last_z + z * step_width * BlockEngine.blocksize;
						BroadcastHelper.PushLabel({id="BuildMinimap1", label = format("进度%d/%d, 请等待...", count, total_count), max_duration=5000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
						BuildMinimap.RefreshPage();
						timer:Change(6000, nil);
					end
				end
			end
			if(count >= total_count) then
				-- close timer
				BuildMinimap.mytimer:Change();
				BuildMinimap.mytimer = nil;

				self.x, self.y, self.z = last_x, last_y, last_z;
				BuildMinimap.RefreshPage()
				BroadcastHelper.PushLabel({id="BuildMinimap1", label = format("%d张切图全部生成完毕!", total_count), max_duration=5000, color = "0 255 0", scaling=1.1, bold=true, shadow=true,});
			end
		end})
		-- start the timer after 0 milliseconds, and signal every 1000 millisecond
		BuildMinimap.mytimer:Change(10);
		
		
	end
end
