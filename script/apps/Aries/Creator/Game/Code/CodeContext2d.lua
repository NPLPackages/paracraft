--[[
Title: context for drawing 2d on code window
Author(s): LiXizhi
Date: 2019/10/10
Desc: code api wrapper of painter context used directly in code block. 
I have tried to loosely conform with https://www.w3.org/TR/2dcontext/ API 

Differences with HTML5 canvas:
- font property uses NPL format like "System;30;"
- fillText coordinates uses left top instead of left bottom
- composition mode default to "source-blend" instead of "source-over" for text and alpha blending
- Note: set composition mode does not take effect if nothing is drawn
- TODO: transforms can not be applied between path points, it can only apply to stroke or fill methods.
- TODO: clearRect only support full screen clear
- TODO: fillStyle only support #ff0000 format, not rgba or hsl format. 
- TODO: restore/save only apply to transforms, not font or other settings


use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeContext2d.lua");
local CodeContext2d = commonlib.gettable("MyCompany.Aries.Game.Code.CodeContext2d")

local wnd = window("<div>draw something</div>", "_lt",200,20,300,300);
local ctx = wnd:getContext();
ctx.fillStyle="#800000"
ctx:fillRect(0, 0, 300, 30)
ctx.fillStyle="#808000"
ctx.strokeStyle="blue"
ctx:moveTo(0, 0)
ctx:lineTo(300,300)
ctx:lineTo(150,300)
ctx:closePath()
ctx.lineWidth = 2
ctx:fill();
ctx:stroke()
ctx:fillText("world", 90, 40)
ctx.fillStyle="#00000030"
ctx.font="System;30"
ctx:fillText("hello", 20, 40)
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Window.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/css/StyleColor.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local StyleColor = commonlib.gettable("System.Windows.mcml.css.StyleColor");
local PainterContext = commonlib.gettable("System.Core.PainterContext");
local type = type;
local CodeContext2d = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Code.CodeContext2d"));

CodeContext2d:Property({"maxCachedCommand", 100000});
CodeContext2d:Property({"globalAlpha", 1});
CodeContext2d:Property({"globalCompositeOperation", nil, "getCompositeOperation", "setCompositeOperation", strict=true});

-- colors and styles (see also the CanvasDrawingStyles interface)
CodeContext2d:Property({"strokeStyle", "#000000"});
CodeContext2d:Property({"fillStyle", "#000000"});
CodeContext2d:Property({"lineWidth", 1});
CodeContext2d:Property({"font", "System;14;"});
-- zorder used for all 2d UI in range [0,1]
CodeContext2d:Property({"zorder", 0});
CodeContext2d:Property({"globalAlpha", 1});
CodeContext2d:Property({"width", 0, "getWidth", strict=true});
CodeContext2d:Property({"height", 0, "getHeight", strict=true});


function CodeContext2d:ctor()
	self.cmds = {};
	self.pointPool = {}
	self.nextPointPoolIndex = 1;
	self.vec2DPool = {}
	self.nextVec2DPoolIndex = 1;
	self.vec3DPool = {}
	self.nextVec3DPoolIndex = 1;
	self.m_compositionMode = "source-blend";
	self:clearCommands()
	self:beginPath()
end

-- private
function CodeContext2d:clearCommands()
	self.nextCmdIndex = 1;
	self.nextVec2DPoolIndex = 1;
	self.nextVec3DPoolIndex = 1;
end

-- private:
function CodeContext2d:newPathPoint(type, x, y)
	local point;
    if (self.nextPointPoolIndex > #self.pointPool) then
		point = {type = type, x = x, y= y};
        self.pointPool[#self.pointPool+1] = point
    else
        point = self.pointPool[self.nextPointPoolIndex];
		point.type = type;
		point.x = x;
		point.y = y;
    end
    self.nextPointPoolIndex = self.nextPointPoolIndex + 1;
    return point;
end

-- private:
function CodeContext2d:newVec2D(x, y)
	local vec;
    if (self.nextVec2DPoolIndex > #self.vec2DPool) then
		vec = {x, y};
        self.vec2DPool[#self.vec2DPool+1] = vec
    else
        vec = self.vec2DPool[self.nextVec2DPoolIndex];
		vec[1] = x;
		vec[2] = y;
    end
    self.nextVec2DPoolIndex = self.nextVec2DPoolIndex + 1;
    return vec;
end

function CodeContext2d:newVec3D(x, y, z)
	local vec;
    if (self.nextVec3DPoolIndex > #self.vec3DPool) then
		vec = {x, y, z};
        self.vec3DPool[#self.vec3DPool+1] = vec
    else
        vec = self.vec3DPool[self.nextVec3DPoolIndex];
		vec[1] = x;
		vec[2] = y;
		vec[3] = z;
    end
    self.nextVec3DPoolIndex = self.nextVec3DPoolIndex + 1;
    return vec;
end

-- private function
function CodeContext2d:addCommand(name, a2, a3, a4, a5, a6, a7)
	if(self.nextCmdIndex >= self.maxCachedCommand) then
		if(self.nextCmdIndex == self.maxCachedCommand) then
			LOG.std(nil, "warn", "CodeContext2d", "max cached command %s is reached", self.maxCachedCommand);	
		end
		return;
	end
	local cmd = self.cmds[self.nextCmdIndex];
	if(not cmd) then
		cmd = {}
		self.cmds[self.nextCmdIndex] = cmd;
	end
	cmd[1] = name;
	cmd[2] = a2;
	cmd[3] = a3;
	cmd[4] = a4;
	cmd[5] = a5;
	cmd[6] = a6;
	cmd[7] = a7;
	self.nextCmdIndex = self.nextCmdIndex + 1;
end

function CodeContext2d:SetWindow(window)
	self.window = window
	self.painterContext = window.painterContext;
end

-- push state on state stack
function CodeContext2d:save()
	self:addCommand("Save")
end

function CodeContext2d:clearStates()
	self.curPenColor = nil;
	self.curFont = nil;
	self.curCompositionMode = nil;
end

-- pop state stack and restore state
function CodeContext2d:restore()
	self:addCommand("Restore")
	-- TODO: remove these, when we implemented ContextLayer in NPL
	self:clearStates();
end

-- transformations (default: transform is the identity matrix)
function CodeContext2d:scale(x, y)
	self:addCommand("Scale", x, y)
end

-- @param angle: radian
function CodeContext2d:rotate(angle)
	self:addCommand("Rotate", angle * 180 / math.pi)
end
function CodeContext2d:translate(x, y)
	self:addCommand("Translate", x, y)
end

function CodeContext2d:transform(a, b, c, d, e, f)
end

function CodeContext2d:setTransform(a, b, c, d, e, f)
end


function CodeContext2d:getCompositeOperation()
	return self.m_compositionMode;
end

local comModeMaps = {
	["source-blend"] = PainterContext.CompositionMode.SourceBlend,

	["source"] = PainterContext.CompositionMode.Source,
	["source-over"] = PainterContext.CompositionMode.SourceOver,
	["source-in"] = PainterContext.CompositionMode.SourceIn,
	["source-out"] = PainterContext.CompositionMode.SourceOut,
	
	["destination"] = PainterContext.CompositionMode.Destination,
	["destination-over"] = PainterContext.CompositionMode.Destination,
	["destination-in"] = PainterContext.CompositionMode.DestinationIn,
	["destination-out"] = PainterContext.CompositionMode.DestinationOut,
	
	["xor"] = PainterContext.CompositionMode.Xor,
	["Plus"] = PainterContext.CompositionMode.multiply,
} 

function CodeContext2d:setCompositeOperation(mode)
	self.m_compositionMode = mode;
	if(self.curCompositionMode~=mode) then
		self.curCompositionMode = mode;
		self:addCommand("SetCompositionMode", comModeMaps[mode] or PainterContext.CompositionMode.Source);
	end
end

-- @param x, y, w, h: if all nil, it will clear all 
function CodeContext2d:clearRect(x, y, w, h)
	x = x or 0;
	y = y or 0;
	w = w or self:getWidth();
	h = h or self:getHeight();
	-- since we are using separate alpha blending, the following is not supported.	
	-- TODO: we shall disable D3DRS_SEPARATEALPHABLENDENABLE in C++ when clearing rect
		
	if(x == 0 and y==0 and w == self:getWidth() and h == self:getHeight()) then
		-- however we can simulate full size clearRect with 
		self.window:SetAutoClearBackground(true);
		self.hasClearCommand = true;
		self:clearCommands();
	else
		-- NOT supported due to D3DRS_SEPARATEALPHABLENDENABLE is true for self-painted container in C++
		self:addCommand("SetCompositionMode", PainterContext.CompositionMode.Source)
		local lastFillStyle = self.fillStyle;
		self.fillStyle = '#00000000';
		self:fillRect(x, y, w, h);

		self:addCommand("SetCompositionMode", PainterContext.CompositionMode.SourceBlend)
		self.fillStyle = lastFillStyle;
	end
end

function CodeContext2d:getWidth()
	return self.window:width()
end

function CodeContext2d:getHeight()
	return self.window:height()
end

function CodeContext2d:fillRect(x, y, w, h)
	self:beginPath();
    self:rect(x, y, w, h);
	self:fill();
	self:beginPath();
end

function CodeContext2d:strokeRect(x, y, w, h)
	self:beginPath();
    self:rect(x, y, w, h);
    self:stroke();
end

-- Begins a path, or resets the current
function CodeContext2d:beginPath()
	if(not self.path or (#(self.path)) ~= 1 or self.path[1].type~="begin") then
		self.nextPointPoolIndex = 1;
		self.path = {self:newPathPoint('begin')};
	end
end

function CodeContext2d:fill()
	self:drawPath("fill")
	self:markDirty();
end

function CodeContext2d:stroke()
	self:drawPath("stroke")
	self:markDirty();
end

function CodeContext2d:clip()
end

function CodeContext2d:isPointInPath(x, y)
end


-- Creates a path from the current point back to the starting point
function CodeContext2d:closePath()
	local x, y = 0, 0;
    local i = #(self.path);
    while(i >= 1) do
        if (self.path[i].type == 'begin') then
            if (self.path[i + 1] and type(self.path[i + 1].x) == 'number') then
                x, y  = self.path[i + 1].x, self.path[i + 1].y;
                self.path[#self.path+1] = self:newPathPoint('lt', x, y);
                break;
            end
        end
		i = i - 1;
    end
	-- close path more complete by drawing one more line segment
    --if (self.path[i + 2] and type(self.path[i + 2].x) == 'number') then
	--	self.path[#self.path+1] = commonlib.clone(self.path[i + 2]);
    --end
    self.path[#self.path+1] = self:newPathPoint('close');
end

-- Moves the path to the specified point in the canvas, without creating a line
function CodeContext2d:moveTo(x, y)
	if(type(x) == "number" and type(y) == "number") then
		self.path[#self.path+1] = self:newPathPoint('mt', x, y);
	end
end

-- Adds a new point and creates a line to that point from the last specified point in the canvas
function CodeContext2d:lineTo(x, y)
	if(type(x) == "number" and type(y) == "number") then
		self.path[#self.path+1] = self:newPathPoint('lt', x, y);
	end
end

function CodeContext2d:quadraticCurveTo(cpx, cpy, x, y)
	if(type(cpx) ~= "number" or type(cpy) ~= "number" or type(x) ~= "number" or type(y) ~= "number") then
		return
	end
	self.path[#self.path+1] = {
        type = 'qct',
        x1 = cpx,
        y1 = cpy,
        x = x,
        y = y
    };
end

-- Creates a cubic B¨¦zier curve
function CodeContext2d:bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y)
	if(type(cp1x) ~= "number" or type(cp1y) ~= "number" or type(cp2x) ~= "number" or type(cp2y) ~= "number" or type(x) ~= "number" or type(y) ~= "number") then
		return
	end
	self.path[#self.path+1] = {
        type = 'bct',
        x1 = cp1x,
        y1 = cp1y,
        x2 = cp2x,
        y2 = cp2y,
        x = pt0.x,
        y = pt0.y
    };
end

function CodeContext2d:arcTo(x1, y1, x2, y2, radius)
end

-- Creates a rectangle
function CodeContext2d:rect(x, y, w, h)
	w = w or self:getWidth();
	h = h or self:getHeight();
	self:moveTo(x, y);
    self:lineTo(x + w, y);
    self:lineTo(x + w, y + h);
    self:lineTo(x, y + h);
    self:lineTo(x, y);
    --self:lineTo(x + w, y);
    --self:lineTo(x, y);
end

local two_pi = math.pi * 2;

-- @param fromAngle: default to 0;
-- @param toAngle: default to 2*math.pi;
function CodeContext2d:arc(cx, cy, radius, fromAngle, toAngle, counterclockwise, segment)
	if(counterclockwise) then
		fromAngle, toAngle = toAngle, fromAngle
	end
	fromAngle = fromAngle or 0;
	toAngle = toAngle or two_pi;
	
	while(toAngle<=fromAngle) do
		toAngle = toAngle + two_pi;
	end
	if(not segment) then
		segment = math.max(5, math.min(100, radius*(toAngle - fromAngle)/0.05));
	end
	segment = math.floor(segment);
	local delta_angle = (toAngle - fromAngle) / segment;

	local last_x, last_y = math.cos(fromAngle)*radius, math.sin(fromAngle)*radius;
	local nIndex = 1;
	
	self:moveTo(cx + last_x, cy + last_y);

	for i=1, segment do
		local angle = fromAngle+delta_angle*i;	
		local x, y = math.cos(angle)*radius, math.sin(angle)*radius;
		self:lineTo(cx + x, cy + y);
		last_x, last_y = x, y;
	end
end


-- text
function CodeContext2d:fillText(text, x, y, maxWidth)
	self:setPen(self.fillStyle);
	self:setFont(self.font);
	self:addCommand("DrawText", x, y, text)
	self:addCommand("Flush")
	self:markDirty();
end

function CodeContext2d:strokeText(text, x, y, maxWidth)
	self:setPen(self.strokeStyle);
	self:setFont(self.font);
	self:addCommand("DrawText", x, y, text)
	self:addCommand("Flush")
	self:markDirty();
end

function CodeContext2d:measureText(text)
end

-- drawing images
function CodeContext2d:drawImage(image, a1, a2, a3, a4, a5, a6, a7, a8)
	if(not a3) then
		self:drawImage2(image, a1, a2)
	elseif(not a5) then
		self:drawImage4(image, a1, a2, a3, a4)
	else
		self:drawImage8(image, a1, a2, a3, a4, a5, a6, a7, a8)
	end
end

-- @return filename, filepath:
local function GetImageFilename(filename)
	if(filename and filename~="") then
		local filepath, params = filename:match("^([^:;]+)(.*)$");
		-- repeated calls are cached
		filename = Files.FindFile(filepath);
		if(params and params~="") then
			return (filename..params), filename
		else
			return filename;
		end
	end
end

function CodeContext2d:getTextureAsset(filename)
	self.textures_ = self.textures_ or {}
	local tex = self.textures_[filename] 
	if(not tex) then
		tex = ParaAsset.LoadTexture("", filename, 1);
		self.textures_[filename] = tex;
	end
	return tex;
end

function CodeContext2d:drawImage2(image, dx, dy)
	local filename, filepath = GetImageFilename(image);
	if(filename) then
		local tex = self:getTextureAsset(filepath or filename)
		local dw, dh = tex:GetWidth(), tex:GetHeight()
		if(dw > 0) then
			self:drawImage4(image, dx, dy, dw, dh)
		end
	end
end

function CodeContext2d:drawImage4(image, dx, dy, dw, dh)
	local filename = GetImageFilename(image);
	if(filename) then
		self:setPen("#ffffff");
		self:addCommand("DrawRectTexture", dx, dy, dw, dh, filename)
		self:addCommand("Flush")
		self:markDirty();
	end
end

function CodeContext2d:drawImage8(image, sx, sy, sw, sh, dx, dy, dw, dh)
	image = format("%s;%d %d %d %d", image, sx, sy, sw, sh);
	if(dw and dh) then
		self:drawImage4(image, dx, dy, dw, dh)
	else
		self:drawImage2(image, dx, dy)
	end
end

-- private function
function CodeContext2d:markDirty()
	self.window:markDirty();
end

function CodeContext2d:setPen(penColor)
	if(self.curPenColor ~= penColor or self.curPenWidth ~= self.lineWidth) then
		self.curPenColor = penColor;
		self.curPenWidth = self.lineWidth;
		self:addCommand("SetPen", {color = StyleColor.GetColorString(penColor), width=self.lineWidth })
	end
end

function CodeContext2d:setFont(font, bForceUpdate)
	if(self.curFont ~= font or bForceUpdate) then
		self.curFont = font;
		self:addCommand("SetFont", font)
	end
end

-- private: 
-- @param rule: "stroke" or "fill", default to "stroke"
function CodeContext2d:drawPath(rule)
	rule = rule or "stroke";

	-- TODO: we need to avoid too many memory allocations here
	local moves = {};
	local xPath = self.path;
	for i = 1, #xPath do
        local pt = xPath[i];
		local path_type = pt.type
        
		if( path_type == 'begin') then
			moves[#moves+1] = { begin = true };
		elseif( path_type == 'close') then
			moves[#moves+1] = { close = true };
		elseif( path_type == 'mt') then
			moves[#moves+1] = { start = self:newVec2D(pt.x, pt.y), deltas = {}};
        elseif( path_type == 'lt') then        
            local iii = #moves;
            if (xPath[i - 1].x) then
                while (iii >= 1) do
					if (moves[iii].close ~= true and moves[iii].begin ~= true) then
                        table.insert(moves[iii].deltas, self:newVec2D(pt.x, pt.y));
                        break;
                    end
					iii = iii -1;
                end
            end
		elseif( path_type == 'bct') then
			-- emulate with a line
            table.insert(moves[#moves].deltas, self:newVec2D(pt.x1, pt.y1));
			table.insert(moves[#moves].deltas, self:newVec2D(pt.x2, pt.y2));
			table.insert(moves[#moves].deltas, self:newVec2D(pt.x, pt.y));
		elseif( path_type == 'qct') then
            local x1 = xPath[i - 1].x + 2.0 / 3.0 * (pt.x1 - xPath[i - 1].x);
            local y1 = xPath[i - 1].y + 2.0 / 3.0 * (pt.y1 - xPath[i - 1].y);
            local x2 = pt.x + 2.0 / 3.0 * (pt.x1 - pt.x);
            local y2 = pt.y + 2.0 / 3.0 * (pt.y1 - pt.y);
            local x3 = pt.x;
            local y3 = pt.y;
            table.insert(moves[#moves].deltas, self:newVec2D(x1, y1));
			table.insert(moves[#moves].deltas, self:newVec2D(x2, y2));
			table.insert(moves[#moves].deltas, self:newVec2D(x3, y3));
		elseif( path_type == 'arc') then
			moves[#moves+1] = { arc = true};
        end
	end

	local zOrder = self.zorder;
	if(rule == "stroke") then
		self:setPen(self.strokeStyle);
		local lines = {};
		for i = 1, #moves do
			local move = moves[i]
			if (move.arc) then
				-- TODO
			else
				if (move.close ~= true and move.begin ~= true) then
					move.start[3] = zOrder;
					local lineStart = move.start;
					local deltas = move.deltas
					for k = 1, #deltas do
						local delta = deltas[k];
						delta[3] = zOrder;
						lines[#lines + 1] = lineStart;
						lines[#lines + 1] = delta;
						lineStart = delta;
					end
				end
			end
		end
		if(#lines>0) then
			self:addCommand("DrawLineList", lines)
			self:addCommand("Flush")
		end
	else 
		-- "fill"
		self:setPen(self.fillStyle);
		
		local triangles = {};
		for i = 1, #moves do
			local move = moves[i]
			if (move.arc) then
				-- TODO
			else
				if (move.close ~= true and move.begin ~= true and #move.deltas >= 2) then
					-- invert y coordinates, since draw triangle uses Y up coordinates
					local startPt = self:newVec3D(move.start[1], -move.start[2], zOrder)
					local deltas = {};
					local fromDeltas = move.deltas;
					
					local pt = fromDeltas[1];
					deltas[1] = self:newVec3D(pt[1], -pt[2], zOrder);
					local lineStart = deltas[1];
					local delta
					for k = 2, #fromDeltas do
						pt = fromDeltas[k];
						delta = self:newVec3D(pt[1], -pt[2], zOrder)
						deltas[k] = delta;
						triangles[#triangles + 1] = lineStart;
						triangles[#triangles + 1] = delta;
						triangles[#triangles + 1] = startPt;
						lineStart = delta;
					end
					
				end
			end
		end
		if(#triangles > 0) then
			self:addCommand("DrawTriangleList", triangles)
			self:addCommand("Flush")
		end
	end
end

function CodeContext2d:Render(painterContext)  
	if(self.hasClearCommand) then
		self.window:SetAutoClearBackground(false);
	end
	if(self.nextCmdIndex <= 1) then
		return
	end
	-- prepare drawing states
	if(self.globalAlpha ~= 1) then
		painterContext:SetOpacity(self.globalAlpha);
	end
	-- tricky: calling painterContext:save() will make previous calls to setCompositionMode invalid. 
	painterContext:SetCompositionMode(comModeMaps[self:getCompositeOperation()] or PainterContext.CompositionMode.SourceBlend);

	-- run commands
	local cmds = self.cmds;
	for i=1, self.nextCmdIndex-1 do
		local cmd = cmds[i];
		if(cmd[5]) then
			painterContext[cmd[1]](painterContext, cmd[2], cmd[3], cmd[4], cmd[5], cmd[6], cmd[7])
		else
			painterContext[cmd[1]](painterContext, cmd[2], cmd[3], cmd[4])
		end
	end
	self:clearCommands()
	
	self:clearStates()
end