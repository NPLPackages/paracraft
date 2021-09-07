--[[
Title: ItemNplCadEditor
Author(s): leio
Date: 2021/8/14
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Items/ItemNplCadEditor.lua");
local ItemNplCadEditor = commonlib.gettable("MyCompany.Aries.Game.Items.ItemNplCadEditor");

-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)script/ide/System/Windows/Keyboard.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/NPLWebServer.lua");
local NplBrowserLoaderPage = commonlib.gettable("NplBrowser.NplBrowserLoaderPage");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local NPLWebServer = commonlib.gettable("MyCompany.Aries.Game.Network.NPLWebServer");

local Player = commonlib.gettable("MyCompany.Aries.Player");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local ItemNplCadEditor = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Items.Item"), commonlib.gettable("MyCompany.Aries.Game.Items.ItemNplCadEditor"));
block_types.RegisterItemClass("ItemNplCadEditor", ItemNplCadEditor);



