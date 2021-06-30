--[[
Title: ParaWorld Minimap Surface Realtime
Author(s): LiXizhi
Date: 2020/8/24
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/CourseWorldMinimapSurfaceRealtime.lua");
local CourseWorldMinimapSurfaceRealtime = commonlib.gettable("Paracraft.Controls.CourseWorldMinimapSurfaceRealtime");

-- it is important for the parent window to enable self paint and disable auto clear background. 
window:EnableSelfPaint(true);
window:SetAutoClearBackground(false);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldMinimapSurface.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/CourseWorldMain.lua");
local CourseWorldMain = commonlib.gettable("Paracraft.Controls.CourseWorldMain");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local ParaWorldMain = commonlib.gettable("Paracraft.Controls.ParaWorldMain");
local CourseWorldMinimapSurfaceRealtime = commonlib.inherit(commonlib.gettable("Paracraft.Controls.ParaWorldMinimapSurface"), commonlib.gettable("Paracraft.Controls.CourseWorldMinimapSurfaceRealtime"));
CourseWorldMinimapSurfaceRealtime:Property({"PlayerIconColor", "#ffffffcc"});
CourseWorldMinimapSurfaceRealtime:Property({"PlayerIcon", "Texture/Aries/Creator/keepwork/map/maparrow_32bits.png"});
CourseWorldMinimapSurfaceRealtime:Property({"PlayerIconSize", 32});
CourseWorldMinimapSurfaceRealtime:Property({"PlayerIconCenterX", 16});
CourseWorldMinimapSurfaceRealtime:Property({"PlayerIconCenterY", 19});
CourseWorldMinimapSurfaceRealtime:Property({"IsTrackMainPlayer", true});
CourseWorldMinimapSurfaceRealtime:Property({"ClickToTeleport", true});

-- mapping from block_id to block color like "#ff0000"
local color_table = nil;

function CourseWorldMinimapSurfaceRealtime:ctor()
end

function CourseWorldMinimapSurfaceRealtime:OnTimer()
	CourseWorldMinimapSurfaceRealtime._super.OnTimer(self);
end

function CourseWorldMinimapSurfaceRealtime:Invalidate()
end

function CourseWorldMinimapSurfaceRealtime:paintEvent(painter)
	if(self.IsTrackMainPlayer) then
		local player = EntityManager.GetPlayer();
		if(player) then
			local bx, by, bz = player:GetBlockPos();
			local facing = ParaCamera.GetAttributeObject():GetField("CameraRotY", 0);
			
			local x, y = self:WorldToMapPos(bx, bz)
			if(x and y) then
				painter:Save()
				painter:SetPen(self.PlayerIconColor);

				painter:PushMatrix()
				painter:Translate(self:x() + x, self:y() + y)
				painter:Rotate(facing / math.pi * 180)
				local iconSize = self.PlayerIconSize;
				painter:DrawRectTexture( - self.PlayerIconCenterX,  -self.PlayerIconCenterY, iconSize, iconSize, self.PlayerIcon)
				painter:PopMatrix()

				painter:Restore()
			end
		end
	end
end

-- teleport player to position, and wait at most nTimeLeft for terrain to load. 
-- @param nTimeLeft: if nil, default to 1000ms. 
function CourseWorldMinimapSurfaceRealtime:GotoPos(x, z, nTimeLeft, bRefreshMap)
	if(not nTimeLeft) then
		nTimeLeft = 1000;
	end
	if(nTimeLeft < 0) then
		return
	end
	local y = self:GetHeightByWorldPos(x, z)
	if(y) then
		GameLogic.RunCommand(format("/goto %d %d %d", x, y+1, z))
		if(bRefreshMap) then
			commonlib.TimerManager.SetTimeout(function()  
				self:RefreshMap()
			end, 500)
		end
		return true
	else
		local nStepInterval = 300;
		local _, playerY, _ = EntityManager.GetPlayer():GetBlockPos();
		GameLogic.RunCommand(format("/goto %d %d %d", x, playerY, z))
		commonlib.TimerManager.SetTimeout(function()  
			local curX, _, curZ = EntityManager.GetPlayer():GetBlockPos();
			self:GotoPos(curX, curZ, nTimeLeft - nStepInterval, true)
		end, nStepInterval)
	end
end


function CourseWorldMinimapSurfaceRealtime:RefreshMap()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/CourseWorldMinimapWnd.lua");
	local CourseWorldMinimapWnd = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.CourseWorldMinimapWnd");
	CourseWorldMinimapWnd:RefreshMap()
end

-- virtual: 
function CourseWorldMinimapSurfaceRealtime:mousePressEvent(mouse_event)
	if(mouse_event:button() == "left") then
		mouse_event:accept();
		local pos = mouse_event:localPos();
		local x, z = self:MapToWorldPos(pos[1], pos[2])
		local y = self:GetHeightByWorldPos(x, z)
		if(x>0 and x<64000 and z>0 and z<64000) then
			self:GotoPos(x, z)
			CourseWorldMain:LoadMiniWorldOnPos(x, z);
		end
	elseif(mouse_event:button() == "right") then
		mouse_event:accept();
		self:RefreshMap()
	end
end

-- virtual: 
function CourseWorldMinimapSurfaceRealtime:mouseReleaseEvent(mouse_event)
end

-- virtual: 
function CourseWorldMinimapSurfaceRealtime:mouseWheelEvent(mouse_event)
end