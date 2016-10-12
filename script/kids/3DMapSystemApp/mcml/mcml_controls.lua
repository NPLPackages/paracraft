--[[
Title: all officially bindable controls that renders mcml nodes (only for 2D UI controls). 
Author(s): LiXizhi, WangTian
Date: 2008/2/15
Desc: all control implementations are in the mcml/pe_* files. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/mcml_controls.lua");
Map3DSystem.mcml_controls.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height)
-------------------------------------------------------
]]

local mcml_controls = commonlib.gettable("Map3DSystem.mcml_controls");

NPL.load("(gl)script/kids/3DMapSystemApp/mcml/mcml_controls_layout.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/default_css.lua");

NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_social.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_design.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_editor.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_component.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_html.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_html_input.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_script.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_user.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_profile.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_item.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_avatar.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_map.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_motion.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_storyboard.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_gridview.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_treeview.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_stackview.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_datasource.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_ribbon.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_asset.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_bag.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_dialog.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_template.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_hotkey.lua");
--NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_aries.lua");
--NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_aries2.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_flash.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_textsprite.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/aries_camera.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/aries_camera_2.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_fileloader.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_powerpoint.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_viewport.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_downlistbutton.lua");

NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_minikeyboard.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_togglebuttons.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_style.lua");
local L = CommonCtrl.Locale("IDE");

-- the null node
local pe_none = commonlib.gettable("Map3DSystem.mcml_controls.pe_none");
pe_none.create = function() end;

-- default control mapping: from tag name to rendering controls
local default_control_mapping = {
	-- global
	["pe:mcml"] = mcml_controls.pe_simple_styles,
	
	-- textsprite tags
	["pe:textsprite"] = mcml_controls.pe_textsprite,
	["pe:minikeyboard"] = mcml_controls.pe_minikeyboard,
	
	-- social tags
	["pe:profile"] = mcml_controls.pe_profile,
	["pe:profile-mini"] = mcml_controls.pe_profile_mini,
	["pe:profile-photo"] = mcml_controls.pe_profile_photo,
	["pe:friends"] = mcml_controls.pe_friends,
	["pe:app"] = mcml_controls.pe_app,
	["pe:name"] = mcml_controls.pe_name,
	["pe:avatar"] = mcml_controls.pe_avatar,
	["pe:quickaction"] = mcml_controls.pe_quickaction,
	["pe:onlinestatus"] = mcml_controls.pe_onlinestatus,
	
	["pe:player"] = mcml_controls.pe_player,
	
	-- item tags
	["pe:item"] = mcml_controls.pe_item,
	["pe:slot"] = mcml_controls.pe_slot,
	["pe:item-shortcut"] = mcml_controls.pe_item_shortcut,
	
	-- dialog tags
	["pe:dialog"] = mcml_controls.pe_dialog,
	["pe:state"] = mcml_controls.pe_state,
	["pe:answer"] = mcml_controls.pe_answer,
	["pe:answer-if"] = mcml_controls.pe_answer_if,
	
	-- template tags
	["pe:template"] = mcml_controls.pe_template,
	["pe:template-block"] = mcml_controls.pe_template_block,
	["pe:placeholder"] = mcml_controls.pe_placeholder,

	-- component tags
	["pe:download"] = mcml_controls.pe_download,
	["ready"] = mcml_controls.pe_simple_styles,
	["notready"] = mcml_controls.pe_simple_styles,
	["pe:custom"] = mcml_controls.pe_custom,
	["pe:world"] = mcml_controls.pe_world,
	
	-- control tags
	["pe:if-is-user"] = mcml_controls.pe_if_is_user,
	["pe:if"] = mcml_controls.pe_if,
	["pe:if-not"] = mcml_controls.if_not,
	["pe:if-is-friends-with-viewer"] = mcml_controls.pe_if_is_friends_with_viewer,
	["pe:else"] = mcml_controls.pe_else,
	["pe:repeat"] = mcml_controls.pe_repeat,
	
	-- map tags
	["pe:map"] = mcml_controls.pe_map,
	["pe:mark"] = mcml_controls.pe_none,
	["pe:map-anchor"] = mcml_controls.pe_none,

	["pe:downlistbutton"] = mcml_controls.pe_downlistbutton,


	["pe:tile"] = mcml_controls.pe_land,
	["pe:mapmark"] = mcml_controls.pe_mapmark,
	["pe:minimap"] = mcml_controls.pe_minimap,
	["pe:viewport"] = mcml_controls.pe_viewport,
	
	-- design tags
	["pe:treeview"] = mcml_controls.pe_treeview,
	["pe:treenode"] = mcml_controls.pe_treenode,
	["pe:tabs"] = mcml_controls.pe_tabs,
	["pe:tab-item"] = mcml_controls.pe_tab_item,
	["pe:image"] = mcml_controls.pe_image,
	["pe:flash"] = mcml_controls.pe_flash,
	["pe:container"] = mcml_controls.pe_editor,
	["pe:slide"] = mcml_controls.pe_slide,
	["pe:filebrowser"] = mcml_controls.pe_filebrowser,
	["pe:canvas3d"] = mcml_controls.pe_canvas3d,
	["pe:canvas3dui"] = mcml_controls.pe_canvas3dui,
	["pe:label"] = mcml_controls.pe_label,
	["pe:fileupload"] = mcml_controls.pe_fileupload,
	["pe:GridView"] = mcml_controls.pe_gridview,
	["pe:gridview"] = mcml_controls.pe_gridview,
	["pe:stackview"] = mcml_controls.pe_stackview,
	["pe:pager"] = mcml_controls.pe_pager,
	["pe:bindingblock"] = mcml_controls.pe_bindingblock,
	["pe:xmldatasource"] = mcml_controls.pe_xmldatasource,
	["pe:mqldatasource"] = mcml_controls.pe_mqldatasource,
	["pe:progressbar"] = mcml_controls.pe_progressbar,
	["pe:sliderbar"] = mcml_controls.pe_sliderbar,
	["pe:numericupdown"] = mcml_controls.pe_numericupdown,
	["pe:colorpicker"] = mcml_controls.pe_colorpicker,
	["pe:ribbonbar"] = mcml_controls.pe_ribbonbar,
	["pe:command"] = mcml_controls.pe_command,
	["pe:asset"] = mcml_controls.pe_asset,
	["pe:bag"] = mcml_controls.pe_bag,
	["pe:flash"] = mcml_controls.pe_flash,
	["pe:preloader"] = mcml_controls.pe_preloader,
	["pe:fileloader"] = mcml_controls.pe_fileloader,
	["pe:powerpoint"] = mcml_controls.pe_powerpoint,
	["pe:maskarea"] = mcml_controls.pe_maskarea,
	["pe:webbrowser"] = mcml_controls.pe_webbrowser,
	["pe:hotkey"] = mcml_controls.pe_hotkey,
	
	-- motion tags
	["pe:animgroup"] = mcml_controls.pe_animgroup,
	["pe:animlayer"] = mcml_controls.pe_animlayer,
	["pe:animator"] = mcml_controls.pe_animator,
	
	-- storyboard tags	
	["pe:storyboards"] = mcml_controls.pe_storyboards,
		["pe:storyboard"] = mcml_controls.pe_storyboard,
			["pe:doubleAnimationUsingKeyFrames"] = mcml_controls.pe_doubleAnimationUsingKeyFrames,
				["pe:linearDoubleKeyFrame"] = mcml_controls.pe_linearDoubleKeyFrame,
				["pe:discreteDoubleKeyFrame"] = mcml_controls.pe_discreteDoubleKeyFrame,
			["pe:stringAnimationUsingKeyFrames"] = mcml_controls.pe_stringAnimationUsingKeyFrames,
				["pe:discreteStringKeyFrame"] = mcml_controls.pe_discreteStringKeyFrame,
			["pe:point3DAnimationUsingKeyFrames"] = mcml_controls.pe_point3DAnimationUsingKeyFrames,
				["pe:linearPoint3DKeyFrame"] = mcml_controls.pe_linearPoint3DKeyFrame,
				["pe:discretePoint3DKeyFrame"] = mcml_controls.pe_discretePoint3DKeyFrame,
			["pe:objectAnimationUsingKeyFrames"] = mcml_controls.pe_objectAnimationUsingKeyFrames,
				["pe:discreteObjectKeyFrame"] = mcml_controls.pe_discreteObjectKeyFrame,
			
			
	
	-- editor tags
	["pe:dialog"] = mcml_controls.pe_dialog,
	["pe:editor"] = mcml_controls.pe_editor,
	["pe:editor-button"] = mcml_controls.pe_editor_button,
	["pe:editor-buttonset"] = mcml_controls.pe_editor_buttonset,
	["pe:editor-text"] = mcml_controls.pe_editor_text,
	["pe:editor-divider"] = mcml_controls.pe_editor_divider,
	["pe:editor-custom"] = mcml_controls.pe_editor_custom,
	["pe:editor-radiobox"] = mcml_controls.pe_editor_radiobox,
	["pe:editor-checkbox"] = mcml_controls.pe_editor_checkbox,
	["pe:editor-hidden"] = mcml_controls.pe_editor_hidden,
	
	-- supported html tags
	["<text>"] = mcml_controls.pe_text, -- there is no node called <text>, but all inner xml text is mapped to this one. 
	["h1"] = mcml_controls.pe_simple_styles,
	["h2"] = mcml_controls.pe_simple_styles,
	["h3"] = mcml_controls.pe_simple_styles,
	["h4"] = mcml_controls.pe_simple_styles,
	["ul"] = mcml_controls.pe_simple_styles,
	["li"] = mcml_controls.pe_simple_styles,
	["p"] = mcml_controls.pe_simple_styles,
	["div"] = mcml_controls.pe_simple_styles,
	["a"] = mcml_controls.pe_a,
	["span"] = mcml_controls.pe_span,
	["font"] = mcml_controls.pe_font,
	["strong"] = mcml_controls.pe_font,
	["b"] = mcml_controls.pe_font,
	["br"] = mcml_controls.pe_br,
	["hr"] = mcml_controls.pe_editor_divider,
	["img"] = mcml_controls.pe_img,
	["form"] = mcml_controls.pe_form,
	["input"] = mcml_controls.pe_input,
	["textarea"] = mcml_controls.pe_editor_text,
	["select"] = mcml_controls.pe_select,
	["button"] = mcml_controls.pe_editor_button,
	["iframe"] = mcml_controls.pe_iframe,
	["script"] = mcml_controls.pe_script,
	["style"] = mcml_controls.pe_style,
	["unknown"] = mcml_controls.pe_script, -- this will handle <%embeded code block%>
	["label"] = mcml_controls.pe_label,
	["pe:togglebuttons"] = mcml_controls.pe_togglebuttons,
	
	["pe:div"] = mcml_controls.pe_editor,
	["pe:button"] = mcml_controls.pe_editor_button,
	["pe:block"] = mcml_controls.pe_editor,

	-- HTML extension
	["pe:a"] = mcml_controls.pe_pe_a,
	["pe:script"] = mcml_controls.pe_script,
	["pe:code"] = mcml_controls.pe_code,
	["pe:style"] = mcml_controls.pe_style,
	
	-- the following aries tags are moved to apps folder and use RegisterUserControl() function. 
	-- aries tags
	--["aries:mountpetname"] = mcml_controls.aries_mountpetname,
	--["aries:userinfo"] = mcml_controls.aries_userinfo,
	--["aries:textsprite"] = mcml_controls.aries_textsprite,
	--["aries:mountpet"] = mcml_controls.aries_mountpet,
	--["aries:followpet"] = mcml_controls.aries_followpet,
	--["aries:mountpet-health"] = mcml_controls.aries_mountpet_health,
	--["aries:mountpet-level"] = mcml_controls.aries_mountpet_level,
	--["aries:mountpet-status"] = mcml_controls.aries_mountpet_status,
	--["aries:mountpet-status2"] = mcml_controls.aries_mountpet_status2,
	--
	---- aries2 tags
	--["aries:onlinestatus"] = mcml_controls.aries_onlinestatus,
	--["aries:miniscenecameramodifier"] = mcml_controls.aries_miniscenecameramodifier,
	--["aries:questobjectivestatus"] = mcml_controls.aries_questobjectivestatus,

	--v1
	["camera"] = mcml_controls.aries_camera,
	["camera_empty"] = mcml_controls.aries_camera_empty,
	["camera_point"] = mcml_controls.aries_camera_point,
	["camera_track"] = mcml_controls.aries_camera_track,
	["camera_dynamic"] = mcml_controls.aries_camera_dynamic,
	["camera_caster"] = mcml_controls.aries_camera_caster,
	["camera_follow"] = mcml_controls.aries_camera_follow,
	["camera_target"] = mcml_controls.aries_camera_target,
	["camera_ground"] = mcml_controls.aries_camera_ground,
	["camera_abcenter"] = mcml_controls.aries_camera_abcenter,
	["camera_abgcenter"] = mcml_controls.aries_camera_abgcenter,
	["camera_agcenter"] = mcml_controls.aries_camera_agcenter,
	["camera_bgcenter"] = mcml_controls.aries_camera_bgcenter,

	--v2
	["camera_v2"] = mcml_controls.aries_camera_2,
	["camera_empty_v2"] = mcml_controls.aries_camera_2_empty,
	--·ÏÆú["camera_point"]
	["camera_track_v2"] = mcml_controls.aries_camera_2_track,
	["camera_dynamic_v2"] = mcml_controls.aries_camera_2_dynamic,
	["camera_caster_v2"] = mcml_controls.aries_camera_2_caster,
	["camera_follow_v2"] = mcml_controls.aries_camera_2_follow,
	["camera_target_v2"] = mcml_controls.aries_camera_2_target,
	["camera_ground_v2"] = mcml_controls.aries_camera_2_ground,
	["camera_abcenter_v2"] = mcml_controls.aries_camera_2_abcenter,
	["camera_abgcenter_v2"] = mcml_controls.aries_camera_2_abgcenter,
	["camera_agcenter_v2"] = mcml_controls.aries_camera_2_agcenter,
	["camera_bgcenter_v2"] = mcml_controls.aries_camera_2_bgcenter,
};
local control_mapping = commonlib.gettable("Map3DSystem.mcml_controls.control_mapping");
commonlib.partialcopy(control_mapping, default_control_mapping);

-- register a given mcml tag with a custom user control.
-- @param tag_name: the mcml tag name, such as "pe:my_user_control"
-- @param tag_class: the tag class table used to create the control at runtime. At minimum it should be a table containing a create() function
--   i.e. {create = function(rootName,mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)  end, }
--   please see the rich number existing tag classes for examples. 
function mcml_controls.RegisterUserControl(tag_name, tag_class)
	control_mapping[tag_name] = tag_class;
end

-- unregister a tag
function mcml_controls.UnRegisterUserControl(tag_name)
	control_mapping[tag_name] = nil;
end

-- get tag names
function mcml_controls.GetClassByTagName(tag_name) 
	return control_mapping[tag_name] or default_control_mapping[tag_name]
end

-- automatically create the appropriate controls that renders the mcmlNode. Controls are child of _parent, and use automatic databinding. 
-- this function is recursive. See default control mapping for which control a specifc mcmlNode is mapped to. 
-- If one wants to manually choose which control an mcmlNode should be bound to, he can call any of the create function of that specific control. 
-- @param rootName: a name that uniquely identifies this UI instance, usually the userid or app_key. The renderer will create sub control names by concartinating this rootname with relative baseNode path. 
-- @param mcmlNode: any supported mcml node defined in mcml/mcml. 
-- @param bindingContext: the bindingContext object to use. If nil, it is automatically used. 
-- @param _parent: the parent paraUIObject inside which controls are rendered. 
-- @param left, top: the next free renderable cursor position from which following controls should be appended. The idea is similar to HTML renderer. 
-- @param width, height: desired width and height of the _parent (or desired right, bottom position of the control in parent). they can be nil, and result is dependent on controls. 
-- @param style: nil or a table containing css style, such as {color=string, href=string}. This is a style object to be associated with each node.
-- @param parentLayout: optional in|out: type of mcml_controls.layout
function mcml_controls.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	if(not parentLayout) then
		parentLayout = mcml_controls.layout:new();
		parentLayout:reset(left, top, width, height);
	end
	if(mcmlNode == nil) then 
		return	
	elseif(type(mcmlNode) == "string")	then
		-- for inner text of xml
		return control_mapping["<text>"].create(rootName,mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
	end
	
	--
	-- control tags
	--
	if(mcmlNode.name == "pe:visible-to-owner") then
		-- pe:visible-to-owner
		if(mcmlNode:GetOwnerUserID() ~= Map3DSystem.App.profiles.ProfileManager.GetUserID()) then
			return;
		end
	end
	local ctl = control_mapping[mcmlNode.name];
	if (ctl and ctl.create) then
		-- if there is a known control_mapping, use it and return
		return ctl.create(rootName,mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);
	else
		-- if no control mapping found, create each child node. 
		for childnode in mcmlNode:next() do
			local left, top, width, height = parentLayout:GetPreferredRect();
			mcml_controls.create(rootName,childnode, bindingContext, _parent, left, top, width, height, style, parentLayout)
		end
	end
end

---------------------------------------------
-- event handler helper functions
---------------------------------------------

-- use clicks to open an href URL. 
-- @param href: the url to open. 
function mcml_controls.OnClickHRef(href)
	if(href) then
		if(string.match(href,"^open://")) then
			-- open// file or folder. 
			local filepath = string.match(href,"^open://(.*)$")
			local rootDir = ParaIO.GetCurDirectory(0);
			local absPath;
			if(not string.match(filepath, rootDir)) then
				-- append root
				absPath = rootDir..filepath;
			else
				absPath = filepath;
			end
			absPath = string.gsub(absPath, "/", "\\");
			
			_guihelper.MessageBox(string.format(L"Are you sure that you want to open %s using external browser?", filepath), function()
				ParaGlobal.ShellExecute("open", "explorer.exe", absPath, "", 1); 
			end);	
		else
			Map3DSystem.App.Commands.Call("File.WebBrowser", href);
		end	
	end	
end

-- call this when a pe:editor-button is clicked. 
-- @param mcmlNode: mcmlNode that is firing this event. Please note that, if this is nil, the DOM (document object) will not be valid within the callback script.
-- @param callbackFunc: the call back script function name or function itself.
--  the script function will be called with function(param1, param2, param3,...)
-- @param param1: param1 is usually the btnName
-- @param param2: param2 is usually values from the calling control.
-- @param param3: param3 is usually the binding context object
-- @return function result or nil. 
function mcml_controls.OnPageEvent(mcmlNode, callbackFunc, ...)
	local pageEnv, result;
	if(mcmlNode) then
		-- get the page env table where the inline script function is defined, it may be nil if there is no page control or there is no inline script function. 
		local pageCtrl = mcmlNode:GetPageCtrl();
		if(pageCtrl) then
			pageEnv = pageCtrl._PAGESCRIPT
		end
		
		mcml_controls.pe_script.BeginCode(mcmlNode);
	end
	if(type(callbackFunc) == "string") then
		if(string.find(callbackFunc, "http://")) then
			-- TODO: post values using http post. 
		else
			-- first search function in page script environment and then search in global environment. 
			local pFunc;
			if(pageEnv) then
				pFunc = commonlib.getfield(callbackFunc, pageEnv);
			end
			if(type(pFunc) ~= "function") then
				pFunc = commonlib.getfield(callbackFunc);
			end	
			if(type(pFunc) == "function") then
				result = pFunc(...);
			else
				log("warning: MCML page event call back "..callbackFunc.." is not a valid function. \n")	
			end
		end	
	elseif(type(callbackFunc) == "function") then
		result = pFunc(...);
	end
	if(mcmlNode) then
		mcml_controls.pe_script.EndCode();
	end
	return result;
end
