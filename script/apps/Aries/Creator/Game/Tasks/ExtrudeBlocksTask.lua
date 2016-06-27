--[[
Title: Extruding all input blocks 
Author(s): LiXizhi
Date: 2013/2/10
Desc: extruding all input blocks in the positive/negative y direction. 
Support undo/redo
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ExtrudeBlocksTask.lua");
local task = MyCompany.Aries.Game.Tasks.ExtrudeBlocks:new({dy = 1, blocks={},})
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")

local ExtrudeBlocks = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.ExtrudeBlocks"));

ExtrudeBlocks.max_radius = 30;

function ExtrudeBlocks:ctor()
end

function ExtrudeBlocks:Run()
	
	if(((self.dx or 0) + (self.dy or 0) + (self.dz or 0)) ~= 0 and (self.blocks and #(self.blocks) > 0) ) then
		self.finished = true;

		self.history = {};
		self.step = 1;

		GameLogic.PlayAnimation({animationName = "RaiseTerrain",});

		local dx = self.dx or 0;
		local dy = self.dy or 0;
		local dz = self.dz or 0;

		local i;
		for i = 1, #(self.blocks) do
			local b = self.blocks[i];
			local x, y, z = b[1]+dx, b[2]+dy, b[3]+dz;
			if(ParaTerrain.GetBlockTemplateByIdx(x,y,z) == 0) then
				local from_id, from_data, from_entity_data = BlockEngine:GetBlockFull(b[1],b[2],b[3]);
				local to_id = 0;
				if(from_id and from_id>0) then
					BlockEngine:SetBlock(x,y,z, from_id, from_data, 3, from_entity_data);
					self.history[#(self.history)+1] = {x,y,z, from_id, to_id, from_data, from_entity_data};
				end
			end
		end
		if(GameLogic.GameMode:CanAddToHistory()) then
			if(#(self.history) > 0) then
				UndoManager.PushCommand(self);
			end
		end
	end
end

function ExtrudeBlocks:FrameMove()
	self.finished = true;
end

function ExtrudeBlocks:Redo()
	if((#self.history)>0) then
		local _, b;
		for _, b in ipairs(self.history) do
			BlockEngine:SetBlock(b[1],b[2],b[3], b[4] or 0, b[6], b[7]);
		end
	end
end

function ExtrudeBlocks:Undo()
	if((#self.history)>0) then
		local _, b;
		for _, b in ipairs(self.history) do
			BlockEngine:SetBlock(b[1],b[2],b[3], b[5] or 0);
		end
	end
end
