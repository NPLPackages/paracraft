--[[
Title: character customization string codec
Author(s): LiXizhi
Date: 2014/1/24
Desc: ccs info for network transmission for player. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityPlayerCCS.lua");
local EntityPlayerCCS = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityPlayerCCS");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/Codec/TableCodec.lua");
local TableCodec = commonlib.gettable("commonlib.TableCodec");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local EntityPlayerCCS = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityPlayerCCS");

local ccs_codec;

-- return codec (singleton)
local function GetCodec()
	if(ccs_codec) then
		return ccs_codec;
	else
		ccs_codec = EntityPlayerCCS.CreateCodec();
		return ccs_codec;
	end
end

-- create the codec(singleton in most cases)
function EntityPlayerCCS.CreateCodec()
	local codec = TableCodec:new();
	-- TODO: add more field and default value. 
	codec:AddFields({
		{name="skin", default_value="", frequent_values={"", "", ""}},
		{name="assetfile", default_value="", frequent_values={"", "", ""}},
		{name="name", default_value="", frequent_values={"", "", ""}},
	});
	return codec;
end

-- @parm entityPlayer: the entity player
-- @param obj: this is the ParaObject, not Entity. 
function EntityPlayerCCS.ApplyCCSInfoString(entityPlayer, ccs, obj)
	local ccs = GetCodec():Decode(ccs);
	if(ccs and entityPlayer and obj) then
		System.ShowHeadOnDisplay(true, obj, ccs.name or "", GameLogic.options.PlayerHeadOnTextColor);	
		obj:SetReplaceableTexture(2, ParaAsset.LoadTexture("", ccs.skin or "", 1))
	end
end

local ccs = {};

-- get the ccs info string for player. 
function EntityPlayerCCS.GetCCSInfoString(entityPlayer)
	ccs.skin = entityPlayer:GetSkin();
	ccs.name = entityPlayer:GetDisplayName();
	return GetCodec():Encode(ccs);
end