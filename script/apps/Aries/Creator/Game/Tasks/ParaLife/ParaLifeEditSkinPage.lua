--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{pbb}
    time:2021-12-07 11:33:12
    use lib:
    local ParaLifeEditSkinPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeEditSkinPage.lua") 
    ParaLifeEditSkinPage.ShowView()
]]

local ParaLifeEditSkinPage = NPL.export()
ParaLifeEditSkinPage.call_func = nil
local page = nil
function ParaLifeEditSkinPage.OnInit()
    page = document:GetPageCtrl();
end

function ParaLifeEditSkinPage.ShowView(model_name,call_func)
    ParaLifeEditSkinPage.call_func = call_func
    local view_width = 300
    local view_height = 200
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeEditSkinPage.html",
        name = "ParaLifeEditSkinPage.ShowView", 
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
    print("model.name=========",model_name)
    if model_name and model_name ~= "" then
        page:SetValue("model_name",model_name);
    end
end

function ParaLifeEditSkinPage.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
        ParaLifeEditSkinPage.call_func = nil
    end
end

function ParaLifeEditSkinPage.FinishEditing()
    if ParaLifeEditSkinPage.call_func then
        local name = page:GetValue("model_name");
        if name and name~= "" then
            ParaLifeEditSkinPage.call_func(name)
        end
    end
    ParaLifeEditSkinPage.ClosePage()
end

function ParaLifeEditSkinPage.CancelEditing()
    ParaLifeEditSkinPage.ClosePage()
end