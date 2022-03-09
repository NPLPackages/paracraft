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
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestAction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldLoginAdapter.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/game_logic.lua");
local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
local NplBrowserManager = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserManager.lua");
local QuestAction = commonlib.gettable("MyCompany.Aries.Game.Tasks.Quest.QuestAction");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local ParaWorldLoginAdapter = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldLoginAdapter");
local DailyTaskManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/DailyTask/DailyTaskManager.lua");
local RedSummerCampPPtPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ParacraftLearningRoomDailyPage = NPL.export()
ParacraftLearningRoomDailyPage.is_red_summercamp = false;
local page;
ParacraftLearningRoomDailyPage.exid = 10001;
ParacraftLearningRoomDailyPage.gsid = 30102;
ParacraftLearningRoomDailyPage.max_cnt_preset = 238;
ParacraftLearningRoomDailyPage.max_cnt = 0;
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
代码方块教学1
Paracraft由多少行代码构成的
代码方块教学2
语法、注释、Log语句
代码方块教学3《乒乓球游戏》
什么是编译？
代码方块教学4《钢琴》
程序的本质
代码方块教学5《迷宫小游戏》
数字与数学
代码方块教学6《全局变量》
变量与名字
代码方块教学7《双重机关与事件》
变量的作用域
代码方块教学8《制作图形界面》
变量的使用方法
代码方块教学9《代码方块的输出》
变量举例
字符串与文字
字符串常用操作
字符串练习
表的基本概念
表与数组的创建方法
表的用法举例
如何定义函数
调用函数
有返回值的函数
内置函数 and or
内置函数 if
如何避免 if
内置函数 while for
学习NPL语言的总结
学习编程的建议
打字练习1
打字练习2
打字练习3
打字练习4
打字练习5
打字练习6
跟随我
示教系统（上）
示教系统（下）
人工智能冬令营
隐形方块
text命令
多人联网ggs命令
ggs同步消息
关卡与事件
人物头顶文字
ask提问
loadworld命令
sky命令
time命令
可换装人物
say头顶说话
设置角色的感知半径
用感知半径配合电影播放
anim函数
hide隐藏角色
宏示教舞台（上）
宏示教舞台（下）
自定义物品AgentItem（上）
自定义物品AgentItem（中）
自定义物品AgentItem（下）
playSound播放音乐(上）
playSound播放音乐(下）
playText朗读文字
在电影方块中朗读字幕
playBone骨骼动画
自定义动画anim（上）
自定义动画anim（下）
Clone命令上升的气球
运动的可换装方块
教学模式与地基方块
限制可创作的方块数
看不见的可点击区域
激活代码方块编辑器(上)
激活代码方块编辑器(下)
相对位置播放动画
用命令生成地形
预加载地形上的代码
接收键盘消息
接收任意键盘消息
处理并发的键盘消息
接收鼠标消息
取消接收消息
并行执行:边走边跳
自动启动代码方块
用代码方块自动加载房间内景
NPL图块
NPL图块自动生成宏示教
NPL自定义世界图块
选择非方块物体
批量替换方块
不可编辑方块
彩色的提问按钮
可点击的相册
密室解锁逻辑（上）
密室解锁逻辑（下）
将电脑使用权还给孩子
禁止世界另存为
设置世界的多人编辑权限
世界权限分组与只读权限
更改光源颜色
新手模板 F1
创建新手模板（上）
创建新手模板（下）
分享作品视频和点赞
搜索官方文档
给图块添加注释
相册的使用
永远面向摄影机
会员种类和权限说明
免费用户的世界访问权限
角色连接到角色
玩家连接到电梯
《创意空间》与教育3.0
自我检测表
clone一群随机角色
录音与ogg音频文件
给电影方块添加声音
clone电影方块中的多个角色
如何使用PPT教学
如何做1v1辅导
编程教学中模仿的重要性
参观机构样板校
离线模式与个人电脑
全国创意大赛列表
代码方块的字体大小
多窗口编辑代码方块中的代码
开启代码方块高性能模式
代码方块设置断点(上)
代码方块设置断点(下)
架设私服与多人合作
允许客户端执行代码
自动注册学生账号
配置教师服务器
隐藏会员按钮
分享世界
找回历史版本
过山车与动力铁轨
过山车与探测铁轨
出生点的摄影机lookat命令
添加世界规则addrule
制作有待机动画的方块模型
制作有行走动作的方块模型
自主动画方块模型
100个游戏项目设计
制作交互示课件
基于角色扮演的动画制作
摄影机与蒙太奇动画
多人联网共享数据
多人联网排行榜
手机版操作介绍（上）
手机版操作介绍（下）
给平板电脑加上键盘和鼠标
发布手机App
世界激活码 （上）
世界激活码 （下）
新建世界模板展示
2合1课程世界介绍（上）
2合1课程世界介绍（下）
摄影机图块 (上)
摄影机图块 (下)
]]
ParacraftLearningRoomDailyPage.Current_Item_DS = {

}
ParacraftLearningRoomDailyPage.max_lesson = 0 --最大课程数，添加或者删除课程时记得修改这个

function ParacraftLearningRoomDailyPage.OnInit()
	page = document:GetPageCtrl();
end

function ParacraftLearningRoomDailyPage.GetPageCtrl()
	return page
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

    -- getting preset value first from client
    local cnt = ParacraftLearningRoomDailyPage.max_cnt_preset;
    if(template.max and template.max > cnt)then
        cnt = template.max;
    end
	ParacraftLearningRoomDailyPage.max_cnt = cnt;
	ParacraftLearningRoomDailyPage.copies = copies or 0;

	ParacraftLearningRoomDailyPage.Current_Item_DS = {};

	for k = 1,ParacraftLearningRoomDailyPage.max_cnt do
		table.insert(ParacraftLearningRoomDailyPage.Current_Item_DS, {});
	end
end
function ParacraftLearningRoomDailyPage.OnInit()
	page = document:GetPageCtrl();
end

function ParacraftLearningRoomDailyPage.GetTitle(index)
    local s = string.format(L"第%d天:%s", index, ParacraftLearningRoomDailyPage.lessons_title[index] or "");
    return s;
end
function ParacraftLearningRoomDailyPage.ShowPage_RedSummerCamp()
	ParacraftLearningRoomDailyPage.is_red_summercamp = true;

	ParacraftLearningRoomDailyPage.FillDays()
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampRecCoursePage.html",
			name = "ParacraftLearningRoomDailyPage.ShowPage_RedSummerCamp", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			enable_esc_key = false,
			cancelShowAnimation = true,
			-- app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_fi",
				x = 0,
				y = 0,
				width = 0,
				height = 0,
			DesignResolutionWidth = 1280,
			DesignResolutionHeight = 720,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
    if(page)then
        local index = ParacraftLearningRoomDailyPage.GetNextDay();
        local row = math.floor((index-1) / 5) + 1;
	    page:CallMethod("item_gridview", "ScrollToRow", row);
    end
end
function ParacraftLearningRoomDailyPage.ShowPage()
	ParacraftLearningRoomDailyPage.is_red_summercamp = false;
	
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

	-- if not ParacraftLearningRoomDailyPage.HasCheckedToday() then
	-- 	GameLogic.AddBBS("desktop", L"至少需要学习20秒才能获得学习任务奖励哦~", 3000, "0 255 0"); 
	-- end
end
function ParacraftLearningRoomDailyPage.ClosePage()
	if(page)then
		page:CloseWindow();
	end
end
function ParacraftLearningRoomDailyPage.DoCheckin(callback)
    if(not KeepWorkItemManager.GetToken())then
		GameLogic.CheckSignedIn(L"此功能需要登陆后才能使用",
			function(result)
				if (result) then
					ParacraftLearningRoomDailyPage.DoCheckin(callback)
				end
			end)
		return
	end

	ParacraftLearningRoomDailyPage.is_red_summercamp = false;
	local show_page = function()
		ParacraftLearningRoomDailyPage.ShowPage();
	end
	if(not KeepWorkItemManager.IsLoaded())then
		KeepWorkItemManager.GetFilter():add_filter("loaded_all", show_page);
		return
	end
	show_page();
end

function ParacraftLearningRoomDailyPage.GetMaxLearnDays()
	if ParacraftLearningRoomDailyPage.max_lesson == 0 then
		local nLesson = 0
		for title in string.gfind(ParacraftLearningRoomDailyPage.lessons, "([^\r\n]+)") do
            if(title and title ~= "")then
                nLesson = nLesson + 1
            end
		end
		ParacraftLearningRoomDailyPage.max_lesson = nLesson
	end
	-- print("最大课程数是================",ParacraftLearningRoomDailyPage.max_lesson)
end

function ParacraftLearningRoomDailyPage.GetLearnDays()
	local gsid = ParacraftLearningRoomDailyPage.gsid;
	local template = KeepWorkItemManager.GetItemTemplate(gsid);
	if(not template)then
		return 0
	end
	local bHas,guid,bagid,copies,item = KeepWorkItemManager.HasGSItem(gsid)
	-- print("数据是===================",bHas,guid,bagid,copies)
	-- commonlib.echo(item,true)
	if not bHas then
		return 0
	end
	return copies or 0
end

function ParacraftLearningRoomDailyPage.OnCheckinToday()
    local index = ParacraftLearningRoomDailyPage.GetNextDay();
	LOG.std(nil, "debug", "ParacraftLearningRoomDailyPage.OnCheckinToday", index);
	if(not ParacraftLearningRoomDailyPage.is_red_summercamp)then
		ParacraftLearningRoomDailyPage.ClosePage();
	end
	ParacraftLearningRoomDailyPage.OnOpenWeb(index)
end
function ParacraftLearningRoomDailyPage.IsVip()
	return KeepWorkItemManager.IsVip() or KeepWorkItemManager.IsOrgVip()
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
	ParacraftLearningRoomDailyPage.GetMaxLearnDays()
	local date = ParaGlobal.GetDateFormat("yyyy-M-d");
	local key = string.format("LearningRoom_HasCheckedToday_%s", date);
	local gsid = ParacraftLearningRoomDailyPage.gsid;
	local clientData = KeepWorkItemManager.GetClientData(gsid) or {};
	local nLearnDays = ParacraftLearningRoomDailyPage.GetLearnDays()
	if nLearnDays >= ParacraftLearningRoomDailyPage.max_lesson then
		return true
	end
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
		if(not ParacraftLearningRoomDailyPage.isLoading) then
			ParacraftLearningRoomDailyPage.isLoading = true
			NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NplBrowserLoaderPage.lua");
			local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
			NplBrowserLoaderPage.Check(function(bLoaded)
				if(bLoaded) then
					ParacraftLearningRoomDailyPage.OnOpenWeb(index,bCheckVip)
				end
				ParacraftLearningRoomDailyPage.isLoading = false
			end)
		else
			_guihelper.MessageBox(L"正在加载内置浏览器，请稍等！");
		end
		return
    end

	index = tonumber(index)
	
	if(index <= 16)then
		bCheckVip = false;
	end

	local studyFunc = function (is_association_vip)
		if(bCheckVip and not ParacraftLearningRoomDailyPage.IsVip()) and not System.User.isVipSchool and not is_association_vip then
			if(ParacraftLearningRoomDailyPage.IsFuture(index))then
				ParacraftLearningRoomDailyPage.OnVIP("DailyNote");
				--[[
				_guihelper.MessageBox(L"非VIP用户仅可观看已签到视频，是否开通VIP观看此视频？", function(res)
					if(res == _guihelper.DialogResult.OK) then
						ParacraftLearningRoomDailyPage.OnVIP("daily_note");
					else
						ParacraftLearningRoomDailyPage.ShowPage();
					end
				end, _guihelper.MessageBoxButtons.OKCancel_CustomLabel_Highlight_Right,nil,nil,nil,nil,{ ok = L"立即开通", cancel = L"暂不开通", title = L"开通VIP", });
				]]
				return
			end
		end
		if(index < 1)then
			index = 1;
		end
		LOG.std(nil, "debug", "ParacraftLearningRoomDailyPage.OnOpenWeb", index);
		local url = string.format("https://keepwork.com/official/tips/s1/1_%d",index);
		local start_time = os.time()
		local title = ParacraftLearningRoomDailyPage.GetTitle(index);

		RedSummerCampPPtPage.StartTask("dailyVideo")
		GameLogic.GetFilters():apply_filters("user_behavior", 2, "duration.learning_daily", { started = true, learningIndex = index });
		if System.os.GetPlatform() ~= 'win32' then
			-- 除了win32平台，使用默认浏览器打开视频教程
			local cmd = string.format("/open %s", url);
			GameLogic.RunCommand(cmd);
			if not ParacraftLearningRoomDailyPage.HasCheckedToday() then
				local exid = ParacraftLearningRoomDailyPage.exid;
				KeepWorkItemManager.DoExtendedCost(exid, function()
	
					if(ParacraftLearningRoomDailyPage.is_red_summercamp)then
						ParacraftLearningRoomDailyPage.SaveToLocal(ParacraftLearningRoomDailyPage.ShowPage_RedSummerCamp);
					else
						ParacraftLearningRoomDailyPage.SaveToLocal(ParacraftLearningRoomDailyPage.ShowPage);
					end
	
					local reward_num = DailyTaskManager.GetTaskRewardNum(ParacraftLearningRoomDailyPage.exid)
					local desc = string.format("为你的学习点赞，奖励你%s个知识豆，再接再厉哦~", reward_num)
					GameLogic.AddBBS("desktop", desc, 3000, "0 255 0"); 
	
					QuestAction.SetDailyTaskValue("40009_1",1)
					RedSummerCampPPtPage.OnCloseDailyVideo()
				end, function()
					_guihelper.MessageBox(L"签到失败！");
				end)
			end
			return
		end
	
		NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/BackgroundMusic.lua");
		local BackgroundMusic = commonlib.gettable("MyCompany.Aries.Game.Sound.BackgroundMusic");
		BackgroundMusic:Silence()
		
		NplBrowserManager:CreateOrGet("DailyCheckBrowser"):Show(url, title, false, true, { scale_screen = "4:3:v", closeBtnTitle = L"退出" }, function(state)
			if(state == "ONCLOSE")then
				BackgroundMusic:Recover()
				GameLogic.GetFilters():apply_filters("user_behavior", 2, "duration.learning_daily", { ended = true, learningIndex = index });
				NplBrowserManager:CreateOrGet("DailyCheckBrowser"):GotoEmpty();
				RedSummerCampPPtPage.OnCloseDailyVideo()
				-- 如果不是今天的签到课，就直接返回
				if(not ParacraftLearningRoomDailyPage.IsNextDay(index))then
					return
				end
				local end_time = os.time()
				if not ParacraftLearningRoomDailyPage.HasCheckedToday() and end_time - start_time >= 20 then
					local exid = ParacraftLearningRoomDailyPage.exid;
					KeepWorkItemManager.DoExtendedCost(exid, function()
	
						if(ParacraftLearningRoomDailyPage.is_red_summercamp)then
							ParacraftLearningRoomDailyPage.SaveToLocal(ParacraftLearningRoomDailyPage.ShowPage_RedSummerCamp);
						else
							ParacraftLearningRoomDailyPage.SaveToLocal(ParacraftLearningRoomDailyPage.ShowPage);
						end
	
						local reward_num = DailyTaskManager.GetTaskRewardNum(ParacraftLearningRoomDailyPage.exid)
						local desc = string.format("为你的学习点赞，奖励你%s个知识豆，再接再厉哦~", reward_num)
						GameLogic.AddBBS("desktop", desc, 3000, "0 255 0"); 
	
						QuestAction.SetDailyTaskValue("40009_1",1)
					end, function()
						_guihelper.MessageBox(L"签到失败！");
					end)
				else
					if(ParacraftLearningRoomDailyPage.is_red_summercamp)then
						ParacraftLearningRoomDailyPage.ShowPage_RedSummerCamp();
					else
						ParacraftLearningRoomDailyPage.ShowPage();
					end
				end
			end
		end);
	end
	if bCheckVip then
		keepwork.permissions.check({
			featureName = "LP_CommunityCourses",
		},function(err, msg, data)
			if err == 200 then
				studyFunc(data.data)
			end
		end) 
	else
		studyFunc()
	end

end

function ParacraftLearningRoomDailyPage.OnLearningLand()
	if(not KeepWorkItemManager.GetToken())then
		GameLogic.CheckSignedIn(L"此功能需要登陆后才能使用",
			function(result)
				if (result) then
					ParacraftLearningRoomDailyPage.OnLearningLand()
				end
			end)
		return
	end

	local learning = function()
		KeepWorkItemManager.GetFilter():remove_all_filters("loaded_all");
		GameLogic.RunCommand(format("/loadworld -s -force %d", ParaWorldLoginAdapter.GetDefaultWorldID()));
		--[[
		local template = KeepWorkItemManager.GetItemTemplate(TeachingQuestPage.totalTaskGsid);
		if (template) then
			if (TeachingQuestPage.MainWorldId == nil) then
				-- TeachingQuestPage.MainWorldId = template.extension;
				TeachingQuestPage.MainWorldId = tostring(template.desc);
			end
			GameLogic.RunCommand(format("/loadworld -s -force %d", ParaWorldLoginAdapter.GetDefaultWorldID()));
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
function ParacraftLearningRoomDailyPage.OnVIP(from)
	GameLogic.IsVip(from, true, function(result)
		if result then
			ParacraftLearningRoomDailyPage:Refresh();
		end
	end);
end