--[[
Title: popup menu to shown when click on a keyframe
Author(s): LiXizhi
Date: 2014/10/13
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/KeyFramePopupMenu.lua");
local KeyFramePopupMenu = commonlib.gettable("MyCompany.Aries.Game.Movie.KeyFramePopupMenu");
KeyFramePopupMenu.ShowPopupMenu(time, var, actor);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/Actor.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieUISound.lua");
local MovieUISound = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieUISound");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local KeyFramePopupMenu = commonlib.gettable("MyCompany.Aries.Game.Movie.KeyFramePopupMenu");

-- menu items
local standard_keylist = {
	{name="EditKey", text=L"编辑..."}, 
	{name="DeleteCurrentKey", text=L"删除关键帧"},
	{name="DeleteAllKeysToTheRight", text=L"删除右侧全部关键帧"},
	{name="DeleteAllKeys", text=L"删除全部关键帧"},
	{name="ShiftKeyTime", text=L"平移右侧所有帧的时间..."}, 
	{name="CopyKey", text=L"复制"},
	{name="CopyInRange", text=L"复制区间"},
	{name="PasteKey", text=L"粘贴"},
	{name="MoveKeyTime", text=L"设置时间..."}, 
};

function KeyFramePopupMenu.SetCurrentVar(time, var, actor)
	KeyFramePopupMenu.time = time;
	KeyFramePopupMenu.var = var;
	if(KeyFramePopupMenu.actor~=actor) then
		KeyFramePopupMenu.actor = actor;
		KeyFramePopupMenu.last_key_name = nil
		KeyFramePopupMenu.copyInRangeStarted = nil
		KeyFramePopupMenu.copy_from_time = nil
		KeyFramePopupMenu.copy_to_time = nil
		KeyFramePopupMenu.last_key_data = nil
	end
end

-- show the popup menu
-- @param var: the parent variable containing the key
-- @param actor: the parent actor containing the actor
function KeyFramePopupMenu.ShowPopupMenu(time, var, actor)
	local itemList = KeyFramePopupMenu.GetMenuItemList(time, var, actor);
	if(itemList) then
		KeyFramePopupMenu.SetCurrentVar(time, var, actor);

		-- display the context menu item.
		local ctl = KeyFramePopupMenu.var_menu_ctl;
		if(not ctl)then
			ctl = CommonCtrl.ContextMenu:new{
				name = "MovieClipTimeLine.KeyFramePopupMenu",
				width = 190,
				height = 60, -- add menuitemHeight(30) with each new item
				DefaultNodeHeight = 26,
				onclick = KeyFramePopupMenu.OnClickMenuItem,
			};
			KeyFramePopupMenu.var_menu_ctl = ctl;
			ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "", Name = "root_node", Type = "Group", NodeHeight = 0 });
		end
		local node = ctl.RootNode:GetChild(1);
		if(node) then
			node:ClearAllChildren();
			for index, item in ipairs(itemList) do
				local text = item.text or item.name;
				if(item.name == "PasteKey") then
					if(KeyFramePopupMenu.last_key_name) then
						if(KeyFramePopupMenu.copy_from_time and KeyFramePopupMenu.copy_to_time) then
							text = format(L"粘贴区间: %d-%d", KeyFramePopupMenu.copy_from_time,KeyFramePopupMenu.copy_to_time);
						elseif(KeyFramePopupMenu.last_key_data) then
							text = format("%s %s:%s", text, KeyFramePopupMenu.last_key_name, commonlib.serialize_in_length(KeyFramePopupMenu.last_key_data, 10));
						else
							text = nil;
						end
					else
						text = nil;
					end
				elseif(item.name == "CopyInRange") then
					if(not KeyFramePopupMenu.copyInRangeStarted) then
						text = format(L"%s: 开始时间%d", text, time);
					elseif(KeyFramePopupMenu.copyInRangeStarted and KeyFramePopupMenu.copy_from_time) then
						text = format("%s: %d-%d", text, KeyFramePopupMenu.copy_from_time, time);
					end
				end
				if(text) then
					node:AddChild(CommonCtrl.TreeNode:new({Text = text, Name = item.name, Type = "Menuitem", onclick = nil, }))
				end
			end
			ctl.height = (#itemList) * 26 + 4;
		end
		local x, y, width, height = _guihelper.GetLastUIObjectPos();
		if(x and y)then
			ctl:Show(x, y - ctl.height);
		end
	end
end

function KeyFramePopupMenu.GetMenuItemList(time, var, actor)
	return standard_keylist;
end

function KeyFramePopupMenu.OnClickMenuItem(node)
	local actor, var, time = KeyFramePopupMenu.actor, KeyFramePopupMenu.var, KeyFramePopupMenu.time;
	if(node.Name == "EditKey") then
		if(actor) then
			actor:CreateKeyFromUI(var.name, function(bIsAdded)
				if(bIsAdded) then
					MovieUISound.PlayAddKey();
				end
			end);
		end
	elseif(node.Name == "ShiftKeyTime" or node.Name == "MoveKeyTime") then
		if(time and var and actor) then
			local title = format(L"输入关键帧的时间:");
			NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
			local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
			EnterTextDialog.ShowPage(title, function(result)
				if(result and result~="") then
					local newTime = result:match("^(%d+)");
					if(newTime) then
						newTime = tonumber(newTime);
						if(newTime and newTime~= time) then
							actor:BeginModify();
							if(node.Name == "ShiftKeyTime") then
								var:ShiftKeyFrame(time, newTime-time);
							else
								var:MoveKeyFrame(newTime, time);
							end
							actor:EndModify();
							MovieUISound.PlayAddKey();
						end
					end
				end
			end,tostring(time));
		end
	elseif(node.Name == "DeleteCurrentKey") then
		if(var and actor) then
			actor:BeginModify();
			MovieUISound.PlayRemoveKey();
			var:RemoveKeyFrame(time);
			actor:EndModify();
		end
	elseif(node.Name == "DeleteAllKeys") then
		if(var and actor) then
			actor:BeginModify();
			var:TrimEnd(0);
			actor:EndModify();
			MovieUISound.PlayAddKey();
		end
	elseif(node.Name == "DeleteAllKeysToTheRight") then	
		if(time and var and actor) then
			actor:BeginModify();
			var:TrimEnd(time);
			actor:EndModify();
			MovieUISound.PlayAddKey();
		end
	elseif(node.Name == "CopyKey") then	
		if(var and actor) then
			KeyFramePopupMenu.last_key_data = var:getValue(time);
			KeyFramePopupMenu.last_key_name = var.name;
			KeyFramePopupMenu.copyInRangeStarted = nil;
			KeyFramePopupMenu.copy_from_time = nil;
			KeyFramePopupMenu.copy_to_time = nil;
		end
	elseif(node.Name == "CopyInRange") then	
		if(var and actor) then
			KeyFramePopupMenu.last_key_name = var.name;
			KeyFramePopupMenu.last_key_data = nil;
			if(not KeyFramePopupMenu.copyInRangeStarted) then
				KeyFramePopupMenu.copy_from_time = time;
				KeyFramePopupMenu.copyInRangeStarted = true;
			else
				KeyFramePopupMenu.copy_to_time = time;
				KeyFramePopupMenu.copyInRangeStarted = false;
			end
		end
	elseif(node.Name == "PasteKey") then	
		if(var and actor and KeyFramePopupMenu.last_key_name == var.name) then
			actor:BeginModify();
			if(KeyFramePopupMenu.last_key_data) then
				-- copy single key
				var:UpsertKeyFrame(time, KeyFramePopupMenu.last_key_data);
			elseif(KeyFramePopupMenu.copy_from_time and KeyFramePopupMenu.copy_to_time) then
				-- a range of all key frames
				var:PasteKeyFramesInRange(time, KeyFramePopupMenu.copy_from_time, KeyFramePopupMenu.copy_to_time);
			end
			actor:EndModify();
			MovieUISound.PlayAddKey();
		end
	end
end