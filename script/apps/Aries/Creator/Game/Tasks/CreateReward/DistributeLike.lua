--[[
    author:pbb
    date:
    Desc:
    use lib:
    local DistributeLike = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateReward/DistributeLike.lua") 
    DistributeLike.ShowView()
]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local DistributeLike = NPL.export()
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local page = nil
DistributeLike.worldDts = {}
DistributeLike.inputNums = {}

DistributeLike.ItemNum = -1

function DistributeLike.OnInit()
    page = document:GetPageCtrl();
    page.OnCreate = DistributeLike.OnCreate
end

function DistributeLike.ShowView()
    DistributeLike.GetMyWorldList(function()
        DistributeLike.Show()
    end)
end

function DistributeLike.Show()
    local view_width = 750
    local view_height = 580
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/CreateReward/DistributeLike.html",
        name = "DistributeLike.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = 4,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key,
        directPosition = true,
        align = "_ct",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function DistributeLike.OnCreate()

end

function DistributeLike.UpdateGSItem(gsid)
    if(not gsid)then
        return
    end
    gsid = tonumber(gsid)
    if(gsid > 0)then
        for k,v in ipairs(KeepWorkItemManager.items) do
            if( v.gsId == gsid)then
                local copies = v.copies or 0;
                local bOwn = false;
                if(copies > 0)then
                    bOwn = true;
                end
                return bOwn, v.id, v.bagId, copies, v;
            end    
        end
    end
end

function DistributeLike.GetMyWorldList(callback)
    DistributeLike.worldDts = {}
    keepwork.world2in1.project_list({
        parentId=0,
        ["x-per-page"] = 200,
        ["x-page"] = 1,
    }, function(err, msg, data)
        if err == 200 then
            if #data.rows == 0 then
                if callback then callback() end
            else
                for k, v in pairs(data.rows) do
                    local temp = {}
                    temp.name = v.name
                    temp.worldId = v.id
                    temp.isselect = 0
                    temp.updateAt = DistributeLike.GetTimeDesc(v.updatedAt)
                    temp.limit_name = DistributeLike.GetLimitLabel(v.name)
                    DistributeLike.worldDts[#DistributeLike.worldDts + 1] = commonlib.copy(temp)
                end
                if callback then callback() end
            end
            return
        end
        GameLogic.AddBBS(nil,"获取世界数据失败")
    end)
end

function DistributeLike.RefreshPage()
    if page then
        page:Refresh(0)
    end    
end

function DistributeLike.OnClosePage()
    if page then
        page:CloseWindow()
    end
    KeepWorkItemManager.LoadItems(nil)
    DistributeLike.worldDts = {}
    DistributeLike.inputNums = {}   
end

function DistributeLike.GetTimeDesc(updatedAt)
	local time_stamp = commonlib.timehelp.GetTimeStampByDateTime(updatedAt)
	local date_desc = os.date("%Y-%m-%d", time_stamp)
	local time_desc = os.date("%H:%M", time_stamp)
	local desc = string.format("%s %s", date_desc, time_desc)
    return desc
end

function DistributeLike.GetLimitLabel(text, maxCharCount)
    maxCharCount = maxCharCount or 17;
    local len = ParaMisc.GetUnicodeCharNum(text);
    if(len >= maxCharCount)then
	    text = ParaMisc.UniSubString(text, 1, maxCharCount-2) or "";
        return text .. "...";
    else
        return text;
    end
end

function DistributeLike.GetTotalItemNum()
    if DistributeLike.ItemNum == -1 then
        local bOwn, guid, bag, copies, item = KeepWorkItemManager.HasGSItem(10005)
        DistributeLike.ItemNum = copies
    end
    return DistributeLike.ItemNum
end

function DistributeLike.GetTotalStr()
    local str = string.format("获得%d个赞，请选择你要增加赞数的作品，并在输入框内输入需要增加的赞数，可选多个作品。",DistributeLike.GetTotalItemNum())
    return str
end

function DistributeLike.OnClickOk()
    local totalNum = DistributeLike.GetTotalItemNum()
    local num = #DistributeLike.worldDts
    local curInputNum = 0
    local starconfig = {}
    for i=1,num do
        local isSel = DistributeLike.worldDts[i].isselect
        local inputNum = DistributeLike.inputNums[i]
        if isSel == 1 and inputNum then
            curInputNum = curInputNum + inputNum
            if inputNum > 0 then
                starconfig[#starconfig + 1] = {projectId = DistributeLike.worldDts[i].worldId,cnt = inputNum}
            end
        end
    end
    if curInputNum > totalNum then
        _guihelper.MessageBox("你输入的赞数已超过获得的赞数，请重新调整后再点击确定。")
        return
    end
    
    if curInputNum == 0 then 
        _guihelper.MessageBox("你输入的赞数不正确，请重新调整后再点击确定。")
        return
    end
    
    keepwork.projects.allocateStar({
        stars = starconfig
    },function(err, msg, data)
        if err == 200 then
            DistributeLike.ItemNum = DistributeLike.ItemNum -  curInputNum
            DistributeLike.RefreshPage()
            _guihelper.MessageBox("分配点赞成功")   
        else
            _guihelper.MessageBox("分配点赞失败")       
        end
    end)
end