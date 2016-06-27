--[[
Title: Image3D Display
Author(s): LiXizhi
Date: 2013/12/23
Desc: Headon 3d image for static models. Characters currently does not support real 3d text. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/Image3DDisplay.lua");
local Image3DDisplay = commonlib.gettable("MyCompany.Aries.Game.Effects.Image3DDisplay");
Image3DDisplay.ShowHeadonDisplay(bShow, obj, image_path, width, height, color, offset, facing)
Image3DDisplay.Reset();
Image3DDisplay.InitHeadOnTemplates(true)
-------------------------------------------------------
]]
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")

local Image3DDisplay = commonlib.gettable("MyCompany.Aries.Game.Effects.Image3DDisplay");

-- head on display UI style, edit it here or change via Image3DDisplay.headon_style
local headon_style = {
	-- some background
	default_bg = "Texture/blocks/cake_top.png",
	-- text color
	text_color = "0 160 0",
	-- whether there is text shadow
	-- use_shadow = true,
	-- any text scaling
	-- scaling = 1.2,
	spacing = 2,
	width = 64,
	height = 64,
}

Image3DDisplay.headon_style = Image3DDisplay.headon_style or headon_style;


-- @param bShow: show or hide the head on display
-- @param obj: must be mesh object. character not supported yet. 
-- @param filename: image filename, if bShow is false, filename can be anything
-- @param offset: nil or a table of {x=0,y=0.3,z=0}. Offset in meters
-- @param index: default to 0;
function Image3DDisplay.ShowHeadonDisplay(bShow, obj, filename, width, height, color, offset, facing, index)
	local o;
	local playerChar;
	
	-- get the object
	if(type(obj) == "userdata") then
		o = obj;
	else
		log("error: obj not userdata value.\n");
		return;
	end
	
	if(o:IsValid()) then
		index = index or 0;
		if(bShow == false or filename == nil or filename == "") then
			o:ShowHeadOnDisplay(false,index);
			return;
		else
			o:ShowHeadOnDisplay(true,index);
		end

		local style = headon_style;
		-- calculate the text width
		o:SetHeadOnUITemplateName(Image3DDisplay.GetTemplateByImageAndSize(filename, width, height),index);

		if(offset) then
			o:SetHeadOnOffset(offset.x or 0, offset.y or 0, offset.z or 0, index);
		end

		-- this line will enable both 3d text display and 3d facing. 
		o:SetField("HeadOn3DFacing", facing or 0);
	end
end

local keynames = {};
local count = 1;
local function ComputeKeyName(filename, width, height)
	local keyname = format("%s%d%d", filename, width, height);
	if(keynames[keyname]) then
		return keynames[keyname];
	else
		count = count + 1;
		keynames[keyname] = "_i3d_"..tostring(count);
		return keynames[keyname];
	end
end

-- call this before world is first loaded to clean up all status.
function Image3DDisplay.Reset()
	keynames = {};
	count = 1;
	local _parent = ParaUI.GetUIObject("headon_templates_cont");
	if(_parent:IsValid()) then
		_parent:RemoveAll();
	end
	Image3DDisplay.InitHeadOnTemplates(true);
end

function Image3DDisplay.GetTemplateByImageAndSize(filename, width, height)
	local _parent = ParaUI.GetUIObject("headon_templates_cont");
	if(_parent:IsValid() and filename) then
		width = width or self.width;
		height = height or self.height;
		local keyname = ComputeKeyName(filename, width, height);
		local _this = _parent:GetChild(keyname);
		if(not _this:IsValid()) then
			filename = filename:gsub("#", ";");
			_this=ParaUI.CreateUIObject("button",keyname, "_lt",-width/2, 0,width,height);
			_this.visible = false;
			_this.background = filename;
			_guihelper.SetUIColor(_this, "#ffffffff");
			_parent:AddChild(_this);
		end
		return keyname;
	else
		return "3DImageDefault";
	end
end

-- create all character head on templates that shall may be used by the game
-- @param bForceReload: true to reload
function Image3DDisplay.InitHeadOnTemplates(bForceReload)
	local style = Image3DDisplay.headon_style;
	local _parent = ParaUI.GetUIObject("headon_templates_cont");
	if(not _parent:IsValid()) then
		_parent = ParaUI.CreateUIObject("container","headon_templates_cont", "_lt",0,0,1,1);
		_parent.visible = false;
		_parent.enabled = false;
		_parent:AttachToRoot();
	end

	-- selected: HOD_Selected_DoubleLine
	if(bForceReload or ParaUI.GetUIObject("3DImageDefault"):IsValid() == false) then
		ParaUI.Destroy("3DImageDefault");
		local _this=ParaUI.CreateUIObject("text","3DImageDefault", "_lt",-style.width/2, 0,style.width,style.height);
		_this.visible = false;
		_this.autosize = false;
		if(style.use_shadow) then
			_this.shadow = style.use_shadow;
		end
		if(style.scaling) then
			_this.scalingx = style.scaling;
			_this.scalingy = style.scaling;
		end
		_this.background = style.default_bg;
		_this:GetFont("text").color = style.text_color;
		_this.spacing = style.spacing;
		_this:GetFont("text").format = 1+16+256; -- center and no clip and word break
		_parent:AddChild(_this);
	end
end	
