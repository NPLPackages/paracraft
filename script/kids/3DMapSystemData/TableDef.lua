--[[
Title: Table defination to 3D Map system data
Author(s): WangTian
Date: 2007/9/18
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemData/TableDef.lua");
------------------------------------------------------------

]]
NPL.load("(gl)script/ide/commonlib.lua");

-- 3D Map System
if(not Map3DSystem) then 
	Map3DSystem = {}; 
end

-- network information
if(not Map3DSystem.Network) then Map3DSystem.Network = {}; end

-- user interface information
if(not Map3DSystem.UI) then Map3DSystem.UI = {}; end

-- application interface information
if(not Map3DSystem.App) then Map3DSystem.App = {}; end
if(not Map3DSystem.Apps) then Map3DSystem.Apps = {}; end

-- map 3d system database table for assets
if(not Map3DSystem.DB) then Map3DSystem.DB = {}; end

-- character animation manager
if(not Map3DSystem.Animation) then Map3DSystem.Animation = {}; end
