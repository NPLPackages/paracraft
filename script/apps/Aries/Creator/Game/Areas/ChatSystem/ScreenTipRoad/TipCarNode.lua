--[[
Title: 
Author(s): leio
Date: 2020/5/8
Desc:  
Use Lib:
-------------------------------------------------------
local TipCarNode = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ScreenTipRoad/TipCarNode.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/gui_helper.lua");
local TipCarNode = commonlib.inherit(nil, NPL.export());
TipCarNode.states = {
    stop = "stop",
    waitting = "waitting",
    running = "running",
    removed = "removed",
}
TipCarNode.farthest_pos = -100000000;

function TipCarNode:ctor()
    
end
function TipCarNode:OnInit(txt, safe_distance, speed, acceleration)
    self.id = ParaGlobal.GenerateUniqueID();
    self.txt = txt;
    self.safe_distance = safe_distance;
    self.speed = speed;
    self.acceleration = acceleration;
    self.state = TipCarNode.states.stop;
    self.start_x = TipCarNode.farthest_pos;
    self.x = TipCarNode.farthest_pos;
    self.t = 0;
    self.length = 0;
    return self;
end
function TipCarNode:GetState()
    return self.state;
end
function TipCarNode:SetState(state)
    self.state = state;
end
function TipCarNode:GetSafeDistance()
    return self.safe_distance;
end
function TipCarNode:GetPosition()
    return self.x;
end
function TipCarNode:SetPosition(x)
    self.start_x = x;
    self.x = x;
end
function TipCarNode:SetLength(length)
    self.length = length;
end
function TipCarNode:GetLength()
    return self.length;
end
-- moving car by time delta
-- @param speed_state: the state of accelerated speed, 0 normal, -1 speed cut, 1 speed up
function TipCarNode:Move(delta,speed_state)
    delta = delta or 0;
    speed_state = speed_state or 0;
    self.t = self.t + delta;
    local s = 0;
    if(speed_state == 0)then
        s = self.t * self.speed;
    elseif(speed_state == -1)then
        s = self.t * self.speed - 0.5 * self.acceleration * self.t * self.t;
    elseif(speed_state == 1)then
        s = self.t * self.speed + 0.5 * self.acceleration * self.t * self.t;
    end
    self.x = self.start_x + s;
end