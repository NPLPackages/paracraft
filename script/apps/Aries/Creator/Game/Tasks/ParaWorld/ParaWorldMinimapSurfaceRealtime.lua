--[[
Title: ParaWorld Minimap Surface Realtime
Author(s): LiXizhi
Date: 2020/8/24
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldMinimapSurfaceRealtime.lua");
local ParaWorldMinimapSurfaceRealtime = commonlib.gettable("Paracraft.Controls.ParaWorldMinimapSurfaceRealtime");

-- it is important for the parent window to enable self paint and disable auto clear background. 
window:EnableSelfPaint(true);
window:SetAutoClearBackground(false);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldMinimapSurface.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local ParaWorldMinimapSurfaceRealtime = commonlib.inherit(commonlib.gettable("Paracraft.Controls.ParaWorldMinimapSurface"), commonlib.gettable("Paracraft.Controls.ParaWorldMinimapSurfaceRealtime"));
ParaWorldMinimapSurfaceRealtime:Property({"PlayerIconColor", "#ffffff80"});
ParaWorldMinimapSurfaceRealtime:Property({"PlayerIcon", "Texture/Aries/WorldMaps/common/maparrow_32bits.png"});
ParaWorldMinimapSurfaceRealtime:Property({"PlayerIconSize", 32});
ParaWorldMinimapSurfaceRealtime:Property({"PlayerIconCenterX", 15});
ParaWorldMinimapSurfaceRealtime:Property({"PlayerIconCenterY", 19});
ParaWorldMinimapSurfaceRealtime:Property({"IsTrackMainPlayer", true});

-- mapping from block_id to block color like "#ff0000"
local color_table = nil;

function ParaWorldMinimapSurfaceRealtime:ctor()
end

function ParaWorldMinimapSurfaceRealtime:OnTimer()
	ParaWorldMinimapSurfaceRealtime._super.OnTimer(self);
end

function ParaWorldMinimapSurfaceRealtime:Invalidate()
end

function ParaWorldMinimapSurfaceRealtime:paintEvent(painter)
	if(self.IsTrackMainPlayer) then
		local player = EntityManager.GetPlayer();
		if(player) then
			local bx, by, bz = player:GetBlockPos();
			local facing = ParaCamera.GetAttributeObject():GetField("CameraRotY", 0);
			
			local x, y = self:WorldToMapPos(bx, bz)
			if(x and y) then
				painter:SetPen(self.PlayerIconColor);
				painter:PushMatrix()
				painter:Translate(self:x() + x, self:y() + y)
				painter:Rotate(facing / math.pi * 180)
				local iconSize = self.PlayerIconSize;
				painter:DrawRectTexture( - self.PlayerIconCenterX,  -self.PlayerIconCenterY, iconSize, iconSize, self.PlayerIcon)
				painter:PopMatrix()
			end
		end
	end
end