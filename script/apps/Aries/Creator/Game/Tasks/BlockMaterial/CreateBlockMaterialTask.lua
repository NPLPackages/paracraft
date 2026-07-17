--[[
Title: Create Block Material task
Author(s): LiXizhi
Date: 2022/11/23
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BlockMaterial/CreateBlockMaterialTask.lua");
local task = MyCompany.Aries.Game.Tasks.CreateBlockMaterialTask:new({blockX = result.blockX,blockY = result.blockY, blockZ = result.blockZ, 
	materialId=1, side = 1, nohistory=false})

local task = MyCompany.Aries.Game.Tasks.CreateBlockMaterialTask:new({blocks = {{x,y,z,side,materialId}},
	materialId=1, nohistory=false})
task:Run();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local CreateBlockMaterialTask = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.CreateBlockMaterialTask"));

-- if true, we will skip history
CreateBlockMaterialTask.nohistory = nil

local function SideToFaceIndex(side)
	return side or -1;
end

function CreateBlockMaterialTask:ctor()
end

function CreateBlockMaterialTask:TryPaintSingleFace(x, y, z, faceId, materialId)
	local blockTemplate = BlockEngine:GetBlock(x,y,z)
	if(blockTemplate and blockTemplate:canPaintMaterial()) then
		local lastMatId = BlockEngine:GetBlockExternalMaterial(x, y, z, faceId)
		BlockEngine:SetBlockExternalMaterial(x, y, z, faceId, materialId)
		if(materialId and materialId > 0) then
			blockTemplate:play_create_sound(blockTemplate:ComputeSoundVolumeByBlockPos(x, y, z));
		else
			blockTemplate:play_break_sound(blockTemplate:ComputeSoundVolumeByBlockPos(x, y, z));

			-- create some block pieces using diffuse texture
			if(lastMatId and lastMatId > 0) then
				local material = ParaAsset.GetBlockMaterial(lastMatId);
				local attr = material:GetAttributeObject();
				if (attr:IsValid()) then 
					local materialDiffuseTex = attr:GetField("DiffuseFullPath", "")
					if(materialDiffuseTex and materialDiffuseTex~= "") then
						blockTemplate:CreateBlockPieces(x, y, z, 0.5, materialDiffuseTex);	
					end
				end
			end
		end
		return true;
	end
end

function CreateBlockMaterialTask:Run()
	self.finished = true;
	self.history = {};
	

	local add_to_history;
	if(self.materialId and self.blockX and not self.blocks) then
		self.faceId = SideToFaceIndex(self.side)
		self.last_material_id = BlockEngine:GetBlockExternalMaterial(self.blockX,self.blockY,self.blockZ, self.faceId);

		if(self:TryPaintSingleFace(self.blockX,self.blockY,self.blockZ, self.faceId, self.materialId)) then
			if(not self.nohistory) then
				if(GameLogic.GameMode:CanAddToHistory()) then
					add_to_history = true;
					self.add_to_history = true;
				end
			end
		else
			return
		end
	elseif(self.blocks) then
		local dx = self.blockX or 0;
		local dy = self.blockY or 0;
		local dz = self.blockZ or 0;

		if(not self.nohistory) then
			if(GameLogic.GameMode:CanAddToHistory()) then
				add_to_history = true;
				self.add_to_history = true;
			end
		end

		local faceId = self.side and SideToFaceIndex(self.side);
		local materialId = self.materialId;
		BlockEngine:BeginUpdate()
		for _, b in ipairs(self.blocks) do
			local x, y, z = b[1]+dx, b[2]+dy, b[3]+dz;
			self:AddFace(x,y,z, b[4] and SideToFaceIndex(b[4]) or faceId, b[5] or materialId);
		end
		BlockEngine:EndUpdate()
	end

	if(add_to_history) then
		UndoManager.PushCommand(self);
	end
	if(self.blockX and not self.isSilent) then
		local tx, ty, tz = BlockEngine:real(self.blockX,self.blockY,self.blockZ);
		GameLogic.PlayAnimation({animationName = "Create",facingTarget = {x=tx, y=ty, z=tz},});
	end
end

-- only used in batch faces
function CreateBlockMaterialTask:AddFace(x,y,z, faceId, materialId)
	local blockTemplate = BlockEngine:GetBlock(x,y,z)
	if(blockTemplate and blockTemplate:canPaintMaterial()) then
		if(self.add_to_history) then
			local last_material_id = BlockEngine:GetBlockExternalMaterial(x,y,z, faceId);
			self.history[#(self.history)+1] = {x,y,z, faceId, last_material_id, materialId};
		end
		BlockEngine:SetBlockExternalMaterial(x, y, z, faceId, materialId)
		return true;
	end
end

function CreateBlockMaterialTask:Redo()
	if(self.blockX and self.materialId) then
		BlockEngine:SetBlockExternalMaterial(self.blockX,self.blockY,self.blockZ, self.faceId, self.materialId);
	elseif((#self.history)>0) then
		BlockEngine:BeginUpdate()
		for _, b in ipairs(self.history) do
			BlockEngine:SetBlockExternalMaterial(b[1],b[2],b[3], b[4], b[6] or -1);
		end
		BlockEngine:EndUpdate()
	end
end

function CreateBlockMaterialTask:Undo()
	if(self.blockX and self.last_material_id) then
		BlockEngine:SetBlockExternalMaterial(self.blockX,self.blockY,self.blockZ, self.faceId, self.last_material_id);
	elseif((#self.history)>0) then
		BlockEngine:BeginUpdate()
		for _, b in ipairs(self.history) do
			BlockEngine:SetBlockExternalMaterial(b[1],b[2],b[3], b[4], b[5] or -1);
		end
		BlockEngine:EndUpdate()
	end
end
