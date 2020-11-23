--[[
Title: StudyPage
Author(s): 
Date: 2020/8/7
Desc:  
Use Lib:
-------------------------------------------------------
local StudyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/StudyPage.lua");
StudyPage.ShowPage();
--]]
local StudyPage = NPL.export()
local page
local grid_type_list = {
	study = 1,
	knowledge_island = 2,
	art_of_war = 3,
	video_res = 4,
	doc = 5,
	baidu_konw = 6,
}
local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Session.lua")
local ParacraftLearningRoomDailyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParacraftLearningRoom/ParacraftLearningRoomDailyPage.lua");
-- local WorldList = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/WorldList.lua")
local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")

function StudyPage.OnInit()
    page = document:GetPageCtrl();
end

function StudyPage.ShowPage()
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/User/StudyPage.html",
			name = "StudyPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			zorder = 0,
			--app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -610/2,
				y = -400/2,
				width = 610,
				height = 400,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end
function StudyPage.GetPageCtrl()
    return page;
end
function StudyPage.clickGridItem(item_data)
	commonlib.echo(item_data, true)
	if nil == item_data then
		return
	end
	
	if item_data.click_cb then
		item_data.click_cb()
	end
end

function StudyPage.clickStudy()
    if(KeepworkServiceSession:IsSignedIn())then
        ParacraftLearningRoomDailyPage.DoCheckin();
        return
    end
    LoginModal:CheckSignedIn(L"请先登录", function(result)
        if result == true then
            Mod.WorldShare.Utils.SetTimeOut(function()
                if result then
                    -- WorldList:RefreshCurrentServerList()
                    local ParacraftLearningRoomDailyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParacraftLearningRoom/ParacraftLearningRoomDailyPage.lua");
                    ParacraftLearningRoomDailyPage.DoCheckin();
                end
            end, 500)
        end
    end)
end

function StudyPage.clickKnowledgeIsland()
	local TeachingQuestLinkPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/TeachingQuestLinkPage.lua");
	TeachingQuestLinkPage.ShowPage();
	-- if(KeepworkServiceSession:IsSignedIn())then
	-- 	ParacraftLearningRoomDailyPage.OnLearningLand();
	-- 	return
	-- end
	-- LoginModal:CheckSignedIn(L"请先登录", function(result)
	-- 	if result == true then
	-- 		Mod.WorldShare.Utils.SetTimeOut(function()
	-- 			if result then
	-- 				-- WorldList:RefreshCurrentServerList()
	-- 				local ParacraftLearningRoomDailyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParacraftLearningRoom/ParacraftLearningRoomDailyPage.lua");
	-- 				ParacraftLearningRoomDailyPage.OnLearningLand();
	-- 			end
	-- 		end, 300)
	-- 	end
	-- end)
end

function StudyPage.clickArtOfWar()
	-- _guihelper.MessageBox("敬请期待")
	local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon");
	local info = string.format(L"即将离开【%s】进入【%s】", WorldCommon.GetWorldTag("name") or "", L"孙子兵法");
	_guihelper.MessageBox(info, function(res)
		if(res and res == _guihelper.DialogResult.OK) then
			local word_id = 19405
			local UserConsole = NPL.load("(gl)Mod/WorldShare/cellar/UserConsole/Main.lua")
			UserConsole:HandleWorldId(word_id, "force");
		end
	end, _guihelper.MessageBoxButtons.OKCancel);
end

function StudyPage.clickVideoRes()
	ParaGlobal.ShellExecute("open", "https://keepwork.com/official/paracraft/VideoTutorials", "", "", 1); 
end

function StudyPage.clickDoc()
	ParaGlobal.ShellExecute("open", "https://keepwork.com/official/docs/index", "", "", 1); 
end

function StudyPage.clickBaiduKnow()
	ParaGlobal.ShellExecute("open", "https://zhidao.baidu.com/search?lm=0&rn=10&pn=0&fr=search&ie=gbk&word=paracraft", "", "", 1); 
end

function StudyPage.onclickTieBa()
	ParaGlobal.ShellExecute("open", "https://tieba.baidu.com/f?kw=paracraft&fr=index", "", "", 1); 
end

StudyPage.grid_data_sources = {
	{name="成长日记", type = grid_type_list.study, click_cb = StudyPage.clickStudy},
	{name="每周实战", type = grid_type_list.knowledge_island, click_cb = StudyPage.clickKnowledgeIsland},
	{name="玩学课堂", type = grid_type_list.art_of_war, click_cb = StudyPage.clickArtOfWar},
	{name="视频资源", type = grid_type_list.video_res, click_cb = StudyPage.clickVideoRes},
	{name="文档资料", type = grid_type_list.doc, click_cb = StudyPage.clickDoc},
	{name="百度知道", type = grid_type_list.baidu_konw, click_cb = StudyPage.clickBaiduKnow},
}