--[[
Title: MusicBox
Author(s): LiXizhi
Date: 2013/12/17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityMusicBox.lua");
local EntityMusicBox = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityMusicBox")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityBlockBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/InventoryBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ContainerView.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/BackgroundMusic.lua");
local BackgroundMusic = commonlib.gettable("MyCompany.Aries.Game.Sound.BackgroundMusic");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockBase"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityMusicBox"));

-- class name
Entity.class_name = "EntityMusicBox";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
Entity.is_persistent = true;
-- always serialize to 512*512 regional entity file
Entity.is_regional = true;

function Entity:ctor()
end


-- @param Entity: the half radius of the object. 
function Entity:init()
	if(not Entity._super.init(self)) then
		return
	end
	-- TODO: 
	return self;
end

function Entity:Destroy()
	if(self.isPlaying) then
		self:StopMusic();
	end
	return Entity._super.Destroy(self);
end

function Entity:Refresh()
end

function Entity:OnNeighborChanged(x,y,z, from_block_id)
	local isPowered = BlockEngine:isBlockIndirectlyGettingPowered(x,y,z);
	if(self.isPowered ~= isPowered) then
		self.isPowered = isPowered;
		if(isPowered) then
			self.timer = self.timer or commonlib.Timer:new({callbackFunc = function(timer)
				local x,y,z = self:GetBlockPos();
				local isPowered = BlockEngine:isBlockIndirectlyGettingPowered(x,y,z);
				if(isPowered) then
					self:ToggleMusic();
				end
			end})
			self.timer:Change(100, nil);
		end
	end
end

function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);
	self.isPowered = node.attr.isPowered == "true";
end

function Entity:SaveToXMLNode(node, bSort)
	node = Entity._super.SaveToXMLNode(self, node, bSort);
	if(self.isPowered) then
		node.attr.isPowered = true;
	end
	return node;
end

function Entity:PlayMusic()
	if(self.cmd) then
		self.isPlaying = BackgroundMusic:Play(self.cmd)
	end
end

function Entity:StopMusic()
	BackgroundMusic:Stop(self.cmd);
	self.isPlaying = false;
end

function Entity:ToggleMusic()
	if(self.cmd) then
		self.isPlaying = BackgroundMusic:ToggleMusic(self.cmd)
	end
end

function Entity:GetCommandTitle()
	return L"输入声音文件路径或名字：<div>支持ogg, mp3, wav, mid格式</div><div>内部声音：数字[1-6]</div>"
end

--  right click to edit and left click to play
function Entity:OnClick(x, y, z, mouse_button)
	if(GameLogic.isRemote) then
		GameLogic.GetPlayer():AddToSendQueue(GameLogic.Packets.PacketClickEntity:new():Init(entity or GameLogic.GetPlayer(), self, mouse_button, x, y, z));
		return true;
	else
		if(not GameLogic.GameMode:CanEditBlock() or mouse_button=="left") then
			self:ToggleMusic();
			return true;
		end
		return Entity._super.OnClick(self, x, y, z, mouse_button);
	end
end

-- virtual function: right click to edit. 
function Entity:OpenEditor(editor_name, entity)
	if(self:IsServerEntity() and self:IsRemote()) then
		LOG.std(nil, "info", "Entity:OpenEditor", "access denied, entity is only editable on server");
		return;
	end
	if(editor_name == "entity") then
		local old_value = self.cmd;

		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenFileDialog.lua");
		local OpenFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenFileDialog");
		OpenFileDialog.ShowPage(self:GetCommandTitle(), function(result)
			if(result and result ~= old_value) then
				if(result ~= commonlib.Encoding.DefaultToUtf8(result)) then
					_guihelper.MessageBox(L"文件名必须是英文字母与数字的组合");
					return 
				end
				local filename = result;
				NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
				local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
				if(filename~="" and not filename:match("^%d+$") and not Files.GetWorldFilePath(filename)) then
					_guihelper.MessageBox(format(L"当前世界的目录下没有文件: %s", commonlib.Encoding.DefaultToUtf8(filename)));
				else
					self.cmd = filename;
				end
			end
		end,old_value, L"声音文件", "audio")
	end
end
