--[[
Title: ItemDialog
Author(s): LiXizhi
Date: 2014/1/20
Desc: left click the icon to edit. 

Dialog is a rule item, which is defined by an xml file. Dialog rule is usually associated with an NPC entity. 
When the NPC is clicked, the dialog rule is activated. It will display UI dialog to the user according to the 
internal rules defined, such as whether a given quest is active, accepted or finished, etc. 

There are three types of dialogs: gossips, quests and triggers:
* gossips: a randomly picked dialog will be shown when there is no other options
* quests: one or more quest related dialogs
   * startdialog: dialogs to show to the user, when pre-condition is met, but froms and goals are not met.
   * acceptdialog: dialogs to show to the user has already accepted the quest. 
   * enddialog: dialogs to show to the user, when froms and goals are met, before rule is executed. 
* triggers: one or more dialog that is only triggered when virtual item or precondition is found on the target NPC
            triggers themselves can be used to complete simple one-time tasks.
   * input: virtual items or real items before this trigger can be activated. Item listed will be removed after dialog is shown.
   * dialogs: dialogs to show when this item is triggered. 
   * output: virtual items or real items to be given to the user when the dialog is finished. 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemDialog.lua");
local ItemDialog = commonlib.gettable("MyCompany.Aries.Game.Items.ItemDialog");
local item_ = ItemDialog:new({icon,});
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
NPL.load("(gl)script/ide/System/Windows/Keyboard.lua");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local Player = commonlib.gettable("MyCompany.Aries.Player");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemDialog = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.Item"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemDialog"));

block_types.RegisterItemClass("ItemDialog", ItemDialog);

function ItemDialog:ctor()
	-- all dialog files for current world
	self.files = {};
end

function ItemDialog:OnLeaveWorld()
	self.files = {};
end

-- stackable
function ItemDialog:GetMaxCount()
	return 64;
end

-- it just remove from cache
function ItemDialog:Reload(filename)
	if(filename) then
		self.files[filename] = nil;
	end
end

function ItemDialog:GetNextNewFileName()
	-- TODO: iterative all files and return a new dialog file id
	local filename = "config/1001_quest.dialog.xml";
	ParaIO.CreateDirectory(GameLogic.GetWorldDirectory()..filename);
	return filename;
end

-- edit the dialog
function ItemDialog:OpenChangeFileDialog(itemStack)
	if(itemStack) then
		local local_filename = itemStack:GetDataField("tooltip");
		self:Reload(local_filename);
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenFileDialog.lua");
		local OpenFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenFileDialog");
		OpenFileDialog.ShowPage(L"请输入*.dialog.xml文件的相对路径", function(result)
			if(result and result~="" and result~=local_filename) then
				if(result:match("%.dialog%.xml$")) then
					itemStack:SetDataField("tooltip", result);
				end
			end
		end, local_filename, L"选择对话文件", "xml", nil, function(filename)
			if(not filename or filename == "") then
				filename = self:GetNextNewFileName();
			end
			NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EditDialog.lua");
			local EditDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EditDialog");
			EditDialog.ShowPage(itemStack, filename);
			return filename;
		end)
	end
end

function ItemDialog:GetDialogFromItemStack(itemStack)
	local filename = itemStack:GetDataField("tooltip");
	if(filename and filename~="") then
		local dialog = self.files[filename];
		if(dialog==nil) then
			local fullpath = Files.FindFile(filename);
			if(fullpath) then
				NPL.load("(gl)script/apps/Aries/Creator/Game/GameRules/Dialog.lua");
				local Dialog = commonlib.gettable("MyCompany.Aries.Game.Rules.Dialog");
				dialog = Dialog:new():LoadFromFile(fullpath);
				self.files[filename] = dialog;
			else
				LOG.std(nil, "warn", "ItemDialog", "file not found: %s", filename);
				dialog = false;
			end
		end
		return dialog;
	end
end

function ItemDialog:OnActivate(itemStack, entityContainer, entityTrigger)
	if(entityContainer and entityContainer:isa(EntityManager.EntityCommandBlock)) then
		return self:TryActivate(itemStack, entityContainer, entityPlayer);
	end 
end

function ItemDialog:TryActivate(itemStack, entityContainer, entityTrigger)
	local dialog = self:GetDialogFromItemStack(itemStack);
	if(dialog) then
		return dialog:OnActivate(entityContainer, entityTrigger);
	end
end


-- Called whenever this item is equipped and the right mouse button is pressed.
-- @return the new item stack to put in the position.
function ItemDialog:OnItemRightClick(itemStack, entityPlayer)
	if( Keyboard.IsCtrlKeyPressed()) then
		self:TryActivate(itemStack, entityContainer, entityPlayer);
	else
		self:OpenChangeFileDialog(itemStack);
	end
	return itemStack, true;
end

function ItemDialog:OnClickInHand(itemStack, entityPlayer)
	if(GameLogic.GameMode:IsEditor() and entityPlayer == EntityManager.GetPlayer()) then
		self:OpenChangeFileDialog(itemStack);
	end
end
-- called when entity receives a custom event via one of its rule bag items. 
function ItemDialog:handleEntityEvent(itemStack, entity, event)
	if(event:GetHandlerFuncName() == "onclick") then
		return self:TryActivate(itemStack, entity, event.fromEntity or nil);
	end
end
