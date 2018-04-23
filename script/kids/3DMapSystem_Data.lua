--[[
Title: The 3D Map System Database
Author(s): WangTian
Date: 2007/8/29
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystem_Data.lua");
------------------------------------------------------------

NOTE: all data presentation in Map3DSystem table and subtable
	  any lua file want to use the Map3DSystem table can load this file
]]
NPL.load("(gl)script/kids/3DMapSystemData/TableDef.lua");
NPL.load("(gl)script/kids/3DMapSystemData/options.lua");
NPL.load("(gl)script/kids/3DMapSystemData/world_db.lua");
NPL.load("(gl)script/kids/3DMapSystemData/WindowData.lua");
NPL.load("(gl)script/kids/3DMapSystemData/ChatData.lua");
NPL.load("(gl)script/kids/3DMapSystemData/BCSData.lua");
NPL.load("(gl)script/kids/3DMapSystemData/CCSData.lua");
NPL.load("(gl)script/kids/3DMapSystemData/DBAssets.lua");
NPL.load("(gl)script/kids/3DMapSystemData/AnimationData.lua");
NPL.load("(gl)script/kids/3DMapSystemUI/event_handlers.lua");
NPL.load("(gl)script/kids/3DMapSystemUI/Msg_Def.lua"); -- message defination
--NPL.load("(gl)script/kids/3DMapSystemData/ItemManager.lua");
NPL.load("(gl)script/kids/3DMapSystemItem/ItemManager.lua");

-- TODO: put folder to seperate zip file for easy of update patching. 
-- there are some preload, hence the following file must be executed even before the scripting interface is ready.
--ParaAsset.OpenArchive ("character.zip", true);
--ParaAsset.OpenArchive ("model.zip", true);
--ParaAsset.OpenArchive ("Texture.zip", true);
--ParaAsset.OpenArchive ("terrain.zip", true);
--ParaAsset.OpenArchive ("script.zip", true);

-- clear all states
function Map3DSystem.ResetState()
	Map3DSystem.state = {}
end
Map3DSystem.ResetState()

-- push a state to the state queue. 
-- @param state: it can be a simple string or a custom table with name field like {name = "some state name", ...}
function Map3DSystem.PushState(state)
	Map3DSystem.state[4] = Map3DSystem.state[3]
	Map3DSystem.state[3] = Map3DSystem.state[2]
	Map3DSystem.state[2] = Map3DSystem.state[1]
	Map3DSystem.state[1] = state
	
	-- enable this line, if one wants to debug the state changes.
	--log("PushState: "..state.."\r\n");
end

-- @param state: Either nil or string or table state. if nil, the current state is removed. otherwise it will only pop the state if the current state name is the same as the input
function Map3DSystem.PopState(state)
	if(not state) then
		Map3DSystem.state[1] = Map3DSystem.state[2]
		Map3DSystem.state[2] = Map3DSystem.state[3]
		Map3DSystem.state[3] = Map3DSystem.state[4]
		Map3DSystem.state[4] = nil
	else
		local topState = Map3DSystem.GetState();
		if(type(topState)=="string") then
			if(type(state) == "table") then
				state = state.name;
			end
			if(topState == state) then
				Map3DSystem.PopState();
			end
		elseif(type(topState)=="table") then
			if((topState == state) or topState.name==state or (topState.name == "MessageBox")) then
				Map3DSystem.PopState();
			end
		end	
	end	
end

-- if index is nil or 1, the current state is returned, otherwise, the state at the given index is returned.
function Map3DSystem.GetState(index)
	if(not index) then
		return Map3DSystem.state[1]
	else
		return Map3DSystem.state[index]
	end	
end

--this function initialize the default appearance of the ui objects used in KidsMovie
-- make sure this function is called, before any UI is created. 
function Map3DSystem.LoadDefaultMap3DSystemTheme()
	
	-- ParaUI.SetUseSystemCursor(true);
	ParaUI.SetCursorFromFile("Texture/kidui/main/cursor.tga",3,4);
	ParaUI.GetUIObject("root").cursor = "Texture/kidui/main/cursor.tga"
	-- how many minutes are there in a day.
	ParaScene.SetDayLength(900);
	
	local _this;
	_this=ParaUI.GetDefaultObject("scrollbar");
	local states={[1]="highlight", [2] = "pressed", [3] = "disabled", [4] = "normal"};
	local i;
	for i=1, 4 do
		_this:SetCurrentState(states[i]);
		texture=_this:GetTexture("track");
		texture.texture="Texture/3DMapSystem/common/ThemeLightBlue/scroll_track.png";
		--texture.texture="Texture/3DMapSystem/common/ThemeLightBlue/scroll_track.png: 2 2 2 2";
		texture=_this:GetTexture("up_left");
		texture.texture="Texture/3DMapSystem/common/ThemeLightBlue/scroll_upleft.png";
		--texture.texture="Texture/3DMapSystem/common/ThemeLightBlue/scroll_upleft.png; 0 0 24 24 : 2 2 2 2";
		texture=_this:GetTexture("down_right");
		texture.texture="Texture/3DMapSystem/common/ThemeLightBlue/scroll_downright.png";
		--texture.texture="Texture/3DMapSystem/common/ThemeLightBlue/scroll_downright.png; 0 0 24 24 : 2 2 2 2";
		texture=_this:GetTexture("thumb");
		texture.texture="Texture/3DMapSystem/common/ThemeLightBlue/scroll_thumb.png";
		--texture.texture="Texture/3DMapSystem/common/ThemeLightBlue/scroll_thumb.png: 2 2 2 2";
	end
	
	--Map3DSystem.DefaultFontFamily = "Tahoma";
	--Map3DSystem.DefaultFontFamily = "helvetica";
	--Map3DSystem.DefaultFontFamily = "Verdana";
	Map3DSystem.DefaultFontFamily = "System";
	Map3DSystem.DefaultFontSize = 12;
	Map3DSystem.DefaultFontWeight = "norm";
	
	local fontStr = string.format("%s;%d;%s", 
				Map3DSystem.DefaultFontFamily, 
				Map3DSystem.DefaultFontSize, 
				Map3DSystem.DefaultFontWeight);
	

	_this=ParaUI.GetDefaultObject("button");
	_this.font = fontStr;
	_this.background = "Texture/3DMapSystem/common/ThemeLightBlue/btn_bg.png: 4 4 4 4";

	_this=ParaUI.GetDefaultObject("listbox");
	_this.font = fontStr;
	_this.background = "Texture/3DMapSystem/common/ThemeLightBlue/listbox_bg.png: 4 4 4 4";
	
	_this=ParaUI.GetDefaultObject("container");
	_this.background = "Texture/3DMapSystem/common/ThemeLightBlue/container_bg.png: 4 4 4 4";

	_this=ParaUI.GetDefaultObject("editbox");
	_this.font = fontStr;
	_this.background = "Texture/3DMapSystem/common/ThemeLightBlue/editbox_bg.png: 4 4 4 4";
	_this.spacing = 2;
	
	_this=ParaUI.GetDefaultObject("imeeditbox");
	_this.font = fontStr;
	_this.background = "Texture/3DMapSystem/common/ThemeLightBlue/editbox_bg.png: 4 4 4 4";
	_this.spacing = 2;
	
	_this=ParaUI.GetDefaultObject("text");
	_this.font = fontStr;
	
	_this=ParaUI.GetDefaultObject("slider");
	_this.background = "Texture/3DMapSystem/common/ThemeLightBlue/slider_background_16.png: 4 8 4 7"; 
	_this.button = "Texture/3DMapSystem/common/ThemeLightBlue/slider_button_16.png";
	
	-- TODO: message box a non-transparent window, with highlighting border. 
	_guihelper.MessageBox_BG = "Texture/3DMapSystem/MessageBox.png: 8 8 8 8";
	-- default toplevel dialogbox bg
	_guihelper.DialogBox_BG = "Texture/3DMapSystem/MessageBox.png: 8 8 8 8";
	
	_guihelper.OK_BG = "Texture/3DMapSystem/common/ThemeLightBlue/btn_bg_highlight.png: 8 8 8 8";
	
	_guihelper.Cancel_BG = nil;
	
	_guihelper.QuestionMark_BG = "Texture/3DMapSystem/QuestionMark_BG.png";
	
	_guihelper.ExclamationMark_BG = "Texture/3DMapSystem/ExclamationMark_BG.png";
end