--[[
Title: CodePyToNplPage
Author(s): leio
Date: 2019.9.24
Desc: 
checking convert python to npl codes
this conversion is depend on https://github.com/tatfook/PyRuntime
set command line args to test: pytonpl="true" 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodePyToNplPage.lua");
local CodePyToNplPage = commonlib.gettable("MyCompany.Aries.Game.Code.CodePyToNplPage");
CodePyToNplPage.ShowPage();
------------------------------------------------------------
]]
local CodePyToNplPage = commonlib.gettable("MyCompany.Aries.Game.Code.CodePyToNplPage");

CodePyToNplPage.codes = "";
CodePyToNplPage.page = nil;

function CodePyToNplPage.OnInit()
    CodePyToNplPage.page = document.GetPageCtrl();
end
function CodePyToNplPage.ShowPage(codes,callback)
    CodePyToNplPage.codes = codes;
    CodePyToNplPage.callback = callback;
    local params = {
		url = "script/apps/Aries/Creator/Game/Code/CodePyToNplPage.html", 
		name = "CodePyToNplPage.ShowPage", 
		app_key=MyCompany.Aries.app.app_key, 
		isShowTitleBar = false,
		DestroyOnClose = true, 
		bToggleShowHide = true,
		enable_esc_key = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		zorder = zorder,
		directPosition = true,
			align = "_lt",
            x = 0,
			y = 0,
			width = 500,
			height = 600,
			cancelShowAnimation = true,
	}
	System.App.Commands.Call("File.MCMLWindowFrame", params);	
end

function CodePyToNplPage.OnClose()
    CodePyToNplPage.page:CloseWindow(true);
end
function CodePyToNplPage.GetInputText()
    return CodePyToNplPage.codes;
end
function CodePyToNplPage.OnConvert()
	local py_code_ctrl = CodePyToNplPage.page:FindControl("py_code");
    local py_codes = py_code_ctrl:GetText();
    local pyruntime = NPL.load("Mod/PyRuntime/Transpiler.lua")
    pyruntime:transpile(py_codes, function(res)
        local lua_code = res.lua_code;
        if(not lua_code)then
            local error_msg = res.error_msg;
	        LOG.std(nil, "error", "CodePyToNplPage", error_msg);
            _guihelper.MessageBox(error_msg);
            return
        end
        local npl_code_ctrl = CodePyToNplPage.page:FindControl("npl_code");
        npl_code_ctrl:SetText(lua_code)
    end)
end
