--[[
Title: CompoundBoxPage
Author(s): LiXizhi
Date: 2014/1/7
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/CompoundBoxPage.lua");
local CompoundBoxPage = commonlib.gettable("MyCompany.Aries.Game.GUI.CompoundBoxPage");
CompoundBoxPage.ShowPage(entity);
-------------------------------------------------------
]]
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local CompoundBoxPage = commonlib.gettable("MyCompany.Aries.Game.GUI.CompoundBoxPage");

CompoundBoxPage.category_ds = {
    {text="工具", name="tool",   },
    {text="食物", name="foot",   },
    {text="装备", name="equip",  },
    {text="机关", name="gear",   },
    {text="装饰", name="deco",   },
}

local cur_entity;
local page;

function CompoundBoxPage.OnInit()
	page = document:GetPageCtrl();
end

function CompoundBoxPage.GetEntity()
	return cur_entity;
end

function CompoundBoxPage.GetContainerView()
	if(cur_entity) then
		return cur_entity.inventoryView;
	end
end

function CompoundBoxPage.GetItemID()
	if(cur_entity) then
		return cur_entity:GetBlockId();
	else
		return 0;
	end
end

function CompoundBoxPage.GetItemName()
    local block = block_types.get(CompoundBoxPage.GetItemID())
    if(block) then
        return block:GetDisplayName();
    end
end

function CompoundBoxPage.GetCommand()
	if(cur_entity) then
		return cur_entity:GetCommand();
	end
end

function CompoundBoxPage.ShowPage()
	--cur_entity = entity;
	local params = {
			url = "script/apps/Aries/Creator/Game/GUI/CompoundBoxPage.html", 
			name = "CompoundBoxPage.ShowPage", 
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
				align = "_ct",
				x = -205,
				y = -205,
				width = 410,
				height = 410,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	--params._page.OnClose = OnClose;
end
