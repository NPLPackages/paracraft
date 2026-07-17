--[[
Title: EntityUserPoint
Author(s): LiXizhi
Date: 2025/11/3
Desc: Represents an arbitrary user in the scene. Users can interact with this entity to add the owner as friend, 
give flowers to the world, visit the owner's world, etc. The entity can be associated with a username, 
an editable world ID, or the current world.
use the lib:
------------------------------------------------------------
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityUserPoint.lua");
local EntityUserPoint = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityUserPoint")
local entity = MyCompany.Aries.Game.EntityManager.EntityUserPoint:new({x,y,z});
entity:SetUserName("username");
entity:Attach();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/Text3DDisplay.lua");
local Text3DDisplay = commonlib.gettable("MyCompany.Aries.Game.Effects.Text3DDisplay");
local ShapeAABB = commonlib.gettable("mathlib.ShapeAABB");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local Encoding = commonlib.gettable("commonlib.Encoding");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityLiveModel"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityUserPoint"));

-- persistent object by default. 
Entity.is_persistent = true;
Entity.framemove_interval = nil;
-- class name
Entity.class_name = "EntityUserPoint";
Entity.isServerEntity = false;
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
-- text display settings
Entity.text_color = "0 0 0";
Entity.text_offset = {x=0, y=1.8, z=-0.18};
Entity.text_facing = -math.pi/2;
Entity.filename = "character/CC/artwar/furnitures/GaoShiPai_Xiao.x";
Entity.mainAssetPath = Entity.filename;

function Entity:ctor()
	self.item_id = block_types.names.UserPoint;
	-- The username of the user this entity represents
	self.username = nil;
	-- The world ID (project ID) associated with this user point
	self.worldId = nil;
	-- Display name for the user
	self.displayName = nil;
	-- Whether the current user has added this user as friend
	self.isFriend = false;
	-- Number of flowers given to this world
	self.flowerCount = 0;
	-- Whether the current user has given flowers
	self.hasGivenFlowers = false;
	self.physicsHeight = self.physicsHeight or 2.2;
end

function Entity:init()
	if(not Entity._super.init(self)) then
		return
	end
    self:Refresh();
    return self;
end

-- Load entity data from XML
function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);
	
	for _, subnode in ipairs(node) do 
		if(subnode.name == "userpoint_data") then
			local data = NPL.LoadTableFromString(subnode[1] or "");
			if(data) then
				self.username = data.username;
				self.worldId = data.worldId;
				self.displayName = data.displayName;
				self.text = data.text;
			end
		end
	end
end

-- Save entity data to XML
function Entity:SaveToXMLNode(node, bSort)
	node = node or {name='entity', attr={}};
	
	local data = {
		username = self.username,
		worldId = self.worldId,
		displayName = self.displayName,
		text = self.text,
	};
	
	node[#node+1] = {[1]=commonlib.serialize_compact(data, bSort), name="userpoint_data"};
	node = Entity._super.SaveToXMLNode(self, node, bSort);
	return node;
end

function Entity:HasBag()
	return false;
end

function Entity:HasRule()
	return false;
end

-- bool: whether has command panel
function Entity:HasCommand()
	return true;
end

-- the title text to display (can be mcml)
function Entity:GetCommandTitle()
	return L"输入展示信息"
end

local  EditorPanelMCML;
-- the title text to display (can be mcml)
function Entity:GetCommandTitle()
	EditorPanelMCML = EditorPanelMCML or string.format([[
		<div style="margin:5px;height:36px;text-align:left">
			<div style="float:left;margin-top:5px;">%s</div>
			<input type="button" value='<%%="%s"%%>' onclick="MyCompany.Aries.Game.EntityManager.EntityUserPoint.OnClickEditUsername" style="margin-left:10px;min-width:80px;color:#ffffff;font-size:14px;height:32px;background:url(Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png#179 89 21 21:8 8 8 8)" />
		</div>
	]], L"输入展示信息", L"设置用户名...");
	return EditorPanelMCML;
end

function Entity.OnClickEditUsername()
	NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EditEntityPage.lua");
	local EditEntityPage = commonlib.gettable("MyCompany.Aries.Game.GUI.EditEntityPage");
	local self = EditEntityPage.GetEntity()
	if(self and self:isa(Entity)) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
		local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
		EnterTextDialog.ShowPage(L"请输入用户名", function(result)
			if(result) then
				self:SetUserName(result);
			end
		end, self:GetUserName());
	end
end

-- Set the username for this user point
function Entity:SetUserName(username)
	self.username = username;
	self:LoadUserInfo();
end

-- Get the username
function Entity:GetUserName()
	return self.username;
end

-- Set the world ID associated with this user point
function Entity:SetWorldId(worldId)
	self.worldId = worldId;
end

-- Get the world ID
function Entity:GetWorldId()
	return self.worldId;
end

-- Set display name
function Entity:SetDisplayName(name)
	self.displayName = name;
end

-- Get display name
function Entity:GetDisplayName()
	return self.displayName or self.username or "User";
end

-- Load user information from KeepWork API
function Entity:LoadUserInfo()
	if(not self.username or self.username == "") then
		return;
	end
end

-- Called when user info is loaded from server
function Entity:OnUserInfoLoaded()
	-- Update the inner object if needed
	-- Subclasses can override this to update visuals
end

-- Refresh the entity display, including text
function Entity:Refresh()
	local obj = self:GetInnerObject();
	if(obj) then
        local text = self:GetCommand() or "";
		if(text ~= "") then
			Text3DDisplay.ShowText3DDisplay(true, obj, text, self.text_color, self.text_offset, self.text_facing);
		else
			Text3DDisplay.ShowText3DDisplay(false, obj);
		end
	end
end

function Entity:Destroy()
	self:DestroyInnerObject();
	Entity._super.Destroy(self);
end

-- Check if the current user is friends with this user
function Entity:CheckFriendStatus()
	-- TODO: Implement friend status check via API
	-- This would need to call a KeepWork API to check friendship
end

-- Add the user as friend
function Entity:AddAsFriend()
	if(not self.username or self.username == "") then
		_guihelper.MessageBox(L"无法添加好友：用户名未设置");
		return;
	end
end

-- Give flowers to the world
function Entity:GiveFlowers(count)
	self.hasGivenFlowers = true;
end

-- Visit the user's world
function Entity:VisitWorld()
	if(not self.worldId or self.worldId == "") then
		return;
	end
end

-- Show user profile page
function Entity:ShowProfile()
	local username = self:GetUserName()
	if(username == System.User.username) then
		GameLogic.AddBBS(nil, L"这是你自己", 3000);
		return
	elseif(username and #username > 4) then
		local UserInfoCtrl = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/UserInfoCtrl.lua");
		UserInfoCtrl.ShowPage(username, nil, 512, 200, function()
			UserInfoCtrl.ShowUserOperate(512+100, 200+20)
		end)
	end
end

function Entity:AddToFavourites()
	-- TODO: implement add to favourites
    _guihelper.MessageBox(L"添加到收藏夹");
end

-- Show interaction menu
function Entity:ShowInteractionMenu()
	local options = {
		{text = L"添加好友", callback = function() self:AddAsFriend() end},
		{text = L"送花", callback = function() self:GiveFlowers(1) end},
	};
	
	if(self.worldId and self.worldId ~= "") then
		table.insert(options, {text = L"访问世界", callback = function() self:VisitWorld() end});
	end
	
	table.insert(options, {text = L"查看资料", callback = function() self:ShowProfile() end});
end

-- return the action name of the entity. if there are multiple action names, they are separated by "|".
-- @return: nil or string
function Entity:GetActionName()
    local names = L"查看"
    if(self.worldId and self.worldId ~= "") then
        names = names .. "|"..L"收藏"
    end
	return names;
end

-- if there is an action point, return its world position.
-- if there are multiple action points, return the first one as x,y,z, and return all points in the 4th return value.
-- return x, y, z, {{x,y,z}, ...} 
function Entity:GetActionPoint()
	return self:GetPosition()
end

function Entity:GetActionRadius()
	return 2; 
end

function Entity:DoAction(actionIndex)
	if(not actionIndex or actionIndex == 1) then
		if(self:GetUserName() == System.User.username) then
			NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EditEntityPage.lua");
			local EditEntityPage = commonlib.gettable("MyCompany.Aries.Game.GUI.EditEntityPage");
			EditEntityPage.ShowPage(self, EntityManager.GetPlayer());
		else
        	self:ShowProfile();
		end
    elseif(actionIndex == 2) then
         
	end
end

-- Right click to show interaction menu
function Entity:OnClick(x, y, z, mouse_button)
	if(mouse_button == "right") then
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EditEntityPage.lua");
		local EditEntityPage = commonlib.gettable("MyCompany.Aries.Game.GUI.EditEntityPage");
		EditEntityPage.ShowPage(self, EntityManager.GetPlayer());
	elseif(mouse_button == "left") then
		self:ShowProfile();
	end
	return true;
end

-- Make entity searchable
function Entity:IsSearchable()
	return true;
end

-- Text for search - override to include both display text and username
function Entity:GetSearchText()
	local parts = {};
	if(self.text and self.text ~= "") then
		table.insert(parts, self.text);
	end
	if(self.displayName and self.displayName ~= "") then
		table.insert(parts, self.displayName);
	end
	if(self.username and self.username ~= "") then
		table.insert(parts, self.username);
	end
	return table.concat(parts, " ");
end

