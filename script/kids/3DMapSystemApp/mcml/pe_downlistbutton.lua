--[[
Title: 
Author(s): zrf
Date: 2011/3/21
Desc: 

------------------------------------------------

---++ pe:downlistbutton tag
| *Property*				| *Descriptions*				|
| name						| instance name|
| text						| 按钮上显示的文本|
| width						| width in pixel like "100px"	|
| height					| height in pixel like "100px"	|
| highlight_bg				| 按钮高亮时显示的背景图	|
| normal_bg					| 按钮正常时显示的背景图	|
| pressed_bg				| 按钮按下时显示的背景图	|
| invalid_bg				| 按钮无效时显示的背景图	|
| listwidth					| 弹出列表的宽度	|
| listheight				| 弹出列表的高度	|
| defaultlineheight			| 每行列表的默认高度	|
| list_bg					| 列表背景图	|
| list_lvl2_bg				| 2级列表背景图	|
| list_separator_bg			| 列表分隔图	|
| list_item_bg				| 列表节点图	|
| list_expand_bg			| 节点展开背景图	|
| list_expand_bg_mouseover	| 节点鼠标移上去显示的图	|


---++ pe:item tag
| *Property*				| *Descriptions*				|
| name						| instance name|
| text						| 节点文字	|
| onclick					| 节点被点击后触发的回调函数	|


use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_downlistbutton.lua");
-------------------------------------------------------
--]]

local pe_downlistbutton = commonlib.gettable("Map3DSystem.mcml_controls.pe_downlistbutton");

--local ItemManager = System.Item.ItemManager;
--local hasGSItem = ItemManager.IfOwnGSItem;

pe_downlistbutton.instances = {};
pe_downlistbutton.param = {};

function pe_downlistbutton.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local highlight_bg = mcmlNode:GetAttributeWithCode("highlight_bg") or "";
	local normal_bg = mcmlNode:GetAttributeWithCode("normal_bg") or "";
	local invalid_bg = mcmlNode:GetAttributeWithCode("invalid_bg") or "";
	local pressed_bg = mcmlNode:GetAttributeWithCode("pressed_bg") or "";
	local text = mcmlNode:GetAttributeWithCode("text") or "";


	local left, top, width, height = parentLayout:GetPreferredRect();
	local css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css["pe:downlistbutton"]) or {};

	local margin_left, margin_top, margin_bottom, margin_right = 
			(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
			(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	

	local tmpWidth = mcmlNode:GetNumber("width") or css.width;
	if(tmpWidth) then
		if((left + tmpWidth+margin_left+margin_right)<width) then
			width = left + tmpWidth+margin_left+margin_right;
		else
			parentLayout:NewLine();
			left, top, width, height = parentLayout:GetPreferredRect();
			width = left + tmpWidth+margin_left+margin_right;
		end
	end

	local tmpHeight = mcmlNode:GetNumber("height") or css.height
	if(tmpHeight) then
		height = top + tmpHeight+margin_top+margin_bottom
	end
	
	parentLayout:AddObject(width-left, height-top);
	left = left + margin_left
	top = top + margin_top;
	width = width - margin_right;
	height = height - margin_bottom;

	local instName = mcmlNode:GetAttribute("name");
	pe_downlistbutton.instances[instName] = mcmlNode;

	if(instName ==  nil) then
		log("error: nil name for pe:downlistbutton canvas\n")
		return;
	end

	local ctlname = "Aries_downlistbutton_tv_" .. instName;
	local btnname = "Aries_downlistbutton_btn_" .. instName;

	local _Canvas = ParaUI.CreateUIObject("container", instName, "_lt", left, top, width-left, height-top);
	_Canvas.background = "";
	_Canvas.fastrender = true;
	_parent:AddChild(_Canvas);
	local _btn = ParaUI.CreateUIObject("button", btnname, "_lt", 0, 0, width-left, height-top);
	_btn.text= text;
	_btn.onclick = string.format(";Map3DSystem.mcml_controls.pe_downlistbutton.OnButtonClick('%s')",instName );
	
	local font;
	if(css and (css["font-family"] or css["font-size"] or css["font-weight"]))then
		local font_family = css["font-family"] or "System";
		-- this is tricky. we convert font size to integer, and we will use scale if font size is either too big or too small. 
		local font_size = math.floor(tonumber(css["font-size"] or 12));
		local max_font_size = 20;
		local min_font_size = 11;
		if(font_size>max_font_size) then
			font_size = max_font_size;
		end
		if(font_size<min_font_size) then
			font_size = min_font_size;
		end
		local font_weight = css["font-weight"] or "norm";
		font = string.format("%s;%d;%s", font_family, font_size, font_weight);
	end
	if(css and css["text-offset-y"]) then
		_btn:GetAttributeObject():SetField("TextOffsetY", tonumber(css["text-offset-y"]) or 0)
	end
	if(font) then
		_btn.font = font;
	end

	if(normal_bg==highlight_bg and highlight_bg == pressed_bg)then
		_btn.background = normal_bg;
	else
		_guihelper.SetVistaStyleButton3(_btn, normal_bg, highlight_bg, normal_bg, pressed_bg);
	end
	_Canvas:AddChild(_btn);

	local listwidth = mcmlNode:GetNumber("listwidth") or 100;
	local listheight = mcmlNode:GetNumber("listheight") or 80;
	local defaultlineheight = mcmlNode:GetNumber("defaultlineheight") or 24;
	local list_bg = mcmlNode:GetString("list_bg") or "Texture/Aries/Creator/border_bg_32bits.png:3 3 3 3";
	local list_lvl2_bg = mcmlNode:GetString("list_lvl2_bg") or "Texture/Aries/Creator/border_bg_32bits.png:3 3 3 3";
	local list_separator_bg = mcmlNode:GetString("list_separator_bg") or "Texture/Aries/Dock/menu_separator_32bits.png";
	local list_item_bg = mcmlNode:GetString("list_item_bg") or "Texture/Aries/Dock/menu_item_bg_32bits.png: 10 6 10 6";
	local list_expand_bg = mcmlNode:GetString("list_expand_bg") or "Texture/Aries/Dock/menu_expand_32bits.png; 0 0 34 34";
	local list_expand_bg_mouseover = mcmlNode:GetString("list_expand_bg_mouseover") or "Texture/Aries/Dock/menu_expand_mouseover_32bits.png; 0 0 34 34";

	local ctl = CommonCtrl.GetControl(ctlname);
	if(ctl == nil)then
		ctl = CommonCtrl.ContextMenu:new{
			name = ctlname,
			width = listwidth,
			height = listheight, -- add menuitemHeight(30) with each new item
			DefaultNodeHeight = defaultlineheight,
			style = {
				borderTop = 4,
				borderBottom = 4,
				borderLeft = 4,
				borderRight = 4,
				
				fillLeft = 0,
				fillTop = 0,
				fillWidth = 0,
				fillHeight = 0,
				
				titlecolor = "#283546",
				level1itemcolor = "#283546",
				level2itemcolor = "#3e7320",
				
				iconsize_x = 24,
				iconsize_y = 21,
				
				menu_bg = list_bg,
				menu_lvl2_bg = list_lvl2_bg,
				shadow_bg = nil,
				separator_bg = list_separator_bg, -- : 1 1 1 4
				item_bg = list_item_bg,
				expand_bg = list_expand_bg,
				expand_bg_mouseover = list_expand_bg_mouseover,
				
				menuitemHeight = 24,
				separatorHeight = 2,
				titleHeight = 24,
				textFont = font,
				titleFont = font,
			},
		};
	end	

	ctl.RootNode:ClearAllChildren();
	local node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new{Text = "", Name = "Group", Type = "Group", NodeHeight = 0 });

	local function render_node(childnode,parentnode)
		if(type(childnode) ~= "table") then
			return true;
		end
		if(childnode.name == "pe:item") then
			local name = childnode:GetAttributeWithCode("name") or "name";
			local text = childnode:GetAttributeWithCode("text") or "text";
			local onclick = childnode:GetAttributeWithCode("onclick");
			local subnode = parentnode:AddChild(CommonCtrl.TreeNode:new({
			Text = text, 
			Name = name, 
			Type = "Menuitem", 
			onclick = function()
				if(type(onclick)=="function")then
					onclick(name,text);
				end
			end, }));
				
			local childnode_;
			for childnode_ in childnode:next() do
				if(type(childnode_) == "table") then
					render_node(childnode_,subnode);
				end
			end				
		end
		return true;
	end	
	
	local childnode;
	for childnode in mcmlNode:next() do
		if(not render_node(childnode,node)) then
			break;
		end
	end
end

function pe_downlistbutton.OnButtonClick(instName)
	CommonCtrl.TooltipHelper.HideLast();
	local mcmlNode = pe_downlistbutton.instances[instName];
	local tvname = "Aries_downlistbutton_tv_" .. instName;
	local ctl = CommonCtrl.GetControl(tvname);
	if(ctl)then
		local parentNode = ctl.RootNode:GetChild(1);
		local i;
		for i = 1, parentNode:GetChildCount() do
			local node = parentNode:GetChild(i);
			if(node) then
				node.mcmlNode = mcmlNode;
			end
		end

		local _can = ParaUI.GetUIObject(instName);
		local x,y = _can:GetAbsPosition();
		if(_can)then
			ctl:Show(x, y+_can.height);
		end
	end
end


-- get the MCML value on the node
function pe_downlistbutton.GetValue(mcmlNode)
	return mcmlNode:GetAttribute("value") or mcmlNode:GetInnerText();
end

-- set the MCML value on the node
function pe_downlistbutton.SetValue(mcmlNode, value)
	--if(type(value) == "string") then
		--mcmlNode:SetInnerText(value)
	--else
		--mcmlNode:SetInnerText(nil);
	--end	
	local instName = mcmlNode:GetAttribute("name");
	local btnname = "Aries_downlistbutton_btn_" .. instName;
	local _btn = ParaUI.GetUIObject(btnname);

	if(_btn)then
		if(type(value)=="string")then
			_btn.text = value;
		else
			_btn.text = "";
		end
	end
end

-- get the UI value on the node
function pe_downlistbutton.GetUIValue(mcmlNode, pageInstName)
	local ctl = mcmlNode:GetControl(pageInstName);
	if(ctl) then
		return ctl.text;
	end
end

-- set the UI value on the node
function pe_downlistbutton.SetUIValue(mcmlNode, pageInstName, value)
	local ctl = mcmlNode:GetControl(pageInstName);
	if(ctl) then
		if(value) then
			local text = tostring(value);
			--resize control
			local textWidth = _guihelper.GetTextWidth(text) + 6
			ctl.width = textWidth;
			ctl.text = text;
		else
			ctl.text = "";
		end	
	end
end