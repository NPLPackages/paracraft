--[[
Title: CmdParser
Author(s): LiXizhi
Date: 2014/2/13
Desc: command parser functions, parse from string and return value and remaining string. 
It is just a simple forward looking sequencial parser
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CmdParser.lua");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");

local x, y, z, cmd_text = CmdParser.ParsePos(cmd_text, fromEntity);
local dx, dy, dz, cmd_text = CmdParser.ParsePosInBrackets(cmd_text, fromEntity);
local blockid, cmd_text = CmdParser.ParseBlockId(cmd_text);
local bBoolean, cmd_text = CmdParser.ParseBool(cmd_text);
local data, cmd_text = CmdParser.ParseInt(cmd_text);
local data, cmd_text = CmdParser.ParseNumber(cmd_text); -- same as ParseInt
local data, cmd_text = CmdParser.ParseDeltaInt(cmd_text);
local player, cmd_text = CmdParser.ParsePlayer(cmd_text, fromEntity);
local list, cmd_text = CmdParser.ParseNumberList(cmd_text, nil, "|,%s")
local list, cmd_text = CmdParser.ParseStringList(cmd_text, )
local text, cmd_text = CmdParser.ParseText(cmd_text, "sometext")
local str, cmd_text = CmdParser.ParseString(cmd_text);
local str, cmd_text = CmdParser.ParseFormated(cmd_text, "_%S+");
local word, md_text = CmdParser.ParseWord(cmd_text);
local color, md_text = CmdParser.ParseColor(cmd_text, "#ff0000");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Util/CmdParser.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names")

local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
commonlib.add_interface(CmdParser, commonlib.gettable("System.Util.CmdParser"));

-- @param cmd_text:  @p or @[playername]. if @p it is the last triggering entity or current player. 
-- if @self, it is the fromEntity. if @a, it means closest nearby player. 
-- return player_entity, cmd_text_remain
function CmdParser.ParsePlayer(cmd_text, fromEntity)
	local player_name, cmd_text_remain = cmd_text:match("^%s*@(%S+)%s*(.*)$");
	if(player_name == "p") then
		-- @p is the triggering entity
		return EntityManager.GetLastTriggerEntity() or EntityManager.GetPlayer(), cmd_text_remain;
	elseif(player_name == "self") then
		return fromEntity, cmd_text_remain;
	elseif(player_name == "a") then
		-- @a the closest player entity
		return EntityManager.GetPlayer(), cmd_text_remain;
	elseif(player_name) then
		return EntityManager.GetEntity(player_name), cmd_text_remain;
	end
	return nil, cmd_text;
end

-- 3d position absolute or relative with ~
-- e.g. "20000 0 20000" or "~ ~1 ~" or "~1 ~-2 ~-3"
-- return x,y,z, cmd_text_remain: cmd_text_remaining is remaining unparsed text. 
function CmdParser.ParsePos(cmd_text, entity)
	local origin_x, origin_y, origin_z;
	if(type(entity) == "table" and entity.GetBlockPos) then
		origin_x, origin_y, origin_z = entity:GetBlockPos();
	else
		origin_x, origin_y, origin_z = EntityManager.GetPlayer():GetBlockPos();
	end
	local x, y, z, cmd_text_remain = cmd_text:match("^([~%-%d]%-?%d*)%s+([~%-%d]%-?%d*)%s+([~%-%d]%-?%d*)%s*(.*)$");
	if(x) then
		if(x:match("^~")) then
			x = x:match("^~(.*)");
			x = (tonumber(x) or 0) + origin_x;
		else
			x = tonumber(x);
		end

		if(y:match("^~")) then
			y = y:match("^~(.*)");
			y = (tonumber(y) or 0) + origin_y;
		else
			y = tonumber(y);
		end

		if(z:match("^~")) then
			z = z:match("^~(.*)");
			z = (tonumber(z) or 0) + origin_z;
		else
			z = tonumber(z);
		end
		return x, y, z, cmd_text_remain;
	else
		return nil, nil, nil, cmd_text;
	end
end

-- additional pos in brackets like "(2 -1 0)", "(2 ~ ~)"
function CmdParser.ParsePosInBrackets(cmd_text)
	local x, y, z, cmd_text_remain = cmd_text:match("^%(([~%-%d]%-?%d*)%s+([~%-%d]%-?%d*)%s+([~%-%d]%-?%d*)%)%s*(.*)$");
	if(x) then
		if(x:match("^~")) then
			x = x:match("^~(.*)");
			x = (tonumber(x) or 0);
		else
			x = tonumber(x);
		end

		if(y:match("^~")) then
			y = y:match("^~(.*)");
			y = (tonumber(y) or 0);
		else
			y = tonumber(y);
		end

		if(z:match("^~")) then
			z = z:match("^~(.*)");
			z = (tonumber(z) or 0);
		else
			z = tonumber(z);
		end
		cmd_text = cmd_text_remain;
		return x, y, z, cmd_text_remain;
	else
		return nil, nil, nil, cmd_text;
	end
end

-- block_id can be number or block name.
-- return block_id, cmd_text_remain
function CmdParser.ParseBlockId(cmd_text)
	local blockid, cmd_text_remain = cmd_text:match("^%s*([%d%w_]+)%s*(.*)$");
	if(blockid) then
		if(blockid:match("^%d+$")) then
			blockid = tonumber(blockid);
		else
			blockid = names[blockid];
		end
		if(blockid) then
			return blockid or 0, cmd_text_remain
		end
	end
	return nil, cmd_text;
end
