--[[
Title: CommandWalk
Author(s): LiXizhi
Date: 2015/7/18
Desc: entity walk action
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandWalk.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/vector.lua");
local vector3d = commonlib.gettable("mathlib.vector3d");
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");


Commands["walk"] = {
	name="walk", 
	quick_ref="/walk [@entityname] [x y z] [-random 5] [-speed 1.0] [-finishanim 0] [-to|away @entityname] [-dist 10] [-fly]", 
	desc=[[let the given entity walk to a given position. 
@param entityname: name of the entity, if nil, it means the calling entity, such as inside the entity's inventory.  
@param x, y, z: the target position. if not specified it means the current entity's position. 
@param -random: if specified we will find add a random number to the target position, so that it walks to a random position within this radius
@param -speed: if specified it will modify the entity's walk speed. 
@param -finishanim: if specified, it will play the given animation once the player has reached the given position. 
@param -to|away: if specified, the player will walk to or away from the specified entity
@param -dist: only used when -to/away is specified.  How close to stop when walk to (default to 1). or how far to stop when walk away, default to 20. 
@param -fly: force flying
e.g.
/walk 19200 4 19200 -random 10   walk randomly to any position within 10 meters of the specified point. 
/walk -to @a -dist 1  walk towards nearby player until distance is 1. 
/walk -away @a -dist 10 walk away from nearby player until distance is 10. 
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local playerEntity;
		playerEntity, cmd_text = CmdParser.ParsePlayer(cmd_text);
		playerEntity = playerEntity or fromEntity;

		if(not playerEntity or not playerEntity.WalkTo) then
			return;
		end

		local x, y, z;
		x, y, z, cmd_text = CmdParser.ParsePos(cmd_text, fromEntity);
		if(not x) then
			x,y,z = playerEntity:GetBlockPos();
		end

		local random_radius, walkspeed, finish_anim, to_x, to_y, to_z, isAway, dist;

		local option = "";
		while (option) do
			option, cmd_text = CmdParser.ParseOption(cmd_text);
			if(option == "random") then
				random_radius, cmd_text = CmdParser.ParseNumber(cmd_text);
			elseif(option == "speed") then	
				walkspeed, cmd_text = CmdParser.ParseNumber(cmd_text);
				if(walkspeed) then
					playerEntity:SetWalkSpeed(walkspeed);
				end
			elseif(option == "dist") then
				dist, cmd_text = CmdParser.ParseNumber(cmd_text);
			elseif(option == "to" or option == "away") then
				local toEntity
				toEntity, cmd_text = CmdParser.ParsePlayer(cmd_text);
				if(toEntity) then
					to_x, to_y, to_z = toEntity:GetBlockPos();
					isAway = (option == "away");
				end
			elseif(option == "finishanim") then	
				finish_anim, cmd_text = CmdParser.ParseNumber(cmd_text);
			elseif(option == "fly") then	
				playerEntity:ToggleFly(true);
			end
		end

		if(to_z) then
			dist = dist or 1;
			local curPos = vector3d:new(playerEntity:GetBlockPos())
			local toPos = vector3d:new(to_x, to_y, to_z);
			local pos;
			pos = toPos + (curPos - toPos):normalize() * dist;
			x,y,z = pos:get();
		end

		if(x) then
			if(random_radius and random_radius>1) then
				local dx = math.random(-random_radius, random_radius);
				local dz = math.random(-random_radius,  random_radius);
				x = x + dx;
				z = z + dz;
			end
		end
		-- try to walk to a given position. 
		playerEntity:WalkTo(x, y, z);
	end,
};

Commands["togglefly"] = {
	name="togglefly", 
	quick_ref="/togglefly [@entityname] [on|off]", 
	desc=[[toggle whether the entity is flying or not. 
During fly mode, we can use /walk command to reach places in the air. 
@param entityname: name of the entity.
e.g.
/togglefly @test on    : enable fly mode
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local playerEntity;
		playerEntity, cmd_text = CmdParser.ParsePlayer(cmd_text);
		playerEntity = playerEntity or fromEntity;
		if(playerEntity) then
			local bFly;
			bFly, cmd_text = CmdParser.ParseBool(cmd_text);	
			playerEntity:ToggleFly(bFly);
		end
	end,
};


Commands["dist"] = {
	name="dist", 
	quick_ref="/dist [@entityname]", 
	desc=[[return the block distance from current player to given player.
This command is usually run from NPC or command block to obtain distance to a nearby player. 
@param entityname: name of the entity.
@return the block distance. if entity is not found, it will return a very large number
e.g.
/if $(dist @a) <= 2 /tip hello  : when the distance to closest nearby player is less than 2 meters, say hello
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local toEntity;
		toEntity, cmd_text = CmdParser.ParsePlayer(cmd_text, fromEntity);
		if(fromEntity and toEntity) then
			local dist = fromEntity:DistanceSqTo(toEntity:GetBlockPos());
			if(dist > 0) then
				dist = dist ^ 0.5;
			end
			return dist;
		end
		-- return a very large number for unfound item.
		return 9999999999;
	end,
};
