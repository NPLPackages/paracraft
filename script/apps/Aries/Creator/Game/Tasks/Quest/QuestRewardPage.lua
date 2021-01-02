--[[
Title: QuestRewardPage
Author(s): yangguiyi
Date: 2020/12/9
Desc:  
Use Lib:
-------------------------------------------------------
local QuestRewardPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Quest/QuestRewardPage.lua");
QuestRewardPage.Show();
--]]
local QuestRewardPage = NPL.export();

local view_width = 474
local view_height = 351

commonlib.setfield("MyCompany.Aries.Creator.Game.Task.Quest.QuestRewardPage", QuestRewardPage);
local page;
QuestRewardPage.RewardData = {}

function QuestRewardPage.OnInit()
	page = document:GetPageCtrl();
	page.OnClose = QuestRewardPage.CloseView
end

function QuestRewardPage.Show(data)
	QuestRewardPage.RewardData = data
    if(GameLogic.GetFilters():apply_filters('is_signed_in'))then
        QuestRewardPage.ShowView()
        return
    end
    GameLogic.GetFilters():apply_filters('check_signed_in', L"请先登录", function(result)
        if result == true then
            commonlib.TimerManager.SetTimeout(function()
                if result then
					QuestRewardPage.ShowView()
                end
            end, 500)
        end
	end)

end

function QuestRewardPage.ShowView()
	if page then
		page:CloseWindow();
	end

	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/Quest/QuestRewardPage.html",
			name = "QuestRewardPage.Show", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			zorder = 0,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -view_width/2,
				y = -view_height/2,
				width = view_width,
				height = view_height,
				isTopLevel = true
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);	
end

function QuestRewardPage.OnRefresh()
    if(page)then
        page:Refresh(0);
    end
end

function QuestRewardPage.GetRewardDiv()
	local div = ""
	local item_width = 60
	local item_height = 60
	for i, v in ipairs(QuestRewardPage.RewardData) do
		local path = QuestRewardPage.GetGiftItemIcon(v.goods)
		local num = v.amount
		if #QuestRewardPage.RewardData == 1 then
			local pos_x = view_width/2 - item_width/2	
			div = string.format([[
				<div style="margin-left: %s; margin-top: 55; width: 60px; height: 60px; background: Texture/Aries/Creator/keepwork/Quest/wupingdi_60X60_32bits.png#0 0 40 40;">
					<img style="margin-top: 12px;margin-left: 12px; position: relative;" src='%s' width="36" height="36"/>
					<div style="margin-top: 38px;margin-left: 34px;text-align: center;color: #ffffffff;font-weight: bold;text-shadow:true;shadow-quality:8">%s</div>
				</div>
			]], pos_x, path, num)
		else
			local pos_x = i == 1 and 157 or 40
			div = div .. string.format([[
				<div style="margin-left: %s; margin-top: 55; width: 60px; height: 60px;float: left; background: Texture/Aries/Creator/keepwork/Quest/wupingdi_60X60_32bits.png#0 0 40 40;">
					<img style="margin-top: 12px;margin-left: 12px; position: relative;" src='%s' width="36" height="36"/>
					<div style="margin-top: 38px;margin-left: 34px;text-align: center;color: #ffffffff;font-weight: bold;text-shadow:true;shadow-quality:8">%s</div>
				</div>
			]], pos_x, path, num)
		end
	end

	return div
end

function QuestRewardPage.GetGiftItemIcon(item_data)
    local gsid = item_data.gsId or 998
    local path = string.format("Texture/Aries/Creator/keepwork/items/item_%d_32bits.png#32 0 65 64", gsid)
    return path
end

function QuestRewardPage.GetRewardDesc()
	local desc = "获得"
	for i, v in ipairs(QuestRewardPage.RewardData) do
		desc = desc .. v.amount .. v.goods.name
		if i ~= #QuestRewardPage.RewardData then
			desc = desc .. "，"
		end
	end

	return desc
end