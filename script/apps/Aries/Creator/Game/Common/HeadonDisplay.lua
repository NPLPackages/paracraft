--[[
Title: Headon Display
Author(s): LiXizhi
Date: 2019/11/8
Desc: Create a headon display object
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/HeadonDisplay.lua");
local HeadonDisplay = commonlib.gettable("MyCompany.Aries.Game.Common.HeadonDisplay");
local gui = HeadonDisplay:new():Init(EntityManager.GetPlayer());
gui:Show({url=ParaXML.LuaXML_ParseString('<pe:mcml><div style="background-color:red">hello world</div></pe:mcml>')})
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/PainterContext.lua");
NPL.load("(gl)script/ide/System/Windows/Window.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local PainterContext = commonlib.gettable("System.Core.PainterContext");
local HeadonDisplay = commonlib.inherit(commonlib.gettable("System.Windows.Window"), commonlib.gettable("MyCompany.Aries.Game.Common.HeadonDisplay"));
HeadonDisplay:Property({"bIsBillBoard", false, "IsBillBoarded", "SetBillBoarded", auto=true});

local template_name = "HeadonDisplay_mcmlv2"
local template_3d_name = "HeadonDisplay_3d_mcmlv2"
local next_id = 0;

function HeadonDisplay:ctor()
	next_id = next_id + 1
	self.id = tostring(next_id);
end

local all_instances = {};
local DummyObject = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"))
function DummyObject:Init(obj)
	all_instances[obj.id] = obj;
	self.obj = obj;
	return self;
end
function DummyObject:Destroy()
	all_instances[self.obj.id] = nil
	self.obj:Destroy();
	local parent = self:GetParent();
	if(parent) then
		local obj = parent:GetInnerObject()
		if(obj) then
			obj:ShowHeadOnDisplay(false,0);
		end
	end
	return DummyObject._super.Destroy(self)
end


-- @param parentEntity: should be an entity
function HeadonDisplay:Init(parentEntity)
	if(parentEntity.headonEntity) then
		parentEntity.headonEntity:Destroy();
	end
	self.painter = System.Core.PainterContext:new();

	local dummyObj = DummyObject:new():Init(self)
	dummyObj:SetParent(parentEntity)
	self.dummyObj = dummyObj;
	parentEntity.headonEntity = dummyObj;
	return self;
end

function HeadonDisplay:CloseWindow()
	HeadonDisplay._super.CloseWindow(self, true);
	if(self.dummyObj) then
		self.dummyObj:Destroy()
	end
end

function HeadonDisplay:Is3DUI()
	return self.is3D;
end

function HeadonDisplay:GetParentEntity()
	return self.dummyObj and self.dummyObj:GetParent();
end

function HeadonDisplay:SetHeadOnZEnabled(bEnabled)
	local parentEntity = self:GetParentEntity();
	if(parentEntity) then
		local obj = parentEntity:GetInnerObject()
		if(obj) then
			obj:SetField("HeadOnZEnabled", bEnabled==true);
		end
	end
end

function HeadonDisplay:SetHeadOn3DScalingEnabled(bEnabled)
	local parentEntity = self:GetParentEntity();
	if(parentEntity) then
		local obj = parentEntity:GetInnerObject()
		if(obj) then
			obj:SetField("HeadOn3DScalingEnabled", bEnabled==true);
		end
	end
end


-- @param params: {url="", alignment, x,y,width, height, allowDrag,zorder, enable_esc_key, DestroyOnClose, parent, pageGlobalTable, 
--	is3D, offset, facing}
-- pageGlobalTable can be a custom page environment table, if nil, it will be the global _G. 
-- is3D£º if true, it is 3d UI, default is false
function HeadonDisplay:ShowWithParams(params)
	self.name = params.name;
	self.pageGlobalTable = params.pageGlobalTable;
	self.is3D = params.is3D
	
	local parentEntity = self:GetParentEntity();
	if(not parentEntity) then
		return
	end
	local obj = parentEntity:GetInnerObject()
	if(obj) then
		obj:ShowHeadOnDisplay(true,0);
		if(self:Is3DUI())  then
			HeadonDisplay.InitHeadonTemplate3D();
			obj:SetHeadOnUITemplateName(template_3d_name,0);
			local offset = params.offset;
			if(offset) then
				obj:SetHeadOnOffset(offset.x or 0, offset.y or 0, offset.z or 0, 0);
			end
			-- setting 3d facing will automatically make the text control to render in 3d. 
			obj:SetField("HeadOn3DFacing", params.facing or 0);
		else
			HeadonDisplay.InitHeadonTemplate();
			obj:SetHeadOnUITemplateName(template_name,0);
		end
		obj:SetHeadOnText(self.id, 0);
	end

	-- load component if url has changed
	if(self.url ~= params.url) then
		self.url = params.url;
		if(params.url) then
			self:LoadComponent(params.url);
			self:urlChanged(self.url);
		end
	end
	if(not self:isCreated()) then
		self:create_sys();
	end
	local bShow = true;
	if(bShow) then
		local nativeWnd = self:GetNativeWindow();
		if(nativeWnd) then
			-- reposition/attach to parent
			local left, top, width, height, alignment = params.left, params.top, params.width, params.height, params.alignment or "_lt";
			self:SetAlignment(alignment);
			local x, y, width, height = nativeWnd:GetAbsPosition();
			self.screen_x, self.screen_y = 0, 0;
			-- update geometry
			self:setGeometry(x, y, width, height);
		end
	end
	self:SetDestroyOnClose(params.DestroyOnClose)
	-- show the window
	self:show();
	if(self:Is3DUI())  then
		if(HeadonDisplay.ui_3d_obj) then
			HeadonDisplay.ui_3d_obj.visible = false;
		end
	else
		if(HeadonDisplay.ui_obj) then
			HeadonDisplay.ui_obj.visible = false;
		end
	end
end


function HeadonDisplay.InitHeadonTemplate()
	if(HeadonDisplay.ui_obj and HeadonDisplay.ui_obj:IsValid()) then
		return HeadonDisplay.ui_obj
	end
	local _this = ParaUI.CreateUIObject("button", template_name, "_lt",0,0,100,30);
	HeadonDisplay.ui_obj = _this;
	_this.visible = false;
	_this.enabled = false;
	_this:SetField("OwnerDraw", true); -- enable owner draw paint event
	_this:AttachToRoot();
	_this:SetScript("ondraw", HeadonDisplay.onDraw);
	return HeadonDisplay.ui_obj; 
end

function HeadonDisplay.InitHeadonTemplate3D()
	if(HeadonDisplay.ui_3d_obj and HeadonDisplay.ui_3d_obj:IsValid()) then
		return HeadonDisplay.ui_3d_obj
	end
	local _this = ParaUI.CreateUIObject("button", template_3d_name, "_lt",0,0,100,30);
	HeadonDisplay.ui_3d_obj = _this;
	_this.visible = false;
	_this.enabled = false;
	_this:SetField("OwnerDraw", true); -- enable owner draw paint event
	_this:AttachToRoot();
	_this:SetScript("ondraw", HeadonDisplay.onDraw);
	return HeadonDisplay.ui_3d_obj; 
end

-- virtual: if this element is a native window, destroy it. 
function HeadonDisplay:destroy_sys()
end

-- bind to native window.
function HeadonDisplay:create_sys(native_window, initializeWindow, destroyOldWindow)
	if(self:testAttribute("WA_WState_Created")) then
		LOG.std(nil, "warn", "Window", "window already created before");
		return;
	end
	if(not native_window) then
		if(self:Is3DUI()) then
			native_window = HeadonDisplay.InitHeadonTemplate3D()
		else
			native_window = HeadonDisplay.InitHeadonTemplate()
		end
	end

	-- painting context
	self.painterContext = System.Core.PainterContext:new():init(self);
	
	local _this = native_window;
	self.native_ui_obj = _this;
	self:setAttribute("WA_WState_Created");     
	self:UpdateGeometry_Sys();
	if(self.bSelfPaint~=nil) then
		self:EnableSelfPaint(self.bSelfPaint);
	end
	if(not self.AutoClearBackground) then
		self:SetAutoClearBackground(self.AutoClearBackground);
	end

	-- redirect events from native ParaUI object to this object. 
	_this:SetScript("ondraw", HeadonDisplay.onDraw);
end

function HeadonDisplay.onDraw(obj)
	local id = obj.text;
	local self = all_instances[id];
	if(self) then
		if(self:IsBillBoarded()) then
			self.painterContext:LoadBillboardMatrix();
		end
		self:handleRender()
	end
end

-- virtual function
function HeadonDisplay:FilterImage(filename)
	if(not filename:match("^https?:") and not filename:match("^%w:")) then
		local filename_, params = filename:match("^([^;#:]+)(.*)$");
		if(filename_) then
			local filepath = Files.GetFilePath(filename_);
			if(filepath) then
				 if(filepath~=filename_) then
					filename = filepath..(params or "");
				 end
			else
				-- file not exist, return nil
				LOG.std(nil, "warn", "HeadonDisplay", "image file not exist %s", filename);
				return;
			end
		end
	end
	return filename;
end