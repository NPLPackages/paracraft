--[[
Title: Player Context
Author(s): LiXizhi
Date: 2017/6/3
Desc: information about current status of the host player, like asset model, scale, skin, facing, etc
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/PlayerContext.lua");
local PlayerContext = commonlib.gettable("MyCompany.Aries.Game.Memory.PlayerContext");
-------------------------------------------------------
]]
local PlayerContext = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Memory.PlayerContext"));
PlayerContext:Property("Name", "PlayerContext");
PlayerContext:Property("player", nil, "GetPlayer");
PlayerContext:Property("assetfile", "");
PlayerContext:Property("skin", "");
PlayerContext:Property("scaling", 1);
PlayerContext:Property("facing", 0);
PlayerContext:Property("anim", 0);
PlayerContext:Property("bx", 0);
PlayerContext:Property("by", 0);
PlayerContext:Property("bz", 0);

function PlayerContext:ctor()
end

-- @param player: player entity
function PlayerContext:Update(player)
	self.player = player;
	local obj = player:GetInnerObject();
	if(obj) then
		self.assetfile = obj:GetPrimaryAsset():GetKeyName();
		self.scaling = obj:GetScale();
		self.skin = player:GetSkin();
		self.facing = obj:GetField("yaw", 0);
		self.anim = obj:GetField("AnimID", 0);
		self.bx, self.by, self.bz = player:GetBlockPos();
	end
end

function PlayerContext:GetPlayer()
	return self.player;
end

function PlayerContext:GetEntity()
	return self.player;
end

function PlayerContext:GetBlockPos()
	return self.bx, self.by, self.bz;
end

function PlayerContext:GetFacing()	
	return self.facing or 0;
end