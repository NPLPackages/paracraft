--[[
Title: Edit Item Dialog
Author(s): LiXizhi
Date: 2016/4/5
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EditDialog.lua");
local EditDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EditDialog");
EditDialog.ShowPage(itemStack, filename)
-------------------------------------------------------
]]
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local EditDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EditDialog");

function EditDialog.OnInit()
end

function EditDialog.ShowPage(itemStack, filename, triggerEntity)
	filename = filename or itemStack:GetDataField("tooltip");
	local url = "/open npl://open?file=script/apps/Aries/Creator/Game/GUI/EditDialog.page&title=Edit Dialog";
	if(filename and filename~="") then
		url = url.."&filename="..filename;
	end
	GameLogic.RunCommand(url);
end
