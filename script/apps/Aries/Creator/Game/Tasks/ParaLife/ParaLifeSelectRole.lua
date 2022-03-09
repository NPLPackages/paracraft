--[[
    author:{pbb}
    time:2021-10-22 16:22:14
    use lib:
    local ParaLifeSelectRole = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeSelectRole.lua") 
    ParaLifeSelectRole.ShowView()
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/ModelTextureAtlas.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/RolePlayMode/RolePlayMovieController.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems");
local ModelTextureAtlas = commonlib.gettable("MyCompany.Aries.Game.Common.ModelTextureAtlas");
local RolePlayMovieController = commonlib.gettable("MyCompany.Aries.Game.Movie.RolePlayMode.RolePlayMovieController");
local ParaLifeSelectRole = NPL.export()
ParaLifeSelectRole.roleDt = {}
local default_model = "character/CC/02human/CustomGeoset/actor.x"
local default_skin = CustomCharItems:SkinStringToItemIds(CustomCharItems.defaultSkinString)
local empty_data = {model = default_model,skin ="",slot_index = -1,}
local add_data = {model = default_model,skin ="",is_add = 1}
local max_role_num = 32
ParaLifeSelectRole.select_index = -1
local page = nil
function ParaLifeSelectRole.OnInit()
    page = document:GetPageCtrl();
end

function ParaLifeSelectRole.ShowView(curItem,OnCloseFunc)
    ParaLifeSelectRole.InitPageData()
    local view_width = 1160
    local view_height = 850
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeSelectRole.html",
        name = "ParaLifeSelectRole.ShowView", 
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
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    params._page.OnClose = function()
		if(OnCloseFunc) then
			-- OnClose(currentModelFile, currentSkin);
		end
	end;
end

function ParaLifeSelectRole.InitPageData()
    ParaLifeSelectRole.roleDt = {}
    local playerDt = ParaLifeSelectRole.GetPlayerData()
    ParaLifeSelectRole.roleDt[#ParaLifeSelectRole.roleDt + 1] = playerDt
    local movieData = ParaLifeSelectRole.GetMoviePlayerData()
    for i=1,#movieData do
        ParaLifeSelectRole.roleDt[#ParaLifeSelectRole.roleDt + 1] = movieData[i]
    end
    -- if ParaLifeSelectRole.roleDt and #ParaLifeSelectRole.roleDt == 0 then
    --     ParaLifeSelectRole.roleDt[#ParaLifeSelectRole.roleDt + 1] = commonlib.copy(add_data)
    -- end
    ParaLifeSelectRole.roleDt[#ParaLifeSelectRole.roleDt + 1] = commonlib.copy(add_data)
    ParaLifeSelectRole.select_index = 1
end

function ParaLifeSelectRole.ClearPageData()
    ParaLifeSelectRole.roleDt = {}
    ParaLifeSelectRole.select_index = -1
end

function ParaLifeSelectRole.AddBlankData()
    local role_num = #ParaLifeSelectRole.roleDt
    if role_num > max_role_num then
        GameLogic.AddBBS(nil,"最多添加"..max_role_num.."个角色，你可以先删除几个角色，然后重新添加")
        return
    end
    local curData = commonlib.copy(empty_data)
    curData.slot_index = RolePlayMovieController.GetEmptySlot()
    curData.skin = default_skin
    local params = {}
    params.type = "npc"
    params.skin = default_skin
    params.assetfile = default_model
    RolePlayMovieController.AddRoleToEntity(params)
    table.insert(ParaLifeSelectRole.roleDt, role_num, curData)
end

function ParaLifeSelectRole.SelectCurRole(index)
    local cur_role = ParaLifeSelectRole.roleDt[index]
    if not cur_role then
        return
    end
    if cur_role.skin and cur_role.skin ~= "" then
        -- TODO: add actor to movie entity with params contains skin and model
        local slot_index = cur_role.slot_index
        RolePlayMovieController.SelectSlotItem(slot_index)
        -- ParaLifeSelectRole.ClosePage()
        return
    end
    _guihelper.MessageBox("请先选择正确的任务形象~")
end

function ParaLifeSelectRole.DeleteCurRole(index)
    local cur_role = ParaLifeSelectRole.roleDt[index]
    if cur_role then
        local slot_index = cur_role.slot_index
        table.remove(ParaLifeSelectRole.roleDt, index)
        RolePlayMovieController.RemoveSlotItem(slot_index)
        print("delete movie role=============",slot_index)
        ParaLifeSelectRole.RefreshPage()
    end
end

function ParaLifeSelectRole.ChangeCurRoleAssets(index)
    local cur_role = ParaLifeSelectRole.roleDt[index]
    if cur_role then
        local old_value = cur_role.skin
        NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeSkinPage.lua");
        local ParaLifeSkinPage = commonlib.gettable("MyCompany.Aries.Game.ParaLife.ParaLifeSkinPage");
        ParaLifeSkinPage.ShowPage(function(filename, skin)
            if (filename and skin~=old_value) then
                cur_role.skin = skin
                local slot_index = cur_role.slot_index
                RolePlayMovieController.UpdateSlotItem(slot_index,skin)
                ParaLifeSelectRole.RefreshPage()
            end
        end, old_value);
    end
    
end

function ParaLifeSelectRole.OnClickItem(name)
    local index = tonumber(name)
    local cur_role = ParaLifeSelectRole.roleDt[index]
    if cur_role and cur_role.is_add == 1 then
        ParaLifeSelectRole.AddBlankData()
        ParaLifeSelectRole.select_index = ParaLifeSelectRole.GetAddIndex()
        echo(ParaLifeSelectRole.roleDt,true)
        ParaLifeSelectRole.RefreshPage()
        return
    end
    --show select
    ParaLifeSelectRole.select_index = index
    ParaLifeSelectRole.RefreshPage()
end

function ParaLifeSelectRole.OnClickOperate(name)
    if name == "select" then
        ParaLifeSelectRole.SelectCurRole(ParaLifeSelectRole.select_index)
    elseif name == "change" then
        ParaLifeSelectRole.ChangeCurRoleAssets(ParaLifeSelectRole.select_index)
    elseif name == "delete" then
        ParaLifeSelectRole.DeleteCurRole(ParaLifeSelectRole.select_index)
    end
end

function ParaLifeSelectRole.CheckIsSelAdd()
    local cur_role = ParaLifeSelectRole.roleDt[ParaLifeSelectRole.select_index]
    if cur_role.is_add== 1 then
        return true
    end
    return false
end

function ParaLifeSelectRole.CheckHasSkin()
    local cur_role = ParaLifeSelectRole.roleDt[ParaLifeSelectRole.select_index]
    if cur_role.skin and cur_role.skin ~= "" then
        return true
    end
    return false
end

function ParaLifeSelectRole.GetAddIndex()
    local num = #ParaLifeSelectRole.roleDt
    for i=1,num do
        if ParaLifeSelectRole.roleDt[i].is_add == 1 then
            return i
        end
    end
end

function ParaLifeSelectRole.CheckIsSetSkin(index)
    local data = ParaLifeSelectRole.roleDt[tonumber(index)]
    if data and data.skin and data.skin ~= "" then
        return true
    end
    return false
end

function ParaLifeSelectRole.CheckIsMainPlayer()
    local data = ParaLifeSelectRole.roleDt[ParaLifeSelectRole.select_index]
    if data and (data.isMainPlayer or data.slot_index == -1)  then
        return true
    end
    return false
end

function ParaLifeSelectRole.GetSkinPicture(index)
    local data = ParaLifeSelectRole.roleDt[tonumber(index)]
    if data and data.skin~="" and data.model~="" then
        return string.gsub(ModelTextureAtlas:CreateGetModel(data.model, data.skin),";","#")
    end
    return ""
end

function ParaLifeSelectRole.GetPlayerData()
    local player = GameLogic.GetPlayer()
    local skin = player:GetSkinId()
    local modelFile = player:GetMainAssetPath()
    return {model = modelFile,skin = skin,isMainPlayer = true,slot_index = -1}
end

function ParaLifeSelectRole.GetMoviePlayerData()
    local movieDatas = RolePlayMovieController.GetalExistsRoleData()
    if movieDatas and #movieDatas > 0 then
        local allData = {}
        for i=1,#movieDatas do
            local temp = {}
            temp.model = movieDatas[i].assetfile
            temp.skin = movieDatas[i].skin
            temp.slot_index = movieDatas[i].slot_index
            allData[#allData +1] = temp
        end
        return allData
    end
end

function ParaLifeSelectRole.IsAddItems(index)
    local cur_role = ParaLifeSelectRole.roleDt[index]
    if cur_role.is_add== 1 then
        return true
    end
    return false
end

function ParaLifeSelectRole.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
end

function ParaLifeSelectRole.RefreshPage()
    if page then
        page:Refresh(0)
    end
end

