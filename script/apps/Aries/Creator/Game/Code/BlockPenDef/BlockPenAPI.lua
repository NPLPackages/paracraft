--[[
Title: Block Pen
Author(s): LiXizhi
Date: 2020/2/16
Desc: This is from the ArtWork project (id: 852). I have turned that project into a built-in module
use the lib:
-------------------------------------------------------
local BlockPenAPI = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/BlockPenDef/BlockPenAPI.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CmdParser.lua");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
local BlockPenAPI = commonlib.inherit(nil, NPL.export());

function BlockPenAPI:ctor()
	self.penBlockId = 10;
	self.penColor = "#ff0000";
	self.direction = 90;
	self.x = 0;
	self.y = 0;
	self.speed = 2;
	self.plane = "xz"; -- "xy" or "xz"
end

-- private:invoke code block API 
function BlockPenAPI:InvokeMethod(name, ...)
	return self.codeEnv[name](...);
end

local publicMethods = {
"setPenBlockId","setPenColor", "jumpTo", "drawLine", "drawBlock", "turnPen", "turnPenTo", "resetPen", "setPenSpeed",
"createCanvas", "clearCanvas", "setCanvasSize",
}

-- create short cut in code API
function BlockPenAPI:InstallAPIToCodeEnv(codeEnv)
	for _, func_name in ipairs(publicMethods) do
		local func = self[func_name];
		if(type(func) == "function") then
			codeEnv[func_name] = function(...)
				return func(self, ...);
			end
		end
	end
end

function BlockPenAPI:Init(codeEnv)
	self.codeEnv = codeEnv;
	self:InstallAPIToCodeEnv(codeEnv);
		
	-- global functions for canvas
	self:createCanvas("xz", 200, 200)
	self:resetPen();
	return self;
end

-- @param speed: 1-10
function BlockPenAPI:setPenSpeed(speed)
	self.speed = speed;
end

function BlockPenAPI:resetPen()
	self:setPenBlockId(10)
	self:setPenColor("#ff0000")
	self:jumpTo(0, 0)
	self:setPenSpeed(2)
	self:turnPenTo(90)
end


-- @param color: "#ff0000"
function BlockPenAPI:setPenColor(color)
	if(type(color) == "number") then
		color = string.format("#%06x", color)
	end
	self.penColor = color;
	self:InvokeMethod("setActorValue", "color", color)
end

-- @param penBlockId: default to 10
function BlockPenAPI:setPenBlockId(penBlockId)
	penBlockId = CmdParser.ParseBlockId(tostring(penBlockId))
	self.penBlockId = penBlockId or self.penBlockId;
end

function BlockPenAPI:penToBlockPos(x, y)
	if(self.mode == "xy") then
		return math.floor(self.center.x + x), math.floor(self.center.y + y), self.center.z
	else -- "xz"
		return math.floor(self.center.x + x), self.center.y, math.floor(self.center.z + y)
	end
end

function BlockPenAPI:jumpTo(x, y)
	self.x = x
	self.y = y
	local x, y, z = self:penToBlockPos(x, y)
	self:InvokeMethod("moveTo", x, y, z)
	self:updatePainterMan();
	if(self.speed < 10) then
		self.couter =(self.couter or 0) + 1;
		if((self.couter%self.speed) == 0) then
			self:InvokeMethod("wait", 0.1)
		end
	end
end

function BlockPenAPI:updatePainterMan()
end

function BlockPenAPI:turnPenTo(angle)
	self.direction = angle%360;
	self:updatePainterMan()
end

function BlockPenAPI:turnPen(leftOrRight, angle)
	if(leftOrRight == "right") then
		angle = - angle;
	end
	self:turnPenTo(self.direction + angle)
end

function BlockPenAPI:drawBlock(x, y)
	self:jumpTo(x, y)
	if(math.abs(x)<=self.halfWidth and math.abs(y)<=self.halfHeight) then
		local x, y, z = self:penToBlockPos(x, y)
		GameLogic.RunCommand(format("/setblock %d %d %d %d", x, y, z, self.penBlockId))
		GameLogic.RunCommand(format("/setcolor %d %d %d %s", x, y, z, self.penColor))
		return true;
	end
end

-- @param forwardOrBackward: "forward" or "backward"
function BlockPenAPI:drawLine(forwardOrBackward, distance)
	local x, y = self.x, self.y;
	local rot = self.direction * math.pi / 180;
	if(distance > 0) then
		local cosAngle = math.cos(rot)
		local sinAngle = math.sin(rot)
		if(forwardOrBackward == "backward") then
			cosAngle = - cosAngle;
			sinAngle = - sinAngle;
		end
		self:drawBlock(x, y)
		for i = 1, math.floor(distance) do
			x = x + cosAngle
			y = y + sinAngle
			self:drawBlock(x, y)
		end
	end
end

-- create canvas at the current player position as center. 
-- @param mode: "xy" or "xz"
-- @param blockId: nil or -1 means no block are set. 0 means clear. 10 is color block
-- color default to 0 (white)
function BlockPenAPI:createCanvas(mode, width, height, blockId, blockData)
	self:setCanvasSize(width or self.width, height or self.height, mode);
	blockId = tonumber(blockId or -1);
	if(blockId >= 0) then
		if(self.mode == "xy") then
			local left = math.floor(self.center.x - self.width / 2)
			local bottom = math.floor(self.center.y - self.height / 2)
			GameLogic.RunCommand(format("/setblock %d %d %d (%d %d 0) %d:%d", left, bottom, self.center.z, self.width, self.height, blockId or 10, blockData or 4095))
		else -- "xz"
			local left = math.floor(self.center.x - self.width / 2)
			local bottom = math.floor(self.center.z - self.height / 2)
			GameLogic.RunCommand(format("/setblock %d %d %d (%d 0 %d) %d:%d", left, self.center.y, bottom, self.width, self.height, blockId or 10, blockData or 4095))
		end
	end
end

function BlockPenAPI:clearCanvas(width, height)
	self:createCanvas(width, height, 0, 0)
end

function BlockPenAPI:setCanvasSize(width, height, mode)
	self.mode = mode or self.mode;
	local x, y, z = self.codeEnv.actor:GetEntity():GetBlockPos()
	self.center = {x = x, y = y, z = z};
	self.width = width or self.width;
	self.height = height or self.height;
	self.halfWidth = math.floor(width / 2 + 0.5);
	self.halfHeight = math.floor(height / 2 + 0.5);
	self:jumpTo(0, 0);
end
