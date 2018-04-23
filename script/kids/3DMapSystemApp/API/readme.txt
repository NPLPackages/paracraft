--[[
Title: read me file for ParaWorldAPI
Author(s): LiXizhi
Date: 2008/3/4
Desc: developer guide for ParaWorldAPI
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/readme.lua");
-------------------------------------------------------
]]

--[[ ParaWorldAPI wiki page:
%T% *Do not edit this page*. It is automatically generated from "script/kids/3DMapSystemApp/MCML/readme.lua", so edit the source file instead. 
%STARTINCLUDE%
---++!! <nop>ParaWorld API

<div style="float:right; margin:5px; width:240px; padding:5px; color:#4E5155; background-color:#F0EDED; border:1px solid #ccc;">
*Contents*
%TOC%
</div>

---++ What is <nop>ParaWorld API?
ParaWorld API is an evolving collection of web service or REST interface. 
You can add social context to your application by calling these API to access
user profile, friend, photo, map, and many other official application interface.

---++ Web serivce vs. REST Interface
API uses both web service and REST-like interface. REST interface means that 
all web method calls are made over the Internet by sending HTTP GET or POST requests 
to the our servers. Nearly any computer language can be used to communicate over HTTP with our servers. 

The query result can be returned either in XML format or NPL table format. 
The latter is more compact and more readable by human beings and is the default format used by our official servers.

---++ API Methods
APIs are organized by namespaces. The sample code in this article assumes that you are using the NPL web service wrapper 
which is located in script/app/API folder of the client installation.

<table border="0" width="100%"><tbody><tr><td valign="top" width="33%">

---+++ [[ParaWorld_Auth][auth]]
   * [[Paraworld_auth_AuthUser][paraworld.auth.AuthUser]]
   * [[Paraworld_auth_Logout][paraworld.auth.Logout]]
   * [[Paraworld_auth_VerifyUser][paraworld.auth.VerifyUser]]
   * [[Paraworld_auth_CheckVersion][paraworld.auth.CheckVersion]]
   * [[Paraworld_auth_SendConfirmEmail][paraworld.auth.SendConfirmEmail]]

---+++ [[ParaWorld_Friends][friends]]
   * [[Paraworld_friends_get][paraworld.friends.get]]
   * [[Paraworld_friends_add][paraworld.friends.add]]
   * [[Paraworld_friends_remove][paraworld.friends.remove]]   

---+++ [[ParaWorld_Profile][profile]]
   * [[Paraworld_profile_SetMCML][paraworld.profile.SetMCML]]
   * [[Paraworld_profile_GetMCML][paraworld.profile.GetMCML]]   

---+++ [[ParaWorld_Users][users]]
   * [[Paraworld_users_getInfo][paraworld.users.getInfo]]
   * [[Paraworld_users_setInfo][paraworld.users.setInfo]]
   * [[Paraworld_users_isAppAdded][paraworld.users.isAppAdded]]
   * [[Paraworld_users_Find][paraworld.users.Find]]
   * [[Paraworld_users_Search][paraworld.users.Search]]
   * [[Paraworld_users_Invite][paraworld.users.Invite]]

---+++ [[ParaWorld_File][file]]
   * [[Paraworld_map_UploadFile][paraworld.map.UploadFile]]
   * [[Paraworld_file_CreateFile][Paraworld.file.CreateFile]]
   * [[Paraworld_file_DeleteFile][Paraworld.file.DeleteFile]]
   * [[Paraworld_file_GetFile][Paraworld.file.GetFile]]
   * [[Paraworld_file_RenameFile][Paraworld.file.RenameFile]]
   * [[Paraworld_file_FindFile][Paraworld.file.FindFile]]
         
</td><td valign="top" width="33%">
---+++ [[ParaWorld_Map][worlds]]
   * [[Paraworld_map_PublishWorld][paraworld.map.PublishWorld]]
   * [[Paraworld_map_GetWorldByID][paraworld.map.GetWorldByID]]
   * [[Paraworld_map_UpdateWorld][paraworld.map.UpdateWorld]]
   * [[Paraworld_map_RemoveWorld][paraworld.map.RemoveWorld]]
   * [[Paraworld_map_JoinWorld][paraworld.map.JoinWorld]]
   * [[Paraworld_map_MqlQuery][paraworld.map.MqlQuery]]
   * [[Paraworld_map_LeaveWorld][paraworld.map.LeaveWorld]]
   * [[Paraworld_map_VisitWorld][paraworld.map.VisitWorld]]
   * [[Paraworld_map_GetWorlds][paraworld.map.GetWorlds]]
   
---+++ [[ParaWorld_Map][map]]   
   * [[Paraworld_map_OfficialMap][paraworld.map.OfficialMap]]   
   * [[Paraworld_map_UserMap][paraworld.map.UserMap]]
   * [[Paraworld_map_GetMapMarkOfPage][paraworld.map.GetMapMarkOfPage]]
   * [[Paraworld_map_GetMapMarksInRegion][paraworld.map.GetMapMarksInRegion]]
   * [[Paraworld_map_GetMapModelByIDs][paraworld.map.GetMapModelByIDs]]
   * [[Paraworld_map_GetMapModelOfPage][paraworld.map.GetMapModelOfPage]]
   * [[Paraworld_map_GetTilesInRegion][paraworld.map.GetTilesInRegion]]
   * [[Paraworld_map_GetMapMarkByID][paraworld.map.GetMapMarkByID]]
   * [[Paraworld_map_AddMapMark][paraworld.map.AddMapMark]]
   * [[Paraworld_map_RemoveMapMark][paraworld.map.RemoveMapMark]]
   * [[Paraworld_map_AddModel][paraworld.map.AddModel]]
   * [[Paraworld_map_GetModelByID][paraworld.map.GetModelByID]]
   * [[Paraworld_map_UpdateModel][paraworld.map.UpdateModel]]
   * [[Paraworld_map_RemoveModel][paraworld.map.RemoveModel]]
   * [[Paraworld_map_SearchMapMark][paraworld.map.SearchMapMark]]
   * [[Paraworld_map_AddTile][paraworld.map.AddTile]]
   * [[Paraworld_map_GetTileByID][paraworld.map.GetTileByID]]
   * [[Paraworld_map_UpdateTile][paraworld.map.UpdateTile]]
   * [[Paraworld_map_BuyTile][paraworld.map.BuyTile]]
   
</td><td valign="top">
---+++ [[ParaWorld_MQL][MQL]]
   * [[Paraworld_MQL_query][paraworld.MQL.query]]
   
---+++ [[ParaWorld_Actionfeed][actionfeed]]
   * [[Paraworld_actionfeed_PublishStoryToUser][paraworld.actionfeed.PublishStoryToUser]]
   * [[Paraworld_actionfeed_PublishActionToUser][paraworld.actionfeed.PublishActionToUser]]
   * [[Paraworld_actionfeed_PublishRequestToUser][paraworld.actionfeed.PublishRequestToUser]]
   * [[Paraworld_actionfeed_PublishMessageToUser][paraworld.actionfeed.PublishMessageToUser]]
   * [[Paraworld_actionfeed_PublishItemToUser][paraworld.actionfeed.PublishItemToUser]]
   * [[Paraworld_actionfeed_sendEmail][paraworld.actionfeed.sendEmail]]

---+++ [[ParaWorld_Email][email]]
   * [[Paraworld_email_send][paraworld.email.send]]   
   * [[Paraworld_email_check][paraworld.email.check]]
   * [[Paraworld_email_get][paraworld.email.get]]
   * [[Paraworld_email_remove][paraworld.email.remove]]
   * [[Paraworld_email_cmd][paraworld.email.cmd]]

---+++ [[ParaWorld_Inventory][inventory]]
   * [[Paraworld_bag_GetBag][paraworld.bag.GetBag]]
   * [[Paraworld_bag_BuyItems][paraworld.bag.BuyItems]]
   * [[Paraworld_bag_SwapItems][paraworld.bag.SwapItems]]
   * [[Paraworld_bag_SendItems][paraworld.bag.SendItems]]
   * [[Paraworld_bag_DestroyItems][paraworld.bag.DestroyItems]]
   * [[Paraworld_store_GetItems][paraworld.store.GetItems]]   
   * [[Paraworld_store_ManageItem][paraworld.store.ManageItem]]

---+++ [[ParaWorld_Lobby][lobby]]
   * [[Paraworld_lobby_CreateRoom][paraworld.lobby.CreateRoom]]
   * [[Paraworld_lobby_JoinRoom][paraworld.lobby.JoinRoom]]   
   * [[Paraworld_lobby_GetRoomList][paraworld.lobby.GetRoomList]]
   * [[Paraworld_lobby_PostBBS][paraworld.lobby.PostBBS]]
   * [[Paraworld_lobby_GetBBS][paraworld.lobby.GetBBS]]

---+++ [[ParaWorld_Marketplace][marketplace]]
   * [[Paraworld_marketplace_GetBags][paraworld.marketplace.GetBags]]
   * [[Paraworld_marketplace_AddBag][paraworld.marketplace.AddBag]]
   * [[Paraworld_marketplace_RemoveBag][paraworld.marketplace.RemoveBag]]
   
</td></tr></tbody></table>

---++ Additional documentation
   * [[AuthGuide][Authentication guide]]
   * [[ErrorCodes][Error codes]]
   
---++ Usage Examples in NPL
   * [[ExamplePhotoUploads][photo uploads]]
   * [[ExampleMarketplace][Marketplace Listing]]
   * [[ExampleMap][Map Editing]]
   * [[ExamplePublishWorld][Publish World]]
   * [[ExampleProfileMCML][Profile box MCML]]
   * [[ExampleUserFriends][User and friends Info]]

---++ External tools
   * ParaWorld's api [[UnitTest][UnitTest console]]
   * TODO: Create our own test console as a TestConsoleApp
   
%STOPINCLUDE%
]]