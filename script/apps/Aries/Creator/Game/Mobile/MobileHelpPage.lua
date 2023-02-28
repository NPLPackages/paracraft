--[[
    author:{pbb}
    time:2022-10-31 15:37:02
    uselib:
        local MobileHelpPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobileHelpPage.lua")
        MobileHelpPage.ShowPage()
]]
local MobileHelpPage = NPL.export()
local filePath = "Texture/Aries/Creator/keepwork/Mobile/help/"
MobileHelpPage.pageCnf = {
    {icon=filePath.."piliang_48x48_32bits.png", title=L"批量(Shift)", task="新增", content="按住批量按钮，点击方块，可快速新增3个方块，或快速填充相同方块"},
    {icon="", title="", task="清除", content="按住批量按钮，长按方块快速删除3x3x3范围内的方块"},
    {icon=filePath.."xuanze_48x48_32bits.png", title=L"选择(Ctrl)", task="选择", content="按住选择按钮，点击选中一个方块或拖动选中一片区域的方块"},
    {icon=filePath.."shanchu_48x48_32bits.png", title=L"删除", task="删除方块", content="按住删除按钮，单击屏幕操作从放置方块转换成删除方块"},
    {icon=filePath.."chexiao_48x48_32bits.png", title=L"撤销(Ctrl+Z)", task="撤销操作", content="点击撤销按钮，撤销上一步操作；按住撤销按钮右滑，恢复上一步撤销的操作"},
    {icon=filePath.."xiqu_48x48_32bits.png", title=L"吸取(Alt)", task="吸取", content="按住吸取按钮，点击吸取一个相同的方块到手中"},
    {icon=filePath.."tihuan_48x48_32bits.png", title=L"替换(Alt + 鼠标右键)", task="替换", content="按住替换按钮，点击方块替换成选中的方块"},
}

local page
function MobileHelpPage.OnInit()
    page = document:GetPageCtrl();
end

function MobileHelpPage.ShowPage()
    local params = {
        url = "script/apps/Aries/Creator/Game/Mobile/MobileHelpPage.html",
        name = "MobileHelpPage.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        zorder = 1,
        directPosition = true,
        DesignResolutionWidth = 1280,
        DesignResolutionHeight = 720,
        cancelShowAnimation = true,
        align = "_fi",
            x = 0,
            y = 0,
            width = 0,
            height = 0,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function MobileHelpPage.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
end