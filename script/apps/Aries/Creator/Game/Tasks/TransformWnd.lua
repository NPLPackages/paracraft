--[[
Title: A simple 3d transform window
Author(s): LiXizhi
Date: 2013/8/24
Desc: block transform window
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TransformWnd.lua");
local TransformWnd = commonlib.gettable("MyCompany.Aries.Game.Tasks.TransformWnd");
TransformWnd.ShowPage({x=10, y=0, z=10, facing=90}, function(trans)
	_guihelper.MessageBox(trans)
end)
-------------------------------------------------------
]]
local TransformWnd = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Tasks.TransformWnd"));

local groupindex_hint = 6; 

------------------------
-- page function 
------------------------
local page;

local transform = {};
local old_transform = {};
-- @param trans: {x, y, z, rot_y, blocks, method}
-- @param callbackFunc: function(trans, result) end, where result is "ok" if user clicked ok. 
function TransformWnd.ShowPage(blocks, trans, callbackFunc)
	TransformWnd:InitSingleton();
	if(page) then
		page:CloseWindow();
	end
	TransformWnd.callbackFunc = callbackFunc;
	
	TransformWnd.result = nil;
	TransformWnd.blocks = blocks;
	transform = trans or {};

	old_transform = commonlib.clone(trans);
	
	local x, y, width, height = 124, 160, 110, 235;
	local align = "_lt";
	
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/TransformWnd.html", 
			name = "TransformWnd.ShowPage", 
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			isShowTitleBar = false, 
			DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
			style = CommonCtrl.WindowFrame.ContainerStyle,
			zorder = 10,
			allowDrag = true,
			-- click_through = false,
			directPosition = true,
				align = align,
				x = x,
				y = y,
				width = width,
				height = height,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	params._page.OnClose = function()
		ParaTerrain.DeselectAllBlock(groupindex_hint);
		if(TransformWnd.callbackFunc) then
			TransformWnd.callbackFunc(transform, TransformWnd.result);
		end
		page = nil;
	end
	TransformWnd.UpdateHintLocation();
end

function TransformWnd:IsVisible()
	return page ~= nil;
end

function TransformWnd.GetNumberValue(name, default_value)
	value = page:GetValue(name, 1);
	return tonumber(value) or default_value or 0;
end

function TransformWnd.SetNumberValue(name, value)
	if(page) then
		page:SetValue(name, tostring(value));
	end
end


function TransformWnd.ChangeCoordinate(name,mcmlNode)
	local value;
	if(name == "btn_sub_x" or name == "btn_add_x") then
		value = TransformWnd.GetNumberValue("text_pos_x", 0);
		if(name == "btn_add_x") then
			value = value + 1;
		elseif(name == "btn_sub_x") then
			value = value - 1;
		end
		page:SetValue("text_pos_x",value);
		TransformWnd.UpdateHintLocation();
	elseif(name == "btn_sub_y" or name == "btn_add_y") then
		value = TransformWnd.GetNumberValue("text_pos_y", 0);
		if(name == "btn_add_y") then
			value = value + 1;
		elseif(name == "btn_sub_y") then
			value = value - 1;
		end
		page:SetValue("text_pos_y",value);
		TransformWnd.UpdateHintLocation();
	elseif(name == "btn_sub_z" or name == "btn_add_z") then
		value = TransformWnd.GetNumberValue("text_pos_z", 0);
		if(name == "btn_add_z") then
			value = value + 1;
		elseif(name == "btn_sub_z") then
			value = value - 1;
		end
		page:SetValue("text_pos_z",value);
		TransformWnd.UpdateHintLocation();
	elseif(name == "btn_sub_scaling" or name == "btn_add_scaling") then
		if(name == "btn_add_scaling") then
			value = "2,2,2";
		elseif(name == "btn_sub_scaling") then
			value = "0.5,0.5,0.5";
		end
		page:SetValue("text_scaling",value);
	end
end

function TransformWnd.ClosePage()
	if(page) then
		page:CloseWindow();
	end
end

function TransformWnd.GetTransformedPoint(src_x, src_y, src_z, dx, dy, dz)
	return src_x+dx, src_y+dy,src_z+dz;
end

-- public function
function TransformWnd.UpdateHintLocation(blocks, dx,dy,dz)
	ParaTerrain.DeselectAllBlock(groupindex_hint);

	blocks = blocks or TransformWnd.blocks;
	if(blocks) then
		if(dx) then
			TransformWnd.SetNumberValue("text_pos_x", dx);
			TransformWnd.SetNumberValue("text_pos_y", dy);
			TransformWnd.SetNumberValue("text_pos_z", dz);
		else
			transform.x = TransformWnd.GetNumberValue("text_pos_x", 0);
			transform.y = TransformWnd.GetNumberValue("text_pos_y", 0);
			transform.z = TransformWnd.GetNumberValue("text_pos_z", 0);
			dx, dy, dz = transform.x, transform.y, transform.z;
		end

		if(dx~=0 or dy~=0 or dz~=0) then
			local GetTransformedPoint = TransformWnd.GetTransformedPoint;
			for i = 1, #blocks do
				local b = blocks[i];
				local x,y,z = GetTransformedPoint(b[1], b[2], b[3], dx, dy, dz);
				ParaTerrain.SelectBlock(x,y,z, true, groupindex_hint);
			end
		end
	end
end

function TransformWnd.OnUIValueChanged()
	TransformWnd.UpdateHintLocation();
end

function TransformWnd.TransformSelection()
	transform.x = TransformWnd.GetNumberValue("text_pos_x", 0);
	transform.y = TransformWnd.GetNumberValue("text_pos_y", 0);
	transform.z = TransformWnd.GetNumberValue("text_pos_z", 0);
	transform.method = page:GetUIValue("method");
	local scaling = page:GetValue("text_scaling", "1,1,1");
	if(scaling) then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CmdParser.lua");
		local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");
		local scalings = CmdParser.ParseNumberList(scaling);
		if(scalings and #scalings>=1) then
			transform.scalingX, transform.scalingY, transform.scalingZ = scalings[1], scalings[2] or scalings[1], scalings[3] or scalings[1];
		end
	end
	if((transform.x~=0 or transform.y~=0 or transform.z~=0) or 
		(transform.scalingX~=1 or transform.scalingY~=1 or transform.scalingZ~=1) ) then

		TransformWnd.result = "ok";
		if(page) then
			page:CloseWindow();
		end
	end
end

function TransformWnd.OnClickReset()
	transform = commonlib.clone(old_transform);
	if(page) then
		page:Refresh(0.01);
	end
end

function TransformWnd.OnInit()
	page = document:GetPageCtrl();
	
	page:SetValue("text_pos_x", transform.x or 0);
	page:SetValue("text_pos_y", transform.y or 0);
	page:SetValue("text_pos_z", transform.z or 0);
	page:SetValue("facing", transform.facing or 0);
	page:SetValue("method", if_else(not transform.method or transform.method=="move" or transform.method == "no_clone", "no_clone", "clone"));
end

function TransformWnd:Translate(dx, dy, dz)
	if(page) then
		local x = TransformWnd.GetNumberValue("text_pos_x", 0) + dx;
		local y = TransformWnd.GetNumberValue("text_pos_y", 0) + dy;
		local z = TransformWnd.GetNumberValue("text_pos_z", 0) + dz;
		TransformWnd.SetNumberValue("text_pos_x", x);
		TransformWnd.SetNumberValue("text_pos_y", y);
		TransformWnd.SetNumberValue("text_pos_z", z);
		TransformWnd.UpdateHintLocation();
	end
end


