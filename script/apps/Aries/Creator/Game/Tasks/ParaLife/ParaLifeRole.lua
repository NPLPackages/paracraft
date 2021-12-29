--[[
    author:{pbb}
    time:2021-12-10 16:04:28
    use lib:
    local ParaLifeRole = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeRole.lua") 
    ParaLifeRole.ShowView()
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemLiveModel.lua");
local ItemLiveModel = commonlib.gettable("MyCompany.Aries.Game.Items.ItemLiveModel");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems");
local ModelTextureAtlas = commonlib.gettable("MyCompany.Aries.Game.Common.ModelTextureAtlas");
local RolePlayMovieController = commonlib.gettable("MyCompany.Aries.Game.Movie.RolePlayMode.RolePlayMovieController");
local default_model = "character/CC/02human/CustomGeoset/actor.x"
local default_skin = CustomCharItems:SkinStringToItemIds(CustomCharItems.defaultSkinString)
local move_timer
local isTouchPlayer = false
local ParaLifeRole = NPL.export()
ParaLifeRole.IsRegisterEvent = false

ParaLifeRole.role_configs = {
    {id = 1,assetsfile= default_model,skin = default_skin},
    {id = 2,assetsfile= default_model,skin = default_skin},
    {id = 3,assetsfile= default_model,skin = default_skin},
    {id = 4,assetsfile= default_model,skin = default_skin},
    {id = 5,assetsfile= default_model,skin = default_skin},
    {id = 6,assetsfile= default_model,skin = default_skin},
    {id = 7,assetsfile= default_model,skin = default_skin},
    {id = 8,assetsfile= default_model,skin = default_skin},
    {id = 9,assetsfile= default_model,skin = default_skin},
    -- {id = 10,assetsfile= default_model,skin = default_skin},
    -- {id = 11,assetsfile= default_model,skin = default_skin},
    -- {id = 12,assetsfile= default_model,skin = default_skin},
    -- {id = 13,assetsfile= default_model,skin = default_skin},
    -- {id = 14,assetsfile= default_model,skin = default_skin},
    -- {id = 15,assetsfile= default_model,skin = default_skin},
}
local building_configs ={
    {id = 1,assetsfile= ""}
}
local mouse_event = nil
local creatEntity = nil
local page = nil
function ParaLifeRole.OnInit()
    page = document:GetPageCtrl();
    page.OnCreate = ParaLifeRole.OnCreate
    page.OnClose = function(bDestroy)
        --ParaLifeRole.IsRegisterEvent = false
    end
end

function ParaLifeRole.ShowView()
    local view_width = 1280
    local view_height = 256
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeRole.html",
        name = "ParaLifeRole.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = false,
        directPosition = true,
        click_through = true,
        align = "_ctb",
            x = 0,
            y = 0,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    if not ParaLifeRole.IsRegisterEvent then
        GameLogic.GetFilters():add_filter("basecontext_after_handle_mouse_event", function(event)
            if not event then
                return 
            end
            local mouse_x,mouse_y = mouse_x,mouse_y
            mouse_event = event
            local event_type = event:GetType() --mousePressEvent mouseReleaseEvent mouseMoveEvent
            -- print("basecontext_after_handle_mouse_event=======",event_type)
            if creatEntity then
                if event_type == "mouseMoveEvent" then
                    if not creatEntity.IsMousePress then
                        creatEntity:mousePressEvent(event)
                        creatEntity.IsMousePress = true
                    end
                    creatEntity:mouseMoveEvent(event)
                end
                
                if event_type == "mouseReleaseEvent" then
                    creatEntity:mouseReleaseEvent(event)
                    creatEntity = nil
                end
            end
            return event
        end);
        ParaLifeRole.IsRegisterEvent = true
    end
    
end

function ParaLifeRole.OnCreate()
    if page then
        local touchIndex =-1
        for i,v in ipairs(ParaLifeRole.role_configs) do
            local playUser = page:FindControl("main_user_player"..i)
            local node =page:GetNode("main_user_player"..i)
            if node then
                local abcdf = node.Canvas3D_ctl
                if abcdf then
                    local parent = abcdf:GetContainer()
                    parent:GetAttributeObject():SetField("ClickThrough", false)
                    parent:SetScript("onmouseup",function()
                        isTouchPlayer = false
                        touchIndex = -1
                    end)
                    parent:SetScript("onmousedown",function()
                        isTouchPlayer = true
                        touchIndex = i
                    end)
                    parent:SetScript("onmousemove",function()
                        if isTouchPlayer and touchIndex == i then
                            parent.visible = false
                            parent:GetAttributeObject():SetField("ClickThrough", true)
                            local result = Game.SelectionManager:MousePickBlock();
                            if result then
                                local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
                                local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
                                local bx,by,bz = result.blockX,result.blockY,result.blockZ
                                local filename="character/CC/02human/CustomGeoset/actor.x"
                                local entity = EntityManager.EntityLiveModel:Create({bx=bx,by=by + 1,bz=bz, item_id = block_types.names.LiveModel, facing=0.57}, serverdata);
                                entity:SetModelFile(filename)
                                entity:Refresh();
                                entity:Attach();
                                if creatEntity and mouse_event then
                                    creatEntity:mouseReleaseEvent(mouse_event)
                                    creatEntity = nil
                                end
                                creatEntity = entity
                            end
                        end
                    end)
                end
            end 
            local scene = ParaScene.GetMiniSceneGraph(playUser.resourceName);
            if scene and scene:IsValid() then
                local player = scene:GetObject(playUser.obj_name);
                if player then
                    player:SetScale(1)
                    player:SetFacing(1.57);
                    player:SetField("HeadUpdownAngle", 0.3);
                    player:SetField("HeadTurningAngle", 0);
                end
            end 
        end
              
    end
end

function ParaLifeRole.AddRoleIcon()
    if not page then
        return 
    end
    local bg = page:FindControl("paralife_role")
    local backimg = "Texture/Aries/Creator/keepwork/macro/btn_2_32X32_32bits.png;0 0 32 32:14 14 14 14"
    for i=1,3 do
        local btnTest = ParaUI.CreateUIObject("button", "AquariusCursorText", "_lt", (i - 1) * 60, 0, 40, 40); 
		btnTest.enabled = true;
		btnTest.background = backimg;
		btnTest.zorder = 1000; -- stay above all other ui objects
		_guihelper.SetUIColor(btnTest, "255 255 255")
		bg:AddChild(btnTest)
    end
end