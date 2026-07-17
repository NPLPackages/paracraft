--[[
    author: pbb
    date: 2024-05-20
    description: 注销用户页面
    uselib:
     local RemoveAccount = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/RemoveAccount.lua")
     RemoveAccount.ShowPage()
]]

local RemoveAccount = NPL.export()

local page
function RemoveAccount.OnInit()
    page = document:GetPageCtrl()
end

function RemoveAccount.ShowPage()
    RemoveAccount.step = 1
    local view_width = 0
	local view_height = 0
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/Community/RemoveAccount.html",
			name = "RemoveAccount.Show", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			enable_esc_key = true,
			-- zorder = 2,
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
end

function RemoveAccount.OnClickNext()
    local isConfirm = page:GetValue("checkagree")
    if not isConfirm or isConfirm == "false" or isConfirm == false then
        GameLogic.AddBBS(nil, "请先阅读并同意协议")
        return
    end
    GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.remove_account.click_next", {useNoId=true},nil,true);
    if RemoveAccount.step == 1 then
        RemoveAccount.step = 2
        if page then
            page:Refresh(0)
        end
    end
end


function RemoveAccount.OnClickConfirm()
    local pwd = page:GetValue("password")
    if not pwd or
           type(pwd) ~= 'string' or
           pwd == '' then
           _guihelper.MessageBox(
                '请输入密码',
                nil,
                nil,
                {
                    src = 'Texture/Aries/Creator/keepwork/RedSummerCamp/lessonppt/tishi_70x48_32bits.png#0 0 70 48',
                    icon_width = 70,
                    icon_height = 48,
                    icon_x = 5,
                    icon_y = -14
                }
           )

            return
        end
        GameLogic.GetFilters():apply_filters("user_behavior", 1, "click.community.remove_account.click_remove", {useNoId=true},nil,true);
        Mod.WorldShare.MsgBox:Show(L'正在删除账号，请稍候...', nil, nil, 380, nil, 10, nil, nil, true)

        local KeepworkServiceSession = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/KeepworkServiceSession.lua')
        KeepworkServiceSession:RemoveAccount(pwd)
end

