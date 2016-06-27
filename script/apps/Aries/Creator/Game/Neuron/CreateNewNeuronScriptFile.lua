--[[
Title: Create a new script file. 
Author(s): LiXizhi
Date: 2013/8/20
Desc: editing the neuron, such as its dendrites, axon connections, neural coding, etc. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/CreateNewNeuronScriptFile.lua");
local CreateNewNeuronScriptFile = commonlib.gettable("MyCompany.Aries.Game.Tasks.CreateNewNeuronScriptFile");
CreateNewNeuronScriptFile.ShowPage(function(filename)
end)
-------------------------------------------------------
]]

local NeuronManager = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronManager");
local NeuronBlock = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronBlock");
local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local CreateNewNeuronScriptFile = commonlib.gettable("MyCompany.Aries.Game.Tasks.CreateNewNeuronScriptFile");

------------------------
-- page function 
------------------------
local page;
function CreateNewNeuronScriptFile.ShowPage(callbackFunc)
	CreateNewNeuronScriptFile.callbackFunc = callbackFunc;
	-- display a page containing all operations that can apply to current selection, like deletion, extruding, coloring, etc. 
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Neuron/CreateNewNeuronScriptFile.html", 
			name = "CreateNewNeuronScriptFile.ShowPage", 
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			isShowTitleBar = false,
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = 1,
			allowDrag = false,
			click_through = true,
			directPosition = true,
				align = "_ct",
				x = -350,
				y = -200,
				width = 700,
				height = 400,
		});
	
end

function CreateNewNeuronScriptFile.OnInit()
	page = document:GetPageCtrl();
end

function CreateNewNeuronScriptFile.OnFinishedFile(filename)
	if(filename) then
		page:CloseWindow();

		if(CreateNewNeuronScriptFile.callbackFunc) then
			CreateNewNeuronScriptFile.callbackFunc(filename);
		end
	end
end