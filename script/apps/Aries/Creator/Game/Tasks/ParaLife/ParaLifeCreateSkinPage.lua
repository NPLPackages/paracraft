--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{pbb}
    time:2021-12-07 11:33:12
    use lib:
    local ParaLifeCreateSkinPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeCreateSkinPage.lua") 
    ParaLifeCreateSkinPage.ShowView()
]]

local ParaLifeCreateSkinPage = NPL.export()
ParaLifeCreateSkinPage.call_func = nil
local page = nil
function ParaLifeCreateSkinPage.OnInit()
    page = document:GetPageCtrl();
end

function ParaLifeCreateSkinPage.ShowView(call_func)
    ParaLifeCreateSkinPage.call_func = call_func
    local view_width = 300
    local view_height = 200
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeCreateSkinPage.html",
        name = "ParaLifeCreateSkinPage.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        enable_esc_key = true,
        directPosition = true,
        align = "_ct",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function ParaLifeCreateSkinPage.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
        ParaLifeCreateSkinPage.call_func = nil
    end
end

function ParaLifeCreateSkinPage.FinishEditing()
    if ParaLifeCreateSkinPage.call_func then
        local name = page:GetValue("model_name");
        if name and name~= "" then
            ParaLifeCreateSkinPage.call_func(name)
        else
            GameLogic.AddBBS(nil,"搭配的名称不可为空")
        end
    end
    ParaLifeCreateSkinPage.ClosePage()
end

function ParaLifeCreateSkinPage.CancelEditing()
    ParaLifeCreateSkinPage.ClosePage()
end