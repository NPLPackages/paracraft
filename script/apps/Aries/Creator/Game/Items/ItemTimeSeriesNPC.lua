--[[
Title: ItemTimeSeriesNPC
Author(s): LiXizhi
Date: 2014/3/29
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemTimeSeriesNPC.lua");
local ItemTimeSeriesNPC = commonlib.gettable("MyCompany.Aries.Game.Items.ItemTimeSeriesNPC");
local item_ = ItemTimeSeriesNPC:new({});
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/ActorNPC.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/ModelTextureAtlas.lua");
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
local ModelTextureAtlas = commonlib.gettable("MyCompany.Aries.Game.Common.ModelTextureAtlas");
local ActorNPC = commonlib.gettable("MyCompany.Aries.Game.Movie.ActorNPC");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemTimeSeriesNPC = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.ItemTimeSeries"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemTimeSeriesNPC"));

block_types.RegisterItemClass("ItemTimeSeriesNPC", ItemTimeSeriesNPC);

-- @param template: icon
-- @param radius: the half radius of the object. 
function ItemTimeSeriesNPC:ctor()
	self:SetOwnerDrawIcon(true);
end

-- create actor from item stack. 
-- @param isReuseActor: whether we will reuse actor in the scene with the same name instead of creating a new entity. default to false.
-- @param name: if not provided, it will use the name in itemStack
function ItemTimeSeriesNPC:CreateActorFromItemStack(itemStack, movieclipEntity, isReuseActor, name, movieclip)
	local actor = ActorNPC:new():Init(itemStack, movieclipEntity, isReuseActor, name, movieclip);
	return actor;
end

function ItemTimeSeriesNPC:GetTooltipFromItemStack(itemStack)
	local name = itemStack:GetDisplayName();
	if(not name and name~="") then
		return self:GetTooltip();
	else
		return format(L"%s:右键编辑", name);
	end
end

-- get the first model if any 
function ItemTimeSeriesNPC:GetModelFileName(itemStack)
	local ts = itemStack:GetDataField("timeseries");
	if(ts and ts["assetfile"] and ts["assetfile"].data) then
		return ts["assetfile"].data[1];
	end
end

-- get the first skin if any 
function ItemTimeSeriesNPC:GetModelSkin(itemStack)
	local ts = itemStack:GetDataField("timeseries");
	if(ts and ts["skin"] and ts["skin"].data) then
		return ts["skin"].data[1];
	end
end

-- virtual: draw icon with given size at current position (0,0)
-- @param width, height: size of the icon
-- @param itemStack: this may be nil. or itemStack instance. 
function ItemTimeSeriesNPC:DrawIcon(painter, width, height, itemStack)
	local filename = self:GetModelFileName(itemStack);
	if(filename and filename~="") then
		local skin = self:GetModelSkin(itemStack)
		filename = PlayerAssetFile:GetBuildInFilenameByName(filename)
		filename = EntityManager.Entity:GetModelDiskFilePath(filename)
		if(filename) then
			itemStack.renderedTexturePath = ModelTextureAtlas:CreateGetModel(filename, skin)
		end
		
		if(itemStack.renderedTexturePath) then
			-- painter:SetPen("#ffffffcc");
			-- painter:DrawRectTexture(0, height*0.7, width*0.3, height*0.3, self:GetIcon());
			-- draw a small background block to indicate there is a valid item. 
			painter:SetPen("#ffffff80");
			painter:DrawRect(0, height*0.75, width*0.25, height*0.25);
			painter:SetPen("#ffffff");
			painter:DrawRectTexture(0, 0, width, height, itemStack.renderedTexturePath);
		else
			ItemTimeSeriesNPC._super.DrawIcon(self, painter, width, height, itemStack);
		end
	else
		ItemTimeSeriesNPC._super.DrawIcon(self, painter, width, height, itemStack);
	end
end