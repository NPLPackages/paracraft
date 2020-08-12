--[[
Title: code behind for page KeepWorkCoinNoEnough.html
Author(s): yangguiyi
Date: 2020/8/6
Desc:  script/apps/Aries/Creator/Game/KeepWork/KeepWorkCoinNoEnough.html
Use Lib:
-------------------------------------------------------
-------------------------------------------------------
]]
local KeepWorkCoinNoEnough = {};
commonlib.setfield("MyCompany.Aries.Creator.Game.KeepWork.KeepWorkCoinNoEnough", KeepWorkCoinNoEnough);
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local page;
local coin_gsid = 888
local my_coin = 0
function KeepWorkCoinNoEnough.OnInit(data)
	page = document:GetPageCtrl();
end

function KeepWorkCoinNoEnough.getLeftBean()
    local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(coin_gsid)
	my_coin = copies or 0;
	local desc = "你的知识币余额：" .. my_coin

	return desc
end

function KeepWorkCoinNoEnough.OnOK()
	ParaGlobal.ShellExecute("open", "explorer.exe", "https://keepwork.com/vip", "", 1); 
	_guihelper.MessageBox("充值成功后点击【确定】，刷新知识币数量。", function()
		page:CloseWindow()
		KeepWorkItemManager.LoadItems()
	end)
end