--[[
    author:{pbb}
    time:2021-10-18 16:40:59
    uselib:
        local ParaLifeMainUI = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeMainUI.lua");
        ParaLifeMainUI.ShowView()
	-- ParaCamera.GetAttributeObject():SetField("BlockInput", true);
	-- ParaCamera.GetAttributeObject():SetField("EnableMouseRightButton", false)
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/QuickSelectBar.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TouchSession.lua");
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/RolePlayMode/RolePlayMovieController.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemLiveModel.lua");
NPL.load("Mod/GeneralGameServerMod/App/Client/AppGeneralGameClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/TouchMiniKeyboard.lua");
local TouchMiniKeyboard = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchMiniKeyboard");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local AppGeneralGameClient = commonlib.gettable("Mod.GeneralGameServerMod.App.Client.AppGeneralGameClient");
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
local ItemLiveModel = commonlib.gettable("MyCompany.Aries.Game.Items.ItemLiveModel");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local ModelTextureAtlas = commonlib.gettable("MyCompany.Aries.Game.Common.ModelTextureAtlas");
local RolePlayMovieController = commonlib.gettable("MyCompany.Aries.Game.Movie.RolePlayMode.RolePlayMovieController");
local Screen = commonlib.gettable("System.Windows.Screen");
local RolePlayMovieController = commonlib.gettable("MyCompany.Aries.Game.Movie.RolePlayMode.RolePlayMovieController");
local TouchSession = commonlib.gettable("MyCompany.Aries.Game.Common.TouchSession");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
local ParaLifeMainUI = NPL.export()
local page = nil
local ani_path = "Texture/Aries/Creator/keepwork/Paralife/animation/"
local player_ani_config = {
	{ani_name="bow",ani_id = 34,ani_icon = "bow_32bits.png",isdefault = true},
	{ani_name="wave",ani_id = 35,ani_icon = "wave_32bits.png",isdefault = true},
	{ani_name="lieside",ani_id = 88,ani_icon = "lieside_32bits.png",isdefault = true},
	{ani_name="dance",ani_id = 144,ani_icon = "dance_32bits.png",isdefault = true},
	{ani_name="clap",ani_id = 145,ani_icon = "clap_32bits.png",isdefault = true},
	{ani_name="nod",ani_id = 31,ani_icon = "nod_32bits.png",isdefault = true},
	{ani_name="shakehead",ani_id = 32,ani_icon = "shakehead_32bits.png",isdefault = true},
	{ani_name="sit",ani_id = 72,ani_icon = "sit_32bits.png",},
	{ani_name="lie",ani_id = 100,ani_icon = "lie_32bits.png",},
	{ani_name="sort",ani_id = 118,ani_icon = "sort_32bits.png",},
	{ani_name="jump",ani_id = 176,ani_icon = "jump_32bits.png",},
	{ani_name="dazuo",ani_id = 187,ani_icon = "dazuo_32bits.png",},
	{ani_name="pushup",ani_id = 188,ani_icon = "pushup_32bits.png",},
	{ani_name="dizzy",ani_id = 189,ani_icon = "dizzy_32bits.png",},
	{ani_name="hooray",ani_id = 191,ani_icon = "hooray_32bits.png",},
}


local default_model = "character/CC/02human/CustomGeoset/actor.x"
local default_skin = CustomCharItems:SkinStringToItemIds(CustomCharItems.defaultSkinString)
local default_role_data = {assetfile=default_model,skin=default_skin,scaling=1}
local ani_icon_num = 7
local creatEntity
local isMouseRelease
local role_timer
ParaLifeMainUI.role_data = {}
ParaLifeMainUI.show_role_data = {}
ParaLifeMainUI.main_ui_mode = "switchmain" --decorate
ParaLifeMainUI.view_mode = "main" -- movie
ParaLifeMainUI.cur_btn_anis = {}
ParaLifeMainUI.movie_entity = nil
function ParaLifeMainUI.OnInit()
    page = document:GetPageCtrl();
	page.OnCreate = ParaLifeMainUI.OnCreate
end

function ParaLifeMainUI.ShowView(entity)
	ParaLifeMainUI.InitRoleDataWithEntity(entity)
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeMainUI.html",
        name = "ParaLifeMainUI.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        click_through = true,
        enable_esc_key = true,
        zorder = -13,
		-- DesignResolutionWidth = 1280,
		-- DesignResolutionHeight = 720,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key,
        directPosition = true,
        align = "_fi",
            x = 0,
            y = 0,
            width = 0,
            height = 0,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
	ParaLifeMainUI.GetSceneContext():activate();
    QuickSelectBar.ShowPage(false);
	GameLogic.RunCommand("/clearbag")
	GameLogic:Connect("WorldUnloaded", ParaLifeMainUI, ParaLifeMainUI.OnWorldUnload, "UniqueConnection");
	Screen:Connect("sizeChanged", ParaLifeMainUI, ParaLifeMainUI.OnScreenSizeChange, "UniqueConnection")
	ParaLifeMainUI.CheckPickRole()
end

function ParaLifeMainUI.CheckPickRole()
	role_timer = role_timer or commonlib.Timer:new({callbackFunc = function(timer)
		local mouse_x, mouse_y = ParaUI.GetMousePosition();
		local screen_width,screen_height = Screen:GetWidth(),Screen:GetHeight()
		local startx = screen_width/2 - 640
		local starty = screen_height - 300
		if mouse_y > starty and ParaLifeMainUI.main_ui_mode == "switchrole" then
			local result, targetEntity = ItemLiveModel:CheckMousePick()
			if not targetEntity and result.blockX then
				local entityBlock = EntityManager.GetBlockEntity(result.blockX, result.blockY, result.blockZ)
				if(entityBlock and entityBlock:isa(EntityManager.EntityBlockModel)) then
					targetEntity = entityBlock;
				end
			end
			if targetEntity or result.entity then
				local entity = result.entity or targetEntity
				if entity.item_id and entity.item_id == 10074 and entity.hasCustomGeosets  then
					ParaLifeMainUI.AddRoleData(entity) 
					entity:SetDead();
				end
			end
		end
	end})
	role_timer:Change(0,10);
end

function ParaLifeMainUI.InitShowRoleData()
	local screen_width = Screen:GetWidth()
	local data_num = math.floor(screen_width / 200)
	for i=1,data_num do
		if not ParaLifeMainUI.role_data[i].isUse then
			ParaLifeMainUI.show_role_data[i] = commonlib.deepcopy(ParaLifeMainUI.role_data[i])
			ParaLifeMainUI.role_data[i].isUse = true
		end
	end
end

function ParaLifeMainUI.GetIndexWithMouse()
	local mouse_x, mouse_y = ParaUI.GetMousePosition();
	local index = math.floor(mouse_x / 200) + 1
	return index
end

function ParaLifeMainUI.GetShowNum()
	local screen_width = Screen:GetWidth()
	local num = math.floor(screen_width / 200)
	return num
end

function ParaLifeMainUI.OnScreenSizeChange()
	ParaLifeMainUI.RereshPage()
end

function ParaLifeMainUI.OnWorldUnload()
	ParaLifeMainUI.OnExitWorld()
	RolePlayMovieController.OnExitWorld()
end

function ParaLifeMainUI.InitRoleDataWithEntity(entity)
	if not entity or entity:GetType() ~= "EntityMovieClip" then
		return
	end
	ParaLifeMainUI.role_data = {}
	ParaLifeMainUI.movie_entity = entity
	local data = ParaLifeMainUI.movie_entity:GetAllActorData()
	local num = #data
	if num > 0 then
		ParaLifeMainUI.role_data = data
	else
		for i=1,7 do
			ParaLifeMainUI.role_data[ParaLifeMainUI.role_data + 1] = commonlib.deepcopy(default_role_data);
		end
	end
	echo(ParaLifeMainUI.role_data)
end

function ParaLifeMainUI.InitAnimPlayer()
    local player = ParaLifeMainUI.GetPlayer()
    if player then
        player:SetScale(1)
        player:SetFacing(1.57);
        player:SetField("HeadUpdownAngle", 0.3);
        player:SetField("HeadTurningAngle", 0);
    end
end

function ParaLifeMainUI.GetPlayer()
    if page and page:IsVisible() then
        local module_ctl = page:FindControl("main_role_anim")
        local scene = ParaScene.GetMiniSceneGraph(module_ctl.resourceName);
        if scene and scene:IsValid() then
            local player = scene:GetObject(module_ctl.obj_name);
            if player then
                return player
            end
        end
    end
end

function ParaLifeMainUI.OnCreate()
	if page then
		ParaLifeMainUI.OnInitButton()
        ParaLifeMainUI.InitPlayerUI() 
		ParaLifeMainUI.InitPlayerView()
		ParaLifeMainUI.InitPlayerControl()
		local paralife_back = ParaUI.GetUIObject("paralife_back")
		if paralife_back then
			paralife_back:GetAttributeObject():SetField("ClickThrough", true)
		end             
    end
end

function ParaLifeMainUI.RemoveRoleData(index)
	local num = #ParaLifeMainUI.role_data
	for i=index,num do
		ParaLifeMainUI.role_data[i] = ParaLifeMainUI.role_data[i + 1]
	end
	ParaLifeMainUI.role_data[num] = nil
	ParaLifeMainUI.RereshPage()
end

function ParaLifeMainUI.AddRoleData(entity)
	if not entity then
		return 
	end
	local xmlnode = entity:SaveToXMLNode()
	local curNum = #ParaLifeMainUI.role_data
	local objScale = entity:GetInnerObject():GetScale()
	local assetfile = entity.filename
	local skin = entity.skin
	local scaling = entity.scaling or objScale
	local temp = {assetfile = entity.filename,skin = entity.skin,scaling = scaling or 1,xmlnode=xmlnode}
	local index = ParaLifeMainUI.GetIndexWithMouse()
	if curNum < ParaLifeMainUI.GetShowNum() then
		ParaLifeMainUI.role_data[curNum + 1] = temp
	else
		table.insert(ParaLifeMainUI.role_data, index ,temp)
	end
	ParaLifeMainUI.RereshPage()
end

function ParaLifeMainUI.MoveRoleData(move_num,ismoveleft)
	if move_num < 0 then
		return 
	end
	local role_num = #ParaLifeMainUI.role_data
	local type = ismoveleft or false
	local moveDatas = {}
	if ismoveleft then
		for i=1,move_num do
			local temp = commonlib.deepcopy(ParaLifeMainUI.role_data[i])
			table.remove(ParaLifeMainUI.role_data,i)
			table.insert( ParaLifeMainUI.role_data, temp)
		end
	else
		for i=1,move_num do
			local removeindex = role_num - i + 1
			local temp = commonlib.deepcopy(ParaLifeMainUI.role_data[removeindex])
			table.remove(ParaLifeMainUI.role_data,removeindex)
			table.insert( ParaLifeMainUI.role_data,1, temp)
		end
	end
	ParaLifeMainUI.RereshPage()
end


function ParaLifeMainUI.InitPlayerView()
	for i,v in ipairs(ParaLifeMainUI.role_data) do
		local playUser = page:FindControl("main_user_player"..i)
		if playUser then
			local scene = ParaScene.GetMiniSceneGraph(playUser.resourceName);
			if scene and scene:IsValid() then
				local player = scene:GetObject(playUser.obj_name);
				if player then
					player:SetScale(1)
					player:SetFacing(1.57);
					player:SetField("HeadUpdownAngle", 0.3);
					player:SetField("HeadTurningAngle", 0);
					player:SetField("assetfile",v.assetfile)
					ParaLifeMainUI.SetPlayerSkin(player,v.assetfile,v.skin)
				end
			end 
		end
	end
end

function ParaLifeMainUI.InitPlayerControl()
	local paralife_back = ParaUI.GetUIObject("paralife_back")
	paralife_back:SetScript("onmouseup",function()			
		if creatEntity then
			ItemLiveModel:DropDraggingEntity();
			local index = creatEntity.remove_index
			ParaLifeMainUI.RemoveRoleData(index)
			paralife_back:GetAttributeObject():SetField("ClickThrough", true)
			creatEntity = nil
		end
	end)
	paralife_back:SetScript("onmousemove",function()
		if creatEntity  then
			local result, targetEntity = ItemLiveModel:CheckMousePick()
			ItemLiveModel:UpdateDraggingEntity(creatEntity, result, targetEntity)
		else

		end
	end)
end

function ParaLifeMainUI.InitPlayerUI()
	local touchIndex =-1
	local isTouchPlayer = false
	local paralife_back = ParaUI.GetUIObject("paralife_back")
	local paralife_role = ParaUI.GetUIObject("paralife_role")
	local screen_width,screen_height = Screen:GetWidth(),Screen:GetHeight()
	local startx = screen_width/2 - 640
	local starty = screen_height - 250
	local mouse_x, mouse_y = ParaUI.GetMousePosition();
	local startmousex,startmousey
	local disx,disy = 0,0
	for i,v in ipairs(ParaLifeMainUI.role_data) do
		local parentUser = ParaUI.GetUIObject("main_user_player_parent"..i)
		local startParaX,startParaY
		if parentUser then
			if i > ParaLifeMainUI.GetShowNum() then
				--parentUser.visible = false
			else
				parentUser:SetScript("onmouseup",function()
					isTouchPlayer = false
					touchIndex = -1
					local move_num = math.floor(math.abs(disx) / 200) + 1
					if move_num > 0 then
						ParaLifeMainUI.MoveRoleData(move_num , disx < 0 and disx ~= 0 )
					end
				end)
				parentUser:SetScript("onmousedown",function()
					isTouchPlayer = true
					touchIndex = i
					startmousex,startmousey = ParaUI.GetMousePosition();
					startParaX = paralife_role.x
				end)
				parentUser:SetScript("onmousemove",function()
					if isTouchPlayer and touchIndex == i then
						mouse_x, mouse_y = ParaUI.GetMousePosition();
						disx,disy = mouse_x - startmousex ,mouse_y - startmousey
						if disy < 0 and mouse_y < starty  then
							ParaLifeMainUI.CreateEntity(i,v)
							parentUser.visible = false
							paralife_back:GetAttributeObject():SetField("ClickThrough", false)
						end
						if ParaLifeMainUI.GetShowNum() < #ParaLifeMainUI.role_data then
							paralife_role.x = startParaX + disx
						end
					end
				end)
			end
			
		end
	end
end

function ParaLifeMainUI.CreateEntity(index,data) --创建livemodel
	local result, targetEntity = ItemLiveModel:CheckMousePick()
	local bx,by,bz = BlockEngine:GetBlockIndexBySide(result.blockX,result.blockY,result.blockZ,result.side);
	local facing = Direction.GetFacingFromCamera()
	facing = Direction.NormalizeFacing(facing)
	local filename=data.assetfile or "character/CC/02human/CustomGeoset/actor.x"
	local entity = EntityManager.EntityLiveModel:Create({bx=bx,by=by + 1,bz=bz, item_id = block_types.names.LiveModel, facing=facing}, serverdata);
	entity:SetModelFile(filename)
	if data.xmlnode then
		entity:LoadFromXMLNode(data.xmlnode)
	end
	entity:SetSkin(data.skin)
	entity:setScale(data.scaling)
	entity:Refresh();
	entity:Attach();
	creatEntity = entity
	creatEntity.remove_index = index
	ItemLiveModel:StartDraggingEntity(creatEntity)
end

function ParaLifeMainUI.SetPlayerSkin(player,assetfile,skin)
	if not player or not assetfile then
		return
	end
	local isCustomModel = PlayerAssetFile:IsCustomModel(assetfile)
	local hasCustomGeosets = PlayerAssetFile:HasCustomGeosets(assetfile)
	if string.find(assetfile,"bmax") then
		print("isCustomModel===",isCustomModel,hasCustomGeosets)
	end
	if isCustomModel then
		PlayerAssetFile:RefreshCustomModel(player, skin)
		return
	end

	if hasCustomGeosets then
		PlayerAssetFile:RefreshCustomGeosets(player, skin);
		return
	end
end

function ParaLifeMainUI.GetSceneContext()
	if(not ParaLifeMainUI.sceneContext) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/AllContext.lua");
		local AllContext = commonlib.gettable("MyCompany.Aries.Game.AllContext");
		ParaLifeMainUI.sceneContext = AllContext:GetContext("roleplay");
	end
	return ParaLifeMainUI.sceneContext;
end

function ParaLifeMainUI.RereshPage()
    if page then
        page:Refresh(0)
    end
end

function ParaLifeMainUI.ClosePage()
	if page then
        page:CloseWindow()
		page = nil
		GameLogic.ActivateDefaultContext()
    end
end

function ParaLifeMainUI.SwitchOperateButton(name)
	if not name or ParaLifeMainUI.main_ui_mode == name  then
		return
	end
	if name == "switchmap" then
		
		return
	end
	local isMobile = System.options.IsTouchDevice or GameLogic.options:HasTouchDevice()
	if isMobile then
		if name == "switchmain" then
			TouchMiniKeyboard.CheckShow(true)
		end
		if name == "switchrole" then
			TouchMiniKeyboard.CheckShow(false)
		end
	end
	ParaLifeMainUI.main_ui_mode = name
	ParaLifeMainUI.RereshPage()
end

function ParaLifeMainUI.OnClickTopBtn(name)
	if name == "gift" then
		local VipPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/VipPage.lua");
        VipPage.ShowPage();
	elseif name == "wifi" then
		local isLogin = AppGeneralGameClient:IsLogin()
		if not isLogin then
			GameLogic.RunCommand("/ggs connect")
		end
	elseif name == "exit" then

	elseif name == "skin" then

	end
end

--动作模块start

function ParaLifeMainUI.GetDefaultAni()
	local defaultAni = {}
	for i=1,#player_ani_config do
		if player_ani_config[i].isdefault then
			defaultAni[#defaultAni + 1] = player_ani_config[i]
		end
	end
	return defaultAni
end

function ParaLifeMainUI.GetAniIconById(aniId)
	local path = ani_path
	for i=1,#player_ani_config do
		local cnf = player_ani_config[i]
		if cnf and cnf.ani_id == aniId then
			path = path..cnf.ani_icon..";0 0 128 128"
			break
		end
	end
	return path
end

function ParaLifeMainUI.InitBtnAniIcon()
	local default = ParaLifeMainUI.GetDefaultAni()
	for i=1,ani_icon_num do
		local uiname = "ParaLifeMainUI.actor_ani"..i
		local btn = ParaUI.GetUIObject(uiname)
		local cnf = default[i]
		if cnf and cnf.ani_id then
			local background = ParaLifeMainUI.GetAniIconById(cnf.ani_id)
			btn.background = background
		end
	end
	ParaLifeMainUI.cur_btn_anis = default
end

function ParaLifeMainUI.ChangeAni(index,ani_id)
	local uiname = "ParaLifeMainUI.actor_ani"..index
	local btn = ParaUI.GetUIObject(uiname)
	btn.background = ParaLifeMainUI.GetAniIconById(ani_id)
	local select_anim = ParaLifeMainUI.GetAnimById(ani_id)
	ParaLifeMainUI.cur_btn_anis[index] = select_anim
	-- echo(ParaLifeMainUI.cur_btn_anis,true)
end

function ParaLifeMainUI.GetAnimById(anim_id)
	for i=1,#player_ani_config do
		local cnf = player_ani_config[i]
		if cnf and cnf.ani_id == anim_id then
			return cnf
		end
	end
end

function ParaLifeMainUI.OnInitButton()
	local self = ParaLifeMainUI
	self.InitBtnAniIcon()
	for i=1,ani_icon_num do
		local uiname = "ParaLifeMainUI.actor_ani"..i
		local btn = ParaUI.GetUIObject(uiname)
		-- echo(btn)
		if btn and btn:IsValid()then
			btn:SetScript("ontouch", function() 
				self:OnTouch(msg,i) 
			end);
			btn:SetScript("onmousedown", function() self:OnMouseDown(i) end);
			btn:SetScript("onmouseup", function() self:OnMouseUp(i) end);
		end
	end
end

-- simulate the touch event with id=-1
function ParaLifeMainUI:OnMouseDown(touchIndex)
	local touch = {type="WM_POINTERDOWN", x=mouse_x, y=mouse_y, id=-1, time=0};
	self:OnTouch(touch,touchIndex);
end

-- simulate the touch event
function ParaLifeMainUI:OnMouseUp(touchIndex)
	local touch = {type="WM_POINTERUP", x=mouse_x, y=mouse_y, id=-1, time=0};
	self:OnTouch(touch,touchIndex);
end

-- handleTouchEvent
function ParaLifeMainUI:OnTouch(touch,touchIndex)
	-- handle the touch
	local self = ParaLifeMainUI
	local touch_session = TouchSession.GetTouchSession(touch);
	local btnItem = self:GetButtonItem(touchIndex);
	-- let us track it with an item. 
	local curTime = os.time()
	if(touch.type == "WM_POINTERDOWN") then
		if(btnItem) then
			touch_session:SetField("keydownBtn", btnItem);
			self:SetKeyState(btnItem, true);
			btnItem.isDragged = nil;
			curTime = os.time()
			ParaLifeMainUI.touch_time = curTime
		end
	elseif(touch.type == "WM_POINTERUPDATE") then
		local keydownBtn = touch_session:GetField("keydownBtn");
		if(keydownBtn and touch_session:IsDragging()) then
			
		end
		
	elseif(touch.type == "WM_POINTERUP") then
		self:SetKeyState(btnItem, false);
		local ani_id = ParaLifeMainUI.cur_btn_anis[touchIndex].ani_id
		curTime = os.time()
		local btnName = btnItem.name
		if curTime - ParaLifeMainUI.touch_time >= 1 then --长按
			-- GameLogic.AddBBS(nil,"开始===============")
			ParaLifeMainUI.touch_time = curTime
			local ParaLifeSelectAnimate = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeSelectAnimate.lua") 
    		ParaLifeSelectAnimate.ShowView(ani_id,function(select_anim_id)
				ParaLifeMainUI.ChangeAni(touchIndex,select_anim_id)
			end)
			return
		end
		-- GameLogic.AddBBS(nil,"播放动作，或者电影方块添加动作")
		--播放动作，或者电影方块添加动作
		print("ani_id=============",ani_id)
		ParaLifeMainUI.PlayPlayerAni(ani_id)
	end
	
end

function ParaLifeMainUI.PlayPlayerAni(ani_id)
	if not ani_id or ani_id < 0 then
		return
	end
	local player = EntityManager:GetFocus()--GameLogic.GetPlayer()
	if player then
		local obj = player:GetInnerObject();
		if(obj) then
			obj:ToCharacter():PlayAnimation(ani_id);
		end
	end
end

--{normal="#ffffff", pressed="#888888"}, 
function ParaLifeMainUI:SetKeyState(btnItem, bPress)
	if btnItem and btnItem:IsValid() then
		if bPress then
			_guihelper.SetUIColor(btnItem, "#888888");
		else
			_guihelper.SetUIColor(btnItem, "#ffffff");
		end
	end
end

-- get button item by global touch screen position. 
function ParaLifeMainUI:GetButtonItem(touchIndex)
	local btn = ParaUI.GetUIObject("ParaLifeMainUI.actor_ani"..touchIndex)
	if btn and btn:IsValid() then
		return btn
	end
end

-- 动作模块end


--
function ParaLifeMainUI.OnClickGlove()
	ParaLifeMainUI.GetSceneContext().SetIsSelectGlove()
end

function ParaLifeMainUI.OnClickBrush()
	ParaLifeMainUI.GetSceneContext().SetIsSelectBrush()
	GameLogic.ToggleDesktop("builder");
end

function ParaLifeMainUI.OnClickPaint()
	ParaLifeMainUI.GetSceneContext().SetIsSelectPaint()
	GameLogic.ToggleDesktop("builder");
end

function ParaLifeMainUI.OnClickFurniture() --工具箱
	ParaLifeMainUI.GetSceneContext().SetIsSelectOther()
	GameLogic.RunCommand("/clearbag")
	GameLogic.ToggleDesktop("builder");
end

function ParaLifeMainUI.OnClickCamera() --电影
	ParaLifeMainUI.GetSceneContext().SetIsSelectOther()
	GameLogic.RunCommand("/clearbag")
	ParaLifeMainUI.ClosePage()
	RolePlayMovieController.OnActivate()
end


function ParaLifeMainUI.OnExitWorld()
	ParaLifeMainUI.main_ui_mode = "switchmain"
	ParaLifeMainUI.view_mode = "main"
	ParaLifeMainUI.cur_btn_anis = {}
	GameLogic.RunCommand("/clearbag")
	ParaLifeMainUI.ClosePage()
end

--对应电影方块的插槽

function ParaLifeMainUI.ShowRolePage()
	local ParaLifeSelectRole = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeSelectRole.lua") 
	ParaLifeSelectRole.ShowView(function(model,skin)
		ParaLifeMainUI.UpdateRoleIcon(model,skin)
	end)
end

function ParaLifeMainUI.UpdateRoleIcon(model,skin)
	local player = ParaLifeMainUI.GetPlayer()
	if player then
		
	end
end
