--[[
Title: present a bag window
Author(s): LiXizhi
Date: 2008/11/4
Desc: pe:bag
		
---++ pe:bag
a bag is a fixed sized matrix container for items such as pe:command, pe:asset, pe:task etc. Drag and drop operations are allowed among bags of the same type
Contents of a bag can be retrieved and updated locally or remotely. Local bag stores content in local disk file, whereas remote bag update content via web services. 
Typically, we organize the belongings of a user into different local and remote bags. Customization to the local bags will be lost if a user switches computers. 
Hence, the remote bags are the persistent way to store user info. 

bags can be displayed as a fixed sized matrix of icons or as a list of items. 
@note: if one wants to use scrollables and paging, consider pe:gridview instead. 

attributes: 
| DataSource | a local/remote bag xml file, or the address of a XML bag service.|
| row | item row number. default to 5 |
| col | item column number. default to 4 |
| itemwidth | item width. this will replace the item size of content object. default to 32 |
| itempadding | number of pixels between items. default to 2|
| itemanimstyle | animstyle of sub items. | 
| itemassetcmd | the command to call when cliking sub items of pe:asset. |
| allowdrag | whether allow item drag and drop operations between bags of the same type |
| type | this is an arbitrary type string used during drag and drop operation. |
| autosave | default to true. if true, whenever the content is changed, it will immediately save to disk or via web service.|
| enabled| whether it is enabled |
| candelete | whether items can be deleted by dragging them out of the window. |

dynamic UI attributes:

the NPL UI control has dynamic attribute, which one can retrieve by GetAttributeObject():GetDynamicField("FieldName", "") |
This is usually used in drag and drop operations between bag and items
| DataSource | the data source object. |
If it has inner item nodes, they are always displayed in front of data source items. 

sample code: 
<verbatim> 
     <pe:bag DataSource="http://file.pala5.com/bags/trees.bag.xml" row="5" col="3" allowdrag="true" type="local_asset" autosave="true" itemanimstyle="14"/>
     <pe:bag DataSource="temp/mybags/trees.bag.xml" itemassetcmd="Creation.CreateObject" style="margin:3px;padding:2px" itemwidth="48" row="5" col="3" allowdrag="true" type="local_asset" autosave="true" itemanimstyle="14" >
		<pe:command cmd="File.Open.Asset" />
     </pe:bag>
</verbatim>

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_bag.lua");
-------------------------------------------------------
]]

if(not Map3DSystem.mcml_controls) then Map3DSystem.mcml_controls = {} end

-- all bags data
local bags = {};

-----------------------------------
-- pe:bag control:
-----------------------------------
local pe_bag = {};
Map3DSystem.mcml_controls.pe_bag = pe_bag;

-- tab pages are only created when clicked. 
function pe_bag.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css["pe:bag"]);
	local dataSource =  mcmlNode:GetAttributeWithCode("DataSource");
	local row =  mcmlNode:GetNumber("row") or 5;
	local col =  mcmlNode:GetNumber("col") or 5;
	local itemwidth =  mcmlNode:GetNumber("itemwidth") or 32;
	local itempadding =  mcmlNode:GetNumber("itempadding") or 4;
	local itemanimstyle =  mcmlNode:GetNumber("itemanimstyle");
	local itemassetcmd =  mcmlNode:GetString("itemassetcmd");
	local candrag = mcmlNode:GetBool("candelete"); -- maybe some other attributes will enable candrag to sub controls as well.
	
	left, top = parentLayout:GetAvailablePos();
	
	local padding_left, padding_top, padding_bottom, padding_right = 
		(css["padding-left"] or css["padding"] or 0),(css["padding-top"] or css["padding"] or 0),
		(css["padding-bottom"] or css["padding"] or 0),(css["padding-right"] or css["padding"] or 0);
	local margin_left, margin_top, margin_bottom, margin_right = 
		(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
		(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
	
	if(not css.float) then
		parentLayout:NewLine();
	end
	local myLayout = parentLayout:clone();
	myLayout:SetUsedSize(0,0);
	left,top = myLayout:GetAvailablePos();
	myLayout:SetPos(left,top);
	width,height = myLayout:GetSize();
	myLayout:reset(0, 0, width, height)
	-- for inner control preferred size
	myLayout:OffsetPos(margin_left+padding_left, margin_top+padding_top);
	myLayout:IncWidth(-margin_right-padding_right)
	myLayout:IncHeight(-margin_bottom-padding_bottom)
	
	local _this = ParaUI.CreateUIObject("container", "pe_bag", "_lt", left+margin_left, top+margin_top, width, height)
	if(css and css.background) then
		_this.background = css.background;
	else
		_this.background = "";
	end
	if(mcmlNode:GetAttribute("enabled")) then
		_this.enabled = mcmlNode:GetBool("enabled")
	end
	_parent:AddChild(_this);
	local att = _this:GetAttributeObject()
	att:SetDynamicField("DataSource", dataSource)
	
	local nCount = 0;
	-- add an item to slot
	-- @param itemNode: usually the mcml node of pe:asset and pe:command
	-- @return true if succeeded;
	local function AddItemToSlot(itemNode)
		nCount = nCount+1;
		if(nCount<row*col) then
			itemNode:SetAttribute("width", itemwidth);
			if(itemanimstyle) then
				itemNode:SetAttribute("animstyle", itemanimstyle);
			end
			if(itemNode.name=="pe:asset" and itemassetcmd) then
				itemNode:SetAttribute("cmd", itemassetcmd);
			end
			if(itemNode.name=="pe:asset" and candrag) then
				itemNode:SetAttribute("candrag", candrag);
			end
			
			local curCol = (nCount-1) % col+1;
			local curRow = math.floor((nCount-1)/col) + 1;
			itemNode:SetAttribute("tag", string.format("%s_%d_%d_", itemNode.name, curRow, curCol));
				
			local left, top, width, height = myLayout:GetPreferredRect();
			local myLayoutFake = myLayout:clone();
			Map3DSystem.mcml_controls.create(rootName, itemNode, bindingContext, _this, left, top, width, height, style, myLayoutFake)
			
			if(nCount%col == 0) then
				myLayout:AddObject(itemwidth, itemwidth+itempadding);
				myLayout:NewLine();
			else
				myLayout:AddObject(itemwidth+itempadding, itemwidth+itempadding);
			end
			return true;
		else
			commonlib.log("warning: too many items to display for the bag %s\n", dataSource)
		end	
	end
	
	local childnode;
	for childnode in mcmlNode:next() do
		if(not AddItemToSlot(childnode)) then 
			break 
		end
	end
	
	if(type(dataSource) == "string") then
		if(string.match(dataSource, "http://")) then
			-- TODO: remote xml or web serivce bag
		else
			-- local disk xml file. 
			local xmlRoot = ParaXML.LuaXML_ParseFile(dataSource);
			if(not xmlRoot) then 
				commonlib.log("warning: pe:bag can not locate local data source xml file %s\n", dataSource);
			else
				NPL.load("(gl)script/ide/XPath.lua");
				local fileNode;
				for fileNode in commonlib.XPath.eachNode(xmlRoot, "//pe:asset") do
					fileNode = Map3DSystem.mcml.buildclass(fileNode);
					if(not AddItemToSlot(fileNode)) then 
						break 
					end
				end
			end	
		end
	end
	
	local left, top = parentLayout:GetAvailablePos();
	local width, height = myLayout:GetUsedSize()
	if(css.width) then
		width = left + css.width + margin_left+margin_right;
	else
		width = left + itemwidth * col + itempadding *(col-1) + padding_right + margin_right + margin_left+padding_left;
	end	
	if(css.height) then
		height = top + css.height + margin_top+margin_bottom;
	else
		height = top + itemwidth * row + itempadding *(row-1) + padding_bottom + margin_bottom + margin_top + padding_top
	end
	parentLayout:AddObject(width-left, height-top);
	
	-- enable dragging to all sub button types items. 
	if(candrag) then
		local i, nCount = 1, _this:GetChildCount()
		for i=1, nCount do
			local _item = _this:GetChildAt(i);
			if(_item.candrag) then
				_item.ondragbegin = string.format([[;Map3DSystem.mcml_controls.pe_bag.OnDragBegin(%d);]], _item.id);
				_item.ondragend = string.format([[;Map3DSystem.mcml_controls.pe_bag.OnDragEnd(%d);]], _item.id);
			end
		end
	end
	
	if(not css.float) then
		parentLayout:NewLine();
	end
	_this:SetSize(width-left-margin_left-margin_right, height-top-margin_top-margin_bottom);
end

-- default bag asset drag begin handler
function pe_bag.OnDragBegin(id)
	--ParaUI.AddDragReceiver("root");
end

-- default bag asset drag end handler
function pe_bag.OnDragEnd(id)
	local _this = ParaUI.GetUIObject(id);
	local att = _this:GetAttributeObject();
	-- the current dragging object's location in the bag
	local row, col = string.match(att:GetDynamicField("tag", ""), "_(%d+)_(%d+)_");
	local AssetFile = att:GetDynamicField("AssetFile", "")
	-- the data source name of the original container bag. 
	local dataSource = _this.parent:GetAttributeObject():GetDynamicField("DataSource", "");
	
	-- the drop location
	local x, y = ParaUI.GetMousePosition();
	local temp = ParaUI.GetUIObjectAtPoint(x, y);
	if(not temp:IsValid()) then
		-- if dropped on the root, delete it
		-- TODO: this logics should be moved to application code, not in mcml implementation. 
		local function DeleteItem() 
			if(string.match(dataSource, "http://")) then
				-- TODO: remote xml or web serivce bag
			else
				-- local disk xml file. 
				local xmlRoot = ParaXML.LuaXML_ParseFile(dataSource);
				if(not xmlRoot) then 
					return
				end
				NPL.load("(gl)script/ide/XPath.lua");
				local fileNode, bagNode;
				-- add to the last bag in the file
				for bagNode in commonlib.XPath.eachNode(xmlRoot, "//pe:bag") do
					local nIndex;
					for nIndex, fileNode in ipairs(bagNode) do
						if(fileNode.attr and fileNode.attr["src"] == AssetFile) then
							commonlib.removeArrayItem(bagNode, nIndex);
						end
					end
				end
				-- output project file.
				ParaIO.CreateDirectory(dataSource);
				local file = ParaIO.open(dataSource, "w");
				if(file:IsValid()) then
					file:WriteString([[<?xml version="1.0" encoding="utf-8"?>]]);
					file:WriteString("\r\n");
					-- change encoding to "utf-8" before saving
					file:WriteString(ParaMisc.EncodingConvert("", "utf-8", commonlib.Lua2XmlString(xmlRoot)));
					file:close();
				end
				ParaUI.Destroy(id);
			end
		end	
	
		--_guihelper.MessageBox({row, col, dataSource, AssetFile})
		_guihelper.MessageBox(string.format("确定要删除\n%s?", AssetFile), DeleteItem);
	end
end
