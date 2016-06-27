--[[
Title: Assets Common
Author(s): LiXizhi
Date: 2010/1/27
Desc: Common functions for assets
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Assets/AssetsCommon.lua");
local ds_func = MyCompany.Aries.Creator.AssetsCommon.Get_DS_Func_FromAssetsXMLFile("temp/mybag/helloassets/grass.bag.xml")
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/AI/LocalNPC.lua");
local LocalNPC = commonlib.gettable("MyCompany.Aries.Creator.AI.LocalNPC")

-- create class
local AssetsCommon = commonlib.gettable("MyCompany.Aries.Creator.AssetsCommon")

local page;

-- mapping from xml filename to data source table. 
local xml_ds = {};

-- create the data source function for a given xml_file
-- @param xml_filename: such as "temp/mybag/helloassets/grass.bag.xml"
-- @param bReload: true to force reloading of xml bag file. 
function AssetsCommon.Get_DS_Func_FromAssetsXMLFile(xml_filename,bReload)
	local dataSource = xml_ds[xml_filename];
	if(not dataSource or bReload) then
		dataSource = {};
		xml_ds[xml_filename] = dataSource;
		
		-- local disk xml file. 
		local xmlRoot = ParaXML.LuaXML_ParseFile(xml_filename);
		if(not xmlRoot) then 
			commonlib.log("warning: can not locate local asset data source xml file %s\n", xml_filename);
		else
			NPL.load("(gl)script/ide/XPath.lua");
			local itemNode;
			for itemNode in commonlib.XPath.eachNode(xmlRoot, "//pe:asset") do
				if(itemNode.attr) then
					dataSource[#dataSource + 1] = itemNode.attr;
				end	
			end
		end
		commonlib.log("Get_DS_Func_FromAssetsXMLFile: %s , %d items loaded\n", xml_filename, #dataSource);
	end
	
	return function(index)
		if(index == nil) then
			return #(dataSource);
		else
			return dataSource[index];
		end	
	end
end

-- Delete object such as user created mesh, character
-- @param msg: a table of {obj_params={...}}
function AssetsCommon.DeleteObject(msg)
	if(msg and msg.IsCharacter) then
		LocalNPC:RemoveNPCCharacter(msg.name);
	end	
	
	msg.type = Map3DSystem.msg.OBJ_DeleteObject;
	msg.silentmode = true;
	msg.SkipHistory = true;
	Map3DSystem.SendMessage_obj(msg)
end

------------------------------------------
-- helper class for creating new object
------------------------------------------
local ObjectCreator = {
	indoorOrigin = nil,--在室内的起点
	inRoomNode = nil,--现在是在哪个房屋的室内
	outdoorOrigin = nil,--在室外的起点
	
	limitBuildNodeTimer = nil,--限定创建物体的timer 功能: 不能创建太快
	
	minHouseNodeHeight = 100,--室内模型的最低高度
	houseNodeHeightStep = 20,--每个室内模型分配的高度
	buildNodeRadius = 0,
	buildNodeRadiusStep = 2,
	buildNodeMaxRadius = 10,
	buildNodeAngle = 0,
	buildNodeAngleStep = 30,
	buildNodeMaxAngle = 360,
	last_x = 0,
	last_y = 0,
	last_z = 0,
}

-- from leio's code in HomelandCanvas_New.lua
function ObjectCreator:GetBuildNodePostion()
	local x,y,z = ParaScene.GetPlayer():GetPosition();
	--如果是在室内 只允许在脚下创建物体
	if(self.inRoomNode and self.locationState == "inside")then
		return x,y,z;
	end
	local old_x,old_y,old_z = self.last_x,self.last_y,self.last_z;
	if(old_x ~= x or old_y ~= y or old_z ~= z)then
		--新位置
		self.buildNodeRadius = 0;
		self.buildNodeAngle = 0;
		self.last_x,self.last_y,self.last_z = x,y,z;
	end

	if(self.buildNodeRadius == 0 and self.buildNodeAngle == 0)then
		self.buildNodeRadius = self.buildNodeRadius + self.buildNodeRadiusStep;
		return x,y,z;
	else
		self.buildNodeAngle = self.buildNodeAngle + self.buildNodeAngleStep;
		if(self.buildNodeAngle > self.buildNodeMaxAngle)then
			self.buildNodeAngle = 0;
			
			self.buildNodeRadius = self.buildNodeRadius + self.buildNodeRadiusStep;
			if(self.buildNodeRadius > self.buildNodeMaxRadius)then
				self.buildNodeRadius = 0;
			end
		end
	end
	
	local angle = self.buildNodeAngle * 3.14/180;
	x = x + self.buildNodeRadius * math.cos(angle);
	z = z - self.buildNodeRadius * math.sin(angle);
	return x,y,z;
end

-- user created an object at the current player position. 
-- @param obj_params: such as { AssetFile="model/06props/v5/01stone/EvngrayRock/EvngrayRock03.x" }
function AssetsCommon.OnCreateObject(obj_params)
	--Note: the code is modified from System.App.Commands.Call("Creation.CreateObject", obj_params);
	
	if(not obj_params) then return end
	
	-- create the item according to the params
	local player = ParaScene.GetPlayer();
	
	-- position
	if(not obj_params.x)then
		local x,y,z = ObjectCreator:GetBuildNodePostion();
		obj_params.x = x;
		obj_params.y = y;
		obj_params.z = z;
	end
	if(not obj_params.facing and obj_params.IsCharacter)then
		obj_params.facing = player:GetFacing();
	end
		
	if(obj_params.IsCharacter) then
		if(not obj_params.name) then
			-- create a random name
			obj_params.name = tostring(ParaGlobal.timeGetTime());
		end
		if(not string.match(obj_params.name, "^local:")) then
			obj_params.name = "local:"..obj_params.name;
		end
		obj_params.DisplayName = obj_params.DisplayName or "";
	end
	commonlib.log("Aries: a new local world object is create\n");
	commonlib.echo(obj_params);
	
	-- post processing
	if(obj_params.IsCharacter) then
		-- use local NPC for creation. 
		LocalNPC:CreateNPCCharacter(obj_params)
		
		-- play "CreateCharacter" animation
		Map3DSystem.Animation.SendMeMessage({type = Map3DSystem.msg.ANIMATION_Character,obj_params = nil, animationName = "CreateCharacter",});
	else
		-- create object by sending a message
		Map3DSystem.SendMessage_obj({
				type = Map3DSystem.msg.OBJ_CreateObject, 
				obj_params = obj_params,
				silentmode = true, SkipHistory = true
			});
			
		-- play "RaiseTerrain" animation
		Map3DSystem.Animation.SendMeMessage({type = Map3DSystem.msg.ANIMATION_Character,obj_params = nil, animationName = "RaiseTerrain",});
	end		
end
