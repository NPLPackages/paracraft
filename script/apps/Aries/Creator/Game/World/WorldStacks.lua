--[[
Title: World stack
Author(s): LiXizhi
Date: 2016/1/16
Desc: singleton class
only used by /pushworld and /loadworld command
-----------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/World/WorldStacks.lua");
local WorldStacks = commonlib.gettable("MyCompany.Aries.Game.WorldStacks");
WorldStacks:PopWorld();
-----------------------------------------------
]]
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon");
local WorldStacks = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.WorldStacks"))

-- a simple class for keeping track of world stack
local World = commonlib.inherit(nil, {});


function World:LoadWorld()
	local params = self.loadworld_params;
	if(params) then
		return Game.Start(params.worldpath, params.is_standalone, params.nid, params.gs_nid, params.ws_id);
	end
end

function World:GetDisplayName()
	return  self.displayname or L"返回上个世界";
end

function WorldStacks:ctor()
	self.worlds_stack = commonlib.List:new();
end


-- push current world to world stack. The world will be popped from the stack, 
-- when it is loaded again or the user explicitly load a world from UI. 
-- When there are worlds on the world stack, the esc window will show a big link button to load the world
-- on top of stack if the current world is different from it. 
-- @param displayname: the text to display on the big link button which bring the user back to world on top of the stack.
-- @return true if successfully pushed.
function WorldStacks:PushWorld(displayname)
	if(displayname=="") then
		displayname = nil;
	end
	local loadworld_params = Game.GetLoadWorldParams();
	if(not loadworld_params) then
		return;
	end
	if(self:IsTopOfStackWorld()) then
		LOG.std(nil, "warn", "WorldStacks", "duplicated push world is not allowed for %s", loadworld_params.worldpath);
		return;
	end
	
	local world = World:new({
		displayname = displayname,
		loadworld_params = loadworld_params,
	});
	self.worlds_stack:push_back(world);
	LOG.std(nil, "info", "WorldStacks", "%s is pushed with world path: %s", displayname, loadworld_params.worldpath);
	return true;
end

-- @return true if current world is same as the top of stack world
function WorldStacks:IsTopOfStackWorld()
	local loadworld_params = Game.GetLoadWorldParams();
	if(not loadworld_params) then
		return;
	end
	local last_world = self.worlds_stack:last();
	if(last_world and last_world.loadworld_params.worldpath == loadworld_params.worldpath) then
		return true;
	end
end

-- similar to GetTopOfStackWorld(), except that it will return nil, if current world is same as the top of stack world
function WorldStacks:GetReturnWorld()
	if(not self:IsTopOfStackWorld()) then
		return self:GetTopOfStackWorld();
	end
end

-- return the world on top of the stack, this may return nil
function WorldStacks:GetTopOfStackWorld()
	return self.worlds_stack:last();
end

-- we will only pop a world when it is the current world
-- @param bPopAll: if true, all world will be popped. 
function WorldStacks:PopWorld(bPopAll)
	if(bPopAll) then
		self.worlds_stack:clear();
	else
		if(self:IsTopOfStackWorld()) then
			self.worlds_stack:pop();
			return true;
		end
	end
end

function WorldStacks:ReturnLastWorld()
	local world = self:GetReturnWorld()
	if(world) then
		world:LoadWorld();
	end
end

WorldStacks:InitSingleton();