--[[
    local ActRedhat = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ActRedhat/ActRedhat.lua")
    ActRedhat.ShowPage()
]]

local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local ParaWorldLoginAdapter = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaWorld.ParaWorldLoginAdapter");
local ActRedhat = NPL.export()

local hat_gisd = 90000
local maxHatNum = 105
local my_hat = 0
local page

function ActRedhat.ShowPage()
    local twidth = 470
    local theight = 350
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/ActRedhat/ActRedhat.html",
        name = "ActRedhat.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        zorder = -1,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
        directPosition = true,                
        align = "_ct",
        x = -twidth/2,
        y = -theight/2,
        width = twidth,
        height = theight,
    };                
    System.App.Commands.Call("File.MCMLWindowFrame", params)            
end

function ActRedhat.OnInit()
	page = document:GetPageCtrl();
end

function ActRedhat.getLeftHat()
    local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(hat_gisd)
	my_hat = copies or 0;

	return my_hat
end

function ActRedhat.OnClickOk()
    if page then
        page:CloseWindow(0)
    end
end

function ActRedhat.getHatDescDefault()
    local max = 45
    return string.format( "创意空间 （%d/%d）",ActRedhat.getHatNum(1),max)
end

function ActRedhat.getHatDescShanghai()
    local max = 30
    return string.format( "上海市黄浦区 （%d/%d）",ActRedhat.getHatNum(2),max)
end

function ActRedhat.getHatDescLiyuan()
    local max = 30
    return string.format( "荔园小学 （%d/%d）",ActRedhat.getHatNum(3),max)
end

function ActRedhat.getHatNum(index)
    local project = {tostring(ParaWorldLoginAdapter.GetDefaultWorldID()),"23501","23540"} 
    local clientData = KeepWorkItemManager.GetClientData(hat_gisd) or {};

    local id_key= "id"..project[index];
    local items = clientData[id_key];
    local datas = commonlib.split(items, ",");
    local num = 0
    if datas and type(datas) == "table" then
        --print("0000000000000000000000111111111111111111")
        num = #datas
    end
    return num
end

