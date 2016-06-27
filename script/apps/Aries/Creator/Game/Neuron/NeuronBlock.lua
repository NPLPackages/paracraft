--[[
Title: Base class for a single neuron block
Author(s): LiXizhi
Date: 2013/3/17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/NeuronBlock.lua");
local NeuronBlock = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronBlock");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/STL.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/NeuronAPISandbox.lua");
local NeuronAPISandbox = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronAPISandbox");
local NeuronManager = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local NeuronBlock = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronBlock"));

local math_abs = math.abs;

-- default neuron messages
-- this is usually two sets of events. One set contains triggering events, the other set contains events that is passed down the axon once triggered. 
NeuronBlock.msg_templates = {
	-- fired when user clicks on a given block, and the block that received the click event will usually fire the "toggle" event to all of its axons. 
	-- msg.action can be nil or "toggle", "mem_zero", "reset_to_zero", "addmem", "break_synapse"
	["click"] = {type="click"},
	-- this msg is usually fired by an interactive neuron block when the user clicks on it. When a passive neuron block received this message, it will 
	-- search its memory and toggle its appearance according to previous "addmem". 
	["toggle"] = {type="toggle"},
	-- clear and remember it
	["mem_zero"] = {type="reset_to_zero"},
	-- clear without adding memory
	["reset_to_zero"] = {type="reset_to_zero"},
	-- once the a neuron receives a addmem msg, it will remember the relationship between the source neuron and the current state of itself. 
	-- so that once a "toggle" message is received, it will switch its appearance according to this newly added relationship. 
	["addmem"] = {type="addmem"},

	-- once received, the neuron block is reset to empty and marked as modified. When saving the world, empty neurons will be removed. 
	-- it will send "break_connection" to all of its axon neurons. 
	["destroy"] = {type="destroy"},
	-- Once received, it will break connection with the source neuron, and removed any memories associated with it. 
	["break_synapse"] = {type="break_synapse"},
	-- activate the script file associated with the block. 
	["script"] = {type="script"},
}
local msg_templates = NeuronBlock.msg_templates;

-- only for small relative position. 
local function GetSparseIndex(bx, by, bz)
	return by*256*256+bx*256+bz;
end

-----------------------------------------
-- signal class 
-----------------------------------------
local signal_class = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Neuron.signal_class"));
-- how many blocks per second that the signal is passed down. 
signal_class.speed = 5;
-- max distance between current block and the next block.  this equals to 10 seconds of speed. 
signal_class.max_distance = signal_class.speed*5;

-- default second per frame move
signal_class.default_sim_step = 0.033;
function signal_class:ctor()
	-- the message to pass along
	self.msg = self.msg;
	-- how far the signal has traveled. 
	self.dist = 0;
end

-- @param neuron: the parent neuron block object that owned this signal
-- @param delta_time: seconds that have passed. 
-- @return true if the signal is finished, otherwise return nil
function signal_class:FrameMove(neuron, delta_time)
	local last_dist = self.dist;
	local new_dist = last_dist + math.ceil(self.speed * (delta_time or signal_class.default_sim_step));
	self.dist = new_dist;
	local next_dist = self.next_dist
	if(next_dist) then
		if(next_dist > new_dist) then
			if( (next_dist - new_dist) > self.max_distance) then
				self.dist = self.next_dist - self.max_distance;
			end
			return;
		else
			local futher_dist;
			local axons = neuron.axons
			local pt = axons:first();
			while (pt) do
				local dist = pt.dist;
				if(dist > new_dist) then
					if(not futher_dist or dist < futher_dist) then
						futher_dist = dist;
					end
				elseif(dist > last_dist and dist <=new_dist) then
					neuron:ActivateAxonSynpase(pt, self.msg);
				end
				pt = axons:next(pt)
			end
			if(futher_dist) then
				self.next_dist = futher_dist;
			else
				return true;
			end
		end
	else
		local futher_dist;
		local axons = neuron.axons
		local pt = axons:first();
		while (pt) do
			if(pt.dist > new_dist) then	
				if(not futher_dist or pt.dist < futher_dist) then
					futher_dist = pt.dist;
				end
			else
				neuron:ActivateAxonSynpase(pt, self.msg);
			end
			pt = axons:next(pt)
		end
		if(futher_dist) then
			self.next_dist = futher_dist;
		else
			return true;
		end
	end
end

-----------------------------------------
-- neuron block base class 
-----------------------------------------
-- called every frame move. 
-- containing: x, y, z, state, coding and axons
function NeuronBlock:ctor()
	self.state = self.state;
	self.coding = self.coding;
	self.axons = self.axons or commonlib.List:new();
	-- mapping from sparse index to axon. 
	-- self.axons_map = self.axons_map;
end

-- load from an xml node. 
function NeuronBlock:LoadFromXMLNode(node)
	if(node) then
		local attr = node.attr;
		if(attr) then
			-- the activation file if any. 
			if(attr.filename and attr.filename~="") then
				self.filename = attr.filename;
			end
		end
		local i, sub_node;
		for i=1, #node do
			sub_node = node[i];
			if(sub_node.name == "mem") then
				local code_str = sub_node[1]
				if(code_str and type(code_str) == "string") then
					self.memory = NPL.LoadTableFromString(code_str);
				end
			elseif(sub_node.name == "axon") then
				self.axons_map = self.axons_map or {};
				self.axons_dist_map = self.axons_dist_map or {};
				local k, dendrite;
				for k=1, #sub_node do
					local dendrite = sub_node[k];
					local attr = dendrite.attr;
					if(attr) then
						local rx, ry, rz = tonumber(attr.x), tonumber(attr.y), tonumber(attr.z);
						if(rx) then
							local dist = math_abs(rx)+math_abs(ry)+math_abs(rz)
							local pt_new = {x=rx, y=ry, z=rz, dist = dist }
							self.axons:push_back(pt_new);
							local nIndex = GetSparseIndex(rx,ry,rz);
							self.axons_map[nIndex] = pt_new;
							self.axons_dist_map[dist] = pt_new;
						end
					end
				end
			end
		end
	end
end

-- whether this neruon is empty. 
function NeuronBlock:IsEmpty()
	if(self:GetAxonsCount() > 0 or self.filename) then
		return false;
	end
	if(self.memory and next(self.memory)~=nil) then
		return false;
	end
	return true;
end

-- whether the block is cooling down. some logics may only be active when neuron is not in CD state. 
function NeuronBlock:IsCoolDown()
	if(not self.cooldown or self.cooldown<NeuronManager.elapsed_time) then
		return false;
	else
		return true;
	end
end

-- add a cd in seconds to this neuron. 
-- if the neuron already has a larger active cd, it is ignored. 
function NeuronBlock:AddCoolDown(cd_seconds)
	if(not self.cooldown) then
		self.cooldown = NeuronManager.elapsed_time + cd_seconds;
	else
		self.cooldown = math.max(self.cooldown, NeuronManager.elapsed_time + cd_seconds);
	end
end

-- make this neuron not responsible for this number of seconds. 
function NeuronBlock:Sleep(cd_seconds)
	if(not cd_seconds) then
		self:ResetCoolDown();
	else
		self:AddCoolDown(cd_seconds);
	end
end

-- make no cool down. 
function NeuronBlock:ResetCoolDown()
	self.cooldown = nil;
end

-- serialize to xml string
function NeuronBlock:SerializeToXMLString()
	local out = {};
	out[#out+1] = format("<neuron x='%d' y='%d' z='%d' ", self.x, self.y, self.z);
	if(self.filename and self.filename~="") then
		out[#out+1] = format("filename='%s' ", self.filename)
	end
	out[#out+1] = ">\n"
	if(self.memory and next(self.memory)~=nil) then
		out[#out+1] = "<mem>";
		out[#out+1] = commonlib.serialize_compact(self.memory);
		out[#out+1] = "</mem>\n";
	end
	local axons = self.axons;
	if(axons and axons:size()>0) then
		out[#out+1] = "<axon>";
		local pt = axons:first();
		while (pt) do
			out[#out+1] = format("<d x='%d' y='%d' z='%d'/>", pt.x, pt.y, pt.z);
			pt = axons:next(pt)
		end
		out[#out+1] = "</axon>\n";
	end

	out[#out+1] = "</neuron>\n";
	return table.concat(out);
end

function NeuronBlock:SetModified()
	self.is_dirty = true;
end

-- whether it has an axon-dendrite connection with a given block.
function NeuronBlock:HasConnection(bx, by, bz)
	local rx, ry, rz = bx-self.x, by-self.y, bz-self.z;
	local nIndex = GetSparseIndex(rx, ry, rz);
	if(self.axons_map and self.axons_map[nIndex]) then
		-- already exist
		return true;
	end
end

-- connect the axon of this neuron to a foreign neuron, forming a axon-dendrite synapse
-- the axons are stored sorted according to distance to neuclia;
function NeuronBlock:ConnectBlock(bx, by, bz)
	local rx, ry, rz = bx-self.x, by-self.y, bz-self.z;
	local dist = math_abs(rx)+math_abs(ry)+math_abs(rz)
	
	self.axons_map = self.axons_map or {};

	local nIndex = GetSparseIndex(rx, ry, rz);
	if(self.axons_map[nIndex]) then
		-- already exist
		return;
	end
	self.axons_dist_map = self.axons_dist_map or {};
	local pt = self.axons_map[dist];

	local pt_new = {x=rx, y=ry, z=rz, dist = dist };
	self.axons:insert_after(pt_new, pt);

	-- added axon map
	self.axons_dist_map[dist] = pt_new; -- remember the last inserted dist to point map. 
	self.axons_map[nIndex] = pt_new;

	self:SetModified();
	return true;
end

function NeuronBlock:GetAxonsCount()
	local axons = self.axons;
	if(axons) then
		return axons:size();
	end
	return 0;
end

-- remove all axons
function NeuronBlock:ClearAxons()
	local axons = self.axons;
	if(axons) then
		axons:clear();
		self.axons_map = nil;
		self.axons_dist_map = nil;
	end
end

-- disconnect the axon of this neuron from a foreign neuron
function NeuronBlock:DisconnectBlock(bx, by, bz)
	local rx, ry, rz = bx-self.x, by-self.y, bz-self.z;

	if(self.axons_map) then
		local nIndex = GetSparseIndex(rx, ry, rz);
		local pt = self.axons_map[nIndex];
		if(pt) then
			local pt_last = self.axons_dist_map[pt.dist];
			if(pt_last and pt_last == pt) then
				if(pt.prev and pt.prev.dist == pt.dist) then
					self.axons_dist_map[pt.dist] = pt.prev;
				else
					self.axons_dist_map[pt.dist] = nil;
				end
			end
			self.axons:remove(pt);
			self.axons_map[nIndex] = nil;
			
			self:SetModified();
		end
	end
end

-- call this function to create a new signal that is associated with this neuron. 
-- The signal should pass down the axon when the framemove function is called
function NeuronBlock:make_new_signal(o)
	local signal = signal_class:new(o);
	if(not self.signals) then
		self.signals = commonlib.List:new();
	end
	self.signals:push_back(signal);
	return signal;
end

-- call this function to fire an action 
-- we support firing multiple action signals when the previous one has not fully finished. 
-- but generally, the activation logics may disallow repeated action firing. 
function NeuronBlock:FireAction(msg)
	-- this actually does nothing more than adding this neuron to active list.
	self:make_new_signal({msg = msg});
	NeuronManager.MakeActive(self);
end

-- make this neuron inactive thus no longer passing any messages. 
function NeuronBlock:MakeInactive()
	NeuronManager.MakeInactive(self);
end

-- @param pt: the axon point
function NeuronBlock:ActivateAxonSynpase(pt, msg)
	local x, y, z = self.x + pt.x, self.y + pt.y,self.z + pt.z;
	local next_neuron = NeuronManager.GetNeuron(x, y, z, true);
	if(next_neuron) then
		return next_neuron:Activate(msg, self);
	end
end

-- pt must be a valid table with x,y,z
function NeuronBlock:GetAxonNeuronByPoint(pt, bCreateIfNotExist)
	local x, y, z = self.x + pt.x, self.y + pt.y,self.z + pt.z;
	return  NeuronManager.GetNeuron(x, y, z, bCreateIfNotExist);
end

-- return an interator (pt, neuron) looping all axon neurons
function NeuronBlock:EachAxonNeuron()
	
	local axons = self.axons;
	local pt = axons:first();
		
	return function()
		local last_pt, neuron;
		last_pt = pt;
		if (last_pt) then
			neuron = self:GetAxonNeuronByPoint(last_pt);
			while(not neuron and last_pt) do
				last_pt = axons:next(last_pt);
				if(last_pt) then
					neuron = self:GetAxonNeuronByPoint(last_pt);
				end
			end
			if(last_pt) then
				pt = axons:next(last_pt);
			end
		end
		return last_pt, neuron;
	end
end

-- this function is called when pre-synapse AP is received by this neuron. 
-- The activation is series of signals in time. The coding model of the neuron 
-- @param msg: such as {type="click"}
-- @param src_neuron: the source neuron. if nil, it default to self.
-- decides whether and when an activation(AP) should be fired 
function NeuronBlock:Activate(msg, src_neuron)
	-- modify and compute and decide whether we need to call self:FireAction()
	local output_msg = self:OnActivated(msg, src_neuron or self)
	if(output_msg) then
		self:FireAction(output_msg);
	end
end

-- virtual function: this may be overridden  according to different types of neuron blocks. 
-- the default behavior emulates a standard memory neuron. 
-- @param src_neuron: the source neuron. 
-- @return: nil or output_msg. if nil, nothing happens. otherwise it return a message that should be passed down using FireAction
function NeuronBlock:OnActivated(msg, src_neuron)
	return self:OnActivated_Default(msg, src_neuron);
end

-- get the current block template id. 
function NeuronBlock:GetCurrentBlockID()
	return ParaTerrain.GetBlockTemplateByIdx(self.x,self.y,self.z);
end

-- get the block template object
function NeuronBlock:GetBlockTemplate()
	local block_id = self:GetCurrentBlockID();
	if(block_id) then
		return block_types.get(block_id);
	end
end

-- get the local index 
function NeuronBlock:get_block_local_index(dx, dy, dz)
	return dx*10000+dy*100+dz; 
end

-- remove any memory associated with the source neuron. 
-- return true, if memory is modified. 
function NeuronBlock:RemoveMemory(src_neuron)
	if(not src_neuron) then
		return
	end
	local dx, dy, dz = self.x - src_neuron.x, self.y -  src_neuron.y, self.z -  src_neuron.z;
	-- simply encode relative position to a sparse index
	local src_block_index = self:get_block_local_index(dx, dy, dz); 

	if(self.memory) then
		if(self.memory[src_block_index]) then
			self.memory[src_block_index] = nil;
			return true;
		end
	end
end

-- basic memory function, it will make a pair between the src_neuron, and the current one. 
-- memory = {src_block_index = {weight=50, dest= dest_block_id}}
-- @param src_neuron: the source neuron
-- @param value: a value usually between [0,50]. it will overwrite the privous one if value is bigger then the once stored. 
-- @param cur_block_id: if nil, the current block is fetched. otherwise we can also specify a forced value here
-- @return dest_block_id, weight_value
function NeuronBlock:AddMemoryWidth(src_neuron, value, cur_block_id)
	if(not src_neuron) then
		return
	end
	local dx, dy, dz = self.x - src_neuron.x, self.y -  src_neuron.y, self.z -  src_neuron.z;
	-- simply encode relative position to a sparse index
	local src_block_index = self:get_block_local_index(dx, dy, dz); 

	self.memory = self.memory or {};
	local memory = self.memory;
	memory[src_block_index] = memory[src_block_index] or {}
	local mem = memory[src_block_index];
	
	cur_block_id = cur_block_id or self:GetCurrentBlockID()
	if(mem.dest and mem.dest ~= cur_block_id) then
		if(mem.weight <= value) then
			mem.dest = cur_block_id;
			mem.weight = value;
		else
			-- input signal is not big enough to overwrite the old dest.
			-- TODO: we may need to save cur_block_id and value to a temporary memory. 
		end
	else
		mem.dest = cur_block_id;
		local new_value = (mem.weight or 0) + value;
		if(new_value > 50) then
			new_value = 50;
		end
		mem.weight = new_value;
	end
	return mem.dest, mem.weight;
end

-- toggle all nearby blocks that contains the buildin toggle function. 
function NeuronBlock:ToggleNearbyBlocks(radius)
	radius = radius or 1;
	local dx, dy, dz;
	for dx=-radius, radius do
		for dy=-radius, radius do
			for dz=-radius, radius do
				if(dx~=0 or dy~=0 or dz~=0) then
					local x, y, z = self.x + dx, self.y + dy, self.z + dz;
					local block_id = ParaTerrain.GetBlockTemplateByIdx(x, y, z);
					if(block_id) then
						local block_template = block_types.get(block_id);
						if(block_template and block_template.hasAction) then
							block_template:OnToggle(x,y,z);
						end
					end
				end
			end
		end
	end
end

-- create or get script scope
function NeuronBlock:GetScriptScope()
	if(not self._PAGESCRIPT) then
		self._PAGESCRIPT = {
			this = self,
		};
		setmetatable (self._PAGESCRIPT, NeuronAPISandbox.CreateGetSandbox())
	end
	return self._PAGESCRIPT;
end

-- set script and automatically reload if a different file is specified. 
function NeuronBlock:SetScript(filename)
	if(self.filename ~= filename) then
		if(filename == nil or filename == "") then
			self.filename = nil;
			self.activate_func = nil;
		else
			self.filename = filename;
			if(self.activate_func) then
				self:CheckLoadScript(true);
			end
		end
	end
end

-- check load script code if any. It will only load on first call. Subsequent calls will be very fast. 
-- usually one do not need to call this function explicitly, unless one wants to preload or reload. 
-- @param bReload: default to nil. 
function NeuronBlock:CheckLoadScript(bReload)
	if( bReload or self.activate_func == nil) then
		local func = NeuronManager.GetScriptCode(self.filename, bReload);
		self.activate_func = func;
		if(func) then
			-- load on first activation call.
			setfenv(func, self:GetScriptScope());
			local ok, errmsg = pcall(func);
			if(not ok) then
				LOG.std(nil, "error", "NeuronBlock", errmsg);
				GameLogic.ShowMsg(errmsg);
			end
		end
		NeuronManager.RegisterScript(self.filename, self);
	end
	return self.activate_func;
end

-- get script function if any. 
-- @param func_name: some known functions are "main"
-- @return the function or nil is returned. 
function NeuronBlock:GetScriptFunction(func_name, bReload)
	if(func_name and self:CheckLoadScript(bReload)) then
		local script_scope = self:GetScriptScope();
		return rawget(script_scope, func_name);
	end
end

-- the default behavior emulates a standard memory neuron. 
function NeuronBlock:OnActivated_Default(msg, src_neuron)
	local msg_type = type(msg)
	if(msg_type == "table") then
		local msg_type = msg.type;
		local msg_value = msg.value;

		if(self.filename) then
			local main_func = self:GetScriptFunction("main");
			if(main_func and type(main_func) == "function") then
				main_func(msg);
			end
		end

		if(msg_type == "destroy") then
			--if(self.memory) then
				--self.memory = nil;
				--self:SetModified();
			--end
			return msg_templates.break_synapse;
		elseif(msg_type == "toggle") then
			local dest_block_id, new_value = self:AddMemoryWidth(src_neuron, msg_value or 1);
			if(new_value and new_value >= 50) then
				dest_block_id = dest_block_id or 0;
				local last_block_id = ParaTerrain.GetBlockTemplateByIdx(self.x, self.y, self.z);
				if(last_block_id ~= dest_block_id) then
					BlockEngine:SetBlock(self.x, self.y, self.z, dest_block_id);
					local dest_block = block_types.get(dest_block_id);
					if(dest_block) then
						if(dest_block.toggle_sound) then
							dest_block:play_toggle_sound();
						else
							dest_block:play_create_sound();
						end
					end
				else
					-- trigger the "toggle" or "click" event if the last block is already the dest block. 
					if(dest_block_id) then
						local dest_block = block_types.get(dest_block_id);
						if(dest_block) then
							if(dest_block.hasAction) then
								-- if the block template contains action, we will the toggle message will generate another click message on itself. 
								self:Activate(msg_templates["click"]);
							end
							dest_block:OnToggle(self.x, self.y, self.z);
						end
					end
				end
				
			end
		elseif(msg_type == "addmem") then
			self:AddMemoryWidth(src_neuron, msg_value or 50);
			self:SetModified();
		elseif(msg_type == "break_synapse") then
			if(self:RemoveMemory(src_neuron)) then
				self:SetModified();
			end
		elseif(msg_type == "click") then
			local action = msg.action;
			if(not action or action == "toggle" or action == "user_toggle") then
				local block_template = self:GetBlockTemplate();
				if(block_template) then
					block_template:OnToggle(self.x, self.y, self.z);
				end
				if(action == "user_toggle") then
					if(self:GetAxonsCount() == 0) then
						-- if the user does not specify any learnt axons, we will automatically 
						-- searching in 5*5*5 area of nearby blocks that contains buildin toggle action and toggle it. 
						self:ToggleNearbyBlocks(2);
						return;
					end
				end
				return msg_templates["toggle"];
			elseif(msg_templates[action]) then
				return msg_templates[action];
			end
		elseif(msg_type == "script") then
			
		elseif(msg_type == "mem_zero") then
			self:AddMemoryWidth(src_neuron, msg_value or 50, 0);
			self:SetModified();
		elseif(msg_type == "reset_to_zero") then
			if(self:GetAxonsCount() == 0) then
				local last_block_id = self:GetCurrentBlockID()
				if(last_block_id > 0) then
					local block_template = self:GetBlockTemplate();
					if(block_template) then
						BlockEngine:SetBlockToAir(self.x, self.y, self.z);
					end
				end
			end
		end
	elseif(msg_type == "number") then
		local dest_block_id, new_value = self:AddMemoryWidth(src_neuron, msg_value or 1);
		if(new_value and new_value >= 50) then
			BlockEngine:SetBlock(self.x, self.y, self.z, dest_block_id or 0);
		end
	end
end

-- this function is called every framemove to pass signals down the axons
function NeuronBlock:FrameMove()
	-- for each signal, pass down a fixed distance, and stop or call the active function of the connected neuron.
	if(self.signals) then
		local signal = self.signals:first();
		while (signal) do
			if(signal:FrameMove(self)) then
				signal = self.signals:remove(signal);
			else
				signal = self.signals:next(signal);
			end
		end
		if(self.signals:size() == 0) then
			self:MakeInactive();
		end
	else
		self:MakeInactive();
	end
end

