--[[
Title: mostly for displaying 2d map and map marks 
Author(s): LiXizhi
Date: 2011/5/18
Desc: 
--++ pe:viewport
See :test_pe_viewport.html

<verbatim>
local pointdata = {
{x=0, y=0,width=40,tooltip="0,0"}, 
{x=20, y=20,tooltip="20,20"},
{x=30, y=30,tooltip="30,30"},
{x=50, y=50,tooltip="50,10"},

};
local texdata = { 
{left=-100,top=-100,right=0,bottom=0,background="Texture/16number.png",}, 
{left=0,top=-100,right=100,bottom=0,background="Texture/16number.png",}, 
{left=0,top=0,right=100,bottom=100,background="Texture/16number.png",}, 
{left=-100,top=0,right=0,bottom=100,background="Texture/16number.png",}, 
};

function DS_Func_tex(index)
    if(index==nil)then
        return #texdata;
    else
        return texdata[index];
    end
end

function DS_Func_point(index)
    if(index==nil)then
        return #pointdata;
    else
        return pointdata[index];
    end
end


<div style="width:600px;height:600px">
    <pe:viewport style="width:160px;height:160px;background:url(Texture/alphadot.png)" 
        name="my_minimap" active_rendering="true" mask_texture="Texture/Aries/Common/circular_mask.png" 
        ClipCircle="0,0,100" >
        <pe:texture_grid>
            <pe:textureassemble name="tex" DataSource='<%=DS_Func_tex %>' />
        </pe:texture_grid>
        <pe:point_cache>
            <pe:pointassemble name="po" default_width="20" default_height="40" default_background="Texture/Aries/WorldMaps/HaqiTownMap/MagicForest2_32bits.png; 0 0 60 52" DataSource='<%=DS_Func_point %>' />
        </pe:point_cache>

    </pe:viewport>
</div>
</verbatim>

---+++ attributes
| *Property*		| *Descriptions*				|
| name				| unique local viewport instance name|
| background		| viewport background url			|
| width				| width in pixel like "100px"	|
| height			| height in pixel like "100px"	|
| ClipRect			| "centerx,centery,width,height"	|
| ClipCircle		| "centerx,centery,radius"	|
| zorder | if specified a parent container of the same zorder will be created in its place. otherwise it will create on the default container. |
| flip_vertical | whether to flip all points vertically. this is usually true for 3D avatar because the y axis direction is different in 3D than in 2d. |

---+++ pe:texture_grid sub node
texture grid background either 2d or dynamic textures rendered in 3d. 

---+++ pe:pointcache sub node
| *Property*		| *Descriptions*				 |
| default_background| 如果点数据中没有指定background,则采用本图片 |
| default_width		| 如果点数据中没有指定width,则采用此宽度, 未设置时默认为8 |
| default_height	| 如果点数据中没有指定height,则采用此高度, 未设置时默认为8 |
| tooltip			| mouse over tooltip |
| DataSource		| 标记对应的坐标的数据源函数,像素为单位 {{x=10, y=10,tooltip="",background="",width=20,height=30，}, {x=20, y=20},{x=30, y=30},} |

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_viewport.lua");
-------------------------------------------------------
--]]

NPL.load("(gl)script/ide/timer.lua");
NPL.load("(gl)script/ide/Display2D/viewport2d.lua");
local viewport2d = commonlib.gettable("CommonCtrl.Display2D.viewport2d");
local pe_viewport = commonlib.gettable("Map3DSystem.mcml_controls.pe_viewport");

pe_viewport.LocalMaps = {};
pe_viewport.instances = {};

-- create view port 
function pe_viewport.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, pe_viewport.render_callback);
end

-- render call back
function pe_viewport.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
	local pageCtrl = mcmlNode:GetPageCtrl();
	local my_view = mcmlNode.my_view or viewport2d:new({
		name = mcmlNode:GetString("name"),
		flip_vertical = mcmlNode:GetBool("flip_vertical"),
	});
	mcmlNode.my_view = my_view;

	local zorder = mcmlNode:GetNumber("zorder");
	if(zorder) then
		local _this = ParaUI.CreateUIObject("container", "c", "_lt", left, top, right-left,bottom-top);
		_this:GetAttributeObject():SetField("ClickThrough", true);
		_this.background = ""
		_this.zorder = zorder;
		_parent:AddChild(_this);
		_parent = _this;
		left, top, right, bottom = 0, 0, right-left, bottom-top;
	end

	local point_ui_radius = mcmlNode:GetNumber("point_ui_radius");
	if(point_ui_radius) then
		my_view:set_point_ui_radius(point_ui_radius);
	end
	my_view:clear();

	local my_tex = my_view:get_texture_grid();
	local mask_texture = mcmlNode:GetString("mask_texture")
	local is_active_rendering = mcmlNode:GetBool("active_rendering");
	my_tex:set_active_rendering(is_active_rendering);
	if(mask_texture) then
		my_tex:set_mask_texture(mask_texture)
	end
	my_tex:clear();

	-- add child nodes
	local childnode;
	for childnode in mcmlNode:next() do
		if(type(childnode) == "table") then
			if(childnode.name=="pe:texture_grid") then
				-- static texture here
				local subnode;
				for subnode in childnode:next() do
					if(type(subnode) == "table" and subnode.name=="pe:texture") then
						local tmp = {left=subnode:GetNumber("left"),top=subnode:GetNumber("top"), right=subnode:GetNumber("right"), bottom=subnode:GetNumber("bottom"), background=subnode:GetString("filename")};
						my_tex:add(subnode:GetAttribute("name"), tmp);
					elseif(type(subnode) == "table" and subnode.name=="pe:textureassemble")then
						local DataSource = subnode:GetAttributeWithCode("DataSource");
						local subname = subnode:GetString("name") or "";
						if(DataSource == nil)then
							log("error: DataSource must be specified in pe:textureassemble: \n");
							commonlib.echo(subnode);
							return false;
						end

						subnode.datasource = DataSource;
						local count;
						if(type(subnode.datasource)=="function")then
							count = subnode.datasource() or 0;
						elseif(type(subnode.datasource)=="table")then
							count = #(subnode.datasource);
						end

						
						local i;

						if( count and count > 0 )then
							for i = 1,count do
								local row;
								if(type(subnode.datasource) == "function")then
									row = subnode.datasource(i);
								elseif(type(subnode.datasource) == "table")then
									row = subnode.datasource[i];									
								end

						
								if(row and type(row) == "table")then
									my_tex:add( subname .. i, row);
								end
							end
						end
					end
				end
				-- TODO: dsFunc here for dynamic texture
			elseif(childnode.name=="pe:point_cache") then
				-- static point here
				local subnode;
				for subnode in childnode:next() do
					if(type(subnode) == "table" and subnode.name=="pe:point") then
						my_view:add(subnode:GetAttribute("name"), {
							x=subnode:GetNumber("x"),
							y=subnode:GetNumber("y"), 
							tooltip=subnode:GetString("tooltip"),
							width = subnode:GetNumber("width") or 8,
							height = subnode:GetNumber("height") or 8,
							background = subnode:GetString("background"), });

					elseif(type(subnode) == "table" and subnode.name=="pe:pointassemble")then					
						local DataSource = subnode:GetAttributeWithCode("DataSource");
						local subname = subnode:GetString("name") or "";
						local default_bg = subnode:GetString("default_background");
						local default_width = subnode:GetNumber("default_width") or 8;
						local default_height = subnode:GetNumber("default_height") or 8;

						
						if(DataSource == nil)then
							log("error: DataSource must be specified in pe:pointassemble: \n");
							commonlib.echo(subnode);
							return false;
						end

						subnode.datasource = DataSource;
						local count;
						if(type(subnode.datasource)=="function")then
							count = subnode.datasource() or 0;
						elseif(type(subnode.datasource)=="table")then
							count = #(subnode.datasource);
						end

						local i;

						if( count and count > 0 )then
							for i = 1,count do
								local row;
								if(type(subnode.datasource)=="function")then
									row = subnode.datasource(i);
								elseif(type(subnode.datasource)=="table")then
									row = subnode.datasource[i];									
								end

						
								if(row and type(row) == "table")then
									row.background = row.background or default_bg;
									row.width = row.width or default_width;
									row.height = row.height or default_height;
									row.x = row.x or 0;
									row.y = row.y or 0;
									my_view:add( subname .. i, row );
								end
							end
						end
					end
				end
			end
		end
	end
		
	local ClipRect = mcmlNode:GetString("ClipRect") or "";

	if(ClipRect~="")then
		local _centerx, _centery, _width, _height = string.match(ClipRect, "([%-%.%d]+),([%-%.%d]+),([%-%.%d]+),([%-%.%d]+)");
		_width = tonumber(_width);
		_height = tonumber(_height);
		_centerx = tonumber(_centerx);
		_centery = tonumber(_centery);

		my_view:clip_rect( _centerx, _centery, _width, _height );
	end

	local ClipCircle = mcmlNode:GetString("ClipCircle") or "";
	if(ClipCircle~="")then
		local _centerx, _centery, _radius  = string.match(ClipCircle, "([%-%.%d]+),([%-%.%d]+),([%-%.%d]+)");
		_radius = tonumber(_radius);
		_centerx = tonumber(_centerx);
		_centery = tonumber(_centery);

		my_view:clip_circle( _centerx, _centery, _radius );
	end	

	my_view:draw(_parent, left, top, right, bottom);
	return true, false, true; -- ignore_onclick, ignore_background, ignore_tooltip;
end

function pe_viewport.UpdatePoints( mcmlNode )

end