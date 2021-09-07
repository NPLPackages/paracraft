--[[
    author:pbb
    date:
    Desc:
    use lib:
    local CreateRewardManager = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateReward/CreateRewardManager.lua") 
    CreateRewardManager.InitCreateManager()
]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local CreateRewardManager = NPL.export()
CreateRewardManager.parentName = "createward_ui_root"
CreateRewardManager.m_nCreateTotalTime = 0
local times = {300,900,1800,3600}
CreateRewardManager.reward_timer = nil
CreateRewardManager.task_gsid = 40006
local CreateRewardSaveKey = "Paracraft_CreateTime"

function CreateRewardManager.InitCreateManager()
    CreateRewardManager.LoadCreateTime()
    CreateRewardManager.reward_timer = CreateRewardManager.reward_timer or commonlib.Timer:new({callbackFunc = function(timer)
		CreateRewardManager.m_nCreateTotalTime = CreateRewardManager.m_nCreateTotalTime + 1
        CreateRewardManager.UpdateTimeText()
        if CreateRewardManager.CheckShowTip() then
            CreateRewardManager.ShowGetRewardTip()
        end
	end})
end

function CreateRewardManager.UpdateTime()
    if CreateRewardManager.reward_timer then
        CreateRewardManager.reward_timer:Change(1000, 1000)        
    end
end

function CreateRewardManager.EndTime()
    if CreateRewardManager.reward_timer then
        CreateRewardManager.reward_timer:Change()
        CreateRewardManager.SaveCreateTime()
    end
end

function CreateRewardManager.CheckShowTip()
    local isShow = false
    for i=1,4 do
        if CreateRewardManager.m_nCreateTotalTime == times[i] then
            isShow = true
            break
        end
    end
    return isShow
end

function CreateRewardManager.SaveCreateTime()
    --保存数据的方式
    --GameLogic.GetPlayerController():SaveRemoteData(CreateRewardSaveKey,CreateRewardManager.m_nCreateTotalTime,true);
    local clientData = CreateRewardManager.GetClientData()
    clientData.m_nCreateTotalTime = CreateRewardManager.m_nCreateTotalTime
    CreateRewardManager.SetClientData(clientData)
end

function CreateRewardManager.LoadCreateTime()
    local clientData = CreateRewardManager.GetClientData()
    local value = clientData.m_nCreateTotalTime--GameLogic.GetPlayerController():LoadRemoteData(CreateRewardSaveKey,0);
    if value then
        CreateRewardManager.m_nCreateTotalTime = value
    end
end

function CreateRewardManager.CheckGetIndex()
    local index = 0
    for i=1,4 do
        local time = times[i]
        if CreateRewardManager.m_nCreateTotalTime >= time then
            index = index + 1
        end
    end    
    return index
end

function CreateRewardManager.ShowGiftBtn(parentRoot,isCreateRegion)
    if not parentRoot then
        return 
    end
    if isCreateRegion then
        CreateRewardManager.UpdateTime()
    end
    local giftBtn = ParaUI.GetUIObject("giftBtn")
    local txtTime = ParaUI.GetUIObject("gifttime_text")
    local txtTimebg = ParaUI.GetUIObject("gifttxt_bg")
    local _parent = ParaUI.GetUIObject(CreateRewardManager.parentName);	
    if not giftBtn:IsValid() and not txtTime:IsValid() then        
        local strPath = ';NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateReward/CreateRewardManager.lua") '
        giftBtn = ParaUI.CreateUIObject("button", "giftBtn", "_lt", 310, 28, 58, 58);
        giftBtn.background = "Texture/Aries/Creator/keepwork/CreateReward/jiangli_58X58_32bits.png;0 0 58 58";
        giftBtn.onclick = string.format([[%s.OnClickGiftBtn();]],strPath)
        parentRoot:AddChild(giftBtn);       

        local txtTimebg = ParaUI.CreateUIObject("container", "gifttxt_bg", "_lt", 307, 72, 61, 28);
        txtTimebg.background = "Texture/Aries/Creator/keepwork/CreateReward/b2_61X28_32bits.png;0 0 61 28";
        txtTimebg.visible = true
        txtTimebg.zorder = 1
        parentRoot:AddChild(txtTimebg);

        local txtTime = ParaUI.CreateUIObject("button", "gifttime_text", "_lt", 314, 71, 50, 30);
        txtTime.enabled = false;
        txtTime.text = CreateRewardManager.GetTimeText();
        txtTime.background = "";
        txtTime.font = "System;16;bold";
        txtTime.visible = true
        txtTime.zorder = 2
        _guihelper.SetButtonFontColor(txtTime, "#020202", "#020202");
        parentRoot:AddChild(txtTime);

        local tipTxtBg = ParaUI.CreateUIObject("container" ,"gifttip_bg","_lt",230,10,91,29) --b3_91X29_32bits.png
        tipTxtBg.background = "Texture/Aries/Creator/keepwork/CreateReward/b3_91X29_32bits.png;0 0 91 29";
        tipTxtBg.visible = false
        parentRoot:AddChild(tipTxtBg)

        local txtTip = ParaUI.CreateUIObject("button", "gifttip_text", "_lt", 230, 8, 91, 30);
        txtTip.enabled = false;
        txtTip.text = "+1奖励可领取";
        txtTip.background = "";
        txtTip.font = "System;12;bold";
        txtTip.visible = false
        txtTip.zorder = 1
        _guihelper.SetButtonFontColor(txtTip, "#020202", "#020202");
        parentRoot:AddChild(txtTip);
    else
        txtTime.visible = true
        giftBtn.visible = true
        txtTimebg.visible = true
    end    
end

function CreateRewardManager.HideGiftBtn()
    CreateRewardManager.EndTime()
    CreateRewardManager.SaveCreateTime()
    local giftBtn = ParaUI.GetUIObject("giftBtn")
    local txtTime = ParaUI.GetUIObject("gifttime_text")
    local txtTimeBg = ParaUI.GetUIObject("gifttxt_bg")
    local txtGiftTip = ParaUI.GetUIObject("gifttip_text")
    local txtGiftTipBg = ParaUI.GetUIObject("gifttip_bg")
    if giftBtn  and giftBtn:IsValid() then
        giftBtn.visible = false
    end
    if txtTime and txtTime:IsValid() then
        txtTime.visible = false
    end
    if txtTimeBg and txtTimeBg:IsValid() then
        txtTimeBg.visible = false
    end

    if txtGiftTip and txtGiftTip:IsValid() then
        txtGiftTip.visible = false
    end
    if txtGiftTipBg and txtGiftTipBg:IsValid() then
        txtGiftTipBg.visible = false
    end
end

function CreateRewardManager.UpdateTimeText()
    local txtTime = ParaUI.GetUIObject("gifttime_text")
    if txtTime and txtTime:IsValid() then
        txtTime.visible = true
        txtTime.text = CreateRewardManager.GetTimeText()
    end
end

function CreateRewardManager.GetTimeText()
    local time = CreateRewardManager.m_nCreateTotalTime
    if time == 0 then
        return ""
    end
    local minite = math.floor(time/60)
    local second = time - minite * 60
    local str = string.format("%02d:%02d",minite,second)
    return str
end

function CreateRewardManager.ShowGetRewardTip()
    local txtGiftTip = ParaUI.GetUIObject("gifttip_text")
    local txtGiftTipBg = ParaUI.GetUIObject("gifttip_bg")
    if txtGiftTip and txtGiftTip:IsValid() then
        txtGiftTip.visible = true
    end
    if txtGiftTipBg and txtGiftTipBg:IsValid() then
        txtGiftTipBg.visible = true
    end   
end

function CreateRewardManager.HideRewardTip()
    local txtGiftTip = ParaUI.GetUIObject("gifttip_text")
    local txtGiftTipBg = ParaUI.GetUIObject("gifttip_bg")
    if txtGiftTip and txtGiftTip:IsValid() then
        txtGiftTip.visible = false
    end
    if txtGiftTipBg and txtGiftTipBg:IsValid() then
        txtGiftTipBg.visible = false
    end
end

function CreateRewardManager.OnClickGiftBtn()
    CreateRewardManager.HideRewardTip()
    local CreateReward = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateReward/CreateReward.lua") 
    CreateReward.ShowView()
end

function CreateRewardManager.GetGiftStateList()
	local clientData = CreateRewardManager.GetClientData()
    return clientData.gift_state or {}
end


function CreateRewardManager.SetGiftState(gift_id, state)
    local clientData = CreateRewardManager.GetClientData()
    local gift_state_list = clientData.gift_state or {}
    if gift_state_list[gift_id] == nil then
        gift_state_list[gift_id] = 0
    end

    gift_state_list[gift_id] = state  
    clientData.gift_state = gift_state_list
    CreateRewardManager.SetClientData(clientData)
end

-- 检测是否新一天的数据
function CreateRewardManager.CheckIsNewDay(clientData)
	if clientData == nil then
		return true, 0
	end
    local time_stamp = clientData.time_stamp or 0;
	-- 获取今日凌晨的时间戳 1603949593
    local cur_time_stamp = GameLogic.QuestAction.GetServerTime() or 0
    if cur_time_stamp == nil or cur_time_stamp == 0 then
        cur_time_stamp = os.time()
    end
    
	local day_time_stamp = commonlib.timehelp.GetWeeHoursTimeStamp(cur_time_stamp)
	-- 天数改变 清除数据
	if day_time_stamp > time_stamp then
		return true, day_time_stamp
	end
	return false, time_stamp
end

function CreateRewardManager.GetClientData()
    if CreateRewardManager.clientData == nil then
        CreateRewardManager.clientData = KeepWorkItemManager.GetClientData(CreateRewardManager.task_gsid) or {};
    end

	local clientData = CreateRewardManager.clientData
    local is_new_day, time_stamp = CreateRewardManager.CheckIsNewDay(clientData)
    if is_new_day then
        clientData.gift_state = {}
        clientData.m_nCreateTotalTime = 0
        clientData.time_stamp = time_stamp
        CreateRewardManager.clientData = clientData        
    end
	return clientData
end

function CreateRewardManager.SetClientData(clientData, cb)
    KeepWorkItemManager.SetClientData(CreateRewardManager.task_gsid, clientData, function()
        CreateRewardManager.clientData = clientData
        if cb then
            cb()
        end
    end)
end

function CreateRewardManager:GetParent()
	local _parent = ParaUI.GetUIObject(CreateRewardManager.id or CreateRewardManager.parentName);	
	if(not _parent:IsValid()) then
		_parent = ParaUI.CreateUIObject("container",CreateRewardManager.parentName, "_rt",10,10,100,100);
		_parent.background = "";
		_parent:AttachToRoot();
		_parent.zorder = 100;
		CreateRewardManager.id = _parent.id;
	else
		_parent:Reposition("_rt",10,10,100,100);
	end
	return _parent;
end

