--[[
Title: Note Block
Author(s): LiXizhi
Date: 2014/4/22
Desc: 
more information about note: http://www.nyu.edu/classes/bello/FMT_files/9_MIDI_code.pdf

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityNote.lua");
local EntityNote = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityNote")
EntityNote.PlayCmd("c1");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemClient.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Direction.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityBlockBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/InventoryBase.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ContainerView.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/BackgroundMusic.lua");
local BackgroundMusic = commonlib.gettable("MyCompany.Aries.Game.Sound.BackgroundMusic");
local Direction = commonlib.gettable("MyCompany.Aries.Game.Common.Direction")
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Materials = commonlib.gettable("MyCompany.Aries.Game.Materials");

local Entity = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityBlockBase"), commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityNote"));

-- class name
Entity.class_name = "EntityNote";
EntityManager.RegisterEntityClass(Entity.class_name, Entity);
Entity.is_persistent = true;
-- always serialize to 512*512 regional entity file
Entity.is_regional = true;

local last_cmd = "0";

function Entity:ctor()
end


-- @param Entity: the half radius of the object. 
function Entity:init()
	if(not Entity._super.init(self)) then
		return
	end
	self.cmd = self.cmd or self:GetNextNoteCmd();
	return self;
end

-- any newly created note block is increased by one from the last played note. 
function Entity:GetNextNoteCmd()
	if(last_cmd) then
		local pre, note = last_cmd:match("^([^%d]*)(%d+)$");
		if(note) then
			note = tonumber(note) or 0;
			if(note <256) then
				local cmd = pre..tostring(note+1);
				Entity.SetLastCmd(cmd);
				return cmd;
			end
		end
	end
	return "0";
end

-- static function.
function Entity.SetLastCmd(cmd)
	last_cmd = cmd;
end

function Entity:Refresh()
end

function Entity:OnNeighborChanged(x,y,z, from_block_id)
	local isPowered = BlockEngine:isBlockIndirectlyGettingPowered(x,y,z);
	if(self.isPowered ~= isPowered) then
		self.isPowered = isPowered;
		if(isPowered) then
			self.timer = self.timer or commonlib.Timer:new({callbackFunc = function(timer)
				local x,y,z = self:GetBlockPos();
				local isPowered = BlockEngine:isBlockIndirectlyGettingPowered(x,y,z);
				if(isPowered) then
					self:PlayNote();
				end
			end})
			self.timer:Change(100, nil);
		end
	end
end

function Entity:LoadFromXMLNode(node)
	Entity._super.LoadFromXMLNode(self, node);
	-- self.isPowered = node.attr.isPowered == "true";
end

function Entity:SaveToXMLNode(node)
	node = Entity._super.SaveToXMLNode(self, node);
	--if(self.isPowered) then
		--node.attr.isPowered = true;
	--end
	return node;
end

-- static function: more information please see: http://www.nyu.edu/classes/bello/FMT_files/9_MIDI_code.pdf
-- a note msg is 0x00[XX:Velocity][XX:Note][9X:9channel]
-- @param note: 0-127: 128 note keys. where 60 is middle-C key. 
-- @param velocity: usually how hard a key is pressed. 0-128. default to 64
-- @param channel: 0-15 channels. default to channel 0
function Entity.CreateNoteMsg(note, velocity, channel)
	-- 9n: where n is channel number
	local status = 9*16 + (channel or 0);
	return mathlib.bit.lshift(velocity or 64, 16) + mathlib.bit.lshift(note or 60, 8) + status;
end

-- base reference note
local ref_notes = {
	a = 46, A = 46,
	b = 53,	B = 53,
	c = 60, C = 60,
	d = 67,	D = 67,
	e = 74,	E = 74,
	f = 81,	F = 81,
	g = 88,	G = 88,
};

-- static function: create note from cmd. 
-- @param cmd: if cmd begins with "c" or number, it is in tone C. 
function Entity.CreateNoteMsgFromCmd(cmd, baseNote, velocity, channel)
	local refNote, note = cmd:match("([^%d]?)(%-?%d+)")
	if(note) then
		note = tonumber(note);
	else
		return 0;
	end
	if(note < 256) then
		Entity.SetLastCmd(cmd);
		if(refNote and refNote~="") then
			local base_note = ref_notes[refNote] or ref_notes["c"];
			note = note + base_note;
		else
			note = note + (baseNote or ref_notes["c"]);
		end
		note = note % 128;
	end
	return Entity.CreateNoteMsg(note, velocity, channel);
end

-- static function function to play a given command.
function Entity.PlayCmd(cmd)
	local note = Entity.CreateNoteMsgFromCmd(cmd);
	ParaAudio.PlayMidiMsg(note);
end

function Entity:PlayNote()
	local x, y, z = self:GetBlockPos();

	-- only play when block above is air.
	if(BlockEngine:GetBlockMaterial(x, y+1, z) == Materials.air) then
		local baseMat = BlockEngine:GetBlockMaterial(x, y- 1, z);
		local baseNote = 56;
		if (baseMat == Materials.rock) then
            baseNote = 21;
        elseif (baseMat == Materials.sand) then
            baseNote = 28;
        elseif (baseMat == Materials.wood) then
            baseNote = 35;
		elseif (baseMat == Materials.glass) then
            baseNote = 70;
        end

		if(self.cmd) then
			local note = Entity.CreateNoteMsgFromCmd(self.cmd, baseNote);
			ParaAudio.PlayMidiMsg(note);
		end
	end
end

function Entity:GetCommandTitle()
	return "输入音符：<div>数字[0-7]或[a|b|c|d|e|f|g][0-7]</div>"
end

--  right click to edit and left click to play
function Entity:OnClick(x, y, z, mouse_button)
	if(GameLogic.isRemote) then
		GameLogic.GetPlayer():AddToSendQueue(GameLogic.Packets.PacketClickEntity:new():Init(entity or GameLogic.GetPlayer(), self, mouse_button, x, y, z));
		return true;
	else
		-- mouse left down already plays the note
		if(not GameLogic.GameMode:CanEditBlock() and mouse_button~="left") then
			self:PlayNote();
			return true;
		end
		return Entity._super.OnClick(self, x, y, z, mouse_button);
	end
end
