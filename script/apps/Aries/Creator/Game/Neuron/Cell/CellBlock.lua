--[[
Title: Base class of cell block
Author(s): LiXizhi
Date: 2013/7/14
Desc: a cell block is a special kind of neuron block that can split into 2 cells. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/Cell/CellBlock.lua");
local CellBlock = commonlib.gettable("MyCompany.Aries.Game.Cell.CellBlock");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/NeuronBlock.lua");
local NeuronBlock = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronBlock");

local NeuronManager = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local block = commonlib.gettable("MyCompany.Aries.Game.block")

local CellBlock = commonlib.inherit(NeuronBlock, commonlib.gettable("MyCompany.Aries.Game.Cell.CellBlock"));

local math_abs = math.abs;

-----------------------------------------
-- cell block base class 
-----------------------------------------

function CellBlock:ctor()
end

-- virtual function from neuron class. 
function CellBlock:OnActivated(msg, src_neuron)
	self:check_split(msg, src_neuron);
end

-- checking whether spliting condition is met. 
function CellBlock:check_split(msg, src_neuron)
end

-- split into two cells
function CellBlock:split()
end




