--[[
Title: TerrainBrushMarker
Author(s): LiXizhi
Company: ParaEnging Co. & Taomee Inc.
Date: 2010/1/26
Desc: miniscenegraph for rendering terrain brush. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Env/TerrainBrushMarker.lua");
local TerrainBrushMarker = MyCompany.Aries.Creator.TerrainBrushMarker;
TerrainBrushMarker.DrawBrush({x,z,radius});
TerrainBrushMarker.Clear()
------------------------------------------------------------
]]

local TerrainBrushMarker = commonlib.gettable("MyCompany.Aries.Creator.TerrainBrushMarker")

TerrainBrushMarker.Assets = {
	["center"] = "model/common/editor/z.x",
	["point"] = "model/common/editor/scalebox.x",
	["cell_region"] = "model/06props/v5/03quest/AchievementBrand/AchievementBrand.x",
	--["cell_region"] = "model/common/editor/z.x",
}
-- how many point to draw for the circle 
TerrainBrushMarker.CirclePointCount = 12;
TerrainBrushMarker.MinCirclePointCount = 12;
TerrainBrushMarker.MaxCirclePointCount = 36;
-- distance between markers in meters
TerrainBrushMarker.MakerSpacing = 1.0;

TerrainBrushMarker.CellSize = 64;
TerrainBrushMarker.CellCenterX = 0;
TerrainBrushMarker.CellCenterY = 0;

local brush = {
	x=nil,
	y=nil,
	z=nil,
	radius=nil,
}

local elapsedTime=0;
local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
	local miniscene = ParaScene.GetMiniSceneGraph("TerrainBrushMarker");
	if(miniscene:IsVisible()) then
		-- move an object
		local obj = miniscene:GetObject("cell_region");
		if(obj:IsValid() and obj:IsVisible()) then
			-- move a particle around a border. 
			elapsedTime = elapsedTime + 0.05;
			--local x = TerrainBrushMarker.CellCenterX+math.cos(elapsedTime)*6;
			--local z = TerrainBrushMarker.CellCenterY+math.sin(elapsedTime)*6;
			local x, z = TerrainBrushMarker.CellCenterX, TerrainBrushMarker.CellCenterY
			local y = ParaTerrain.GetElevation(x, z)+math.sin(2*elapsedTime)*2+2;
			obj:SetPosition(x, y, z);
		else
			-- kill the timer
			timer:Change(nil,nil)
		end
	else
		-- kill the timer
		timer:Change(nil,nil)
	end
end})

-- show texture cell region by location. It will highlight the closest cell region near point(x,y)
-- @param bShow: if true to show. false to hide. 
-- @param x: x position in world unit. if nil, current player location is used. 
-- @param y: y position in world unit. 
function TerrainBrushMarker.ShowTextureCellRegion(bShow, x,y,z)
	local miniscene = ParaScene.GetMiniSceneGraph("TerrainBrushMarker");
	if(bShow) then
		miniscene:SetVisible(true);
	end
	
	if(x == nil or z ==nil) then
		x,y,z = ParaScene.GetPlayer():GetPosition();
	end	
	
	local obj = ParaTerrain.GetAttributeObjectAt(x,z);
	if(obj:IsValid()) then
		local cell_size = obj:GetField("Size", 500)/8;
		TerrainBrushMarker.CellSize = cell_size;
		x = math.floor(x/cell_size)*cell_size + cell_size/2;
		z = math.floor(z/cell_size)*cell_size + cell_size/2;
		TerrainBrushMarker.CellCenterX = x;
		TerrainBrushMarker.CellCenterY = z;
	end
	y = ParaTerrain.GetElevation(x, z);
	
	local obj = miniscene:GetObject("cell_region");
	if(not obj:IsValid()) then
		local _asset = ParaAsset.LoadStaticMesh("", TerrainBrushMarker.Assets["cell_region"]);
		obj = ParaScene.CreateMeshPhysicsObject("cell_region", _asset, 1,1,1,false, "1,0,0,0,1,0,0,0,1,0,0,0");
		obj:SetFacing(0);
		obj:GetAttributeObject():SetField("progress", 1);
		obj:SetPosition(x,y,z);
		miniscene:AddChild(obj);
	else
		obj:SetPosition(x,y,z);
	end
	if(obj:IsValid()) then
		obj:SetVisible(bShow);
		if(bShow) then
			mytimer:Change(0,30)
		else
			mytimer:Change(nil,nil)
		end
	end	
end

-- called to init page
-- @param brush: {x,z,radius}, all fields are optional. it will partial copy to brush struct
function TerrainBrushMarker.DrawBrush(newBrush)
	commonlib.partialcopy(brush, newBrush);
	
	local miniscene = ParaScene.GetMiniSceneGraph("TerrainBrushMarker");
	miniscene:SetVisible(true);
	if(brush.x and brush.z and brush.radius) then
		local y = ParaTerrain.GetElevation(brush.x, brush.z)
		local obj = miniscene:GetObject("center");
		if(obj:IsValid() == false) then
			local _asset = ParaAsset.LoadStaticMesh("", TerrainBrushMarker.Assets["center"]);
			obj = ParaScene.CreateMeshPhysicsObject("center", _asset, 1,1,1,false, "1,0,0,0,1,0,0,0,1,0,0,0");
			obj:SetFacing(0);
			obj:GetAttributeObject():SetField("progress", 1);
			obj:SetPosition(brush.x, y, brush.z);
			miniscene:AddChild(obj);
		else
			obj:SetPosition(brush.x, y, brush.z);
		end
		
		-- automatically determine how many maker to use. 
		local markerCount = math.floor(brush.radius*6.28/TerrainBrushMarker.MakerSpacing)
		if(markerCount>TerrainBrushMarker.MaxCirclePointCount) then
			markerCount = TerrainBrushMarker.MaxCirclePointCount
		elseif(markerCount<TerrainBrushMarker.MinCirclePointCount) then
			markerCount = TerrainBrushMarker.MinCirclePointCount
		end	
		TerrainBrushMarker.CirclePointCount = markerCount;
		
		local i;
		local _asset;
		for i=1,TerrainBrushMarker.CirclePointCount do
			local angle = (i/TerrainBrushMarker.CirclePointCount)*6.28;
			local x = brush.x + brush.radius * math.sin(angle);
			local z = brush.z + brush.radius * math.cos(angle);
			local y = ParaTerrain.GetElevation(x, z)
			
			local obj = miniscene:GetObject(tostring(i));
			if(obj:IsValid() == false) then
				_asset = _asset or ParaAsset.LoadStaticMesh("", TerrainBrushMarker.Assets["point"]);
				obj = ParaScene.CreateMeshPhysicsObject(tostring(i), _asset, 1,1,1,false, "1,0,0,0,1,0,0,0,1,0,0,0");
				obj:SetFacing(0);
				obj:GetAttributeObject():SetField("progress", 1);
				obj:SetPosition(x, y, z);
				miniscene:AddChild(obj);
			else
				obj:SetVisible(true);
				obj:SetPosition(x, y, z);
			end
		end
		if(TerrainBrushMarker.CirclePointCount < TerrainBrushMarker.MaxCirclePointCount ) then
			for i=TerrainBrushMarker.CirclePointCount+1,TerrainBrushMarker.MaxCirclePointCount do
				local obj = miniscene:GetObject(tostring(i));
				if(obj:IsValid()) then
					obj:SetVisible(false);
				else
					break;
				end
			end
		end
	end	
end

-- brush line and circle from (x1,z1) to (x,z)
function TerrainBrushMarker.DrawRamp(brush)
	local miniscene = ParaScene.GetMiniSceneGraph("TerrainBrushMarker");
	miniscene:SetVisible(true);
	if(brush.x1 and brush.z1 and brush.x and brush.z and brush.radius) then
		local y = ParaTerrain.GetElevation(brush.x, brush.z)
		local obj = miniscene:GetObject("center");
		if(obj:IsValid() == false) then
			local _asset = ParaAsset.LoadStaticMesh("", TerrainBrushMarker.Assets["center"]);
			obj = ParaScene.CreateMeshPhysicsObject("center", _asset, 1,1,1,false, "1,0,0,0,1,0,0,0,1,0,0,0");
			obj:SetFacing(0);
			obj:GetAttributeObject():SetField("progress", 1);
			obj:SetPosition(brush.x, y, brush.z);
			miniscene:AddChild(obj);
		else
			obj:SetPosition(brush.x, y, brush.z);
		end
		
		-- automatically determine how many maker to use. 
		local markerCount = math.floor(brush.radius*6.28/TerrainBrushMarker.MakerSpacing)
		if(markerCount>TerrainBrushMarker.MaxCirclePointCount/2) then
			markerCount = TerrainBrushMarker.MaxCirclePointCount/2
		elseif(markerCount<TerrainBrushMarker.MinCirclePointCount) then
			markerCount = TerrainBrushMarker.MinCirclePointCount
		end	
		TerrainBrushMarker.CirclePointCount = markerCount;
		
		local i;
		local _asset;
		for i=1,markerCount do
			local angle = (i/markerCount)*6.28;
			local x = brush.x + brush.radius * math.sin(angle);
			local z = brush.z + brush.radius * math.cos(angle);
			local y = ParaTerrain.GetElevation(x, z)
			
			local obj = miniscene:GetObject(tostring(i));
			if(obj:IsValid() == false) then
				_asset = _asset or ParaAsset.LoadStaticMesh("", TerrainBrushMarker.Assets["point"]);
				obj = ParaScene.CreateMeshPhysicsObject(tostring(i), _asset, 1,1,1,false, "1,0,0,0,1,0,0,0,1,0,0,0");
				obj:SetFacing(0);
				obj:GetAttributeObject():SetField("progress", 1);
				obj:SetPosition(x, y, z);
				miniscene:AddChild(obj);
			else
				obj:SetVisible(true);
				obj:SetPosition(x, y, z);
			end
		end
		if(TerrainBrushMarker.CirclePointCount < TerrainBrushMarker.MaxCirclePointCount ) then
			if(brush.x1~=brush.x or brush.z1~=brush.z) then
				-- now draw a line
				local lineLength = math.sqrt((brush.x1-brush.x)*(brush.x1-brush.x)+(brush.z1-brush.z)*(brush.z1-brush.z))
				
				local markerLeftCount = TerrainBrushMarker.MaxCirclePointCount - TerrainBrushMarker.CirclePointCount-1;
				local markerCount = math.floor(lineLength/TerrainBrushMarker.MakerSpacing)
				if(markerCount>markerLeftCount) then
					markerCount = markerLeftCount
				end	
				for i=1,markerCount do
					local k = (i-1)/markerCount;
					local x = brush.x1 + (brush.x-brush.x1) * k;
					local z = brush.z1 + (brush.z-brush.z1) * k;
					local y = ParaTerrain.GetElevation(x, z)
			
					local objname = tostring(i+TerrainBrushMarker.CirclePointCount);
					local obj = miniscene:GetObject(objname);
					if(obj:IsValid() == false) then
						_asset = _asset or ParaAsset.LoadStaticMesh("", TerrainBrushMarker.Assets["point"]);
						obj = ParaScene.CreateMeshPhysicsObject(objname, _asset, 1,1,1,false, "1,0,0,0,1,0,0,0,1,0,0,0");
						obj:SetFacing(0);
						obj:GetAttributeObject():SetField("progress", 1);
						obj:SetPosition(x, y, z);
						miniscene:AddChild(obj);
					else
						obj:SetVisible(true);
						obj:SetPosition(x, y, z);
					end
				end
				TerrainBrushMarker.CirclePointCount = TerrainBrushMarker.CirclePointCount + markerCount;
			end
			
			-- make remaining invisible
			for i=TerrainBrushMarker.CirclePointCount+1,TerrainBrushMarker.MaxCirclePointCount do
				local obj = miniscene:GetObject(tostring(i));
				if(obj:IsValid()) then
					obj:SetVisible(false);
				else
					break;
				end
			end
		end
	else
		TerrainBrushMarker.DrawBrush(brush);
	end	
end

-- clear everything. 
function TerrainBrushMarker.Clear()
	local miniscene = ParaScene.GetMiniSceneGraph("TerrainBrushMarker");
	miniscene:SetVisible(false);
end
