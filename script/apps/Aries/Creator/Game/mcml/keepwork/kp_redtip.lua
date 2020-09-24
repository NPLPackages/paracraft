--[[
Title: mcml tag for callling attention
Author(s): leio
Date: 2020/6/19
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/keepwork/kp_redtip.lua");
local kp_redtip = commonlib.gettable("MyCompany.Aries.Game.mcml.kp_redtip");
--]]

local kp_redtip = commonlib.gettable("MyCompany.Aries.Game.mcml.kp_redtip");
function kp_redtip.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
    local width = 10;
    local height = 10;
    local resized = mcmlNode:GetBool("resized",false);
    if(resized)then
        width = right-left;
        height = bottom-top;
    end
	local _this = ParaUI.CreateUIObject("container", "b", "_lt", left, top, width, height);

    local function showBg(b)
        if(b == true)then
	        _this.background = "Texture/Aries/Creator/keepwork/LearningDailyCheck/red_tip_32bits.png;0 0 10 10";
        else
	        _this.background = "";
        end
    end
	_this.zorder = mcmlNode:GetNumber("zorder") or 0;
	_parent:AddChild(_this);
	

	local instName = mcmlNode:GetInstanceName(rootName);
    local instName_timer = instName .. "_timer";
	local timer = CommonCtrl.GetControl(instName_timer);
    if(not timer)then
        NPL.load("(gl)script/ide/timer.lua");
        timer = commonlib.Timer:new();
	    CommonCtrl.AddControl(instName_timer, timer);
    end
    timer.callbackFunc = function()
	    local bShowing_redtip = mcmlNode:GetBool("value",false);
        if(not bShowing_redtip)then
	        bShowing_redtip = mcmlNode:GetAttributeWithCode("onupdate",false,true);
        end
        showBg(bShowing_redtip);
    end
    timer:Change(0, 1000)
    
	return true, true, true; -- ignore_onclick, ignore_background, ignore_tooltip;
end


-- this is just a temparory tag for offline mode
function kp_redtip.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, kp_redtip.render_callback);
end
