--[[
Title: code behind for page KeepWorkBeanNoEnough.html
Author(s): yangguiyi
Date: 2020/8/6
Desc:  script/apps/Aries/Creator/Game/KeepWork/KeepWorkBeanNoEnough.html
Use Lib:
-------------------------------------------------------
-------------------------------------------------------
]]
local KeepWorkBeanNoEnough = {};
commonlib.setfield("MyCompany.Aries.Creator.Game.KeepWork.KeepWorkBeanNoEnough", KeepWorkBeanNoEnough);
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");

local page;
local my_bean = 0
local bean_gsid = 998;
function KeepWorkBeanNoEnough.OnInit(data)
	page = document:GetPageCtrl();
end

function KeepWorkBeanNoEnough.getLeftBean()
    local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(bean_gsid)
	my_bean = copies or 0;

	return my_bean
end