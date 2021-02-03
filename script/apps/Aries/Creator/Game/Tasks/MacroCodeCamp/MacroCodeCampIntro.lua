--[[
    活动详情也
    local MacroCodeCampIntro = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MacroCodeCamp/MacroCodeCampIntro.lua");
    MacroCodeCampIntro.ShowView()
]]
local MacroCodeCampIntro = NPL.export()--commonlib.gettable("WinterCamp.MacroCodeCamp")

local page 
MacroCodeCampIntro.m_nCurIndex = 1
MacroCodeCampIntro.schools = {
    {name="广州天府路小学"},
    {name="深圳黄田小学"},
    {name="景莲小学"},
    {name="南山第二实验学校"},
    {name="清远市清新区第三中学"},
    {name="清远河洞学校"},
    {name="深圳宝城小学"},
    {name="江西省九江市浔阳区柴桑小学"},
    {name="江西省九江市浔阳区东风小学"},
    {name="江西省九江市浔阳区浔东小学"},
    {name="江西省九江市浔阳区外国语小学"},
    {name="江西省九江市浔阳区龙山小学"},
    {name="内蒙古东禾教育（和林格尔县盛乐园区小学）"},
    {name="深圳美莲小学"},
    {name="仙桃第二实验小学"},
    {name="贵州昌文小学"},
    {name="贵州巧马中心小学"},
    {name="东莞市桥头镇第三小学"},
    {name="成都市龙泉驿区实验小学"},
    {name="清远市清新区第五小学"},
    {name="凤岗中心小学"},
    {name="南京市高淳区漆桥中心小学"},
    {name="银莺路小学"},
    {name="文源小学"},
    {name="沂水县第一实验小学"},
    {name="锡林浩特市第四中学"},
    {name="平果县第八小学"},
    {name="深圳东海实验学校"},
    {name="清远市太平初级中学"},
    {name="江西省九江市浔阳区湖滨小学"},
    {name="江西省九江市浔阳区湖滨小学桃园校区"},
    {name="江西省九江市浔阳区琵琶亭小学"},
    {name="江西省九江市浔阳区三里小学"},
    {name="江西省九江市浔阳区新星小学"},
    {name="江西省九江市浔阳区希望学校"},
    {name="江西省九江市浔阳区浔阳小学"},
}
function MacroCodeCampIntro.OnInit()
	page = document:GetPageCtrl();
end

function MacroCodeCampIntro.ShowView()
    local view_width = 740
	local view_height = 560
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/MacroCodeCamp/MacroCodeCampIntro.html",
        name = "MacroCodeCampIntro.ShowView", 
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

function MacroCodeCampIntro.OnClickNext(index)
    MacroCodeCampIntro.m_nCurIndex = MacroCodeCampIntro.m_nCurIndex + index
    if MacroCodeCampIntro.m_nCurIndex < 1 then
        MacroCodeCampIntro.m_nCurIndex = 3
    end
    if MacroCodeCampIntro.m_nCurIndex > 3 then
        MacroCodeCampIntro.m_nCurIndex = 1
    end
    if page then
        page:Refresh(0)
    end
end