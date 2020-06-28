--[[
Title: mob entity actor
Author(s): LiXizhi
Date: 2014/3/30
Desc: for recording and playing back of mob and NPC
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/ActorNPC.lua");
local ActorNPC = commonlib.gettable("MyCompany.Aries.Game.Movie.ActorNPC");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/Actor.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/ActorBlock.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/MultiAnimBlock.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CmdParser.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/BonesVariable.lua");
NPL.load("(gl)script/ide/math/Quaternion.lua");
local Matrix4 = commonlib.gettable("mathlib.Matrix4");
local Quaternion = commonlib.gettable("mathlib.Quaternion");
local math3d = commonlib.gettable("mathlib.math3d");
local BonesVariable = commonlib.gettable("MyCompany.Aries.Game.Movie.BonesVariable");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
local MultiAnimBlock = commonlib.gettable("MyCompany.Aries.Game.Common.MultiAnimBlock");
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
local ActorBlock = commonlib.gettable("MyCompany.Aries.Game.Movie.ActorBlock");
local EntityNPC = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityNPC")
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");


local Actor = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Movie.Actor"), commonlib.gettable("MyCompany.Aries.Game.Movie.ActorNPC"));

Actor.class_name = "ActorNPC";
Actor:Property({"entityClass", "EntityNPC"});
Actor:Property({"offset_facing", nil, "GetOffsetFacing", "SetOffsetFacing", auto=true});
-- asset file is changed
Actor:Signal("assetfileChanged");

-- recommended to set to true to use script to calculate pose for each frame precisely. 
local animate_by_script = true;
			

-- keyframes that can be edited from UI keyframe. 
local selectable_var_list = {
	"anim", "bones", 
	"pos", -- multiple of x,y,z
	"facing", 
	"rot", -- multiple of "roll", "pitch", "facing"
	"scaling",
	"head", -- multiple of "HeadUpdownAngle", "HeadTurningAngle"
	"---", -- separator
	"speedscale", 
	"gravity", 
	"---", -- separator
	"assetfile", "skin", "opacity", 
	"blockinhand",
	"blocks",
	"---", -- separator
	"parent", 
	"cam_dist", -- object to camera distance
	"static", -- multiple of "name" and "isAgent"
};


function Actor:ctor()
	self.actor_block = ActorBlock:new();
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
		var:AddVariable(self:GetVariable("anim"));
		var:AddVariable(self:GetVariable("skin"));
		var:AddVariable(self:GetVariable("blockinhand"));
		var:AddVariable(self:GetVariable("assetfile"));
		var:AddVariable(self:GetVariable("scaling"));
		self:SetCustomVariable("multi_variable", var);
		return var;
	end
end

-- get rotate multi variable
function Actor:GetStaticVariable()
	local var = self:GetCustomVariable("static_variable");
	if(var) then
		return var;
	else
		var = MultiAnimBlock:new({name="static"});
		var:AddVariable(self:GetVariable("name"));
		var:AddVariable(self:GetVariable("isAgent"));
		var:AddVariable(self:GetVariable("isServer"));
		self:SetCustomVariable("static_variable", var);
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

function Actor:GetBlocksVariable()
	return self.actor_block.blocks;
end

-- get position multi variable
function Actor:GetHeadVariable()
	local var = self:GetCustomVariable("head_variable");
	if(var) then
		return var;
	else
		var = MultiAnimBlock:new({name="head"});
		var:AddVariable(self:GetVariable("HeadTurningAngle"));
		var:AddVariable(self:GetVariable("HeadUpdownAngle"));
		self:SetCustomVariable("head_variable", var);
		return var;
	end
end

-- load bone animations if not loaded before, this function does nothing if no bones are in the time series. 
function Actor:CheckLoadBonesAnims()
	if(not self.bones_variable) then
		local bones = self:GetTimeSeries():GetChild("bones");
		if(bones) then
			self:GetBonesVariable();
		end
	end
end

function Actor:GetSelectionName()
	local name = self:GetDisplayName() or "";
	local var = self:GetEditableVariable();

	if(var) then
		name = format("%s::%s", name, var.name);
		if(var.name == "bones") then
			local bone_name = var:GetSelectedBoneName();
			if(bone_name) then
				name = format("%s::%s", name, bone_name);
			else
				name = format("%s::[all]", name);
			end
		end
	end
	return name;
end

function Actor:GetBonesVariable()
	if(not self.bones_variable) then
		self.bones_variable = BonesVariable:new():init(self);
		self:Connect("dataSourceChanged", self.bones_variable, self.bones_variable.LoadFromActor)
		self:Connect("assetfileChanged", self.bones_variable, self.bones_variable.OnAssetFileChanged)
	end
	return self.bones_variable;
end

-- @param isReuseActor: whether we will reuse actor in the scene with the same name instead of creating a new entity. default to false.
-- @param newName: if not provided, it will use the name in itemStack
function Actor:Init(itemStack, movieclipEntity, isReuseActor, newName, movieclip)
	self.actor_block:Init(itemStack, movieclipEntity);
	-- base class must be called last, so that child actors have created their own variables on itemStack. 
	if(not Actor._super.Init(self, itemStack, movieclipEntity, movieclip)) then
		return;
	end

	local timeseries = self.TimeSeries;
	timeseries:CreateVariableIfNotExist("x", "Linear");
	timeseries:CreateVariableIfNotExist("y", "Linear");
	timeseries:CreateVariableIfNotExist("z", "Linear");
	timeseries:CreateVariableIfNotExist("facing", "LinearAngle");
	timeseries:CreateVariableIfNotExist("pitch", "LinearAngle");
	timeseries:CreateVariableIfNotExist("roll", "LinearAngle");
	timeseries:CreateVariableIfNotExist("HeadUpdownAngle", "Linear");
	timeseries:CreateVariableIfNotExist("HeadTurningAngle", "Linear");
	timeseries:CreateVariableIfNotExist("anim", "Discrete");
	timeseries:CreateVariableIfNotExist("assetfile", "Discrete");
	timeseries:CreateVariableIfNotExist("speedscale", "Discrete");
	timeseries:CreateVariableIfNotExist("gravity", "Discrete");
	timeseries:CreateVariableIfNotExist("scaling", "Linear");
	timeseries:CreateVariableIfNotExist("name", "Discrete");
	timeseries:CreateVariableIfNotExist("isAgent", "Discrete"); -- true, nil|false, "relative", "searchNearPlayer"
	timeseries:CreateVariableIfNotExist("isServer", "Discrete"); -- false, whether this entity is a server mode entity
	
	timeseries:CreateVariableIfNotExist("skin", "Discrete");
	timeseries:CreateVariableIfNotExist("blockinhand", "Discrete");
	timeseries:CreateVariableIfNotExist("opacity", "Linear");
	timeseries:CreateVariableIfNotExist("parent", "LinearTable");
	timeseries:CreateVariableIfNotExist("cam_dist", "Discrete");
	
	
	self:AddValue("position", self.GetPosVariable);

	-- get initial position from itemStack, if not exist, we will use movie clip entity's block position. 
	local movieClip = self:GetMovieClip();
	if(movieClip) then
		local x, y, z = self:CheckSetDefaultPosition();

		local HeadUpdownAngle, HeadTurningAngle, anim, facing,skin, opacity, name;
		HeadUpdownAngle = self:GetValue("HeadUpdownAngle", 0);
		HeadTurningAngle = self:GetValue("HeadTurningAngle", 0);
		anim = self:GetValue("anim", 0);
		facing = self:GetValue("facing", 0);
		skin = self:GetValue("skin", 0);
		opacity = self:GetValue("opacity", 0);
		name = newName or self:GetValue("name", 0);
		local isAgent = self:GetValue("isAgent", 0);
		local isServerEntity = self:GetValue("isServer", 0);

		if(isReuseActor == nil) then
			isReuseActor = isAgent
		end

		if((isReuseActor or isAgent) and name and name~="") then
			local entity;
			local offsetFacing;
			if(name == "player") then
				entity = EntityManager.GetPlayer();
			else
				if(isReuseActor == "searchNearPlayer") then
					local playerActor = movieClip:FindActor("player");
					if(playerActor) then	
						-- if the movie clip already contains a player, we will use it to locate the entity
						local x, y, z = playerActor:TransformToEntityPosition(x, y, z)
						local bx, by, bz = BlockEngine:block(x, y+0.1, z);
						local r = 1;
						local entities = EntityManager.GetEntitiesByMinMax(bx-r, by-r, bz-r, bx+r, by+r, bz+r)
						if(entities and #entities>0) then
							-- tricky: we will match either name or assetfile 
							local assetfile = self:GetValue("assetfile", 0);
							for i, entity_ in ipairs(entities) do
								if(entity_:GetName() == name) then
									entity = entity_;
									break;
								elseif(entity_.GetModelFile and entity_:GetModelFile() == assetfile) then
									entity = entity_;
									break;
								end
							end
						end
						if (entity) then
							-- tricky: always use relative facing of the nearby player actor
							offsetFacing = playerActor:GetOffsetFacing()
						end
					else
						-- search near the current player
						local x, y, z = EntityManager.GetPlayer():GetBlockPos()
						local r = 5;
						local entities = EntityManager.FindEntities({name = name, x=x,  y=y, z=z, r=r})
						if(entities and #entities>0) then
							entity = entities[1];
							if(entity and not entity.SetActor) then
								entity = nil;
							end
						end
					end
				end
				if(not entity) then
					entity = EntityManager.GetEntity(name);
					if(entity and not entity.SetActor) then
						entity = nil;
					end
				end
			end
			if(isAgent and isReuseActor==false and (not newName) and entity) then
				-- tricky: we still need to reuse actor, even if isReuseActor == false under above conditions
				isReuseActor = true;
			end

			if(isReuseActor and entity) then
				self:BecomeAgent(entity);
				if(isReuseActor == "relative" or isReuseActor == "searchNearPlayer") then
					self:CalculateRelativeParams();
					if(offsetFacing) then
						self:SetOffsetFacing(offsetFacing);
					end
				end
			end
		end
		if(not self.entity) then
			self.entity = EntityManager[self.entityClass]:Create({name=name, x=x,y=y,z=z, facing=facing, 
				opacity = opacity, item_id = block_types.names.TimeSeriesNPC, 
			});	
		end
		
		if(self.entity and not self:IsAgent()) then
			self.entity:SetActor(self);
			self.entity:SetPersistent(false);
			self.entity:SetDummy(true);
			self.entity:SetGroupId(nil);
			self.entity:SetSentientField(0);
			self.entity:SetServerEntity(isServerEntity == true);

			self.entity:SetSkin(skin);
			
			self.entity:SetCanRandomMove(false);
			self.entity:SetDisplayName(name);
			self.entity:EnableAnimation(not animate_by_script);
			-- self.entity:EnableLOD(false);
			self.entity:Attach();
			self:CheckLoadBonesAnims();

			if(isReuseActor) then
				-- just incase the reused actor is not found, we will create a new one and become an agent of it. 
				self:BecomeAgent(self.entity);
			end
		end
		return self;
	end
end

-- from data source coordinate to entity coordinate according to CalculateRelativeParams()
function Actor:TransformToEntityPosition(x, y, z)
	x = x + (self.offset_x or 0);
	y = y + (self.offset_y or 0);
	z = z + (self.offset_z or 0);
	
	if((self.offset_facing or 0) ~= 0) then
		local dx, _, dz = math3d.vec3Rotate(x - self.origin_x, 0, z - self.origin_z, 0, self.offset_facing, 0);
		x = dx + self.origin_x;
		z = dz + self.origin_z;
	end
	return x,y,z;
end

-- from data source coordinate to entity coordinate according to CalculateRelativeParams()
function Actor:TransformToEntityFacing(facing)
	return facing + (self.offset_facing or 0);
end

function Actor:IsAgentRelative()
	return self.origin_x~=nil;
end

-- calculate relative params at time 0 according to the current entity's parameters
-- so that all time series values are relative to time 0, instead of absolute values in data source. 
-- currently, only entity position and facing are taking in to account and snapped to block position and 4 direction. 
-- calculated values in self.offset_x, self.offset_y, self.offset_z, self.offset_facing
function Actor:CalculateRelativeParams()
	local entity = self:GetEntity();
	if(entity) then
		local obj = entity:GetInnerObject();
		if(not obj) then
			return
		end	
		-- relative position
		local entity_bx, entity_by, entity_bz = entity:GetBlockPos();
		local entity_x, entity_y, entity_z = entity:GetPosition();
		local entity_facing = entity:GetFacing() or 0;
		
		local memory_x, memory_y, memory_z = self:GetValue("x", 0), self:GetValue("y", 0), self:GetValue("z", 0);
		local memory_bx, memory_by, memory_bz = BlockEngine:block(memory_x, memory_y+0.1, memory_z);
		local memory_facing = self:GetValue("facing", 0) or 0;
		
		self.offset_x = (entity_bx - memory_bx)*BlockEngine.blocksize;
		self.offset_y = (entity_by - memory_by)*BlockEngine.blocksize;
		self.offset_z = (entity_bz - memory_bz)*BlockEngine.blocksize;
		self.origin_x, self.origin_y, self.origin_z = BlockEngine:real(entity_bx, entity_by, entity_bz);

		-- relative facing
		local memory_dir_facing = Direction.NormalizeFacing(memory_facing)
		local entity_dir_facing = Direction.NormalizeFacing(entity_facing)
		self.offset_facing = mathlib.ToStandardAngle(entity_dir_facing - memory_dir_facing);

		-- echo({self.offset_x, self.offset_y, self.offset_z, self.offset_facing})
	end
end

-- set the default position
-- @param bUseCurrentPosition: true to use the current entity's position. false or nil to use the entaining movie block's position.
-- @return x,y,z at time 0
function Actor:CheckSetDefaultPosition(bUseCurrentPosition)
	local x = self:GetValue("x", 0);
	local y = self:GetValue("y", 0);
	local z = self:GetValue("z", 0);
	if(not x or not y or not z) then
		if(bUseCurrentPosition) then
			x,y,z = self.entity:GetPosition();
		else
			local movieClip = self:GetMovieClip();
			if(movieClip) then
				x, y, z = movieClip:GetOrigin();
				y = y + BlockEngine.blocksize;
			end
		end
		if(x) then
			self:AddKey("x", 0, x);
			self:AddKey("y", 0, y);
			self:AddKey("z", 0, z);
		end
	end
	return x,y,z;
end

function Actor:OnRemove()
	self.actor_block:OnRemove();
	
	Actor._super.OnRemove(self);
end

function Actor:SetItemStack(itemStack)
	self.actor_block:SetItemStack(itemStack);
	-- base class must be called last, so that child actors have initialized their own variables on itemStack. 
	Actor._super.SetItemStack(self, itemStack);
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
	elseif(name == "head") then
		var = self:GetHeadVariable();
	elseif(name == "bones") then
		var = self:GetBonesVariable();
	elseif(name == "blocks") then
		var = self:GetBlocksVariable();
	elseif(name == "static") then
		var = self:GetStaticVariable();
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

	if(keyname == "anim") then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/EntityAnimation.lua");
		local EntityAnimation = commonlib.gettable("MyCompany.Aries.Game.Effects.EntityAnimation");
			
		-- get {{value, text}} array of all animations in the asset file. 
		local options = {};
		local assetfile = self:GetValue("assetfile", curTime);
		if(not assetfile) then
			local entity = self:GetEntity()
			if(entity) then
				assetfile = entity:GetMainAssetPath();
			end
		end
		if(assetfile) then
			assetfile = PlayerAssetFile:GetFilenameByName(assetfile)
			NPL.load("(gl)script/ide/System/Scene/Assets/ParaXModelAttr.lua");
			local ParaXModelAttr = commonlib.gettable("System.Scene.Assets.ParaXModelAttr");
			local attr = ParaXModelAttr:new():initFromAssetFile(assetfile);
			local animations = attr:GetAnimations()
			if(animations) then
				for _, anim in ipairs(animations) do
					if(anim.animID) then
						options[#options+1] = {value = anim.animID, text = EntityAnimation.GetAnimTextByID(anim.animID, assetfile)}
					end
				end
				table.sort(options, function(a, b)
					return a.value < b.value;
				end)
			end
			if(assetfile:match("%.bmax$")) then
				-- we will add some more default values
				local hasAnims = {};
				for _, option in ipairs(options) do
					hasAnims[option.value] = true;
				end
				local default_anim_placeholders = {0,4,5,13, 37,38,39,41,42,43,44,45,91,135,153, 154, 155, 156,}
				for _, animId in ipairs(default_anim_placeholders) do
					if(not hasAnims[animId]) then
						options[#options+1] = {value = animId, text = EntityAnimation.GetAnimTextByID(animId, assetfile)};
					end
				end
			end
		end
		
		local title = format(L"起始时间%s, 请输入动画ID或名称:", strTime);

		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
		local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
		EnterTextDialog.ShowPage(title, function(result)
			if(result and result ~= "") then
				result = EntityAnimation.CreateGetAnimId(result);	
				if( type(result) == "number") then
					self:AddKeyFrameByName(keyname, nil, result);
					self:FrameMovePlaying(0);
					if(callbackFunc) then
						callbackFunc(true);
					end
				end
			end
		end,old_value, "select", options);

	elseif(keyname == "assetfile") then
		local title = format(L"起始时间%s, 请输入模型路经或名称(默认default)", strTime);

		if(old_value == nil) then
			local entity = self:GetEntity()
			if(entity) then
				old_value = entity:GetMainAssetPath();
			end
		end

		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/OpenAssetFileDialog.lua");
		local OpenAssetFileDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.OpenAssetFileDialog");
		OpenAssetFileDialog.ShowPage(title, function(result)
			if(result) then
				local filepath = PlayerAssetFile:GetValidAssetByString(result);
				if(filepath or result=="0" or result=="") then
					-- PlayerAssetFile:GetNameByFilename(filename)
					self:AddKeyFrameByName(keyname, nil, result);
					self:FrameMovePlaying(0);
					if(callbackFunc) then
						callbackFunc(true);
						return
					end
				end
			end
			if(callbackFunc) then
				callbackFunc(false);
			end
		end, old_value, L"选择模型文件", "model");
	elseif(keyname == "cam_dist") then
		local title = format(L"起始时间%s, 请输入到摄影机的距离(0-10000)", strTime);

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
	elseif(keyname == "blockinhand") then
		local title = format(L"起始时间%s, 请输入手持物品ID(空为0)", strTime);

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
	elseif(keyname == "skin") then
		local title = format(L"起始时间%s, 请输入皮肤ID或名称", strTime);

		local assetFilename;
		local entity = self:GetEntity()
		if(entity) then
			assetFilename = entity:GetMainAssetPath();
		end

		NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/EditSkinPage.lua");
		local EditSkinPage = commonlib.gettable("MyCompany.Aries.Game.Movie.EditSkinPage");
		EditSkinPage.ShowPage(function(result)
			if(result) then
				self:AddKeyFrameByName(keyname, nil, result);
				self:FrameMovePlaying(0);
				if(callbackFunc) then
					callbackFunc(true);
				end
			end
		end, old_value, title, assetFilename)

	elseif(keyname == "scaling") then
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
	elseif(keyname == "facing" or keyname == "HeadUpdownAngle" or keyname=="HeadTurningAngle") then
		local title;
		if(keyname == "facing") then
			title = format(L"起始时间%s, 请输入转身的角度".."[-180, 180]", strTime);
		elseif(keyname == "HeadUpdownAngle") then
			title = format(L"起始时间%s, 请输入头部上下运动的角度".."[-90, 90]", strTime);
		elseif(keyname == "HeadTurningAngle") then
			title = format(L"起始时间%s, 请输入头部左右运动的角度".."[-90, 90]", strTime);
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
	elseif(keyname == "head") then
		local title = format(L"起始时间%s, 请输入头部角度[-90, 90]<br/>左右角度, 上下角度:", strTime);
		old_value = string.format("%f, %f", (self:GetValue("HeadTurningAngle", curTime) or 0) / math.pi * 180, 
			(self:GetValue("HeadUpdownAngle", curTime) or 0) / math.pi * 180);
		-- TODO: use a dedicated UI 
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
		local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
		EnterTextDialog.ShowPage(title, function(result)
			if(result and result~="") then
				local vars = CmdParser.ParseNumberList(result, nil, "|,%s");
				if(result and vars[1] and vars[2]) then
					self:BeginUpdate();
					self:AddKeyFrameByName("HeadTurningAngle", nil, vars[1] / 180 * math.pi);
					self:AddKeyFrameByName("HeadUpdownAngle", nil, vars[2] / 180 * math.pi);
					self:EndUpdate();
					self:FrameMovePlaying(0);
					if(callbackFunc) then
						callbackFunc(true);
					end
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
		end,old_value)
	elseif(keyname == "gravity") then
		local title = format(L"起始时间%s, 请输入重力加速度(默认18.36)", strTime);

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
	elseif(keyname == "speedscale") then
		local title = format(L"起始时间%s, 请输入运动速度系数(默认1)", strTime);

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
	elseif(keyname == "bones") then
		local var = self:GetBonesVariable();
		if(var) then
			local bone = var:GetSelectedBone();
			if(bone) then
				local rotVarCpp = bone:GetVariable(1);
				local rotVar = rotVarCpp:CreateGetTimeVar();
				local quat = rotVar:getValue(1, curTime);
				if(quat) then
					local yaw, roll, pitch = Quaternion.ToEulerAngles(quat) 
					local title = format(L"起始时间%s, 请输入roll, pitch, yaw [-180, 180]<br/>", strTime);
					old_value = string.format("%f, %f, %f", (roll or 0) / math.pi * 180, (pitch or 0) / math.pi * 180, (yaw or 0) / math.pi * 180);
					-- TODO: use a dedicated UI 
					NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
					local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
					EnterTextDialog.ShowPage(title, function(result)
						if(result and result~="") then
							local vars = CmdParser.ParseNumberList(result, nil, "|,%s");
							if(result and vars[1] and vars[2] and vars[3]) then
								self:BeginUpdate();
								roll, pitch, yaw  = vars[1] / 180 * math.pi, vars[2] / 180 * math.pi, vars[3] / 180 * math.pi;
								self:BeginModify();
								quat = Quaternion.FromEulerAngles(quat, yaw, roll, pitch);
								rotVarCpp:LoadFromTimeVar();
								self:SetModified();
								self:EndModify();
								self:EndUpdate();
								self:FrameMovePlaying(0);
								if(callbackFunc) then
									callbackFunc(true);
								end
							end
						end
					end,old_value)
				end
			else
				local rangeVar = var:GetRangeVariable();
				if(rangeVar) then
					old_value = rangeVar:getValue(1, curTime) or "on";
				else
					old_value = "on";
				end
				
				-- TODO: use a dedicated UI 
				local title = format(L"起始时间%s, 请输入on或off<br/>on代表禁用骨骼动画，off代表使用骨骼动画<br/>", strTime);
				
				NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EnterTextDialog.lua");
				local EnterTextDialog = commonlib.gettable("MyCompany.Aries.Game.GUI.EnterTextDialog");
				EnterTextDialog.ShowPage(title, function(result)
					if(result and (result=="on" or result=="off") and old_value~=result) then
						local bEnabled = CmdParser.ParseBool(result);
						self:BeginModify();
						local rangeVar = var:GetRangeVariable(true);
						rangeVar:AddKey(curTime, result)
						self:EndModify();
						self:FrameMovePlaying(0);
						if(callbackFunc) then
							callbackFunc(true);
						end
					end
				end, old_value)
			end
		end
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
	elseif(keyname == "static") then
		old_value = {name = self:GetValue("name", 0) or "", isAgent = self:GetValue("isAgent", 0), isServer = self:GetValue("isServer", 0)==true}
		NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/EditStaticPropertyPage.lua");
		local EditStaticPropertyPage = commonlib.gettable("MyCompany.Aries.Game.Movie.EditStaticPropertyPage");
		EditStaticPropertyPage.ShowPage(function(values)
			if(values.name ~= old_value.name) then
				self:AddKeyFrameByName("name", 0, values.name);
				self:SetDisplayName(values.name)
			end
			if(values.isAgent ~= old_value.isAgent) then
				self:AddKeyFrameByName("isAgent", 0, values.isAgent);
			end
			if(values.isServer ~= old_value.isServer) then
				self:AddKeyFrameByName("isServer", 0, values.isServer);
			end
			if(callbackFunc) then
				callbackFunc(true);
			end
		end, old_value);
	end
end


-- clear all record to a given time. if curTime is nil, it will use the current time. 
function Actor:ClearRecordToTime(curTime)
	-- trim all keys to current time
	local curTime = curTime or self:GetTime();

	Actor._super.ClearRecordToTime(self, curTime);
	self.actor_block:ClearRecordToTime(curTime);
end

function Actor:SetControllable(bIsControllable)
	local entity = self:GetEntity()
	if(entity) then
		local obj = entity:GetInnerObject();
		if(obj) then
			obj:SetField("IsControlledExternally", not bIsControllable);
			obj:SetField("EnableAnim", not animate_by_script or bIsControllable);
		end
	end
end

-- whether the actor can create blocks. The camera actor can not create blocks
function Actor:CanCreateBlocks()
	return true;
end

-- this function is called whenver the create block task is called. i.e. the user has just created some block
function Actor:OnCreateBlocks(blocks)
	if(self:IsRecording())then
		self.actor_block:AddKeyFrameOfBlocks(blocks);
	end
end

-- this function is called whenver the destroy block task is called. i.e. the user has just destroyed some blocks
function Actor:OnDestroyBlocks(blocks)
	if(self:IsRecording())then
		self.actor_block:AddKeyFrameOfBlocks(blocks);
	end
end

function Actor:SaveStaticAppearance()
	local curTime = 0;
	local entity = self.entity;
	if(not entity or not curTime) then
		return
	end
	
	self:BeginUpdate();

	local obj = entity:GetInnerObject();
	if(obj) then
		local assetfile = obj:GetPrimaryAsset():GetKeyName();
		self:AutoAddKey("assetfile", curTime, PlayerAssetFile:GetNameByFilename(assetfile));
	end
	local skin = entity:GetSkin();
	if(skin) then
		self:AutoAddKey("skin", curTime, skin);
	end

	-- name property can not be animated and only save/replace the name key at frame 0. 
	local displayname = entity:GetDisplayName();
	if(displayname and displayname~="") then
		self:AddKey("name", 0, displayname);
		self:GetItemStack():SetTooltip(displayname);
	end

	self:EndUpdate();
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

function Actor:FrameMoveRecording(deltaTime)
	local curTime = self:GetTime();
	local entity = self.entity;
	if(not entity or not curTime) then
		return
	end
	entity:UpdatePosition();
	local x,y,z = entity:GetPosition();
	local skin = entity:GetSkin();
	
	self:BeginUpdate();

	self:AutoAddKey("x", curTime, x);
	self:AutoAddKey("y", curTime, y);
	self:AutoAddKey("z", curTime, z);
	if(skin) then
		self:AutoAddKey("skin", curTime, skin);
	end
	
	local obj = entity:GetInnerObject();

	if(obj) then
		obj:SetField("IsControlledExternally", false);
		obj:SetField("EnableAnim", true);

		local yaw = obj:GetField("yaw", 0);
		self:AutoAddKey("facing", curTime, yaw);
		local roll = obj:GetField("roll", 0);
		self:AutoAddKey("roll", curTime, roll);
		local pitch = obj:GetField("pitch", 0);
		self:AutoAddKey("pitch", curTime, pitch);
		local scaling = obj:GetScale();
		self:AutoAddKey("scaling", curTime, scaling);

		local anim = obj:GetField("AnimID", 0);
		if(anim > 1000) then
			anim = 0;
		end
		self:AutoAddKey("anim", curTime, anim);

		local HeadUpdownAngle = obj:GetField("HeadUpdownAngle", 0);
		self:AutoAddKey("HeadUpdownAngle", curTime, HeadUpdownAngle);

		local HeadTurningAngle = obj:GetField("HeadTurningAngle", 0);
		self:AutoAddKey("HeadTurningAngle", curTime, HeadTurningAngle);

		local speedscale = entity:GetSpeedScale();
		self:AutoAddKey("speedscale", curTime, speedscale);

		local gravity = obj:GetField("Gravity", 9.18);
		self:AutoAddKey("gravity", curTime, gravity);

		local blockinhand = entity:GetBlockInRightHand();
		self:AutoAddKey("blockinhand", curTime, blockinhand or 0);

		local assetfile = obj:GetPrimaryAsset():GetKeyName();
		self:AutoAddKey("assetfile", curTime, PlayerAssetFile:GetNameByFilename(assetfile));
	end
	self:EndUpdate();
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

-- make sure that the low level C++ attributes contains the latest value.
function Actor:UpdateAnimInstance()
	if(self:GetTime() ~= self.lastPlayTime) then
		local bIsUserControlled = self:IsUserControlled();
		self:FrameMovePlaying(0);
		if(bIsUserControlled) then
			self:SetControllable(bIsUserControlled);
		end
	end
	local bones = self:GetBonesVariable();
	if(bones) then
		bones:UpdateAnimInstance();
	end
end

-- in world coordinate system
-- @param boneName: name of the bone. if nil or "", it is the current actor's root position
-- @return x,y,z, roll, pitch yaw, scale: in world space.  
function Actor:ComputeBoneWorldTransform(bonename, bUseParentRotation)
	local link_x, link_y, link_z = self:GetEntity():GetPosition();
	if(bonename and bonename~="") then
		local bFoundTarget;
		self.parentPivot = self.parentPivot or mathlib.vector3d:new();
						
		local parentBoneRotMat;
		local bones = self:GetBonesVariable();
		local boneVar = bones:GetChild(bonename);
		if(boneVar) then
			self:UpdateAnimInstance();
			local pivot = boneVar:GetPivot(true);
			self.parentPivot:set(pivot);
			if(bUseParentRotation) then
				parentBoneRotMat = boneVar:GetPivotRotation(true);
			end
			bFoundTarget = true;
		end
		if(bFoundTarget) then
			local parentObj = self:GetEntity():GetInnerObject();
			local parentScale = parentObj:GetScale() or 1;
			local dx,dy,dz = 0,0,0;
			if(not bUseParentRotation and localPos) then
				self.parentPivot:add((localPos[1] or 0), (localPos[2] or 0), (localPos[3] or 0));
			end

			self.parentTrans = self.parentTrans or mathlib.Matrix4:new();
			self.parentTrans = parentObj:GetField("LocalTransform", self.parentTrans);
			self.parentPivot:multiplyInPlace(self.parentTrans);
			self.parentQuat = self.parentQuat or mathlib.Quaternion:new();
			if(parentScale~=1) then
				self.parentTrans:RemoveScaling();
			end
			self.parentQuat:FromRotationMatrix(self.parentTrans);
			if(bUseParentRotation and parentBoneRotMat) then
				self.parentPivotRot = self.parentPivotRot or Quaternion:new();
				self.parentPivotRot:FromRotationMatrix(parentBoneRotMat);
				self.parentQuat:multiplyInplace(self.parentPivotRot);
			end
			
			local p_roll, p_pitch, p_yaw = self.parentQuat:ToEulerAnglesSequence("zxy");
			
			local x, y, z = link_x + self.parentPivot[1] + dx, link_y + self.parentPivot[2] + dy, link_z + self.parentPivot[3] + dz
			-- This fixed a bug where x or y or z could be NAN(0/0), because GetPivotRotation and GetPivot could return NAN
			if(x == x and y==y and z==z) then
				return x, y, z, p_roll, p_pitch, p_yaw, parentScale;
			end
		end
	end
	return link_x, link_y, link_z;
end

-- get world transform of a given sub part (bone).
-- @param keypath: subpart of this actor of which we are computing, such as "bones::R_Hand", if nil it is current actor.
-- @param localPos: if not nil, this is the local offset
-- @param localRot: if not nil, this is the local rotation {roll, pitch yaw}
-- @param bUseParentRotation: use the parent rotation
-- @return x,y,z, roll, pitch yaw, scale: in world space.  
-- return nil, if such information is not available, such as during async loading.
function Actor:ComputeWorldTransform(keypath, curTime, localPos, localRot, bUseParentRotation)
	local link_x = self:GetValue("x", curTime);
	local link_y = self:GetValue("y", curTime);
	local link_z = self:GetValue("z", curTime);
	if(not link_x) then
		return
	end
	if(keypath and keypath~="") then
		local bFoundTarget;
		self.parentPivot = self.parentPivot or mathlib.vector3d:new();
						
		local bonename = keypath:match("^bones::(.+)");
		local parentBoneRotMat;
		if(bonename) then
			local bones = self:GetBonesVariable();
			local boneVar = bones:GetChild(bonename);
			if(boneVar) then
				self:UpdateAnimInstance();
				local pivot = boneVar:GetPivot(true);
				self.parentPivot:set(pivot);
				if(bUseParentRotation) then
					parentBoneRotMat = boneVar:GetPivotRotation(true);
				end
				bFoundTarget = true;
			end
		else
			self.parentPivot:set(0,0,0);
			bFoundTarget = true;
		end 
		if(bFoundTarget) then
			local parentObj = self:GetEntity():GetInnerObject();
			local parentScale = parentObj:GetScale() or 1;
			local dx,dy,dz = 0,0,0;
			if(not bUseParentRotation and localPos) then
				self.parentPivot:add((localPos[1] or 0), (localPos[2] or 0), (localPos[3] or 0));
			end

			self.parentTrans = self.parentTrans or mathlib.Matrix4:new();
			self.parentTrans = parentObj:GetField("LocalTransform", self.parentTrans);
			self.parentPivot:multiplyInPlace(self.parentTrans);
			self.parentQuat = self.parentQuat or mathlib.Quaternion:new();
			if(parentScale~=1) then
				self.parentTrans:RemoveScaling();
			end
			self.parentQuat:FromRotationMatrix(self.parentTrans);
			if(bUseParentRotation and parentBoneRotMat) then
				self.parentPivotRot = self.parentPivotRot or Quaternion:new();
				self.parentPivotRot:FromRotationMatrix(parentBoneRotMat);
				self.parentQuat:multiplyInplace(self.parentPivotRot);

				if(localRot) then
					self.localRotQuat = self.localRotQuat or Quaternion:new();
					self.localRotQuat:FromEulerAngles((localRot[3] or 0), (localRot[1] or 0), (localRot[2] or 0));
					self.parentQuat:multiplyInplace(self.localRotQuat);
				end

				--local az,ax,ay = self.parentQuat:ToEulerAnglesSequence("zxy");
				--local q = Quaternion:new():FromEulerAnglesSequence(az,ax,ay,"zxy");
				--echo({self.parentQuat, self.parentQuat:tostringAngleAxis(),"zxy--->", az,ax,ay, "angle, axis-->",q:tostringAngleAxis(), "-->", q})
				
				if(localPos) then
					self.localPos = self.localPos or mathlib.vector3d:new();
					self.localPos:set((localPos[1] or 0), (localPos[2] or 0), (localPos[3] or 0));
					self.localPos:rotateByQuatInplace(self.parentQuat);
					dx, dy, dz = self.localPos[1], self.localPos[2], self.localPos[3];
				end
			end
			
			local p_roll, p_pitch, p_yaw = self.parentQuat:ToEulerAnglesSequence("zxy");
			
			if(not bUseParentRotation and localRot) then
				-- just for backward compatibility, bUseParentRotation should be enabled in most cases
				p_roll = (localRot[1] or 0) + p_roll;
				p_pitch = (localRot[2] or 0) + p_pitch;
				p_yaw = (localRot[3] or 0) + p_yaw;
			end
			local x, y, z = link_x + self.parentPivot[1] + dx, link_y + self.parentPivot[2] + dy, link_z + self.parentPivot[3] + dz
			-- This fixed a bug where x or y or z could be NAN(0/0), because GetPivotRotation and GetPivot could return NAN
			if(x == x and y==y and z==z) then
				return x, y, z, p_roll, p_pitch, p_yaw, parentScale;
			end
		end
	else
		return link_x, link_y, link_z;
	end
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
				LOG.std(nil, "info", "ActorNPC", "parent bone may be async loading, wait 500ms");
				self.loader_timer:Change(500, nil);
			end
		end
	end
	if(self:IsAgentRelative()) then
		new_x, new_y, new_z = self:TransformToEntityPosition(new_x, new_y, new_z);
	end
	yaw = self:TransformToEntityFacing(yaw or 0);
	return new_x, new_y, new_z, yaw, roll, pitch;
end

function Actor:ComputeScaling(curTime)
	return self:GetValue("scaling", curTime) or 1;
end

function Actor:FrameMovePlaying(deltaTime)
	local curTime = self:GetTime();
	self.lastPlayTime = curTime;
	local entity = self.entity;
	if(not entity or not curTime) then
		return
	end
	-- allow adding keyframe while playing during the last segment. 
	local allow_user_control = self:IsAllowUserControl() and
		((self:GetMultiVariable():GetLastTime()+1) <= curTime);

	if(allow_user_control) then
		local obj = entity:GetInnerObject();
		if(obj) then
			obj:SetField("IsControlledExternally", false);
			obj:SetField("EnableAnim", true);
		end
		if(deltaTime ~= 0) then
			return;
		end
	end
	local obj = entity:GetInnerObject();
	local new_x, new_y, new_z, yaw, roll, pitch = self:ComputePosAndRotation(curTime);
	
	local HeadUpdownAngle, HeadTurningAngle, anim, skin, speedscale, scaling, gravity, opacity, blockinhand, assetfile, cam_dist;
	HeadUpdownAngle = self:GetValue("HeadUpdownAngle", curTime);
	HeadTurningAngle = self:GetValue("HeadTurningAngle", curTime);
	anim = self:GetValue("anim", curTime);
	skin = self:GetValue("skin", curTime);
	speedscale = self:GetValue("speedscale", curTime);
	scaling = self:ComputeScaling(curTime);
	gravity = self:GetValue("gravity", curTime);
	opacity = self:GetValue("opacity", curTime);
	assetfile = self:GetValue("assetfile", curTime);
	blockinhand = self:GetValue("blockinhand", curTime);
	cam_dist = self:GetValue("cam_dist", curTime);

	self:GetBonesVariable():AutoEnableBonesAtTime(curTime);
	
	if(obj) then
		if(cam_dist) then
			obj:SetField("ObjectToCameraDistance", cam_dist);
		end

		-- in case of explicit animation
		obj:SetField("yaw", yaw or 0);
		obj:SetField("roll", roll or 0);
		obj:SetField("pitch", pitch or 0);

		if(new_x) then
			entity:SetPosition(new_x, new_y, new_z);
		end
		
		-- this may cause animation instance to lose all custom bones, Time and EnableAnim properties. 
		if(entity:SetMainAssetPath(PlayerAssetFile:GetFilenameByName(assetfile))) then
			self:assetfileChanged();
		end
		entity:SetSkin(skin);
		entity:SetBlockInRightHand(blockinhand);

		obj:SetField("Time", curTime); 
		obj:SetField("IsControlledExternally", true);
		obj:SetField("EnableAnim", not animate_by_script);


		if(anim) then
			if(anim~=obj:GetField("AnimID", 0)) then
				obj:SetField("AnimID", anim);
			end
			if(animate_by_script) then
				local var = self:GetVariable("anim");
				if(var) then
					-- get the time when model assetfile just takes effect. 
					local start_time = 0;
					local varAssetFile = self:GetVariable("assetfile");
					if(varAssetFile and varAssetFile:GetKeyNum()>1) then
						start_time = varAssetFile:getStartTime(1, curTime);
						if(varAssetFile:GetFirstTime() == start_time) then
							start_time = 0;
						end
					end
					-- get the time, when the animation is first started
					local fromTime = var:getStartTime(1, curTime);
					local localTime = curTime;
					if(var:GetFirstTime() == fromTime) then
						-- force looping from first frame
						fromTime = start_time;
					elseif(fromTime < start_time) then
						-- in case the asset model is changed, the start time is relative to the asset model. 
						fromTime = start_time;
					end

					localTime = curTime - fromTime;
					-- calculate speedscale? 
					local varSpeed = self:GetVariable("speedscale");
					if(varSpeed and varSpeed:GetKeyNum()>1) then
						local fromTimeSpeed, toTimeSpeed = varSpeed:getTimeRange(1, fromTime);
						if(toTimeSpeed >= curTime) then
							localTime = localTime * (speedscale or 1);
						else
							-- we need more calculations, here:  localtime = Sigma_sum{delta_time*speedscale(time)}
							local totalScaledTime = 0;
							local calculatedTime = fromTime;
							local lastTime, lastValue;
							for time, v in varSpeed:GetKeys_Iter(1, fromTimeSpeed-1, curTime) do
								local dt = time - calculatedTime;
								if(dt > 0) then
									totalScaledTime = totalScaledTime + dt * (lastValue or v);
									calculatedTime = time;
								end
								lastTime = time;
								lastValue = v;
							end
							if(curTime > calculatedTime) then
								totalScaledTime = totalScaledTime + (curTime - calculatedTime) * speedscale;
							end
							localTime = totalScaledTime;
						end
					else
						localTime = localTime * (speedscale or 1);
					end
					obj:SetField("AnimFrame", localTime);
					local default_blending_time = 250;
					if( localTime < default_blending_time and 
						-- if this the first animation, set it without using a blending factor. 
						fromTime ~= 0) then
						obj:SetField("BlendingFactor", 1 - localTime / default_blending_time);
					else
						-- this is actually already set in obj:SetField("AnimFrame", localTime); so no need to set again. 
						-- obj:SetField("BlendingFactor", 0);
					end
				end
			else
				if(curTime < 500) then
					-- if this the first animation, set it without using a blending factor. 
					obj:SetField("BlendingFactor", 0);
				end
			end
		end

		obj:SetField("HeadUpdownAngle", HeadUpdownAngle or 0);
		obj:SetField("HeadTurningAngle", HeadTurningAngle or 0);
		
		entity:SetSpeedScale(speedscale or 1);
		obj:SetField("Speed Scale", speedscale or 1);
		obj:SetScale(scaling or 1);
		
		if(gravity) then
			obj:SetField("Gravity", gravity);
		end
		obj:SetField("opacity", opacity or 1);
	end

	self.actor_block:FrameMovePlaying(deltaTime);
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

-- bone selection changed in editor
function Actor:OnChangeBone(bone_name)
	local var = self:GetBonesVariable();
	if(var) then
		var:SetSelectedBone(bone_name);
		-- signal
		self:keyChanged();
	end
end

-- set the local bone time
-- @param boneName: a precise bone name or regular expression, like "hand" or ".*hand"
-- @param time: if nil or -1, it will remove bone time. 
function Actor:SetBoneTime(boneName, time)
	local var = self:GetBonesVariable();
	if(var) then
		local variables = var:GetVariables();
		if(variables[boneName]) then
			variables[boneName]:SetTime(time);
		else
			for name, bone in pairs(variables) do
				if(name:match(boneName)) then
					bone:SetTime(time);
				end
			end
		end
	end
end

function Actor:DestroyEntity()
	if(self:IsAgent() and self.entity) then
		self:ReleaseEntityControl();
	end
	Actor._super.DestroyEntity(self)
	if(self.bones_variable) then
		self:Disconnect("dataSourceChanged", self.bones_variable, self.bones_variable.LoadFromActor)
		self:Disconnect("assetfileChanged", self.bones_variable, self.bones_variable.OnAssetFileChanged)
		self.bones_variable = nil;
	end
end

function Actor:UnbindAnimInstance()
	if(self.bones_variable) then
		self:Disconnect("dataSourceChanged", self.bones_variable, self.bones_variable.LoadFromActor)
		self:Disconnect("assetfileChanged", self.bones_variable, self.bones_variable.OnAssetFileChanged)
		self.bones_variable:UnbindAnimInstance();
		self.bones_variable = nil;
	end
end

function Actor:BecomeAgent(entity)
	Actor._super.BecomeAgent(self, entity);
	self:CheckLoadBonesAnims();
end

-- when deactivated we will release the control to human player with this function.
function Actor:ReleaseEntityControl()
	self:SetControllable(true);
	self:UnbindAnimInstance();
end

