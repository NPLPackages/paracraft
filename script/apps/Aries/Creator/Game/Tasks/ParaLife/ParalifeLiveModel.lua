--[[
    author:{pbb}
    time:2021-10-18 16:40:59
    uselib:
        local ParalifeLiveModel = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParalifeLiveModel.lua");
        ParalifeLiveModel.ShowView()
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
local Screen = commonlib.gettable("System.Windows.Screen");
local RolePlayMovieController = commonlib.gettable("MyCompany.Aries.Game.Movie.RolePlayMode.RolePlayMovieController");
local TouchSession = commonlib.gettable("MyCompany.Aries.Game.Common.TouchSession");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
local ParalifeLiveModel = NPL.export()
local page = nil
local default_model = "character/CC/02human/CustomGeoset/actor.x"
local default_skin = CustomCharItems:SkinStringToItemIds(CustomCharItems.defaultSkinString)
local default_role_data = {assetfile=default_model,skin=default_skin,scaling=1}
local creatEntity
local role_timer
ParalifeLiveModel.role_data = {
	{
		assetfile = "character/CC/02human/CustomGeoset/actor.x", 
        skin = "80001;83148;84100;81018;88002;85073;", 
        scaling = 1,
	},
	{
		assetfile = "character/CC/02human/CustomGeoset/actor.x",
		skin = "80001;84072;81049;88002;85091;83055;",
		scaling = 0.85152,
	}, 
	{
		assetfile = "character/CC/02human/CustomGeoset/actor.x",
		skin = "80001;82014;84013;81049;88002;85011;",
		scaling = 1,
	}, 
	{
		assetfile = "character/CC/02human/CustomGeoset/actor.x",
		skin = "80001;82035;84015;81018;88002;85011;",
		scaling = 0.88751,
	}, 
	{
		assetfile = "character/CC/02human/CustomGeoset/actor.x",
		skin = "80001;82025;84089;81007;88002;85109;",
		scaling = 1,
	},
	 {
		assetfile = "character/CC/02human/CustomGeoset/actor.x",
		skin = "80001;82107;84018;81007;88002;85020;",
		scaling = 1,
	}, 
	{
		assetfile = "character/CC/02human/CustomGeoset/actor.x",
		skin = "80001;84009;81075;88002;85015;83084;",
		scaling = 1,
	}, 
	{
		assetfile = "character/CC/02human/CustomGeoset/actor.x",
		skin = "80001;84100;81023;88002;85093;83161;",
		scaling = 1,
	}, 
	{
		assetfile = "character/CC/02human/CustomGeoset/actor.x",
		skin = "80001;84066;81049;88002;85085;83057;",
		scaling = 1,
	}, 
	{
		assetfile = "character/CC/02human/CustomGeoset/actor.x",
		skin = "80001;84027;81049;88002;85091;83132;",
		scaling = 1,
	}, 
	{
		assetfile = "character/CC/02human/CustomGeoset/actor.x",
		skin = "80001;84101;81006;88002;85097;83187;",
		scaling = 1,
	}, 
	{
		assetfile = "character/CC/02human/CustomGeoset/actor.x",
		skin = "80001;84058;81068;88018;85077;83166;",
		scaling = 1,
	}, 
	{
		assetfile = "character/CC/02human/CustomGeoset/actor.x",
		skin = "80001;84055;81068;88018;85077;83065;",
		scaling = 1,
	}, 
	{
		assetfile = "character/CC/02human/CustomGeoset/actor.x",
		skin = "80001;84073;81040;88023;85077;83001;",
		scaling = 1,
	}, 
	{
		assetfile = "character/CC/02human/CustomGeoset/actor.x",
		skin = "80001;84101;81034;88005;85093;83127;",
		scaling = 1,
	}, 
	{
		assetfile = "character/CC/02human/CustomGeoset/actor.x",
		skin = "80001;84107;81053;88023;85013;83050;",
		scaling = 1,
	}, 
	{
		assetfile = "character/CC/02human/CustomGeoset/actor.x",
		skin = "80001;84005;81017;88010;85013;83068;",
		scaling = 1,
	}, 
	{
		assetfile = "character/CC/02human/CustomGeoset/actor.x",
		skin = "80001;82047;84022;81009;88023;85081;",
		scaling = 1,
	}, 
	{
		assetfile = "character/CC/02human/CustomGeoset/actor.x",
		skin = "80001;84099;81015;88013;85081;83185;",
		scaling = 1,
	}, {
		assetfile = "character/CC/02human/CustomGeoset/actor.x",
		skin = "80001;82090;84103;81014;88026;85117;",
		scaling = 1,
	}, 
	{
		assetfile = "character/CC/02human/CustomGeoset/actor.x",
		skin = "80001;83151;84035;81001;88002;85087;",
		scaling = 1,
	}, 
	{
		assetfile = "character/CC/02human/CustomGeoset/actor.x",
		skin = "80001;83152;84037;81081;88002;85087;",
		scaling = 1,
	}, 
	{
		assetfile = "character/CC/02human/CustomGeoset/actor.x",
		skin = "80001;83153;84051;81082;88025;85087;",
		scaling = 1,
	}, 
	{
		assetfile = "character/CC/02human/CustomGeoset/actor.x",
		skin = "80001;83157;84044;81076;88025;85087;",
		scaling = 1,
	}, 
	{
		assetfile = "character/CC/02human/CustomGeoset/actor.x",
		skin = "80001;83148;84041;81016;88025;85087;",
		scaling = 1,
	}, 
	{
		assetfile = "character/CC/02human/CustomGeoset/actor.x",
		skin = "80001;83150;84049;81083;88025;85087;",
		scaling = 1,
	}, 
	{
		assetfile = "character/CC/02human/CustomGeoset/actor.x",
		skin = "80001;84056;88025;85075;83164;",
		scaling = 1,
	}, 
	{
		assetfile = "character/CC/02human/CustomGeoset/actor.x",
		skin = "80001;84057;81018;88025;85076;83165;",
		scaling = 1,
	}, 
	{
		assetfile = "character/CC/02human/CustomGeoset/actor.x",
		skin = "80001;84058;81042;88025;85077;83166;",
		scaling = 1,
	}, 
	{
		assetfile = "character/CC/02human/CustomGeoset/actor.x",
		skin = "80001;84059;81018;88025;85078;83167;86041;",
		scaling = 1,
	},
}
ParalifeLiveModel.show_role_data = {}
ParalifeLiveModel.main_ui_mode = "switchmain" --decorate
ParalifeLiveModel.cur_btn_anis = {}
ParalifeLiveModel.movie_entity = nil
function ParalifeLiveModel.OnInit()
    page = document:GetPageCtrl();
	page.OnCreate = ParalifeLiveModel.OnCreate
end

function ParalifeLiveModel.ShowView(entity)
	-- ParalifeLiveModel.InitRoleDataWithEntity(entity)
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/ParaLife/ParalifeLiveModel.html",
        name = "ParalifeLiveModel.ShowView", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        click_through = true,
        enable_esc_key = false,
        zorder = -13,
        app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key,
        directPosition = true,
        align = "_fi",
            x = 0,
            y = 0,
            width = 0,
            height = 0,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
	-- ParalifeLiveModel.GetSceneContext():activate();
    QuickSelectBar.ShowPage(false);
	GameLogic.RunCommand("/clearbag")
	GameLogic:Connect("WorldUnloaded", ParalifeLiveModel, ParalifeLiveModel.OnWorldUnload, "UniqueConnection");
	Screen:Connect("sizeChanged", ParalifeLiveModel, ParalifeLiveModel.OnScreenSizeChange, "UniqueConnection")
	ParalifeLiveModel.CheckPickRole()
end

function ParalifeLiveModel.CheckPickRole()
	role_timer = role_timer or commonlib.Timer:new({callbackFunc = function(timer)
		local mouse_x, mouse_y = ParaUI.GetMousePosition();
		local screen_width,screen_height = Screen:GetWidth(),Screen:GetHeight()
		local startx = screen_width/2 - 640
		local starty = screen_height - 300
		if mouse_y > starty and ParalifeLiveModel.main_ui_mode == "switchrole" then
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
					ParalifeLiveModel.AddRoleData(entity) 
					entity:SetDead();
				end
			end
		end
	end})
	role_timer:Change(0,10);
end

function ParalifeLiveModel.GetIndexWithMouse()
	local mouse_x, mouse_y = ParaUI.GetMousePosition();
	local index = math.floor(mouse_x / 200) + 1
	return index
end

function ParalifeLiveModel.GetShowNum()
	local screen_width = Screen:GetWidth()
	local num = math.floor(screen_width / 200)
	return num
end

function ParalifeLiveModel.OnScreenSizeChange()
	ParalifeLiveModel.RereshPage()
end

function ParalifeLiveModel.OnWorldUnload()
	ParalifeLiveModel.OnExitWorld()
	-- RolePlayMovieController.OnExitWorld()
end

function ParalifeLiveModel.InitRoleDataWithEntity(entity)
	if not entity or entity:GetType() ~= "EntityMovieClip" then
		return
	end
	ParalifeLiveModel.role_data = {}
	ParalifeLiveModel.movie_entity = entity
	local data = ParalifeLiveModel.movie_entity:GetAllActorData()
	local num = #data
	if num > 0 then
		ParalifeLiveModel.role_data = data
	else
		for i=1,7 do
			ParalifeLiveModel.role_data[ParalifeLiveModel.role_data + 1] = commonlib.deepcopy(default_role_data);
		end
	end
	echo(ParalifeLiveModel.role_data)
end

function ParalifeLiveModel.OnCreate()
	if page then
        ParalifeLiveModel.InitPlayerUI() 
		ParalifeLiveModel.InitPlayerView()
		ParalifeLiveModel.InitPlayerControl()
		local paralife_back = ParaUI.GetUIObject("paralife_back")
		if paralife_back then
			paralife_back:GetAttributeObject():SetField("ClickThrough", true)
		end             
    end
end

function ParalifeLiveModel.RemoveRoleData(index)
	local num = #ParalifeLiveModel.role_data
	for i=index,num do
		ParalifeLiveModel.role_data[i] = ParalifeLiveModel.role_data[i + 1]
	end
	ParalifeLiveModel.role_data[num] = nil
	ParalifeLiveModel.RereshPage()
end

function ParalifeLiveModel.AddRoleData(entity)
	if not entity then
		return 
	end
	local xmlnode = entity:SaveToXMLNode()
	local curNum = #ParalifeLiveModel.role_data
	local objScale = entity:GetInnerObject():GetScale()
	local assetfile = entity.filename
	local skin = entity.skin
	local scaling = entity.scaling or objScale
	local temp = {assetfile = entity.filename,skin = entity.skin,scaling = scaling or 1,xmlnode=xmlnode}
	local index = ParalifeLiveModel.GetIndexWithMouse()
	if curNum < ParalifeLiveModel.GetShowNum() then
		ParalifeLiveModel.role_data[curNum + 1] = temp
	else
		table.insert( ParalifeLiveModel.role_data, index ,temp )
	end
	ParalifeLiveModel.RereshPage()
end

function ParalifeLiveModel.MoveRoleData(move_num,ismoveleft)
	if move_num < 0 then
		return 
	end
	local role_num = #ParalifeLiveModel.role_data
	local type = ismoveleft or false
	local moveDatas = {}
	if ismoveleft then
		for i=1,move_num do
			local temp = commonlib.deepcopy(ParalifeLiveModel.role_data[i])
			table.remove(ParalifeLiveModel.role_data,i)
			table.insert( ParalifeLiveModel.role_data, temp)
		end
	else
		for i=1,move_num do
			local removeindex = role_num - i + 1
			local temp = commonlib.deepcopy(ParalifeLiveModel.role_data[removeindex])
			table.remove(ParalifeLiveModel.role_data,removeindex)
			table.insert( ParalifeLiveModel.role_data,1, temp)
		end
	end
	ParalifeLiveModel.RereshPage()
end


function ParalifeLiveModel.InitPlayerView()
	for i,v in ipairs(ParalifeLiveModel.role_data) do
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
					ParalifeLiveModel.SetPlayerSkin(player,v.assetfile,v.skin)
				end
			end 
		end
	end
end

function ParalifeLiveModel.InitPlayerControl()
	local paralife_back = ParaUI.GetUIObject("paralife_back")
	paralife_back:SetScript("onmouseup",function()			
		if creatEntity then
			ItemLiveModel:DropDraggingEntity();
			local index = creatEntity.remove_index
			ParalifeLiveModel.RemoveRoleData(index)
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

function ParalifeLiveModel.InitPlayerUI()
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
	for i,v in ipairs(ParalifeLiveModel.role_data) do
		local parentUser = ParaUI.GetUIObject("main_user_player_parent"..i)
		local startParaX,startParaY
		if parentUser then
			if i > ParalifeLiveModel.GetShowNum() then
				--parentUser.visible = false
			else
				parentUser:SetScript("onmouseup",function()
					isTouchPlayer = false
					touchIndex = -1
					local move_num = math.floor(math.abs(disx) / 200) + 1
					if move_num > 0 then
						ParalifeLiveModel.MoveRoleData(move_num , disx < 0 and disx ~= 0 )
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
							ParalifeLiveModel.CreateEntity(i,v)
							parentUser.visible = false
							paralife_back:GetAttributeObject():SetField("ClickThrough", false)
						end
						if ParalifeLiveModel.GetShowNum() < #ParalifeLiveModel.role_data then
							paralife_role.x = startParaX + disx
						end
					end
				end)
			end
			
		end
	end
end

function ParalifeLiveModel.CreateEntity(index,data) --创建livemodel
	local result, targetEntity = ItemLiveModel:CheckMousePick()
	local bx,by,bz = BlockEngine:GetBlockIndexBySide(result.blockX,result.blockY,result.blockZ,result.side);
	local facing = Direction.GetFacingFromCamera()
	facing = Direction.NormalizeFacing(facing)
	local filename=data.assetfile or "character/CC/02human/CustomGeoset/actor.x"
	local entity = EntityManager.EntityLiveModel:Create({bx=bx,by=by + 1,bz=bz, item_id = block_types.names.LiveModel, facing=facing}, serverdata);
	entity:SetModelFile(filename)
	entity:SetSkin(data.skin)
	entity:setScale(data.scaling)
	if data.xmlnode then
		entity:LoadFromXMLNode(data.xmlnode)
	end
	entity:Refresh();
	entity:Attach();
	creatEntity = entity
	creatEntity.remove_index = index
	ItemLiveModel:StartDraggingEntity(creatEntity)
end

function ParalifeLiveModel.SetPlayerSkin(player,assetfile,skin)
	if not player or not assetfile then
		return
	end
	local isCustomModel = PlayerAssetFile:IsCustomModel(assetfile)
	local hasCustomGeosets = PlayerAssetFile:HasCustomGeosets(assetfile)
	if isCustomModel then
		PlayerAssetFile:RefreshCustomModel(player, skin)
		return
	end

	if hasCustomGeosets then
		PlayerAssetFile:RefreshCustomGeosets(player, skin);
		return
	end
end

function ParalifeLiveModel.GetSceneContext()
	if(not ParalifeLiveModel.sceneContext) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/AllContext.lua");
		local AllContext = commonlib.gettable("MyCompany.Aries.Game.AllContext");
		ParalifeLiveModel.sceneContext = AllContext:GetContext("roleplay");
	end
	return ParalifeLiveModel.sceneContext;
end

function ParalifeLiveModel.RereshPage()
    if page then
        page:Refresh(0)
    end
end

function ParalifeLiveModel.ClosePage()
	if page then
        page:CloseWindow()
		page = nil
		ParalifeLiveModel.main_ui_mode = "switchmain"
		--GameLogic.ActivateDefaultContext()
    end
end

function ParalifeLiveModel.SwitchOperateButton(name)
	if not name or ParalifeLiveModel.main_ui_mode == name  then
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
	
	ParalifeLiveModel.main_ui_mode = name
	ParalifeLiveModel.RereshPage()
end

function ParalifeLiveModel.OnExitWorld()
	ParalifeLiveModel.main_ui_mode = "switchmain"
	GameLogic.RunCommand("/clearbag")
	ParalifeLiveModel.ClosePage()
end
