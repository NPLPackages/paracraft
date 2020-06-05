--[[
Title: Actor Light
Author(s): LiXizhi
Date: 2020/5/11
Desc: actor light object
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/ActorLight.lua");
local ActorLight = commonlib.gettable("MyCompany.Aries.Game.Movie.ActorLight");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/Actor.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CmdParser.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemStack.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityLightChar.lua");
local EntityLightChar = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityLightChar")
local Color = commonlib.gettable("System.Core.Color");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
local MultiAnimBlock = commonlib.gettable("MyCompany.Aries.Game.Common.MultiAnimBlock");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local Actor = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Movie.Actor"), commonlib.gettable("MyCompany.Aries.Game.Movie.ActorLight"));

Actor.class_name = "ActorLight";
Actor:Property({"enablePicking", true, "IsPickingEnabled", "EnablePicking", auto=true})

-- keyframes that can be edited from UI keyframe. 
local selectable_var_list = {
	"pos", -- multiple of x,y,z
	"rot", -- multiple of "roll", "pitch", "facing"
	"---", -- separator
	"LightType", 
	"Diffuse",
	"Specular",
	"Ambient",
	"Range",
	"Falloff",
	"Attenuation0",
	"Attenuation1",
	"Attenuation2",
	"Theta",
	"Phi",
	"---", -- separator
	"parent",
};


function Actor:ctor()
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
		var:AddVariable(self:GetVariable("Range"));
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

	timeseries:CreateVariableIfNotExist("LightType", "Discrete");
	timeseries:CreateVariableIfNotExist("Diffuse", "LinearTable");
	timeseries:CreateVariableIfNotExist("Specular", "LinearTable");
	timeseries:CreateVariableIfNotExist("Ambient", "LinearTable");
	
	timeseries:CreateVariableIfNotExist("Range", "Linear");
	timeseries:CreateVariableIfNotExist("Falloff", "Linear");
	timeseries:CreateVariableIfNotExist("Attenuation0", "Linear");
	timeseries:CreateVariableIfNotExist("Attenuation1", "Linear");
	timeseries:CreateVariableIfNotExist("Attenuation2", "Linear");
	timeseries:CreateVariableIfNotExist("Theta", "Linear");
	timeseries:CreateVariableIfNotExist("Phi", "Linear");
	
	timeseries:CreateVariableIfNotExist("parent", "LinearTable");

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

		self.entity = EntityLightChar:Create({x=x,y=y,z=z,});
		if(self.entity) then
			self.entity:SetActor(self);
			self.entity:SetPersistent(false);
			self.entity:Attach();
		end
		return self;
	end
end

-- return the parent link and parent actor if found.
-- @return parent, curTime, parentActor, keypath: where parent contains local transform relative to target:
--  in the form {target="fullname", pos={}, rot={}, use_rot=true}
function Actor:GetParentLink(curTime)
	curTime = curTime or self:GetTime();
	local parent = self:GetValue("parent", curTime);
	if(parent and type(parent) == "table" and parent.target and parent.target ~="")then
		-- animate linking to another actor's bone animation. 
		local actorname, keypath = parent.target:match("^([^:]+):*(.*)"); 
		if(actorname) then
			local parentActor = self:FindActor(actorname);
			if(parentActor and parentActor~=self) then
				return parent, curTime, parentActor, keypath;
			end
		end
	end
end

-- force adding current values to all transform variables, these include position and rotation.
function Actor:KeyTransform()
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

	local obj = entity:GetInnerObject();

	if(obj) then
		local yaw = obj:GetField("yaw", 0);
		self:AutoAddKey("facing", curTime, yaw);
		local roll = obj:GetField("roll", 0);
		self:AutoAddKey("roll", curTime, roll);
		local pitch = obj:GetField("pitch", 0);
		self:AutoAddKey("pitch", curTime, pitch);
	end
	self:EndUpdate();
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

	if(keyname == "Range") then
		old_value = old_value or self.entity:GetField(keyname)
		local title = format(L"起始时间%s, 请输入光源范围", strTime);

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
	elseif(keyname == "Falloff") then
		old_value = old_value or self.entity:GetField(keyname)
		local title = format(L"起始时间%s, 请输入衰减值", strTime);

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
	elseif(keyname == "Theta" or keyname == "Phi") then
		old_value = old_value or self.entity:GetField(keyname)
		local title = format(L"起始时间%s, 请输入%s角度", strTime, keyname);

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
	elseif(keyname == "Attenuation0" or keyname == "Attenuation1" or keyname == "Attenuation2") then
		old_value = old_value or self.entity:GetField(keyname)
		local title = format(L"起始时间%s, 请输入 %s角度", strTime, keyname);

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
	elseif(keyname == "LightType") then
		old_value = old_value or self.entity:GetField(keyname)
		local title = format(L"起始时间%s, 光源类型:", strTime);
		local options = {
			{value = 1, text= L"点光源"},
			{value = 2, text= L"聚光灯"},
			{value = 3, text= L"平行光"},
		}
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
		local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
		EnterTextDialog.ShowPage(title, function(result)
			if(result and result ~= "") then
				if( type(result) == "number") then
					local result = tonumber(result);
					if(result >= 1 and result <=3) then
						self:AddKeyFrameByName(keyname, nil, result);
						self:FrameMovePlaying(0);
						if(callbackFunc) then
							callbackFunc(true);
						end
					end
				end
			end
		end, old_value or 1, "select", options);

	elseif(keyname == "Diffuse" or keyname == "Specular" or keyname == "Ambient") then
		local title = format(L"起始时间%s, 请输入颜色RGB. 例如:#ffffff", strTime);
		old_value = old_value or self.entity:GetField(keyname)
		old_value = old_value and Color.RGBAfloat_TO_ColorStr(old_value[1],old_value[2],old_value[3])

		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
		local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
		EnterTextDialog.ShowPage(title, function(result)
			if(result and result~="" and result:match("^#[%d%w]+$")) then
				local r, g, b = Color.ColorStr_TO_RGBAfloat(result);
				self:AddKeyFrameByName(keyname, nil, {r,g,b});
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
	elseif(keyname == "parent") then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/EditParentLinkPage.lua");
		local EditParentLinkPage = commonlib.gettable("MyCompany.Aries.Game.Movie.EditParentLinkPage");
		EditParentLinkPage.ShowPage(strTime, self, function(values)
			if(values.target=="") then
				-- this will automatically add a key frame, when link is removed. 
				self:KeyTransform();
			end
			self:AddKeyFrameByName(keyname, nil, values);
			self:FrameMovePlaying(0);
			if(target~="") then
				-- this will automatically add a key frame at the position. 
				self:KeyTransform();
			end
			if(callbackFunc) then
				callbackFunc(true);
			end
		end, old_value);
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
	
	local new_x, new_y, new_z, yaw, roll, pitch = self:ComputePosAndRotation(curTime);
	
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
	local LightType = self:GetValue("LightType", curTime)
	if(LightType) then
		entity:SetLightType(LightType);
	end
	local Diffuse = self:GetValue("Diffuse", curTime)
	if(Diffuse) then
		entity:SetDiffuse(Diffuse);
	end
	local Ambient = self:GetValue("Ambient", curTime)
	if(Ambient) then
		entity:SetAmbient(Ambient);
	end
	local Specular = self:GetValue("Specular", curTime)
	if(Specular) then
		entity:SetSpecular(Specular);
	end

	local Range = self:GetValue("Range", curTime)
	if(Range) then
		entity:SetRange(Range);
	end
	local Falloff = self:GetValue("Falloff", curTime)
	if(Falloff) then
		entity:SetFalloff(Falloff);
	end

	local Attenuation0 = self:GetValue("Attenuation0", curTime)
	if(Attenuation0) then
		entity:SetAttenuation0(Attenuation0);
	end
	local Attenuation1 = self:GetValue("Attenuation1", curTime)
	if(Attenuation1) then
		entity:SetAttenuation1(Attenuation1);
	end
	local Attenuation2 = self:GetValue("Attenuation2", curTime)
	if(Attenuation2) then
		entity:SetAttenuation2(Attenuation2);
	end

	local Theta = self:GetValue("Theta", curTime)
	if(Theta) then
		entity:SetTheta(Theta);
	end
	local Phi = self:GetValue("Phi", curTime)
	if(Phi) then
		entity:SetPhi(Phi);
	end
	
	entity:SetFacing(yaw or 0);
	entity:SetPitch(pitch or 0);
	entity:SetRoll(roll or 0);
end

function Actor:ComputePosAndRotation(curTime)
	local new_x = self:GetValue("x", curTime);
	local new_y = self:GetValue("y", curTime);
	local new_z = self:GetValue("z", curTime);
	local yaw = self:GetValue("facing", curTime);
	local roll = self:GetValue("roll", curTime);
	local pitch = self:GetValue("pitch", curTime);

	-- animate linking to another actor's bone animation. 
	local parent, _, parentActor, keypath = self:GetParentLink(curTime);
	if(keypath and parentActor and parentActor.ComputeWorldTransform)then
		local p_x, p_y, p_z, p_roll, p_pitch, p_yaw, p_scale = parentActor:ComputeWorldTransform(keypath, curTime, parent.pos, parent.rot, parent.use_rot); 
		if(p_x) then
			new_x, new_y, new_z = p_x, p_y, p_z;
			if(p_roll) then
				roll, pitch, yaw = p_roll, p_pitch, p_yaw;
			end
			if(p_scale) then
				-- scale = p_scale * (scale or 1);
			end
		else
			if(self.last_unknown_keypath~=keypath and keypath and keypath~="") then
				-- here we just wait 500 and try again only once for a given bone keypath.
				self.last_unknown_keypath = keypath;
				self.loader_timer = self.loader_timer or commonlib.Timer:new({callbackFunc = function(timer)
					self:FrameMovePlaying(0);
				end})
				LOG.std(nil, "info", "ActorLight", "parent bone may be async loading, wait 500ms");
				self.loader_timer:Change(500, nil);
			end
		end
	end

	return new_x, new_y, new_z, yaw, roll, pitch;
end

