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
	{name="DeleteAllKeysToTheRight", text=L"删除右侧全部关键帧"},
	{name="DeleteAllKeys", text=L"删除全部关键帧"},
	{name="ShiftKeyTime", text=L"平移右侧所有帧的时间..."}, 
	{name="MoveKeyTime", text=L"设置时间..."}, 
};

function KeyFramePopupMenu.SetCurrentVar(time, var, actor)
	KeyFramePopupMenu.time = time;
	KeyFramePopupMenu.var = var;
	KeyFramePopupMenu.actor = actor;
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
				node:AddChild(CommonCtrl.TreeNode:new({Text = item.text or item.name, Name = item.name, Type = "Menuitem", onclick = nil, }));
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
	end
end