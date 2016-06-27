--[[
Title: Tree cell block
Author(s): LiXizhi
Date: 2013/7/14
Desc: Cells that generate Tree trunk/root/earth/leaves/fruit/seed procedurally. and may turn into a forest. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/Cell/CellBlock_Tree.lua");
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

local CellBlock_Tree = commonlib.inherit(CellBlock, commonlib.gettable("MyCompany.Aries.Game.Cell.CellBlock_Tree"));

-----------------------------------------
-- tree cell
-----------------------------------------

function CellBlock_Tree:ctor()
end

-- checking whether spliting condition is met. 
function CellBlock_Tree:check_split(msg, src_neuron)
end





