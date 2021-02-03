--[[
Title: Macro Control Commands
Author(s): LiXizhi
Date: 2021/1/7
Desc: 

Use Lib:
-------------------------------------------------------
GameLogic.Macros.SetPlaySpeed(1.25)
GameLogic.Macros.SetHelpLevel(1)
GameLogic.Macros.SetAutoPlay(true)
GameLogic.Macros.cmd("/tip hello")
GameLogic.Macros.loadtemplate("abc.bmax");
GameLogic.Macros.loadtemplate("abc.bmax", "-r");

-- in code block, we can do 
local wnd = window("<input type='button' value='stop' onclick='OnStopPlay'/>", "(global)_lt", 201, 10, 100, 32);
GameLogic.Macros.AttachWindow(wnd)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/MacroPlayer.lua");
local MacroPlayer = commonlib.gettable("MyCompany.Aries.Game.Tasks.MacroPlayer");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros")


local playSpeed = 1;


function Macros.GetPlaySpeed()
	return playSpeed
end

-- set the current play back speed.
-- @param speed: like 0.5, 1, 1.5, 2;
function Macros.SetPlaySpeed(speed)
	playSpeed = speed or 1
end

local nHelpLevel = 1;

-- @param nLevel: 1 (default) to show all tips
-- 1 (default) to show all possible tips
-- -1 to display key and mouse tips
-- 0 to disable mouse tips
function Macros.SetHelpLevel(nLevel)
	nHelpLevel = nLevel
end

-- @return default to 1
function Macros.GetHelpLevel()
	return nHelpLevel
end

function Macros.IsShowButtonTip()
	return nHelpLevel >= 1
end

function Macros.IsShowKeyButtonTip()
	return nHelpLevel >= 0
end

local isAutoPlay = false;

-- whether triggers are played automatically
function Macros.IsAutoPlay()
	return isAutoPlay;
end


-- whether triggers are played automatically
function Macros.SetAutoPlay(bAutoPlay)
	isAutoPlay = bAutoPlay
end

local blockOrigin = {0,0,0};

function Macros.SetMacroOrigin(x, y, z)
	blockOrigin[1], blockOrigin[2], blockOrigin[3] = x, y, z;
end

-- this is usually the player's block position when macro starts recording. 
function Macros.GetMacroOrigin()
	return blockOrigin[1], blockOrigin[2], blockOrigin[3]
end

-- whether to generate triggers during recording. 
function Macros.SetInteractiveMode(isInteractive)
	Macros.isInteractive = isInteractive == true;
end

function Macros.IsInteractiveMode()
	return Macros.isInteractive;
end

local playOrigin = {0,0,0};

-- @param x, y, z: the block position to play relative to. these can be nil to play with absolute positions(default)
function Macros.SetPlayOrigin(x, y, z)
	playOrigin[1], playOrigin[2], playOrigin[3] = x, y, z;
end

-- this is usually the player location when macro starts recording. 
function Macros.GetPlayOrigin()
	return playOrigin[1], playOrigin[2], playOrigin[3]
end

-- @return offset in real world coordinate system.  it may return nil, if we are playing with absolute positions(default)
function Macros.GetPlayOffset()
	local x1, y1, z1 = Macros.GetPlayOrigin()
	local x2, y2, z2 = Macros.GetMacroOrigin()
	if(x1 and x2) then
		return x1 - x2, y1 - y2, z1 - z2;
	end
end

-- @param x, y, z:  real world position
function Macros.ComputePosition(x, y, z)
	local dx, dy, dz = Macros.GetPlayOffset()
	if(dx) then
		local blocksize = BlockEngine.blocksize;
		return x + dx*blocksize, y + dy*blocksize, z + dz*blocksize;
	else
		return x, y, z;
	end
end

-- @param x, y, z:  block world position
function Macros.ComputeBlockPosition(x, y, z)
	local dx, dy, dz = Macros.GetPlayOffset()
	if(dx) then
		return x + dx, y + dy, z + dz
	else
		return x, y, z
	end
end

-- run command text
function Macros.cmd(cmd_text)
	GameLogic.RunCommand(cmd_text);
end


-- load template relative to MacroOrigin
-- @param filename: load block model at the macro origin. 
-- @param options: additional template command "-r" to remove. 
function Macros.loadtemplate(filename, options)
	local x, y, z = Macros.GetPlayOrigin()
	local text = "/loadtemplate"
	if(options) then
		text = text.." "..options;
	end
	if(x) then
		text = format("%s %d %d %d", text, x, y, z);
	else
		text = text.." -abspos";
	end
	text = format("%s %s", text, filename)
	GameLogic.RunCommand(text);
end


-- @param window: attach a mcml v2 window object to it, usually from CodeBlock's window() function
function Macros.AttachWindow(window)
	return MacroPlayer.AttachWindow(window)
end

-- show virtual keyboard with button 
-- @param: "ctrl+DIK_E"
function Macros.ShowKeyboard(bShow, button)
	MacroPlayer.ShowKeyboard(bShow, button)
end