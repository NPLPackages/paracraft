--[[
Title: ParacraftLearningRoomDailyPage
Author(s): leio
Date: 2020/5/15
Desc:  
the daily page for learning paracraft
Use Lib:
-------------------------------------------------------
local ParacraftLearningRoomDailyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParacraftLearningRoom/ParacraftLearningRoomDailyPage.lua");
ParacraftLearningRoomDailyPage.DoCheckin();
--]]
NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldLoginAdapter.lua");
local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
local NplBrowserManager = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserManager.lua");

local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ParaWorldLoginAdapter = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldLoginAdapter");
local DailyTaskManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DailyTask/DailyTaskManager.lua");

local ParacraftLearningRoomDailyPage = NPL.export()

local page;
ParacraftLearningRoomDailyPage.exid = 10001;
ParacraftLearningRoomDailyPage.gsid = 30102;
ParacraftLearningRoomDailyPage.max_cnt = 32;
ParacraftLearningRoomDailyPage.copies = 0;
ParacraftLearningRoomDailyPage.lessons = [[关于移动
F3信息状态栏
关于选择
跳转
命令
电影方块
代码方块
获得帮助
日志文件
过山车的开头
过山车的中间
过山车的结束
空气墙
/blockimage
禁止跳跃
防止作弊
联机创作
彩色告示牌
HTML与用户UI
录制视频F9
/tip 命令
机关与/sendevent
代码方块控制电影播放
删除电影方块中的摄影机
写出工整的代码
代码和命令中的注释
/avatar 命令
让电影控制主角
/shader命令
查看图块的源代码
学会看命令说明
代码的英文发音
全文搜索(上)
全文搜索(下)
复制电影角色
选择性复制角色关键帧
到镜头的距离
响应HTML中的按钮事件(上）
响应HTML中的按钮事件(下）
HTML中的数据绑定 （上）
HTML中的数据绑定 （下）
中继器的几个用处
隐藏的含羞草
出生点的作用
方块的颜色
初识CAD方块
查看CAD教程
CAD与3D打印
如何摆放箭头和有方向的物品
代码方块中的角色（上）
代码方块中的角色（中）
代码方块中的角色（下）
更加精细的bmax模型
物理模型与/lod命令
用骨骼方块制作电风扇（上）
用骨骼方块制作电风扇（下）
控制CAD模型的面数
CAD中建立骨骼绑定
点光源
电影方块中加入光源
代码方块中加入光源
绑定光源到骨骼
主角手中的光源
聚光灯
地形笔刷的技巧
地形画笔的技巧
CodeBlockTest (上）
CodeBlockTest (下）
骨骼动画的RST快捷键
骨骼与反向动力学（上）
骨骼与反向动力学（下）
电影方块中的图层角色
代码方块控制图层角色
3D立体输出
CodeBlockLesson（上）
CodeBlockLesson（下）
生成独立应用程序
Paracraft作者写的教材
相似原理介绍
MindManager
学习的本质
我的童年
教育的本质
如何保持有事可做？
从自然界到虚拟世界
从虚拟世界到物理世界
自学编程：从零到无穷大
学以致用：数学篇
学以致用：英语篇
学生要做的最重要的事情是什么？
作品就是你自己
作品是最好的老师
寻找一位导师
作品历史记录与备份
未来教育的评估方式
随心所欲的创作
Scratch与Paracraft的区别
Minecraft与Paracraft的区别
孩子应该学习什么编程语言？
NPL语言简介
]]
ParacraftLearningRoomDailyPage.Current_Item_DS = {

}

function ParacraftLearningRoomDailyPage.OnInit()
	page = document:GetPageCtrl();
end
function ParacraftLearningRoomDailyPage.LoadLessonsConfig()
    if(not ParacraftLearningRoomDailyPage.is_loaded_lessons)then
        ParacraftLearningRoomDailyPage.lessons_title = {};
        ParacraftLearningRoomDailyPage.is_loaded_lessons = true;
        for title in string.gfind(ParacraftLearningRoomDailyPage.lessons, "([^\r\n]+)") do
            if(title and title ~= "")then
                table.insert(ParacraftLearningRoomDailyPage.lessons_title,title);
            end
        end
    end
end
function ParacraftLearningRoomDailyPage.FillDays()
    ParacraftLearningRoomDailyPage.LoadLessonsConfig();
    local gsid = ParacraftLearningRoomDailyPage.gsid;
	local template = KeepWorkItemManager.GetItemTemplate(gsid);
	if(not template)then
		return
	end
	local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(gsid)

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

function ParacraftLearningRoomDailyPage.ShowPage()
	ParacraftLearningRoomDailyPage.FillDays()
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/ParacraftLearningRoom/ParacraftLearningRoomDailyPage.html",
			name = "ParacraftLearningRoomDailyPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			zorder = 100,
			--app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -600/2,
				y = -500/2,
				width = 600,
				height = 500,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
    if(page)then
        local index = ParacraftLearningRoomDailyPage.GetNextDay();
        local row = math.floor((index-1) / 5) + 1;
	    page:CallMethod("item_gridview", "ScrollToRow", row);
    end

	if not ParacraftLearningRoomDailyPage.HasCheckedToday() then
		GameLogic.AddBBS("desktop", L"至少需要学习20秒才能获得学习任务奖励哦~", 3000, "0 255 0"); 
	end
end
function ParacraftLearningRoomDailyPage.ClosePage()
	if(page)then
		page:CloseWindow();
	end
end
function ParacraftLearningRoomDailyPage.DoCheckin(callback)
    if(not KeepWorkItemManager.GetToken())then
			_guihelper.MessageBox(L"请先登录！");
		return
	end

	local show_page = function()
        ParacraftLearningRoomDailyPage.ShowPage();
	end
	if(not KeepWorkItemManager.IsLoaded())then
		KeepWorkItemManager.GetFilter():add_filter("loaded_all", show_page);
		return
	end
	show_page();
end
function ParacraftLearningRoomDailyPage.OnCheckinToday()
    local index = ParacraftLearningRoomDailyPage.GetNextDay();
	LOG.std(nil, "debug", "ParacraftLearningRoomDailyPage.OnCheckinToday", index);
	ParacraftLearningRoomDailyPage.ClosePage();
	ParacraftLearningRoomDailyPage.OnOpenWeb(index)
end
function ParacraftLearningRoomDailyPage.IsVip()
	return KeepWorkItemManager.IsVip()
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
    -- for red tip, hide tip before data loaded
    if(not KeepWorkItemManager.IsLoaded())then
		return true
	end
	local date = ParaGlobal.GetDateFormat("yyyy-M-d");
	local key = string.format("LearningRoom_HasCheckedToday_%s", date);
	local gsid = ParacraftLearningRoomDailyPage.gsid;
	local clientData = KeepWorkItemManager.GetClientData(gsid) or {};
	return clientData[key];
end
function ParacraftLearningRoomDailyPage.SaveToLocal(callback)
	local date = ParaGlobal.GetDateFormat("yyyy-M-d");
	local key = string.format("LearningRoom_HasCheckedToday_%s", date);
	local gsid = ParacraftLearningRoomDailyPage.gsid;
	local clientData = KeepWorkItemManager.GetClientData(gsid) or {};
	clientData[key] = true;
    for k, v in pairs(clientData) do
		if(k ~= key)then
			if string.find(k, "daily_task_data") == nil then
				clientData[k] = nil; -- clear other days
			end
        end
	end
	
	KeepWorkItemManager.SetClientData(gsid, clientData, callback)
end
function ParacraftLearningRoomDailyPage.OnOpenWeb(index,bCheckVip)
    if(not NplBrowserLoaderPage.IsLoaded())then
        _guihelper.MessageBox(L"正在加载内置浏览器，请稍等！");
		return
    end
	index = tonumber(index)
	if(bCheckVip and not ParacraftLearningRoomDailyPage.IsVip())then
		if(ParacraftLearningRoomDailyPage.IsFuture(index))then
            _guihelper.MessageBox(L"非VIP用户仅可观看已签到视频，是否开通VIP观看此视频？", function(res)
                if(res == _guihelper.DialogResult.OK) then
                    ParacraftLearningRoomDailyPage.OnVIP();
                else
                    ParacraftLearningRoomDailyPage.ShowPage();
	            end
            end, _guihelper.MessageBoxButtons.OKCancel_CustomLabel_Highlight_Right,nil,nil,nil,nil,{ ok = L"立即开通", cancel = L"暂不开通", title = L"开通VIP", });
			return
		end
	end
    if(index < 1)then
        index = 1;
    end
	LOG.std(nil, "debug", "ParacraftLearningRoomDailyPage.OnOpenWeb", index);
	local url = string.format("https://keepwork.com/official/tips/s1/1_%d",index);
	local start_time = os.time()

	NplBrowserManager:CreateOrGet("DailyCheckBrowser"):Show(url, "", false, true, nil, function(state)
		if(state == "ONCLOSE")then
            NplBrowserManager:CreateOrGet("DailyCheckBrowser"):GotoEmpty();
			
			
			local end_time = os.time()
			if not ParacraftLearningRoomDailyPage.HasCheckedToday() and end_time - start_time >= 20 then
				local exid = ParacraftLearningRoomDailyPage.exid;
				KeepWorkItemManager.DoExtendedCost(exid, function()
					ParacraftLearningRoomDailyPage.SaveToLocal(ParacraftLearningRoomDailyPage.ShowPage);
					-- _guihelper.MessageBox(L"今日签到成功，自动获得4个知识豆。", function(res)
						
					-- end, _guihelper.MessageBoxButtons.OK);   
					-- ParacraftLearningRoomDailyPage.ShowPage();

					local reward_num = DailyTaskManager.GetTaskRewardNum(ParacraftLearningRoomDailyPage.exid)
					local desc = string.format("为你的学习点赞，奖励你%s个知识豆，再接再厉哦~", reward_num)
					GameLogic.AddBBS("desktop", desc, 3000, "0 255 0"); 
				end, function()
					_guihelper.MessageBox(L"签到失败！");
				end)
			else
				ParacraftLearningRoomDailyPage.ShowPage();
			end
		end
	end);
end
function ParacraftLearningRoomDailyPage.OnLearningLand()
	if(not KeepWorkItemManager.GetToken())then
		_guihelper.MessageBox(L"请先登录！");
		return
	end

	local learning = function()
		KeepWorkItemManager.GetFilter():remove_all_filters("loaded_all");
		local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
		UserConsole:HandleWorldId(ParaWorldLoginAdapter.GetDefaultWorldID(), "force");
		--[[
		local template = KeepWorkItemManager.GetItemTemplate(TeachingQuestPage.totalTaskGsid);
		if (template) then
			if (TeachingQuestPage.MainWorldId == nil) then
				-- TeachingQuestPage.MainWorldId = template.extension;
				TeachingQuestPage.MainWorldId = tostring(template.desc);
			end
			local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
			UserConsole:HandleWorldId(ParaWorldLoginAdapter.MainWorldId, "force");
		end
		]]
	end
	if(not KeepWorkItemManager.IsLoaded())then
		KeepWorkItemManager.GetFilter():add_filter("loaded_all", learning);
		return
	end

	learning();
end
function ParacraftLearningRoomDailyPage:Refresh()
    if(not page)then
        return
    end
    page:Refresh(0);
end
function ParacraftLearningRoomDailyPage.OnVIP()
	GameLogic.GetFilters():apply_filters("VipNotice", true, function()
        ParacraftLearningRoomDailyPage:Refresh();
    end);
end