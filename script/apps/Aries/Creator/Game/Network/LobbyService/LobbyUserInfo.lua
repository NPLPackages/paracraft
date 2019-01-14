--[[
Title: LobbyServer
Author(s): LiXizhi
Date: 2018/12/19
Desc: all LobbyServer
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/LobbyService/LobbyUserInfo.lua");
local LobbyUserInfo = commonlib.gettable("MyCompany.Aries.Game.Network.LobbyUserInfo");
-------------------------------------------------------
]]
local LobbyUserInfo = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Network.LobbyUserInfo"));

function LobbyUserInfo:ctor()
end

function LobbyUserInfo:Init(keepworkUsername, nickname, nid)
	self.keepworkUsername = keepworkUsername;
	self.nickname = nickname;
	self.nid = nid or "LobbyServer_" .. keepworkUsername;
	return self;
end

function LobbyUserInfo:GetNid()
	return self.nid;
end

function LobbyUserInfo:GetUserName()
	return self.keepworkUsername;
end