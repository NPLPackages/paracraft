--[[
    Author: <pbb>
    Date: 2024/05/15
    Description: This script is used to create a community notification page.
    useLib:
        local CommunityNotification = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Notification/CommunityNotification.lua")
        CommunityNotification.ShowPage()
]]

local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local NotificationManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/Notification/NotificationManager.lua")

local CommunityNotification = NPL.export()
CommunityNotification.email_list = {}
CommunityNotification.conten_data = {{},}

local page
function CommunityNotification.OnInit()
    page = document:GetPageCtrl()
end

function CommunityNotification.ShowPage()
    if(GameLogic.GetFilters():apply_filters('is_signed_in'))then
        CommunityNotification.ShowView()
        return
	end
	
	GameLogic.GetFilters():apply_filters('check_signed_in', L"请先登录", function(result)
        if result == true then
            commonlib.TimerManager.SetTimeout(function()
                if result then
					CommunityNotification.ShowView()
                end
            end, 500)
        end
	end)
end


function CommunityNotification.ShowView()
    local view_width = 0
	local view_height = 0
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/Community/Notification/CommunityNotification.html",
			name = "CommunityNotification.Show", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			enable_esc_key = true,
			zorder = 2,
			--app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			isTopLevel = true,
			directPosition = true,
				align = "_fi",
				x = -view_width/2,
				y = -view_height/2,
				width = view_width,
				height = view_height,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

    NotificationManager.Init()
end

function CommunityNotification.CloseView()
    CommunityNotification.isOpen = false
    CommunityNotification.select_email_idx = -1
    CommunityNotification.email_list = {}
end

function CommunityNotification.OnRefresh(time)
    if page then
        page:Refresh(time or 0)
    end
	
end

function CommunityNotification.IsVisible()
	return page:IsVisible()
end

function CommunityNotification.ClickEmailItem(index)
	if index < 0 then
		CommunityNotification.OnRefresh()
		return
	end
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.notification_page.click_email_item", { useNoId=true},nil,true);
    NotificationManager.cur_email_content = ""
	CommunityNotification.select_email_idx = index
	NotificationManager.SetEmailReaded(index)
	NotificationManager.ReadEmail(index)
end


function CommunityNotification.OnClickDeleteAll()
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.notification_page.click_delete_all", { useNoId=true},nil,true);
	_guihelper.MessageBox(L"是否需要删除全部邮件，删除后不可找回", function(res)
		if(res and res == _guihelper.DialogResult.Yes) then
			local ids = NotificationManager.GetAllEmailIds()
			NotificationManager.DeleteEmail(ids)
		end
	end, _guihelper.MessageBoxButtons.YesNo);
end

local isgetall = false
function CommunityNotification.OnClickGetAll()
	if not isgetall then
		GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.notification_page.click_get_all", { useNoId=true},nil,true);
		local ids = NotificationManager.GetAllUnGetRewardEmailIds()
		NotificationManager.GetEmailReward(ids)
		NotificationManager.SetEmailReaded(ids)
		isgetall = true
	end
	commonlib.TimerManager.SetTimeout(function()
		isgetall = false
	end, 500)
end


function CommunityNotification.OnClickDelete()
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.notification_page.click_delete", { useNoId=true},nil,true);
	_guihelper.MessageBox(L"是否需要删除当前邮件，删除后不可找回", function(res)
		if(res and res == _guihelper.DialogResult.Yes) then
			local id = CommunityNotification.select_email_idx
			NotificationManager.DeleteEmail(id)
		end
	end, _guihelper.MessageBoxButtons.YesNo);
end

function CommunityNotification.OnClickGet()
	GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.notification_page.click_get", { useNoId=true},nil,true);
    if not CommunityNotification.OnGetFunc then
        CommunityNotification.OnGetFunc = commonlib.debounce(function()
            CommunityNotification.OnClickGetImp()
        end,500)
    end
    CommunityNotification.OnGetFunc()
end

function CommunityNotification.OnClickGetImp()
    local id = CommunityNotification.select_email_idx
    if NotificationManager.IsHaveReward(id) then
        NotificationManager.GetEmailReward(id)
    else
        GameLogic.AddBBS(nil,"此邮件奖励已经领取过了~")
    end	
end

function CommunityNotification.SetEmailList(email_list)
	CommunityNotification.email_list = email_list
    CommunityNotification.OnRefresh()
end

function CommunityNotification.GetStrWithLength(str,length)
	--print("GetStrWithLength=====",str,length)
	local length = length or 0
	local str = str or ""
	local nStrLength = ParaMisc.GetUnicodeCharNum(str);
	if nStrLength > length then
		return ParaMisc.UniSubString(str, 1, length).."...";
	else
		return str;
	end
	
end

function CommunityNotification.GetEmailContent(str)
	-- print(str)
	local str = string.gsub(str,"<br>","<br />")
	str = string.gsub(str,"&nbsp"," ")
	str = string.gsub(str,"<p>","")
	str = string.gsub(str,"</p>","")
	str = string.gsub(str,";","")
	str = string.gsub(str,"&lt","<")
	str = string.gsub(str,"&gt",">")
	str = string.gsub(str,"\\"," ")
	-- print("str=============",str)
	return str
end

function CommunityNotification.GetTimeDescByAtTime(at_time)
	at_time = at_time or ""
	local time_stamp = commonlib.timehelp.GetTimeStampByDateTime(at_time)
	local date_desc = os.date("%Y-%m-%d", time_stamp)
	local time_desc = os.date("%H:%M", time_stamp)
	local desc = string.format("%s %s", date_desc, time_desc)
	return desc
end