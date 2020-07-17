--[[
Title: icon tag for user
Author(s): leio
Date: 2020/7/15
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/keepwork/kp_usertag.lua");
local kp_usertag = commonlib.gettable("MyCompany.Aries.Game.mcml.kp_usertag");
--]]
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");

local kp_usertag = commonlib.gettable("MyCompany.Aries.Game.mcml.kp_usertag");

function kp_usertag.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
	local _this = ParaUI.CreateUIObject("container", "c", "_lt", left, top, right-left, bottom-top);
	_parent:AddChild(_this);
    local function set_icon(tag,gray)
        if(not tag)then
            return
        end
        local icons = {
            ["VT"] = { background = "Texture/Aries/Creator/keepwork/UserInfo/VT_32bits.png;0 0 34 18",  width = 34, height = 18, },  
            ["VT_gray"] = { background = "Texture/Aries/Creator/keepwork/UserInfo/VT_gray_32bits.png;0 0 34 18",  width = 34, height = 18, },  

            ["T"] = { background = "Texture/Aries/Creator/keepwork/UserInfo/T_32bits.png;0 0 18 18",  width = 18, height = 18, },  
            ["T_gray"] = { background = "Texture/Aries/Creator/keepwork/UserInfo/T_gray_32bits.png;0 0 18 18",  width = 18, height = 18, },  

            ["V"] = { background = "Texture/Aries/Creator/keepwork/UserInfo/V_32bits.png;0 0 18 18",  width = 18, height = 18, },  
            ["V_gray"] = { background = "Texture/Aries/Creator/keepwork/UserInfo/V_gray_32bits.png;0 0 18 18",  width = 18, height = 18, },  
        }
        local key = tag;
        if(gray)then
            key = key .. "_gray";
        end
        local icon = icons[key];
        if(icon)then
	        _this.background = icon.background;
        end
    end
	local tag = mcmlNode:GetAttributeWithCode("tag", nil, true);
	local gray = mcmlNode:GetAttributeWithCode("gray", false, true);
	local username = mcmlNode:GetAttributeWithCode("username", nil, true);

    if(tag)then
        set_icon(tag,gray);
        return
    end


	KeepWorkItemManager.GetUserInfo({
        username = username,
    },function(err,msg,data)
        if(err ~= 200)then
            return
        end
        local tag = KeepWorkItemManager.GetUserTag(data);
        set_icon(tag,gray);
    end)
	
	
	return true, true, true; -- ignore_onclick, ignore_background, ignore_tooltip;
end


-- this is just a temparory tag for offline mode
function kp_usertag.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, kp_usertag.render_callback);
end
