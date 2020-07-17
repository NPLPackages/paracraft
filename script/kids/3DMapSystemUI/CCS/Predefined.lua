--[[
Title: character customization UI plug-in for 3D Map System
Author(s): WangTian
Date: 2007/10/29
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/CCS/Predefined.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/kids/3DMapSystemUI/CCS/DB.lua");
local DB = commonlib.gettable("Map3DSystem.UI.CCS.DB")
NPL.load("(gl)script/kids/3DMapSystemUI/CCS/DefaultAppearance.lua");
		
local Predefined = commonlib.gettable("Map3DSystem.UI.CCS.Predefined")

function Predefined.SetBaseModel(obj_params, asset_file)

	local obj = ObjEditor.GetObjectByParams(obj_params);
	local playerChar;
	
	-- get player character
	if(obj ~= nil and obj:IsValid() == true) then
		if(obj:IsCharacter() == true) then
			playerChar = obj:ToCharacter();
		end
	end
	
	if(playerChar ~= nil) then
		-- set the base model according to ccs table(base model info part, asset_file)
		
		-- only reset the base model if it is different than the current one. 
		if(asset_file ~=  obj:GetPrimaryAsset():GetKeyName()) then
			local asset = ParaAsset.LoadParaX("", asset_file);
			playerChar:ResetBaseModel(asset);
		end
	else
		log("error: attempt to set a non character base model.\n");
	end
end

-- reset the base model, e.g.
-- Predefined.ResetBaseModel("character/v3/Child/", "Male");
-- Predefined.ResetBaseModel("character/v3/Child/", "Female");
function Predefined.ResetBaseModel(ModelDir, Gender)
	local player, playerChar = DB.GetPlayerChar();
	if(playerChar~=nil) then
		DB.ResetBaseModel(ModelDir, Gender);
		
		Predefined.OnChangeBaseModel(
				Map3DSystem.obj.GetObjectParams("selection"), 
				DB.ModelPath);
		Map3DSystem.UI.CCS.DefaultAppearance.MountDefaultAppearance(player);
	end
	
	-----------------------------
	---- OLD IMPLEMENTATION
	-----------------------------
	--local player, playerChar = DB.GetPlayerChar();
	--if(playerChar~=nil) then
		--DB.ResetBaseModel(ModelDir, Gender);
		--
		---- only reset the base model if it is different than the current one. 
		--if(DB.ModelPath ~=  player:GetPrimaryAsset():GetKeyName()) then
			--local asset = ParaAsset.LoadParaX("", DB.ModelPath);
			--playerChar:ResetBaseModel(asset);
		--end
	--end	
end

-- change the facial info of the current seleceted character
function Predefined.OnChangeBaseModel(obj_params, assetfile)
	local obj = ObjEditor.GetObjectByParams(obj_params);
	local playerChar;
	
	-- get player character
	if(obj ~= nil and obj:IsValid() == true) then
		if(obj:IsCharacter() == true) then
			playerChar = obj:ToCharacter();
		end
	end
	
	if(playerChar ~= nil) then
		-- record the base model(facial info part)
		
		obj_params.AssetFile = assetfile;
		
		-- send object modify message
		Map3DSystem.SendMessage_obj({
				type = Map3DSystem.msg.OBJ_ModifyObject, 
				obj_params = obj_params,
				obj = obj,
				asset_file = obj_params.AssetFile,
				});
	else
		log("error: attempt to set a non character ccs information.\n");
	end
end


-- reset the base model, e.g.
-- Predefined.ResetBaseModel("character/v3/Child/", "Male");
-- Predefined.ResetBaseModel("character/v3/Child/", "Female");
function Predefined.ResetBaseModel2(name, ModelDir, Gender)

	local playerOriginal = ObjEditor.GetCurrentObj();
	local temp = ParaScene.GetObject(name);
	if(temp~=nil and temp:IsValid()==true) then
		if(temp:IsCharacter()) then
		
			ObjEditor.SetCurrentObj(temp);
		end
	end	
	
	local player, playerChar = DB.GetPlayerChar();
	if(playerChar~=nil) then
		DB.ResetBaseModel(ModelDir, Gender);
		
		-- only reset the base model if it is different than the current one. 
		if(DB.ModelPath ~=  player:GetPrimaryAsset():GetKeyName()) then
			local asset = ParaAsset.LoadParaX("", DB.ModelPath);
			playerChar:ResetBaseModel(asset);
		end
	end
	
	ObjEditor.SetCurrentObj(playerOriginal);	
end

Predefined.HairColor = 0;
Predefined.MaxHairColor = 3;
function Predefined.NextHairColor()
	local player, playerChar = DB.GetPlayerChar();
	if(playerChar~=nil) then
		local r = playerChar:GetRaceID();
		local g = playerChar:GetGender();
		Predefined.MaxHairColor = DB.BodyParamIDSet[r][g].HairColorCount;
		Predefined.HairColor = playerChar:GetBodyParams(2); -- BP_HAIRCOLOR
				
		--playerChar:SetDisplayOptions(-1,-1,1);
		Predefined.HairColor = math.mod(Predefined.HairColor+1, Predefined.MaxHairColor);
		if (playerChar:GetBodyParams(3) == 0) then
			--playerChar:SetBodyParams(-1,-1, Predefined.HairColor, 1, -1);
			Predefined.HairStyle = 1;
			Predefined.OnChangeFacialParam(
					Map3DSystem.obj.GetObjectParams("selection"), 
					nil, nil, Predefined.HairColor, 1, nil
					);
		else
			--playerChar:SetBodyParams(-1,-1, Predefined.HairColor, -1, -1);
			Predefined.OnChangeFacialParam(
					Map3DSystem.obj.GetObjectParams("selection"), 
					nil, nil, Predefined.HairColor, nil, nil
					);
		end
	end
end

Predefined.HairStyle = 0;
Predefined.MaxHairStyle = 3;
function Predefined.NextHairStyle()
	local player, playerChar = DB.GetPlayerChar();
	if(playerChar~=nil) then
		local r = playerChar:GetRaceID();
		local g = playerChar:GetGender();
		Predefined.MaxHairStyle = DB.BodyParamIDSet[r][g].HairStyleCount;
		Predefined.HairStyle = playerChar:GetBodyParams(3); -- BP_HAIRSTYLE 
		
		Predefined.HairStyle = math.mod(Predefined.HairStyle+1, Predefined.MaxHairStyle);
		--playerChar:SetBodyParams(-1,-1, -1, Predefined.HairStyle, -1);
		Predefined.OnChangeFacialParam(
				Map3DSystem.obj.GetObjectParams("selection"), 
				nil, nil, nil, Predefined.HairStyle, nil
				);
	end
end


Predefined.FaceType = 0;
Predefined.MaxFaceType = 2;
function Predefined.NextFaceType()
	local player, playerChar = DB.GetPlayerChar();
	if(playerChar~=nil) then
		local r = playerChar:GetRaceID();
		local g = playerChar:GetGender();
		Predefined.MaxFaceType = DB.BodyParamIDSet[r][g].FaceTypeCount;
		Predefined.FaceType = playerChar:GetBodyParams(1); -- BP_FACETYPE 
		Predefined.FaceType = math.mod(Predefined.FaceType+1, Predefined.MaxFaceType);
		--playerChar:SetBodyParams(-1,Predefined.FaceType, -1,-1, 0);
		Predefined.OnChangeFacialParam(
				Map3DSystem.obj.GetObjectParams("selection"), 
				nil, Predefined.FaceType, nil, nil, nil
				);
	end
end

function Predefined.GetFacialInfo(obj_params)
	
	local obj = ObjEditor.GetObjectByParams(obj_params);
	local playerChar;
	
	-- get player character
	if(obj ~= nil and obj:IsValid() == true) then
		if(obj:IsCharacter() == true) then
			playerChar = obj:ToCharacter();
		end
	end
	
	if(playerChar ~= nil and playerChar:IsCustomModel() == true) then
		-- set the faical parameter according to ccs table(facial info part)
		
		local facial_info = {
			skinColor = playerChar:GetBodyParams(0),
			faceType = playerChar:GetBodyParams(1),
			hairColor = playerChar:GetBodyParams(2),
			hairStyle = playerChar:GetBodyParams(3),
			facialHair = playerChar:GetBodyParams(4),
		};
		
		return facial_info;
	else
		log("error: attempt to set a non character ccs information or non custom character.\n");
	end
end

-- get the facial information string from the obj_param
-- @param obj_param: object parameter(table) or ParaObject object
-- @return: the facial info string if CCS character
--		or nil if no facial information is found
function Predefined.GetFacialInfoString(obj_params)
	
	local obj;
	local playerChar;
	
	if(type(obj_params) == "userdata") then
		obj = obj_params;
	elseif(type(obj_params) == "table") then
		obj = ObjEditor.GetObjectByParams(obj_params);
	else
		log("error: obj_params not table or userdata value.\n");
		return;
	end
	
	-- get player character
	if(obj ~= nil and obj:IsValid() == true) then
		if(obj:IsCharacter() == true) then
			playerChar = obj:ToCharacter();
		end
	end
	
	if(playerChar ~= nil and playerChar:IsCustomModel() == true) then
		-- set the faical parameter according to ccs table(facial info part)
		return string.format("%d#%d#%d#%d#%d#", playerChar:GetBodyParams(0), playerChar:GetBodyParams(1), playerChar:GetBodyParams(2), playerChar:GetBodyParams(3), playerChar:GetBodyParams(4));
	else
		--log("error: attempt to get a non character ccs information or non custom character.\n");
		return nil;
	end
end

-- apply the facial information string to the obj_param object
-- @param obj_param: object parameter(table) or ParaObject object
-- @param sInfo: ccs information string
-- NOTE: Facial information string is the first section of the full CCS information string
function Predefined.ApplyFacialInfoString(obj_params, sInfo)
	
	local obj;
	local playerChar;
	
	if(type(obj_params) == "userdata") then
		obj = obj_params;
	elseif(type(obj_params) == "table") then
		obj = ObjEditor.GetObjectByParams(obj_params);
	else
		log("error: obj_params not table or userdata value.\n");
		return;
	end
	
	-- get player character
	if(obj ~= nil and obj:IsValid() == true) then
		if(obj:IsCharacter() == true) then
			playerChar = obj:ToCharacter();
		end
	end
	
	if(playerChar ~= nil and playerChar:IsCustomModel()) then
		-- set the faical parameter according to ccs table(facial info part)
		local skinColor, faceType, hairColor, hairStyle, facialHair = string.match(sInfo, "([^#]+)#([^#]+)#([^#]+)#([^#]+)#([^#]+)#");
		if(facialHair) then
			playerChar:SetBodyParams(tonumber(skinColor), tonumber(faceType), tonumber(hairColor), tonumber(hairStyle), tonumber(facialHair));
		end	
	else
		--log("error: attempt to set a non character ccs information or non custom character.\n");
	end
end

function Predefined.SetFacialInfo(obj_params, facial_info)
	
	local obj = ObjEditor.GetObjectByParams(obj_params);
	local playerChar;
	
	-- get player character
	if(obj ~= nil and obj:IsValid() == true) then
		if(obj:IsCharacter() == true) then
			playerChar = obj:ToCharacter();
		end
	end
	
	if(playerChar ~= nil) then
		-- set the faical parameter according to ccs table(facial info part)
		playerChar:SetBodyParams(
				facial_info.skinColor or -1, 
				facial_info.faceType or -1, 
				facial_info.hairColor or -1, 
				facial_info.hairStyle or -1, 
				facial_info.facialHair or -1);
		
		-- TODO: play animation according to ccs change
		
	else
		log("error: attempt to set a non character ccs information.\n");
	end
end

-- change the facial info of the current seleceted character
function Predefined.OnChangeFacialParam(obj_params, skinColor, faceType, hairColor, hairStyle, facialHair)
	local obj = ObjEditor.GetObjectByParams(obj_params);
	local playerChar;
	
	-- get player character
	if(obj ~= nil and obj:IsValid() == true) then
		if(obj:IsCharacter() == true) then
			playerChar = obj:ToCharacter();
		end
	end
	
	if(playerChar ~= nil) then
		-- record the ccs table(facial info part)
		local _ccsTable = {
			skinColor = skinColor,
			faceType = faceType,
			hairColor = hairColor,
			hairStyle = hairStyle,
			facialHair = facialHair,
		};
		
		-- send object modify message
		Map3DSystem.SendMessage_obj({
				type = Map3DSystem.msg.OBJ_ModifyObject, 
				obj = obj,
				obj_params = obj_params,
				facial_info = _ccsTable,
				});
	else
		log("error: attempt to set a non character ccs information.\n");
	end
end

Predefined.CartoonFaceType = 1;
--Predefined.MaxCartoonFaceType = 2;
function Predefined.NextCartoonFaceType()
	--local player, playerChar = DB.GetPlayerChar();
	--if(playerChar:GetGender() == 0 and playerChar:GetRace() == 2) then
		--Predefined.MaxCartoonFaceType = 1;
	--end
	--if(playerChar~=nil) then
		--playerChar:SetBodyParams(-1,-1, -1,-1, Predefined.CartoonFaceType);
		--Predefined.CartoonFaceType = 1+math.mod(Predefined.CartoonFaceType, Predefined.MaxCartoonFaceType);
	--end
end


-- CurrentFaceType == "CartoonFace": cartoon face
-- CurrentFaceType == "CharacterFace": character face
Predefined.CurrentFaceType = "CharacterFace";

function Predefined.ToggleFace()
	local player, playerChar = DB.GetPlayerChar();
	if (Predefined.CurrentFaceType == "CartoonFace") then
		-- set to character face
		Predefined.CurrentFaceType = "CharacterFace";
		playerChar:SetBodyParams(-1,Predefined.FaceType, -1,-1, 0);
		local obj = ObjEditor.GetCurrentObj();
		headon_speech.Speek(obj.name, "我可以更换人物脸型了...", 2);
	elseif (Predefined.CurrentFaceType == "CharacterFace") then
		-- set to cartoon face
		Predefined.CurrentFaceType = "CartoonFace";
		playerChar:SetBodyParams(-1,-1, -1,-1, Predefined.CartoonFaceType);
		local obj = ObjEditor.GetCurrentObj();
		headon_speech.Speek(obj.name, "我可以编辑卡通脸了...", 2);
	end
end


-- itemid: it can be nil to iterate through all available ones in the database
function Predefined.ShowNextShirt(itemid)
	local player, playerChar = DB.GetPlayerChar();
	if(playerChar~=nil) then
		
		if(not itemid) then
			-- TODO: iterate through all available ones in the database
			-- test 2 is a shirt
			local samples = DB.GetItemIdListByType(DB.IT_SHIRT);
			if(not Predefined.ShirtType) then
				Predefined.ShirtType = 0;
			else
				Predefined.ShirtType = math.mod(Predefined.ShirtType+1, table.getn(samples));
			end	
			itemid = samples[Predefined.ShirtType+1];
		end
		playerChar:SetCharacterSlot(DB.CS_SHIRT, itemid);
	end
end


-- IsleftHand: nil if right hand, otherwise left one
-- itemid: it can be nil to iterate through all available ones in the database
function Predefined.ShowNextHandSlot(IsleftHand, itemid)
	local player, playerChar = DB.GetPlayerChar();
	if(playerChar~=nil) then
		
		if(not itemid) then
			-- TODO: iterate through all available ones in the database
			local samples = DB.GetItemIdListByType(DB.IT_1HANDED);
			if(not Predefined.WeaponType) then
				Predefined.WeaponType = 0;
			else
				Predefined.WeaponType = math.mod(Predefined.WeaponType+1, table.getn(samples));
			end	
			itemid = samples[Predefined.WeaponType+1];
		end
		if(not IsleftHand) then
			playerChar:SetCharacterSlot(DB.CS_HAND_RIGHT, itemid);
		else
			playerChar:SetCharacterSlot(DB.CS_HAND_LEFT, itemid);
		end	
	end
end

-- itemid: it can be nil to iterate through all available ones in the database
function Predefined.ShowNextCape(itemid)
	local player, playerChar = DB.GetPlayerChar();
	if(playerChar~=nil) then
		
		if(not itemid) then
			-- TODO: iterate through all available ones in the database
			local samples = DB.GetItemIdListByType(DB.IT_CAPE);
			if(not Predefined.CapeType) then
				Predefined.CapeType = 0;
			else
				Predefined.CapeType = math.mod(Predefined.CapeType+1, table.getn(samples));
			end	
			itemid = samples[Predefined.CapeType+1];
		end
		playerChar:SetCharacterSlot(DB.CS_CAPE, itemid);
	end
end

-- itemid: it can be nil to iterate through all available ones in the database
function Predefined.ShowNextHeadAtt(itemid)
	local player, playerChar = DB.GetPlayerChar();
	if(playerChar~=nil) then
		
		if(not itemid) then
			-- TODO: iterate through all available ones in the database
			local samples = DB.GetItemIdListByType(DB.IT_HEAD);
			if(not Predefined.HeadAttType) then
				Predefined.HeadAttType = 0;
			else
				Predefined.HeadAttType = math.mod(Predefined.HeadAttType+1, table.getn(samples));
			end	
			itemid = samples[Predefined.HeadAttType+1];
		end
		playerChar:SetCharacterSlot(DB.CS_HEAD, itemid);
	end
end

-- itemid: it can be nil to iterate through all available ones in the database
function Predefined.ShowNextShoulderAtt(itemid)
	local player, playerChar = DB.GetPlayerChar();
	if(playerChar~=nil) then
		
		if(not itemid) then
			-- TODO: iterate through all available ones in the database
			local samples = {
				0, 7, -- some test item id
			}
			if(not Predefined.ShoulderAttType) then
				Predefined.ShoulderAttType = 0;
			else
				Predefined.ShoulderAttType = math.mod(Predefined.ShoulderAttType+1, table.getn(samples));
			end	
			itemid = samples[Predefined.ShoulderAttType+1];
		end
		playerChar:SetCharacterSlot(DB.CS_SHOULDER, itemid);
	end
end

