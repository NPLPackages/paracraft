--[[
Title: EntityOverlay actor
Author(s): LiXizhi
Date: 2016/1/3
Desc: for recording and playing back of 3d text and images
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/ActorOverlay.lua");
local ActorOverlay = commonlib.gettable("MyCompany.Aries.Game.Movie.ActorOverlay");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/Actor.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CmdParser.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemStack.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
NPL.load("(gl)script/ide/math/ShapeBox.lua");
NPL.load("(gl)script/ide/System/Scene/Overlays/ShapesDrawer.lua");
NPL.load("(gl)script/ide/System/Core/Color.lua");
NPL.load("(gl)script/ide/System/Scene/Cameras/Cameras.lua");
NPL.load("(gl)script/ide/math/Matrix4.lua");
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
local Screen = commonlib.gettable("System.Windows.Screen");
local Matrix4 = commonlib.gettable("mathlib.Matrix4");
local vector3d = commonlib.gettable("mathlib.vector3d");
local Cameras = commonlib.gettable("System.Scene.Cameras");
local Color = commonlib.gettable("System.Core.Color");
local ShapesDrawer = commonlib.gettable("System.Scene.Overlays.ShapesDrawer");
local ShapeBox = commonlib.gettable("mathlib.ShapeBox");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
local MultiAnimBlock = commonlib.gettable("MyCompany.Aries.Game.Common.MultiAnimBlock");
local ActorBlock = commonlib.gettable("MyCompany.Aries.Game.Movie.ActorBlock");
local EntityOverlay = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityOverlay")
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Actor = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Movie.Actor"), commonlib.gettable("MyCompany.Aries.Game.Movie.ActorOverlay"));

Actor:Property({"Font", "System;14;norm", auto=true})
Actor:Property({"text", nil, "GetText", "SetText", auto=true})
-- line height in pixels
Actor:Property({"lineheight", 16,})
Actor:Property({"enablePicking", true, "IsPickingEnabled", "EnablePicking", auto=true})

Actor:Property({"bounding_radius", 0, "GetBoundingRadius", "SetBoundingRadius", auto=true})
Actor:Property({"m_aabb", nil,})

Actor.class_name = "ActorOverlay";

-- keyframes that can be edited from UI keyframe. 
local selectable_var_list = {
	"text",
	"code",
	"---", -- separator
	"pos", -- multiple of x,y,z
	"facing", 
	"rot", -- multiple of "roll", "pitch", "facing"
	"scaling", 
	"---", -- separator
 	"screen_pos", -- multiple of ui_x, ui_y
	"ui_align", -- "center", "top", "bottom"
	"ui_zorder", -- 2d ui zorder
	"---", -- separator
	"opacity",
	"color",
};


function Actor:ctor()
	self.codeItem = ItemStack:new():Init(block_types.names.Code, 1);
	self.m_aabb = ShapeBox:new():SetPointBox(0,0,0);
end

function Actor:DeleteThisActor()
	self:OnRemove();
	self:Destroy();
end

function Actor:GetMultiVariable()
	local var = self:GetCustomVariable("multi_variable");
	if(var) then
		return var;
	else
		var = MultiAnimBlock:new();
		var:AddVariable(self:GetVariable("x"));
		var:AddVariable(self:GetVariable("y"));
		var:AddVariable(self:GetVariable("z"));
		var:AddVariable(self:GetVariable("facing")); -- facing is yaw, actually
		var:AddVariable(self:GetVariable("pitch"));
		var:AddVariable(self:GetVariable("roll"));
		var:AddVariable(self:GetVariable("scaling"));
		self:SetCustomVariable("multi_variable", var);
		return var;
	end
end

-- get position multi variable
function Actor:GetPosVariable()
	local var = self:GetCustomVariable("pos_variable");
	if(var) then
		return var;
	else
		var = MultiAnimBlock:new({name="pos"});
		var:AddVariable(self:GetVariable("x"));
		var:AddVariable(self:GetVariable("y"));
		var:AddVariable(self:GetVariable("z"));
		var.getValue = function(var, anim, time)
			if(self:HasScreenPos()) then
				local x, y, z = self:GetPosition();
				var.screenWorldPos = var.screenWorldPos or {};
				var.screenWorldPos[1], var.screenWorldPos[2], var.screenWorldPos[3] = x or 0, y or 0, z or 0;
				return var.screenWorldPos;
			else
				return MultiAnimBlock.getValue(var, anim, time);
			end
		end

		self:SetCustomVariable("pos_variable", var);
		return var;
	end
end

-- get rotate multi variable
function Actor:GetRotateVariable()
	local var = self:GetCustomVariable("rot_variable");
	if(var) then
		return var;
	else
		var = MultiAnimBlock:new({name="rot"});
		var:AddVariable(self:GetVariable("roll"));
		var:AddVariable(self:GetVariable("pitch"));
		var:AddVariable(self:GetVariable("facing"));
		self:SetCustomVariable("rot_variable", var);
		return var;
	end
end

-- get position multi variable
function Actor:GetScreenPosVariable()
	local var = self:GetCustomVariable("screen_pos_variable");
	if(var) then
		return var;
	else
		var = MultiAnimBlock:new({name="screen_pos"});
		var:AddVariable(self:GetVariable("ui_x"));
		var:AddVariable(self:GetVariable("ui_y"));
		self:SetCustomVariable("screen_pos_variable", var);
		return var;
	end
end

function Actor:Init(itemStack, movieclipEntity)
	-- base class must be called last, so that child actors have created their own variables on itemStack. 
	if(not Actor._super.Init(self, itemStack, movieclipEntity)) then
		return;
	end

	local timeseries = self.TimeSeries;
	timeseries:CreateVariableIfNotExist("x", "Linear");
	timeseries:CreateVariableIfNotExist("y", "Linear");
	timeseries:CreateVariableIfNotExist("z", "Linear");
	timeseries:CreateVariableIfNotExist("ui_x", "Linear");
	timeseries:CreateVariableIfNotExist("ui_y", "Linear");
	timeseries:CreateVariableIfNotExist("ui_zorder", "Linear");
	timeseries:CreateVariableIfNotExist("ui_align", "Discrete");
	timeseries:CreateVariableIfNotExist("facing", "LinearAngle");
	timeseries:CreateVariableIfNotExist("pitch", "LinearAngle");
	timeseries:CreateVariableIfNotExist("roll", "LinearAngle");
	timeseries:CreateVariableIfNotExist("scaling", "Linear");
	timeseries:CreateVariableIfNotExist("opacity", "Linear");
	timeseries:CreateVariableIfNotExist("code", "Discrete");
	timeseries:CreateVariableIfNotExist("text", "Discrete");
	timeseries:CreateVariableIfNotExist("color", "Discrete");
	
	
	self:AddValue("position", self.GetPosVariable);
	self:AddValue("screen_pos", self.GetScreenPosVariable);

	-- get initial position from itemStack, if not exist, we will use movie clip entity's block position. 
	local movieClip = self:GetMovieClip();
	if(movieClip) then
		local x = self:GetValue("x", 0);
		local y = self:GetValue("y", 0);
		local z = self:GetValue("z", 0);
		if(not x or not y or not z) then
			x, y, z = movieClip:GetOrigin();
			y = y + BlockEngine.blocksize;
			self:AddKey("x", 0, x);
			self:AddKey("y", 0, y);
			self:AddKey("z", 0, z);
		end

		self.entity = EntityOverlay:Create({x=x,y=y,z=z,});
		if(self.entity) then
			self.entity:SetActor(self);
			self.entity:SetPersistent(false);
			self.entity:Attach();
			-- make it very big at first, so that it always get rendered, and we will update aabb at each render step.
			self.entity:SetBoundingRadius(100);
			self.entity.DoPaint = function(entity, painter)
				self:DoRender(painter);
			end
		end
		return self;
	end
end

-- @return nil or a table of variable list. 
function Actor:GetEditableVariableList()
	return selectable_var_list;
end

-- @param selected_index: if nil,  default to current index
-- @return var
function Actor:GetEditableVariable(selected_index)
	selected_index = selected_index or self:GetCurrentEditVariableIndex();
	
	local name = selectable_var_list[selected_index];
	local var;
	if(name == "pos") then
		var = self:GetPosVariable();
	elseif(name == "rot") then
		var = self:GetRotateVariable();
	elseif(name == "screen_pos") then
		var = self:GetScreenPosVariable();
	else
		var = self.TimeSeries:GetVariable(name);
	end
	return var;
end

function Actor:CreateKeyFromUI(keyname, callbackFunc)
	local curTime = self:GetTime();
	local h,m,s = commonlib.timehelp.SecondsToHMS(curTime/1000);
	local strTime = string.format("%.2d:%.2d", m,math.floor(s));
	local old_value = self:GetValue(keyname, curTime);

	if(keyname == "scaling") then
		local title = format(L"起始时间%s, 请输入放大系数(默认1)", strTime);

		-- TODO: use a dedicated UI 
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
		local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
		EnterTextDialog.ShowPage(title, function(result)
			result = tonumber(result);
			if(result) then
				self:AddKeyFrameByName(keyname, nil, result);
				self:FrameMovePlaying(0);
				if(callbackFunc) then
					callbackFunc(true);
				end
			end
		end,old_value)
	elseif(keyname == "opacity") then
		local title = format(L"起始时间%s, 请输入透明度[0,1](大于1不透明)", strTime);

		-- TODO: use a dedicated UI 
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
		local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
		EnterTextDialog.ShowPage(title, function(result)
			result = tonumber(result);
			if(result and result>=0) then
				self:AddKeyFrameByName(keyname, nil, result);
				self:FrameMovePlaying(0);
				if(callbackFunc) then
					callbackFunc(true);
				end
			end
		end,old_value)
	elseif(keyname == "text") then
		local title = format(L"起始时间%s, 请输入文字:", strTime);
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
		local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
		EnterTextDialog.ShowPage(title, function(result)
			if(result) then
				self:AddKeyFrameByName(keyname, nil, result);
				self:FrameMovePlaying(0);
				if(callbackFunc) then
					callbackFunc(true);
				end
			end
		end,old_value, true);

	elseif(keyname == "code") then
		local title = format(L"起始时间%s, 请输入绘图代码. 例如:", strTime).."<br/>"..[[
text("hello"); text("line2",0,16);<br/>
image("1.png", 300, 200);<br/>
rect(-10,-10,250,64,"1.png;0 0 32 32:8 8 8 8");<br/>
color("#ff0000"); font(14);<br/>
]];
		
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
		local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
		EnterTextDialog.ShowPage(title, function(result)
			if(result) then
				self:AddKeyFrameByName(keyname, nil, result);
				self:FrameMovePlaying(0);
				if(callbackFunc) then
					callbackFunc(true);
				end
			end
		end,old_value, true);

	elseif(keyname == "facing") then
		local title;
		if(keyname == "facing") then
			title = format(L"起始时间%s, 请输入转身的角度".."[-180, 180]", strTime);
		end

		old_value = (tonumber(old_value) or 0) / math.pi * 180
		-- TODO: use a dedicated UI 
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
		local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
		EnterTextDialog.ShowPage(title, function(result)
			result = tonumber(result);
			if(result) then
				result = result / 180 * math.pi;
				self:AddKeyFrameByName(keyname, nil, result);
				self:FrameMovePlaying(0);
				if(callbackFunc) then
					callbackFunc(true);
				end
			end
		end, old_value)
	elseif(keyname == "color") then
		local title = format(L"起始时间%s, 请输入颜色RGB. 例如:#ffffff", strTime);
		
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
		local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
		EnterTextDialog.ShowPage(title, function(result)
			if(result and result~="" and result:match("^#[%d%w]+$")) then
				self:AddKeyFrameByName(keyname, nil, result);
				self:FrameMovePlaying(0);
				if(callbackFunc) then
					callbackFunc(true);
				end
			end
		end,old_value)
	elseif(keyname == "rot") then
		local title = format(L"起始时间%s, 请输入roll, pitch, yaw [-180, 180]<br/>", strTime);
		old_value = string.format("%f, %f, %f", (self:GetValue("roll", curTime) or 0) / math.pi * 180,
			(self:GetValue("pitch", curTime) or 0) / math.pi * 180,
			(self:GetValue("facing", curTime) or 0) / math.pi * 180);
		-- TODO: use a dedicated UI 
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
		local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
		EnterTextDialog.ShowPage(title, function(result)
			if(result and result~="") then
				local vars = CmdParser.ParseNumberList(result, nil, "|,%s");
				if(result and vars[1] and vars[2] and vars[3]) then
					self:BeginUpdate();
					self:AddKeyFrameByName("roll", nil, vars[1] / 180 * math.pi);
					self:AddKeyFrameByName("pitch", nil, vars[2] / 180 * math.pi);
					self:AddKeyFrameByName("facing", nil, vars[3] / 180 * math.pi);
					self:EndUpdate();
					self:FrameMovePlaying(0);
					if(callbackFunc) then
						callbackFunc(true);
					end
				end
			end
		end,old_value)
	elseif(keyname == "pos") then
		local title = format(L"起始时间%s, 请输入位置x,y,z:", strTime);
		local bx, by, bz = self:GetValue("x", curTime),self:GetValue("y", curTime), self:GetValue("z", curTime);
		if(not bx or not by or not bz) then
			local entity = self:GetEntity() or EntityManager.GetPlayer();
			bx, by, bz = entity:GetPosition();
		end
		bx, by, bz = BlockEngine:block_float(bx, by, bz)
		bx = bx - 0.5;
		bz = bz - 0.5;
		old_value = string.format("%f, %f, %f", bx, by, bz);

		-- TODO: use a dedicated UI 
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
		local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
		EnterTextDialog.ShowPage(title, function(result)
			if(result and result~="") then
				local vars = CmdParser.ParseNumberList(result, nil, "|,%s");
				if(result and vars[1] and vars[2] and vars[3]) then
					local x, y, z = BlockEngine:real_bottom(vars[1], vars[2], vars[3])
					self:BeginUpdate();
					self:AddKeyFrameByName("x", nil, x);
					self:AddKeyFrameByName("y", nil, y);
					self:AddKeyFrameByName("z", nil, z);
					self:EndUpdate();
					self:FrameMovePlaying(0);
					if(callbackFunc) then
						callbackFunc(true);
					end
				end
			end
		end, old_value)
	elseif(keyname == "ui_align") then
		local title = format(L"起始时间%s, 请输入UI对齐方式", strTime);
		title = title.."<br/>center|top|bottom";
		old_value = self:GetValue("ui_align", curTime) or "center";

		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
		local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
		EnterTextDialog.ShowPage(title, function(result)
			if(result and result~="") then
				local align = result:match("%w+");
				if(align == "center" or align == "top"  or align == "bottom") then
					self:BeginUpdate();
					self:AddKeyFrameByName("ui_align", nil, align);
					self:EndUpdate();
					self:FrameMovePlaying(0);
					if(callbackFunc) then
						callbackFunc(true);
					end
				end
			end
		end, old_value)
	elseif(keyname == "ui_zorder") then
		local title = format(L"起始时间%s, 请输入UI Z排序", strTime);
		title = title.."<br/>0-1000";
		old_value = self:GetValue("ui_zorder", curTime) or 0;

		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
		local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
		EnterTextDialog.ShowPage(title, function(result)
			if(result) then
				local zorder = result:match("%-?%d+");
				if(zorder) then
					zorder = tonumber(zorder);
					self:BeginUpdate();
					self:AddKeyFrameByName("ui_zorder", nil, zorder);
					self:EndUpdate();
					self:FrameMovePlaying(0);
					if(callbackFunc) then
						callbackFunc(true);
					end
				end
			end
		end, old_value)
	elseif(keyname == "screen_pos") then
		local title = format(L"起始时间%s, 请输入位置x,y", strTime);
		title = title.."<br/>x=[-500,500],y=[-500,500]";
		old_value = string.format("%d, %d", self:GetValue("ui_x", curTime) or 0,self:GetValue("ui_y", curTime) or 0);

		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
		local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
		EnterTextDialog.ShowPage(title, function(result)
			if(result and result~="") then
				local vars = CmdParser.ParseNumberList(result, nil, "|,%s");
				if(result and vars[1] and vars[2]) then
					self:BeginUpdate();
					self:AddKeyFrameByName("ui_x", nil, vars[1]);
					self:AddKeyFrameByName("ui_y", nil, vars[2]);
					self:EndUpdate();
					self:FrameMovePlaying(0);
					if(callbackFunc) then
						callbackFunc(true);
					end
				end
			end
		end, old_value)
	end
end


function Actor:FrameMoveRecording(deltaTime)
	local curTime = self:GetTime();
	local entity = self.entity;
	if(not entity or not curTime) then
		return
	end
	entity:UpdatePosition();
	local x,y,z = entity:GetPosition();
	
	self:BeginUpdate();

	self:AutoAddKey("x", curTime, x);
	self:AutoAddKey("y", curTime, y);
	self:AutoAddKey("z", curTime, z);

	self:EndUpdate();
end

-- absoleted function, logics is moved to EntityOverlay with a faster implementation.
function Actor:ScreenToWorldPosition(ui_x, ui_y)
	ui_x = ui_x or 0;
	ui_y = ui_y or 0;
	
	local matView = Cameras:GetCurrent():GetViewMatrix();
	local matInverseView = matView:inverse();

	local viewport = ViewportManager:GetSceneViewport();
	local screenWidth, screenHeight = Screen:GetWidth()-viewport:GetMarginRight(), Screen:GetHeight() - viewport:GetMarginBottom();
	
	-- x range is in [-500, 500] pixels
	local screenHalfWidth = 500;
	local aspect = Cameras:GetCurrent():GetAspectRatio();
	local ui_z = screenHalfWidth / aspect / math.tan(Cameras:GetCurrent():GetFieldOfView()*0.5);

	local vScreen = mathlib.vector3d:new(ui_x/100, ui_y/100, ui_z/100);
	local vWorld = vScreen * matInverseView + Cameras:GetCurrent():GetRenderOrigin();

	-- solving: V*M(-90)*M(rpy)*M(view) = V*M(E)
	-- M(rpy) = M(90)*M(InverseView)
	local matRollPitchYaw = Matrix4.rotationY(90)*matInverseView;
	
	local quat = mathlib.Quaternion:new();
	quat:FromRotationMatrix(matRollPitchYaw);
	local roll, pitch, yaw = quat:ToEulerAnglesSequence("zxy");
	return vWorld[1], vWorld[2], vWorld[3], roll, pitch, yaw;
end

function Actor:HasScreenPos()
	local ui_x = self:GetValue("ui_x", 0);
	local ui_y = self:GetValue("ui_y", 0);
	return ui_x or ui_y;
end


function Actor:ComputeRoll(curTime)
	local entity = self.entity;
	if(entity and entity:IsScreenMode())  then
		return (self:GetValue("roll", curTime) or 0) + entity:GetRoll();	
	else
		return self:GetValue("roll", curTime);	
	end
end

function Actor:ComputeColor(curTime)
	return self:GetValue("color", curTime);
end

function Actor:ComputeText(curTime)
	return self:GetValue("text", curTime);
end

function Actor:ComputeRenderCode(curTime)
	return self:GetValue("code", curTime);
end

-- set rendering code
function Actor:SetRenderCode(code)
	self.codeItem:SetCode(code);
end

function Actor:FrameMovePlaying(deltaTime)
	local curTime = self:GetTime();
	local entity = self.entity;
	if(not entity or not curTime) then
		return
	end
	-- allow adding keyframe while playing during the last segment. 
	local allow_user_control = self:IsAllowUserControl() and
		((self:GetMultiVariable():GetLastTime()+1) <= curTime);

	local new_x, new_y, new_z, yaw, roll, pitch = self:ComputePosAndRotation(curTime);
	
	local ui_x = self:GetValue("ui_x", curTime);
	local ui_y = self:GetValue("ui_y", curTime);
	local ui_align = self:GetValue("ui_align", curTime);

	local scaling, opacity, color;
	
	scaling = self:ComputeScaling(curTime);
	opacity = self:GetValue("opacity", curTime);
	color = self:ComputeColor(curTime);

	if(ui_x or ui_y) then
		if(ui_align) then
			entity:SetAlignment(ui_align);
		end			

		entity:SetScreenPos(ui_x or 0, ui_y or 0);
		entity:SetScreenMode(true);

		local ui_zorder = self:GetValue("ui_zorder", curTime);
		if(ui_zorder) then
			entity:SetZOrder(ui_zorder);
		end
	else
		entity:SetScreenMode(false);

		if(new_x) then
			entity:SetPosition(new_x, new_y, new_z);		
		else
			local movieClip = self:GetMovieClip();
			if(movieClip) then
				new_x, new_y, new_z = movieClip:GetOrigin();
				new_y = new_y + BlockEngine.blocksize;
				entity:SetPosition(new_x, new_y, new_z);
			end
		end
	end

	self:SetText(self:ComputeText(curTime));
	entity:SetFacing(yaw or 0);
	entity:SetScaling(scaling or 1);
	entity:SetPitch(pitch or 0);
	entity:SetRoll(roll or 0);
	entity:SetOpacity(opacity or 1);
	
	entity:SetColor(color or "#ffffff");
	-- set render code
	self:SetRenderCode(self:ComputeRenderCode(curTime))
end

-- example codes:
-- image("1.png", 300,200)
-- color("#ff0000")
-- text("hello", 0, 0)
-- rect(-10,-10, 250,64, "1.png;0 0 32 32:8 8 8 8")
function Actor:CheckInstallCodeEnv(painter, isPickingPass)
	local env = self.codeItem:GetScriptScope();
	env.painter = painter;
	env.isPickingPass = isPickingPass;

	if(not env.text) then

		-- draw text
		-- @param text: text to render with current font 
		-- @param x,y: default to 0,0
		-- @param width, height: can be nil, unless you want to center the text
		-- @param alignment: only used when width is not nil
		env.text = function(text, x, y, width, height, alignment)
			if(text and text~="" ) then
				x = x or 0;
				y = y or 0;
									
				if(not env.isPickingPass) then
					self:ExtendAABB(x, y);
					if(not width or not height) then
						for line in text:gmatch("[^\n]+") do
							env.painter:DrawText(x, y, line);
							y = y + self.lineheight;
							self:ExtendAABB(x + _guihelper.GetTextWidth(line, self:GetFont()), y);
						end
					else
						alignment = alignment or 0x00000105; 
						env.painter:DrawText(x, y, width, height, text, alignment);
					end
				else
					if(not width) then
						width, height = 0,0;
						for line in text:gmatch("[^\n]+") do
							height = height + self.lineheight;
							width = math.max(width, _guihelper.GetTextWidth(line, self:GetFont()))
						end
					end
					if(width~=0 and height~=0) then
						env.painter:DrawRect(x,y, width, height);
					end
				end
			end
		end

		-- draw a rectangle with texture filename 
		-- @param filename: if nil, it will render with current pen color. 
		env.rect = function(x, y, width, height, filename)
			if(x and y and width and height) then
				if(not env.isPickingPass) then
					if(filename and filename~="") then
						local filepath, params = filename:match("^([^:;]+)(.*)$");
						-- repeated calls are cached
						filename = Files.FindFile(filepath);
						if(params and params~="") then
							filename = filename..params;
						end
					end
					self:ExtendAABB(x, y);
					self:ExtendAABB(x+width, y+height);
					env.painter:DrawRectTexture(x, y, width, height, filename);
				else
					env.painter:DrawRect(x,y, width, height);
				end
			end
		end

		-- set pen color
		-- @param color: such as "#ff0000"
		env.color = function(color)
			if(not env.isPickingPass) then
				env.painter:SetPen(color);
			end
		end

		-- set font 
		-- @param font: font_size
		-- or {family="System", size=10, bold=true}
		-- or it can be string "System;14;" or "System;14;bold"
		env.font = function(font)
			if(not env.isPickingPass) then
				if(type(font) == "number") then
					font = "System;"..font;
				end
				env.painter:SetFont(font);
			end
		end

		-- draw image
		-- @param filename: file relative to current world 
		-- @param width, height: default to image size
		-- @param x, y: default to 0,0
		env.image = function(filename, width, height, x, y)
			if(filename and filename~="") then
				-- repeated calls are cached
				filename = Files.FindFile(filename);
				if(filename) then
					if(not width or not height) then
						local texture = ParaAsset.LoadTexture("", filename, 1);
						
						-- fix display bug under opengl
						local function hackLength(pLen)
							if not pLen then
								return;
							end
														
							NPL.load("(gl)script/ide/math/bit.lua");
							local rshift = mathlib.bit.rshift;
							local bor = mathlib.bit.bor;
							local band = mathlib.bit.band;
							
							local ret = pLen;

							-- if power of 2
							if((ret > 0) and (band(ret, (ret-1)) == 0)) then
								return ret;
							end							
							
							ret = ret - 1;
							
							ret = bor(ret, rshift(ret, 1));
							ret = bor(ret, rshift(ret, 2));
							ret = bor(ret, rshift(ret, 4));
							ret = bor(ret, rshift(ret, 8));
							ret = bor(ret, rshift(ret, 16));
							
							ret = ret + 1;
							
							return ret;
						end
						width = hackLength(width or texture:GetWidth());
						height = hackLength(height or texture:GetHeight());
					end
					x,y,width, height = x or 0, y or 0, width or 64, height or 64;

					if(not env.isPickingPass) then
						self:ExtendAABB(x, y);
						self:ExtendAABB(x+width, y+height);
						env.painter:DrawRectTexture(x, y, width, height, filename);
					else
						env.painter:DrawRect(x,y, width, height);
					end
				end
			end
		end
	end
	return env;
end

-- between BeginRender() and EndRender(), the bounding box is automatically calculated 
-- based on env exposed draw calls using ExtendAABB() function. 
function Actor:BeginRender()
	self.bounding_radius = 0;
	self.m_aabb:SetPointBox(0,0,0);
	self:ExtendAABB(32, 16);
end

function Actor:ExtendAABB(x, y, z)
	-- invert y, since GUI has different coordinate system
	self.m_aabb:Extend(x or 0, -(y or 0), z or 0);
end

function Actor:EndRender()
	local entity = self:GetEntity();
	if(entity) then
		self.bounding_radius = math.max(self.m_aabb:GetMax():dist(0,0,0), self.m_aabb:GetMin():dist(0,0,0));
		entity:SetBoundingRadius(self.bounding_radius);
	end
end

function Actor:DoRender(painter)
	local isPickingPass = self.entity.overlay:IsPickingPass();

	if(not self:IsPickingEnabled() and isPickingPass) then
		return
	end


	local env = self:CheckInstallCodeEnv(painter, isPickingPass);
	
	-- scale 100 times, match 1 pixel to 1 centimeter in the scene. 
	painter:ScaleMatrix(0.01, 0.01, 0.01);

	painter:SetFont(self:GetFont());

	self:BeginRender();

	painter:Save();
	local text = self:GetText();
	
	if(self.codeItem:HasScript()) then
		self.codeItem:RunCode();	
	elseif(not text and not isPickingPass) then
		-- draw something, when empty code is used. 
		env.color("#80808080");
		env.rect(-10, -26, 250, 48);
		env.color("#ff0000");
		env.text("text('hello world');", 0,-16);
		env.text("rect(0, 0, 250, 64);");
	end
	painter:Restore();

	-- draw explicit text
	if(text and text~="") then
		env.text(text);
	end

	self:EndRender();
	
	if(self:IsSelected() and not isPickingPass) then
		-- draw selection border in yellow
		local radius = self.bounding_radius;
		if(radius > 0) then
			painter:SetPen("#ffff00");
			local vMin = self.m_aabb:GetMin();
			local vMax = self.m_aabb:GetMax();
			ShapesDrawer.DrawLine(painter, vMin[1], vMin[2], 0, vMax[1], vMax[2], 0);
			ShapesDrawer.DrawLine(painter, vMin[1], vMin[2], 0, vMax[1], vMin[2], 0);
			ShapesDrawer.DrawLine(painter, vMin[1], vMin[2], 0, vMin[1], vMax[2], 0);
			ShapesDrawer.DrawLine(painter, vMax[1], vMin[2], 0, vMax[1], vMax[2], 0);
			ShapesDrawer.DrawLine(painter, vMin[1], vMax[2], 0, vMax[1], vMax[2], 0);
		end
	end
end

-- select me: for further editing. 
function Actor:SelectMe()
	local entity = self:GetEntity();
	if(entity) then
		local editmodel = entity:GetEditModel();
		editmodel:Connect("EndEdit", self, "OnEndEdit");
		Actor._super.SelectMe(self);	
	end
end

function Actor:CanShowSelectManip()
	return false
end

function Actor:OnEndEdit()
	local entity = self:GetEntity();
	if(entity) then
		local displayname = entity:GetDisplayName();
		if(displayname and displayname~="") then
			self:AddKey("name", 0, displayname);
			self:GetItemStack():SetTooltip(displayname);
		end
	end
end

function Actor:ComputePosAndRotation(curTime)
	local new_x = self:GetValue("x", curTime);
	local new_y = self:GetValue("y", curTime);
	local new_z = self:GetValue("z", curTime);
	local yaw = self:GetValue("facing", curTime);
	local roll = self:ComputeRoll(curTime);
	local pitch = self:GetValue("pitch", curTime);

	return new_x, new_y, new_z, yaw, roll, pitch;
end

function Actor:GetPlaySpeed()
	return 1;
end

function Actor:ComputeScaling(curTime)
	return self:GetValue("scaling", curTime) or 1;
end
