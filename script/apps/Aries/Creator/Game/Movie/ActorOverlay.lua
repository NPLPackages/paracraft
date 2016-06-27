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
Actor:Property({"text", "", "GetText", "SetText", auto=true})
-- line height in pixels
Actor:Property({"lineheight", 16,})

Actor:Property({"bounding_radius", 0, "GetBoundingRadius", "SetBoundingRadius", auto=true})
Actor:Property({"m_aabb", nil,})

Actor.class_name = "ActorOverlay";

-- keyframes that can be edited from UI keyframe. 
local selectable_var_list = {
	"text",
	"code",
	"pos", -- multiple of x,y,z
	"facing", 
	"rot", -- multiple of "roll", "pitch", "facing"
	"scaling", 
	"opacity",
	"color",
};


function Actor:ctor()
	self.codeItem = ItemStack:new():Init(block_types.names.Code, 1);
	self.m_aabb = ShapeBox:new():SetPointBox(0,0,0);
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

function Actor:Init(itemStack, movieclipEntity)
	-- base class must be called last, so that child actors have created their own variables on itemStack. 
	if(not Actor._super.Init(self, itemStack, movieclipEntity)) then
		return;
	end

	local timeseries = self.TimeSeries;
	timeseries:CreateVariableIfNotExist("x", "Linear");
	timeseries:CreateVariableIfNotExist("y", "Linear");
	timeseries:CreateVariableIfNotExist("z", "Linear");
	timeseries:CreateVariableIfNotExist("facing", "LinearAngle");
	timeseries:CreateVariableIfNotExist("pitch", "LinearAngle");
	timeseries:CreateVariableIfNotExist("roll", "LinearAngle");
	timeseries:CreateVariableIfNotExist("scaling", "Linear");
	timeseries:CreateVariableIfNotExist("opacity", "Linear");
	timeseries:CreateVariableIfNotExist("code", "Discrete");
	timeseries:CreateVariableIfNotExist("text", "Discrete");
	timeseries:CreateVariableIfNotExist("color", "Discrete");
	
	self:AddValue("position", self.GetPosVariable);

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
		local title = format(L"起始时间%s, 请输入透明度[0,1](默认1)", strTime);

		-- TODO: use a dedicated UI 
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
		local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
		EnterTextDialog.ShowPage(title, function(result)
			result = tonumber(result);
			if(result and result>=0 and result<=1) then
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
			if(result and result~="") then
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
color("#ff0000");<br/>
]];
		
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
		local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
		EnterTextDialog.ShowPage(title, function(result)
			if(result and result~="") then
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
			title = format(L"起始时间%s, 请输入转身的角度(-3.14, 3.14)", strTime);
		end

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
		local title = format(L"起始时间%s, 请输入roll, pitch, yaw (-1.57, 1.57)<br/>", strTime);
		old_value = string.format("%f, %f, %f", self:GetValue("roll", curTime) or 0,self:GetValue("pitch", curTime) or 0,self:GetValue("facing", curTime) or 0);
		-- TODO: use a dedicated UI 
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
		local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
		EnterTextDialog.ShowPage(title, function(result)
			if(result and result~="") then
				local vars = CmdParser.ParseNumberList(result, nil, "|,%s");
				if(result and vars[1] and vars[2] and vars[3]) then
					self:BeginUpdate();
					self:AddKeyFrameByName("roll", nil, vars[1]);
					self:AddKeyFrameByName("pitch", nil, vars[2]);
					self:AddKeyFrameByName("facing", nil, vars[3]);
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
		old_value = string.format("%f, %f, %f", self:GetValue("x", curTime) or 0,self:GetValue("y", curTime) or 0, self:GetValue("z", curTime) or 0);
		-- TODO: use a dedicated UI 
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
		local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
		EnterTextDialog.ShowPage(title, function(result)
			if(result and result~="") then
				local vars = CmdParser.ParseNumberList(result, nil, "|,%s");
				if(result and vars[1] and vars[2] and vars[3]) then
					self:BeginUpdate();
					self:AddKeyFrameByName("x", nil, vars[1]);
					self:AddKeyFrameByName("y", nil, vars[2]);
					self:AddKeyFrameByName("z", nil, vars[3]);
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

function Actor:FrameMovePlaying(deltaTime)
	local curTime = self:GetTime();
	local entity = self.entity;
	if(not entity or not curTime) then
		return
	end
	-- allow adding keyframe while playing during the last segment. 
	local allow_user_control = self:IsAllowUserControl() and
		((self:GetMultiVariable():GetLastTime()+1) <= curTime);

	local new_x = self:GetValue("x", curTime);
	local new_y = self:GetValue("y", curTime);
	local new_z = self:GetValue("z", curTime);

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

	local yaw, roll, pitch, scaling, opacity, color;
	yaw = self:GetValue("facing", curTime);
	roll = self:GetValue("roll", curTime);
	pitch = self:GetValue("pitch", curTime);
	scaling = self:GetValue("scaling", curTime);
	opacity = self:GetValue("opacity", curTime);
	color = self:GetValue("color", curTime);

	self:SetText(self:GetValue("text", curTime));
	entity:SetFacing(yaw or 0);
	entity:SetScaling(scaling or 1);
	entity:SetPitch(pitch or 0);
	entity:SetRoll(roll or 0);
	entity:SetOpacity(opacity or 1);
	entity:SetColor(color or "#ffffff");
	-- set render code
	self.codeItem:SetCode(self:GetValue("code", curTime));
end

-- example codes:
-- image("1.png", 300,200)
-- color("#ff0000")
-- text("hello", 0, 0)
-- rect(-10,-10, 250,64, "1.png;0 0 32 32:8 8 8 8")
function Actor:CheckInstallCodeEnv(painter)
	local env = self.codeItem:GetScriptScope();
	env.painter = painter;
	if(not env.text) then

		-- draw text
		-- @param text: text to render with current font 
		-- @param x,y: default to 0,0
		env.text = function(text, x, y)
			if(text and text~="") then
				x = x or 0;
				y = y or 0;
				self:ExtendAABB(x, y);
				for line in text:gmatch("[^\n]+") do
					env.painter:DrawText(x, y, line);
					y = y + self.lineheight;
					self:ExtendAABB(x + _guihelper.GetTextWidth(line, self:GetFont()), y);
				end
			end
		end

		-- draw a rectangle with texture filename 
		-- @param filename: if nil, it will render with current pen color. 
		env.rect = function(x, y, width, height, filename)
			if(x and y and width and height) then
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
			end
		end

		-- set pen color
		-- @param color: such as "#ff0000"
		env.color = function(color)
			env.painter:SetPen(color);
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
						width = width or texture:GetWidth();
						height = height or texture:GetHeight();
					end
					x,y,width, height = x or 0, y or 0, width or 64, height or 64;
					self:ExtendAABB(x, y);
					self:ExtendAABB(x+width, y+height);
					env.painter:DrawRectTexture(x, y, width, height, filename);
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
	local env = self:CheckInstallCodeEnv(painter);
	
	-- scale 100 times, match 1 pixel to 1 centimeter in the scene. 
	painter:ScaleMatrix(0.01, 0.01, 0.01);

	painter:SetFont(self:GetFont());

	self:BeginRender();

	painter:Save();
	local text = self:GetText();
	if(self.codeItem:HasScript()) then
		self.codeItem:RunCode();	
	elseif(not text or text=="") then
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
	
	if(self:IsSelected()) then
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
