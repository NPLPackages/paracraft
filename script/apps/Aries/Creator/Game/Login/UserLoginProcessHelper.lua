--[[
Title: UserLoginProcess
Author(s): LiXizhi
Date: 2014/1/14
Desc: Helper Class
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/UserLoginProcessHelper.lua");
UserLoginProcess.Fail(msg, state, callbackFunc)
UserLoginProcess.HideProgressUI()
UserLoginProcess.ShowProgress(msg, percentage, step)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local MainLogin = commonlib.gettable("MyCompany.Aries.Game.MainLogin");
local UserLoginProcess = commonlib.gettable("MyCompany.Aries.Game.UserLoginProcess")
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")

-- whether to use flash loader
local bUseFlashLoader = false;

-- current login procentage. 
UserLoginProcess.percentage = 0;

-- Display error message and go back to login page. 
-- @msg: text to shown in message box
-- @state: nil or a table to pass to MainLogin:next_step(). if nil it defaults to {IsLoginStarted = false}
-- @callbackFunc: a callback function to be invoked
function UserLoginProcess.Fail(msg, state, callbackFunc)
	if(bUseFlashLoader)then
		Map3DSystem.App.MiniGames.SwfLoadingBarPage.UpdateText(nil);
		Map3DSystem.App.MiniGames.SwfLoadingBarPage.ClosePage();
	end
	UserLoginProcess.percentage = 0;
	
	_guihelper.MessageBox(msg or "无法登录, 未知错误", callbackFunc, _guihelper.MessageBoxButtons.OK);
	
	MainLogin:reset_user_login_steps();
	--MainLogin:next_step(state or {IsLoginModeSelected = false});
end

function UserLoginProcess.HideProgressUI()
	if(bUseFlashLoader)then
		Map3DSystem.App.MiniGames.SwfLoadingBarPage.UpdateText(nil);
		Map3DSystem.App.MiniGames.SwfLoadingBarPage.ClosePage();
	end
end

-- display current progress. Pass nil to all params like UserLoginProcess.ShowProgress(); will hide UI. 
-- @param msg: message string. If nil, it means 100% finished. 
-- @param percentage: value in [0,100]. If nil, it will just increase the self.percentage by step or 10. 
-- @param step: the step to increase when percentage is nil. default to 10. 
function UserLoginProcess.ShowProgress(msg, percentage, step)
	if(percentage) then
		UserLoginProcess.percentage = percentage;
	else
		UserLoginProcess.percentage = UserLoginProcess.percentage + (step or 10);
		if(UserLoginProcess.percentage >= 100) then
			UserLoginProcess.percentage = 99
		end
	end
	if(not msg) then
		UserLoginProcess.percentage = 100;
	end
	
	-- commonlib.echo({"ShowProgress", msg})
	
	-- TODO: leio, update Loader UI here. message is {text=msg, percent = UserLoginProcess.percentage}, msg may be nil, percent is [0,100]
	if(bUseFlashLoader)then
		local p = UserLoginProcess.percentage or 0;
		if(p == 0)then
			Map3DSystem.App.MiniGames.SwfLoadingBarPage.ShowPage(
				{ top = -50 }
			);
		else
			Map3DSystem.App.MiniGames.SwfLoadingBarPage.ShowPage({top = -50});
		end
		p = p / 100;
		Map3DSystem.App.MiniGames.SwfLoadingBarPage.Update(p);
		Map3DSystem.App.MiniGames.SwfLoadingBarPage.UpdateText(msg);
		if(p == 1)then
			Map3DSystem.App.MiniGames.SwfLoadingBarPage.UpdateText(nil);
			Map3DSystem.App.MiniGames.SwfLoadingBarPage.ClosePage();
		end
	else
		_guihelper.MessageBox(msg, nil, _guihelper.MessageBoxButtons.Nothing);
	end
end

