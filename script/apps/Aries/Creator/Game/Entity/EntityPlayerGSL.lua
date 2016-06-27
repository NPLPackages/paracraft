--[[
Title: entity player
Author(s): LiXizhi
Date: 2014/1/16
Desc: GSL functions are in this file for code clarity. This file customizes functions in GSL_agent.lua and it also handles 
creation and ccs info for OPC. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityPlayerGSL.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/ide/headon_speech.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/InventoryPlayer.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ContainerView.lua");
NPL.load("(gl)script/ide/Codec/TableCodec.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityPlayerCCS.lua");
local EntityPlayerCCS = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityPlayerCCS");
local TableCodec = commonlib.gettable("commonlib.TableCodec");
local ContainerView = commonlib.gettable("MyCompany.Aries.Game.Items.ContainerView");
local InventoryPlayer = commonlib.gettable("MyCompany.Aries.Game.Items.InventoryPlayer");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local PhysicsWorld = commonlib.gettable("MyCompany.Aries.Game.PhysicsWorld");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");


local math_abs = math.abs;
local math_random = math.random;
local math_floor = math.floor;

local Entity = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityPlayer");


-- external applications can override sentient group ids afterwards. 
local SentientGroupIDs = commonlib.gettable("MyCompany.Aries.Game.GameLogic.SentientGroupIDs");

-----------------------------------------
-- GSL related implementations
-----------------------------------------
-- static:
function Entity.GSL_OnCreateAgent(agent, name)
	if(not agent.x) then
		return;
	end
	local player = EntityManager.LoadPlayer(name);
	if(player) then
		local x, y, z = agent.x, agent.y, agent.z;

		local obj = ObjEditor.CreateObjectByParams({
			name = name,
			IsCharacter = true,
			AssetFile = player:GetMainAssetPath(),
			x = x,
			y = y,
			z = z,
			scaling = 1.0,
			facing = agent.facing, 
			IsPersistent = false,
		});
		if(not obj) then
			LOG.std(nil, "error", "EntityPlayer", "failed creating character for player");
			return
		end
		-- Disable sentient fields.
		obj:SetField("AlwaysSentient", false);
		-- make opc senses nobody 
		obj:SetField("SentientField", 0);
		obj:SetField("Sentient", false);

		obj:SetGroupID(SentientGroupIDs["OPC"]);
		obj:SetSentientField(SentientGroupIDs["Player"], true);
		obj:SetField("Sentient Radius", 40);
		obj:SetField("On_EnterSentientArea", [[;Map3DSystem.GSL.OnAgentEnterSentient();]]);
		obj:SetField("On_LeaveSentientArea", [[;Map3DSystem.GSL.OnAgentLeaveSentient();]]);

		-- make it OPC movement style
		obj:SetField("MovementStyle", 4);

		-- MESH_USE_LIGHT = 0x1<<7: use block ambient and diffuse lighting for this model. 
		obj:SetAttribute(128, true);

		-- attach to main game scene
		ParaScene.Attach(obj);

		agent:update_from_viewcache(obj);

		player:UpdateBlockContainer();
		player:BindToScenePlayer(obj, true);
	end
end

-- static:
function Entity.GSL_OnUpdateAgent(agent, player)
	local is_sentient = player:IsSentient();
	if(agent.x and agent.y and agent.z) then
			
		-- we shall only animate character position if the current agent is not mounted. 
		if((not agent.is_mounted or not player:ToCharacter():IsMounted()) and not agent.is_local) then
			-- just normal update
			local x,y,z = player:GetPosition();
			
			local deltaXZ = math_abs(x-agent.x) + math_abs(z-agent.z);
			local deltaY = math_abs(y-agent.y);
			
			if(not is_sentient or deltaXZ > 70) then
				if(not player:ToCharacter():IsMounted()) then
					player:SetPosition(agent.x, agent.y, agent.z);
					player:UpdateTileContainer();
					if(agent.facing ~= nil) then
						if(math_abs(player:GetFacing() - agent.facing)>0.01) then
							player:SetFacing(agent.facing);
						end	
					end
				end
			elseif(deltaXZ > 0.1 and not (type(agent.anim) == "string" and agent.anim~="")) then
				-- only if agent is sentient will we move with animation
				if(not player:ToCharacter():IsMounted()) then
					if(agent.facing) then
						-- encode facing in MoveTo command. 
						player:ToCharacter():MoveAndTurn(agent.x-x, agent.y-y, agent.z-z, agent.facing);
					else
						player:ToCharacter():MoveTo(agent.x-x, agent.y-y, agent.z-z);
					end
				end
			else
				-- original implementation
				-- if we are almost there, just set at precise location and facing
				-- TODO: if agents are not in the same world (different terrain heights), we may allow the self.y to be player.y. 
				if(not player:ToCharacter():IsMounted()) then
					player:SetPosition(agent.x, agent.y, agent.z);
					player:UpdateTileContainer();
					
					if(agent.facing~=nil) then
						if(math_abs(player:GetFacing()-agent.facing)>0.01) then
							player:SetFacing(agent.facing);
						end	
					end
				end
			end	
		end	
	end
	if(is_sentient) then
		-- only update if agent is sentient (within view range). 
		agent:update_from_viewcache(player);
	end
end

function Entity.GSL_update_from_viewcache(self, player)
	local nid_name = tostring(self.nid);
	if(not player) then
		player = ParaScene.GetObject(nid_name);
		if(player:IsValid() == false) then
			return;
		end
	end

	-- ccs appearance
	if(self.ccs~=nil) then
		if(self.ccs~=self.last_ccs) then
			local entityPlayer = EntityManager.GetPlayer(nid_name);
			if(entityPlayer) then
				EntityPlayerCCS.ApplyCCSInfoString(entityPlayer, self.ccs, player);
				self.last_ccs = self.ccs;
				self.GTwo = true;
			end
		end
	end
end

function Entity:GetCCSInfoString()
	return EntityPlayerCCS.GetCCSInfoString(self)
end

-- static:
function Entity.GSL_UpdateFromPlayer(self, player, timeid)
	local entity = EntityManager.GetPlayer(self.nid);
	if(entity) then
		self.x, self.y, self.z = entity:GetPosition();
		self.facing = player:GetFacing();

		local ccs = entity:GetCCSInfoString()
		if(self.ccs~=ccs) then
			self.ccs=ccs;
			self.GTwo = true;
		end
		self:UpdateFromSelf(timeid)
	else
		LOG.std(nil, "error", "EntityPlayer", "error: no agent found to update");
	end
end

-- virtual: remove player if any. 
function Entity.GSL_OnRemovePlayer(self, player)
	local entity = EntityManager.GetPlayer(self.nid);
	if(entity) then
		entity:Destroy();
	end
end


-- static: whenever Entity enters sentient area, it does the following things
-- 1. make the Entity visible 
-- 2. make the mountpet visible and sentient with Entity, and then move it near the Entity. 
-- 3. make the followpet visible and sentient with Entity, and then move it near the Entity. 
function Entity.GSL_On_EnterSentientArea()
	local _opc = ParaScene.GetObject(sensor_name);
	if(_opc:IsValid()) then
		_opc:SetVisible(true);
		_opc:SetField("RenderImportance", -1);
		if(_opc:IsSentient() == true) then
			-- Player.ShowHeadonTextForNID(tonumber(sensor_name), _opc)
		end
	end
end

-- static: whenever OPC leaves the sentient area, it does the following things
-- 1. make the OPC invisible 
-- 2. make the mountpet invisible and unsentient with OPC, and then leave it where it is. 
-- 3. make the followpet invisible and unsentient with OPC, and then leave it where it is.
function Entity.GSL_On_LeaveSentientArea()
	local _opc = ParaScene.GetObject(sensor_name);
	if(_opc and _opc:IsValid()) then
		_opc:SetVisible(false);
		-- 2011.4.26: this fixed a bug that when player is unsentient there is still a way point, so when it is sentient again, it will be drawn back.
		-- so we will remove all waypoints when OPC is not sentient. 
		_opc:ToCharacter():Stop();
	end
end
