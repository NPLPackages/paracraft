--[[
Title: quest data
Author(s): chenjinxian
Date: 2021/1/6
Desc: 
use the lib:
------------------------------------------------------------
local QuestItemToolTip = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestItemToolTip.lua");
-------------------------------------------------------
]]

local QuestItemToolTip = NPL.export()
local page

QuestItemToolTip.DescList = {}
function QuestItemToolTip.OnInit()
	page = document:GetPageCtrl();
end

function QuestItemToolTip.Show(uiobject_id, desc_data)
	QuestItemToolTip.DescList = desc_data

	local tooltip_page = "script/apps/Aries/Creator/Game/Tasks/Quest/QuestItemToolTip.html"
	if(tooltip_page) then
		CommonCtrl.TooltipHelper.BindObjTooltip(uiobject_id, tooltip_page, 20, 20,
			nil,nil,nil, nil, nil, nil, is_lock_position, use_mouse_offset);
	end
end

function QuestItemToolTip.GetDescDiv()
	if QuestItemToolTip.DescList == nil or #QuestItemToolTip.DescList == 0 then
		return ""
	end

	local div = ""
	for i, v in ipairs(QuestItemToolTip.DescList) do
		local desc = string.format("<div>%s</div>", v)
		div = div .. desc
	end


	return div
end