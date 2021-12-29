--[[
    author:{pbb}
    time:2021-10-21 14:40:56
     use lib:
    local ParaLifeSelectAnimate = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeSelectAnimate.lua") 
    ParaLifeSelectAnimate.ShowView()
]]
local ParaLifeMainUI = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeMainUI.lua");
local ParaLifeSelectAnimate = NPL.export()
ParaLifeSelectAnimate.cur_ani_id = 0
ParaLifeSelectAnimate.cur_btn_anims = {}
ParaLifeSelectAnimate.OnClose = nil
local page = nil
ParaLifeSelectAnimate.player_ani_config = {
	{ani_name="bow",ani_id = 34,cname="鞠躬"},
	{ani_name="wave",ani_id = 35,cname="招手"},
	{ani_name="lieside",ani_id = 88,cname="侧躺"},
	{ani_name="dance",ani_id = 144,cname="跳舞"},
	{ani_name="clap",ani_id = 145,cname="鼓掌"},
	{ani_name="nod",ani_id = 31,cname="点头"},
	{ani_name="shakehead",ani_id = 32,cname="摇头"},
	{ani_name="sit",ani_id = 72,cname="坐下"},
	{ani_name="lie",ani_id = 100,cname="趟着"},
	{ani_name="sort",ani_id = 118,cname="整理"},
	{ani_name="jump",ani_id = 176,cname="跳跃"},
	{ani_name="dazuo",ani_id = 187,cname="打坐"},
	{ani_name="pushup",ani_id = 188,cname="俯卧撑"},
	{ani_name="dizzy",ani_id = 189,cname="头晕"},
	{ani_name="hooray",ani_id = 191,cname="欢呼"},
}
function ParaLifeSelectAnimate.OnInit()
    page = document:GetPageCtrl();
end

function ParaLifeSelectAnimate.ShowView(select_anim_id,OnClose)
    ParaLifeSelectAnimate.cur_btn_anims = ParaLifeMainUI.cur_btn_anis
    ParaLifeSelectAnimate.cur_ani_id = select_anim_id
    ParaLifeSelectAnimate.OnClose = OnClose
    local view_width = 1010 
    local view_height = 760
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeSelectAnimate.html",
        name = "ParaLifeSelectAnimate.ShowView", 
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
    commonlib.TimerManager.SetTimeout(function ()
        ParaLifeSelectAnimate.InitAnimPlayer()
    end, 100);
end

function ParaLifeSelectAnimate.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
    ParaLifeSelectAnimate.cur_ani_id = 0
    ParaLifeSelectAnimate.cur_btn_anims = {}
    ParaLifeSelectAnimate.OnClose = nil
end

function ParaLifeSelectAnimate.GetAniText(name)
    local num = #ParaLifeSelectAnimate.player_ani_config
    for i=1,num do
        local cnf = ParaLifeSelectAnimate.player_ani_config[i]
        if cnf.ani_name == name then
            return string.format("（%d）%s",cnf.ani_id,cnf.cname)
        end
    end
    return ""
end

function ParaLifeSelectAnimate.OnClickAnim(name)
    local anim_id = ParaLifeSelectAnimate.GetAnimIdByName(name)
    if anim_id and anim_id > 0 then
        local player = ParaLifeSelectAnimate.GetPlayer()
        if player then
            player:ToCharacter():PlayAnimation(anim_id);
            ParaLifeSelectAnimate.cur_ani_id = anim_id
        end
    end
end

function ParaLifeSelectAnimate.GetPlayer()
    if page and page:IsVisible() then
        local module_ctl = page:FindControl("change_role_anim")
        local scene = ParaScene.GetMiniSceneGraph(module_ctl.resourceName);
        if scene and scene:IsValid() then
            local player = scene:GetObject(module_ctl.obj_name);
            if player then
                return player
            end
        end
    end
end

function ParaLifeSelectAnimate.GetAnimIdByName(name)
    local num = #ParaLifeSelectAnimate.player_ani_config
    for i=1,num do
        local cnf = ParaLifeSelectAnimate.player_ani_config[i]
        if cnf.ani_name == name then
            return cnf.ani_id
        end
    end
end

function ParaLifeSelectAnimate.OnClickOk()
    if ParaLifeSelectAnimate.OnClose then
        local bHave = false
        local num = #ParaLifeSelectAnimate.cur_btn_anims 
        for i=1,num do
            if ParaLifeSelectAnimate.cur_btn_anims[i].ani_id == ParaLifeSelectAnimate.cur_ani_id then
                bHave = true
            end
        end
        if bHave then
            _guihelper.MessageBox("你选择的角色动作已存在")
            return
        end
        ParaLifeSelectAnimate.OnClose(ParaLifeSelectAnimate.cur_ani_id)
    end
    ParaLifeSelectAnimate.ClosePage()
end

--player:ToCharacter():PlayAnimation(190);
function ParaLifeSelectAnimate.InitAnimPlayer()
    local player = ParaLifeSelectAnimate.GetPlayer()
    if player then
        player:SetScale(1)
        player:SetFacing(1.57);
        player:SetField("HeadUpdownAngle", 0.3);
        player:SetField("HeadTurningAngle", 0);
    end
end