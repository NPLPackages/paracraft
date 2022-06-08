--[[
Title: 
Author(s): yangguiyi
Date: 2021/9/15
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/keepwork/lessons_ppt/notes.lua");
local notes = commonlib.gettable("MyCompany.Aries.Game.mcml.lessons_ppt.notes");
-------------------------------------------------------
]]
local notes = commonlib.gettable("MyCompany.Aries.Game.mcml.lessons_ppt.notes");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local RedSummerCampPPtPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampPPtPage.lua");

function notes.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
	notes.create_default(rootName, mcmlNode, bindingContext, _parent, left, top, right, bottom, myLayout, css);
	return true, true, true; -- ignore_onclick, ignore_background, ignore_tooltip;
end

function notes.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout, css)
	return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, notes.render_callback);
end

function notes.create_default(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, parentLayout, css)
	local display = mcmlNode:GetString("display")
	if display == "teacher" then
		if RedSummerCampPPtPage.GetTeachingPlanPower() then	
			mcmlNode:DrawChildBlocks_Callback(rootName, bindingContext, _parent, left, top, width, height, parentLayout, css);
		end
	else
		mcmlNode:DrawChildBlocks_Callback(rootName, bindingContext, _parent, left, top, width, height, parentLayout, css);
	end	
end