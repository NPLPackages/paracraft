--[[
Title: header file for all mcml tag node definitions and data binding controls
Author(s): LiXizhi, WangTian
Date: 2008/2/14
Desc: mcml is an XML format describing profile box items and other display items in paraworld, such as task, quick action, action feed, tradableitem, etc. 
One can think of it as the HTML counterpart in 3D social networking world for describing renderable objects in 2D and 3D. 
it conforms with the ide/LuaXML conversion format, so that the script table defined here has a strict XML translation. 
mcml is a universal format defined by ParaEngine. and any thing in the name space "pe" is official mcml control node that can be data binded to NPL controls. 
mcml_controls for rendering mcml data is defined in mcml/mcml_controls and mcml/pe_* files. 

tag overview: 
	- social tags: pe:profile pe:userinfo pe:friends pe:app pe:name pe:profile-action pe:profile-box pe:app-home-button
	- map tags: pe:map-mark pe:map-mark2d pe:map-tile
	- design tags: pe:container pe:dialog pe:tabs pe:tab-item pe:treeview pe:treenode pe:image pe:flash
	- component tags:pe:roomhost pe:market pe:comments 
	- editor display: pe:editor pe:editor-buttonset pe:editor-button pe:editor-text pe:editor-divider pe:editor-custom pe:editor-radiobox(same as <input type="radio">) pe:editor-checkbox (same as <input type="checkbox">)
		HTML editor tags are implemented by editor: 
		<input type="checkbox" name="option2" value="Butter" checked="true"/> 
		<input type="radio" name="group1" value="Milk"/> 
		<input type="radio" name="group1" value="Butter"/> 
		<select name="select" size="3">
			<option selected="selected">line1</option>
			<option>line2</option>
		</select>
	- control tags: pe:visible-to-owner
	- worlds tags:pe:world pe:world-ip pe:model pe:avatar
	- HTML tags:<text>, h1, h2,h3, h4, li, p, div, hr, a(href), img(attr: src,height, width, title), <form>
			anyTag(attr: style="float:left;color: #006699; left: -60px; position: relative; top: 30px;width: 100px;height: 100px;class:"box";margin:5;margin-top:5;padding:5;background:url;background-color:#FF0000"),
			By default: <text>, font,a(href) will float around previous control, allowing content to automatically wrap to the next line. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/mcml.lua");
-- to create a user defined tag
local node = Map3DSystem.mcml.new("pe:profile", {})
-- to deserialize from xml data or pure table. 
local node = Map3DSystem.mcml.buildclass(node);
-- to render(create) databinding controls for an mcml node. 
Map3DSystem.mcml_controls.create("me", node, bindingContext, _parent, left, top, right, bottom)
-- one can access a node via baseNode functions (see mcml/mcml_base) or using ide/Xpath
-------------------------------------------------------
]]

if(not Map3DSystem.mcml) then Map3DSystem.mcml = {} end

-- base mcml public functions
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/mcml_base.lua");
-- all data binding controls
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/mcml_controls.lua");

local mcml = Map3DSystem.mcml;
--------------------------------------
-- social tags
--------------------------------------
-- the profile mcml root node that specifys a version of the mcml body. 
mcml["pe:profile"] = mcml.new("baseNode", {
	name = "pe:profile", 
	attr = {
		version = "1.0",
		-- user id
		uid = nil,
	}
	-- child nodes: "pe:userinfo", "pe:friends", "pe:app"
});

-- user info 
mcml["pe:userinfo"] = mcml.new("baseNode", {
	name = "pe:userinfo", 
	attr = {
		-- user id
		uid = nil,
		-- user name
		name = nil, 
		-- user photo path or photo id, photo path can be deduced from photo id. 
		photo = nil,
		sex = nil,
		-- user status
		userstatus = nil,
		age = nil,
		signature = nil,
		city = nil,
		nation = nil,
		-- array of friends's userid
		friends = nil,
	}
	-- child nodes: none
});

-- friends user ids
mcml["pe:friends"] = mcml.new("baseNode", {
	name = "pe:friends", 
	attr = {
		-- [string] List of user ids. This is a comma-separated list of user ids.
		uids = nil,
	}
	-- child nodes: none
});

-- application profile box: including both 3d and 2d integration points. 
mcml["pe:app"] = mcml.new("baseNode", {
	name = "pe:app", 
	attr = {
		-- required: application key
		app_key = nil,
		-- the application with a higher version must be installed on the local computer in order to render this application box. 
		-- if this is nil, the application can be rendered even the application is not installed on the local computer. 
		-- it is the app developers' responsibility to ensure that it uses no app specific resources for rendering, when version is nil,
		version = nil, -- "1.0"
	}
	-- child nodes: pe:world, pe:treeview, pe:profile-action, any
});

-- a user name in 2d. Renders the name of the user specified, optionally linked to his or her profile. 
-- You can use this tag for both the subject and the object of a sentence describing an action.
mcml["pe:name"] = mcml.new("baseNode", {
	name = "pe:name", 
	attr = {
		-- required: The ID of the user or Page whose name you want to show. You can also use "loggedinuser" or "profileowner". 
		uid = nil,
		-- following are all optional: 
		-- bool  Show only the user's first name. (default value is false)  
		firstnameonly = false, 
		-- bool:  Link to the user's profile. (default value is true)  
		linked = true,
		-- bool  Use "you" if uid matches the logged in user. (default value is true)  
		useyou = true,
	}
	-- child nodes: none
});

-- Renders a link on the user's profile under their photo (such as "View More photos of.."). 
mcml["pe:profile-action"] = mcml.new("baseNode", {
	name = "pe:profile-action", 
	attr = {
		-- If not nil, it is the URL to which the user is taken after clicking. 
		-- otherwise, the attr of the profile action is passed to the application's do quick action handler.  
		url = nil,
		-- anything that is passed to the application's do quick action handler.  
	}
	-- child nodes: text
});

-- contents in this box are rendered in profile page. 
mcml["pe:profile-box"] = mcml.new("baseNode", {
	name = "pe:profile-box", 
	attr = {
	}
	-- child nodes: any
});

-- clicks to go to the home page of an application
mcml["pe:app-home-button"] = mcml.new("baseNode", {
	name = "pe:app-home-button", 
	attr = {
		app_key = nil,
	}
	-- child nodes: none
});

--------------------------------------
-- map tags
--------------------------------------
mcml["pe:map"] = mcml.new("baseNode",{
	name = "pe:map",
	attr = {
		x = 0.5,
		y = 0.5,
		mode = nil,
		canmove = false,
		zoom = 0,
	}
});


mcml["pe:minimap"] = mcml.new("baseNode",{
	name = "pe:minimap",
	attr = {
	}
});
		

-- map mark on the 3d map layer. 
mcml["pe:map-mark"] = mcml.new("baseNode", {
	name = "pe:map-mark", 
	attr = {
		-- user id
		markid = nil,
	}
	-- child nodes: none
});

-- map mark on the 2d map layer. 
mcml["pe:map-mark2d"] = mcml.new("baseNode", {
	name = "pe:map-mark2d", 
	attr = {
		-- following is the same as Map/SideBar/Map2DMarkInfo.lua
		markID = nil,
		markType = 0,
		-- int, mark model or icon type: see MarkButton.button_style
		markStyle = 1,
		-- text style: see MarkButton.text_style
			bShowText = true,
			textColor = "0 0 0",
			textScale = 1,
			textRot = 0,
		markTitle = "未命名",
		markDesc = "",
		startTime = "",
		endTime = "",
		x = 0,
		y = 0,
		cityName = "",
		rank = 0,
		logo = "",
		signature = "",
		desc = "",
		ageGroup = 0,
		URL = "",
		isApproved = false,
		version = "",
		ownerUserID = "",
		clickCnt = 0,
		worldid = -1,
		allowEdit = false,
		z = 0,
	}
	-- child nodes: none
});

-- a map tile (land) owned by a user
mcml["pe:map-tile"] = mcml.new("baseNode", {
	name = "pe:map-tile", 
	attr = {
		-- tile id
		tileid = nil,
	}
	-- child nodes: none
});

--------------------------------------
-- Sanitization Tags: some content like flash files are sanitized. 
-- Any unknown tags are also not rendered. Please refer to mcml doc for which one is not supported or sanitized. 
--------------------------------------

--------------------------------------
-- Design tags: Design tags help define the look of a page. 
-- While mcml allows developers to render their pages using some standard HTML and CSS, 
-- we offer some custom design tags to utilize special NPL ide controls that help them blend their application into the style of the host app.
--------------------------------------

-- a group of standard tab pages. Must contain at least one pe:tab-item. 
mcml["pe:tabs"] = mcml.new("baseNode", {
	name = "pe:tabs", 
	-- child nodes: pe:tab-item
});

mcml["pe:tab-item"] = mcml.new("baseNode", {
	name = "pe:tab-item", 
	attr = {
		-- Specifies the text to display on the tab
		text = nil,
		-- optional:  [bool]  Indicates whether this tab item has the selected state. (default value is nil)  
		selected  = nil,
	}
	-- child nodes: any
});

-- content inside this node is suggested to be rendered in a treeview control. 
mcml["pe:treeview"] = mcml.new("baseNode", {
	name = "pe:treeview", 
	attr = {
		-- following are the same as ide/treeview
		-- normal window size
		alignment = "_lt",
		left = 0,
		top = 0,
		width = 300,
		height = 300, 
		-- appearance
		-- the background of container
		background = "Texture/3DMapSystem/common/ThemeLightBlue/container_bg.png: 4 4 4 4", 
		-- automatically display vertical scroll bar when content is large
		AutoVerticalScrollBar = true,
		-- offset ScrollBar postion in horizontal
		VerticalScrollBarOffsetX = 0,
		-- Vertical ScrollBar Width
		VerticalScrollBarWidth = 15,
		-- how many pixels to scroll each time
		VerticalScrollBarStep = 3,
		-- how many pixels to scroll when user hit the empty space of the scroll bar. this is usually same as DefaultNodeHeight
		VerticalScrollBarPageSize = 25,
		-- The root tree node. containing all tree node data
		RootNode = nil, 
		-- Default height of Tree Node
		DefaultNodeHeight = 25,
		-- default icon size
		DefaultIconSize = 16,
		-- whether to show icon on the left of each line. 
		ShowIcon = true,
		-- default indentation
		DefaultIndentation = 5,
	}
	-- child nodes: pe:treenode or any (if child node is not pe:treenode, it is always rendered inside an anonymous treenode using the default height)
});

-- content inside this node is suggested to be rendered as a treenode in treeview control. 
-- it may contain other pe:treenode as child or anything else. 
mcml["pe:treenode"] = mcml.new("baseNode", {
	name = "pe:treenode", 
	attr = {
		-- optional: Specifies the text to display on the tree Node
		text = nil,
		-- optional: treenode name
		name = nil,
		-- optional:  icon path. 
		icon  = nil,
		-- optional:  node height. if 0, this node is not rendered, but child nodes are rendered.
		height  = nil,
		-- optional:  indentation in pixel relative to the parent treeview control. if nil, the default is used. 
		indent = nil,
		-- optional:expanded
		expanded = true,
		-- optional:  bool : whether node is invisible. 
		invisible = nil,
	}
	-- child nodes: "pe:treenode", any
});

-- a image control. 
mcml["pe:image"] = mcml.new("baseNode", {
	name = "pe:image", 
	attr = {
		alignment = "_lt",
		left = 0,
		top = 0,
		width = 300,
		height = 300, 
	}
	-- child nodes: none
});

-- an interactive flash control.
mcml["pe:flash"] = mcml.new("baseNode", {
	name = "pe:flash", 
	attr = {
		-- TODO: see ide/flashplayer
	}
	-- child nodes: none
});

--------------------------------------
-- component tags:
-- In addition to design tags, mcml features some tags that provide richer features of the site. Component tags create widget-like components 
-- that allow for user interaction with an application on paraworld. Often these tags provide full ready made items that can be placed into the application. 
-- e.g. pe:roomhost displays a room control that allow users create and join each other's 3d world related to a given app_key. 
-- e.g. pe:comments renders a control that allows visitors to post comments to the dicussion board of an app. 
-- e.g. pe:market renders a control that allows visitors to buy and sell items via an app. 
--------------------------------------
mcml["pe:roomhost"] = mcml.new("baseNode", {
	name = "pe:roomhost", 
	attr = {
		-- optional:if nil, it will search for its parent until a pe:app node is found and use its app_key.
		app_key = nil,
		-- optional:  
		height = nil,
		width = nil,
		-- normal window size
		alignment = "_lt",
		left = 0,
		top = 0,
		-- use max width
		width = nil,
		height = 300, 
	}
	-- child nodes: none
});
mcml["pe:market"] = mcml.new("baseNode", {
	name = "pe:market", 
	attr = {
		-- optional:if nil, it will search for its parent until a pe:app node is found and use its app_key.
		app_key = nil,
		-- optional:  
		height = nil,
		width = nil,
		-- normal window size
		alignment = "_lt",
		left = 0,
		top = 0,
		-- use max width
		width = nil,
		height = 300, 
	}
	-- child nodes: none
});
mcml["pe:comments"] = mcml.new("baseNode", {
	name = "pe:comments", 
	attr = {
		-- optional:if nil, it will search for its parent until a pe:app node is found and use its app_key.
		app_key = nil,
		-- normal window size
		alignment = "_lt",
		left = 0,
		top = 0,
		-- use max width
		width = nil,
		height = 300, 
	}
	-- child nodes: none
});
mcml["pe:dialog"] = mcml.new("baseNode", {
	name = "pe:dialog", 
	attr = {
		--  string of title text or nil. 
		title = nil,
		-- position and size of the client area of the dialog. if x,y is nil, it is displayed at the center of the screen. 
		x = nil,
		y = nil,
		width = 300,
		height = 200, 
		-- int: type of _guihelper.MessageBoxButtons: OKCancel = 3,YesNo = 5, YesNoCancel = 6,
		buttons = nil,
		-- function (dialogResult) end or the function name string. 
		onclick = nil,
	}
	-- child nodes: none
});

------------------
-- editor display component tags
------------------
-- Creates a form with two columns, just like the form on the edit-profile page. The children of pe:editor specify the 
-- rows of the form. For example, an pe:editor-text child adds a row with a text field in the right column. 
-- The label attribute of the pe:editor-* child specifies what text appears in the left column of that row. 
mcml["pe:editor"] = mcml.new("baseNode", {
	name = "pe:editor", 
	attr = {
		-- required:   string: if it begins with http, it is the URL to which the form's data is posted.
		-- otherwise, it is forwarded to the doaction handler of its container app. 
		action = nil,
		-- int:  The width of the first column of the form/table, in pixels. (default value is 75). Note: This value cannot be 0 as it is ignored; use 1 instead.  
		labelwidth = 75,
		-- normal window size
		alignment = "_lt",
		left = 0,
		top = 0,
		-- The width of the form/table, in pixels. (profile default value is 425) 
		width = nil,
		height = nil, 
	}
	-- child nodes: pe:editor-buttonset, pe:editor-button, pe:editor-text, editor-divider, 
	-- pe:treenode(allows you to put any content into an pe:editor block), 
});

-- A container for one or more fb:editor-button tags, which are rendered next to each other with some space between each button. 
mcml["pe:editor-buttonset"] = mcml.new("baseNode", {
	name = "pe:editor-buttonset", 
	-- child nodes: pe:editor-button
});

-- Renders a button of type submit inside an fb:editor tag. 
-- This tag can be a child of an fb:editor-buttonset container to render multiple buttons next to each other. 
mcml["pe:editor-button"] = mcml.new("baseNode", {
	name = "pe:editor-button", 
	attr = {
		-- required:  string  The text label for the button.  
		text = nil,
		-- optional: string  The variable name that is sent in the POST request when the form is submitted.  
		name = "unamed_button",
		-- @param onclick: the onclick script name or an URL to receive result using HTTP post. 
		--  if it is a script name, the script will be called with onclick(btnName, values, bindingContext), 
		--	where btnName is name of button that is clicked and values is nil or a table collecting all name value pairs. 
		onclick = nil,
	}
	-- child nodes: none
});

-- an input edit box. it can be multiline
mcml["pe:editor-text"] = mcml.new("baseNode", {
	name = "pe:editor-text", 
	attr = {
		-- optional string  The label to display on the left side of the text box.  
		label = nil,
		-- The default text that populates the edit box. 
		text = nil,
		-- optional: string  The variable name that is sent in the POST request when the form is submitted.  
		name = "unamed_editbox",
		-- int  The maximum length of the input allowed in the edit box. 
		maxlength = 255,
		-- int  The height of the text area in number of lines of text. Default is 1 for single lined edit box. 
		rows = 1,
	}
	-- child nodes: none
});

-- Allows you to put any content into an pe:editor block, as long as it is valid mcml.
mcml["pe:editor-custom"] = mcml.new("baseNode", {
	name = "pe:editor-custom", 
	attr = {
		-- optional string  The label to display on the left side of the text box.  
		label = nil,
		-- the height of this custom node. 
		height = 26,
	}
	-- child nodes: any
});
-- Renders a horizontal line separator in the column containing the form elements.
mcml["pe:editor-divider"] = mcml.new("baseNode", {
	name = "pe:editor-divider", 
	-- child nodes: none
});

--------------------------------------
-- HTML tags: 
--------------------------------------
-- selection box: either list box or combo box (drop down list box)
mcml["select"] = mcml.new("baseNode", {
	name = "select", 
	attr = {
		-- if 1 it is combo box, if greater than 1, it is a listbox. 
		size = 1,
	}
	-- child nodes: <option>line_text</option>
});

--------------------------------------
-- control tags: 
-- The most useful of these are the visible-to-XXX tags, such as fb:visible-to-owner.
--------------------------------------
-- Displays content inside only if the viewer of the profile matches the profile owner. 
-- Note: Do not use this tag to display private or sensitive information. Content inside this tag is rendered to all users' browsers, including those who are not the profile owner. For those who are not the owner, the content is shown as white space on the page but it is still visible by viewing the page source. 
mcml["pe:visible-to-owner"] = mcml.new("baseNode", {
	name = "pe:visible-to-owner", 
	-- child nodes: any
});

--------------------------------------
-- worlds tags: 
--------------------------------------
-- a user created virtual world 
mcml["pe:world"] = mcml.new("baseNode", {
	name = "pe:worldip", 
	attr = {
		-- the unique world id
		worldid = nil,
	}
	-- child nodes: none
});

-- world integration point: the parent node for all 3D world objects in the in-game world integration point. 
mcml["pe:worldip"] = mcml.new("baseNode", {
	name = "pe:worldip", 
	attr = {
		-- optional:if nil, it will search for its parent until a pe:app node is found and use its app_key.
		app_key = nil,
		-- icon to be shown on the mini-map. if nil, the app's icon is used. 
		icon = nil,
		-- tooltip text to be displayed on the mini-map.
		text = nil,
	}
	-- child nodes: "pe:model", "pe:avatar"
});

-- a 3D model or character specified using relative positioning in pe:world integration point. 
mcml["pe:model"] = mcml.new("baseNode", {
	name = "pe:model", 
	attr = {
		-- following has the same definition as the obj_params table in ide/object_editor
		name,
		AssetFile, -- primary asset file: either string or para asset object.
		x,
		y,
		z,
		IsCharacter, -- can be nil
		scaling,	-- can be nil
		rotation,   -- can be nil or {x=0,y=0,z=0,w=1} which is rotational quaternion.
		facing,  -- can be nil
		IsGlobal,	-- can be nil
		ViewBox, -- can be nil
		Density,	-- can be nil
		PhysicsRadius, -- can be nil
		
		IsPersistent, -- can be nil
		ReplaceableTextures, -- = {[1] = "filepath"}, -- can be nil
		SkinIndex,  -- can be nil
		localMatrix, -- can be nil
		EnablePhysics, -- can be nil, whether physics is enabled for the mesh
		
		-- TODO: Customizable character properties here?
		-- TODO: dynamic properties?
	}
	-- child nodes: none
});

-- a 3D character avatar of a given user. One only needs to specify userid to render it properly
mcml["pe:avatar"] = mcml.new("baseNode", {
	name = "pe:avatar", 
	
	attr = {
		-- the user ID whose avatar this belongs. all following attributes can be nil. 
		-- If following attributes are provided, they will override default avatar settings of the given userid
		userid = nil,
		
		-- following has the same definition as the obj_params table in ide/object_editor
		name,
		AssetFile, -- primary asset file: either string or para asset object.
		x,
		y,
		z,
		IsCharacter, -- can be nil
		scaling,	-- can be nil
		rotation,   -- can be nil or {x=0,y=0,z=0,w=1} which is rotational quaternion.
		facing,  -- can be nil
		IsGlobal,	-- can be nil
		ViewBox, -- can be nil
		Density,	-- can be nil
		PhysicsRadius, -- can be nil
		
		IsPersistent, -- can be nil
		ReplaceableTextures, -- = {[1] = "filepath"}, -- can be nil
		SkinIndex,  -- can be nil
		localMatrix, -- can be nil
		EnablePhysics, -- can be nil, whether physics is enabled for the mesh
		-- TODO: Customizable character properties here?
		-- TODO: dynamic properties?
	}
	-- child nodes: none
});