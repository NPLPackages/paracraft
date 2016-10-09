--[[
Title: present an asset object to be created
Author(s): LiXizhi
Date: 2008/10/28
Desc: pe:asset
		
---++ pe:asset
By default, it displays the icon of a 3D asset. The inner content will be shown when mouse over it. 
pe:asset behaves very much like pe:command, except that its background image are automatically extracted from src. 

attributes: 
| src | source model file. it can also be asset url. |
| tag | the dynamic field of UI control tag.  usually this is set by its parent bag for _row_col_|
| type | "model", "char", default to "model" |
| cmd or command | command to call, when user clicks on it. if nil, it does nothing. Some build-in commands are "Creation.CreateObject", "Creation.UploadObject", "Profile.TradeItem", etc. All attributes of the node plus the params are passed as parameters to the command. |
| params | a string or table to be passed to the command. If it is table, it will be serialized to sCode. it must not be long. |
| Density | |
| animstyle | number such as 11, 12, 13, 14, 21, 22,23,24 |
| scaling | |
| PhysicsRadius | |
| width | size of icon |
| tooltip | text displayed when mouse over |
| candrag | whether allow dragging |

dynamic UI attributes:

the NPL UI control has dynamic attribute, which one can retrieve by GetAttributeObject():GetDynamicField("FieldName", "") |
This is usually used in drag and drop operations between bag and items
| AssetFile | AssetFile string |
| tag | the tag MCML node attribute |

sample code: 
<verbatim> 
     <pe:asset src="model/06props/shared/pops/muzhuang.x" type="model" />
     <pe:asset src="model/06props/shared/pops/muzhuang.x" params='<%={name="li.xi.zhi"}%>'/>
</verbatim>

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_asset.lua");
-------------------------------------------------------
]]

if(not Map3DSystem.mcml_controls) then Map3DSystem.mcml_controls = {} end

-----------------------------------
-- pe:asset control:
-----------------------------------
local pe_asset = {};
Map3DSystem.mcml_controls.pe_asset = pe_asset;

-- tab pages are only created when clicked. 
function pe_asset.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css["pe:asset"]);
	local commandName =  mcmlNode:GetAttributeWithCode("cmd") or mcmlNode:GetAttributeWithCode("command");
	local onclick =  mcmlNode:GetAttributeWithCode("onclick");
	local tag = mcmlNode:GetAttributeWithCode("tag");
	local src =  mcmlNode:GetAttributeWithCode("src");
	local assetType =  mcmlNode:GetAttributeWithCode("type");
	local background;
	local tooltip;
	if(src) then
		background = src..".png";
	end
	
	tooltip = mcmlNode:GetAttributeWithCode("tooltip") or tooltip;
	if(css and css.background) then
		background = css.background;
	end
	
	local icon = mcmlNode:GetAttributeWithCode("icon")
	if(icon) then
		background = icon;
	end

	local buttonWidth = mcmlNode:GetNumber("width") or css.width;
	
	width = parentLayout:GetPreferredSize();
	if(buttonWidth>width) then
		parentLayout:NewLine();
		width = parentLayout:GetMaxSize();
		if(buttonWidth>width) then
			buttonWidth = width
		end
	end
	left, top = parentLayout:GetAvailablePos();
	
	local margin_left, margin_top, margin_bottom, margin_right = 
		(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
		(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
	
	local height = css.height or buttonWidth;
	
	local _this = ParaUI.CreateUIObject("button", "pe_asset", "_lt", left+margin_left, top+margin_top, buttonWidth, height)
	
	if(background) then
		_this.background = background;
	end
	if(tooltip) then
		_this.tooltip = tooltip
	end
	if(mcmlNode:GetAttribute("enabled")) then
		_this.enabled = mcmlNode:GetBool("enabled")
	end
	if(mcmlNode:GetBool("candrag")) then
		_this.candrag = true;
	end
	local animstyle = mcmlNode:GetNumber("animstyle");
	if(animstyle~=nil) then
		_this.animstyle = animstyle;
	end
	
	if((commandName and commandName~="") or onclick) then
		local objParams = mcmlNode:GetAttributeWithCode("params");
		if(type(objParams) ~= "table") then
			objParams = {};
		end	
		if(assetType) then
			if(assetType == "char" or assetType == "character") then
				objParams.IsCharacter = true;
			end
		end
		
		objParams.AssetFile = objParams.AssetFile or src;
		objParams.name = objParams.name or mcmlNode:GetAttributeWithCode("name");
		objParams.scaling = objParams.scaling or tonumber(mcmlNode:GetAttributeWithCode("scaling"));
		objParams.PhysicsRadius = objParams.PhysicsRadius or tonumber(mcmlNode:GetNumber("PhysicsRadius"));
		objParams.Density = objParams.Density or tonumber(mcmlNode:GetAttributeWithCode("Density"));
		objParams.facing = objParams.facing or tonumber(mcmlNode:GetAttributeWithCode("facing"));
		objParams.x = objParams.x or tonumber(mcmlNode:GetAttributeWithCode("x"));
		objParams.y = objParams.y or tonumber(mcmlNode:GetAttributeWithCode("y"));
		objParams.z = objParams.z or tonumber(mcmlNode:GetAttributeWithCode("z"));
		objParams.localMatrix = objParams.localMatrix or mcmlNode:GetAttributeWithCode("localMatrix");
		
		local att = _this:GetAttributeObject()
		if(objParams.AssetFile) then
			att:SetDynamicField("AssetFile", objParams.AssetFile)
		end	
		if(tag) then
			att:SetDynamicField("tag", tag)
		end	
		
		objParams = commonlib.serialize_compact(objParams)
		if((commandName and commandName~="")) then
			_this.onclick = string.format(";Map3DSystem.App.Commands.Call(%q,%s);", commandName, objParams);
		elseif(onclick) then
			onclick = string.gsub(onclick, "[%(%);]+","");
			_this.onclick = string.format(";%s(%s);", onclick, objParams);
		end	
	end
	_parent:AddChild(_this);
	
	parentLayout:AddObject(buttonWidth+margin_left+margin_right, margin_top+margin_bottom+height);
end

