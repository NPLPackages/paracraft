--[[
Author(s): leio
Date: 2014/7/19
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/mcml_controls_layout_lite.lua");
local LayoutLite = commonlib.inherit(nil, commonlib.gettable("Map3DSystem.mcml_controls.LayoutLite"));
LayoutLite.test();

布局阶段：
1 measure()
--访问顺序
--"1/1/1/2"
--"1/1/1/1"
--"1/1/1"
--"1/1"
从最深层node开始计算每个控件大小,这个大小不一定是最终尺寸，只是个推荐值，在布局阶段可能发生改变
2 update()
--访问顺序
--"1/1"
--"1/1/1"
--"1/1/1/1"
--"1/1/1/2"
从最上层node开始布局，根据不同的规则，改变控件大小和位置
NOTE: 控件尺寸大小 优先级 explicit_width > measured_width > default_width

fbox:从左到右自动适应，超过最大宽度自动换行
vbox:垂直布局，子控件 宽度自动拉伸，高度平分
hbox:水平布局，子控件 高度自动拉伸，宽度平分
TODO:更好的布局解析规则
-------------------------------------------------------
]]
local LayoutLiteEletment = commonlib.inherit({
	x = 0,
	y = 0,
	available_width = 0,
	available_height = 0,
	measured_width = nil,
	measured_height = nil,
	old_measured_width = nil,
	old_measured_height = nil,
	explicit_width = nil,
	explicit_height = nil,
	min_width = nil,
	min_height = nil,
	max_width = nil,
	max_height = nil,
	default_width = 0,
	default_height = 0,
	parent = nil,
	mcmlNode = nil,
}, commonlib.gettable("Map3DSystem.mcml_controls.LayoutLiteEletment"));

--list = {{w = w, h = h,}, {w = w, h = h,},}
--output list = {{x = x, y = y, w = w, h = h,},{x = x, y = y, w = w, h = h,},}
local function listToGrid(list,max_width)
	--local list = {
	--	{w = 100, h = 10, index = 1,},
	--	{w = 50, h = 100, index = 2,},
	--	{w = 30, h = 40, index = 3,},
	--	{w = 100, h = 40, index = 4,},
	--	{w = 160, h = 40, index = 5,},
	--	{w = 100, h = 40, index = 6,},
	--	{w = 100, h = 40, index = 7,},
	--}
	local temp_width = 0;
	local k,v;
	local row,col = 0,0;
	local result = {};
	local len = #list;
	local function parse(index)
		if(index > len)then
			return
		end
		local temp_line_max_height = 0;
		row = row + 1;
		temp_width = 0;
		col = 0;
		local pos_x = 0;
		local pos_y = 0;
		local start_index = 0;
		for k = index,len do
			start_index = start_index + 1;
			local node = list[k];
			local width = node.w;
			col = col + 1;
			temp_width = temp_width + width;

			if(start_index > 1)then
				local pre_node = result[k-1] or {};
				local w = pre_node.w  or 0;
				pos_x = pos_x + w;
			end
			temp_line_max_height = math.max(temp_line_max_height,node.h);
			if(temp_width > max_width)then
				--new line
				if(k == index)then
					table.insert(result, {pos_x = pos_x, row = row, col = col, w = node.w, h = node.h, index = node.index, temp_line_max_height = temp_line_max_height,child_instance_layoutlite = node.child_instance_layoutlite,});
					parse(k+1)
				else
					parse(k)
				end
				break
			else
				table.insert(result, {pos_x = pos_x, row = row, col = col, w = node.w, h = node.h, index = node.index,temp_line_max_height = temp_line_max_height,child_instance_layoutlite = node.child_instance_layoutlite,});
			end
		end
	end
	parse(1);
	--计算行高度
	local line_height_map = {};
	local k,v;
	for k,v in ipairs(result)do
		local row = v.row;
		if(not line_height_map[row])then
			line_height_map[row] = v.temp_line_max_height or 0;
		else
			local max_height = line_height_map[row];
			max_height = math.max(max_height,v.temp_line_max_height or 0);
			line_height_map[row] = max_height;
		end
	end
	--计算y值
	for k,v in ipairs(result)do
		local row = v.row - 1;
		local kk;
		local pos_y = 0;
		for kk = 1,row do
			pos_y = pos_y + line_height_map[kk] or 0;
		end
		v.pos_y = pos_y;
	end
	echo("=============result");
	echo(line_height_map);
	local k,v;
	for k,v in ipairs(result)do
		echo(v);
	end
	echo("=============result 111");
	return result;
end
function LayoutLiteEletment:on_init()
end
function LayoutLiteEletment:setPreferredPos(x,y)
	self.x,self.y = x,y;
end
function LayoutLiteEletment:getPreferredPos()
	return self.x,self.y;
end
function LayoutLiteEletment:getOldMeasuredSize()
	return self.old_measured_width,self.old_measured_height;
end
function LayoutLiteEletment:setMeasuredSize(measured_width,measured_height)
	if(self.max_width)then
		measured_width = math.min(measured_width,self.max_width);
	end
	if(self.max_height)then
		measured_height = math.min(measured_height,self.max_height);
	end
	measured_width = math.max(measured_width,self.min_width or 0);
	measured_height = math.max(measured_height,self.min_height or 0);
	self.old_measured_width,self.old_measured_height = self.measured_width,self.measured_height;
	self.measured_width,self.measured_height = measured_width,measured_height;
end
--获得控件合适大小，优先级 explicit_width > measured_width > default_width
function LayoutLiteEletment:getPreferredSize()
	return (self.explicit_width or self.measured_width or self.default_width),(self.explicit_height or self.measured_height or self.default_height);
end
function LayoutLiteEletment:getBorderSize()
	local mcmlNode = self.mcmlNode;
	local css = mcmlNode:GetStyle() or {}
	local padding_left, padding_top, padding_bottom, padding_right = 
		(css["padding-left"] or css["padding"] or 0),(css["padding-top"] or css["padding"] or 0),
		(css["padding-bottom"] or css["padding"] or 0),(css["padding-right"] or css["padding"] or 0);

	local margin_left, margin_top, margin_bottom, margin_right = 
		(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
		(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
	local border_width = margin_left + margin_right + padding_left + padding_right;
	local border_height = margin_top + margin_bottom + padding_top + padding_bottom;
	return border_width,border_height;
end
function LayoutLiteEletment:getBoundsSize()
	local mcmlNode = self.mcmlNode;
	local border_width,border_height = self:getBorderSize();
	local preferred_width,preferred_height = self:getPreferredSize();

	local bounds_width = border_width + preferred_width;
	local bounds_height = border_height + preferred_height;
	return bounds_width,bounds_height;
end
function LayoutLiteEletment:setAvaliableSize(w,h)
	self.available_width,self.available_height = w,h;
end
function LayoutLiteEletment:getAvaliableSize()
	return self.available_width,self.available_height;
end
function LayoutLiteEletment:getFreeSize()
	local available_width,available_height = self:getAvaliableSize();
	local bounds_width,bounds_height = self:getBoundsSize();
	local free_width = available_width - bounds_width;
	local free_height = available_height - bounds_height;
	free_width = math.max(free_width,0);
	free_height = math.max(free_height,0);
	return free_width,free_height;
end
function LayoutLiteEletment:measure()
	local mcmlNode = self.mcmlNode;
	local css = mcmlNode:GetStyle() or {}
	local padding_left, padding_top, padding_bottom, padding_right = 
		(css["padding-left"] or css["padding"] or 0),(css["padding-top"] or css["padding"] or 0),
		(css["padding-bottom"] or css["padding"] or 0),(css["padding-right"] or css["padding"] or 0);

	local margin_left, margin_top, margin_bottom, margin_right = 
		(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
		(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	

	self.min_width = css["min-width"] or self.min_width or 0;
	self.min_height = css["min-height"] or self.min_height or 0;

	self.max_width = css["max-width"];
	self.max_height = css["max-height"];

	self.explicit_width = css["width"];
	self.explicit_height = css["height"];

	self.x = margin_left + padding_left;
	self.y = margin_top + padding_top;
	

	local preferred_width,preferred_height = self:getPreferredSize();
	local child_width,child_height = self:measure_child();
	local measured_width = (preferred_width or 0) + child_width;
	local measured_height = (preferred_height or 0) + child_height;

	self:setMeasuredSize(measured_width,measured_height);
end
function LayoutLiteEletment:measure_child()
	return 0,0;
end
function LayoutLiteEletment:update()
	local preferred_x,preferred_y = self:getPreferredPos();

	local preferred_width,preferred_height = self:getPreferredSize();
	local available_width,available_height = self:getAvaliableSize();
	local bounds_width,bounds_height = self:getBoundsSize();

	local free_width,free_height = self:getFreeSize()
	local measured_width = preferred_width;
	if(not self.explicit_width)then
		measured_width = preferred_width + free_width;
	end
	local measured_height = preferred_height;
	if(not self.explicit_height)then
		measured_height = preferred_height + free_height;
	end

	self:setMeasuredSize(measured_width,measured_height);

	self:updateDispaly();
end
function LayoutLiteEletment:updateDispaly()
end
--LayoutLiteEletment_Button
local LayoutLiteEletment_Button = commonlib.inherit(LayoutLiteEletment, commonlib.gettable("Map3DSystem.mcml_controls.LayoutLiteEletment_Button"));
function LayoutLiteEletment_Button:on_init()
	self.default_width = 40;
	self.default_height = 22;
end
function LayoutLiteEletment_Button.create(mcmlNode)
	local instance = LayoutLiteEletment_Button:new({
		mcmlNode = mcmlNode,
	});
	return instance;
end
function LayoutLiteEletment_Button:updateDispaly()
	local name = "";
	local preferred_x,preferred_y = self:getPreferredPos();
	local preferred_width,preferred_height = self:getPreferredSize();
	echo("==================button");
	if(self.parent)then
		echo({preferred_x, preferred_y, preferred_width, preferred_height});
		local btn = ParaUI.CreateUIObject("button", name, "_lt", preferred_x, preferred_y, preferred_width, preferred_height);
		self.parent:AddChild(btn);
	end
end
--LayoutLiteEletment_Container
local LayoutLiteEletment_Container = commonlib.inherit(LayoutLiteEletment, commonlib.gettable("Map3DSystem.mcml_controls.LayoutLiteEletment_Container"));
function LayoutLiteEletment_Container.create(mcmlNode)
	local instance = LayoutLiteEletment_Container:new({
		mcmlNode = mcmlNode,
	});
	return instance;
end
function LayoutLiteEletment_Container:measure_child()
	local mcmlNode = self.mcmlNode;
	
	local child_width = 0;
	local child_height = 0;

	local childnode;
	for childnode in mcmlNode:next() do
		local child_instance_layoutlite = childnode.instance_layoutlite;
		if(child_instance_layoutlite)then
			local bounds_width,bounds_height = child_instance_layoutlite:getBoundsSize();

			if(self.align == "h")then
				child_height = math.max(child_height,bounds_height);
				child_width = child_width + bounds_width;
			elseif(self.align == "v")then
				child_width = math.max(child_width,bounds_width);
				child_height = child_height + bounds_height;
			elseif(self.align == "left")then

			end
			
		end
	end
	return child_width,child_height;
end
function LayoutLiteEletment_Container:updateDispaly()
	local mcmlNode = self.mcmlNode;
	local preferred_x,preferred_y = self:getPreferredPos();
	local preferred_width,preferred_height = self:getPreferredSize();

	
	local name = "";
	echo("==================container");
	echo({preferred_x, preferred_y, preferred_width, preferred_height});
	local container = ParaUI.CreateUIObject("container", name, "_lt", preferred_x, preferred_y, preferred_width, preferred_height);
	self.parent:AddChild(container);
	local pos_x = 0;
	local pos_y = 0;
	local childnode;
	local index = 1;
	local temp_width = 0;
	local temp_max_height = 0;

	if(self.align == "left")then
		local list = {};
		local temp_instance_list = {};
		for childnode in mcmlNode:next() do
			local child_instance_layoutlite = childnode.instance_layoutlite;
			if(child_instance_layoutlite)then
				local w,h = child_instance_layoutlite:getBoundsSize();
				table.insert(list,{w = w,h = h,})

				temp_instance_list[#list] = child_instance_layoutlite;
			end
		end
		echo("===========preferred_width");
		echo(preferred_width);
		list = listToGrid(list,preferred_width);
		local k,v;
		for k,v in ipairs(list) do
			local child_instance_layoutlite = temp_instance_list[k]
			child_instance_layoutlite.parent = container;
			child_instance_layoutlite:setAvaliableSize(v.w,v.h);
			child_instance_layoutlite.x = v.pos_x;
			child_instance_layoutlite.y = v.pos_y;
		end
	else
		for childnode in mcmlNode:next() do
			local child_instance_layoutlite = childnode.instance_layoutlite;
			if(child_instance_layoutlite)then
				child_instance_layoutlite.parent = container;

				local child_bounds_width,child_bounds_height = child_instance_layoutlite:getBoundsSize();

				if(self.align == "h")then
					child_bounds_height = math.max(child_bounds_height,preferred_height);
					child_instance_layoutlite:setAvaliableSize(child_bounds_width,child_bounds_height);
					if(index > 1)then
						child_instance_layoutlite.x = child_instance_layoutlite.x + pos_x;
					end
					pos_x = pos_x + child_bounds_width;
				elseif(self.align == "v")then
					child_bounds_width = math.max(child_bounds_width,preferred_width);
					child_instance_layoutlite:setAvaliableSize(child_bounds_width,child_bounds_height);
					if(index > 1)then
						child_instance_layoutlite.y = child_instance_layoutlite.y + pos_y;
					end
					pos_y = pos_y + child_bounds_height;
				end
				index = index + 1;
			end
		end
	end
	
end
--LayoutLiteEletment_Container_HBox
local LayoutLiteEletment_Container_HBox = commonlib.gettable("Map3DSystem.mcml_controls.LayoutLiteEletment_Container_HBox");
function LayoutLiteEletment_Container_HBox.create(mcmlNode)
	local instance = LayoutLiteEletment_Container:new({
		mcmlNode = mcmlNode,
		align = "h",
	});
	return instance;
end
--LayoutLiteEletment_Container_VBox
local LayoutLiteEletment_Container_VBox = commonlib.gettable("Map3DSystem.mcml_controls.LayoutLiteEletment_Container_VBox");
function LayoutLiteEletment_Container_VBox.create(mcmlNode)
	local instance = LayoutLiteEletment_Container:new({
		mcmlNode = mcmlNode,
		align = "v",
	});
	return instance;
end
--LayoutLiteEletment_Container_FlowBox
local LayoutLiteEletment_Container_FlowBox = commonlib.gettable("Map3DSystem.mcml_controls.LayoutLiteEletment_Container_FlowBox");
function LayoutLiteEletment_Container_FlowBox.create(mcmlNode)
	local instance = LayoutLiteEletment_Container:new({
		mcmlNode = mcmlNode,
		align = "left",
	});
	return instance;
end
--LayoutLite
local LayoutLite = commonlib.inherit(nil, commonlib.gettable("Map3DSystem.mcml_controls.LayoutLite"));
LayoutLite.create_map = {
	["hbox"] = LayoutLiteEletment_Container_HBox.create,
	["vbox"] = LayoutLiteEletment_Container_VBox.create,
	["fbox"] = LayoutLiteEletment_Container_FlowBox.create,
	["input"] = LayoutLiteEletment_Button.create,
}
function LayoutLite:load(file_path,render_parent_container,width,height)
	if(not file_path or not render_parent_container)then return end
	self.children_list = {};--{ {node_path = "", mcmlNode = nil}}
	self.children_map = {};--{ {[node_path] = mcmlNode} }
	self.render_parent_container = render_parent_container;
	self.width = width;
	self.height = height;
	local xmlRoot = ParaXML.LuaXML_ParseFile(file_path);
	if(type(xmlRoot)=="table" and table.getn(xmlRoot)>0) then
		local xmlRoot = Map3DSystem.mcml.buildclass(xmlRoot);
		xmlRoot = xmlRoot[1];
		self:parseToList(xmlRoot,self.children_list,self.children_map,true);

		table.sort(self.children_list, function(a,b)
			return a.node_path < b.node_path;
		end)
	end
end
function LayoutLite:parseToList(mcmlNode,children_list,children_map,is_root)
	if(not mcmlNode or not mcmlNode.GetNodePath)then return end
	local create_func = LayoutLite.create_map[mcmlNode.name];
	if(create_func)then
		mcmlNode.instance_layoutlite = create_func(mcmlNode);
		mcmlNode.instance_layoutlite:on_init();
	end
	if(is_root)then
		mcmlNode.instance_layoutlite.parent = self.render_parent_container;
		mcmlNode.instance_layoutlite.available_width = self.width;
		mcmlNode.instance_layoutlite.available_height = self.height;
	end
	local node_path = mcmlNode:GetNodePath();
	if(node_path)then
		if(not children_map[node_path])then
			local data = {node_path = node_path, mcmlNode = mcmlNode,};
			table.insert(children_list, data);
			children_map[node_path] = data;

			local childnode;
			for childnode in mcmlNode:next() do
				self:parseToList(childnode,children_list,children_map,false);
			end
		else
			echo(string.format("duplicate node path:%s \n",node_path));
		end
	end
end
--访问顺序
--"1/1/1/2"
--"1/1/1/1"
--"1/1/1"
--"1/1"
function LayoutLite:measure()
	local len = #self.children_list;
	while(len > 0) do
		local node = self.children_list[len];
		local mcmlNode = node.mcmlNode;
		if(mcmlNode and mcmlNode.instance_layoutlite and mcmlNode.instance_layoutlite.measure)then
			
			mcmlNode.instance_layoutlite:measure();
			local bounds_width,bounds_height = mcmlNode.instance_layoutlite:getBoundsSize();
			echo({bounds_width,bounds_height});
		end
		len = len - 1;
	end
end
--访问顺序
--"1/1"
--"1/1/1"
--"1/1/1/1"
--"1/1/1/2"
function LayoutLite:update()
	local k,v;
	for k,v in ipairs(self.children_list) do
		local mcmlNode = v.mcmlNode;
		if(mcmlNode and mcmlNode.instance_layoutlite and mcmlNode.instance_layoutlite.update)then
			mcmlNode.instance_layoutlite:update();
		end
	end
end
function LayoutLite.test()
	NPL.load("(gl)script/kids/3DMapSystemApp/mcml/mcml_controls_layout_lite.lua");
	local LayoutLite = commonlib.inherit(nil, commonlib.gettable("Map3DSystem.mcml_controls.LayoutLite"));
	local layout_lite = LayoutLite:new();
	local render_parent_container = ParaUI.CreateUIObject("container", name, "_lt", 0, 0, 960, 560);
	render_parent_container:AttachToRoot();
	layout_lite:load("script/kids/3DMapSystemApp/mcml/test/test_layout_lite.html",render_parent_container,960,560);
	layout_lite:measure();
	layout_lite:update();
end


