--[[
Title: Dialog Page
Author(s): LiXizhi
Date: 2016/3/30
Desc: Display dialog and return result
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/NPCDialogPage.lua");
local NPCDialogPage = commonlib.gettable("MyCompany.Aries.Game.GUI.NPCDialogPage");
NPCDialogPage.ShowPage(dialog, entityContainer, entityPlayer, callbackFunc);
-------------------------------------------------------
]]
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local NPCDialogPage = commonlib.gettable("MyCompany.Aries.Game.GUI.NPCDialogPage");

local page;

NPCDialogPage.default_button = {{label = L"继续...", action="gotonext"}};

function NPCDialogPage.OnInit()
	page = document:GetPageCtrl();
end

function NPCDialogPage.GetEntity()
	return NPCDialogPage.entityContainer;
end

function NPCDialogPage.ClosePage()
	page:CloseWindow();
	if(NPCDialogPage.callbackFunc) then
		NPCDialogPage.callbackFunc(NPCDialogPage.last_action);
	end
end

-- @param itemIndex: if nil, it will be the current one. 
-- @return dialog item {avatar, content, buttons}
function NPCDialogPage.GetDialogItem(itemIndex)
	if(NPCDialogPage.dialog) then
		return NPCDialogPage.dialog[itemIndex or NPCDialogPage.dialog_item_index or 1];
	end
end

function NPCDialogPage.GetAvatarEntity()
    local item = NPCDialogPage.GetDialogItem();
    if(item and item.avatar) then
		local name = item.avatar.name;
        if(name and name~="") then
            local entity = name == "player" and  EntityManager.GetPlayer() or EntityManager.GetEntity(name);
			if(entity) then
				return entity;
			end
        end
    end
	return NPCDialogPage.GetEntity();
end

function NPCDialogPage.GetAvatarName()
    local item = NPCDialogPage.GetDialogItem();
	if(item and item.avatar) then
		if(item.avatar.title) then
			return item.avatar.title;
		end
	end
    local entity = NPCDialogPage.GetAvatarEntity();
	if(entity) then
		return entity:GetDisplayName();
	end
	return "";
end

function NPCDialogPage.GetDialogButtons()
    local item = NPCDialogPage.GetDialogItem();
    return item and item.buttons or NPCDialogPage.default_button;
end

function NPCDialogPage.GetButtonByIndex(index)
	local buttons = NPCDialogPage.GetDialogButtons()
	if(buttons) then
		return buttons[index or 1];
	end
end

-- return index;
function NPCDialogPage.FindDialogItem(name)
	if(NPCDialogPage.dialog) then
		for i, item in ipairs(NPCDialogPage.dialog) do
			if(item.name == name) then
				return i;
			end
		end
	end
end

function NPCDialogPage.OnClickButton(name, mcmlNode)
	local index = tonumber(name) or 1;
	local button = NPCDialogPage.GetButtonByIndex(index);
	local action = button.action;
	NPCDialogPage.last_action = action;
	if(not action or action == "gotonext") then
		if(NPCDialogPage.GetDialogItem(NPCDialogPage.dialog_item_index+1)) then
			NPCDialogPage.dialog_item_index = NPCDialogPage.dialog_item_index + 1;
			page:Refresh(0.01);
		else
			NPCDialogPage.ClosePage();	
		end
	elseif(action:match("^goto ")) then
		local goto_label = action:match("^goto (.+)");
		if(goto_label) then
			local index = NPCDialogPage.FindDialogItem(goto_label);
			if(index) then
				NPCDialogPage.dialog_item_index = index;
				page:Refresh(0.01);
			end
		end
	elseif(action == "close") then
		NPCDialogPage.ClosePage();
	else
		NPCDialogPage.ClosePage();
	end	
end

-- @param callbackFunc: function(action)  end 
function NPCDialogPage.ShowPage(dialog, entityContainer, entityPlayer, callbackFunc)
	NPCDialogPage.entityContainer = entityContainer;
	NPCDialogPage.entityPlayer = entityPlayer;
	NPCDialogPage.callbackFunc = callbackFunc;
	NPCDialogPage.dialog = dialog;
	NPCDialogPage.dialog_item_index = 1;
	NPCDialogPage.last_action = nil;

	local params = {
			url = format("script/apps/Aries/Creator/Game/GUI/NPCDialogPage.html"), 
			name = "NPCDialogPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			enable_esc_key = true,
			bShow = true,
			click_through = false, 
			zorder = -1,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_fi",
				x = 0,
				y = 0,
				width = 0,
				height = 0,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function NPCDialogPage.OnClickOK()
	local entity = NPCDialogPage.GetEntity();
	if(entity) then
	end
	page:CloseWindow();

	if(NPCDialogPage.callbackFunc) then
		NPCDialogPage.callbackFunc(1);
	end
end