--[[
Title: 
Author(s): leio
Date: 2020/5/8
Desc:  
Use Lib:
-------------------------------------------------------
local TipRoad = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ScreenTipRoad/TipRoad.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/gui_helper.lua");
local TipCarNode = NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/ChatSystem/ScreenTipRoad/TipCarNode.lua");
local TipRoad = commonlib.inherit(nil, NPL.export());
function TipRoad:ctor()
    self.car_nodes = {};
end

function TipRoad:OnInit(parent, x, y, width, height)
    self.id = ParaGlobal.GenerateUniqueID();
	local container = ParaUI.CreateUIObject("container", self.id, "lt", x, y, width, height);
    container:SetField("ClickThrough", true);
	container.background = "";
	parent:AddChild(container);
    self.container = container;
    self.parent = parent;
    self.x = x;
    self.y = y;
    self.width = width;
    self.height = height;
    return self;
end
function TipRoad:GetLength()
    return self.width;
end
function TipRoad:AddCarNode(car_node)
    if(not car_node)then
        return
    end
    table.insert(self.car_nodes,car_node);
end
function TipRoad:RemoveCarNode(index)
    local car_node = self.car_nodes[index];
    if(not car_node)then
        return
    end
    table.remove(self.car_nodes,index);
end
function TipRoad:GetNodeCnt()
    local stop_cnt = 0;
    local waitting_cnt = 0;
    local running_cnt = 0;
    for k, v in ipairs(self.car_nodes) do
        local state = v:GetState();
        if(state == TipCarNode.states.stop)then
            stop_cnt = stop_cnt + 1;
        elseif(state == TipCarNode.states.waitting)then
            waitting_cnt = waitting_cnt + 1;
        elseif(state == TipCarNode.states.running)then
            running_cnt = running_cnt + 1;
        end
    end
    return stop_cnt,waitting_cnt,running_cnt
end
function TipRoad:DrawCarNode(car_node)
    if(not car_node)then
        return
    end
    local state = car_node:GetState();
    if(state == TipCarNode.states.waitting)then
        local x = car_node:GetPosition();
        local width = car_node:GetLength();

        local _this = ParaUI.CreateUIObject("text", car_node.id, "_lt", x, 0, width, car_node.font_size)
		_this.text = car_node.txt;
        _this.font = car_node:GetFont();
		self.container:AddChild(_this);
		_guihelper.SetFontColor(_this, car_node.color);

    elseif(state == TipCarNode.states.running)then
        local _this = ParaUI.GetUIObject(car_node.id);
        if(_this and _this:IsValid())then
            local x = car_node:GetPosition();
            _this.x = x;
        end
    elseif(state == TipCarNode.states.removed)then
        ParaUI.Destroy(car_node.id);
    end
end
function TipRoad:Clear()
    for k, car_node in ipairs(self.car_nodes) do
        ParaUI.Destroy(car_node.id);
    end
    self.car_nodes = {};
end
function TipRoad:OnFrame(delta)
    local pre_car_node = nil;
    for k,v in ipairs (self.car_nodes) do
        local state = v:GetState();
        pre_car_node = self.car_nodes[k-1];
        if(state == TipCarNode.states.stop)then
            local pos = self:GetLength();
            v:SetPosition(pos + v:GetSafeDistance());
            v:SetState(TipCarNode.states.waitting)
            self:DrawCarNode(v);
        elseif(state == TipCarNode.states.waitting)then
            local safe_distance = self:GetSafeDistance(pre_car_node, v);
            if(not safe_distance or (safe_distance >= v:GetSafeDistance()))then
                v:SetState(TipCarNode.states.running);
            end
        elseif(state == TipCarNode.states.running)then
--            local safe_distance = self:GetSafeDistance(pre_car_node, v);
--            if(safe_distance)then
--                local offset = 50;
--                if((safe_distance - v:GetSafeDistance()) > offset)then
--                    v:Move(delta * 2);
--                else
--                    v:Move(delta);
--                end
--            else
--            end
            v:Move(delta);
            

            local min_pos = -(v:GetLength());
            if(v:GetPosition() <= min_pos)then
                v:SetState(TipCarNode.states.removed);
            end
            self:DrawCarNode(v);
        end

    end

    local len = #(self.car_nodes);
    while(len > 0)do
        local node = self.car_nodes[len];
        if(node)then
            if(node:GetState() == TipCarNode.states.removed)then
                self:RemoveCarNode(len);
            end
        end
        len = len - 1;
    end
end
function TipRoad:GetSafeDistance(pre_car_node, car_node)
    if(not pre_car_node or not car_node)then
        return
    end
    local distance = car_node:GetPosition() -  (pre_car_node:GetPosition() + pre_car_node:GetLength());
    return distance;
end

function TipRoad:OnResize(width)
    self.width = width;
    self.container.width = width;

     for k, v in ipairs(self.car_nodes) do
        local state = v:GetState();
        if(state == TipCarNode.states.stop or state == TipCarNode.states.waitting)then
            local pos = self:GetLength();
            v:SetPosition(pos + v:GetSafeDistance());

	        local _this = ParaUI.GetUIObject(v.id);
            if(_this and _this:IsValid())then
                _this.x = v:GetPosition();
            end
        end
    end
end
