--[[
Title: Managing all neurons
Author(s): LiXizhi
Date: 2013/3/17
Desc: Load/Save all neurons making them persistent. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/NeuronManager.lua");
local NeuronManager = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronManager");
NeuronManager.Init()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/NeuronBlock.lua");
local NeuronBlock = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronBlock");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local NeuronManager = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronManager");

-- all neurons mapping from position to neuron object. 
local neuron_cache = {};
-- all active neurons mapping from position to neuron object. 
-- active neurons are neurons that is in action potential and require simulation engine to pass the sign through its axon to lower level neurons. 
-- since the signal takes time to travel in axons according to distance. it may take several seconds for some signal to reach the farthest neuron. 
local active_neurons = {};
local active_neurons_tmp = {};
local scripts = {};

-- in seconds
NeuronManager.elapsed_time = 0;

local default_filename = "neurons.xml";

local function GetSparseIndex(bx, by, bz)
	return by*30000*30000+bx*30000+bz;
end

-- called for each world.
function NeuronManager.Init()
	neuron_cache = {};
	active_neurons = {};
	active_neurons_tmp = {};
	scripts = {};
end

--------------------------------
-- script related
--------------------------------

-- get the full path from relative script file name. 
function NeuronManager.GetScriptFullPath(filename)
	return format("%sscript/blocks/%s", GameLogic.current_worlddir, filename);
end

-- get script code. all functions will be reset. 
-- @return function or false or nil. 
function NeuronManager.GetScriptCode(filename, bReload)
	if(not filename or filename == "") then
		return false;
	end
	
	local script = scripts[filename];
	if(not script) then
		script = {};
		scripts[filename] = script;
	end

	local func = script.func;

	if(bReload or func == nil) then
		func = false;
		local filename_full = NeuronManager.GetScriptFullPath(filename);
		local file = ParaIO.open(filename_full, "r");
		if(file:IsValid()) then
			local text = file:GetText();
			if(text and text~="") then
				local code_func, errormsg = loadstring(text, filename_full);
				if(not code_func) then
					LOG.std(nil, "error", "NeuronBlock", "<Runtime error> syntax error while loading code in file:%s\n%s", filename_full, tostring(errormsg));
					GameLogic.ShowMsg(format("<syntax error>:%s|%s", filename_full, tostring(errormsg)))
				else
					func = code_func;
				end
			end
			file:close();
		else
			GameLogic.ShowMsg(format("<File Not Found>:%s", filename_full));
		end	
		if(not func) then
			LOG.std(nil, "error", "NeuronBlock", "%s not valid neuron file", filename_full);
		end
		script.func = func;
	end
	return func;
end

-- Each neuronblock will call this function when a script file is attached, so that when file is modified externally
-- it will got recompiled automatically. 
function NeuronManager.RegisterScript(filename, neuron)
	local script = scripts[filename];
	if(script) then
		script.neurons = script.neurons or {};
		script.neurons[neuron] = true;
	end
end

-- just in case a neuron filename is modified externally, this function is automatically called by file monitor
function NeuronManager.ReloadScript(filename)
	local script = scripts[filename];
	if(script and script.neurons) then
		local count = 0;
		local neuron, _;
		for neuron, _ in pairs(script.neurons) do
			neuron:CheckLoadScript(true);
			count = count + 1;
		end
		LOG.std(nil, "info", "NeuronManager.ReloadScript", "%s reloaded %d neurons", filename, count);
		GameLogic.ShowMsg(format("%s reloaded %d neurons", filename, count));
	end
end

--------------------------------
-- mod related
--------------------------------
local mods = {};

-- each mod file should call this function to register a mod
-- @note: mod name must be the same as the filename and is case-sensitive. 
function NeuronManager.RegisterMod(name, mod)
	mods[name] = mod;
end

-- get a mod singleton object. 
function NeuronManager.GetMod(name)
	if(name) then
		return mods[name];
	end
end

-- check load a mod by its name. 
function NeuronManager.LoadMod(name)
	local mod = NeuronManager.GetMod(name);
	if(not mod) then
		local filename = format("(gl)script/apps/Aries/Creator/Game/Neuron/Mod/%s.lua", name);
		NPL.load(filename);
		mod = NeuronManager.GetMod(name);
	end
	return mod;
end

--------------------------------
-- manager related
--------------------------------

-- Load all neuron data from a given XML file. 
-- @param filename: if nil, it first search the "[currentworld]/blockworld.lastsave/neurons.xml", if not found, it will search "[currentworld]/blockworld/neurons.xml"
-- @return true if there is local NPC file. or nil if not. 
function NeuronManager.LoadFromFile(filename)
	if(not filename) then
		local test_filename = format("%sblockworld.lastsave/%s", ParaWorld.GetWorldDirectory(), default_filename);
		if(ParaIO.DoesAssetFileExist(test_filename, true))then
			filename = test_filename;
		else
			test_filename = format("%sblockworld/%s", ParaWorld.GetWorldDirectory(), default_filename);
			if(ParaIO.DoesAssetFileExist(test_filename, true))then
				filename = test_filename;
			end
		end
	end

	if(not filename) then
		return;
	end
	local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
	if(xmlRoot) then
		local count = 0;
		local node;
		for node in commonlib.XPath.eachNode(xmlRoot, "/neurons/neuron") do
			local attr = node.attr;
			if(attr and attr.x) then
				local bx, by, bz = tonumber(attr.x), tonumber(attr.y), tonumber(attr.z);
				local neuron = NeuronManager.GetNeuron(bx, by, bz, true);
				if(neuron) then
					count = count + 1;
					neuron:LoadFromXMLNode(node);
				end
			end
		end
		LOG.std(nil, "system", "NeuronManager", "loading %d neurons from file: %s", count, filename);
		return true;
	end
end

-- @param bSaveToLastSaveFolder: whether to save block to "blockworld.lastsave" folder
function NeuronManager.SaveToFile(bSaveToLastSaveFolder)
	local filename;
	if(bSaveToLastSaveFolder) then
		filename = format("%sblockworld.lastsave/%s", ParaWorld.GetWorldDirectory(), default_filename);
	else
		filename = format("%sblockworld/%s", ParaWorld.GetWorldDirectory(), default_filename);
	end
	local file = ParaIO.open(filename, "w");
	if(file:IsValid()) then
		file:WriteString([[<neurons offsets="0,0,0" file_version="0.1">]]);
		file:WriteString("\n");

		local index, neuron;
		for index, neuron in pairs(neuron_cache) do
			if( not neuron:IsEmpty()) then
				local str = neuron:SerializeToXMLString();
				if(str) then
					file:WriteString(str);
				end
			end
		end

		file:WriteString([[</neurons>]]);
		file:close();
	end
end

-- this function can be called when traversing the active_neurons table
-- The behavior of next() is undefined if, during the traversal, you assign any value to a non-existent field in the table. 
-- You may however modify existing fields. In particular, you may clear existing fields. 
function NeuronManager.MakeInactive(neuron)
	local sparse_index = GetSparseIndex(neuron.x, neuron.y, neuron.z)
	active_neurons[sparse_index] = nil;
	active_neurons_tmp[sparse_index] = nil;
end

-- add a neuron to simulation list. what it does is to first insert it to a temporary field and then during framemove, insert to the real active neuron list. 
function NeuronManager.MakeActive(neuron)
	local sparse_index = GetSparseIndex(neuron.x, neuron.y, neuron.z)
	active_neurons_tmp[sparse_index] = neuron;
end

function NeuronManager.GetActiveNeurons()
	return active_neurons;
end

-- create get a given neuron at position. 
function NeuronManager.GetNeuron(bx, by, bz, bCreateIfNotExist)
	local sparse_index = GetSparseIndex(bx, by, bz);
	local block = neuron_cache[sparse_index];
	if(block) then
		return block;
	elseif(bCreateIfNotExist) then
		-- create a default block
		block = NeuronBlock:new({x=bx, y=by, z=bz});
		neuron_cache[sparse_index] = block;
		return block;
	end
end

-- remove a neuron
function NeuronManager.RemoveNeuron(bx, by, bz)
	local sparse_index = GetSparseIndex(bx, by, bz);
	local block = neuron_cache[sparse_index];
	if(block) then
		block:Activate(NeuronBlock.msg_templates["destroy"]);
	end
end

-- called every frame move. 
function NeuronManager.FrameMove(deltaTime)
	NeuronManager.elapsed_time = NeuronManager.elapsed_time + deltaTime;
	local sparse_index, neuron
	for sparse_index, neuron in pairs(active_neurons_tmp) do
		active_neurons_tmp[sparse_index] = nil;
		active_neurons[sparse_index] = neuron;
	end
end

