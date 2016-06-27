--[[
Title: Save File Dialog
Author(s): LiXizhi
Date: 2015/9/29
Desc: Display a dialog with text that let user to enter filename. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/SaveFileDialog.lua");
local SaveFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.SaveFileDialog");
SaveFileDialog.ShowPage("Please enter text", function(result)
	echo(result);
end)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenFileDialog.lua");
local OpenFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenFileDialog");
local SaveFileDialog = commonlib.inherit(OpenFileDialog, commonlib.gettable("MyCompany.Aries.Game.GUI.SaveFileDialog"));

-- @param default_text: default text to be displayed. 
-- @param filters: "model", "bmax", "audio", "texture", nil for any file, or filters table
function SaveFileDialog.ShowPage(text, OnClose, default_text, title, filters)
	return OpenFileDialog.ShowPage(text, OnClose, default_text, title, filters, true);
end