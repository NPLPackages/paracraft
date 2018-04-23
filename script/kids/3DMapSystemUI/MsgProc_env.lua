--[[
Title: All environment message processors, such as terrain, ocean and sky
Author(s): LiXizhi(code&logic)
Date: 2007/10/16
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/MsgProc_obj.lua");
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/TimeSeries/TimeSeries.lua");

--[[Map3DSystem.Env.Terrain library]]
if(not Map3DSystem.Env) then Map3DSystem.Env={}; end
if(not Map3DSystem.Env.Terrain) then Map3DSystem.Env.Terrain={}; end
if(not Map3DSystem.Env.Ocean) then Map3DSystem.Env.Ocean={}; end
if(not Map3DSystem.Env.Sky) then Map3DSystem.Env.Sky={}; end

-- history is a time series object that contains variables, which are a table of time, value pairs. 
Map3DSystem.Env.history=nil;

-- get the history 
function Map3DSystem.Env.GetHistory()
	local self = Map3DSystem.Env;
	if(self.history == nil)  then
		self.ResetHistory();
	end
	return self.history;
end

-- reset the history class
function Map3DSystem.Env.ResetHistory()
	local self = Map3DSystem.Env;
	self.history = TimeSeries:new{name = "EnvHistory",};
	self.history:CreateVariable({name = "env", type="Discrete"});
end

-- texture brush property
Map3DSystem.Env.Terrain.brush = {
	-- texture file name or index into current texture list
	filename,
	-- position of the center of the brush in world coordinate
	x,y,z,
	-- radius
	radius = 2,
	-- brush filter factor
	factor = 0.5,
	-- erase or paint
	bErase = false,
	BrushStrength = 0.7,
	BrushSoftness = 1.0,
};

-- height map or elevation modifier
Map3DSystem.Env.Terrain.HeightFieldBrush = {
	radius = 20,
	BrushStrength = 0.3,
	smooth_factor = 0.5,
	-- scale factor. One can think of it as the maximum height of the Gaussian Hill. this value can be negative
	heightScale = 3.0,
	sq_filter_size = 4,
	sq_filter_weight = 0.5,
	gaussian_deviation = 0.9,
	Elevation = 0,
	FlattenOperation = -1,
	-- whether to use 3*3 filter or 5*5 filter
	big_grid = false,
	bIsHole = true,
};

--[[load the texture list
@param texList: this can be nil, where the default list is loaded.
]]
function Map3DSystem.Env.Terrain.LoadTextureList(texList)
	if(texList~=nil)  then
		Map3DSystem.Env.Terrain.textures = texList;
	else
		-- some default textures. default texture is loaded automatically at startup
		Map3DSystem.Env.Terrain.textures = {
			{filename = "Texture/tileset/generic/StoneRoad.dds"},
			{filename = "Texture/tileset/generic/sandRock.dds"},
			{filename = "Texture/tileset/generic/sandSmallRock.dds"},
			
			{filename = "Texture/tileset/generic/greengrass.dds"},
			{filename = "Texture/tileset/generic/stonegrass.dds"},
			{filename = "Texture/tileset/generic/GridMarker.dds"},
			
			{filename = "Texture/tileset/generic/dryland.dds"},
			{filename = "Texture/tileset/generic/soil.dds"},
			{filename = "Texture/tileset/generic/sandwave.dds"},
			
			{filename = "Texture/tileset/generic/snow.dds"},
			{filename = "Texture/tileset/generic/whitesand.dds"},
			{filename = "Texture/tileset/generic/lightgreen.dds"},
			
			{filename = "Texture/tileset/generic/yellowgrass.dds"},
			{filename = "Texture/tileset/generic/default.dds"},
			{filename = "Texture/tileset/generic/sand.dds"},
			
			{filename = "Texture/tileset/generic/custom1.dds"},
			{filename = "Texture/tileset/generic/custom2.dds"},
			{filename = "Texture/tileset/generic/custom3.dds"},
			
			{filename = "Texture/tileset/generic/custom4.dds"},
			{filename = "Texture/tileset/generic/custom5.dds"},
			{filename = "Texture/tileset/generic/custom6.dds"},
			
			{filename = "Texture/tileset/generic/custom7.dds"},
			{filename = "Texture/tileset/generic/custom8.dds"},
			{filename = "Texture/tileset/generic/custom9.dds"},
			{filename = "Texture/tileset/generic/custom10.dds"},
			{filename = "Texture/tileset/generic/custom11.dds"},
		};
	end	
end

-- load default texture is at startup
if(not Map3DSystem.Env.Terrain.textures)then
	Map3DSystem.Env.Terrain.LoadTextureList();
end
-------------------------------------------------------------
-- message related
-------------------------------------------------------------

-- scene:object window handler
function Map3DSystem.OnEnvMessage(window, msg)
	if(msg.type == Map3DSystem.msg.TERRAIN_SET_PaintBrush) then
		----------------------------------------------
		-- TERRAIN_SET_PaintBrush in the scene
		----------------------------------------------
		if(msg.brush) then
			commonlib.partialcopy(Map3DSystem.Env.Terrain.brush, msg.brush);
			
			-- convert index to filename
			if(type(msg.brush.filename) == "number") then
				local nIndex = msg.brush.filename;
				if(Map3DSystem.Env.Terrain.textures[nIndex]~=nil and Map3DSystem.Env.Terrain.textures[nIndex].filename~=nil) then
					Map3DSystem.Env.Terrain.brush.filename = Map3DSystem.Env.Terrain.textures[nIndex].filename;
				else
					Map3DSystem.Env.Terrain.brush.filename = ""
				end	
			end
		end
		
	elseif(msg.type == Map3DSystem.msg.TERRAIN_GET_PaintBrush) then
		msg.brush = Map3DSystem.Env.Terrain.brush
		
	elseif(msg.type == Map3DSystem.msg.TERRAIN_SET_TextureList) then
		Map3DSystem.Env.Terrain.LoadTextureList(msg.texList);
		
	elseif(msg.type == Map3DSystem.msg.TERRAIN_GET_TextureList) then
		msg.texList = Map3DSystem.Env.Terrain.textures;
		
	elseif(msg.type == Map3DSystem.msg.TERRAIN_SET_HeightFieldBrush) then
		----------------------------------------------
		-- TERRAIN_SET_HeightFieldBrush in the scene
		----------------------------------------------
		if(msg.brush) then
			commonlib.partialcopy(Map3DSystem.Env.Terrain.HeightFieldBrush, msg.brush);
		end
		
	elseif(msg.type == Map3DSystem.msg.TERRAIN_GET_HeightFieldBrush) then
		msg.brush = Map3DSystem.Env.Terrain.HeightFieldBrush;
		
	elseif(msg.type == Map3DSystem.msg.TERRAIN_Paint) then
		---------------------------------------------
		-- paint texture on terrain
		---------------------------------------------
		if(not Map3DSystem.User.CheckRight("TerrainTexture")) then return end
		
		local nServerState = ParaWorld.GetServerState();
		local brush = msg.brush or Map3DSystem.Env.Terrain.brush;
		
		if(msg.forcelocal or nServerState == 0) then
			-- this is a standalone computer
			if(not msg.disableSound) then
				ParaAudio.PlayUISound("Btn1");
			end	
			if(brush.filename~=nil and brush.radius and brush.BrushStrength and brush.x and brush.z) then
				if(not brush.bErase) then
					ParaTerrain.Paint(brush.filename,brush.radius, brush.BrushStrength, brush.BrushSoftness, false, brush.x,brush.z);
				else
					local brushIntensity = 1.0;
					if(filename == "") then
						brushIntensity = 0.2;
					end
					ParaTerrain.Paint(brush.filename,brush.radius, brushIntensity, 0, true, brush.x,brush.z);
				end
			end
			
		elseif(nServerState == 1) then
			-- this is a server. 
			server.BroadcastTerrainTexModify(brush.filename,brush.x,brush.y,brush.z,brush.radius, brush.bErase);
			
		elseif(nServerState == 2) then
			-- this is a client. 
			client.RequestTerrainTexModify(brush.filename,brush.x,brush.y,brush.z,brush.radius, brush.bErase);
		end
		
		-- write to history. 
		if(not msg.SkipHistory) then
			local author = msg.author;
			if(author == nil and not msg.silentmode) then
				-- assume that this is created by the current player
				author = ParaScene.GetPlayer().name;
			end
			if(author~=nil and brush~=nil) then
				local history = Map3DSystem.Env.GetHistory();
				local time = history.env:GetLastTime() or 0;
				-- we will only save non character to history, at the moment. 
				local new_msg = {author = author, brush = commonlib.deepcopy(brush)};
				commonlib.partialcopy(new_msg, msg);
				history.env:AutoAppendKey(time+1, new_msg, true);
				-- log
				--log("History: "..author.." env paint \n")
			end	
		end	
	
	elseif(msg.type == Map3DSystem.msg.TERRAIN_HeightField) then
		---------------------------------------------
		-- apply height field on terrain
		---------------------------------------------
		if(not Map3DSystem.User.CheckRight("TerrainHeightmap")) then return end
		local brush = msg.brush or Map3DSystem.Env.Terrain.HeightFieldBrush;
		
		local nServerState = ParaWorld.GetServerState();
		if(msg.forcelocal or nServerState == 0) then
			-- this is a standalone computer
			if(not msg.disableSound) then
				ParaAudio.PlayUISound("Btn5");
			end	
			if(brush.type == "GaussianHill") then
				-- raise or lower the terrain using gaussian edge
				-- heightScale: height of the hill, it can be negative.
				ParaTerrain.GaussianHill(brush.x,brush.z,brush.radius, brush.heightScale, brush.gaussian_deviation, brush.smooth_factor);
				Map3DSystem.Env.Terrain.TerrainModified(brush.x,brush.y, brush.z,brush.radius);

			elseif(brush.type == "RadialScale") then
				-- raise or lower the terrain using gaussian edge
				-- heightScale: height of the hill, it can be negative.
				ParaTerrain.RadialScale(brush.x,brush.z,brush.heightScale, brush.radius*brush.BrushStrength, brush.radius, brush.smooth_factor);
				Map3DSystem.Env.Terrain.TerrainModified(brush.x,brush.y, brush.z,brush.radius);
				
			elseif(brush.type == "Flatten") then
				-- flatten land
				if(brush.FlattenOperation ==-1) then
					ParaTerrain.DigCircleFlat(brush.x,brush.z,brush.radius, brush.BrushStrength, brush.smooth_factor);
				else
					ParaTerrain.Flatten(brush.x,brush.z,brush.radius, brush.FlattenOperation, brush.Elevation, brush.smooth_factor);
				end	
				Map3DSystem.Env.Terrain.TerrainModified(brush.x,brush.y, brush.z,brush.radius);
				
			elseif(brush.type == "Roughen_Smooth") then	
				-- Roughen_Smooth
				ParaTerrain.Roughen_Smooth(brush.x,brush.z,brush.radius, brush.bRoughen, brush.big_grid, brush.smooth_factor);
				Map3DSystem.Env.Terrain.TerrainModified(brush.x,brush.y, brush.z,brush.radius);
				
			elseif(brush.type == "AddHeightField") then		
				-- apply height field from a raw elevation file
				if(brush.filename~=nil and brush.filename~="") then
					ParaTerrain.AddHeightField(brush.x,brush.z, brush.filename, msg.smoothpixels or 10); -- 10 is the number of pixels to smooth from the edge of the height field.
					Map3DSystem.Env.Terrain.TerrainModified(brush.x,brush.y, brush.z,brush.radius);
				end	
			elseif(brush.type == "MergeHeightField") then		
				-- apply height field from a raw elevation file
				if(brush.filename~=nil and brush.filename~="") then
					ParaTerrain.MergeHeightField(brush.x,brush.z, brush.filename, 
						msg.MergeOperation or 0,  msg.weight1 or 1,  msg.weight2 or 1, msg.smoothpixels or 10); -- 10 is the number of pixels to smooth from the edge of the height field.
					Map3DSystem.Env.Terrain.TerrainModified(brush.x,brush.y, brush.z,brush.radius);
				end		
			elseif(brush.type == "Spherical") then			
				-- obsoleted. offset along x
				ParaTerrain.Spherical(brush.x,brush.z,brush.radius, brush.BrushStrength);
				Map3DSystem.Env.Terrain.TerrainModified(brush.x,brush.y, brush.z,brush.radius);
			elseif(brush.type == "Ramp") then
				-- create an inclined slope
				if(brush.x1 and brush.z1 and brush.x2 and brush.z2 and (brush.x1~=brush.x2 or brush.z1~=brush.z2)) then
					ParaTerrain.Ramp(brush.x1,brush.z1, brush.x2,brush.z2,brush.radius, brush.BrushStrength, brush.smooth_factor);
					local radius = brush.radius + math.sqrt((brush.x1-brush.x2)*(brush.x1-brush.x2)+(brush.z1-brush.z2)*(brush.z1-brush.z2))/2
					Map3DSystem.Env.Terrain.TerrainModified(brush.x,brush.y, brush.z, radius);
				end	
			elseif(brush.type == "SetHole") then	
				-- set or fill hole 
				local x,z = brush.x,brush.z;
				local radius = brush.radius;
				local tilesize = ParaTerrain.GetAttributeObjectAt(x,z):GetField("size", 533.333);
				local spacing = tilesize/128;	
				local nRadius = math.floor(radius/spacing)
				local nSize = nRadius*2+1;
				local from_x = 0 - nRadius
				local from_y = 0 - nRadius
				local i,j
				for j=from_y, from_y+nSize-1 do
					for i=from_x, from_x+nSize-1 do
						ParaTerrain.SetHole(x+i*spacing, z+j*spacing,brush.bIsHole);
					end
				end
				ParaTerrain.UpdateHoles(x,z);
				Map3DSystem.Env.Terrain.TerrainModified(brush.x,brush.y, brush.z,brush.radius);	
			end
				
		elseif(nServerState == 1) then
			-- this is a server.
			-- tricky: first force local and then broadcast
			msg.forcelocal = true;
			Map3DSystem.SendMessage_env(msg);
			
			server.BroadcastTerrainModify(brush.x,brush.y,brush.z, brush.radius);
		elseif(nServerState == 2) then
			-- this is a client. 
			local cmd;
			if(msg.type == "GaussianHill") then
				cmd = 0;
			elseif(msg.type == "Flatten") then
				cmd = 1;
			elseif(msg.type == "Roughen_Smooth") then	
				if(brush.bRoughen) then
					cmd = 5;
				else
					cmd = 4;
				end
			end
			client.RequestTerrainModify(cmd, brush.x,brush.y,brush.z, brush.radius, brush.height);
		end
		
		-- write to history. 
		if(not msg.SkipHistory) then
			local author = msg.author;
			if(author == nil and not msg.silentmode) then
				-- assume that this is created by the current player
				author = ParaScene.GetPlayer().name;
			end
			if(author~=nil and brush~=nil) then
				local history = Map3DSystem.Env.GetHistory();
				local time = history.env:GetLastTime() or 0;
				-- we will only save non character to history, at the moment. 
				local new_msg = {author = author, brush = commonlib.deepcopy(brush)};
				commonlib.partialcopy(new_msg, msg);
				history.env:AutoAppendKey(time+1, new_msg, true);
				-- log
				--log("History: "..author.." env heightfield \n")
			end	
		end	
				
	elseif(msg.type == Map3DSystem.msg.OCEAN_SET_WATER) then
		---------------------------------------------
		-- ocean modify
		---------------------------------------------
		local nServerState = ParaWorld.GetServerState();
		if(msg.forcelocal or nServerState == 0) then
			-- this is a standalone computer
			if(msg.height~=nil or msg.bEnable~=nil) then
				if(msg.height==nil) then
					msg.height = ParaScene.GetGlobalWaterLevel();
				end
				if(msg.bEnable == nil) then
					msg.bEnable = ParaScene.IsGlobalWaterEnabled();
				end
				ParaScene.SetGlobalWater(msg.bEnable, msg.height);
				if(msg.bEnable) then
					ParaScene.UpdateOcean();
				end
			end	
			if(msg.r~=nil) then
				local att = ParaScene.GetAttributeObjectOcean();
				if(att~=nil) then
					att:SetField("OceanColor", {msg.r, msg.g, msg.b});
				end
			end
			
		elseif(nServerState == 1) then
			-- this is a server. 
			server.BroadcastOceanModify(msg.height,msg.bEnable,msg.r, msg.g, msg.b);
			
		elseif(nServerState == 2) then
			-- this is a client. 
			client.RequestOceanModify(msg.height,msg.bEnable,msg.r, msg.g, msg.b);
		end
		
		-- write to history. 
		if(not msg.SkipHistory) then
			local author = msg.author;
			if(author == nil and not msg.silentmode) then
				-- assume that this is created by the current player
				author = ParaScene.GetPlayer().name;
			end
			if(author~=nil) then
				local history = Map3DSystem.Env.GetHistory();
				local time = history.env:GetLastTime() or 0;
				-- we will only save non character to history, at the moment. 
				local new_msg = {author = author};
				commonlib.partialcopy(new_msg, msg);
				history.env:AutoAppendKey(time+1, new_msg, true);
				-- log
				--log("History: "..author.." env water \n")
			end	
		end	
		
	elseif(msg.type == Map3DSystem.msg.SKY_SET_Sky) then
		---------------------------------------------
		-- sky modify
		---------------------------------------------
		if(not Map3DSystem.User.CheckRight("Sky")) then return end
	
		local nServerState = ParaWorld.GetServerState();
		if(nServerState == 0) then
			-- this is a standalone computer
			if(msg.skybox~=nil and msg.skybox_name~=nil) then
				
				ParaScene.CreateSkyBox (msg.skybox_name or "", ParaAsset.LoadStaticMesh ("", msg.skybox), 160,160,160, 0);
			end	
			
			if(msg.fog_r~=nil)then
				local att = ParaScene.GetAttributeObject();
				if(att~=nil) then
					att:SetField("FogColor", {msg.fog_r, msg.fog_g, msg.fog_b});
				end
			end	
			
			if(msg.sky_r~=nil)then
				local att = ParaScene.GetAttributeObjectSky();
				if(att~=nil) then
					att:SetField("SkyColor", {msg.sky_r, msg.sky_g, msg.sky_b});
				end
			end	
			
			if(msg.timeofday~=nil and Map3DSystem.User.CheckRight("TimeOfDay")) then
				ParaScene.SetTimeOfDaySTD(msg.timeofday);
			end
			
		elseif(nServerState == 1) then
			-- this is a server. 
			--TODO: skybox, sky color and fog color
			if(msg.timeofday~=nil and Map3DSystem.User.CheckRight("TimeOfDay")) then
				server.BroadcastTimeModify(msg.timeofday);
			end
		elseif(nServerState == 2) then
			-- this is a client. 
			--TODO: skybox, sky color and fog color
			if(msg.timeofday~=nil and Map3DSystem.User.CheckRight("TimeOfDay")) then
				client.RequestTimeModify(msg.timeofday);
			end
		end
		
		-- write to history. 
		if(not msg.SkipHistory) then
			local author = msg.author;
			if(author == nil and not msg.silentmode) then
				-- assume that this is created by the current player
				author = ParaScene.GetPlayer().name;
			end
			if(author~=nil) then
				local history = Map3DSystem.Env.GetHistory();
				local time = history.env:GetLastTime() or 0;
				-- we will only save non character to history, at the moment. 
				local new_msg = {author = author};
				commonlib.partialcopy(new_msg, msg);
				history.env:AutoAppendKey(time+1, new_msg, true);
			end	
		end						
	end
end

-- need to be called when terrain height field is modified. It will ask all characters to fall down or snap to the new terrain surface.
function Map3DSystem.Env.Terrain.TerrainModified(x,y,z,radius)
	if(not x or not radius) then
		return
	end
	ParaTerrain.UpdateTerrain();
	--[[ 	for all bipeds, let them fall.
	local player = ParaScene.GetObject("<player>");
	local playerCur = player;
	while(playerCur:IsValid() == true) do
		
		local x,y,z = playerCur:GetPosition();
		local fElev = ParaTerrain.GetElevation(x,z);
		if(fElev<y) then 
			-- let the biped fall to the ground
			playerCur:ToCharacter():FallDown();
		else
			-- terrain is above character, we need to bring the biped up
			-- TODO: this will go wrong for underground bipeds.
			playerCur:SnapToTerrainSurface(0);
		end
		
		playerCur = ParaScene.GetNextObject(playerCur);
		if(playerCur:equals(player) == true) then
			break; -- cycled to the beginning again.
		end
	end]]
	
	ParaScene.OnTerrainChanged(x,z,radius); -- this will do the above code in C++
end

--@param skybox: mesh file name. it can be nil.
--@param r,g,b: sky color in the range [0,1]. they can be nil.
function Map3DSystem.Env.Sky.UpdateSky(skybox, r,g,b)
	if(type(skybox) == "string") then
		ParaScene.CreateSkyBox ("", ParaAsset.LoadStaticMesh ("", skybox), 160,160,160, 0);
	end
	if(r~=nil) then
		local att = ParaScene.GetAttributeObjectSky();
		if(att~=nil) then
			att:SetField("SkyColor", {r, g, b});
		end
	end
end