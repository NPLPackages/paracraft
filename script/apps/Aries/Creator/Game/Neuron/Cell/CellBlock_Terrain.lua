--[[
Title: Terrain cell block
Author(s): LiXizhi
Date: 2013/7/14
Desc: Cells that generate land/water/overhangs procedurally. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/Cell/CellBlock_Terrain.lua");
local CellBlock = commonlib.gettable("MyCompany.Aries.Game.Neuron.CellBlock");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/NeuronBlock.lua");
local NeuronBlock = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronBlock");

local NeuronManager = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local CellBlock = commonlib.gettable("MyCompany.Aries.Game.Cell.CellBlock");

local CellBlock_Terrain = commonlib.inherit(CellBlock, commonlib.gettable("MyCompany.Aries.Game.Cell.CellBlock_Terrain"));

-----------------------------------------
-- terrain base class 
-----------------------------------------

function CellBlock_Terrain:ctor()
end

-- checking whether spliting condition is met. 
function CellBlock_Terrain:check_split(msg, src_neuron)
end





