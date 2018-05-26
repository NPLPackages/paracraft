--[[
Title: Base entity object in in block physical world
Author(s): LiXizhi
Date: 2013/1/23
Desc: Entity is anything that is not a block in the 3d scene, such as players and NPC. 
Each entity can contain a command list, a rule bag, and an inventory bag. 
Generally they are used for: 
   * command list: string list components of the entity
   * rule bag: item logics that handles input/output of the entity. 
   * inventory bag: assets that defines the look of the entity or custom settings used by rules. 
Yet, how above components is actually used is up to each entity derived class. 

virtual functions related to input/output logics: 
	FrameMove(deltaTime) called when sentient (within view radius of sentient players)
	OnActivated(triggerEntity)
	LoadFromXMLNode(node)   serializer
	SaveToXMLNode(node)		serializer
	OnClick(x, y, z, mouse_button)   event

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/Entity.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local entity = MyCompany.Aries.Game.EntityManager.Entity:new({x,y,z,radius});
entity:Attach();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/DataContainer.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Physics/DynamicObject.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/TimedEvent.lua");
NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)script/ide/math/ShapeAABB.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/EntityAnimation.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Variables.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/ObtainItemEffect.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Ticks.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/InventoryBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ContainerView.lua");
NPL.load("(gl)script/ide/headon_speech.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/DataWatcher.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Packets/PacketEntityEffect.lua");
local Packets = commonlib.gettable("MyCompany.Aries.Game.Network.Packets");
local DataWatcher = commonlib.gettable("MyCompany.Aries.Game.Common.DataWatcher");
local ContainerView = commonlib.gettable("MyCompany.Aries.Game.Items.ContainerView");
local InventoryBase = commonlib.gettable("MyCompany.Aries.Game.Items.InventoryBase");
local Ticks = commonlib.gettable("MyCompany.Aries.Game.Common.Ticks");
local ObtainItemEffect = commonlib.gettable("MyCompany.Aries.Game.Effects.ObtainItemEffect");
local Variables = commonlib.gettable("MyCompany.Aries.Game.Common.Variables");
local EntityAnimation = commonlib.gettable("MyCompany.Aries.Game.Effects.EntityAnimation");
local vector3d = commonlib.gettable("mathlib.vector3d");
local ShapeAABB = commonlib.gettable("mathlib.ShapeAABB");
local TimedEvent = commonlib.gettable("MyCompany.Aries.Game.TimedEvent")
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");
local DataContainer = commonlib.gettable("MyCompany.Aries.Game.EntityManager.DataContainer")
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ObjEditor = commonlib.gettable("ObjEditor");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");

local Entity = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.Entity"));

Entity:Property({"position", nil, "getPosition", "setPosition"});

Entity:Signal("focusIn");
Entity:Signal("focusOut");
Entity:Signal("valueChanged");


local math_abs = math.abs;

Entity.is_stopped = nil;
-- dummy entity will not fire collision event
Entity.is_dummy = nil;
Entity.is_persistent = nil;
-- whether this entity can be synchronized on the network by EntityTrackerEntry. 
Entity.isServerEntity = nil;
Entity.class_name = "entity";
-- enable frame move in seconds
Entity.framemove_interval = nil;
-- Reduces the velocity applied by entity collisions by the specified percent.
Entity.entityCollisionReduction = 0.3;
-- true to continue movement on collision, otherwise it will stop all movement once in collision. 
Entity.bContinueMoveOnCollision = true;
-- How high this entity can step up when running into a block to try to get over it 
Entity.stepHeight = 0;
-- Which dimension the player is in. 1 for default. */
Entity.dimension = 1;
-- whether this entity should be trackered by all players in the world regardless of player distance to this entity. 
-- this used for global server side entity. 
Entity.bIsGloballyTracked = nil;
-- server position scaled by 32 integer. 
Entity.serverPosX, Entity.serverPosY,Entity.serverPosZ = 0,0,0;

local next_id = 0;
-- @param x,y,z: initial real world position. 
-- @param radius: the half radius of the object. 
function Entity:ctor()
	next_id = next_id + 1;
	self.entityId = next_id;
end

-- this function can only be called before entity is attached, such as in Init() function. 
-- e.g. when that server and client need to share same id
function Entity:SetEntityId(id)
	if(id) then
		self.entityId = id;
		-- this ensures that entity
		if(next_id < id) then
			next_id = id;
		end
	end
end

-- when entity is focused, this is the additional camera roll applied.
function Entity:GetCameraRoll()
	return self.camera_roll or 0;
end

function Entity:SetCameraRoll(roll)
	self.camera_roll = roll;
end

-- all kinds of custom user or game event, that is handled mostly by rule bag items.
-- Entity event is the only source of inputs to the containing rule bag items, which the user can customize using ItemCommand, ItemScript, etc. 
-- In the big picture, event forms a dynamic and user configurable network of connections among entities and rule bag items. 
-- Items in rule bags are executed in sequence, until one of them accept the event. 
-- Some events are system buildin events that is fired automatically by the system like like mousePressEvent, mouseReleaseEvent, worldLoadedEvent, blockTickEvent, timerEvent, etc. 
-- Custom events may be sent to any entity via /sendevent command to achieve any user defined world logics. 
function Entity:event(event)
	if(self:IsInputDisabled()) then
		-- do nothing if not enabled. 
	else
		if(self.rulebag) then
			for i = 1, self.rulebag:GetSlotCount() do
				local itemStack = self.rulebag:GetItem(i);
				if(itemStack) then
					if(itemStack:handleEntityEvent(self, event)) then
						if(event:isAccepted()) then
							return;
						end
					end
				else
					break;
				end
			end
		end
		local event_type = event:GetType();
		local func = self[event:GetHandlerFuncName()];
		if(type(func) == "function") then
			func(self, event);
		end
	end
end

-- static method
function Entity:GetType()
	return self.class_name;
end

-- static method: recursively check if entity is derived from a given type.
-- @param class_name: if nil, it will always return true. 
function Entity:IsOfType(class_name)
	return class_name==nil or self.class_name == class_name or (self._super and self._super.IsOfType and self._super:IsOfType(class_name));
end

function Entity:Reset()
	self.isDead = nil;
	if(self.lifetime and self.lifetime < 0) then
		self.lifetime = nil;
	end
end		

-- return true if the entity is controlled remotely by the server. 
-- i.e. whether this entity is a client proxy of server entity. 
function Entity:IsRemote()
	return GameLogic.isRemote and not self.bIsLocal;
end

-- set whether this entity is a local entity even the game logic is in remote mode. 
-- @sa self:IsRemote().
function Entity:SetLocal(bForceLocal)
	self.bIsLocal = bForceLocal;
end

-- created on demand for editors
function Entity:GetEditModel()
	if(self.editmodel) then
		return self.editmodel;
	else
		NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/Entity.EditModel.lua");
		local EntityEditModel = commonlib.gettable("MyCompany.Aries.Game.EditModels.EntityEditModel")
		self.editmodel = EntityEditModel:new():init(self);
		return self.editmodel;
	end
end

-- get the inventory object if any
function Entity:GetInventory()
	return self.inventory;
end

-- get the inventory view object if any. It will create one if inventory exist but view not exist. 
function Entity:GetInventoryView()
	if(self.inventoryView) then
		return self.inventoryView;
	elseif(self.inventory) then
		self.inventoryView = ContainerView:new():Init(self.inventory);
		return self.inventoryView;
	end
end

-- whether the entity should be serialized to disk. 
function Entity:SetPersistent(bIsPersistent)
	self.is_persistent = bIsPersistent;
end

-- whether automatically advance local time of current animation id. true by default. 
-- Maybe set to false during movie actor action playback 
function Entity:EnableAnimation(bEnable)
	local obj = self:GetInnerObject();
	if(obj) then
		obj:SetField("EnableAnim", bEnable);
	end
end

function Entity:IsBiped()
end

-- whether it will check for collision detection 
function Entity:SetDummy(bIsDummy)
	self.is_dummy = bIsDummy;
end

-- whether it will check for collision detection 
function Entity:IsDummy()
	return self.is_dummy;
end



function Entity:FaceTarget(x,y,z)
end

function Entity:ToggleFly(bFly)
end

-- Sets the reference to the World object.
function Entity:SetWorld(world)
    self.worldObj = world;
end

-- load from an xml node. 
function Entity:LoadFromXMLNode(node)
	if(node) then
		local attr = node.attr;
		if(attr) then
			if(attr.bx) then
				self.bx = self.bx or tonumber(attr.bx);
				self.by = self.by or tonumber(attr.by);
				self.bz = self.bz or tonumber(attr.bz);
			end
			if(attr.x) then
				self.x = tonumber(attr.x);
				self.y = tonumber(attr.y);
				self.z = tonumber(attr.z);
			end
			if(attr.name) then
				self.name = attr.name;
			end
			if(attr.facing) then
				self.facing = tonumber(attr.facing);
			end
			if(attr.anim and attr.anim~="") then
				self.anim = attr.anim;
			end

			local item_id = tonumber(attr.item_id);
			if(item_id == 0) then
				item_id = nil;
			end
			self.item_id = item_id or self.item_id;

			if(attr.lifetime) then
				self.lifetime = tonumber(attr.lifetime);
			end

			if(attr.displayName) then
				self.displayName = attr.displayName;
			end
		end

		for i=1, #node do
			sub_node = node[i];
			if(sub_node.name == "mem") then
				local code_str = sub_node[1]
				if(code_str and type(code_str) == "string") then
					self.memory = NPL.LoadTableFromString(code_str);
				end
			elseif(sub_node.name == "cmd") then
				local cmd = sub_node[1]
				if(cmd) then
					if(type(cmd) == "string") then
						self.cmd = cmd;
					elseif(type(cmd) == "table" and type(cmd[1]) == "string") then
						-- just in case cmd.name == "![CDATA["
						self.cmd = cmd[1];
					end
				end
			elseif(sub_node.name == "inventory" and self.inventory) then
				self.inventory:LoadFromXMLNode(sub_node);
			elseif(sub_node.name == "rulebag" and self.rulebag) then
				self.rulebag:LoadFromXMLNode(sub_node);
			end
			--elseif(sub_node.name == "data") then
			--self:GetDataContainer():LoadFromXMLNode(sub_node);
		end
	end
end

-- get the variable class. 
function Entity:GetVariables()
	return self.variables;
end

function Entity:SaveToXMLNode(node, bSort)
	node = node or {name='entity', attr={}};
	local attr = node.attr;
	attr.class = self.class_name;
	attr.item_id = self.item_id;
	attr.bx, attr.by, attr.bz  = self.bx, self.by, self.bz;
	attr.name = self.name;
	attr.facing = self.facing;
	if(self.lifetime) then
		attr.lifetime = self.lifetime;
	end
	if(self.displayName and self.displayName~="") then
		attr.displayName = self.displayName;
	end
	if(self.anim) then
		attr.anim = self.anim;
	end
	if(self.memory and next(self.memory)) then
		node[#node+1] = {name="mem", [1]=commonlib.serialize_compact(self.memory, bSort)};
	end
	if(self.cmd and self.cmd~="") then
		if(commonlib.Encoding.HasXMLEscapeChar(self.cmd)) then
			node[#node+1] = {name="cmd", [1]={name="![CDATA[", [1] = self.cmd}};
		else
			node[#node+1] = {name="cmd", [1] = self.cmd};
		end
	end

	if(self.inventory and not self.inventory:IsEmpty()) then
		node[#node+1] = self.inventory:SaveToXMLNode({name="inventory"}, bSort);
	end
	if(self.rulebag and not self.rulebag:IsEmpty()) then
		node[#node+1] = self.rulebag:SaveToXMLNode({name="rulebag"}, bSort);
	end

	--if(self.data_container and not self.data_container:IsEmpty()) then
		--local data_node = {name="data",};
		--node[#node+1] = data_node;
		--self.data_container:SaveToXMLNode(data_node);
	--end
	return node;
end

-- let the camera focus on this player and take control of it. 
-- @note: please note if this return nil, and does not call EntityManager.SetFocus(), OnFocusIn and OnFocusOut will never be called
-- @return return true if focus can be set
function Entity:SetFocus()
end

function Entity:HasFocus()
	return self.has_focus;
end

-- called after focus is set
function Entity:OnFocusIn()
	self.has_focus = true;
	local obj = self:GetInnerObject();
	if(obj) then
		if(obj.ToCharacter) then
			obj:ToCharacter():SetFocus();
		end
		-- make it normal movement style
		obj:SetField("MovementStyle", 0)
		obj:SetField("SkipPicking", true);
	end
	self:focusIn();
end

-- called before focus is lost
function Entity:OnFocusOut()
	self.has_focus = nil;
	local obj = self:GetInnerObject();
	if(obj) then
		-- make it linear movement style
		obj:SetField("MovementStyle", 3);
		obj:SetField("SkipPicking", false);
	end
	self:focusOut();
end

function Entity:SetVisible(bVisible)
	local obj = self:GetInnerObject();
	if(obj) then
		obj:SetVisible(bVisible == true);
		self.visible = bVisible == true;
	end
end

function Entity:IsVisible()
	return self.visible ~= false;
end

function Entity:IsFlying()
end

function Entity:IsRunning()
end

function Entity:ToggleRunning()
end

function Entity:GetSpeedScale()
	return self.speedscale or 1;
end

-- take running and flying into account. 
function Entity:GetCurrentSpeedScale()
	local speedscale = self:GetSpeedScale();
	if(not self.has_focus) then
		return speedscale;
	else
		if(self:IsFlying()) then
			return speedscale * 3;
		elseif(self:IsRunning()) then
			return speedscale * 1.3;
		else
			return speedscale;
		end
	end
end

function Entity:GetWalkSpeed()
	return self.speed or 4.0;
end

function Entity:SetWalkSpeed(speed)
	self.speed = speed;
end

function Entity:SetSpeedScale(value)
	self.speedscale = value;
end

function Entity:GetJumpupSpeed()
	return GameLogic.options.jump_up_speed;
end

function Entity:CanReachBlockAt(x,y,z, mode)
	return true;
end

-- whether the entity can be teleported to another place, by teleport stone for instance. 
function Entity:CanTeleport()
	return false;
end


-- usually holding shift key will toggle to walk mode. 
-- @param bWalking: if nil it will toggle. if true, it will force walk or run. 
function Entity:ToggleWalkRun(bWalking)
	local obj = self:GetInnerObject();
	if(obj and obj.ToCharacter) then
		local char = obj:ToCharacter();
		if(char:IsValid())then
			if(bWalking==false or (bWalking == nil and char:WalkingOrRunning())) then
				char:AddAction(action_table.ActionSymbols.S_ACTIONKEY, action_table.ActionKeyID.TOGGLE_TO_RUN);
			else
				char:AddAction(action_table.ActionSymbols.S_ACTIONKEY, action_table.ActionKeyID.TOGGLE_TO_WALK);
			end	
		end
	end
end

-- enable internel mesh level of details if any. 
function Entity:EnableLOD(bEnable)
	local obj = self:GetInnerObject();
	if(obj) then
		obj:SetField("IsLodEnabled", bEnable == true);
	end
end

function Entity:IsLODEnabled()
	local obj = self:GetInnerObject();
	if(obj) then
		return obj:GetField("IsLodEnabled", true)
	end
	return true;
end

-- all entity default to running (not walking). 
function Entity:IsWalking()
	local obj = self:GetInnerObject();
	if(obj and obj.ToCharacter) then
		local char = obj:ToCharacter();
		if(char:IsValid())then
			return char:WalkingOrRunning();
		end
	end
end

-- build animation sequence table to be fed to entity. 
-- @param filenames: can be filename, animation name, animation id or array of above things. currently only two animation is supported. 
-- such as {4,0} 
function Entity:SetAnimation(filenames)
	self.anim = filenames;
	local anims;
	local input_type = type(filenames);
	if(input_type == "string") then
		anims = EntityAnimation.CreateGetAnimId(filenames,self);
	elseif(input_type == "number") then
		anims = filenames;
	elseif(input_type == "table") then	
		local _, filename
		for _, filename in ipairs(filenames) do
			local nAnimID = EntityAnimation.CreateGetAnimId(filename,self);
			if(nAnimID and nAnimID>=0) then
				anims = anims or {};
				anims[#anims + 1] = nAnimID;
			end	
		end
	end	
	local player = self:GetInnerObject();
	if(player) then
		if(type(anims) == "number") then
			self.lastAnimId = anims;
			player:SetField("AnimID", anims);
		else
			self.lastAnimId = nil;
			player:SetField("HeadTurningAngle", 0);
			if(player.ToCharacter) then
				player:ToCharacter():PlayAnimation(anims);	
			end
		end
	end
end

-- get last animation id. this may return nil, which usually mean 0.
function Entity:GetLastAnimId()
	return self.lastAnimId;
end


-- enable headon display
function Entity:ShowHeadOnDisplay(bShow)
end

function Entity:IsShowHeadOnDisplay()
end

-- add stat
function Entity:AddStat(id, delta_count)
end
-- get object params table to create the portait in entity dialog. 
-- @param bForceRefresh: if true, it will fetch again from innerObject. 
function Entity:GetPortaitObjectParams(bForceRefresh)
	if(not self.obj_params or bForceRefresh) then
		local obj = self:GetInnerObject();
		local params;
		if(obj) then
			params = ObjEditor.GetObjectParams(obj);

			if(not params.ReplaceableTextures and params.IsCharacter) then
				local filename = obj:GetReplaceableTexture(2):GetFileName();
				if(filename ~= "") then
					params.ReplaceableTextures = {[2]=filename };
				end
			end
		else
			params = {
				AssetFile = "",
			};
		end
		params.name = "portrait";
		params.x = 0;
		params.y = self.offsetY or 0;
		params.z = 0;
		params.facing = 1.57;
		params.Attribute = 128;
		params.scaling = 1; -- use default scaling
		
		self.obj_params = params;
	end
	return self.obj_params;
end

-- this is helper function that derived class can use to create an inner mesh or character object. 
function Entity:CreateInnerObject(filename, isCharacter, offsetY, scaling)
	local x, y, z = self:GetPosition();

	local obj = ObjEditor.CreateObjectByParams({
		name = format("%d,%d,%d", self.bx or 0, self.by or 0, self.bz or 0),
		IsCharacter = isCharacter,
		AssetFile = filename,
		x = x,
		y = y + (offsetY or 0),
		z = z,
		scaling = scaling, 
		facing = self.facing,
		IsPersistent = false,
		EnablePhysics = false,
	});
	if(obj) then
		-- MESH_USE_LIGHT = 0x1<<7: use block ambient and diffuse lighting for this model. 
		obj:SetAttribute(128, true);
		-- OBJ_SKIP_PICKING = 0x1<<15:
		obj:SetAttribute(0x8000, true);
		obj:SetField("progress", 1);
		-- obj:SetField("persistent", false); 
		-- obj:SetScale(BlockEngine.blocksize);
		obj:SetField("RenderDistance", 160);
		self:SetInnerObject(obj);
		ParaScene.Attach(obj);	
	end
	return obj;
end

-- this is helper function that derived class can use to destroy an inner mesh or character object. 
function Entity:DestroyInnerObject()
	local obj = self:GetInnerObject();
	if(obj) then
		ParaScene.Delete(obj);
		self.obj = nil;
		self.obj_id = nil;
	end
end

-- this is called on each tick, when this entity has focus and user is pressing and holding shift key. 
function Entity:OnShiftKeyPressed()
end

-- this is called, when this entity has focus and user is just released the shift key. 
function Entity:OnShiftKeyReleased()
end

function Entity:Jump()
	local obj = self:GetInnerObject();
	if(obj) then
		if( obj:GetField("MovementStyle", 0) == 3) then
			local x, y, z = self:GetPosition();
			self:SetPosition(x, y+0.1, z);
		else
			local char = ParaScene.GetPlayer():ToCharacter();
			if(char:IsValid())then
				char:AddAction(action_table.ActionSymbols.S_JUMP_START, self.jump_up_speed or GameLogic.options.jump_up_speed);
			end
		end
	end
end

-- @param value: if nil, it will use the global gravity. 
function Entity:SetGravity(value)
	self.gravity = value;
end

function Entity:GetGravity()
	return self.gravity or GameLogic.options:GetGravity();
end

-- get data container. 
function Entity:GetDataContainer()
	if(self.data_container) then
		return self.data_container;
	else
		self.data_container = DataContainer:new();
		return self.data_container;
	end
end

-- whether its persistent. 
function Entity:IsPersistent()
	return self.is_persistent;
end

-- virtual function: handle some external input. 
-- default is do nothing. return true is something is processed. 
function Entity:OnActivated(triggerEntity)
	if(self == triggerEntity) then
		self:ActivateRules(triggerEntity);
	end
end

-- if true, always serialize to 512*512 regional entity file
-- block based entity has this set to true. 
function Entity:IsRegional()
	return self.is_regional;
end

-- virtual function: 
function Entity:init()
	return self;
end

-- player entity collided with this entity
function Entity:OnCollideWithPlayer(from_entity, bx,by,bz)
end

-- virtual function: when the entity is hit (attacked) by the missile
function Entity:OnHit(attack_value, fromX, fromY, fromZ)
end

-- virtual function:
function Entity:OnClick(x,y,z, mouse_button,entity,side)
end

function Entity:GetBlockId()
	return self.item_id or self.block_id;
end

-- return a table array containing all commands or comments. 
function Entity:GetCommandTable()
	local out;
	local text = self.cmd;
	if(type(text) == "string") then
		for cmd in string.gmatch(text, "([^\r\n]+)") do
			out = out or {};
			out[#out + 1] = cmd;
		end
	end
	return out;
end

-- set command table
function Entity:SetCommandTable(commands)
	if(type(commands) == "table") then
		self.cmd = table.concat(commands, "\n");
	else
		self.cmd = nil;
	end
end

-- get latest command list. comments is empty line
-- it will cache last parsed result
function Entity:GetCommandList()
	if(self.cmd) then
		if(not self.cmd_list or self.cmd_list.src ~= self.cmd) then
			self.cmd_list = CommandManager:GetCmdList(self.cmd)
			self.cmd_list.src = self.cmd;
			return self.cmd_list;
		else
			return self.cmd_list;
		end
	end
end

-- bool: whether has command panel
function Entity:HasCommand()
	return true;
end

-- the title text to display (can be mcml)
function Entity:GetCommandTitle()
end

-- bool: whether show the rule panel
function Entity:HasRule()
	return false;
end

-- the title text to display (can be mcml)
function Entity:GetRuleTitle()
end

-- This function is called manually. Such as during OnActivated().
-- @param triggerEntity: this is the triggering player or sometimes the entity itself if /activate self is used. 
function Entity:ActivateCommands(triggerEntity)
	if(not self.cmd) then
		return;
	end

	-- clear all time event
	self:ClearTimeEvent();

	-- just in case the command contains variables. 
	local variables = (triggerEntity or self):GetVariables();
	local last_result;
	local cmd_list = self:GetCommandList();
	if(cmd_list) then
		last_result = CommandManager:RunCmdList(cmd_list, variables, self);
	end
end

-- this function is called automatically when this entity is activated. 
-- override this function to change behavior.
-- build, reload and activate all rules in the self.rulebag
function Entity:ActivateRules(triggerEntity)
	if(self.rulebag) then
		-- clear all time event
		self:ClearTimeEvent();

		for i = 1, self.rulebag:GetSlotCount() do
			local itemStack = self.rulebag:GetItem(i);
			if(itemStack) then
				itemStack:OnActivate(self, self);
			else
				break;
			end
		end
	end
end

-- bool: whether show the bag panel
function Entity:HasBag()
	return false;
end

-- the title text to display (can be mcml)
function Entity:GetBagTitle()
end


-- virtual function:
function Entity:SetDisplayName(v)
	self.displayName = v;
end

function Entity:GetDisplayName()
	return self.displayName;
end

-- internal name 
function Entity:SetName(v)
	if(self.name~=v) then
		local old_name = self.name;
		self.name = v;
		EntityManager.RenameEntity(self, old_name, v);
	end
end

function Entity:GetName()
	return self.name;
end

-- virtual function:
function Entity:SetCommand(cmd)
	self.cmd = cmd;
end

function Entity:GetCommand()
	return self.cmd;
end

-- virtual function
function Entity:Refresh()
end

-- static function: in the Destroy function, the entity are recollected
function Entity:CreateFromPool()
	local pool_manager = EntityPool:CreateGet(self);
	return pool_manager:CreateEntity();
end

-- factory class to create an instance of the entity 
function Entity:Create(o, xml_node)
	o = self:new(o);
	if(xml_node) then
		o:LoadFromXMLNode(xml_node);
	end
	return o:init();
end

function Entity:SetInnerObject(obj)
	if(obj) then
		self.obj = obj;
		self.obj_id = obj:GetID();
	end
end

-- get the ParaObject from self.obj_id. 
-- performace optimized: since we will cache obj in self.obj on first call. 
-- and use ParaScene.CheckExist to check validity on subsequent calls, which is LuaJit optimized. 
-- thus calling this function each frame is fine. 
function Entity:GetInnerObject()
	local obj = self.obj;
	if(obj and obj:IsValid()) then
		return obj;
	elseif(self.obj_id) then
		if(ParaScene.CheckExist(self.obj_id)) then
			local obj = ParaScene.GetObject(self.obj_id);
			self.obj = obj;
			return obj;
		else
			self.obj = nil;
			self.obj_id = nil;
		end
	end
end

function Entity:GetObjID()
	if(self.obj_id) then
		return self.obj_id;
	elseif(self.obj) then
		self.obj_id = self.obj:GetID();
		return self.obj_id;
	end
end

-- obsoleted, use SetInnerObject instead
function Entity:SetObjID(id)
	LOG.std(nil, "error", "Entity:SetObjID", "obsoleted function. use SetInnerObject() instead");
	self.obj_id = id;
	self.obj = nil;
end

function Entity:GetOpacity()
	return self.opacity or 1;
end		

function Entity:SetOpacity(value)
	self.opacity = value;
end		

-- get the associated item class. 
function Entity:GetItemClass()
	if(self.item_id and self.item_id>0) then
		return ItemClient.GetItem(self.item_id);
	end
end		

-- get the associated block template class. 
function Entity:GetBlock()
	if(self.block) then
		return self.block;
	elseif(self.item_id or self.block_id) then
		self.block = block_types.get(self.item_id or self.block_id);
	end
	return self.block;
end		

-- set as dead and will be destroyed in the next framemove.
function Entity:SetDead()
	self.isDead = true;
end

function Entity:IsDead()
	return self.isDead;
end

function Entity:Destroy()
	if(self.physic_obj) then
		self.physic_obj:Destroy();
		self.physic_obj = nil;
	end
	self:Detach();
	if(self.pool_manager) then
		self.pool_manager:RecollectEntity(self);
	end
end

-- detach from entity manager
function Entity:Detach()
	if(self:IsAlwaysSentient()) then
		self:SetAlwaysSentient(nil);
	end
	if(self.block_container) then
		self.block_container:Remove(self);
	end
	if(self:IsRegional()) then
		local region = EntityManager.GetRegionContainer(self.bx, self.bz);
		region:Remove(self)
	end
	EntityManager.RemoveObject(self);
	
end

-- virtual, called when this entity is removed from EntityManager, either detached or during world exit.
-- this function is also called when entity is destroyed if it is attached to EntityManager.
function Entity:OnRemoved()
end

function Entity:GetWorldServer()
    return GameLogic.GetWorld();
end

-- let the entity say something on top of its head for some seconds. 
-- @param text: text to show
-- @param duration: in seconds. default to 4
-- @param bAbove3D: default to nil, if true, headon UI will be displayed above all 3D objects. if false or nil, it just renders the UI with z buffer test enabled. 
-- return true if we actually said something, otherwise nil.
function Entity:Say(text, duration, bAbove3D)
	if(text and text~="") then
		if(GameLogic.isServer and self:IsServerEntity()) then
			local packet = Packets.PacketEntityFunction:new():Init(self, "say", {text=text, duration=duration, bAbove3D=bAbove3D});
			self:GetWorldServer():GetEntityTracker():SendPacketToAllPlayersTrackingEntity(self, packet)
		end
		local obj = self:GetInnerObject();
		if(obj) then
			headon_speech.Speek(obj, text, duration or 4, bAbove3D);
			return true;
		end
	else
		local obj = self:GetInnerObject();
		if(obj) then
			headon_speech.SpeakClear(obj);
		end
	end
end

-- attach to entity manager
function Entity:Attach()
	if(self:IsAlwaysSentient()) then
		EntityManager.AddToSentientList(self);
	end
	EntityManager.AddObject(self);
	self:UpdateBlockContainer();
end

-- virtual function: whether we can place a block where this entity stands in. 
-- in most cases, this is false, unless the entity is wise enough to move around to other free spaces. 
function Entity:canPlaceBlockAt(x,y,z, block)
	return (not block or not block.obstruction);
end

-- when ever an event is received. 
function Entity:OnBlockEvent(x,y,z, event_id, event_param)
end

--virtual function:
function Entity:SetScaling(v)
	local obj = self:GetInnerObject();
	if(obj) then
		self.scaling = v;
		obj:SetScale(v);
	end
end

function Entity:GetScaling(v)
	local obj = self:GetInnerObject();
	if(obj) then
		self.scaling = obj:GetScale(v);
	end
	return self.scaling or 1;
end

--virtual function:
function Entity:SetScalingDelta(v)
	
end

--virtual function:
function Entity:SetFacingDelta(v)
end

-- set facing of the lower object. 
function Entity:SetFacing(facing)	
	local obj = self:GetInnerObject();
	if(obj) then
		self.facing = facing;
		obj:SetFacing(facing);
	end
end

function Entity:GetFacing()	
	return self.facing or 0;
end


function Entity:PlaySound(sound_name)
end

function Entity:IsServerEntity()
	return self.isServerEntity;
end

-- virtual function: right click to edit. 
function Entity:OpenEditor(editor_name, entity)
	-- TODO: move this to a separate file to handle editors for all kinds of object. 
	if(self:IsServerEntity() and self:IsRemote()) then
		LOG.std(nil, "info", "Entity:OpenEditor", "access denied, entity is only editable on server");
		return;
	end
	if(editor_name == "entity") then
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EditEntityPage.lua");
		local EditEntityPage = commonlib.gettable("MyCompany.Aries.Game.GUI.EditEntityPage");
		EditEntityPage.ShowPage(self, entity);
	elseif(editor_name == "property") then
		NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/MobPropertyPage.lua");
		local MobPropertyPage = commonlib.gettable("MyCompany.Aries.Game.GUI.MobPropertyPage");
		MobPropertyPage.ShowPage(self, entity);
	end
end

function Entity:UpdateBlockContainer()
	local x, y, z = self:GetBlockPos();
	if(not self.block_container) then
		self.block_container = EntityManager.GetBlockContainer(x,y,z);
		self.block_container:Add(self);

		if(self:IsRegional()) then
			local region = EntityManager.GetRegionContainer(x, z);
			region:Add(self)
		end
	else
		local block_container = self.block_container;
		if(block_container.x~=x or block_container.y~=y or block_container.z~=z ) then
			if(self:IsRegional()) then
				local region = EntityManager.GetRegionContainer(block_container.x, block_container.z);
				region:Remove(self);
				local region = EntityManager.GetRegionContainer(x, z);
				region:Add(self);
			end
			block_container:Remove(self);
			self.block_container = EntityManager.GetBlockContainer(x,y,z);
			self.block_container:Add(self);
		end
	end
end

-- @return bx, by, bz in block world. 
function Entity:GetBlockPos()
	if(not self.bx and self.x) then
		self.bx, self.by, self.bz = BlockEngine:block(self.x, self.y+0.1, self.z);
	end
	return self.bx or 0, self.by or 0, self.bz or 0;
end

function Entity:doesEntityTriggerPressurePlate()
	return false;
end

-- update block position according to the associated object. 
function Entity:SetBlockPos(bx, by, bz)
	if(not bx) then 
		return;
	end
	if(self.bx~=bx or self.by~=by or self.bz~=bz ) then
		self.bx, self.by, self.bz = bx, by, bz;
		self:UpdateBlockContainer();

		local obj = self:GetInnerObject();
		if(obj) then
			local x, y, z = BlockEngine:real(bx, by, bz);
			y = y - BlockEngine.half_blocksize +  (self.offset_y or 0);
			self.x, self.y, self.z = x, y, z;
			obj:SetPosition(x,y,z);
			obj:UpdateTileContainer();
		end
		self:valueChanged();
	end
end

-- @sa DistanceSqTo() for block pos
function Entity:GetDistanceSq(x,y,z)
	if(self.x) then
		return (self.x-x)^2 + (self.y-y)^2 + (self.z-z)^2;
	end
end

-- Sets the location and Yaw/Pitch of an entity in the world. It will teleport the player at the exact location.
function Entity:SetLocationAndAngles(x,y,z, yaw, pitch)
    self.prevPosX = x;
    self.prevPosY = y;
    self.prevPosZ = z;
    self.rotationYaw = yaw; 	self.facing = yaw;
    self.rotationPitch = pitch;
    self:SetPosition(x, y, z);
end

-- teleport to a given block position. 
function Entity:TeleportToBlockPos(x,y,z)
	self:SetBlockPos(x,y,z);
end

-- Sets the entity's position and rotation. But it does not change last tick position. 
function Entity:SetPositionAndRotation(x,y,z,yaw, pitch)
	self:SetRotation(yaw, pitch);
	self:SetPosition(x,y,z);
end

function Entity:SetRotation(facing, pitch)
	if(facing) then
		self:SetFacing(facing);
	end
end

-- Sets the entity's position and rotation. it will correct y so it will snap to ground. 
-- @param posRotIncrements: smoothed frames. we will move to x,y,z in this number of ticks. 
function Entity:SetPositionAndRotation2(x,y,z,yaw, pitch, posRotIncrements)
	self:SetRotation(yaw, pitch)
	self:SetPosition(x,y,z);
	-- TODO: check for collision for y 
end

-- set real world position for the object. 
function Entity:SetPosition(x, y, z)
	if(not x) then 
		return;
	end
	if(self.x~=x or self.y~=y or self.z~=z ) then
		self.x, self.y, self.z = x, y, z;

		local bx, by, bz = BlockEngine:block(x, y+0.1, z);
		if(self.bx~=bx or self.by~=by or self.bz~=bz ) then
			self.bx, self.by, self.bz = bx, by, bz;
			self:UpdateBlockContainer();
		end

		local obj = self:GetInnerObject();
		if(obj) then
			obj:SetPosition(x,y,z);
			obj:UpdateTileContainer();
		end
		self:valueChanged();
	end
end

-- @return a clone of {x,y,z}
function Entity:getPosition()
	return vector3d:new({self:GetPosition()})
end

-- @param pos: {x,y,z}
function Entity:setPosition(pos)
	if(pos and type(pos) == "table") then
		self:SetPosition(pos[1], pos[2], pos[3]);
	end
end


-- virtual function: Get real world position. if not exist, we will convert from block position. 
function Entity:GetPosition()
	if(self.x) then
		return self.x, self.y, self.z;
	elseif(self.bx) then
		local x,y,z = BlockEngine:real(self.bx, self.by, self.bz);
		y = y - BlockEngine.half_blocksize;
		return x,y,z;
	else
		return 0,0,0;
	end
end

-- get next position using its current speed with deltaTime
function Entity:GetNextPosition(deltaTime)
	local x, y, z = self:GetPosition();
	if(self:HasSpeed() and deltaTime) then
		local vx, vy, vz = self:GetVelocity();
		x = x + vx*deltaTime;
		y = y + vy*deltaTime;
		z = z + vz*deltaTime;
	end
	return x,y,z;
end

-- get block world distance to the give block position. 
-- @sa GetDistanceSq() for real pos
function Entity:DistanceSqTo(x,y,z)
	local mx, my, mz = self:GetBlockPos();
	return (mx-x)^2+(my-y)^2+(mz-z)^2;
end

-- get the picking distance of this entity. 
function Entity:GetPickingDist()
	return GameLogic.options.PickingDist;
end

-- virtual function: only used by EntityPlayer to update Yaw,pitch from player controlled object. 
function Entity:UpdateRotation()
end

-- virtual function: only used by EntityPlayer to update block position from player controlled object. 
-- do not call this if object is controlled completely from scripting interface. 
-- @param x,y,z: if nil, we will use the inner object's real position(NOT block position)
-- @return inner object if x, y, z is not specified. 
function Entity:UpdatePosition(x,y,z)
	local obj;
	if(not x) then
		obj = self:GetInnerObject();
		if(obj) then
			x,y,z = obj:GetPosition();
		else
			return;
		end
	end
	local old_bx, old_by, old_bz = self.bx, self.by, self.bz

	if(self.x~=x or self.y ~= y or self.z~=z) then
		self.x, self.y, self.z = x,y,z;

		local bx, by, bz = BlockEngine:block(x,y+0.1,z); 
		if(old_bx~= bx or old_by~=by or old_bz~=bz) then
			self.bx, self.by, self.bz = bx,by,bz;
			-- update position
			self:UpdateBlockContainer();
		end

		self:valueChanged();
	end
	return obj;
end


-- Applies a velocity to each of the entities pushing them away from each other. 
function Entity:ApplyEntityCollision(fromEntity, deltaTime)
	local from_x, from_y, from_z = fromEntity:GetPosition();
	local x,y,z = self:GetPosition();
    local dX = from_x - x;
    local dZ = from_z - z;
    local dist = math.abs(dX, dZ);

    if (dist >= 0.01) then
        dist = math.sqrt(dist);
        dX = dX / dist;
        dZ = dZ / dist;
        local invert_dist = 1 / dist;

        if (invert_dist > 1) then
            invert_dist = 1;
        end

		local delta = invert_dist * 3.0 * (deltaTime or 0.1) * (1.0 - self.entityCollisionReduction)
        dX = dX * delta;
        dZ = dZ * delta;
		local max_speed = 3;
		local vx, vy, vz = self:GetVelocity();
		if(vx < max_speed and vz < max_speed and vx>-max_speed and vz > -max_speed) then
			self:AddMotion(-dX, 0.0, -dZ);
		end
		local vx, vy, vz = fromEntity:GetVelocity();
		if(vx < max_speed and vz < max_speed and vx>-max_speed and vz > -max_speed) then
			fromEntity:AddMotion(dX, 0.0, dZ);
		end
    end
end

-- whether this entity can push block
function Entity:CanPushBlock()
	return self.can_push_block;
end

-- Returns true if this entity should push and be pushed by other entities when colliding.
function Entity:CanBePushedBy(fromEntity)
    return false;
end

-- Returns true if other Entities should be prevented from moving through this Entity.
function Entity:CanBeCollidedWith()
    return false;
end

-- return true if this entity can be ridden by a player. 
function Entity:CanBeMounted()
	return false;
end

-- this function is called when this entity collide with another entity. 
function Entity:CollideWithEntity(fromEntity)
end

function Entity:GetPhysicsRadius()
	return 0.25;
end

function Entity:GetPhysicsHeight()
	return 1;
end

-- in real world coordinates
function Entity:GetCollisionAABB()
	if(self.aabb) then
		local x, y, z = self:GetPosition();
		self.aabb:SetBottomPosition(x, y, z);
	else
		self.aabb = ShapeAABB:new();
		local x, y, z = self:GetPosition();
		local radius = self:GetPhysicsRadius();
		local half_height = self:GetPhysicsHeight() * 0.5;
		self.aabb:SetCenterExtend(vector3d:new({x,y+half_height,z}), vector3d:new({radius,half_height,radius}));
	end
	return self.aabb;
end

-- returns a boundingBox used to collide the entity with other entities and blocks. 
-- This enables the entity to be pushable on contact
-- @param entity: the entity to check against
function Entity:CheckGetCollisionBox(entity)
	return;
end

-- Adds velocity to push the entity out of blocks at the specified x, y, z position
-- @return true if successfully pushed
function Entity:PushOutOfBlocks(x,y,z)
    -- add velocity and try 6 directions. 
	local block;
	block = BlockEngine:GetBlock(x-1,y,z);
	if(not block or not block.obstruction) then
		self:SetBlockPos(x-1,y,z);
		return true;
	end
	block = BlockEngine:GetBlock(x+1,y,z);
	if(not block or not block.obstruction) then
		self:SetBlockPos(x+1,y,z);
		return true;
	end
	block = BlockEngine:GetBlock(x,y,z-1);
	if(not block or not block.obstruction) then
		self:SetBlockPos(x,y,z-1);
		return true;
	end
	block = BlockEngine:GetBlock(x,y,z+1);
	if(not block or not block.obstruction) then
		self:SetBlockPos(x,y,z+1);
		return true;
	end
	block = BlockEngine:GetBlock(x,y+1,z);
	if(not block or not block.obstruction) then
		self:SetBlockPos(x,y+1,z);
		return true;
	end
	block = BlockEngine:GetBlock(x,y-1,z);
	if(not block or not block.obstruction) then
		self:SetBlockPos(x,y-1,z);
		return true;
	end
end

-- default to true. 
function Entity:SetCheckCollision(bCheck)
	self.bIgnoreCollision = not bCheck;
end

-- whether we will check collision for this entity
function Entity:IsCheckCollision()
	return not self.bIgnoreCollision;
end


-- virtual function: check if the entity collide with other entity or block. if so, we will fire event and adjust position.
function Entity:CheckCollision(deltaTime)
	if(not self:IsCheckCollision()) then
		return
	end
	local bx,by,bz = self:GetBlockPos();

	-- checking collision with blocks
	local block = BlockEngine:GetBlock(bx,by,bz);
	if(block) then
		if(not block.obstruction) then
			-- fire block event if we are colliding with an non-obstruction block, such as pressure plate. 
			block:OnEntityCollided(bx,by,bz, self, deltaTime);
		elseif(block.solid) then
			-- if the player is standing inside an obstruction (and solid) block,
			-- automatically move the entity to the first 1*2*1 free space above the obstruction block.

			if(not self:PushOutOfBlocks(bx,by,bz)) then
				for i=by+1, 250 do
					block = BlockEngine:GetBlock(bx,i,bz);
					if(not block or not block.obstruction) then
						block = BlockEngine:GetBlock(bx,i+1,bz);
						if(not block) then
							self:SetBlockPos(bx, i, bz);
							break;
						end
					end
				end
			end
			return;
		end
	end
	local block = BlockEngine:GetBlock(bx,by-1,bz);
	self.onGround = (block and block.obstruction);
	if(self.onGround) then
		-- fire event if we are steping on a block. 
		block:OnStep(bx,by-1,bz, self);
	else
		-- only falls down when no speed at all. 
		-- NOTE: this is inaccurate, for half-block height slab block, but vertical speed is reset to 0 in C++ physics engine anyway. 
		if(not self:HasSpeed() and not self:IsFlying()) then
			self:FallDown(deltaTime);
		end
	end	
end

-- whether the entity can move to the given side relative to its current location. 
-- it will automatically climb over one block height unless it is a fence
function Entity:CanMoveTo(x,y,z)
	local block = BlockEngine:GetBlock(x,y,z);
	if(block and block.obstruction) then
		if(block.shape == "Fence") then
			return false;
		else
			y = y + 1;
			local block = BlockEngine:GetBlock(x,y,z);
			if((block and block.obstruction) or EntityManager.HasEntityInBlock(x,y,z)) then
				return false;
			end
		end
	elseif(EntityManager.HasEntityInBlock(x,y,z)) then
		return false;
	end

	local block = BlockEngine:GetBlock(x,y+1,z);
	if( (block and block.obstruction) or (EntityManager.HasEntityInBlock(x,y+1,z)) ) then
		return false;
	end
	return true, x,y,z;
end

function Entity:GetItemId()
	return self.item_id;	
end

function Entity:GetItemClass()
	if(self.item_id and self.item_id>0) then
		return ItemClient.GetItem(self.item_id);
	end
end

-- falls down immediately one block if not obstruction below. 
function Entity:FallDown(deltaTime)
	local min_y;
	local block = BlockEngine:GetBlock(self.bx,self.by-1,self.bz);
	if(block and block.obstruction) then
		min_y = BlockEngine:realY(self.by);
	else
		min_y = BlockEngine:realY(self.by-1);
		if(self.x) then
			min_y = math.max(min_y, ParaTerrain.GetElevation(self.x, self.z));
		end
	end

	local obj = self:GetInnerObject();
	if(obj) then
		local x, y, z = obj:GetPosition();
		if(y~=min_y) then
			y = min_y;
			obj:SetPosition(x,y,z);
			self:UpdatePosition(x,y,z);
		end
	end
end

-- get the number of seconds left before the entity is dead. 
-- if return nil, the object has infinite life span. 
function Entity:GetLifeTime()
	return self.lifetime;
end

-- set the number of seconds left before the entity is dead. 
-- if return nil, the object has infinite life span. 
function Entity:SetLifeTime(lifetime)
	self.lifetime = lifetime;
end

-- virtual function: overwrite to customize physical object
function Entity:CreatePhysicsObject()
	return PhysicsWorld.DynamicObject:new();
end

-- create get physics object. 
function Entity:GetPhysicsObject()
	local physic_obj = self.physic_obj;
	if(physic_obj) then
		return physic_obj;
	else
		physic_obj = self:CreatePhysicsObject();
		self.physic_obj = physic_obj;
		return physic_obj;
	end
end

-- whether has speed
function Entity:HasSpeed()
	return self.physic_obj and self.physic_obj:HasSpeed();
end

function Entity:HasMotion()
	return self.motionX ~= 0 or self.motionY ~= 0 or self.motionZ ~= 0;
end

function Entity:IsOnGround()
	return self.physic_obj and self.physic_obj:IsOnGround();
end

local motion_fps = 20;
local inverse_motion_fps = 1/motion_fps;

-- check to see if we should tick. For example, some function may be called with deltaTime in 30fps, 
-- however, we only want to process at 20FPS, such as physics, we can use this function is easily limit function calling rate. 
-- @param func_name: default to "FrameMove". this can be any string. 
-- @param deltaTime: delta time in seconds, since last call
-- @param intervalSeconds: default to 1/20
function Entity:IsTick(func_name, deltaTime, intervalSeconds)
	if(not self.ticks) then
		self.ticks = Ticks:new();
	end
	return self.ticks:IsTick(deltaTime, func_name, intervalSeconds);
end

local inverse_fps = 1/30;
-- Adds to the current velocity of the entity. 
-- @param x,y,z: velocity in x,y,z direction. 
function Entity:AddVelocity(x,y,z)
	if(self.motionX) then
		self:AddMotion((x or 0)*inverse_fps, (y or 0)*inverse_fps, (z or 0)*inverse_fps);
	else
		self:GetPhysicsObject():AddVelocity(x,y,z);
	end
end

-- Set current velocity of the entity. 
-- @param x,y,z: velocity in x,y,z direction. all may be nil to retain last speed. 
function Entity:SetVelocity(x,y,z)
	if(self.motionX) then
		if(x) then
			self.motionX = x*inverse_fps;
		end
		if(y) then
			self.motionY = y*inverse_fps;
		end
		if(z) then
			self.motionZ = z*inverse_fps;
		end
	else
		self:GetPhysicsObject():SetVelocity(x,y,z);
	end
end


-- Adds to the current motion of the entity. 
-- @param x,y,z: velocity in x,y,z direction. 
function Entity:AddMotion(dx,dy,dz)
	if(self.motionX) then
		self.motionX = self.motionX + dx;
		self.motionY = self.motionY + dy;
		self.motionZ = self.motionZ + dz;
	else
		self:GetPhysicsObject():AddVelocity(dx*motion_fps,dy*motion_fps,dz*motion_fps);
	end
end

-- return x,y,z
function Entity:GetVelocity()
	if(self.motionX) then
		return self.motionX*motion_fps, self.motionY*motion_fps, self.motionZ*motion_fps;
	else
		return self:GetPhysicsObject():GetVelocity();
	end
end

-- derived class can call this function to move the entity using its current speed. 
-- @param bTryMove: if true, we will always try move the entity even it does not have speed. 
function Entity:MoveEntity(deltaTime, bTryMove)
	local physic_obj = self.physic_obj;
	if(not physic_obj) then
		return;
	end
	if(physic_obj:HasSpeed() or bTryMove) then
		physic_obj:UpdateFromEntity(self);

		physic_obj:FrameMove(deltaTime);

		physic_obj:UpdateToEntity(self);
	end
end

-- set frame move interval
function Entity:SetFrameMoveInterval(framemove_interval)
	if(self.framemove_interval ~= framemove_interval) then
		self.framemove_interval = framemove_interval;
		self.last_frametime = nil;
		if(not framemove_interval) then
			self:SetAlwaysSentient(nil);
		end
	end
end

function Entity:IsBlockEntity()
	return;
end

-- Overriden in a sign to provide the text.
function Entity:GetDescriptionPacket()
    return;
end

function Entity:OnUpdateFromPacket(packet_UpdateEntitySign)
end

-- how many framemove per seconds
function Entity:SetTickRate(tickRate)
	self.tickRate = tickRate;
	self.tickRateInterval = 1/tickRate;
end

-- this will cause this entity to become always sentent. 
function Entity:SetAlwaysSentient(bSentient)
	if(self.bAlwaysSentient ~= bSentient) then
		self.bAlwaysSentient = bSentient;
		if(bSentient) then
			EntityManager.AddToSentientList(self);
		else
			EntityManager.RemoveFromSentientList(self);
		end
	end
end

function Entity:IsAlwaysSentient()
	return self.bAlwaysSentient;
end

-- 1/tickRate
function Entity:GetTickRateInterval()
	return self.tickRateInterval or 0.03;
end

-- return true if EntityMob.framemove_interval is not nil and ready to frame move. 
-- @param deltaTime in seconds
-- @param bForceFrameMove: if nil we will only check but does not do the framemove. If true, we will not check but do the framemove
-- true to run the framemove and increase the local time. 
-- @return nil or deltaTimeReal in seconds.
function Entity:CheckFrameMove(deltaTime, curTime, bForceFrameMove)
	if(self.framemove_interval and (bForceFrameMove or self:IsTick("FrameMove", deltaTime, self.framemove_interval))) then
		local deltaTimeReal;
		if(self.last_frametime) then
			deltaTimeReal = curTime - (self.last_frametime or curTime);
		else
			deltaTimeReal = self.framemove_interval;
		end
		
		if(bForceFrameMove) then
			self.last_frametime = curTime;

			-- skip entities that is mounted on other entity, instead let the riddenEntity to call its FrameMoveRidding
			if(not self.ridingEntity) then
				self:FrameMove(deltaTimeReal);

				if(self.riddenByEntity) then
					if(not self.riddenByEntity:IsDead() and self.riddenByEntity.ridingEntity == self) then
						self.riddenByEntity:FrameMoveRidding(deltaTimeReal);
					else
						self.riddenByEntity.ridingEntity = nil;
						self.riddenByEntity = nil;
					end
				end
			else
				if (not self.ridingEntity:IsDead() and self.ridingEntity.riddenByEntity == self) then
					-- continue;
				else
					self.ridingEntity.riddenByEntity = nil;
					self.ridingEntity = nil;
				end
			end
		end
		return deltaTimeReal;	
	end
end
-- time event list
function Entity:GetTimeEvent()
	if(not self.timeEvent) then
		self.timeEvent = commonlib.List:new();
	end
	return self.timeEvent;
end

-- add a timed event to this entity
-- @param callbackFunc: function(entity, timedEvent)
function Entity:AddTimeEvent(scheduledTime, name, callbackFunc)
	local cur_time = self:GetTime();
	if(cur_time > scheduledTime) then
		return;
	end

	local event_list = self:GetTimeEvent();
	if(event_list:size() > 100) then
		LOG.std(nil, "warn", "AddTimeEvent", "too many timed event in the list");
		return;
	end

	local item = event_list:first();
	while (item) do
		if(item.scheduledTime <= scheduledTime) then 
			item = event_list:next(item);
		else
			break;
		end
	end
	local event = TimedEvent:new():Init(scheduledTime, name, callbackFunc);
	event_list:insert_after(event, item);

	if(not self.framemove_interval) then
		self:SetFrameMoveInterval(0.5);
	end
	self:SetAlwaysSentient(true);
end

-- radius (in blocks) that this entity will awake nearby entities. 
-- please note, it will only awake other entity if the distance between the two entities is the smaller 
-- than the smallest value of either entity's GetSentientChunkRadius().
-- @return default value is 128
function Entity:GetSentientRadius()
	return 128;
end

-- advance time and fire all timed event that is smaller than current time. 
-- return true if there is still time event left. 
-- @param delta_time: if nil we will advance to next time event. In seconds
function Entity:AdvanceTime(delta_time)
	local event_list = self.timeEvent;
	if(event_list) then
		local cur_time;
		if(delta_time) then
			cur_time = self:GetTime() + delta_time;
			self:SetTime(cur_time);
		else
			-- advance to next time
			local item = event_list:first();
			if(item) then
				cur_time = item.scheduledTime;
				self:SetTime(cur_time);
			end	
		end

		local item = event_list:first();
		while (item and item.scheduledTime <= cur_time) do
			event_list:remove(item);
			item:FireEvent(self);
			-- tricky: just in case FireEvent itself modified the event_list and local time. 
			item = event_list:first();
			cur_time = self:GetTime();
		end
		if(item) then
			return true;
		else
			-- if there is no timed event, reset time to 0. 
			if(not self.disable_auto_stop_time) then
				self:SetTime(0);
			end
		end
	end
end

-- whether the entity can receive activation or user input. 
function Entity:IsInputDisabled()
	return self.is_input_disabled;
end

-- make the entity dummy, it will not respond to any activate command or user input, 
-- unless it is set to not dummy by command line. /disableinput false
function Entity:DisableInput(bDisabled)
	self.is_input_disabled = bDisabled;
end

-- pause any scheduled time event 
function Entity:Pause()
	self.is_paused = true;
end

function Entity:IsPaused()
	return self.is_paused;
end

function Entity:Resume()
	self.is_paused = nil;
end


-- clear all time events in this entity
function Entity:ClearTimeEvent()
	if(self.timeEvent) then
		self.timeEvent:clear();
		-- if there is no timed event, reset time to 0. 
		self:SetTime(0);
	end
end

-- set local time of this entity. this is only used in animated entity or entity with timed event. 
-- in seconds. 
function Entity:SetTime(time)
	self.time = time;
end

-- get local time of this entity. in seconds 
function Entity:GetTime()
	return self.time or 0;
end

-- set local time of this entity to the next time event in the queue.
function Entity:SetTimeToNextEvent()
	local event_list = self.timeEvent;
	if(event_list) then
		local cur_time;
		-- advance to next time
		local item = event_list:first();
		if(item) then
			if(self:GetTime() < item.scheduledTime) then
				cur_time = item.scheduledTime;
				self:SetTime(cur_time);
			end
		end	
	end
end

-- set the character slot
function Entity:SetCharacterSlot(slot_id, item_id)
	local obj = self:GetInnerObject();
	if(obj) then
		obj:ToCharacter():SetCharacterSlot(slot_id, item_id);
		-- TODO: save to inner data
	end
end

function Entity:IsControlledExternally()
	local obj = self:GetInnerObject();
	if(obj) then
		return obj:GetField("IsControlledExternally", false)
	end
end

function Entity:SetControlledExternally(bEnable)
	local obj = self:GetInnerObject();
	if(obj) then
		return obj:SetField("IsControlledExternally", bEnable)
	end
end

function Entity:GetMainAssetPath()
	if(self.mainAssetPath) then
		return self.mainAssetPath;
	else
		local item = self:GetItemClass();
		if(item) then
			return item:GetAssetFile() or "";
		else
			return "";
		end
	end
end

-- set main model
function Entity:SetMainAssetPath(name)
	if(self:GetMainAssetPath() ~= name) then
		self.mainAssetPath = name;
		return true;
	end
end

function Entity:GetBoundRadius()
	local obj = self:GetInnerObject();
	if(obj) then
		return obj:GetField("radius", 0);
	end
	return 0;
end

-- set speed decay. percentage of motion lost per tick. 
-- @param surface_decay:  [0,1]. 0 means no speed lost, 1 will lost all speed.  default to 0.5
function Entity:SetSurfaceDecay(surface_decay)
	self.surface_decay = surface_decay;
end

function Entity:GetSurfaceDecay()
	return self.surface_decay or 0.5;
end

-- called when ever an editor like EditEntityPage is opened for this entity
-- if one wants to provide some basic undo/redo function, this is the place to go.
function Entity:BeginEdit()
	self:GetEditModel():BeginEdit();
	GameLogic.GetEvents():DispatchEvent({type = "OnEditEntity" , entity = self, isBegin = true});	
end

-- called when ever an editor like EditEntityPage is closed for this entity
-- if one wants to provide some basic undo/redo function, this is the place to go.
-- one may also refresh the entity if any changes take place that is not updated automatically. 
function Entity:EndEdit()
	self:ActivateRules();
	self:GetEditModel():EndEdit();
	GameLogic.GetEvents():DispatchEvent({type = "OnEditEntity" , entity = self,});	
end

-- mark for update so that local changes are sent to client or server
function Entity:MarkForUpdate()
	local x,y,z = self:GetBlockPos();
	-- just in case the text is changed. 
	BlockEngine:MarkBlockForUpdate(x,y,z);
end

-- pick the given item. 
-- @param fromBlockX, fromBlockY, fromBlockZ: block position from the item come from. can all be nil. 
function Entity:PickItem(itemStack, fromBlockX, fromBlockY, fromBlockZ)
	if(self.inventory and self.inventory.AddItemToInventory) then
		if(self.inventory:AddItemToInventory(itemStack)) then
			-- play ui animation. 
			local item = itemStack:GetItem();
			if(item) then
				local filename = item:GetIcon();
				if(filename) then
					local bx, by, bz = self:GetBlockPos();
					ObtainItemEffect:new({background=filename, duration=1000, color="#ffffffff", width=32,height=32, 
						from_3d={bx=fromBlockX or bx, by=fromBlockY or (by+4), bz=fromBlockZ or bz}, 
						to_3d={bx=bx, by=by+2, bz=bz}, fadeIn=200, fadeOut=200}):Play();
				end
			end
		end
	end
end

-- create the rule bag if not exist. 
-- @param size: if nil or 0, it will destory the rule bag. otherwise it will resize the rule bag
function Entity:SetRuleBagSize(size)
	if(not size or size == 0) then
		self.rulebag = nil;
		self.rulebagView = nil;
	else
		self.rulebag = InventoryBase:new():Init(size);
		self.rulebagView = ContainerView:new():Init(self.rulebag);
		self.rulebag:SetClient();
	end
end

-- virtual function: load rules and framemove rule items. 
function Entity:FrameMoveRules(deltaTime)
	if(not self.rulebag) then
		return;
	end
	-- load rules
	if(not self.m_bRuleLoaded) then
		self.m_bRuleLoaded = true;
		self:ActivateRules();
	end
end

-- virtual function: called every frame
function Entity:FrameMove(deltaTime)
	if(self.lifetime) then
		self.lifetime = self.lifetime - deltaTime;
		if(self.lifetime < 0) then
			self:SetDead();
		end
	end

	if(not self:IsPaused()) then
		self:FrameMoveRules(deltaTime);
		self:AdvanceTime(deltaTime);
	end
end

function Entity:NotifyBlockCollisions()
	local aabb = self:GetCollisionAABB();
	local blockMinX,  blockMinY, blockMinZ = aabb:GetMinValues()
	local blockMaxX,  blockMaxY, blockMaxZ = aabb:GetMaxValues();
	blockMinX,  blockMinY, blockMinZ = BlockEngine:block(blockMinX+0.001,  blockMinY+0.001, blockMinZ+0.001);
	blockMaxX,  blockMaxY, blockMaxZ = BlockEngine:block(blockMaxX-0.001,  blockMaxY-0.001, blockMaxZ-0.001);

	for bx = blockMinX, blockMaxX do
        for bz = blockMinZ, blockMaxZ do
            for by = blockMinY, blockMaxY do
                local block_template = BlockEngine:GetBlock(bx, by, bz);
                if (block_template) then
                    -- fire block event if we are colliding with an non-obstruction block, such as pressure plate. 
					block_template:OnEntityCollided(bx,by,bz, self, EntityManager:GetDeltaTime());
                end
            end
		end
	end

	--if(self.onGround) then
		--local blockStepY = BlockEngine:blockY(blockMinY-0.001);
		--if(blockStepY < blockMinY) then
			--local block = BlockEngine:GetBlock(bx, blockStepY, bz);
			--if(block and block.obstruction) then
				---- fire event if we are steping on a block. 
				--block:OnStep(bx,blockStepY,bz, self);
			--end
		--end
	--end
end

-- virtual: Called when the entity has just fallen to ground. Calculates and applies fall damage.
-- @param distFallen: distance fallen. 
function Entity:OnFallDown(distFallen)
	if (self.riddenByEntity) then
		self.riddenByEntity:OnFallDown(distFallen);
	end
end

-- Return whether this entity is invulnerable to damage.
function Entity:IsEntityInvulnerable()
    return self.isInvulnerable;
end

-- Sets that this entity has been attacked.
function Entity:SetBeenAttacked()
    self.isBeenAttacked = true;
end

-- Called when the entity is attacked.
-- @param damageSource: what kind of damage. such as DamageSource.inFire, DamageSource.fall, etc. 
-- @param amount: such as 1. 
function Entity:AttackEntityFrom(damageSource, amount)
    if (self:IsEntityInvulnerable()) then
        return false;
    else
        self:SetBeenAttacked();
        return false;
    end
end

-- Drops an item at the position of the entity.
-- @return the EntityItem
function Entity:EntityDropItem(itemStack, fOffsetY)
    if (not itemStack or itemStack.count == 0) then
        return;
    else
		local x, y, z = self:GetPosition();
        local entityItem = EntityManager.EntityItem:new():Init(x, y + (fOffsetY or 0.5), z, itemStack);
        entityItem.delayBeforeCanPickup = 0.5;
        entityItem:Attach();
        return entityItem;
    end
end
-- Takes in the distance the entity has fallen this tick and whether its on the ground to update the fall distance
-- and deal fall damage if landing on the ground.  Args: distanceFallenThisTick, onGround
-- @param distanceFallenThisTick
-- @param bIsOnGround
function Entity:UpdateFallState(distanceFallenThisTick, bIsOnGround)
    if (bIsOnGround) then
        if (self.fallDistance and self.fallDistance > 0) then
            self:OnFallDown(self.fallDistance);
            self.fallDistance = 0;
        end
    elseif (distanceFallenThisTick < 0) then
        self.fallDistance = (self.fallDistance or 0) - distanceFallenThisTick;
    end
end

function Entity:IsSneaking()
    return self.bSneaking;
end

function Entity:SetSneaking(bSneaking)
    self.bSneaking = bSneaking;
end

-- Tries to moves the entity by the passed in displacement. 
-- this function is usually used by entities which need to process physics all by itself 
-- (instead of relying on physicsObj or default low level c++). 
-- @param dx, dy, dz: dispacement
function Entity:MoveEntityByDisplacement(dx,dy,dz)
	if (self.noClip) then
		local x, y, z;
        x = self.x + dx;
		y = self.y + dy;
		z = self.z + dz;
		self:SetPosition(x,y,z);
    else
		local lastX, lastY, lastZ = self:GetPosition();
        if (self.isInWeb) then
            self.isInWeb = false;
            dx = dx * 0.25;
            dy = dy * 0.05;
            dz = dz * 0.25;
            self.motionX = 0;
            self.motionY = 0;
            self.motionZ = 0;
        end

		local dx1,dy1, dz1 = dx,dy,dz;
        
		local boundingBox = self:GetCollisionAABB();
		local oldAABB = boundingBox:clone_from_pool();
		
		-- apply motion physics by extending the aabb and checking offsets with all colliding aabb. 
		local listCollisions = PhysicsWorld:GetCollidingBoundingBoxes(boundingBox:clone_from_pool():AddCoord(dx, dy, dz), self);

		if(dy~=0) then
			for i= 1, listCollisions:size() do
				dy = listCollisions:get(i):CalculateYOffset(boundingBox, dy, 0.01);
			end
			boundingBox:Offset(0, dy, 0);
			if (not self.bContinueMoveOnCollision and dy1 ~= dy) then
				dx,dy,dz = 0,0,0;
			end
		end
		local bOnGroundOrFallOnGround = self.onGround or (dy1 ~= dy and dy1 < 0);

		if(dx~=0) then
			for i= 1, listCollisions:size() do
				dx = listCollisions:get(i):CalculateXOffset(boundingBox, dx);
			end
			boundingBox:Offset(dx, 0, 0);
			if (not self.bContinueMoveOnCollision and dx1 ~= dx) then
				dx,dy,dz = 0,0,0;
			end
		end
		
        if(dz~=0) then
			for i= 1, listCollisions:size() do
				dz = listCollisions:get(i):CalculateZOffset(boundingBox, dz);
			end
			boundingBox:Offset(0, 0, dz);
			if (not self.bContinueMoveOnCollision and dz1 ~= dz) then
				dx,dy,dz = 0,0,0;
			end
		end
		

        if (self.stepHeight > 0 and bOnGroundOrFallOnGround and (dx1 ~= dx or dz1 ~= dz)) then
			-- step over block
			-- algorithm: first move up to the stepHeight, if no collision there, and then move downward until touches the ground. 
			local oldDx, oldDy, oldDz = dx,dy,dz;
			dx = dx1;
            dy = self.stepHeight;
            dz = dz1;

			local newAABB = boundingBox:clone_from_pool();
            boundingBox:SetBB(oldAABB);

			-- pass1: move up to stepheight
			local listCollisions = PhysicsWorld:GetCollidingBoundingBoxes(boundingBox:clone_from_pool():AddCoord(dx1, dy, dz1), self);
			for i= 1, listCollisions:size() do
				dy = listCollisions:get(i):CalculateYOffset(boundingBox, dy);
			end

			boundingBox:Offset(0, dy, 0);
        
			if (not self.bContinueMoveOnCollision and dy1 ~= dy) then
				dx,dy,dz = 0,0,0;
			end

			local bOnGroundOrFallOnGround = self.onGround or (dy1 ~= dy and dy1 < 0);
        

			for i= 1, listCollisions:size() do
				dx = listCollisions:get(i):CalculateXOffset(boundingBox, dx);
			end

			boundingBox:Offset(dx, 0, 0);

			if (not self.bContinueMoveOnCollision and dx1 ~= dx) then
				dx,dy,dz = 0,0,0;
			end
        
			for i= 1, listCollisions:size() do
				dz = listCollisions:get(i):CalculateZOffset(boundingBox, dz);
			end

			boundingBox:Offset(0, 0, dz);

			if (not self.bContinueMoveOnCollision and dz1 ~= dz) then
				dx,dy,dz = 0,0,0;
			end

			if (not self.bContinueMoveOnCollision and dy1 ~= dy) then
                dx,dy,dz = 0,0,0;
            else
				-- pass2: move downward until touches
                dy = -self.stepHeight;

				for i= 1, listCollisions:size() do
					dy = listCollisions:get(i):CalculateYOffset(boundingBox, dy);
				end
                boundingBox:Offset(0, dy, 0);
            end

            if ((oldDx * oldDx + oldDz * oldDz) >= (dx * dx + dz * dz)) then
                dx = oldDx;
                dy = oldDy;
                dz = oldDz;
				boundingBox:SetBB(newAABB);
            end
        end

		local x,y,z = boundingBox:GetBottomPosition();
		self:SetPosition(x,y,z);
        self.isCollidedHorizontally = dx1 ~= dx or dz1 ~= dz;
        self.isCollidedVertically = dy1 ~= dy;
        self.onGround = dy1 ~= dy and dy1 < 0;
        self.isCollided = self.isCollidedHorizontally or self.isCollidedVertically;
		self:UpdateFallState(dy, self.onGround);

		if (dx1 ~= dx) then
            self.motionX = 0;
        end

        if (dy1 ~= dy) then
            self.motionY = 0;
        end

        if (dz1 ~= dz) then
            self.motionZ = 0;
        end

		self:NotifyBlockCollisions();
	end
end

function Entity:GetMountedYOffset()
	return self:GetPhysicsHeight()*0.75;
end

-- framemove this entity when it is riding (mounted) on another entity. 
-- we will update according to mounted entity's position. 
function Entity:FrameMoveRidding(deltaTime)
	if (not self.ridingEntity or self.ridingEntity:IsDead()) then
        self.ridingEntity = nil;
    else
		if(self.motionX) then
			self.motionX = 0;
			self.motionY = 0;
			self.motionZ = 0;
			-- call the standard frame move
			self:FrameMove(deltaTime);
		
			if (self.ridingEntity) then
				self.ridingEntity:UpdateRiderPosition();

				self.entityRiderYawDelta = (self.entityRiderYawDelta or 0) + (self.ridingEntity.rotationYaw - self.ridingEntity.prevRotationYaw);
				self.entityRiderPitchDelta = (self.entityRiderPitchDelta or 0)+ (self.ridingEntity.rotationPitch - self.ridingEntity.prevRotationPitch); 

				self.entityRiderYawDelta = self.entityRiderYawDelta % 360;
				self.entityRiderPitchDelta = self.entityRiderPitchDelta % 360;

				local yawDelta = self.entityRiderYawDelta * 0.5;
				local pitchDelta = self.entityRiderPitchDelta * 0.5;
				local max_angle_speed = 10;

				if (yawDelta > max_angle_speed) then
					yawDelta = max_angle_speed;
				elseif (yawDelta < -max_angle_speed) then
					yawDelta = -max_angle_speed;
				end

				if (pitchDelta > max_angle_speed) then
					pitchDelta = max_angle_speed;
				elseif (pitchDelta < -max_angle_speed) then
					pitchDelta = -max_angle_speed;
				end

				self.entityRiderYawDelta = self.entityRiderYawDelta - yawDelta;
				self.entityRiderPitchDelta = self.entityRiderPitchDelta - pitchDelta;
			end
		else
			if (self.ridingEntity) then
				self.ridingEntity:UpdateRiderPosition();
			end
		end
    end
end

function Entity:GetRidingOffsetY()
	return 0;
end

function Entity:UpdateRiderPosition()
    if (self.riddenByEntity) then
		local x, y, z = self:GetPosition();
        self.riddenByEntity:SetPosition(x, y + self:GetMountedYOffset() + self.riddenByEntity:GetRidingOffsetY(), z);
    end
end

-- mount current entity to the target entity. 
-- @param targetEntity: nil to unmount
function Entity:MountEntity(targetEntity)
	self.entityRiderPitchDelta = 0;
    self.entityRiderYawDelta = 0;

    if (not targetEntity) then
		-- unmount from currently ridden entity
        if (self.ridingEntity) then
			local x, y, z = self.ridingEntity:GetPosition();
            self:SetLocationAndAngles(x, y+self.ridingEntity:GetPhysicsHeight(), z, self.rotationYaw, self.rotationPitch);
            self.ridingEntity.riddenByEntity = nil;
        end
        self.ridingEntity = nil;
    else
        if (self.ridingEntity) then
            self.ridingEntity.riddenByEntity = nil;
        end
        self.ridingEntity = targetEntity;
        targetEntity.riddenByEntity = self;
    end
end

-- whether any trackable data is modified 
function Entity:HasChanges()
    return self.objectChanged;
end

-- set changes
function Entity:SetChanged(bChanged)
    self.objectChanged = bChanged;
end

function Entity:GetRotationYaw()
    return self.rotationYaw or 0;
end

function Entity:GetRotationPitch()
    return self.rotationPitch or 0;
end


function Entity:GetRotationYawHead()
    return self.rotationHeadYaw or 0;
end

-- Sets the head's yaw rotation of the entity.
function Entity:SetRotationYawHead(value)
	self.rotationHeadYaw = value;
end

-- data in watcher are auto synced among clients by the server, without server validation. 
-- data in data watcher can be freely modified by both client and server, such as animation, skin, etc.
-- @NOTE: do NOT put server-critical data here, use inventory for server verified data.
function Entity:GetDataWatcher(bCreateIfNotExist)
	if(self.dataWatcher) then
		return self.dataWatcher;
	elseif(bCreateIfNotExist) then
		self.dataWatcher = DataWatcher:new();
		return self.dataWatcher;
	end
end

-- Returns true if the entity is riding another entity
function Entity:IsRiding()
    return self.ridingEntity ~= nil;
end


--[[ examples: 
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local player = EntityManager.GetPlayer();
player:BeginTouchMove();
player:TouchMove(0);
local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
	player:EndTouchMove();
end})
-- walk 1 seconds
mytimer:Change(1000, nil)
]]
-- begin touch move towards a given position. 
function Entity:BeginTouchMove()
	local attr = ParaCamera.GetAttributeObject();
	attr:SetField("ControlBiped", false);
end

-- move according to a facing angle in screen space relative to current camera view. 
-- call this function between BeginTouchMove() and EndTouchMove(). 
-- Please note, it will walk forever until EndTouchMove() is called. 
-- @param screen_facing: [0,2pi], where 0 is running away from camera, pi is running towards camera, etc. 
function Entity:TouchMove(screen_facing)
	local cam_facing = Direction.GetFacingFromCamera();
	local facing = cam_facing + (screen_facing or 0);
	local player = self:GetInnerObject();
	if(player) then
		player:SetFacing(facing);
		player:ToCharacter():AddAction(action_table.ActionSymbols.S_WALK_FORWORD, facing);
	end
end

-- end touch move towards a given position. 
function Entity:EndTouchMove()
	local attr = ParaCamera.GetAttributeObject();
	attr:SetField("ControlBiped", true);
	local player = self:GetInnerObject();
	if(player) then
		local char = player:ToCharacter();
		char:Stop();
		char:PlayAnimation(0);
	end
end

-- virtual function: get array of item stacks that will be displayed to the user when user try to create a new item. 
-- @return nil or array of item stack.
function Entity:GetNewItemsList()
	--local ItemStack = commonlib.gettable("MyCompany.Aries.Game.Items.ItemStack");
	--return {ItemStack:new():Init(62,1), ItemStack:new():Init(101,1)};
end

-- @param slot: type of ItemSlot in Container View, such as self.rulebagView
function Entity:CreateItemOnSlot(slot)
	if(slot) then
		if(not slot:GetStack()) then
			local itemStackArray = self:GetNewItemsList();
			itemStackArray = GameLogic.GetFilters():apply_filters("new_item", itemStackArray, self);
			if(itemStackArray and #itemStackArray>0) then
				NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/CreateNewItem.lua");
				local CreateNewItem = commonlib.gettable("MyCompany.Aries.Game.GUI.CreateNewItem");
				CreateNewItem.ShowPage(itemStackArray, function(itemStack)
					if(itemStack and itemStack.Copy) then
						slot:AddItem(itemStack:Copy());
					end
				end);
			end
		end
	end
end

-- called when user click to create a new item in the slot
-- @param slot: type of ItemSlot in Container View, such as self.rulebagView
function Entity:OnClickEmptySlot(slot)
	if(not GameLogic.GameMode:CanClickEmptySlot()) then
		return;
	end
	self:CreateItemOnSlot(slot);
end

-- This function is almost always used to enable polygon level collision for static entities only.  
-- Please be very careful NOT to enable physics for moving entities. Physics are automatically unloaded 
-- when geometry or position changed, thus a moving entity may frequently load and unload physics causing performance issues. 
-- @param bForceLoadPhysics: default to nil. by default it is lazy loading when main player collide with it, one can also explicitly load physics
-- make sure to call this function after model is loaded (Due to async loading, the model is not loaded until visible by a camera and loading is done in a separate loading thread)
function Entity:EnablePhysics(bEnable, bForceLoadPhysics)
	local obj = self:GetInnerObject();
	if(obj) then
		obj:SetField("EnablePhysics", bEnable == true);
		-- by default it is lazy loading when main player collide with it, one can also explicitly load physics by following line. 
		if(bForceLoadPhysics) then
			obj:LoadPhysics(); 
		end
	end
end

-- only call this function when the entity may has active memory context 
-- i.e. it has autonomous behaviors on its own.  EntityPlayer can move on its own. 
-- @return true if the entity is controlled by memory context
function Entity:FrameMoveMemoryContext(deltaTime)
	if(self.memoryContext) then
		return self:GetMemoryContext():FrameMove(deltaTime);
	end
end

-- the memory context
function Entity:GetMemoryContext()
	if(not self.memoryContext and not self:IsRemote()) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Memory/MemoryContext.lua");
		local MemoryContext = commonlib.gettable("MyCompany.Aries.Game.Memory.MemoryContext");
		self.memoryContext = MemoryContext:new():Init(self);
	end
	return self.memoryContext;
end