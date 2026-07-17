--[[
Title: Macro Recorder
Author(s): LiXizhi
Date: 2021/1/4
Desc: Macro Recorder page

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroRecorder.lua");
local MacroRecorder = commonlib.gettable("MyCompany.Aries.Game.Tasks.MacroRecorder");
MacroRecorder.ShowPage();
-------------------------------------------------------
]]
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local MacroRecorder = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.MacroRecorder"));
local page;

function MacroRecorder.OnInit()
	page = document:GetPageCtrl();
	GameLogic.GetFilters():add_filter("Macro_EndRecord", MacroRecorder.OnMacroStopped);
	GameLogic.GetFilters():add_filter("Macro_AddRecord", MacroRecorder.OnNewMacroRecorded);
end

-- @param duration: in seconds
function MacroRecorder.ShowPage()
	local params = {
		url = "script/apps/Aries/Creator/Game/Macros/MacroRecorder.html", 
		name = "MacroRecorderTask.ShowPage", 
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		isShowTitleBar = false,
		bShow = true,
		DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
		style = CommonCtrl.WindowFrame.ContainerStyle,
		zorder = 1000,
		allowDrag = true,
		isPinned = true,
		directPosition = true,
			align = "_lt",
			x = 10,
			y = 10,
			width = 64,
			height = 32,
	}
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	MacroRecorder.ShowMacroRecordArea(true)
	params._page.OnClose = function()
		page = nil;
	end;
end

function MacroRecorder.OnMacroStopped()
	MacroRecorder.CloseWindow();
end

function MacroRecorder.OnNewMacroRecorded(count)
	if(page and count) then
		page:SetUIValue("text", tostring(count))
	end
	return count;
end

function MacroRecorder.CloseWindow()
	if(page) then
		page:CloseWindow();
		page = nil;
	end
	MacroRecorder.ShowMacroRecordArea(false)
end

function MacroRecorder.OnStop()
	MacroRecorder.CloseWindow();
	Macros:Stop();
end

function MacroRecorder.OnClickAddSubTitle()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroAddSubTitle.lua");
	local MacroAddSubTitle = commonlib.gettable("MyCompany.Aries.Game.Tasks.MacroAddSubTitle");
	MacroAddSubTitle.ShowPage();
end

function MacroRecorder.ShowMacroRecordArea(bShow)
	if bShow then
		GameLogic.RunCommand("/ggs user hidden")
	else
		GameLogic.RunCommand("/ggs user visible")
	end
    local _parent = ParaUI.GetUIObject("RecordSafeArea");
    if(not bShow) then
        if(_parent:IsValid()) then
            _parent.visible = false;
            ParaUI.Destroy(_parent.id);
        end
        return;
    else
        if(not _parent:IsValid()) then
            local margin_top, margin_bottom,margin_left =102,90,80
			local border_width = 6;
            _parent = ParaUI.CreateUIObject("container", "RecordSafeArea", "_fi", 0,0,0,0);
            _parent.background = "";
            _parent.enabled = false;
            _parent.zorder = -100;
            _parent:AttachToRoot();

            local _border = ParaUI.CreateUIObject("container", "border", "_fi", 0,0,0,0);
            _border.background = "";
            _border.enabled = false;
            _parent:AddChild(_border);

            local _this = ParaUI.CreateUIObject("container", "top", "_mt", margin_left, margin_top, margin_left, border_width);
            _this.background = "Texture/whitedot.png";
            _this.enabled = false;
            _border:AddChild(_this);

            local _this = ParaUI.CreateUIObject("container", "left", "_ml", margin_left, margin_top, border_width, margin_bottom);
            _this.background = "Texture/whitedot.png";
            _this.enabled = false;
            _border:AddChild(_this);

            local _this = ParaUI.CreateUIObject("container", "right", "_mr", margin_left, margin_top, border_width, margin_bottom);
            _this.background = "Texture/whitedot.png";
            _this.enabled = false;
            _border:AddChild(_this);
            
            local _this = ParaUI.CreateUIObject("container", "bottom", "_mb", margin_left, margin_bottom, margin_left, border_width);
            _this.background = "Texture/whitedot.png";
            _this.enabled = false;
            _border:AddChild(_this);
			_border.colormask = "255 0 0 30";
			_border:ApplyAnim();
        end
        _parent.visible = true;
    end
end