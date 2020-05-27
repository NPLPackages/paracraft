--[[
Title: 
Author: leio
Date: 2020/5/21
Desc: 
-----------------------------------------------
local TeachingQuestPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeachingQuest/TeachingQuestPage.lua");
TeachingQuestPage.ShowPage();
-----------------------------------------------
]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");

local TeachingQuestPage = NPL.export();
local page;
TeachingQuestPage.index = 1;
TeachingQuestPage.quests = {
    { 
        name = L"CodeBlock教学", 
        quests = {
            { exid = 2001, label= L"CodeBlock教学内容", },
            { exid = 2001, label= L"CodeBlock教学内容", },
            { exid = 2001, label= L"CodeBlock教学内容", },
            { exid = 2001, label= L"CodeBlock教学内容", },
            { exid = 2001, label= L"CodeBlock教学内容", },
            { exid = 2001, label= L"CodeBlock教学内容", },
            { exid = 2001, label= L"CodeBlock教学内容", },
            { exid = 2001, label= L"CodeBlock教学内容", },
            { exid = 2001, label= L"CodeBlock教学内容", },
            { exid = 2001, label= L"CodeBlock教学内容", },
            { exid = 2001, label= L"CodeBlock教学内容", },
            { exid = 2001, label= L"CodeBlock教学内容", },
        }
    },
    { 
        name = L"CadBlock教学", 
        quests = {
            { exid = 2002, label= L"CadBlock教学内容", },
            { exid = 2002, label= L"CadBlock教学内容", },
            { exid = 2002, label= L"CadBlock教学内容", },
            { exid = 2002, label= L"CadBlock教学内容", },
            { exid = 2002, label= L"CadBlock教学内容", },
            { exid = 2002, label= L"CadBlock教学内容", },
            { exid = 2002, label= L"CadBlock教学内容", },
            { exid = 2002, label= L"CadBlock教学内容", },
            { exid = 2002, label= L"CadBlock教学内容", },
            { exid = 2002, label= L"CadBlock教学内容", },
            { exid = 2002, label= L"CadBlock教学内容", },
            { exid = 2002, label= L"CadBlock教学内容", },
        }
    },
}
function TeachingQuestPage.OnInit()
	page = document:GetPageCtrl();
end
function TeachingQuestPage.ShowPage(index)
    index = index or 1;
    TeachingQuestPage.index = index;

    TeachingQuestPage.Current_Item_DS = TeachingQuestPage.quests[index].quests;

    local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/TeachingQuest/TeachingQuestPage.html",
			name = "TeachingQuestPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			zorder = -1,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -800/2,
				y = -500/2,
				width = 800,
				height = 500,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end
-- index start as 1
function TeachingQuestPage.IsFinished(exid,index)
    local cnt = TeachingQuestPage.GetMarkItemCnt(exid);
    index = index - 1
    if(index < cnt)then
        return true
    end
end
function TeachingQuestPage.CanAccept(exid,index)
    local precondition,cost,goal = KeepWorkItemManager.GetConditions(exid);
    if(not precondition)then
        return true
    end
--    for k,v in ipairs(precondition) do
--        local gsid = v.goods.gsId;
--        local amount = v.amount or 0;
--        local bOwn, guid, bag, copies = KeepWorkItemManager.HasGSItem(gsId);
--        copies = copies or 0;
--        if(copies < amount)then
--            return false;
--        end
--    end
    return true;
end
function TeachingQuestPage.IsActived(exid,index)
    local cnt = TeachingQuestPage.GetMarkItemCnt(exid);
    index = index - 1
    if(index == cnt)then
        return true
    end
end

function TeachingQuestPage.IsLocked(exid,index)
    local cnt = TeachingQuestPage.GetMarkItemCnt(exid);
    index = index - 1
    if(index > cnt)then
        return true
    end
end
function TeachingQuestPage.GetMarkItem(exid)
    local precondition,cost,goal = KeepWorkItemManager.GetConditions(exid);
    if(not goal)then
        return
    end
    if(goal[1] and goal[1]["goods"])then
        local mark_item = goal[1]["goods"][1]["goods"];
        return mark_item;
    end
end
function TeachingQuestPage.GetMarkItemCnt(exid)
    local item = TeachingQuestPage.GetMarkItem(exid);
    if(not item)then
        return
    end
    local gsid = item.gsId;
    local bOwn, guid, bag, copies = KeepWorkItemManager.HasGSItem(gsid);
    copies = copies or 0;
    return copies;
end