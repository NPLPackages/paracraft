--[[
Title: Heart beat and simulation for all neurons
Author(s): LiXizhi
Date: 2013/3/17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/NeuronSimulator.lua");
local NeuronSimulator = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronSimulator");
NeuronSimulator.Init()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/NeuronManager.lua");
local NeuronManager = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local block = commonlib.gettable("MyCompany.Aries.Game.block")

local NeuronSimulator = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronSimulator");

-- how many seconds to framemove once
NeuronSimulator.framemove_interval = 0.02;
local last_frame_time = 0;


function NeuronSimulator.Init()
	NeuronManager.Init();
end

-- called every frame move. 
function NeuronSimulator.FrameMove(deltaTime)
	deltaTime = deltaTime/1000;
	NeuronManager.FrameMove(deltaTime);
	last_frame_time = last_frame_time + deltaTime;
	if(last_frame_time > NeuronSimulator.framemove_interval) then
		last_frame_time = 0;
		-- TODO: find a better way to framemove only limited number of neurons per frame
		local active_neurons = NeuronManager.GetActiveNeurons();
		for _, neuron in pairs(active_neurons) do
			neuron:FrameMove();
		end
	end
end

