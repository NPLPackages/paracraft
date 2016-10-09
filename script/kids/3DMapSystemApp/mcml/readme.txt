--[[
Title: read me file for MCML
Author(s): LiXizhi
Date: 2008/3/4
Desc: developer guide for MCML
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/MCML/readme.lua");
MakeWikiFile("script/kids/3DMapSystemApp/MCML/readme.lua");
-------------------------------------------------------
]]

--[[
%T% *Do not edit this page*. It is automatically generated from "script/kids/3DMapSystemApp/MCML/readme.lua", so edit the source file instead. 

%STARTINCLUDE%
---++ What is <nop>MCML?
MCML is an XML format describing profile and other display items in ParaWorld, such as task, quick action, action feed, tradableitem, etc. 
One can think of it as the HTML counterpart in 3D social networking world for describing renderable objects in both 2D and 3D. 
MCML is a universal format defined by ParaEngine and used by ParaWorld. Any tags in the name space "pe" is official mcml control node that can be data binded to NPL controls. 

---++ <nop>MCML tags
__The following is a list of all supported tags in MCML__

<table border="0" width="100%"><tbody><tr><td valign="top" width="33%">
---+++ Release Notes
   * [[MCMLIntro][MCML Introduction]] 
   * [[MCMLProposals][Submit MCML proposals]] 
   * [[ParaEngineLicense][ParaEngine/NPL License]] 

---+++ [[pe_html][HTML tags]]
<verbatim>
_text_, h1, h2,h3, h4, li, p, div, 
hr,font,span,strong,a(href),form
img(attr: src,height, width, title)

anyTag(attr: style="float:left;
color:#006699; text-align: right;
background:url;background-color:#FF0000";
font-family:Arial;font-size:14pt;
font-weight:bold;left: -60px; 
position: relative|absolute;top:30px;
width:100px;height:100px;class:"box";
margin:5;margin-top:5;padding:5;),

<input type="text|radio|checkbox|file|
submit|button|hidden|reset|password" 
name="", value=""/>
</verbatim>
More info, see [[HTMLTags]]

---+++ [[pe_design][Design tags]]
[[Pe_gridview][pe:gridview]] [[pe_datasource][pe:xmldatasource]] [[pe_datasource][pe:mqldatasource]] [[Pe_Dialog][pe:dialog]] [[Pe_Tabs][pe:tabs]] [[Pe_Tabitem][pe:tab-item]] [[Pe_Treeview][pe:treeview]] [[Pe_Treenode][pe:treenode]] [[Pe_Image][pe:image]] [[Pe_flash][pe:flash]] 
[[Pe_Container][pe:container]] [[Pe_Editor][pe:editor]] [[Pe_Form][pe:editor]] [[pe_Input][input(button, listbox, text, radio, checkbox, file, etc)]]
[[Pe_Slide][pe:slide (interval=3 order="sequence"|"random")]], [[Pe_FileBrowser][pe:filebrowser(rootfolder="script" filter="*.lua;*.txt")]] [[Pe_FileUpload][pe:fileupload]]
[[Pe_progressbar][pe:progressbar]] [[Pe_canvas3d][pe:canvas3d]] [[Pe_numericupdown][pe:numericupdown]] [[Pe_sliderbar][pe:sliderbar]] [[Pe_colorpicker][pe:colorpicker]] [[Pe_ribbonbar][pe:ribbonbar]] 
   
</td><td valign="top" width="33%">
---+++ [[pe_user][Social tags]]
[[Pe_name][pe:name]] [[Pe_profile_photo][pe:profile-photo]] [[Pe_avatar][pe:avatar]] [[Pe_profile][pe:profile]] [[Pe_userinfo][pe:userinfo]] [[Pe_friends][pe:friends]] [[Pe_app][pe:app]] [[Pe_profileaction][pe:profile-action]] [[Pe_profilebox][pe:profile-box]] [[pe:app-home-button]]

---+++ Map tags
 [[Pe_land][pe:land]] [[Pe_map][pe:map]] [[Pe_mapmark][pe:map-mark]] [[Pe_mapmark2d][pe:map-mark2d]] [[Pe_maptile][pe:map-tile]]

---+++ Control tags
 [[Pe_if_is_user][pe:if-is-user]] [[pe_if][pe:if]] [[pe_if_not][pe:if-not]]

---+++ [[Pe_component][Component tags]]
[[Pe_roomhost][pe:roomhost]] [[Pe_market][pe:market]] [[Pe_comments][pe:comments]] [[Pe_ribbonbar][pe:ribbonbar]] [[Pe_command][pe:command]] [[Pe_asset][pe:asset]] [[Pe_bag][pe:bag]] 

---+++ Worlds tags
[[Pe_world][pe:world]] [[Pe_worldip][pe:world-ip]] [[Pe_model][pe:model]]
   
---+++ [[pe_motion][Motion tags]] 
[[Pe_animgroup][pe:animgroup]] [[Pe_Animlayer][pe:animlayer]] [[Pe_Animator][pe:animator]]
 
</td><td valign="top">
---+++ <nop>MCML by Examples
   * [[MCMLExamples][General MCML Examples]]
   * [[ExampleUserProfile][User Profile]] 
   * [[Example2DMap][2D Map]] 
   * [[ExampleMapMark][Map mark]] 
   * [[ExampleHomepage][Application Homepage]] 
   * [[ExampleIP][Integration point]] 
   * [[ExampleInventory][Inventory]] 
   * [[ExamplePhotoGalary][photo galary]] 
   
---+++ <nop>ParaWorld Platform Specific
   * [[ParaWorldAPI][Web Service API]]
   * [[FilesDirectories][Script Files and Directories]] 
   * [[BuildApp][Making an App]]
   
---+++ Other Topics
   * [[NPLFaq][Frequently Asked Questions]] 
   * [[ParaEngineDoc][ParaEngine Documentation]] 
   * [[DeveloperDoc][Documentation for Developers]] 
   * [[NPLMisc][Other Notes]] 
</td></tr></tbody></table>
%STOPINCLUDE%
]]