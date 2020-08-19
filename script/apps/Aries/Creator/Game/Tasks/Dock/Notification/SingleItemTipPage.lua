--[[
Title: SingleItemTipPage
Author(s): leio
Date: 2020/8/18
Desc:  
Use Lib:
-------------------------------------------------------
local SingleItemTipPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Dock/Notification/SingleItemTipPage.lua");
SingleItemTipPage.Show(888,100);
--]]
NPL.load("(gl)script/ide/timer.lua");

NPL.load("(gl)script/kids/3DMapSystemApp/mcml/PageCtrl.lua");
local SingleItemTipPage = NPL.export();

SingleItemTipPage._root = nil;
SingleItemTipPage.gsid = nil;
SingleItemTipPage.count = nil;
SingleItemTipPage.count_down = nil;
SingleItemTipPage.max_count_down = 2000;
function SingleItemTipPage.Show(gsid,count)
    SingleItemTipPage.gsid = gsid;
    SingleItemTipPage.count = count;
    if(not SingleItemTipPage._root)then
        SingleItemTipPage.page = Map3DSystem.mcml.PageCtrl:new({ 
            url = "script/apps/Aries/Creator/Game/Tasks/Dock/Notification/SingleItemTipPage.html" ,

        } );
        SingleItemTipPage._root = SingleItemTipPage.page:Create("SingleItemTipPage.Show_instance", nil, "_ctb", 190, -72, 220, 150)
    else
        SingleItemTipPage.page:Refresh(0);
    end
    SingleItemTipPage.count_down = SingleItemTipPage.max_count_down;
	SingleItemTipPage._root.visible = true;
    UIAnimManager.StopDirectAnimation(SingleItemTipPage._root)
    -- show page
    local block = UIDirectAnimBlock:new();
	block:SetUIObject(SingleItemTipPage._root);
	block:SetTime(200);
	block:SetAlphaRange(0, 1);
	block:SetTranslationYRange(128, 0);
	block:SetApplyAnim(true); 
	UIAnimManager.PlayDirectUIAnimation(block);

    if(not SingleItemTipPage.timer)then
        SingleItemTipPage.timer = commonlib.Timer:new({callbackFunc = function(timer)

            SingleItemTipPage.count_down = SingleItemTipPage.count_down - timer.delta;
            if(SingleItemTipPage.count_down < 0)then
                -- hide page
                local block = UIDirectAnimBlock:new();
			    block:SetUIObject(SingleItemTipPage._root);
			    block:SetTime(150);
			    block:SetAlphaRange(1, 0);
			    block:SetTranslationYRange(0, 128);
			    block:SetApplyAnim(true); 
			    block:SetCallback(function ()
				    SingleItemTipPage._root.visible = false;
			    end); 
			    UIAnimManager.PlayDirectUIAnimation(block);

                SingleItemTipPage.timer:Change();
            end
            
        end})
    end
    SingleItemTipPage.timer:Change(0,100);
end
function SingleItemTipPage.Close()
    SingleItemTipPage.count_down = 0;
end