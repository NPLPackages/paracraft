--[[
Title: MsgCenter
Author(s): yangguiyi
Date: 2020/10/10
Desc:  
Use Lib:
-------------------------------------------------------
local MsgCenter = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MsgCenter/MsgCenter.lua");
MsgCenter.Show();
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local KeepworkServiceSession = NPL.load("(gl)Mod/WorldShare/service/KeepworkService/Session.lua")
local LoginModal = NPL.load("(gl)Mod/WorldShare/cellar/LoginModal/LoginModal.lua")
local MsgCenter = NPL.export();
local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");

commonlib.setfield("MyCompany.Aries.Creator.Game.MsgCenter.MsgCenter", MsgCenter);
local page;
MsgCenter.isOpen = false
MsgCenter.ButtonData = {
	{name = "全部"},
	{name = "互动消息"},
	{name = "任务消息"},
	{name = "机构消息"},
	{name = "系统消息"},
}

MsgCenter.MsgType = {
	dian_zan = 1,		-- 点赞
	guan_zhu = 2,		-- 关注
	yao_qing = 3,		-- 邀请
	ping_lun = 4,		-- 评论
	tong_zhi = 5,		-- 通知
	cheng_zhang = 6,	-- 成长
	shi_zhan = 7,		-- 实战
	da_sai = 8, 		-- 大赛
	ji_gou = 9, 		-- 机构
	xi_tong = 10, 		-- 系统
	shen_qing = 11, 	-- 申请
}

MsgCenter.MsgList = {
	{msg_content1 = "希望小学的 ", msg_content2 = " 关注了你", msg_type = MsgCenter.MsgType.guan_zhu, time = 0, color_name = " 啊啊 "},
	{msg_content1 = "北京师范大学南山附属小学的 ", msg_content2 = " 申请加入项目《项目名称》", msg_type = MsgCenter.MsgType.shen_qing, time = 0, color_name = " 啊啊 "},
	{msg_content1 = "北京师范大学南山附属小学的 ", msg_content2 = " 觉得你的动画作品《作品名称》很赞", msg_type = MsgCenter.MsgType.dian_zan, time = 0, color_name = " 啊啊 "},
	{msg_content1 = "每日成长有新的学习任务", msg_content2 = "", msg_type = MsgCenter.MsgType.cheng_zhang, time = 0},
	{msg_content1 = "《3D校园建造大赛》已正式启动，点击查看去报名参赛吧", msg_content2 = "", msg_type = MsgCenter.MsgType.da_sai, time = 0},
	{msg_content1 = "北京师范大学南山附属小学的 ", msg_content2 = " 收藏了你的动画作品《作品名称》", msg_type = MsgCenter.MsgType.tong_zhi, time = 0, color_name = " 啊啊 "},
	{msg_content1 = "北京师范大学南山附属小学的 ", msg_content2 = " 评论了你的动画作品《作品名称》", msg_type = MsgCenter.MsgType.ping_lun, time = 0, color_name = " 啊啊 "},

}

MsgCenter.select_index = 1
function MsgCenter.OnInit()
	page = document:GetPageCtrl();
	page.OnClose = MsgCenter.CloseView
end

function MsgCenter.Show()
    if(KeepworkServiceSession:IsSignedIn())then
        MsgCenter.ShowView()
        return
    end
    LoginModal:CheckSignedIn(L"请先登录", function(result)
        if result == true then
            Mod.WorldShare.Utils.SetTimeOut(function()
                if result then
					MsgCenter.ShowView()
                end
            end, 500)
        end
	end)
end

function MsgCenter.ShowView()
	MsgCenter.isOpen = true
	local view_width = 640
	local view_height = 613
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/MsgCenter/MsgCenter.html",
			name = "MsgCenter.Show", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			zorder = 1,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -view_width/2,
				y = -view_height/2,
				width = view_width,
				height = view_height,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function MsgCenter.FlushView(only_refresh_grid)
	if only_refresh_grid then
		local gvw_name = "item_gridview";
		local node = page:GetNode(gvw_name);
		pe_gridview.DataBind(node, gvw_name, false);
	else
		MsgCenter.OnRefresh()
	end
end

function MsgCenter.OnRefresh()
    if(page)then
        page:Refresh(0.1);
    end
end

function MsgCenter.ClickItem(index)
	MsgCenter.select_index = index
	MsgCenter.OnRefresh()
end

function MsgCenter.CloseView()
	MsgCenter.isOpen = false
end