--[[
Title: sandbox api environment for the neuron 
Author(s): LiXizhi
Date: 2013/8/19
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/NeuronAPISandbox.lua");
local NeuronAPISandbox = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronAPISandbox");
local sandbox = NeuronAPISandbox.CreateGetSandbox();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/APISandbox/CreatorAPISandbox.lua");
local CreatorAPISandbox = commonlib.gettable("MyCompany.Aries.Game.APISandbox.CreatorAPISandbox");

local NeuronAPISandbox = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronAPISandbox");

-- create get sandbox
function NeuronAPISandbox.CreateGetSandbox()
	return CreatorAPISandbox.CreateGetSandbox();
end
