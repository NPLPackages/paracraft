--[[
Title: Edit Item Rule
Author(s): LiXizhi
Date: 2016/3/16
Desc: For rule editing
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EditRule.lua");
local EditRule = commonlib.gettable("MyCompany.Aries.Game.GUI.EditRule");
EditRule.ShowPage(itemStack)
-------------------------------------------------------
]]
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local EditRule = commonlib.gettable("MyCompany.Aries.Game.GUI.EditRule");

function EditRule.OnInit()
end

function EditRule.ShowPage(itemStack, triggerEntity)
	GameLogic.RunCommand("/open npl://open?file=script/apps/Aries/Creator/Game/GUI/EditRule.page&title=Edit Rule");
end
