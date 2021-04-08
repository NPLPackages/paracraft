--[[
    author:pbb
    date:
    Desc:
    use lib:
    local AskPop = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/AskPop/AskPop.lua");
    AskPop.ShowView();

    local AskPop = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/AskPop/AskPop.lua");
    AskPop.ShowView("你好呀，小东西");
]]
local AskPop = NPL.export()
AskPop.str = ""
AskPop.callback = nil
local page = nil
local baseStyle = "width: 580px; height: 180px; margin-left: 40px;font-size: 14px; base-font-size: 14px; color: #ffffff; text-align: justify;line-height:20px;"
local view_width = 660
local view_height = 180
local pos_config = {
    ct = {
        align = "_ct",
        x = -view_width/2,
        y = -view_height/2,
    },
    ctt = {
        align = "_ctt",
        x = 0,
        y = 0,
    },
    ctb = {
        align = "_ctb",
        x = 0,
        y = -40,
    },
    ctl = {
        align = "_ctl",
        x = 20,
        y = -40,
    },
    ctr = {
        align = "_ctr",
        x = -20,
        y = -40,
    },
    lt = {
        align = "_lt",
        x = 20,
        y = 0,
    },
    lb = {
        align = "_lb",
        x =  20,
        y = -view_height - 40,
    },
    rt = {
        align = "_rt",
        x = -view_width - 20,
        y = 0,
    },
    rb = {
        align = "_rb",
        x = -view_width - 20,
        y = -view_height - 40,
    },
}
local temp = {
    align = "_ct",
    x = -view_width/2,
    y = -view_height/2,
}
function AskPop.OnInit()
    page = document:GetPageCtrl();
end

function AskPop.ShowView(text,mode,callback) 
    AskPop.str = text or "本课程的学习目标为《练习1》"
    AskPop.callback = callback
    local config = pos_config[mode] or temp   
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/AskPop/AskPop.html",
        name = "AskPop.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = false,
        zorder = 10,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key,
        directPosition = true,
        align = config["align"],
        x = config["x"],
        y = config["y"],        
        width = view_width,
        height = view_height,
    };    
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function AskPop.GetFontStyle()
    local count = AskPop.GetStringCount(AskPop.str)
    local margin = 0
    if count <= 42 then
        margin = 42
    elseif count <= 86   then
        margin = 30
    elseif count <= 128 then
        margin = 18
    else
        margin = 2
    end
    local style = string.format("%s margin-top: %dpx;",baseStyle,margin)
    return style
end

function AskPop.GetStringCount(str)--获取字符串一共有几个字符
    if not str or str == "" then
        return 0
    end

    local nLenInByte = #str
    local count = 0
    local i = 1
    while i <= nLenInByte do
        local curByte = string.byte(str, i)
        local byteCount = 1
        if curByte >= 0 and curByte <= 127 then
            byteCount = 1
        elseif curByte >= 192 and curByte < 223 then
            byteCount = 2
        elseif curByte >= 224 and curByte < 239 then
            byteCount = 3
        elseif curByte >= 240 and curByte <= 247 then
            byteCount = 4
        end

        count = count + 1
        i = i + byteCount
    end
    
    return count
end

function AskPop.RunCallFunc()
    if AskPop.callback and type(AskPop.callback) == "function" then
        AskPop.callback()
    end
end