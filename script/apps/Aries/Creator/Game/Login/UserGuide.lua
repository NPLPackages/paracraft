--[[
Title: UserGuide.html code-behind script
Author(s): chenjinxian
Date: 
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/UserGuide.lua");
local UserGuide = commonlib.gettable("MyCompany.Aries.Game.MainLogin.UserGuide")
UserGuide.ShowPage()
-------------------------------------------------------
]]

local UserGuide = commonlib.gettable("MyCompany.Aries.Game.MainLogin.UserGuide")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local page;
local timer;
local isMouseDown = false;
local isMouseMove = false;
local groupindex_hint = 4;
local groupindex_hint_bling = 5;
local groupindex_hint_auto = 6;

function UserGuide.OnInit()
	if(UserGuide.bounce == nil and UserGuide.bar == nil) then
		UserGuide.bounce = UIAnimManager.LoadUIAnimationFile("script/UIAnimation/CommonBounce.lua.table");
		UserGuide.bar = UIAnimManager.LoadUIAnimationFile("script/UIAnimation/CommonBar.lua.table");
	end
	page = document:GetPageCtrl();
end

function UserGuide.ShowPage(param)
	System.App.Commands.Call("File.MCMLWindowFrame", {
		url = "script/apps/Aries/Creator/Game/Login/UserGuide.html"..param, 
		name = "UserGuide.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = false,
		bShow = true,
		zorder = 2000,
		click_through = true,
		directPosition = true,
		align = "_fi", 
		x = 0,
		y = 0,
		width = 0,
		height = 0,
	});
	GameLogic:Connect("WorldUnloaded", UserGuide, UserGuide.OnWorldUnload, "UniqueConnection");
end

function UserGuide:OnWorldUnload()
	UserGuide.CloseWindow();
end

function UserGuide.OnMouseDown(nCode, appName, msg)
	local input = Map3DSystem.InputMsg;
	if(input.mouse_button == "right") then	
		isMouseDown = true;
	end
end

function UserGuide.OnMouseMove(nCode, appName, msg)
	if(isMouseDown) then
		isMouseMove = true;
	else
		isMouseMove = false;
	end
end

function UserGuide.OnMouseMove2(nCode, appName, msg)
	local input = Map3DSystem.InputMsg;
	local Screen = commonlib.gettable("System.Windows.Screen");
	local arrow = page and page:FindControl("down_arrow");
	if(arrow) then
		if (not arrow.visible) then
			arrow.visible = true;
		end
		local x, y, width, height = arrow:GetAbsPosition();
		arrow:Reposition("lt", input.mouse_x - Screen:GetWidth() / 2 - 224, input.mouse_y - Screen:GetHeight() / 2 - 40, width, height);
	end
end

function UserGuide.OnMouseMove3(nCode, appName, msg)
	local input = Map3DSystem.InputMsg;
	local Screen = commonlib.gettable("System.Windows.Screen");
	local arrow = page and page:FindControl("down_arrow2");
	if(arrow) then
		if (not arrow.visible) then
			arrow.visible = true;
		end
		local x, y, width, height = arrow:GetAbsPosition();
		arrow:Reposition("lt", input.mouse_x - Screen:GetWidth() / 2 - 224, input.mouse_y - Screen:GetHeight() / 2 - 40, width, height);
	end
end

function UserGuide.OnMouseUp(nCode, appName, msg)
	local input = Map3DSystem.InputMsg;
	if(input.mouse_button == "right") then
		if(isMouseDown and isMouseMove) then
			UserGuide.Step3();
		else
			isMouseDown = false;
		end
	end	
end

function UserGuide.OnKeyDown(nCode, appName, msg)
	if (UserGuide.isStep1) then
		if(ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_W) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_S) or
			ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_A) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_D)) then
			UserGuide.Step2();
		end
	end
	if(ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_ESCAPE)) then
		_guihelper.MessageBox(L"是否立即退出【新手引导】？", function(res)
			if(res and res == _guihelper.DialogResult.Yes) then
				UserGuide.CloseWindow();
			end
		end, _guihelper.MessageBoxButtons.YesNo);
	end
end

function UserGuide:HighlightPickBlock(event)
	ParaTerrain.SelectBlock(event.x, event.y + 1, event.z, event.select, groupindex_hint_bling);
end

function UserGuide:ClearPickDisplay(event)
	ParaTerrain.DeselectAllBlock(groupindex_hint_bling);
end

function UserGuide.Step1()
	UserGuide.isStep1 = true;
	local param = "?name=step1";
	UserGuide.ShowPage(param);
	CommonCtrl.os.hook.SetWindowsHook({hookType = CommonCtrl.os.hook.HookType.WH_CALLWNDPROC,
		callback = UserGuide.OnKeyDown, hookName = "UserGuideKeyDown", appName = "input", wndName = "key_down"});
	local index = 1;
	timer = commonlib.Timer:new({callbackFunc = function(timer)
		_guihelper.SetUIColor(page:FindControl("key_w"), index == 1 and "#FBBB09" or "#FFFFFF");
		_guihelper.SetUIColor(page:FindControl("key_s"), index == 2 and "#FBBB09" or "#FFFFFF");
		_guihelper.SetUIColor(page:FindControl("key_a"), index == 3 and "#FBBB09" or "#FFFFFF");
		_guihelper.SetUIColor(page:FindControl("key_d"), index == 4 and "#FBBB09" or "#FFFFFF");
		index = index + 1;
		if(index == 5) then index = 1 end
	end})
	timer:Change(0, 500);
end

function UserGuide.Step2()
	UserGuide.isStep1 = false;
	timer:Change();
	local param = "?name=step2";
	UserGuide.ShowPage(param);
	CommonCtrl.os.hook.SetWindowsHook({hookType = CommonCtrl.os.hook.HookType.WH_CALLWNDPROC,
		callback = UserGuide.OnMouseDown, hookName = "UserGuideMouseDown", appName = "input", wndName = "mouse_down"});
	CommonCtrl.os.hook.SetWindowsHook({hookType = CommonCtrl.os.hook.HookType.WH_CALLWNDPROC,
		callback = UserGuide.OnMouseMove, hookName = "UserGuideMouseMove", appName = "input", wndName = "mouse_move"});
	CommonCtrl.os.hook.SetWindowsHook({hookType = CommonCtrl.os.hook.HookType.WH_CALLWNDPROC,
		callback = UserGuide.OnMouseUp, hookName = "UserGuideMouseUp", appName = "input", wndName = "mouse_up"});
end

function UserGuide.Step3()
	CommonCtrl.os.hook.UnhookWindowsHook({hookName = "UserGuideMouseDown", hookType = CommonCtrl.os.hook.HookType.WH_CALLWNDPROC});
	CommonCtrl.os.hook.UnhookWindowsHook({hookName = "UserGuideMouseMove", hookType = CommonCtrl.os.hook.HookType.WH_CALLWNDPROC});
	CommonCtrl.os.hook.UnhookWindowsHook({hookName = "UserGuideMouseUp", hookType = CommonCtrl.os.hook.HookType.WH_CALLWNDPROC});
	local param = "?name=step3";
	UserGuide.ShowPage(param);
	GameLogic.events:AddEventListener("ShowCreatorDesktop", UserGuide.Step4, UserGuide, "UserGuide");
end

function UserGuide:Step4(event)
	if(event.bShow) then
		GameLogic.events:RemoveEventListener("ShowCreatorDesktop", UserGuide.Step4, UserGuide);
		local param = "?name=step4";
		UserGuide.ShowPage(param);
		GameLogic.events:AddEventListener("SetBlockInRightHand", UserGuide.Step5, UserGuide, "UserGuide");
	end
end

function UserGuide:Step5(event)
	GameLogic.events:RemoveEventListener("SetBlockInRightHand", UserGuide.Step5, UserGuide);
	local param = "?name=step5";
	UserGuide.ShowPage(param);
	GameLogic.events:AddEventListener("ShowCreatorDesktop", UserGuide.Step6, UserGuide, "UserGuide");
end

function UserGuide:Step6(event)
	if(not event.bShow) then
		GameLogic.events:RemoveEventListener("ShowCreatorDesktop", UserGuide.Step6, UserGuide);
		local param = "?name=step6";
		UserGuide.ShowPage(param);
		local ctl = page and page:FindControl("down_arrow")
		if(ctl) then
			ctl.visible = false;
		end
		CommonCtrl.os.hook.SetWindowsHook({hookType = CommonCtrl.os.hook.HookType.WH_CALLWNDPROC,
			callback = UserGuide.OnMouseMove2, hookName = "UserGuideMouseMove", appName = "input", wndName = "mouse_move"});
		GameLogic.events:AddEventListener("HighlightPickBlock", UserGuide.HighlightPickBlock, UserGuide, "UserGuide");
		GameLogic.events:AddEventListener("ClearPickDisplay", UserGuide.ClearPickDisplay, UserGuide, "UserGuide");
		GameLogic.events:AddEventListener("CreateBlockTask", UserGuide.Step7, UserGuide, "UserGuide");
	end
end

function UserGuide:Step7(event)
	CommonCtrl.os.hook.UnhookWindowsHook({hookName = "UserGuideMouseMove", hookType = CommonCtrl.os.hook.HookType.WH_CALLWNDPROC});
	GameLogic.events:RemoveEventListener("CreateBlockTask", UserGuide.Step7, UserGuide);
	page:CloseWindow();
	local param = "?name=step7";
	UserGuide.ShowPage(param);
	local ctl = page and page:FindControl("down_arrow2")
	if(ctl) then
		ctl.visible = false;
	end
	CommonCtrl.os.hook.SetWindowsHook({hookType = CommonCtrl.os.hook.HookType.WH_CALLWNDPROC,
		callback = UserGuide.OnMouseMove3, hookName = "UserGuideMouseMove", appName = "input", wndName = "mouse_move"});
	GameLogic.events:AddEventListener("DestroyBlockTask", UserGuide.Step8, UserGuide, "UserGuide");
end

function UserGuide:Step8(event)
	CommonCtrl.os.hook.UnhookWindowsHook({hookName = "UserGuideMouseMove", hookType = CommonCtrl.os.hook.HookType.WH_CALLWNDPROC});
	GameLogic.events:RemoveEventListener("DestroyBlockTask", UserGuide.Step8, UserGuide);
	GameLogic.events:RemoveEventListener("HighlightPickBlock", UserGuide.HighlightPickBlock, UserGuide);
	GameLogic.events:RemoveEventListener("ClearPickDisplay", UserGuide.ClearPickDisplay, UserGuide);
	ParaTerrain.DeselectAllBlock(groupindex_hint_bling);
	local param = "?name=step8";
	UserGuide.ShowPage(param);
	GameLogic.events:AddEventListener("ShowCreatorDesktop", UserGuide.Step9, UserGuide, "UserGuide");
end

function UserGuide:Step9(event)
	if(event.bShow) then
		GameLogic.events:RemoveEventListener("ShowCreatorDesktop", UserGuide.Step9, UserGuide);
		local param = "?name=step9";
		UserGuide.ShowPage(param);
		GameLogic.events:AddEventListener("ShowHelpMenu", UserGuide.Step10, UserGuide, "UserGuide");
	end
end

function UserGuide:Step10(event)
	GameLogic.events:RemoveEventListener("ShowHelpMenu", UserGuide.Step10, UserGuide);
	local param = "?name=step10";
	UserGuide.ShowPage(param);
	GameLogic.events:AddEventListener("ShowHelpPage", UserGuide.StepEnd, UserGuide, "UserGuide");
end

function UserGuide:StepEnd(event)
	GameLogic.events:RemoveEventListener("ShowHelpPage", UserGuide.Step10, UserGuide);
	_guihelper.MessageBox(L"恭喜完成新手引导，点击确定之后在【帮助 F1】中探索更多帮助内容");
	UserGuide.CloseWindow();
end

function UserGuide.CloseWindow()
	GameLogic.events:RemoveEventListener("ShowCreatorDesktop", UserGuide.Step4, UserGuide);
	GameLogic.events:RemoveEventListener("SetBlockInRightHand", UserGuide.Step5, UserGuide);
	GameLogic.events:RemoveEventListener("ShowCreatorDesktop", UserGuide.Step6, UserGuide);
	GameLogic.events:RemoveEventListener("CreateBlockTask", UserGuide.Step7, UserGuide);
	GameLogic.events:RemoveEventListener("DestroyBlockTask", UserGuide.Step8, UserGuide);
	GameLogic.events:RemoveEventListener("HighlightPickBlock", UserGuide.HighlightPickBlock, UserGuide);
	GameLogic.events:RemoveEventListener("ClearPickDisplay", UserGuide.ClearPickDisplay, UserGuide);
	GameLogic.events:RemoveEventListener("ShowCreatorDesktop", UserGuide.Step9, UserGuide);
	GameLogic.events:RemoveEventListener("ShowHelpMenu", UserGuide.Step10, UserGuide);
	GameLogic.events:RemoveEventListener("ShowHelpPage", UserGuide.Step10, UserGuide);
	CommonCtrl.os.hook.UnhookWindowsHook({hookName = "UserGuideMouseDown", hookType = CommonCtrl.os.hook.HookType.WH_CALLWNDPROC});
	CommonCtrl.os.hook.UnhookWindowsHook({hookName = "UserGuideMouseMove", hookType = CommonCtrl.os.hook.HookType.WH_CALLWNDPROC});
	CommonCtrl.os.hook.UnhookWindowsHook({hookName = "UserGuideMouseUp", hookType = CommonCtrl.os.hook.HookType.WH_CALLWNDPROC});
	CommonCtrl.os.hook.UnhookWindowsHook({hookName = "UserGuideKeyDown", hookType = CommonCtrl.os.hook.HookType.WH_CALLWNDPROC});
	if (page) then
		page:CloseWindow();
	end
end