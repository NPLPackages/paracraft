--[[
Title: ParacraftLearningRoomDailyPage
Author(s): leio
Date: 2020/5/15
Desc:  
the daily page for learning paracraft
Use Lib:
-------------------------------------------------------
local ParacraftLearningRoomDailyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParacraftLearningRoom/ParacraftLearningRoomDailyPage.lua");
ParacraftLearningRoomDailyPage.AutoOpen(1001, 10001);

ParacraftLearningRoomDailyPage.FillDays(1001, 10001);
ParacraftLearningRoomDailyPage.ShowPage(1001, 10001);
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ParacraftLearningRoomDailyPage = NPL.export()

local page;
ParacraftLearningRoomDailyPage.exid = nil;
ParacraftLearningRoomDailyPage.gsid = nil;
ParacraftLearningRoomDailyPage.max_cnt = 32;
ParacraftLearningRoomDailyPage.copies = 0;
ParacraftLearningRoomDailyPage.Current_Item_DS = {
}
function ParacraftLearningRoomDailyPage.OnInit()
	page = document:GetPageCtrl();
end
function ParacraftLearningRoomDailyPage.FillDays(exid, gsid)
    local template = KeepWorkItemManager.GetItemTemplate(gsid);
    if(not template)then
        return
    end
    local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(gsid)

    ParacraftLearningRoomDailyPage.exid = exid;
    ParacraftLearningRoomDailyPage.gsid = gsid;
    ParacraftLearningRoomDailyPage.max_cnt = template.max or 0;
    ParacraftLearningRoomDailyPage.copies = copies or 0;

    ParacraftLearningRoomDailyPage.Current_Item_DS = {};

    for k = 1,ParacraftLearningRoomDailyPage.max_cnt do
        table.insert(ParacraftLearningRoomDailyPage.Current_Item_DS, {});
    end
end
function ParacraftLearningRoomDailyPage.OnInit()
	page = document:GetPageCtrl();
end

function ParacraftLearningRoomDailyPage.ShowPage(exid, gsid)
    if(not KeepWorkItemManager.GetToken())then
        _guihelper.MessageBox(L"请先登录！");
        return
    end
    if(not exid or not gsid)then
        return
    end
    local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/ParacraftLearningRoom/ParacraftLearningRoomDailyPage.html",
			name = "ParacraftLearningRoomDailyPage.ShowPage", 
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
function ParacraftLearningRoomDailyPage.ClosePage()
    if(page)then
        page:CloseWindow();
    end
end
function ParacraftLearningRoomDailyPage.AutoOpen(exid, gsid, callback)
    if(not KeepWorkItemManager.GetToken())then
            _guihelper.MessageBox(L"请先登录！");
        return
    end
    exid = exid or 1001;
    gsid = gsid or 10001;
    ParacraftLearningRoomDailyPage.FillDays(exid, gsid)
    if(not ParacraftLearningRoomDailyPage.HasCheckedToday())then
        local index = ParacraftLearningRoomDailyPage.GetNextDay();
        ParacraftLearningRoomDailyPage.OnOpenWeb(index)
    else
        ParacraftLearningRoomDailyPage.ShowPage(exid, gsid);
    end
    if(callback)then
        callback();
    end
end
function ParacraftLearningRoomDailyPage.IsVip()
    local profile = KeepWorkItemManager.GetProfile()
    if(profile.vip == 1)then
        return true;
    end
end
function ParacraftLearningRoomDailyPage.GetNextDay()
    local copies = ParacraftLearningRoomDailyPage.copies or 0;
    if(not ParacraftLearningRoomDailyPage.HasCheckedToday())then
        copies = copies + 1;
    end
    return copies;
end
function ParacraftLearningRoomDailyPage.IsNextDay(index)
    return index == ParacraftLearningRoomDailyPage.GetNextDay();
end
function ParacraftLearningRoomDailyPage.IsFuture(index)
    if(index > ParacraftLearningRoomDailyPage.GetNextDay() )then
        return true;
    end
end
function ParacraftLearningRoomDailyPage.HasCheckedToday()
    local profile = KeepWorkItemManager.GetProfile()
    local userId = profile.id;
    local exId = ParacraftLearningRoomDailyPage.exid;
    local date = ParaGlobal.GetDateFormat("yyyy-M-d");
    local key = string.format("LearningRoom_HasCheckedToday_%s_%s_%s", tostring(userId), tostring(exId), date);
	local v = GameLogic.GetPlayerController():LoadLocalData(key,false,true);
    return v;
end
function ParacraftLearningRoomDailyPage.SaveToLocal()
    local profile = KeepWorkItemManager.GetProfile()
    local userId = profile.id;
    local exId = ParacraftLearningRoomDailyPage.exid;
    local date = ParaGlobal.GetDateFormat("yyyy-M-d");
    local key = string.format("LearningRoom_HasCheckedToday_%s_%s_%s", tostring(userId), tostring(exId), date);
	GameLogic.GetPlayerController():SaveLocalData(key, true, true);
end
function ParacraftLearningRoomDailyPage.OnCheck()
    local profile = KeepWorkItemManager.GetProfile()
    local userId = profile.id;
    local exId = ParacraftLearningRoomDailyPage.exid;
    if(not userId or not exId)then
        return
    end
     keepwork.items.exchange({
        userId = userId, 
        exId = exId,
    },function(err, msg, data)
        echo("=====ParacraftLearningRoomDailyPage.OnCheck()");
        echo(err);
        echo(msg);
        echo(data);
        ParacraftLearningRoomDailyPage.SaveToLocal();
        if(err == 200)then
            KeepWorkItemManager.LoadItems(true,function()
                _guihelper.MessageBox(L"签到成功！",function(res)
                    ParacraftLearningRoomDailyPage.FillDays(ParacraftLearningRoomDailyPage.exid, ParacraftLearningRoomDailyPage.gsid);
                    ParacraftLearningRoomDailyPage.ShowPage(ParacraftLearningRoomDailyPage.exid, ParacraftLearningRoomDailyPage.gsid);
                end, _guihelper.MessageBoxButtons.OK);
            end)
        else
            ParacraftLearningRoomDailyPage.FillDays(ParacraftLearningRoomDailyPage.exid, ParacraftLearningRoomDailyPage.gsid);
            ParacraftLearningRoomDailyPage.ShowPage(ParacraftLearningRoomDailyPage.exid, ParacraftLearningRoomDailyPage.gsid);
        end
    end)
end
function ParacraftLearningRoomDailyPage.OnOpenWeb(index)
    index = tonumber(index)
    if(not ParacraftLearningRoomDailyPage.IsVip())then
        if(ParacraftLearningRoomDailyPage.IsFuture(index))then
            return
        end
    end

    local url = string.format("https://keepwork.com/official/tips/s1/1_%d",index);
    local NplBrowserResizedPage = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserResizedPage.lua");
    NplBrowserResizedPage:Show(url, "", false, true, nil, function(state)
        if(state == "ONCLOSE")then
            if(ParacraftLearningRoomDailyPage.IsNextDay(index) and not ParacraftLearningRoomDailyPage.HasCheckedToday())then
                 ParacraftLearningRoomDailyPage.OnCheck();
            end
        end
    end);
    ParacraftLearningRoomDailyPage.ClosePage();
end
function ParacraftLearningRoomDailyPage.OnLearningLand()
    echo("=====ParacraftLearningRoomDailyPage.OnLearningLand()");
end
function ParacraftLearningRoomDailyPage.OnVIP()
    ParaGlobal.ShellExecute("open", "explorer.exe", "https://keepwork.com/vip", "", 1); 
end