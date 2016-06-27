--[[
Title: Local NPC
Author(s): LiXizhi
Date: 2010/2/10
Desc: Loading and saving all  NPCs in the game world. Local NPCs in local worlds are all non-persistent characters that are created from XML file. 
The LocalNPC class provide an extensible NPC AI framework for loading and saving NPC and their AI states.
In most cases, local NPC file is saved in a file called "LocalNPC.xml" under the current world directory. 

<pe:mcml>
<pe:npc>
	<pe:aimod id="SimpleTalk">{"1111;2222;33333;4444;555;"}</pe:aimod>
	<pe:aimod id="SimpleTalk"/>
</pe:npc>
<pe:mcml>
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/AI/LocalNPC.lua");
local LocalNPC = commonlib.gettable("MyCompany.Aries.Creator.AI.LocalNPC")
LocalNPC:Init();
LocalNPC:LoadFromFile();
LocalNPC:CreateNPCCharacter({IsCharacter=true, AssetFile="", name="local:abc", DisplayName=""})
LocalNPC:OnClickCharacter(char);
LocalNPC:InvokeEditor(char, "SimpleTalk");
-------------------------------------------------------
]]
local NPC = commonlib.gettable("MyCompany.Aries.Quest.NPC");

-- create class 
local LocalNPC = commonlib.gettable("MyCompany.Aries.Creator.AI.LocalNPC")

-- mapping from npl global name to npc_instance, where npc_instance={ai_mods = {}}, where ai_mods is a map from aimod to aimod_data
-- e.g. {"local:npc1" = {ai_mods = {base={}, SimpleTalk={},}},  "local:npc2" = {}, ...}
LocalNPC.npcs = {};

-- mapping from ai module name to ai module class. 
LocalNPC.aimods = {};

-- defualt file to save to if no filename is provided. 
LocalNPC.defaultNPCFile = "LocalNPC.xml";
-- xml file version
LocalNPC.Version = "1.0"


-- call this only once
function LocalNPC:Init()
	if(self.Inited) then
		return 
	end
	self.Inited = true;
	
	NPL.load("(gl)script/apps/Aries/Creator/AI/aimod_base.lua");
	MyCompany.Aries.Creator.AI.aimod_base.main();
	
	NPL.load("(gl)script/apps/Aries/Creator/AI/SimpleTalk.lua");
	MyCompany.Aries.Creator.AI.SimpleTalk.main();
	
	-- TODO: load more modules here
end


-- register a new ai module with the local NPC. 
-- @param aimod_name: ai module name
-- @param aimod_class: the ai module class table. see aimod_base for example
function LocalNPC:RegisterAIMod(aimod_name, aimod_class)
	self.aimods[aimod_name] = aimod_class;
end


-- get ai module by name. 
-- @return the module class is returned or nil if not found. 
function LocalNPC:GetAIModule(name)
	if(name) then
		return self.aimods[name];
	end	
end

-- Load all NPCs from a given XML file. 
-- @param filename: if nil, it is "[currentworld]/LocalNPC.xml"
-- @return true if there is local NPC file. or nil if not. 
function LocalNPC:LoadFromFile(filename)
	if(not filename) then
		filename = ParaWorld.GetWorldDirectory()..self.defaultNPCFile;
	end
	
	local xmlRoot = ParaXML.LuaXML_ParseFile(filename);
	if(xmlRoot) then
		commonlib.log("loading local NPC file: %s\n", filename);
		local node;
		for node in commonlib.XPath.eachNode(xmlRoot, "/pe:mcml/pe:npc") do
			if(node.attr) then
				local obj_params = {
					name = node.attr.name,
					IsCharacter = true,
					x = tonumber(node.attr.x),
					y = tonumber(node.attr.y),
					z = tonumber(node.attr.z),
					facing = tonumber(node.attr.facing) or 0,
					scaling = tonumber(node.attr.scaling),
					AssetFile = node.attr.AssetFile,
					DisplayName = node.attr.DisplayName,
				};
				LocalNPC:CreateNPCCharacter(obj_params, node);
			end
		end
		return true;
	end
end

-- Save all NPCs to a given XML file. 
-- @param filename: if nil, it is "[currentworld]/LocalNPC.xml"
function LocalNPC:SaveToFile(filename)
	if(not filename) then
		filename = ParaWorld.GetWorldDirectory()..self.defaultNPCFile;
	end
	local pe_root = {name="pe:mcml",  attr = {npc_version = LocalNPC.Version} }
	local name, npc_instance
	for name, npc_instance in pairs(self.npcs) do
		local char = ParaScene.GetObject(name);
		if(char:IsCharacter()) then
			local att = char:GetAttributeObject();
			
			-- create pe:npc node for each character. 
			local x,y,z = char:GetPosition();
			local scaling = char:GetScale()
			if(math.abs(scaling - 1) < 0.01) then
				scaling = nil;
			end
			local pe_npc = {name="pe:npc", attr = {
					name = char.name,
					x = x, y = y, z = z,
					AssetFile = char:GetPrimaryAsset():GetKeyName(),
					scaling  = scaling,
					facing = char:GetFacing(),
					DisplayName = att:GetDynamicField("DisplayName", ""), 
				},}
			pe_root[#pe_root + 1] = pe_npc;
			
			local aimod_name, aimod_data
			for aimod_name, aimod_data in pairs(npc_instance.ai_mods) do
				-- serialize each npc mod for this npc
				local aimod = self:GetAIModule(aimod_name);
				if(aimod) then
					local ai_data = aimod.Serialize(char, aimod_data);
					local pe_aimod = {name="pe:aimod", attr = {name = aimod.name, version = aimod.version},};
					if(ai_data) then
						local cdata = commonlib.serialize_compact(ai_data)
						if(cdata) then
							-- cdata = "<![CDATA["..cdata.."]]>";
							pe_aimod[1] = cdata;
						end	
					end
					pe_npc[#pe_npc + 1] = pe_aimod;
				end
			end
		end	
	end
	
	local xml_data = commonlib.Lua2XmlString(pe_root, true);
	if(xml_data) then
		local file = ParaIO.open(filename, "w");
		if(file:IsValid()) then
			file:WriteString(xml_data)
			file:close();
			commonlib.log("local NPC file is successfully saved to disk: %s\n", filename)
		end
	end	
	
end

-- delete a given character in the scene. 
function LocalNPC:RemoveNPCCharacter(npc_name)
	self.npcs[npc_name] = nil;
end

-- Create a non-persistent NPC character in the scene, and load all of its attached AI modules. 
-- @param obj_params: this is the character creation obj_params. such as {IsCharacter=true, AssetFile="", name="abc", DisplayName=""}. 
-- @param AI_node: nil or it can be the parent XML node from which to load all AI modules. 
function LocalNPC:CreateNPCCharacter(obj_params, AI_node)
	if(not obj_params and not AI_node) then
		return;
	end
	local char = nil;
	if(obj_params and obj_params.IsCharacter) then
		-- give a default name that begins with "local:"
		if(not obj_params.name) then
			-- create a random name
			obj_params.name = tostring(ParaGlobal.timeGetTime());
		end
		if(not string.match(obj_params.name, "^local:")) then
			obj_params.name = "local:"..obj_params.name;
		end
		obj_params.DisplayName = obj_params.DisplayName or "";

		-- set default position if no one is provided
		if(not obj_params.x)then
			local x,y,z = ParaScene.GetPlayer():GetPosition();
			obj_params.x = x;
			obj_params.y = y;
			obj_params.z = z;
		end
		
		-- set default facing if no one is provided
		if(not obj_params.facing and obj_params.IsCharacter)then
			obj_params.facing = ParaScene.GetPlayer():GetFacing();
		end
		
		-- make it non-persistent
		obj_params.IsPersistent = false;
	
		char = ObjEditor.CreateObjectByParams(obj_params);
		
		if(char and char:IsValid()) then
			-- attach to scene. 
			ParaScene.Attach(char);
			
			commonlib.log("Local NPC %s is created\n", obj_params.name);
			-- commonlib.echo(obj_params)
			char:SetPersistent(false);
			
			-- add default head on display text. 
			local att = char:GetAttributeObject();
			att:SetDynamicField("AlwaysShowHeadOnText", true);
			att:SetDynamicField("DisplayName", obj_params.DisplayName);
			Map3DSystem.ShowHeadOnDisplay(true, char, obj_params.DisplayName, NPC.HeadOnDisplayColor);
			obj_params.obj_id = char:GetID();
		else
			commonlib.log("warning: Failed creating NPC %s: error: %s\n", obj_params.name, ObjEditor.LastErrorMessage or "");
			commonlib.echo(obj_params)
			char = nil;	
		end	
	end
	
	obj_params = obj_params or {};
	
	local ai_mods = {};
	if(obj_params.name and char) then
		self.npcs[obj_params.name] = {ai_mods = ai_mods};
		
		if(AI_node) then
			-- for each AI module node, deserialize it 
			local node;
			for node in commonlib.XPath.eachNode(AI_node, "/pe:aimod") do
				-- AI module
				if(node.attr and node.attr.name) then
					local aimod = self:GetAIModule(node.attr.name);
					
					if(aimod and type(node[1]) == "string") then
						local ai_data = NPL.LoadTableFromString(node[1]); 
						ai_data = aimod.Deserialize(char, ai_data);
						if(ai_data) then
							ai_data = aimod.ApplyAI(char, ai_data);
						end
						ai_mods[aimod.name] = ai_data;
					end
				end	
			end
		end	
	end	
end

function LocalNPC:GetNPCByName(name)
	if(name) then
		return self.npcs[name];
	end
end

-- get ai module data for a given NPL and a given ai module
-- if there is no ai module data we will create one by calling aimod.ApplyAI
-- @param npc_name: the npc name 
-- @param aimod_name: the ai module
-- @param npc: optional npc object
-- @return: return the ai module data. 
function LocalNPC:GetNPCAIModDataByName(npc_name, aimod_name, npc)
	local aimod = self:GetAIModule(aimod_name);
	if(aimod) then
		local npc_instance = self:GetNPCByName(npc_name);
		if(npc_instance and npc_instance.ai_mods) then
			local ai_data = npc_instance.ai_mods[aimod_name];
			if(not ai_data) then
				ai_data = aimod.ApplyAI(npc or ParaScene.GetObject(npc_name), ai_data);
				if(ai_data) then
					npc_instance.ai_mods[aimod_name] = ai_data;
				end
			end
			return ai_data;
		end
	end	
end

function LocalNPC:GetNPCAIModule(npc_name, isMakeClone)
	local npc_instance = self:GetNPCByName(npc_name);
	if(npc_instance and npc_instance.ai_mods) then
		local aimods = npc_instance.ai_mods;
		if(isMakeClone) then
			aimods = commonlib.clone(aimods);
		end
		return aimods;
	end
end

-- apply a given aimods to a given player
function LocalNPC:ApplyAIModule(char, ai_mods)
	if(char) then
		self.npcs[char.name] = {ai_mods = ai_mods};
		if(ai_mods) then
			local aimod_name, ai_data;
			for aimod_name, ai_data in pairs(ai_mods) do
				local aimod = self:GetAIModule(aimod_name);
				if(aimod) then
					aimod.ApplyAI(char, ai_data);
				end
			end
		end
	end
end


-- invoke the editor of a given NPC.
function LocalNPC:InvokeEditor(char, aimod_name)
	local aimod = self:GetAIModule(aimod_name);
	
	if(aimod and char) then
		local name = char.name;
		local ai_data = self:GetNPCAIModDataByName(name, aimod_name, char)
		-- commonlib.echo(name)
		if(ai_data) then
			aimod.InvokeEditor(char, ai_data);
		end
	else
		commonlib.log("warning: there is no ai module for %s \n", aimod_name)
	end
end

-- On Click character: call onclick of each ai module. 
function LocalNPC:OnClickCharacter(char)
	if(not char) then
		return;
	end
	local npc_name = char.name;
	local npc_instance = self:GetNPCByName(npc_name);
	if(npc_instance and npc_instance.ai_mods) then
		local aimod_name, aimod_data
		for aimod_name, aimod_data in pairs(npc_instance.ai_mods) do
			local aimod = self:GetAIModule(aimod_name);
			if(aimod) then
				if(type(aimod.OnClick) == "function") then
					aimod.OnClick(char, aimod_data);
				end
			end
		end	
	end
end

-- get the next talk text
-- @param char: the ParaObject
-- @param index: the talk index to begin with. if nil, it will be the next talk. 
function LocalNPC:GetNextTalkText(char, index)
	if(not char) then
		return;
	end
	local npc_name = char.name;
	local npc_instance = self:GetNPCByName(npc_name);
	local text;
	if(npc_instance and npc_instance.ai_mods) then
		local aimod_name, aimod_data
		for aimod_name, aimod_data in pairs(npc_instance.ai_mods) do
			local aimod = self:GetAIModule(aimod_name);
			if(aimod) then
				if(type(aimod.GetNextTalkText) == "function") then
					text = aimod.GetNextTalkText(char, aimod_data, index);
					break;
				end
			end
		end	
	end
	return text;
end

-- remove all AI mod of a given character
function LocalNPC:RemoveAllAIMods(char)
	if(not char) then
		return;
	end
	local npc_name = char.name;
	local npc_instance = self:GetNPCByName(npc_name);
	if(npc_instance and npc_instance.ai_mods) then
		local aimod_name, aimod_data
		for aimod_name, aimod_data in pairs(npc_instance.ai_mods) do
			local aimod = self:GetAIModule(aimod_name);
			if(aimod) then
				if(type(aimod.RemoveAI) == "function") then
					aimod.RemoveAI(char, aimod_data);
				end
			end
		end	
		-- now clears all data. 
		npc_instance.ai_mods = {};
	end
end