--[[
Title: pe aries share
Author(s): LiXizhi
Date: 2012/9/17
Desc: 
---++ pe:share
pe:share is a custom button that add a share of text, images, url to multiple SNS sites.
<verbatim>
	<pe:share platform="qq" needconfirm="false" text="" >
		<input name="share" type="button" value="Share!" />
	</pe:share>
</verbatim>

| *property* | *desc*|
| platform | "qq", "sina" | 
| title | |
| url | the url to share. must begin with http:// |
| content | the content to share|
| summary | similar to content. |
| images | urls, multiple images needs to be separated by vertical line(|) |

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/mcml/pe_aries_share.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/math/vector.lua");
local math_abs = math.abs;
local vector3d = commonlib.gettable("mathlib.vector3d");

-----------------------------------
-- pe:share control
-----------------------------------
local pe_aries_share = commonlib.gettable("MyCompany.Aries.mcml_controls.pe_aries_share");

function pe_aries_share.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, width, height, myLayout, css)
	local share_button_name = "share"
	local btnNode = mcmlNode:SearchChildByAttribute("name", share_button_name);
	if(btnNode) then
		btnNode:SetValue("onclick", function()
			pe_aries_share.OnClickShare(mcmlNode);
		end)
	else
		LOG.std(nil, "warn", "pe_aries_share", "no share button found in the mcml page's pe:share tag");
	end

	-- for inner nodes
	mcmlNode:DrawChildBlocks_Callback(rootName, bindingContext, _parent, left, top, width, height, myLayout, css);

	return true, true, true; -- ignore_onclick, ignore_background, ignore_tooltip;
end

function pe_aries_share.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, pe_aries_share.render_callback);
end

function pe_aries_share.OnClickShare_imp(mcmlNode)
	NPL.load("(gl)script/apps/Aries/Partners/PartnerPlatforms.lua");
	local Platforms = commonlib.gettable("MyCompany.Aries.Partners.Platforms");
	
end

function pe_aries_share.OnClickShare(mcmlNode)
	NPL.load("(gl)script/apps/Aries/Partners/PartnerPlatforms.lua");
	local Platforms = commonlib.gettable("MyCompany.Aries.Partners.Platforms");
	Platforms.CallMethod("postToFeed", {title="test", url="www.paraengine.com", comment="text content",  summary="text summary", images="http://res.61.com/images/comm/banner/b_haqi.png" }, function(errCode) end)
end


-----------------------------------
-- pe:mcworld control
-----------------------------------
local pe_mcworld = commonlib.gettable("MyCompany.Aries.mcml_controls.pe_mcworld");

function pe_mcworld.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css["pe:mcworld"], style) or {};

	-- set inner text
	mcmlNode:SetInnerText("创意空间");
	mcmlNode:SetAttribute("onclick", "MyCompany.Aries.mcml_controls.pe_mcworld.OnClick");
	mcmlNode:SetAttribute("tooltip", "点击访问");


	-- just use the standard style to create the control	
	Map3DSystem.mcml_controls.pe_simple_styles.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, css, parentLayout);
end

function pe_mcworld.OnClick(name, mcmlNode)
	local nid = mcmlNode:GetAttributeWithCode("nid");
	local slot_id = mcmlNode:GetAttributeWithCode("slot");
	if(nid) then
		nid = tonumber(nid);
		slot_id = tonumber(slot_id);

		NPL.load("(gl)script/apps/Aries/Creator/Game/GameMarket/OtherPeopleWorlds.lua");
		local OtherPeopleWorlds = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.OtherPeopleWorlds");
		OtherPeopleWorlds.OnHandleGotoHomeLandCmd({nid = nid, slot_id=slot_id});
	end
end