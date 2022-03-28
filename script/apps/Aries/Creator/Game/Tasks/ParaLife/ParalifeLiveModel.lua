--[[
    author:{pbb}
    time:2021-10-18 16:40:59
    uselib:
        local ParalifeLiveModel = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParalifeLiveModel.lua");
        ParalifeLiveModel.ShowView()
]]
NPL.load("(gl)script/ide/Canvas3D.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/QuickSelectBar.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TouchSession.lua");
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/RolePlayMode/RolePlayMovieController.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/TouchMiniKeyboard.lua");
NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeTouchController.lua");
NPL.load("(gl)script/ide/System/Core/Color.lua");
local Color = commonlib.gettable("System.Core.Color");
local ParaLifeTouchController = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeTouchController")
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
local TouchMiniKeyboard = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchMiniKeyboard");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local ModelTextureAtlas = commonlib.gettable("MyCompany.Aries.Game.Common.ModelTextureAtlas");
local Screen = commonlib.gettable("System.Windows.Screen");
local MouseEvent = commonlib.gettable("System.Windows.MouseEvent");
local RolePlayMovieController = commonlib.gettable("MyCompany.Aries.Game.Movie.RolePlayMode.RolePlayMovieController");
local TouchSession = commonlib.gettable("MyCompany.Aries.Game.Common.TouchSession");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
local Recording = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/Recording.lua") 
local ParalifeLiveModel = NPL.export()
local page = nil
local default_model = "character/CC/02human/CustomGeoset/actor.x"
local default_skin = CustomCharItems:SkinStringToItemIds(CustomCharItems.defaultSkinString)
local default_data = {assetfile=default_model,skin=default_skin,scaling=1}
local createdEntity
local default_role_data = {
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

local face_path = "Texture/Aries/Creator/keepwork/Paralife/expression/"
local default_face_data = {
	{
		icon = face_path.."tou1_64x53_32bits.png",
		skin = "81007;88002",
	},
	{
		icon = face_path.."tou2_64x53_32bits.png",
		skin = "81010;88016",
	},
	{
		icon = face_path.."tou3_64x53_32bits.png",
		skin = "81074;88017",
	},
	{
		icon = face_path.."tou4_64x53_32bits.png",
		skin = "81004;88013",
	},
	{
		icon = face_path.."tou5_64x53_32bits.png",
		skin = "81017;88007",
	},
	{
		icon = face_path.."tou6_64x53_32bits.png",
		skin = "81049;88004",
	},
	{
		icon = face_path.."tou7_64x53_32bits.png",
		skin = "81007;88008",
	},
	{
		icon = face_path.."tou8_64x53_32bits.png",
		skin = "81008;88002",
	},
	{
		icon = face_path.."tou9_64x53_32bits.png",
		skin = "81019;88002",
	},
	{
		icon = face_path.."tou10_64x53_32bits.png",
		skin = "81075;88012",
	},
	{
		icon = face_path.."tou11_64x53_32bits.png",
		skin = "81010;88009",
	},
	{
		icon = face_path.."tou12_64x53_32bits.png",
		skin = "81005;88007",
	},
	{
		icon = face_path.."tou13_64x53_32bits.png",
		skin = "81031;88002",
	},
	{
		icon = face_path.."tou14_64x53_32bits.png",
		skin = "81025;88019",
	},
	{
		icon = face_path.."tou15_64x53_32bits.png",
		skin = "81032;88013",
	},
	{
		icon = face_path.."tou16_64x53_32bits.png",
		skin = "81038;88011",
	},
	{
		icon = face_path.."tou17_64x53_32bits.png",
		skin = "81037;88010",
	},
	{
		icon = face_path.."tou18_64x53_32bits.png",
		skin = "81043;88005",
	},
	{
		icon = face_path.."tou19_64x53_32bits.png",
		skin = "81053;88016",
	},
	{
		icon = face_path.."tou20_64x53_32bits.png",
		skin = "81057;88013",
	},
	{
		icon = face_path.."lian1_64x53_32bits.png",
		skin = "81017;88019",
	},
	{
		icon = face_path.."lian2_64x53_32bits.png",
		skin = "81014;88019",
	},
	{
		icon = face_path.."lian5_64x53_32bits.png",
		skin = "81006;88015",
	},
}

--数据分页
local _PaginatedData = commonlib.inherit()
function _PaginatedData:ctor()
	self:setDataSource(self.arr or {},self.pageLen or 10)
end

function _PaginatedData:setDataSource(arr,pageLen)
	self.arr = arr
	self.pageLen = pageLen
	self.curPageIdx = 1
end

--获取当前页的起止索引
function _PaginatedData:getCurIdxes()
	local idx_begin = (self.curPageIdx-1)*self.pageLen+1
	local idx_end = math.min(idx_begin+self.pageLen-1,#self.arr)
	return idx_begin,idx_end
end

function _PaginatedData:getDataByIdx(i)
	return self.arr[i]
end

function _PaginatedData:getSize()
	return #self.arr
end

--获取当前页
function _PaginatedData:getCurPage()
	return self.curPageIdx
end

function _PaginatedData:getNextPage()
	self.curPageIdx = self.curPageIdx + 1
	if self.curPageIdx>math.ceil(#self.arr/self.pageLen) then 
		self.curPageIdx = 1
	end
	
	return self.curPageIdx,self:getCurIdxes()
end

function _PaginatedData:getPrePage()
	self.curPageIdx = self.curPageIdx - 1
	if self.curPageIdx<1 then 
		self.curPageIdx = math.ceil(#self.arr/self.pageLen)
	end
	
	return self.curPageIdx,self:getCurIdxes()
end

ParalifeLiveModel.main_ui_mode = "switchmain"
ParalifeLiveModel.role_data = {}
ParalifeLiveModel.face_data = _PaginatedData:new({arr = default_face_data,pageLen=11})
ParalifeLiveModel.movie_entity = nil
function ParalifeLiveModel.OnInit()
    page = document:GetPageCtrl();
	page.OnCreate = ParalifeLiveModel.OnCreate
end

function ParalifeLiveModel.ShowView(entity)
	ParalifeLiveModel.InitRoleDataWithEntity(entity)
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
		bShow = true,
        align = "_fi",
            x = 0,
            y = 0,
            width = 0,
            height = 0,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
	GameLogic:Connect("WorldUnloaded", ParalifeLiveModel, ParalifeLiveModel.OnWorldUnload, "UniqueConnection");
	Screen:Connect("sizeChanged", ParalifeLiveModel, ParalifeLiveModel.OnScreenSizeChange, "UniqueConnection")
end

function ParalifeLiveModel.GetIndexWithMouse()
	local _parent = ParaUI.GetUIObject("paralife_role")
	local mouse_x, mouse_y = ParaUI.GetMousePosition();
	mouse_x = mouse_x - _parent.x
	local index = math.floor(mouse_x / ParalifeLiveModel.GetRoleViewWidth()) + 1
	return index
end

function ParalifeLiveModel.GetShowNum()
	local screen_width = Screen:GetWidth()
	local num = math.floor(screen_width / ParalifeLiveModel.GetRoleViewWidth())
	return num
end

function ParalifeLiveModel.OnScreenSizeChange()
	ParalifeLiveModel.RefreshPage()
end

function ParalifeLiveModel.OnWorldUnload()
	ParalifeLiveModel.OnExitWorld()
	-- RolePlayMovieController.OnExitWorld()
end

function ParalifeLiveModel.InitRoleDataWithEntity(entity)
	if ParalifeLiveModel.IsInit then
		return
	end
	ParalifeLiveModel.IsInit = true
	ParalifeLiveModel.role_data = default_role_data
	
	if entity and entity:GetType() == "EntityMovieClip" then
		ParalifeLiveModel.movie_entity = entity
		local data = ParalifeLiveModel.movie_entity:GetAllActorData()
		local num = #data
		if num > 0 then
			ParalifeLiveModel.role_data = data
		end
	end

	local entities = GameLogic.EntityManager.FindEntities({category="all", })
	local num = #entities
	for i=1,num do
		local entity = entities[i]
		if entity and entity:isa(EntityManager.EntityLiveModel) and entity:HasCustomGeosets() then
			ParalifeLiveModel.AddRoleData(entity)
		end
	end
end

function ParalifeLiveModel.SetBagDataWithEntity(entity)
	if entity==nil then
		return
	end
	ParalifeLiveModel.IsInit = true
	ParalifeLiveModel.role_data = {}
	if entity:GetType() == EntityManager.EntityMovieClip.class_name then
		ParalifeLiveModel.movie_entity = entity
		local data = ParalifeLiveModel.movie_entity:GetAllActorData()
		local num = #data
		if num > 0 then
			ParalifeLiveModel.role_data = data
		end
	elseif entity:GetType() == EntityManager.EntityLiveModel.class_name then
		ParalifeLiveModel.AddRoleData(entity)
	end
	ParalifeLiveModel.RefreshPage()
end

function ParalifeLiveModel.AddBagDataWithEntity(entity)
	if entity==nil then
		return
	end
	ParalifeLiveModel.AddRoleData(entity)
	ParalifeLiveModel.RefreshPage()
end


function ParalifeLiveModel.ClearBag()
	ParalifeLiveModel.role_data = {}
	ParalifeLiveModel.RefreshPage()
end

function ParalifeLiveModel.OnCreate()
	if page then
		if ParalifeLiveModel.main_ui_mode == "switchrole" then
			ParalifeLiveModel.CreateRoleView()
			ParalifeLiveModel.InitPlayerControl()
			
		elseif ParalifeLiveModel.main_ui_mode == "switch_expression" then
			ParalifeLiveModel.CreateFaceView()
		end
		ParalifeLiveModel.InitCameraButton()
    end
end

-------------------------
-- Camera Recorder 
-------------------------
local touch_time = 0
local IsRecord = false
local touch_timer = nil
function ParalifeLiveModel.InitCameraButton()
	local btnCamera = ParaUI.GetUIObject("ui_camera")
	if btnCamera and btnCamera:IsValid() then
		btnCamera.visible = false
		local platform = System.os.GetPlatform()
		if System.options.isDevMode or platform == "ios" then
		-- TODO: @pbb, iOS and android should be re-enabled when it is not buggy. 
		-- if System.options.isDevMode then
			btnCamera.visible = true
		end
		btnCamera:SetScript("onmouseup",function()
			_guihelper.SetUIColor(btnCamera,"#ffffff")
			btnCamera.scalingx = 1.0
			btnCamera.scalingy = 1.0
			ParalifeLiveModel.OnTouchCamera(false)
			IsRecord = false
		end)
		btnCamera:SetScript("onmousedown",function()
			btnCamera.scalingx = 1.25
			btnCamera.scalingy = 1.25
			_guihelper.SetUIColor(btnCamera,"#ffffff")
			if not IsRecord then
				ParalifeLiveModel.OnTouchCamera(true)
			end			
		end)
	end
end

function ParalifeLiveModel.HideCamera(bHide)
	local btnCamera = ParaUI.GetUIObject("ui_camera")
	if btnCamera then
		_guihelper.SetUIColor(btnCamera,"#ffffff")
		btnCamera.visible = not bHide
		btnCamera.scalingx = 1.0
		btnCamera.scalingy = 1.0
	end
end

function ParalifeLiveModel.SetCameraColor(colorStr)
	local btnCamera = ParaUI.GetUIObject("ui_camera")
	if btnCamera then
		_guihelper.SetUIColor(btnCamera,colorStr)
	end
end

function ParalifeLiveModel.SetRecord(isRecord)
	IsRecord = isRecord
	if not IsRecord then
		touch_time = 0
	end
end

function ParalifeLiveModel.OnTouchCamera(bTouch)
	if IsRecord and bTouch then
		return 
	end
	IsRecord = true
	touch_time = 0
	if not bTouch then
		if touch_timer then
			touch_timer:Change()
			touch_timer = nil
		end
		ParalifeLiveModel.SetCameraColor("#ffffff")
		return
	end
	local startR,startG,satrtB = 255,255,255
	local endR,endG,endB = 136,136,136
	local curR,curG,curB = startR,startG,satrtB
	local max_touch_time = 600
	local touch_delta = 10
	local color_dis = math.floor(startR - endR) / math.floor(max_touch_time / touch_delta)
	touch_timer = commonlib.Timer:new({callbackFunc = function(timer)
		touch_time = touch_time + touch_delta
		curR = curR - color_dis
		curG = curG - color_dis
		curB = curB - color_dis
		if curR >= endR then
			local color = Color.ConvertRGBAStringToColor(string.format("%d %d %d", curR , curG, curB))
			ParalifeLiveModel.SetCameraColor(color)
		end
		if touch_time > max_touch_time then
			ParalifeLiveModel.HideCamera(true)
			local RecordAnimation = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/RecordAnimation.lua") 
    		RecordAnimation.ShowView(function()
				Recording.ShowView()
				Recording.StartRecord()
			end)
			timer:Change()
		end
	end})
	touch_timer:Change(0, 10);
end

function ParalifeLiveModel.ShowShortScreen()
	local RecordFinish = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/RecordFinish.lua") 
    RecordFinish.ShowView()
end

-------------------------
-- Face View
-------------------------
function ParalifeLiveModel.CreateFaceView()
	local _parent = ParaUI.GetUIObject("paralife_expression")
	local lineNum = 11
	ParalifeLiveModel.face_objs = ParalifeLiveModel.face_objs or {}
	for k,v in pairs(ParalifeLiveModel.face_objs) do
		ParaUI.Destroy(v)
	end
	ParalifeLiveModel.face_objs = {}
	if _parent and _parent:IsValid() then
		local screen_width,screen_height = Screen:GetWidth(),Screen:GetHeight()
		screen_width = screen_width - 150
		local data_num = ParalifeLiveModel.face_data:getSize()
		local showNum = data_num <= lineNum and data_num or lineNum
		local start_face_pos_x = screen_width/2 - (showNum *100)/2 + 20

		local startIdx,endIdx = ParalifeLiveModel.face_data:getCurIdxes()
		for i=startIdx,endIdx do
			local face_data = ParalifeLiveModel.face_data:getDataByIdx(i)
			if face_data then
				local name = "main_face_parent"..i
				local _this = ParaUI.CreateUIObject("button", name, "_lt", start_face_pos_x + (i-startIdx) * 100, 20, 64, 64);
				_this.background = face_data.icon..";0 0 64 64"
				_guihelper.SetUIColor(_this, "255 255 255")
				_this.candrag = true;
				_this:SetScript("ondragbegin",function()
					
				end)
				_this:SetScript("ondragend",function()
					ParalifeLiveModel.DropFacialExpressionAtCursor(face_data)
				end)
				_parent:AddChild(_this)
				ParalifeLiveModel.face_objs[#ParalifeLiveModel.face_objs+1] = name
			end
		end 
	end
end

function ParalifeLiveModel.DropFacialExpressionAtCursor(data)
	local event = MouseEvent:init("mousePressEvent")
	local result, targetEntity = GameLogic.GetSceneContext():CheckMousePick(event);
	if not targetEntity and result and result.blockX then
		local entityBlock = EntityManager.GetBlockEntity(result.blockX, result.blockY, result.blockZ)
		if(entityBlock and entityBlock:isa(EntityManager.EntityBlockModel)) then
			targetEntity = entityBlock;
		end
	end
	local entity = (result and result.entity) or targetEntity
	if entity then
		if entity.item_id and entity.item_id == 10074 and entity:HasCustomGeosets()  then
			for skin in string.gmatch(data.skin,"([^;]+)") do
				entity:PutOnCustomCharItem(skin)
			end
		end
	end
end

-------------------------
-- Role View
-------------------------
function ParalifeLiveModel.CreateRoleView()
	local _parent = ParaUI.GetUIObject("paralife_role")
	local screen_width,screen_height = Screen:GetWidth(),Screen:GetHeight()
	local startx = screen_width/2 - 640
	local starty = screen_height - ParalifeLiveModel.GetRoleViewHeight() + 0
	local data_num = #(ParalifeLiveModel.role_data)
	local showNum = data_num <= ParalifeLiveModel.GetShowNum() and data_num or ParalifeLiveModel.GetShowNum()
	local cell_w,cell_h = ParalifeLiveModel.GetRoleViewWidth(), ParalifeLiveModel.GetRoleViewHeight()
	local _w,_h = 132,166 --实际容器大小
	if  _parent and _parent:IsValid() then
		for i=1,showNum do
			local _this = ParaUI.CreateUIObject("container", "main_user_player_parent"..i, "_lt", (i-1) * cell_w+(cell_w-_w)*0.5, (cell_h-_h)*1, _w,_h);
			_this.background = ""
			-- _guihelper.SetUIColor(_this, "#00ff00");
			_parent:AddChild(_this)
			ParalifeLiveModel.CreateCanvasNode(_this,i,_w,_h)
		end
	end

	local startParaX,startRoleY = 0,(cell_h-_h)
	local startmousex,startmousey
	local disx,disy = 0,0
	local touchItem,touchIndex = nil

	local function MoveFrom2Dto3D()
		ParalifeLiveModel.CreateEntity(touchIndex, ParalifeLiveModel.role_data[touchIndex])
		touchItem.visible = false
		touchItem,touchIndex = nil,nil;
	end
	_parent:SetScript("onmousedown",function()
		startmousex,startmousey = ParaUI.GetMousePosition();
		local item,index = ParalifeLiveModel.GetRoleItemByMouse()
		if item then 
			touchItem = item
			touchIndex = index
		else 
			touchItem,touchIndex = nil,nil;
		end
	end)
	_parent:SetScript("onmouseup",function()
		if startmousex==nil then
			return
		end
		local mouse_x, mouse_y = ParaUI.GetMousePosition();
		disx,disy = mouse_x - startmousex ,mouse_y - startmousey
		if data_num > showNum then
			if math.abs( disx ) > 100 then
				local moveDis = {x= (disx > 0 and screen_width or -screen_width),y=0,fillIndex=nil}
				ParalifeLiveModel.MoveAction(moveDis,0.2,function()
					local move_num = showNum
					if move_num > 0 then
						ParalifeLiveModel.MoveRoleData(move_num , disx < 0 and disx ~= 0 )
					end
				end)
			else
				_parent.x = 0
			end
		end
		if touchItem then
			touchItem.y = startRoleY
		end
		startmousex,startmousey = nil,nil
		touchItem,touchIndex = nil,nil;
	end)
	_parent:SetScript("onmousemove",function()
		local mouse_x, mouse_y = ParaUI.GetMousePosition();
		if startmousex==nil then 
			return
		end
		disx,disy = mouse_x - startmousex ,mouse_y - startmousey
		if touchItem then
			local mouse_x, mouse_y = ParaUI.GetMousePosition();
			if disy < 0 and mouse_y < starty+10  then
				MoveFrom2Dto3D()
			else
				if mouse_y >= starty then
					touchItem.y = startRoleY + disy
				end
			end
		end
		
		if data_num > showNum then
			_parent.x = startParaX + disx
		end
	end)
	_parent:SetScript("onmouseleave",function()
		if startmousey then 
			local mouse_x, mouse_y = ParaUI.GetMousePosition();
			disx,disy = mouse_x - startmousex ,mouse_y - startmousey
			if touchItem and disy<-10 and mouse_y < starty then
				MoveFrom2Dto3D()
			end
		end
	end)	
end

function ParalifeLiveModel.GetRoleItemByMouse()
	local _parent = ParaUI.GetUIObject("paralife_role")
	local mouse_x, mouse_y = ParaUI.GetMousePosition();
	local x = mouse_x - _parent.x
	local y = mouse_y - (Screen:GetHeight() - ParalifeLiveModel.GetRoleViewHeight())

	local index = math.floor(x / ParalifeLiveModel.GetRoleViewWidth()) + 1
	local item = ParaUI.GetUIObject("main_user_player_parent"..index)
	if item then 
		if x>item.x and x<item.x+item.width and y>item.y and y<item.y+item.height then 
			return item,index
		end
	end
	return nil
end

function ParalifeLiveModel.InitPlayerControl()
	local touchScreen = page:FindControl("paralife_touch_scene")
	if(touchScreen) then
		touchScreen:SetScript("onmousedown", function()
			-- shall we disable clip cursor to app's window?
			touchScreen:SetField("MouseCaptured", true);
			if not createdEntity then
				local event = MouseEvent:init("mousePressEvent")
				ParaLifeTouchController.handleMouseEvent(event);
				touchScreen.zorder = 10;
			end
		end);
		touchScreen:SetScript("onmouseup", function()
			touchScreen:SetField("MouseCaptured", false);
			if createdEntity then
				local screen_width,screen_height = Screen:GetWidth(),Screen:GetHeight()
				local starty = screen_height - ParalifeLiveModel.GetViewMargin()
				local mouse_x, mouse_y = ParaUI.GetMousePosition();
				if mouse_y > starty then --又给拖回来了
					createdEntity:SetDead(true)
					ParalifeLiveModel.RefreshPage()
				else
					createdEntity:GetItemClass():DropDraggingEntity(createdEntity)
					local index = createdEntity.remove_index
					if ParalifeLiveModel.main_ui_mode == "switchrole" then
						ParalifeLiveModel.RemoveRoleData(index)
					end
				end
				
				createdEntity = nil
			else
				local event = MouseEvent:init("mouseReleaseEvent")
				local capturedEntity = GameLogic.GetSceneContext():GetMouseCaptureEntity(event)
				ParaLifeTouchController.handleMouseEvent(event);
				if(capturedEntity and capturedEntity:isa(EntityManager.EntityLiveModel)) then
					ParalifeLiveModel.TryDropPlayerEntityToRoleDock(capturedEntity, event)
				end
			end
			touchScreen.zorder = -1;
		end);
		touchScreen:SetScript("onmousemove", function() 
			if createdEntity then
				createdEntity:GetItemClass():UpdateDraggingEntity(createdEntity)
				touchScreen.zorder = 10;
			else
				local event = MouseEvent:init("mouseMoveEvent")
				ParaLifeTouchController.handleMouseEvent(event);
			end
		end);
	end
end

function ParalifeLiveModel.TryDropPlayerEntityToRoleDock(draggingEntity, event)
	local mouse_x, mouse_y = event.x, event.y;
	local screen_width,screen_height = Screen:GetWidth(),Screen:GetHeight()
	local startx = screen_width/2 - 640
	local starty = screen_height - ParalifeLiveModel.GetViewMargin()
	if mouse_y > starty and ParalifeLiveModel.main_ui_mode == "switchrole" then
		if (draggingEntity and draggingEntity:isa(EntityManager.EntityLiveModel))  then --只能拖入活动模型
			ParalifeLiveModel.AddRoleData(draggingEntity,true,true) 
			draggingEntity:SetDead();
		end
	end
end

function ParalifeLiveModel.GetRoleViewHeight()
	return 200
end

function ParalifeLiveModel.GetRoleViewWidth()
	return 180
end

function ParalifeLiveModel.GetViewMargin()
	return 100
end

----IsActiveRendering 没有这个参数的话当前帧不会渲染这个角色
----IsInteractive 判断UI角色是否可以拖动旋转，是否可以监听mouseevent
function ParalifeLiveModel.CreateCanvasNode(parent,index,pWidth,pHeight)
	if parent and parent:IsValid() then
		local data = ParalifeLiveModel.role_data[index]
		local name = "livenode"..index
		local size,DefaultCameraObjectDist,LookAtHeight = 300,6,1.57
		local top = (pHeight-size)
		local y = 0
		if data.isNotHuman then
			size = math.max(pWidth,pHeight)
			DefaultCameraObjectDist = nil
			LookAtHeight = nil
			top = (pHeight-size)*0.5-10
		end
		local ctl = CommonCtrl.Canvas3D:new{
			name = name,
			alignment = "_lt",
			left = (pWidth-size)*0.5,top = top,
			width = size,height = size,
			background = "",
			parent = parent,
			IsActiveRendering = true, 
			miniscenegraphname = "create_role"..index,
			DefaultRotY = 0,
			RenderTargetSize = 512,
			IsInteractive = false,
			autoRotateSpeed = 0,
			DefaultCameraObjectDist =  DefaultCameraObjectDist,
			DefaultLiftupAngle =  0.25,
			LookAtHeight =  LookAtHeight,
			FrameMoveCallback = function()
				
			end,
		};
		local scaling = 1
		if data.isNotHuman then 
		end
		local params = {
			IsCharacter = true, 
			AssetFile = data.assetfile,
			x=0, 
			y=0, 
			z=0, 
			facing=1.57,
			-- scaling = data.scaling,
			Attribute = 128,
			name = "test_player"..index,
			CustomGeosets = data.skin
		};
		ctl:Show(true);
		ctl:ShowModel(params)
	end
end

---Role data================================================================================================
function ParalifeLiveModel.RemoveRoleData(index)
	local num = #ParalifeLiveModel.role_data
	for i=index,num do
		ParalifeLiveModel.role_data[i] = ParalifeLiveModel.role_data[i + 1]
	end
	ParalifeLiveModel.role_data[num] = nil
	ParalifeLiveModel.RefreshPage()
	local moveDis = {x= (-ParalifeLiveModel.GetRoleViewWidth()),y=0,fillIndex=index}
	ParalifeLiveModel.MoveAction(moveDis,0.1)
end

function ParalifeLiveModel.AddRoleData(entity,bRefresh,isInsert)
	if not entity then
		return 
	end

	local isHuman = entity:HasCustomGeosets()
	
	local xmlnode = entity:SaveToXMLNode()
	local curNum = #ParalifeLiveModel.role_data
	local objScale = entity:GetInnerObject():GetScale()
	local assetfile = entity.filename or default_model
	local skin = entity.skin or default_skin
	local scaling = entity.scaling or objScale
	local isNotHuman = nil
	if not isHuman then
		isNotHuman = true
		skin = nil
		assetfile = PlayerAssetFile:GetValidAssetByString(entity.filename)
	end
	local temp = {assetfile = assetfile,skin = skin,scaling = scaling or 1,xmlnode=xmlnode,isNotHuman=isNotHuman}
	local index = ParalifeLiveModel.GetIndexWithMouse()
	if curNum < ParalifeLiveModel.GetShowNum() then
		ParalifeLiveModel.role_data[curNum + 1] = temp
	else
		table.insert( ParalifeLiveModel.role_data, index ,temp )
		if bRefresh then 
			local moveDis = {x= (ParalifeLiveModel.GetRoleViewWidth()),y=0,fillIndex=index+1}
			ParalifeLiveModel.MoveAction(moveDis,0.1)
		end
	end
	
	if bRefresh then
		ParalifeLiveModel.RefreshPage()
	end
end

function ParalifeLiveModel.MoveRoleData(move_num,ismoveleft)
	if move_num < 0 then
		return 
	end
	local role_num = #ParalifeLiveModel.role_data
	local type = ismoveleft and -1 or 1
	commonlib.quickMoveArrayItemWithNum(ParalifeLiveModel.role_data,move_num*type)
	ParalifeLiveModel.RefreshPage()
end

local function tweenExec(dur,callback)
    local tick = 1/60
    local acc = 0;
    local schedulerId = commonlib.Timer:new({callbackFunc = function(timer)
        acc = acc + tick;
        local progress = acc/dur
        local finish = false
        if progress>=1 then
            finish = true
            acc = dur
			progress = 1
        end
        if finish then
            timer:Change()
        end
		callback(progress,finish)
    end})
    schedulerId:Change(0, tick *1000)
    return schedulerId
end

local _moveId = nil
function ParalifeLiveModel.MoveAction(movedis,time,callback_func)
	if not movedis then
		return 
	end
	local showNum = ParalifeLiveModel.GetShowNum()
	local moveX = movedis.x
	local startPosX,endPosX = {},{}
	local startIdx = 1
	if movedis.fillIndex then --补空位
		startIdx = movedis.fillIndex
	end
	for i=1,showNum do
		local target = ParaUI.GetUIObject("main_user_player_parent"..i)
		if movedis.fillIndex then --补空位
			endPosX[i] = target.x
			if i>= movedis.fillIndex then
				target.x = target.x - moveX
			end
		else
			endPosX[i] = target.x + moveX
		end
		startPosX[i] = target.x
	end

	if _moveId then 
		_moveId:Change()
	end
	_moveId = tweenExec(time,function(progress,isFinish)
		for i=startIdx,showNum do
			local target = ParaUI.GetUIObject("main_user_player_parent"..i)
			target.x = startPosX[i]+moveX*progress
		end
		if isFinish then
			if callback_func then 
				callback_func()
			end
			_moveId = nil
		end
	end)
end

function ParalifeLiveModel.CreateEntity(index,data) --创建livemodel
	local event = MouseEvent:init("mousePressEvent")
	local result, targetEntity = GameLogic.GetSceneContext():CheckMousePick(event);
	local bx,by,bz = BlockEngine:GetBlockIndexBySide(result.blockX,result.blockY,result.blockZ,result.side);
	local facing = Direction.GetFacingFromCamera()
	facing = Direction.NormalizeFacing(facing)
	local filename=data.assetfile or "character/CC/02human/CustomGeoset/actor.x"
	local entity = EntityManager.EntityLiveModel:Create({bx=bx,by=by + 1,bz=bz, item_id = block_types.names.LiveModel, facing=facing}, serverdata);
	entity:SetModelFile(filename)
	if not data.isNotHuman then 
		entity:SetSkin(data.skin)
	end
	entity:setScale(data.scaling)
	if (data.xmlnode and data.xmlnode.attr) then
		data.xmlnode.attr.name = nil;
		entity:LoadFromXMLNode(data.xmlnode)
	end
	entity:Refresh();
	entity:Attach();
	createdEntity = entity
	createdEntity.remove_index = index
	entity:GetItemClass():StartDraggingEntity(createdEntity)
	entity:GetItemClass():UpdateDraggingEntity(createdEntity)
end

function ParalifeLiveModel.GetSceneContext()
	if(not ParalifeLiveModel.sceneContext) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/AllContext.lua");
		local AllContext = commonlib.gettable("MyCompany.Aries.Game.AllContext");
		ParalifeLiveModel.sceneContext = AllContext:GetContext("roleplay");
	end
	return ParalifeLiveModel.sceneContext;
end

function ParalifeLiveModel.RefreshPage()
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
		local viewport = ViewportManager:GetSceneViewport();
		if viewport:GetMarginBottomHandler() == ParalifeLiveModel then
			viewport:SetMarginBottom(0);
			viewport:SetMarginBottomHandler(nil);
		end
    end
end

function ParalifeLiveModel.SwitchOperateButton(name)
	if not name or ParalifeLiveModel.main_ui_mode == name  then
		return
	end
	local viewport = ViewportManager:GetSceneViewport();
	if name == "switchrole"  then --or name=="switch_expression"
		if viewport:GetMarginBottomHandler() ~= ParalifeLiveModel then
			viewport:SetMarginBottom(math.floor(ParalifeLiveModel.GetViewMargin() * (Screen:GetUIScaling()[2]))); 
			viewport:SetMarginBottomHandler(ParalifeLiveModel);
		end
	elseif name== "switchmain" then
		if viewport:GetMarginBottomHandler() == ParalifeLiveModel then
			viewport:SetMarginBottom(0);
			viewport:SetMarginBottomHandler(nil);
		end
	elseif name== "next_page_expression" then --表情翻页
		name = "switch_expression"
		ParalifeLiveModel.face_data:getNextPage()
	end
	ParalifeLiveModel.main_ui_mode = name
	ParalifeLiveModel.RefreshPage()
end

function ParalifeLiveModel.OnExitWorld()
	ParalifeLiveModel.role_data = default_role_data
	ParalifeLiveModel.main_ui_mode = "switchmain"
	
	local viewport = ViewportManager:GetSceneViewport();
	if viewport:GetMarginBottomHandler() == ParalifeLiveModel then
		viewport:SetMarginBottom(0);
		viewport:SetMarginBottomHandler(nil);
	end
	ParalifeLiveModel.IsInit = nil
	ParalifeLiveModel.ClosePage()
end
