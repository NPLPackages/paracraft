--[[
Title: cursor functions
Author(s): LiXizhi
Date: 2011.9.5
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/Desktop/Cursor.lua");
local Cursor = commonlib.gettable("Map3DSystem.UI.Cursor");
Cursor.ApplyCursor(cursor_name, filename, hot_x, hot_y)
Cursor.LockCursor();
Cursor.UnlockCursor();
-------------------------------------------------------
]]

local Cursor = commonlib.gettable("Map3DSystem.UI.Cursor");

local lastCursorFile;
-- when cursor is locked, any calls to ApplyCursor will take no effect until unlock is called. 
local isCursorLocked = false;

-- cursor files
local cursorRules = {
	["default"]={file="Texture/kidui/main/cursor.tga", hot_x=3,hot_y=4},
	["xref"]={file="Texture/3DMapSystem/CCS/RightPanel/CF_Marks.png", hot_x=0,hot_y=8},
	["char"]={file="Texture/3DMapSystem/CCS/RightPanel/CF_Eye.png", hot_x=0,hot_y=8},
	["player"]={file="Texture/3DMapSystem/CCS/RightPanel/IT_Head.png", hot_x=0,hot_y=8},
	["model"]={file="Texture/3DMapSystem/CCS/RightPanel/IT_HandRight.png", hot_x=0,hot_y=8},
	
	-- TODO: 
	["button"]={file="Texture/kidui/main/cursor.tga", hot_x=3,hot_y=4},
	["move"]={file="Texture/3DMapSystem/common/chat.png", hot_x=0,hot_y=8},
	
	-- Aries specified: 
	["talk"]={file="Texture/Aries/Cursor/dialog.tga", hot_x=2,hot_y=2},
	["talkgrey"]={file="Texture/Aries/Cursor/dialogFar.tga", hot_x=2,hot_y=2},
	["read"]={file="Texture/Aries/Cursor/Read.tga", hot_x=0,hot_y=8},
	["purchase"]={file="Texture/Aries/Cursor/Purchase.tga", hot_x=0,hot_y=8},
	["pick"]={file="Texture/Aries/Cursor/Pick.tga", hot_x=0,hot_y=8},
	["combat"]={file="Texture/Aries/Cursor/Combat.tga", hot_x=1,hot_y=1},
	
	["aries_select"]={file="Texture/Aries/Cursor/select.tga", hot_x=5,hot_y=2},
	-- for throw ball
	["throw"]={file="Texture/Aries/Cursor/fire.tga", hot_x=16,hot_y=16},

	-- none cursor, set the cursor file to empty texture
	["none"]={file="Texture/Transparent.png", hot_x=0,hot_y=0},
};

function Cursor.SetDefaultCursor(cursor_obj)
	if(cursor_obj) then
		cursorRules["default"] = cursor_obj;
	end
end

-- apply a named cursor
-- @param cursor_name: a named cursor defaults to "default" unless filename is provided
-- if value is "lock" we will lock the cursor so that any subsequent calls to this function takes no effect until "unlock" is called.
-- @param filename: the cursor file name
-- @param hot_x, hot_y: hot position. 
function Cursor.ApplyCursor(cursor_name, filename, hot_x, hot_y)
	if(cursor_name == "lock") then
		Cursor.LockCursor()
		return;
	elseif(cursor_name == "unlock") then
		Cursor.UnlockCursor()
		return;
	end

	if(not isCursorLocked) then
		local cursorData = cursorRules[cursor_name or "default"];

		if(not filename and cursorData) then
			filename = cursorData.file;
			hot_x = cursorData.hot_x;
			hot_y = cursorData.hot_y;
		end
		if(filename) then
			if(not hot_x and cursorData and cursorData.file == filename) then
				hot_x = cursorData.hot_x;
				hot_y = cursorData.hot_y;
			end
			-- commonlib.echo({filename,hot_x, hot_y})
			ParaUI.SetCursorFromFile(filename,hot_x or 0, hot_y or 0);
			lastCursorFile = filename;
		end
	end
end

-- add a name, value pair for named cursors. 
function Cursor.AddCursor(name, cursor_obj)
	cursorRules[name] = cursor_obj;
end

-- get cursor
function Cursor.GetCursor(name)
	return cursorRules[name or "default"];
end

-- get last cursor file
function Cursor.GetLastCursorFile()
	return lastCursorFile;
end

-- when cursor is locked, any calls to ApplyCursor will take no effect until unlock is called. 
function Cursor.IsCursorLocked()
	return isCursorLocked;
end

-- when cursor is locked, any calls to ApplyCursor will take no effect until unlock is called. 
-- @param cursor_name: the cursor_name to lock. if nil it is the current cursor
-- @param apply_to_UI: true to apply to GUI object as well. 
function Cursor.LockCursor(cursor_name, apply_to_UI)
	if(cursor_name) then
		Cursor.ApplyCursor(cursor_name);
	end
	isCursorLocked = true;

	if(apply_to_UI) then
		ParaUI.GetUIObject("root").cursor = lastCursorFile;
	end
end

-- when cursor is locked, any calls to ApplyCursor will take no effect until unlock is called. 
-- @param cursor_name: the cursor to restore to. if nil, it is the "default"
function Cursor.UnlockCursor(cursor_name, apply_to_UI)
	isCursorLocked = false;
	Cursor.ApplyCursor(cursor_name or "default")

	if(apply_to_UI) then
		ParaUI.GetUIObject("root").cursor = lastCursorFile;
	end
end
