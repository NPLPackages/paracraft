--[[
Title: character customization database for 3D Map System
Author(s): WangTian
Date: 2007/10/29, refactored  2008.6.12 lxz
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/CCS/DB.lua");
local DB = Map3DSystem.UI.CCS.DB
-------------------------------------------------------
]]

---- common control library
NPL.load("(gl)script/sqlite/sqlite3.lua");

local DB = commonlib.gettable("Map3DSystem.UI.CCS.DB")

DB.BodyParamIDSet = {};

DB.dbfile = "Database/characters.db";
DB.ModelDir = "character/v3/Child/";
DB.Gender= "Male";
DB.ItemObjectPath = "character/v3/Item/ObjectComponents/";
DB.ItemTexturePath = "character/v3/Item/TextureComponents/";
DB.ItemIdLists = {};
DB.ItemIdSlotLists = {};
DB.FaceStyleLists = {};
DB.FaceIconLists = {};
DB.FaceStyleIterators = {};

DB.CurrentCharacterInfo = {};

-- the following are calculated
DB.ModelName = "Child";
DB.ModelPath = "character/v3/Child/Male/ChildMale.x";

-- character slots
DB.CS_HEAD =0;
DB.CS_NECK = 1;
DB.CS_SHOULDER = 2;
DB.CS_BOOTS = 3;
DB.CS_BELT = 4;
DB.CS_SHIRT = 5;
DB.CS_PANTS = 6;
DB.CS_CHEST = 7;
DB.CS_BRACERS = 8;
DB.CS_GLOVES = 9;
DB.CS_HAND_RIGHT = 10;
DB.CS_HAND_LEFT = 11;
DB.CS_CAPE = 12;
DB.CS_TABARD = 13;

-- item types
DB.IT_HEAD = 1;
DB.IT_NECK=2;--脖子
DB.IT_SHOULDER=3;-- 肩
DB.IT_SHIRT=4;-- 上衣
DB.IT_CHEST=5;-- 胸
DB.IT_BELT=6;
DB.IT_PANTS=7;-- 裤子
DB.IT_BOOTS=8; -- 鞋子
DB.IT_BRACERS=9;
DB.IT_GLOVES=10;-- 手套
DB.IT_RINGS=11;
DB.IT_OFFHAND=12;
DB.IT_DAGGER=13;
DB.IT_SHIELD=14;
DB.IT_BOW=15;
DB.IT_CAPE=16; -- 披风
DB.IT_2HANDED=17;-- 双手
DB.IT_QUIVER=18;
DB.IT_TABARD=19;
DB.IT_ROBE=20;
DB.IT_1HANDED=21;-- 单手
DB.IT_CLAW=22;
DB.IT_ACCESSORY=23;
DB.IT_THROWN=24;
DB.IT_GUN=25;

-- cartoon face component
DB.CFS_FACE = 0;
DB.CFS_WRINKLE = 1;
DB.CFS_EYE = 2;
DB.CFS_EYEBROW = 3;
DB.CFS_MOUTH = 4;
DB.CFS_NOSE = 5;
DB.CFS_MARKS = 6;

-- cartoon face sub type
DB.CFS_SUB_Style = 0;
DB.CFS_SUB_Color = 1;
DB.CFS_SUB_Scale = 2;
DB.CFS_SUB_Rotation = 3;
DB.CFS_SUB_X = 4;
DB.CFS_SUB_Y = 5;


-- read facial table information
function DB.InitBodyParamIDSet()
	local i;
	local nFT_M, nFT_F;
	local nHS_M, nHS_F;
	local nHC_M, nHC_F;
	local row;
	local temp;
	local db = sqlite3.open(DB.dbfile);
	
	for row in db:rows("select RaceID, Name from CharRacesDB") do
		
		-- read face information
		i = 0;
		for temp in db:rows("select Section from CharSectionsDB where Race = "..row.RaceID.." and Gender = 1 and Type = 1") do
			i = i+1;
		end
		nFT_F = i;
		
		i = 0;
		for temp in db:rows("select Section from CharSectionsDB where Race = "..row.RaceID.." and Gender = 0 and Type = 1") do
			i = i+1;
		end
		nFT_M = i;
		
		-- read hair information
		i = 0;
		for temp in db:rows("select Section from CharHairGeosetsDB where Race = "..row.RaceID.." and Gender = 1") do
			i = i+1;
		end
		nHS_F = i;
		
		i = 0;
		for temp in db:rows("select Section from CharHairGeosetsDB where Race = "..row.RaceID.." and Gender = 0") do
			i = i+1;
		end
		nHS_M = i;
		
		-- read hair color information
		i = 0;
		for temp in db:rows("select Section from CharSectionsDB where Race = "..row.RaceID.." and Gender = 1 and Type = 3") do
			i = i+1;
		end
		if(nHS_F == 0) then
			nHC_F = 0
		else
			nHC_F = i / (nHS_F - 1);
		end
		
		i = 0;
		for temp in db:rows("select Section from CharSectionsDB where Race = "..row.RaceID.." and Gender = 0 and Type = 3") do
			i = i+1;
		end
		if(nHS_M == 0) then
			nHC_M = 0
		else
			nHC_M = i / (nHS_M - 1);
		end
		
		-- write to BodyParamIDSet table
		DB.BodyParamIDSet[tonumber(row.RaceID)] = {
			Name = tostring(row.Name);
			[1] = {
				FaceTypeCount = nFT_F,
				HairStyleCount = nHS_F,
				HairColorCount = nHC_F,
				}, -- female
			[0] = {
				FaceTypeCount = nFT_M,
				HairStyleCount = nHS_M,
				HairColorCount = nHC_M,
				}, -- male
			};
	end
	
	--NPL.load("(gl)script/kids/3DMapSystem_Misc.lua");
	--Map3DSystem.Misc.SaveTableToFile(DB.BodyParamIDSet, "TestTable/BodyParamIDSet.ini");
		
	db:close();
end

-- reset the base model
function DB.ResetBaseModel(ModelDir, Gender)
	DB.ModelDir = ModelDir;
	DB.Gender = Gender;
	
	-- calculate other paths.
	DB.ModelName = string.gsub(ModelDir, ".*/(.-)/$", "%1");
	DB.ModelPath = string.format("%s%s/%s%s.x", ModelDir, Gender, DB.ModelName, Gender);
end

-- e.g. local player, playerChar = DB.GetPlayerChar();
function DB.GetPlayerChar()
	local player = ObjEditor.GetCurrentObj();
	if(player~=nil and player:IsValid()==true) then
		if(player:IsCharacter()) then
			local playerChar = player:ToCharacter();
			return player, playerChar;
		end
	end	
end


-- return a table containing a list of IDs for a given item type;the last one is always 0
-- @param Type: item types such as DB.IT_CAPE
function DB.GetItemIdListByType(type)
	if(not DB.ItemIdLists[type]) then
		-- only fetch on demand and if it has never been fetched before.
		local result = {};
		local i=1;
		local db = sqlite3.open(DB.dbfile);
		local row;
		for row in db:rows(string.format("select id from ItemDatabase where type=%d",type)) do
			result[i] = tonumber(row.id);
			i = i+1;
		end
		result[i] = 0; -- the last one is always 0, which means no item.
		
		db:close();
		DB.ItemIdLists[type] = result;
	end
	return DB.ItemIdLists[type];
end


-- return a table containing a list of IDs for a given item type;the last one is always 0
-- @param Type: item types such as DB.CS_HAND_RIGHT
function DB.GetItemIdListBySlotType(type)
	if(not DB.ItemIdSlotLists[type]) then
		-- only fetch on demand and if it has never been fetched before.
		local result = {};
		local i=1;
		local db = sqlite3.open(DB.dbfile);
		local row;
		local typeStr;

		if(type == DB.CS_HEAD) then
			typeStr = "1";
		elseif(type == DB.CS_NECK) then
			typeStr = "2";
		elseif(type == DB.CS_SHOULDER) then
			typeStr = "3";
		elseif(type == DB.CS_BOOTS) then
			typeStr = "8";
		elseif(type == DB.CS_BELT) then
			typeStr = "6";
		elseif(type == DB.CS_SHIRT) then
			typeStr = "4";
		elseif(type == DB.CS_PANTS) then
			typeStr = "7";
		elseif(type == DB.CS_CHEST) then
			typeStr = "5".." or ".."type = 20";
		elseif(type == DB.CS_BRACERS) then
			typeStr = "9";
		elseif(type == DB.CS_GLOVES) then
			typeStr = "10";
		elseif(type == DB.CS_HAND_RIGHT) then
			typeStr = "11".." or ".."type = 13"
				.." or ".."type = 15".." or ".."type = 21"
				.." or ".."type = 22".." or ".."type = 24"
				.." or ".."type = 25";
		elseif(type == DB.CS_HAND_LEFT) then
			typeStr = "11".." or ".."type = 12"
				.." or ".."type = 13".." or ".."type = 14"
				.." or ".."type = 18".." or ".."type = 21"
				.." or ".."type = 22".." or ".."type = 23"
				.." or ".."type = 24".." or ".."type = 25";
		elseif(type == DB.CS_CAPE) then
			typeStr = "16";
		elseif(type == DB.CS_TABARD) then
			typeStr = "19";
		end
		
		for row in db:rows(string.format("select id from ItemDatabase where type=%s", typeStr)) do
			result[i] = tonumber(row.id);
			i = i+1;
		end
		--result[i] = 0; -- the last one is always 0, which means no item.
		
		db:close();
		DB.ItemIdSlotLists[type] = result;
	end
	return DB.ItemIdSlotLists[type];
end

-- return a table containing a list of style IDs for the given face component
-- @param nComponentID: such as DB.CFS_FACE
function DB.GetFaceComponentStyleList(nComponentID)
	if(not DB.FaceStyleLists[nComponentID]) then
		-- only fetch on demand and if it has never been fetched before.
		local result = {};
		local i=1;
		local db = sqlite3.open(DB.dbfile);
		local row;
		for row in db:rows(string.format("select Style from CartoonFaceDB where Type=%d", nComponentID)) do
			result[i] = tonumber(row.Style);
			i = i+1;
		end
		
		db:close();
		DB.FaceStyleLists[nComponentID] = result;
	end
	return DB.FaceStyleLists[nComponentID];
end

-- return a table containing a list of Icon path for the given face component
-- @param nComponentID: such as DB.CFS_FACE
function DB.GetFaceComponentIconList(nComponentID)
	if(not DB.FaceIconLists[nComponentID]) then
		-- only fetch on demand and if it has never been fetched before.
		local result = {};
		local i=1;
		local db = sqlite3.open(DB.dbfile);
		local row;
		for row in db:rows(string.format("select Icon from CartoonFaceDB where Type=%d",nComponentID)) do
			if(row.Icon == nil or row.Icon == "") then
				result[i] = tostring(row.Tex1); -- directly use the face component texture as the icon
			else
				result[i] = tostring(row.Icon);
			end
			i = i+1;
		end
		db:close();
		DB.FaceIconLists[nComponentID] = result;
	end
	return DB.FaceIconLists[nComponentID];
end


-- set the face component parameters
-- e.g. DB.SetFaceComponent(DB.CFS_EYE, DB.CFS_SUB_Scale, 0.1);
-- @param nComponentID: such as DB.CFS_FACE
-- @param SubType: such as DB.CFS_SUB_Scale, if this is nil, it will call ResetFaceComponent() instead
-- 0: style: int [0,00]
-- 1: color: 32bits ARGB
-- 2: scale: float in [-1,1]
-- 3: rotation: float in (-3.14,3.14]
-- 4: x: (-128,128]
-- 5: y: (-128,128]
-- @param value: it is abolute for face type and color, and delta value for all other types.
--   if SubType is style and value is nil, it will automatically select the next style
-- @param refreshModel: if nil, it will automatically refresh the character model, otherwise it will not refresh the model.
function DB.SetFaceComponent(nComponentID, SubType, value)
	local player, playerChar = DB.GetPlayerChar();
	if(playerChar~=nil) then
		if(not SubType) then
			return DB.ResetFaceComponent(nComponentID);
		end
		if(not value)then
			if(SubType == DB.CFS_SUB_Style) then
				-- iterate through all available ones in the database
				local samples = DB.GetFaceComponentStyleList(nComponentID);
				if(not DB.FaceStyleIterators[nComponentID]) then
					DB.FaceStyleIterators[nComponentID] = 0;
				else
					DB.FaceStyleIterators[nComponentID] = math.mod(DB.FaceStyleIterators[nComponentID]+1, table.getn(samples));
				end	
				value = samples[DB.FaceStyleIterators[nComponentID]+1];
			else
				return
			end
		end
			
		if(SubType == DB.CFS_SUB_Style or SubType == DB.CFS_SUB_Color) then
			-- value is absolute
			--playerChar:SetCartoonFaceComponent(nComponentID, SubType, value);
			DB.OnChangeCartoonFace(
					Map3DSystem.obj.GetObjectParams("selection"), 
					nComponentID, 
					SubType, 
					value);
		else
			-- value is delta
			local oldvalue = playerChar:GetCartoonFaceComponent(nComponentID, SubType);
			--playerChar:SetCartoonFaceComponent(nComponentID, SubType, value+oldvalue);
			DB.OnChangeCartoonFace(
					Map3DSystem.obj.GetObjectParams("selection"), 
					nComponentID, 
					SubType, 
					value + oldvalue);
		end	
	end
end

function DB.GetCartoonfaceInfo(obj_params)

	local obj = ObjEditor.GetObjectByParams(obj_params);
	local playerChar;
	
	-- get player character
	if(obj ~= nil and obj:IsValid() == true) then
		if(obj:IsCharacter() == true) then
			playerChar = obj:ToCharacter();
		end
	end
	
	if(playerChar ~= nil and playerChar:IsSupportCartoonFace() == true ) then
		-- get the cartoon face parameter according to ccs table(cartoon face info part)
		
		local cartoonface_info = {};
		
		local nComponentID, SubType;
		for nComponentID = 0, 6 do
			for SubType = 0, 5 do
				
				local componentString;
				local subtypeString;
				
				if(nComponentID == 0) then
					componentString = "Face";
				elseif(nComponentID == 1) then
					componentString = "Wrinkle";
				elseif(nComponentID == 2) then
					componentString = "Eye";
				elseif(nComponentID == 3) then
					componentString = "Eyebrow";
				elseif(nComponentID == 4) then
					componentString = "Mouth";
				elseif(nComponentID == 5) then
					componentString = "Nose";
				elseif(nComponentID == 6) then
					componentString = "Marks";
				end
				
				if(SubType == 0) then
					subtypeString = "Type";
				elseif(SubType == 1) then
					subtypeString = "Color";
				elseif(SubType == 2) then
					subtypeString = "Scale";
				elseif(SubType == 3) then
					subtypeString = "Rotation";
				elseif(SubType == 4) then
					subtypeString = "X";
				elseif(SubType == 5) then
					subtypeString = "Y";
				end
				
				local value = playerChar:GetCartoonFaceComponent(nComponentID, SubType);
				cartoonface_info["cartoonFace_"..componentString.."_"..subtypeString] = value;
			end -- for SubType = 0, 5 do
		end -- for nComponentID = 0, 6 do
		
		return cartoonface_info;
	else
		log("error: attempt to get a non character ccs information or character don't support cartoon face.\n");
	end
end


-- get the cartoon face info string from the obj_param
-- @param obj_param: object parameter(table) or ParaObject object
-- @return: the cartoon face string if CCS character with cartoon face
--		or nil if no cartoon face information is found
function DB.GetCartoonfaceInfoString(obj_params)
	
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
	
	if(playerChar ~= nil and playerChar:IsSupportCartoonFace() == true ) then
		-- get the cartoon face parameter according to ccs table(cartoon face info part)
		
		local sInfo = "";
		
		local nComponentID, SubType;
		for nComponentID = 0, 6 do
			for SubType = 0, 5 do
				
				local value = playerChar:GetCartoonFaceComponent(nComponentID, SubType);
				--if(value == 4294967295) then
				-- I think it is a minor bug that 0xffffffff is sometimes converted to 4294967296, instead of 4294967295 randomly. 
				if(value >= 4294967295) then
					value = "F";
				end
				sInfo = sInfo..value.."#";
				
			end -- for SubType = 0, 5 do
		end -- for nComponentID = 0, 6 do
		
		return sInfo;
	else
		--log("error: attempt to get a non character ccs information or character don't support cartoon face.\n");
		return nil;
	end
end

function DB.ApplyCartoonfaceInfoString(obj_params, sInfo, isSkipMask)

	local obj;
	local playerChar;
	
	if(type(obj_params) == "table") then
		obj = ObjEditor.GetObjectByParams(obj_params);
	elseif(type(obj_params) == "userdata") then
		obj = obj_params;
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
	
	-- NOTE: original implementation will check the cartoonface, while canvas:3d in LocalUserSelectPage.html will not pass the cartoonface check
	-- if(playerChar ~= nil and playerChar:IsSupportCartoonFace() == true ) then
	if(playerChar ~= nil and sInfo) then
		-- get the cartoon face parameter according to ccs table(cartoon face info part)
		
		local nComponentID = 0;
		local SubType = 0;
		local value;
		for value in string.gfind(sInfo, "([^#]+)") do
			if(value == "F") then
				value = "4294967295";
			end
			if(not(isSkipMask == true and nComponentID == 6)) then
				value = tonumber(value);
				if(value) then
					playerChar:SetCartoonFaceComponent(nComponentID, SubType, value);
				end
			end
			
			SubType = SubType + 1;
			
			if(SubType == 6) then
				SubType = 0;
				nComponentID = nComponentID + 1;
			end
		end
	else
		--log("error: attempt to set a non character ccs information or character don't support cartoon face.\n");
	end
end

function DB.SetCartoonfaceInfo(obj_params, cartoonface_info)

	local obj = ObjEditor.GetObjectByParams(obj_params);
	local playerChar;
	
	-- get player character
	if(obj ~= nil and obj:IsValid() == true) then
		if(obj:IsCharacter() == true) then
			playerChar = obj:ToCharacter();
		end
	end
	
	if(playerChar ~= nil) then
		-- set the cartoon face parameter according to ccs table(cartoon face info part)
		local k, v;
		for k, v in pairs(cartoonface_info) do
			
			if(type(k) == "string") then
				local _underlingFirst = string.find(k, "_", 1);
				local _underlingSecond = string.find(k, "_", _underlingFirst + 1);
				
				local componentString = string.sub(k, _underlingFirst + 1, _underlingSecond - 1);
				local subtypeString = string.sub(k, _underlingSecond + 1);
				
				local nComponentID, SubType;
				if(componentString == "Face") then
					nComponentID = 0;
				elseif(componentString == "Wrinkle") then
					nComponentID = 1;
				elseif(componentString == "Eye") then
					nComponentID = 2;
				elseif(componentString == "Eyebrow") then
					nComponentID = 3;
				elseif(componentString == "Mouth") then
					nComponentID = 4;
				elseif(componentString == "Nose") then
					nComponentID = 5;
				elseif(componentString == "Marks") then
					nComponentID = 6;
				end
				
				if(subtypeString == "Type") then
					SubType = 0;
				elseif(subtypeString == "Color") then
					SubType = 1;
				elseif(subtypeString == "Scale") then
					SubType = 2;
				elseif(subtypeString == "Rotation") then
					SubType = 3;
				elseif(subtypeString == "X") then
					SubType = 4;
				elseif(subtypeString == "Y") then
					SubType = 5;
				end
				
				playerChar:SetCartoonFaceComponent(nComponentID, SubType, v);
			end
		end
		
		-- TODO: play animation according to ccs change
	else
		log("error: attempt to set a non character ccs information.\n");
	end
end

-- change the cartoon face info of the current seleceted character
function DB.OnChangeCartoonFace(obj_params, nComponentID, SubType, value)
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
		local _ccsTable = {};
		
		local componentString;
		local subtypeString;
		
		if(nComponentID == 0) then
			componentString = "Face";
		elseif(nComponentID == 1) then
			componentString = "Wrinkle";
		elseif(nComponentID == 2) then
			componentString = "Eye";
		elseif(nComponentID == 3) then
			componentString = "Eyebrow";
		elseif(nComponentID == 4) then
			componentString = "Mouth";
		elseif(nComponentID == 5) then
			componentString = "Nose";
		elseif(nComponentID == 6) then
			componentString = "Marks";
		end
		
		if(SubType == 0) then
			subtypeString = "Type";
		elseif(SubType == 1) then
			subtypeString = "Color";
		elseif(SubType == 2) then
			subtypeString = "Scale";
		elseif(SubType == 3) then
			subtypeString = "Rotation";
		elseif(SubType == 4) then
			subtypeString = "X";
		elseif(SubType == 5) then
			subtypeString = "Y";
		end
		
		_ccsTable["cartoonFace_"..componentString.."_"..subtypeString] = value;
		
		-- send object modify message
		Map3DSystem.SendMessage_obj({
				type = Map3DSystem.msg.OBJ_ModifyObject, 
				obj_params = obj_params,
				cartoonface_info = _ccsTable,
				});
	else
		log("error: attempt to set a non character ccs information.\n");
	end
end

-- reset the given face component to default value
function DB.ResetFaceComponent(nComponentID)
	local player, playerChar = DB.GetPlayerChar();
	if(playerChar~=nil) then
		
		--playerChar:SetCartoonFaceComponent(nComponentID, DB.CFS_SUB_Color, _guihelper.RGBA_TO_DWORD(255,255,255));
		--playerChar:SetCartoonFaceComponent(nComponentID, DB.CFS_SUB_Scale, 0);
		--playerChar:SetCartoonFaceComponent(nComponentID, DB.CFS_SUB_Rotation, 0);
		--playerChar:SetCartoonFaceComponent(nComponentID, DB.CFS_SUB_X, 0);
		--playerChar:SetCartoonFaceComponent(nComponentID, DB.CFS_SUB_Y, 0);
		
		DB.OnChangeCartoonFace(
				Map3DSystem.obj.GetObjectParams("selection"), 
				nComponentID, 
				DB.CFS_SUB_Color, 
				_guihelper.RGBA_TO_DWORD(255,255,255));
		DB.OnChangeCartoonFace(
				Map3DSystem.obj.GetObjectParams("selection"), 
				nComponentID, 
				DB.CFS_SUB_Scale, 
				0);
		DB.OnChangeCartoonFace(
				Map3DSystem.obj.GetObjectParams("selection"), 
				nComponentID, 
				DB.CFS_SUB_Rotation, 
				0);
		DB.OnChangeCartoonFace(
				Map3DSystem.obj.GetObjectParams("selection"), 
				nComponentID, 
				DB.CFS_SUB_X, 
				0);
		DB.OnChangeCartoonFace(
				Map3DSystem.obj.GetObjectParams("selection"), 
				nComponentID, 
				DB.CFS_SUB_Y, 
				0);
	end
end

function DB.SaveCurrentCharacterCCSInfo()

	DB.LoadIdentityCurrentCharacterInfo();
	
	local player, playerChar = DB.GetPlayerChar();
	
	if(player ~= nil and player:IsValid()==true) then
		if(player:IsCharacter()==true and playerChar:IsCustomModel()==true) then
			DB.CurrentCharacterInfo.skinColor = playerChar:GetBodyParams(0);
			DB.CurrentCharacterInfo.faceType = playerChar:GetBodyParams(1);
			DB.CurrentCharacterInfo.hairColor = playerChar:GetBodyParams(2);
			DB.CurrentCharacterInfo.hairStyle = playerChar:GetBodyParams(3);
			DB.CurrentCharacterInfo.facialHair = playerChar:GetBodyParams(4);
			
			DB.CurrentCharacterInfo.itemHead = playerChar:GetCharacterSlotItemID(0);
			DB.CurrentCharacterInfo.itemNeck = playerChar:GetCharacterSlotItemID(1);
			DB.CurrentCharacterInfo.itemShoulder = playerChar:GetCharacterSlotItemID(2);
			DB.CurrentCharacterInfo.itemBoots = playerChar:GetCharacterSlotItemID(3);
			DB.CurrentCharacterInfo.itemBelt = playerChar:GetCharacterSlotItemID(4);
			DB.CurrentCharacterInfo.itemShirt = playerChar:GetCharacterSlotItemID(5);
			DB.CurrentCharacterInfo.itemPants = playerChar:GetCharacterSlotItemID(6);
			DB.CurrentCharacterInfo.itemChest = playerChar:GetCharacterSlotItemID(7);
			DB.CurrentCharacterInfo.itemBracers = playerChar:GetCharacterSlotItemID(8);
			DB.CurrentCharacterInfo.itemGloves = playerChar:GetCharacterSlotItemID(9);
			DB.CurrentCharacterInfo.itemHandRight = playerChar:GetCharacterSlotItemID(10);
			DB.CurrentCharacterInfo.itemHandLeft = playerChar:GetCharacterSlotItemID(11);
			DB.CurrentCharacterInfo.itemCape = playerChar:GetCharacterSlotItemID(12);
			DB.CurrentCharacterInfo.itemTabard = playerChar:GetCharacterSlotItemID(13);
			
			-- TODO: race and gender
			DB.CurrentCharacterInfo.gender = playerChar:GetGender();
			DB.CurrentCharacterInfo.raceId = playerChar:GetRaceID();
			
			DB.CurrentCharacterInfo.IsCustomModel = true;
		else
			DB.CurrentCharacterInfo.IsCustomModel = false;
			DB.CurrentCharacterInfo.ModelName = "ModelName";
		end
			
		if(player:IsCharacter()==true and playerChar:IsSupportCartoonFace()==true) then
			DB.CurrentCharacterInfo.cartoonFaceType = playerChar:GetCartoonFaceComponent(0, 0);
			DB.CurrentCharacterInfo.cartoonFaceColor = playerChar:GetCartoonFaceComponent(0, 1);
			DB.CurrentCharacterInfo.cartoonFaceScale = playerChar:GetCartoonFaceComponent(0, 2);
			DB.CurrentCharacterInfo.cartoonFaceRotation = playerChar:GetCartoonFaceComponent(0, 3);
			DB.CurrentCharacterInfo.cartoonFaceX = playerChar:GetCartoonFaceComponent(0, 4);
			DB.CurrentCharacterInfo.cartoonFaceY = playerChar:GetCartoonFaceComponent(0, 5);
			
			DB.CurrentCharacterInfo.cartoonWrinkleType = playerChar:GetCartoonFaceComponent(1, 0);
			DB.CurrentCharacterInfo.cartoonWrinkleColor = playerChar:GetCartoonFaceComponent(1, 1);
			DB.CurrentCharacterInfo.cartoonWrinkleScale = playerChar:GetCartoonFaceComponent(1, 2);
			DB.CurrentCharacterInfo.cartoonWrinkleRotation = playerChar:GetCartoonFaceComponent(1, 3);
			DB.CurrentCharacterInfo.cartoonWrinkleX = playerChar:GetCartoonFaceComponent(1, 4);
			DB.CurrentCharacterInfo.cartoonWrinkleY = playerChar:GetCartoonFaceComponent(1, 5);
			
			DB.CurrentCharacterInfo.cartoonEyeType = playerChar:GetCartoonFaceComponent(2, 0);
			DB.CurrentCharacterInfo.cartoonEyeColor = playerChar:GetCartoonFaceComponent(2, 1);
			DB.CurrentCharacterInfo.cartoonEyeScale = playerChar:GetCartoonFaceComponent(2, 2);
			DB.CurrentCharacterInfo.cartoonEyeRotation = playerChar:GetCartoonFaceComponent(2, 3);
			DB.CurrentCharacterInfo.cartoonEyeX = playerChar:GetCartoonFaceComponent(2, 4);
			DB.CurrentCharacterInfo.cartoonEyeY = playerChar:GetCartoonFaceComponent(2, 5);
			
			DB.CurrentCharacterInfo.cartoonEyebrowType = playerChar:GetCartoonFaceComponent(3, 0);
			DB.CurrentCharacterInfo.cartoonEyebrowColor = playerChar:GetCartoonFaceComponent(3, 1);
			DB.CurrentCharacterInfo.cartoonEyebrowScale = playerChar:GetCartoonFaceComponent(3, 2);
			DB.CurrentCharacterInfo.cartoonEyebrowRotation = playerChar:GetCartoonFaceComponent(3, 3);
			DB.CurrentCharacterInfo.cartoonEyebrowX = playerChar:GetCartoonFaceComponent(3, 4);
			DB.CurrentCharacterInfo.cartoonEyebrowY = playerChar:GetCartoonFaceComponent(3, 5);
			
			DB.CurrentCharacterInfo.cartoonMouthType = playerChar:GetCartoonFaceComponent(4, 0);
			DB.CurrentCharacterInfo.cartoonMouthColor = playerChar:GetCartoonFaceComponent(4, 1);
			DB.CurrentCharacterInfo.cartoonMouthScale = playerChar:GetCartoonFaceComponent(4, 2);
			DB.CurrentCharacterInfo.cartoonMouthRotation = playerChar:GetCartoonFaceComponent(4, 3);
			DB.CurrentCharacterInfo.cartoonMouthX = playerChar:GetCartoonFaceComponent(4, 4);
			DB.CurrentCharacterInfo.cartoonMouthY = playerChar:GetCartoonFaceComponent(4, 5);
			
			DB.CurrentCharacterInfo.cartoonNoseType = playerChar:GetCartoonFaceComponent(5, 0);
			DB.CurrentCharacterInfo.cartoonNoseColor = playerChar:GetCartoonFaceComponent(5, 1);
			DB.CurrentCharacterInfo.cartoonNoseScale = playerChar:GetCartoonFaceComponent(5, 2);
			DB.CurrentCharacterInfo.cartoonNoseRotation = playerChar:GetCartoonFaceComponent(5, 3);
			DB.CurrentCharacterInfo.cartoonNoseX = playerChar:GetCartoonFaceComponent(5, 4);
			DB.CurrentCharacterInfo.cartoonNoseY = playerChar:GetCartoonFaceComponent(5, 5);
			
			DB.CurrentCharacterInfo.cartoonMarksType = playerChar:GetCartoonFaceComponent(6, 0);
			DB.CurrentCharacterInfo.cartoonMarksColor = playerChar:GetCartoonFaceComponent(6, 1);
			DB.CurrentCharacterInfo.cartoonMarksScale = playerChar:GetCartoonFaceComponent(6, 2);
			DB.CurrentCharacterInfo.cartoonMarksRotation = playerChar:GetCartoonFaceComponent(6, 3);
			DB.CurrentCharacterInfo.cartoonMarksX = playerChar:GetCartoonFaceComponent(6, 4);
			DB.CurrentCharacterInfo.cartoonMarksY = playerChar:GetCartoonFaceComponent(6, 5);
			
			DB.CurrentCharacterInfo.IsSupportCartoonFace = true;
		else
			DB.CurrentCharacterInfo.IsSupportCartoonFace = false;
		end
	end
end



function DB.LoadCurrentCharacterCCSInfo()

	local player, playerChar = DB.GetPlayerChar();
	
	if(player ~= nil and player:IsValid()==true) then
		if(DB.CurrentCharacterInfo.IsCustomModel == true) then
			
			g = DB.CurrentCharacterInfo.gender;
			r = DB.CurrentCharacterInfo.raceId;
			if(g == 0 and r == 1) then
				Map3DSystem.UI.CCS.Predefined.ResetBaseModel("character/v3/Human/", "Male");
			elseif(g == 0 and r == 2) then
				Map3DSystem.UI.CCS.Predefined.ResetBaseModel("character/v3/Child/", "Male");
			elseif(g == 1 and r == 1) then
				Map3DSystem.UI.CCS.Predefined.ResetBaseModel("character/v3/Human/", "Female");
			elseif(g == 1 and r == 2) then
				Map3DSystem.UI.CCS.Predefined.ResetBaseModel("character/v3/Child/", "Female");
			end
			
			if(player:IsCharacter()==true and playerChar:IsCustomModel()==true) then
			
				playerChar:SetBodyParams(DB.CurrentCharacterInfo.skinColor, -1, -1, -1, -1);
				playerChar:SetBodyParams(-1, DB.CurrentCharacterInfo.faceType, -1, -1, -1);
				playerChar:SetBodyParams(-1, -1, DB.CurrentCharacterInfo.hairColor, -1, -1);
				playerChar:SetBodyParams(-1, -1, -1, DB.CurrentCharacterInfo.hairStyle, -1);
				playerChar:SetBodyParams(-1, -1, -1, -1, DB.CurrentCharacterInfo.facialHair);
				
				playerChar:SetCharacterSlot(0, DB.CurrentCharacterInfo.itemHead);
				playerChar:SetCharacterSlot(1, DB.CurrentCharacterInfo.itemNeck);
				playerChar:SetCharacterSlot(2, DB.CurrentCharacterInfo.itemShoulder);
				playerChar:SetCharacterSlot(3, DB.CurrentCharacterInfo.itemBoots);
				playerChar:SetCharacterSlot(4, DB.CurrentCharacterInfo.itemBelt);
				playerChar:SetCharacterSlot(5, DB.CurrentCharacterInfo.itemShirt);
				playerChar:SetCharacterSlot(6, DB.CurrentCharacterInfo.itemPants);
				playerChar:SetCharacterSlot(7, DB.CurrentCharacterInfo.itemChest);
				playerChar:SetCharacterSlot(8, DB.CurrentCharacterInfo.itemBracers);
				playerChar:SetCharacterSlot(9, DB.CurrentCharacterInfo.itemGloves);
				playerChar:SetCharacterSlot(10, DB.CurrentCharacterInfo.itemHandRight);
				playerChar:SetCharacterSlot(11, DB.CurrentCharacterInfo.itemHandLeft);
				playerChar:SetCharacterSlot(12, DB.CurrentCharacterInfo.itemCape);
				playerChar:SetCharacterSlot(13, DB.CurrentCharacterInfo.itemTabard);
			end
			
			if(DB.CurrentCharacterInfo.IsSupportCartoonFace == true) then
				
				if(player:IsCharacter()==true and playerChar:IsSupportCartoonFace()==true) then
					
					playerChar:SetCartoonFaceComponent(0, 0, DB.CurrentCharacterInfo.cartoonFaceType);
					playerChar:SetCartoonFaceComponent(0, 1, DB.CurrentCharacterInfo.cartoonFaceColor);
					playerChar:SetCartoonFaceComponent(0, 2, DB.CurrentCharacterInfo.cartoonFaceScale);
					playerChar:SetCartoonFaceComponent(0, 3, DB.CurrentCharacterInfo.cartoonFaceRotation);
					playerChar:SetCartoonFaceComponent(0, 4, DB.CurrentCharacterInfo.cartoonFaceX);
					playerChar:SetCartoonFaceComponent(0, 5, DB.CurrentCharacterInfo.cartoonFaceY);
					
					playerChar:SetCartoonFaceComponent(1, 0, DB.CurrentCharacterInfo.cartoonWrinkleType);
					playerChar:SetCartoonFaceComponent(1, 1, DB.CurrentCharacterInfo.cartoonWrinkleColor);
					playerChar:SetCartoonFaceComponent(1, 2, DB.CurrentCharacterInfo.cartoonWrinkleScale);
					playerChar:SetCartoonFaceComponent(1, 3, DB.CurrentCharacterInfo.cartoonWrinkleRotation);
					playerChar:SetCartoonFaceComponent(1, 4, DB.CurrentCharacterInfo.cartoonWrinkleX);
					playerChar:SetCartoonFaceComponent(1, 5, DB.CurrentCharacterInfo.cartoonWrinkleY);
					
					playerChar:SetCartoonFaceComponent(2, 0, DB.CurrentCharacterInfo.cartoonEyeType);
					playerChar:SetCartoonFaceComponent(2, 1, DB.CurrentCharacterInfo.cartoonEyeColor);
					playerChar:SetCartoonFaceComponent(2, 2, DB.CurrentCharacterInfo.cartoonEyeScale);
					playerChar:SetCartoonFaceComponent(2, 3, DB.CurrentCharacterInfo.cartoonEyeRotation);
					playerChar:SetCartoonFaceComponent(2, 4, DB.CurrentCharacterInfo.cartoonEyeX);
					playerChar:SetCartoonFaceComponent(2, 5, DB.CurrentCharacterInfo.cartoonEyeY);
					
					playerChar:SetCartoonFaceComponent(3, 0, DB.CurrentCharacterInfo.cartoonEyebrowType);
					playerChar:SetCartoonFaceComponent(3, 1, DB.CurrentCharacterInfo.cartoonEyebrowColor);
					playerChar:SetCartoonFaceComponent(3, 2, DB.CurrentCharacterInfo.cartoonEyebrowScale);
					playerChar:SetCartoonFaceComponent(3, 3, DB.CurrentCharacterInfo.cartoonEyebrowRotation);
					playerChar:SetCartoonFaceComponent(3, 4, DB.CurrentCharacterInfo.cartoonEyebrowX);
					playerChar:SetCartoonFaceComponent(3, 5, DB.CurrentCharacterInfo.cartoonEyebrowY);
					
					playerChar:SetCartoonFaceComponent(4, 0, DB.CurrentCharacterInfo.cartoonMouthType);
					playerChar:SetCartoonFaceComponent(4, 1, DB.CurrentCharacterInfo.cartoonMouthColor);
					playerChar:SetCartoonFaceComponent(4, 2, DB.CurrentCharacterInfo.cartoonMouthScale);
					playerChar:SetCartoonFaceComponent(4, 3, DB.CurrentCharacterInfo.cartoonMouthRotation);
					playerChar:SetCartoonFaceComponent(4, 4, DB.CurrentCharacterInfo.cartoonMouthX);
					playerChar:SetCartoonFaceComponent(4, 5, DB.CurrentCharacterInfo.cartoonMouthY);
					
					playerChar:SetCartoonFaceComponent(5, 0, DB.CurrentCharacterInfo.cartoonNoseType);
					playerChar:SetCartoonFaceComponent(5, 1, DB.CurrentCharacterInfo.cartoonNoseColor);
					playerChar:SetCartoonFaceComponent(5, 2, DB.CurrentCharacterInfo.cartoonNoseScale);
					playerChar:SetCartoonFaceComponent(5, 3, DB.CurrentCharacterInfo.cartoonNoseRotation);
					playerChar:SetCartoonFaceComponent(5, 4, DB.CurrentCharacterInfo.cartoonNoseX);
					playerChar:SetCartoonFaceComponent(5, 5, DB.CurrentCharacterInfo.cartoonNoseY);
					
					playerChar:SetCartoonFaceComponent(6, 0, DB.CurrentCharacterInfo.cartoonMarksType);
					playerChar:SetCartoonFaceComponent(6, 1, DB.CurrentCharacterInfo.cartoonMarksColor);
					playerChar:SetCartoonFaceComponent(6, 2, DB.CurrentCharacterInfo.cartoonMarksScale);
					playerChar:SetCartoonFaceComponent(6, 3, DB.CurrentCharacterInfo.cartoonMarksRotation);
					playerChar:SetCartoonFaceComponent(6, 4, DB.CurrentCharacterInfo.cartoonMarksX);
					playerChar:SetCartoonFaceComponent(6, 5, DB.CurrentCharacterInfo.cartoonMarksY);
					
				end
			else
				-- do nothing
			end

			
		else
			--modelname;
		end
	end

end

function DB.LoadIdentityCurrentCharacterInfo()
	DB.CurrentCharacterInfo.cartoonWrinkleType = 0;
	DB.CurrentCharacterInfo.cartoonEyeColor = 0;
	DB.CurrentCharacterInfo.cartoonNoseRotation = 0;
	DB.CurrentCharacterInfo.cartoonFaceColor = 0;
	DB.CurrentCharacterInfo.itemTabard = 0;
	DB.CurrentCharacterInfo.cartoonMarksScale = 0;
	DB.CurrentCharacterInfo.itemChest = 0;
	DB.CurrentCharacterInfo.gender = 0;
	DB.CurrentCharacterInfo.cartoonMarksRotation = 0;
	DB.CurrentCharacterInfo.cartoonEyebrowY = 0;
	DB.CurrentCharacterInfo.faceType = 0;
	DB.CurrentCharacterInfo.cartoonNoseScale = 0;
	DB.CurrentCharacterInfo.cartoonFaceX = 0;
	DB.CurrentCharacterInfo.cartoonNoseColor = 0;
	DB.CurrentCharacterInfo.cartoonEyeType = 0;
	DB.CurrentCharacterInfo.cartoonEyebrowColor = 0;
	DB.CurrentCharacterInfo.cartoonEyeX = 0;
	DB.CurrentCharacterInfo.itemBelt = 0;
	DB.CurrentCharacterInfo.cartoonWrinkleX = 0;
	DB.CurrentCharacterInfo.cartoonFaceY = 0;
	DB.CurrentCharacterInfo.hairColor = 0;
	DB.CurrentCharacterInfo.cartoonWrinkleY = 0;
	DB.CurrentCharacterInfo.cartoonEyeRotation = 0;
	DB.CurrentCharacterInfo.itemShoulder = 0;
	DB.CurrentCharacterInfo.cartoonFaceType = 0;
	DB.CurrentCharacterInfo.itemNeck = 0;
	DB.CurrentCharacterInfo.itemHandLeft = 0;
	DB.CurrentCharacterInfo.cartoonMouthY = 0;
	DB.CurrentCharacterInfo.cartoonMarksType = 0;
	DB.CurrentCharacterInfo.skinColor = 0;
	DB.CurrentCharacterInfo.itemHead = 0;
	DB.CurrentCharacterInfo.itemShirt = 0;
	DB.CurrentCharacterInfo.hairStyle = 0;
	DB.CurrentCharacterInfo.cartoonMouthScale = 0;
	DB.CurrentCharacterInfo.cartoonFaceRotation = 0;
	DB.CurrentCharacterInfo.cartoonMarksX = 0;
	DB.CurrentCharacterInfo.cartoonEyeY = 0;
	DB.CurrentCharacterInfo.itemCape = 0;
	DB.CurrentCharacterInfo.itemPants = 0;
	DB.CurrentCharacterInfo.itemHandRight = 0;
	DB.CurrentCharacterInfo.itemBoots = 0;
	DB.CurrentCharacterInfo.cartoonWrinkleColor = 0;
	DB.CurrentCharacterInfo.cartoonEyeScale = 0;
	DB.CurrentCharacterInfo.cartoonEyebrowRotation = 0;
	DB.CurrentCharacterInfo.cartoonMarksY = 0;
	DB.CurrentCharacterInfo.cartoonNoseY = 0;
	DB.CurrentCharacterInfo.cartoonMarksColor = 0;
	DB.CurrentCharacterInfo.itemGloves = 0;
	DB.CurrentCharacterInfo.cartoonNoseX = 0;
	DB.CurrentCharacterInfo.cartoonWrinkleScale = 0;
	DB.CurrentCharacterInfo.cartoonEyebrowScale = 0;
	DB.CurrentCharacterInfo.cartoonNoseType = 0;
	DB.CurrentCharacterInfo.ModelName = "Default";
	DB.CurrentCharacterInfo.facialHair = 0;
	DB.CurrentCharacterInfo.raceId = 0;
	DB.CurrentCharacterInfo.IsSupportCartoonFace = false;
	DB.CurrentCharacterInfo.cartoonMouthX = 0;
	DB.CurrentCharacterInfo.cartoonMouthType = 0;
	DB.CurrentCharacterInfo.cartoonMouthRotation = 0;
	DB.CurrentCharacterInfo.cartoonMouthColor = 0;
	DB.CurrentCharacterInfo.cartoonEyebrowX = 0;
	DB.CurrentCharacterInfo.cartoonEyebrowType = 0;
	DB.CurrentCharacterInfo.cartoonFaceScale = 0;
	DB.CurrentCharacterInfo.itemBracers = 0;
	DB.CurrentCharacterInfo.cartoonWrinkleRotation = 0;
	DB.CurrentCharacterInfo.IsCustomModel = false;
end

function DB.SaveCharacterCCSInfo(name)

	DB.LoadIdentityCurrentCharacterInfo();

	local player = ParaScene.GetObject(name);
	
	if(player == nil or player:IsValid() == false or player:IsCharacter() == false) then
		return;
	end
	
	local playerChar = player:ToCharacter();
	
	if( playerChar:IsCustomModel()==true ) then
		DB.CurrentCharacterInfo.skinColor = playerChar:GetBodyParams(0);
		DB.CurrentCharacterInfo.faceType = playerChar:GetBodyParams(1);
		DB.CurrentCharacterInfo.hairColor = playerChar:GetBodyParams(2);
		DB.CurrentCharacterInfo.hairStyle = playerChar:GetBodyParams(3);
		DB.CurrentCharacterInfo.facialHair = playerChar:GetBodyParams(4);
		
		DB.CurrentCharacterInfo.itemHead = playerChar:GetCharacterSlotItemID(0);
		DB.CurrentCharacterInfo.itemNeck = playerChar:GetCharacterSlotItemID(1);
		DB.CurrentCharacterInfo.itemShoulder = playerChar:GetCharacterSlotItemID(2);
		DB.CurrentCharacterInfo.itemBoots = playerChar:GetCharacterSlotItemID(3);
		DB.CurrentCharacterInfo.itemBelt = playerChar:GetCharacterSlotItemID(4);
		DB.CurrentCharacterInfo.itemShirt = playerChar:GetCharacterSlotItemID(5);
		DB.CurrentCharacterInfo.itemPants = playerChar:GetCharacterSlotItemID(6);
		DB.CurrentCharacterInfo.itemChest = playerChar:GetCharacterSlotItemID(7);
		DB.CurrentCharacterInfo.itemBracers = playerChar:GetCharacterSlotItemID(8);
		DB.CurrentCharacterInfo.itemGloves = playerChar:GetCharacterSlotItemID(9);
		DB.CurrentCharacterInfo.itemHandRight = playerChar:GetCharacterSlotItemID(10);
		DB.CurrentCharacterInfo.itemHandLeft = playerChar:GetCharacterSlotItemID(11);
		DB.CurrentCharacterInfo.itemCape = playerChar:GetCharacterSlotItemID(12);
		DB.CurrentCharacterInfo.itemTabard = playerChar:GetCharacterSlotItemID(13);
		
		-- TODO: race and gender
		DB.CurrentCharacterInfo.gender = playerChar:GetGender();
		DB.CurrentCharacterInfo.raceId = playerChar:GetRaceID();
		
		DB.CurrentCharacterInfo.IsCustomModel = true;
	else
		DB.CurrentCharacterInfo.IsCustomModel = false;
		
		local name = player:GetPrimaryAsset():GetKeyName();
		if( name == Map3DSystem.UI.MainMenu.DefaultAsset) then
			DB.CurrentCharacterInfo.ModelName = "Default";
		else
			DB.CurrentCharacterInfo.ModelName = name;
		end
	end
		
	if(player:IsCharacter()==true and playerChar:IsSupportCartoonFace()==true) then
		DB.CurrentCharacterInfo.cartoonFaceType = playerChar:GetCartoonFaceComponent(0, 0);
		DB.CurrentCharacterInfo.cartoonFaceColor = playerChar:GetCartoonFaceComponent(0, 1);
		DB.CurrentCharacterInfo.cartoonFaceScale = playerChar:GetCartoonFaceComponent(0, 2);
		DB.CurrentCharacterInfo.cartoonFaceRotation = playerChar:GetCartoonFaceComponent(0, 3);
		DB.CurrentCharacterInfo.cartoonFaceX = playerChar:GetCartoonFaceComponent(0, 4);
		DB.CurrentCharacterInfo.cartoonFaceY = playerChar:GetCartoonFaceComponent(0, 5);
		
		DB.CurrentCharacterInfo.cartoonWrinkleType = playerChar:GetCartoonFaceComponent(1, 0);
		DB.CurrentCharacterInfo.cartoonWrinkleColor = playerChar:GetCartoonFaceComponent(1, 1);
		DB.CurrentCharacterInfo.cartoonWrinkleScale = playerChar:GetCartoonFaceComponent(1, 2);
		DB.CurrentCharacterInfo.cartoonWrinkleRotation = playerChar:GetCartoonFaceComponent(1, 3);
		DB.CurrentCharacterInfo.cartoonWrinkleX = playerChar:GetCartoonFaceComponent(1, 4);
		DB.CurrentCharacterInfo.cartoonWrinkleY = playerChar:GetCartoonFaceComponent(1, 5);
		
		DB.CurrentCharacterInfo.cartoonEyeType = playerChar:GetCartoonFaceComponent(2, 0);
		DB.CurrentCharacterInfo.cartoonEyeColor = playerChar:GetCartoonFaceComponent(2, 1);
		DB.CurrentCharacterInfo.cartoonEyeScale = playerChar:GetCartoonFaceComponent(2, 2);
		DB.CurrentCharacterInfo.cartoonEyeRotation = playerChar:GetCartoonFaceComponent(2, 3);
		DB.CurrentCharacterInfo.cartoonEyeX = playerChar:GetCartoonFaceComponent(2, 4);
		DB.CurrentCharacterInfo.cartoonEyeY = playerChar:GetCartoonFaceComponent(2, 5);
		
		DB.CurrentCharacterInfo.cartoonEyebrowType = playerChar:GetCartoonFaceComponent(3, 0);
		DB.CurrentCharacterInfo.cartoonEyebrowColor = playerChar:GetCartoonFaceComponent(3, 1);
		DB.CurrentCharacterInfo.cartoonEyebrowScale = playerChar:GetCartoonFaceComponent(3, 2);
		DB.CurrentCharacterInfo.cartoonEyebrowRotation = playerChar:GetCartoonFaceComponent(3, 3);
		DB.CurrentCharacterInfo.cartoonEyebrowX = playerChar:GetCartoonFaceComponent(3, 4);
		DB.CurrentCharacterInfo.cartoonEyebrowY = playerChar:GetCartoonFaceComponent(3, 5);
		
		DB.CurrentCharacterInfo.cartoonMouthType = playerChar:GetCartoonFaceComponent(4, 0);
		DB.CurrentCharacterInfo.cartoonMouthColor = playerChar:GetCartoonFaceComponent(4, 1);
		DB.CurrentCharacterInfo.cartoonMouthScale = playerChar:GetCartoonFaceComponent(4, 2);
		DB.CurrentCharacterInfo.cartoonMouthRotation = playerChar:GetCartoonFaceComponent(4, 3);
		DB.CurrentCharacterInfo.cartoonMouthX = playerChar:GetCartoonFaceComponent(4, 4);
		DB.CurrentCharacterInfo.cartoonMouthY = playerChar:GetCartoonFaceComponent(4, 5);
		
		DB.CurrentCharacterInfo.cartoonNoseType = playerChar:GetCartoonFaceComponent(5, 0);
		DB.CurrentCharacterInfo.cartoonNoseColor = playerChar:GetCartoonFaceComponent(5, 1);
		DB.CurrentCharacterInfo.cartoonNoseScale = playerChar:GetCartoonFaceComponent(5, 2);
		DB.CurrentCharacterInfo.cartoonNoseRotation = playerChar:GetCartoonFaceComponent(5, 3);
		DB.CurrentCharacterInfo.cartoonNoseX = playerChar:GetCartoonFaceComponent(5, 4);
		DB.CurrentCharacterInfo.cartoonNoseY = playerChar:GetCartoonFaceComponent(5, 5);
		
		DB.CurrentCharacterInfo.cartoonMarksType = playerChar:GetCartoonFaceComponent(6, 0);
		DB.CurrentCharacterInfo.cartoonMarksColor = playerChar:GetCartoonFaceComponent(6, 1);
		DB.CurrentCharacterInfo.cartoonMarksScale = playerChar:GetCartoonFaceComponent(6, 2);
		DB.CurrentCharacterInfo.cartoonMarksRotation = playerChar:GetCartoonFaceComponent(6, 3);
		DB.CurrentCharacterInfo.cartoonMarksX = playerChar:GetCartoonFaceComponent(6, 4);
		DB.CurrentCharacterInfo.cartoonMarksY = playerChar:GetCartoonFaceComponent(6, 5);
		
		DB.CurrentCharacterInfo.IsSupportCartoonFace = true;
	else
		DB.CurrentCharacterInfo.IsSupportCartoonFace = false;
	end
end


function DB.LoadCharacterCCSInfo(name)

	local player = ParaScene.GetObject(name);
	
	if(player == nil or player:IsValid() == false or player:IsCharacter() == false) then
		return;
	end
	
	local playerChar = player:ToCharacter();
	
	if(DB.CurrentCharacterInfo.IsCustomModel == true) then
		
		g = DB.CurrentCharacterInfo.gender;
		r = DB.CurrentCharacterInfo.raceId;
		if(g == 0 and r == 1) then
			Map3DSystem.UI.CCS.Predefined.ResetBaseModel2(name, "character/v3/Human/", "Male");
		elseif(g == 0 and r == 2) then
			Map3DSystem.UI.CCS.Predefined.ResetBaseModel2(name, "character/v3/Child/", "Male");
		elseif(g == 1 and r == 1) then
			Map3DSystem.UI.CCS.Predefined.ResetBaseModel2(name, "character/v3/Human/", "Female");
		elseif(g == 1 and r == 2) then
			Map3DSystem.UI.CCS.Predefined.ResetBaseModel2(name, "character/v3/Child/", "Female");
		end
		
		if(player:IsCharacter()==true and playerChar:IsCustomModel()==true) then
		
			playerChar:SetBodyParams(DB.CurrentCharacterInfo.skinColor, -1, -1, -1, -1);
			playerChar:SetBodyParams(-1, DB.CurrentCharacterInfo.faceType, -1, -1, -1);
			playerChar:SetBodyParams(-1, -1, DB.CurrentCharacterInfo.hairColor, -1, -1);
			playerChar:SetBodyParams(-1, -1, -1, DB.CurrentCharacterInfo.hairStyle, -1);
			playerChar:SetBodyParams(-1, -1, -1, -1, DB.CurrentCharacterInfo.facialHair);
			
			playerChar:SetCharacterSlot(0, DB.CurrentCharacterInfo.itemHead);
			playerChar:SetCharacterSlot(1, DB.CurrentCharacterInfo.itemNeck);
			playerChar:SetCharacterSlot(2, DB.CurrentCharacterInfo.itemShoulder);
			playerChar:SetCharacterSlot(3, DB.CurrentCharacterInfo.itemBoots);
			playerChar:SetCharacterSlot(4, DB.CurrentCharacterInfo.itemBelt);
			playerChar:SetCharacterSlot(5, DB.CurrentCharacterInfo.itemShirt);
			playerChar:SetCharacterSlot(6, DB.CurrentCharacterInfo.itemPants);
			playerChar:SetCharacterSlot(7, DB.CurrentCharacterInfo.itemChest);
			playerChar:SetCharacterSlot(8, DB.CurrentCharacterInfo.itemBracers);
			playerChar:SetCharacterSlot(9, DB.CurrentCharacterInfo.itemGloves);
			playerChar:SetCharacterSlot(10, DB.CurrentCharacterInfo.itemHandRight);
			playerChar:SetCharacterSlot(11, DB.CurrentCharacterInfo.itemHandLeft);
			playerChar:SetCharacterSlot(12, DB.CurrentCharacterInfo.itemCape);
			playerChar:SetCharacterSlot(13, DB.CurrentCharacterInfo.itemTabard);
		end
		
		if(DB.CurrentCharacterInfo.IsSupportCartoonFace == true) then
			
			if(player:IsCharacter()==true and playerChar:IsSupportCartoonFace()==true) then
				
				playerChar:SetCartoonFaceComponent(0, 0, DB.CurrentCharacterInfo.cartoonFaceType);
				playerChar:SetCartoonFaceComponent(0, 1, DB.CurrentCharacterInfo.cartoonFaceColor);
				playerChar:SetCartoonFaceComponent(0, 2, DB.CurrentCharacterInfo.cartoonFaceScale);
				playerChar:SetCartoonFaceComponent(0, 3, DB.CurrentCharacterInfo.cartoonFaceRotation);
				playerChar:SetCartoonFaceComponent(0, 4, DB.CurrentCharacterInfo.cartoonFaceX);
				playerChar:SetCartoonFaceComponent(0, 5, DB.CurrentCharacterInfo.cartoonFaceY);
				
				playerChar:SetCartoonFaceComponent(1, 0, DB.CurrentCharacterInfo.cartoonWrinkleType);
				playerChar:SetCartoonFaceComponent(1, 1, DB.CurrentCharacterInfo.cartoonWrinkleColor);
				playerChar:SetCartoonFaceComponent(1, 2, DB.CurrentCharacterInfo.cartoonWrinkleScale);
				playerChar:SetCartoonFaceComponent(1, 3, DB.CurrentCharacterInfo.cartoonWrinkleRotation);
				playerChar:SetCartoonFaceComponent(1, 4, DB.CurrentCharacterInfo.cartoonWrinkleX);
				playerChar:SetCartoonFaceComponent(1, 5, DB.CurrentCharacterInfo.cartoonWrinkleY);
				
				playerChar:SetCartoonFaceComponent(2, 0, DB.CurrentCharacterInfo.cartoonEyeType);
				playerChar:SetCartoonFaceComponent(2, 1, DB.CurrentCharacterInfo.cartoonEyeColor);
				playerChar:SetCartoonFaceComponent(2, 2, DB.CurrentCharacterInfo.cartoonEyeScale);
				playerChar:SetCartoonFaceComponent(2, 3, DB.CurrentCharacterInfo.cartoonEyeRotation);
				playerChar:SetCartoonFaceComponent(2, 4, DB.CurrentCharacterInfo.cartoonEyeX);
				playerChar:SetCartoonFaceComponent(2, 5, DB.CurrentCharacterInfo.cartoonEyeY);
				
				playerChar:SetCartoonFaceComponent(3, 0, DB.CurrentCharacterInfo.cartoonEyebrowType);
				playerChar:SetCartoonFaceComponent(3, 1, DB.CurrentCharacterInfo.cartoonEyebrowColor);
				playerChar:SetCartoonFaceComponent(3, 2, DB.CurrentCharacterInfo.cartoonEyebrowScale);
				playerChar:SetCartoonFaceComponent(3, 3, DB.CurrentCharacterInfo.cartoonEyebrowRotation);
				playerChar:SetCartoonFaceComponent(3, 4, DB.CurrentCharacterInfo.cartoonEyebrowX);
				playerChar:SetCartoonFaceComponent(3, 5, DB.CurrentCharacterInfo.cartoonEyebrowY);
				
				playerChar:SetCartoonFaceComponent(4, 0, DB.CurrentCharacterInfo.cartoonMouthType);
				playerChar:SetCartoonFaceComponent(4, 1, DB.CurrentCharacterInfo.cartoonMouthColor);
				playerChar:SetCartoonFaceComponent(4, 2, DB.CurrentCharacterInfo.cartoonMouthScale);
				playerChar:SetCartoonFaceComponent(4, 3, DB.CurrentCharacterInfo.cartoonMouthRotation);
				playerChar:SetCartoonFaceComponent(4, 4, DB.CurrentCharacterInfo.cartoonMouthX);
				playerChar:SetCartoonFaceComponent(4, 5, DB.CurrentCharacterInfo.cartoonMouthY);
				
				playerChar:SetCartoonFaceComponent(5, 0, DB.CurrentCharacterInfo.cartoonNoseType);
				playerChar:SetCartoonFaceComponent(5, 1, DB.CurrentCharacterInfo.cartoonNoseColor);
				playerChar:SetCartoonFaceComponent(5, 2, DB.CurrentCharacterInfo.cartoonNoseScale);
				playerChar:SetCartoonFaceComponent(5, 3, DB.CurrentCharacterInfo.cartoonNoseRotation);
				playerChar:SetCartoonFaceComponent(5, 4, DB.CurrentCharacterInfo.cartoonNoseX);
				playerChar:SetCartoonFaceComponent(5, 5, DB.CurrentCharacterInfo.cartoonNoseY);
				
				playerChar:SetCartoonFaceComponent(6, 0, DB.CurrentCharacterInfo.cartoonMarksType);
				playerChar:SetCartoonFaceComponent(6, 1, DB.CurrentCharacterInfo.cartoonMarksColor);
				playerChar:SetCartoonFaceComponent(6, 2, DB.CurrentCharacterInfo.cartoonMarksScale);
				playerChar:SetCartoonFaceComponent(6, 3, DB.CurrentCharacterInfo.cartoonMarksRotation);
				playerChar:SetCartoonFaceComponent(6, 4, DB.CurrentCharacterInfo.cartoonMarksX);
				playerChar:SetCartoonFaceComponent(6, 5, DB.CurrentCharacterInfo.cartoonMarksY);
				
			end
		else
			-- do nothing
		end

		
	else
		local assetNew;
		if(DB.CurrentCharacterInfo.ModelName == "Default") then
			assetNew = ParaAsset.LoadParaX("", Map3DSystem.UI.MainMenu.DefaultAsset);
		else
			assetNew = ParaAsset.LoadParaX("", DB.CurrentCharacterInfo.ModelName);
		end
	
		if(assetNew:IsValid() == true) then
			playerChar:ResetBaseModel(assetNew);
		end
	end
end

-- NOTE: this function will generate the database items according to standard specification
--		avoid calling this function without authorization
-- Contact Andy for more information
function DB.AutoGenerateItems()
	local databaseFile = "Database/characters.db";
	local itemDir = "character/v3/Item/";
	
	-- key components
	
	local sDir_AL = "character/v3/Item/TextureComponents/ArmLowerTexture/";
	local sDir_AU = "character/v3/Item/TextureComponents/ArmUpperTexture/";
	local sDir_TL = "character/v3/Item/TextureComponents/TorsoLowerTexture/";
	local sDir_TU = "character/v3/Item/TextureComponents/TorsoUpperTexture/";
	
	local sDir_LL = "character/v3/Item/TextureComponents/LegLowerTexture/";
	local sDir_LU = "character/v3/Item/TextureComponents/LegUpperTexture/";
	
	local sDir_HA = "character/v3/Item/TextureComponents/HandTexture/";
	local sDir_FO = "character/v3/Item/TextureComponents/FootTexture/";
	
	local itemStart = 100;
	local itemID = itemStart;
	
	local itemRaceGenderStart = 10;
	local itemRaceGenderID = itemRaceGenderStart;
	
	local result = {};
	local i = 1;
	local db = sqlite3.open(databaseFile);
	local row;
	local typeStr;
	
	-- get the whole database
	
	local db_ItemDatabase = {};
	DB.db_ItemDatabase = db_ItemDatabase;
	local maxItemID = 1;
	for row in db:rows("SELECT id, itemclass, subclass, type, model, name FROM ItemDatabase") do
		local id = tonumber(row.id);
		local itemclass = tonumber(row.itemclass);
		local subclass = tonumber(row.subclass);
		local type = tonumber(row.type);
		local model = tonumber(row.model);
		local name = tostring(row.name);
		
		db_ItemDatabase[id] = {id = id, 
			itemclass = itemclass, 
			subclass = subclass, 
			type = type, 
			model = model, 
			name = name, };
		if(maxItemID <= id) then
			maxItemID = id;
		end
	end
	
	if(maxItemID < itemStart) then
		maxItemID = itemStart;
	end
	
	-- get the whole database
	
	local db_ItemDisplayDB = {};
	for row in db:rows("SELECT ItemDisplayID, Model, Model2, Skin, Skin2, Icon, GeosetA, GeosetB, GeosetC, GeosetD, GeosetE, Flags, GeosetVisID1, GeosetVisID2, TexArmUpper, TexArmLower, TexHands, TexChestUpper, TexChestLower, TexLegUpper, TexLegLower, TexFeet, Visuals FROM ItemDisplayDB") do
		
		local ItemDisplayID = tonumber(row.ItemDisplayID);
		local Model = tostring(row.Model);
		local Model2 = tostring(row.Model2);
		local Skin = tostring(row.Skin);
		local Skin2 = tostring(row.Skin2);
		local Icon = tostring(row.Icon);
		local GeosetA = tonumber(row.GeosetA);
		local GeosetB = tonumber(row.GeosetB);
		local GeosetC = tonumber(row.GeosetC);
		local GeosetD = tonumber(row.GeosetD);
		local GeosetE = tonumber(row.GeosetE);
		local Flags = tonumber(row.Flags);
		local GeosetVisID1 = tonumber(row.GeosetVisID1);
		local GeosetVisID2 = tonumber(row.GeosetVisID2);
		local TexArmUpper = tostring(row.TexArmUpper);
		local TexArmLower = tostring(row.TexArmLower);
		local TexHands = tostring(row.TexHands);
		local TexChestUpper = tostring(row.TexChestUpper);
		local TexChestLower = tostring(row.TexChestLower);
		local TexLegUpper = tostring(row.TexLegUpper);
		local TexLegLower = tostring(row.TexLegLower);
		local TexFeet = tostring(row.TexFeet);
		local Visuals = tonumber(row.Visuals);
		
		
		db_ItemDisplayDB[ItemDisplayID] = {ItemDisplayID = ItemDisplayID, 
			Model = Model, 
			Model2 = Model2, 
			Skin = Skin, 
			Skin2 = Skin2, 
			Icon = Icon, 
			GeosetA = GeosetA, 
			GeosetB = GeosetB, 
			GeosetC = GeosetC, 
			GeosetD = GeosetD, 
			GeosetE = GeosetE, 
			Flags = Flags, 
			GeosetVisID1 = GeosetVisID1, 
			GeosetVisID2 = GeosetVisID2, 
			TexArmUpper = TexArmUpper, 
			TexArmLower = TexArmLower, 
			TexHands = TexHands, 
			TexChestUpper = TexChestUpper, 
			TexChestLower = TexChestLower, 
			TexLegUpper = TexLegUpper, 
			TexLegLower = TexLegLower, 
			TexFeet = TexFeet, 
			Visuals = Visuals, 
			};
	end
	
	
	local function GetIDByItemName(name, type)
		local ret = {};
		local i, item;
		for i, item in pairs(db_ItemDatabase) do
			if(item.name == name) then
				if(type == item.type or type == nil) then
					table.insert(ret, item.id);
				end
			end
		end
		
		return ret;
	end
	
	--
	---- clear all the records except the records reserved for item editor
	--db:exec("DELETE FROM ItemDatabase WHERE id > 8");
	--db:exec("DELETE FROM ItemDisplayDB WHERE ItemDisplayID > 8");
	
	local nMaxNumFiles = 5000;
	
	-- search all shirt items
	local search_result = ParaIO.SearchFiles(sDir_TU, "*.dds", "", 0, nMaxNumFiles, 0);
	local nCount = search_result:GetNumOfResult();
	local i;
	for i = 0, nCount - 1 do
		
		local sTexFileName_TU = search_result:GetItem(i);
		
		if(sTexFileName_TU ~= nil) then
			
			local nGeoSetPos = string.find(sTexFileName_TU, "_TU_");
			
			if(nGeoSetPos == nil) then
				-- ccs character default shirt texture
				local race, gender;
				local nFemale = string.find(sTexFileName_TU, "Female");
				if(nFemale == nil) then
					local nMale = string.find(sTexFileName_TU, "Male");
					if(nMale == nil) then
						-- invalid texture name
						log("invalid chest upper texture name: "..sTexFileName_TU.."\n");
					else
						-- male
						race = string.sub(sTexFileName_TU, 1, nMale - 1);
						gender = "Male";
					end
				else
					-- female
					race = string.sub(sTexFileName_TU, 1, nFemale - 1);
					gender = "Female";
				end
				
				if(race ~= nil and gender ~= nil) then
					local file;
					file = string.format([[character/v3/%s/%s/%s%s.x]], race, gender, race, gender);
					if(ParaIO.DoesFileExist(file) == true) then
						
						local sTexFileName_TL = string.gsub(sTexFileName_TU, "_TU", "_TL");
						local sTexFileName_AU = string.gsub(sTexFileName_TU, "_TU", "_AU");
						local sTexFileName_AL = string.gsub(sTexFileName_TU, "_TU", "_AL");
						
						if(not ParaIO.DoesFileExist(sDir_TL..sTexFileName_TL, true)) then
							sTexFileName_TL = "";
						end
						
						if(not ParaIO.DoesFileExist(sDir_AU..sTexFileName_AU, true)) then
							sTexFileName_AU = "";
						end
						
						if(not ParaIO.DoesFileExist(sDir_AL..sTexFileName_AL, true) ) then
							sTexFileName_AL = "";
						end
						
						local itemName = race..gender.."DefaultShirt";
						
						local IDs = GetIDByItemName(itemName);
						if(#IDs == 0) then
							db:exec(string.format("INSERT INTO ItemDatabase VALUES (%d, 0, 0, %d, %d, '%s');", 
									itemRaceGenderID, 4, itemRaceGenderID, itemName));
									
							db:exec(string.format("INSERT INTO ItemDisplayDB VALUES (%d, '%s', '%s', '%s', '%s', 'icon', %d, %d, 0, 0, 0, 0, 0, 0, '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', 0);", 
									itemRaceGenderID, "", "", "", "", 0, 0, sTexFileName_AU, sTexFileName_AL, "", sTexFileName_TU, sTexFileName_TL, "", "", ""));
							
							itemRaceGenderID = itemRaceGenderID + 1;
						end
					end
				end
			else
				-- ordinary shirt texture
				nGeoSetPos = nGeoSetPos - 2;
				
				local sGeoSet = string.sub(sTexFileName_TU, nGeoSetPos, nGeoSetPos+1);
				local nGeoSet = commonlib.tonumber(string.gsub(sGeoSet, "_", ""));
				
				local sTexFileName_TL = string.gsub(sTexFileName_TU, "_TU_", "_TL_");
				local sTexFileName_AU = string.gsub(sTexFileName_TU, "_TU_", "_AU_");
				local sTexFileName_AL = string.gsub(sTexFileName_TU, "_TU_", "_AL_");
				
				if(not ParaIO.DoesFileExist(sDir_TL..sTexFileName_TL, true)) then
					sTexFileName_TL = "";
				end
				
				if(not ParaIO.DoesFileExist(sDir_AU..sTexFileName_AU, true)) then
					sTexFileName_AU = "";
				end
				
				if(not ParaIO.DoesFileExist(sDir_AL..sTexFileName_AL, true)) then
					sTexFileName_AL = "";
				end
				
				local itemName = string.sub(sTexFileName_TU, 1, string.find(sTexFileName_TU, sGeoSet) - 1);
				
				--db:exec(string.format("INSERT INTO ItemDatabase VALUES (%d, 0, 0, %d, %d, '%s');", 
						--itemID, 4, itemID, itemName));
						--
				--db:exec(string.format("INSERT INTO ItemDisplayDB VALUES (%d, '%s', '%s', '%s', '%s', 'icon', %d, %d, 0, 0, 0, 0, 0, 0, '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', 0);", 
						--itemID, "", "", "", "", nGeoSet-1, 0, sTexFileName_AU, sTexFileName_AL, "", sTexFileName_TU, sTexFileName_TL, "", "", ""));
				--
				--itemID = itemID + 1;
				
				
				local IDs = GetIDByItemName(itemName, 4);
				
				if(#IDs == 0) then
					--local i, ID;
					--local bExist = false;
					--for i, ID in ipairs(IDs) do
						--if(sTexFileName_AU == db_ItemDisplayDB[ID].TexArmUpper
							--and sTexFileName_AL == db_ItemDisplayDB[ID].TexArmLower
							--and sTexFileName_TU == db_ItemDisplayDB[ID].TexChestUpper
							--and sTexFileName_TL == db_ItemDisplayDB[ID].TexChestLower) then
							--
							--bExist = true;
						--end
					--end
					--if(bExist == false) then
						local itemID = maxItemID + 1;
						maxItemID = itemID;
						
						db:exec(string.format("INSERT INTO ItemDatabase VALUES (%d, 0, 0, %d, %d, '%s');", 
								itemID, 4, itemID, itemName));
								
						db:exec(string.format("INSERT INTO ItemDisplayDB VALUES (%d, '%s', '%s', '%s', '%s', 'icon', %d, %d, 0, 0, 0, 0, 0, 0, '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', 0);", 
								itemID, "", "", "", "", nGeoSet-1, 0, sTexFileName_AU, sTexFileName_AL, "", sTexFileName_TU, sTexFileName_TL, "", "", ""));
					--end
				end
			end
		end
	end
	search_result:Release();
	
	
	-- search all pant items
	local search_result = ParaIO.SearchFiles(sDir_LU, "*.dds", "", 0, nMaxNumFiles, 0);
	local nCount = search_result:GetNumOfResult();
	local i;
	for i = 0, nCount - 1 do
		
		local sTexFileName_LU = search_result:GetItem(i);
		
		if(sTexFileName_LU ~= nil) then
			
			local nGeoSetPos = string.find(sTexFileName_LU, "_LU_");
			
			
			if(nGeoSetPos == nil) then
				-- ccs character default pant texture
				local race, gender;
				local nFemale = string.find(sTexFileName_LU, "Female");
				if(nFemale == nil) then
					local nMale = string.find(sTexFileName_LU, "Male");
					if(nMale == nil) then
						-- invalid texture name
						log("invalid leg upper texture name: "..sTexFileName_LU.."\n");
					else
						-- male
						race = string.sub(sTexFileName_LU, 1, nMale - 1);
						gender = "Male";
					end
				else
					-- female
					race = string.sub(sTexFileName_LU, 1, nFemale - 1);
					gender = "Female";
				end
				
				if(race ~= nil and gender ~= nil) then
					local file;
					file = string.format([[character/v3/%s/%s/%s%s.x]], race, gender, race, gender);
					if(ParaIO.DoesFileExist(file, true)) then
						
						local sTexFileName_LL = string.gsub(sTexFileName_LU, "_LU", "_LL");
						
						if(not ParaIO.DoesFileExist(sDir_LL..sTexFileName_LL, true)) then
							sTexFileName_LL = "";
						end
						
						local itemName = race..gender.."DefaultPant";
						
						local IDs = GetIDByItemName(itemName);
						if(#IDs == 0) then
							db:exec(string.format("INSERT INTO ItemDatabase VALUES (%d, 0, 0, %d, %d, '%s');", 
									itemRaceGenderID, 7, itemRaceGenderID, itemName));
									
							db:exec(string.format("INSERT INTO ItemDisplayDB VALUES (%d, '%s', '%s', '%s', '%s', 'icon', %d, %d, 0, 0, 0, 0, 0, 0, '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', 0);", 
									itemRaceGenderID, "", "", "", "", 0, 0, "", "", "", "", "", sTexFileName_LU, sTexFileName_LL, ""));
							
							itemRaceGenderID = itemRaceGenderID + 1;
						end
					end
				end
			else
				-- ordinary pant texture
				nGeoSetPos = nGeoSetPos - 2;
				
				local sGeoSet = string.sub(sTexFileName_LU, nGeoSetPos, nGeoSetPos+1);
				local nGeoSet = commonlib.tonumber(string.gsub(sGeoSet, "_", ""));
				
				local sTexFileName_LL = string.gsub(sTexFileName_LU, "_LU_", "_LL_");
				
				if(not ParaIO.DoesFileExist(sDir_LL..sTexFileName_LL, true)) then
					sTexFileName_LL = "";
				end
				
				local itemName = string.sub(sTexFileName_LU, 1, string.find(sTexFileName_LU, sGeoSet) - 1);
				
				--db:exec(string.format("INSERT INTO ItemDatabase VALUES (%d, 0, 0, %d, %d, '%s');", 
						--itemID, 7, itemID, itemName));
						--
				--db:exec(string.format("INSERT INTO ItemDisplayDB VALUES (%d, '%s', '%s', '%s', '%s', 'icon', %d, %d, 0, 0, 0, 0, 0, 0, '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', 0);", 
						--itemID, "", "", "", "", 0, nGeoSet-1, "", "", "", "", "", sTexFileName_LU, sTexFileName_LL, ""));
				--
				--itemID = itemID + 1;
				
				
				local IDs = GetIDByItemName(itemName, 7);
				if(#IDs == 0) then
					--local i, ID;
					--local bExist = false;
					--for i, ID in ipairs(IDs) do
						--if(sTexFileName_LU == db_ItemDisplayDB[ID].TexLegUpper
							--and sTexFileName_LL == db_ItemDisplayDB[ID].TexLegLower) then
							--
							--bExist = true;
						--end
					--end
					--if(bExist == false) then
						local itemID = maxItemID + 1;
						maxItemID = itemID;
						
						db:exec(string.format("INSERT INTO ItemDatabase VALUES (%d, 0, 0, %d, %d, '%s');", 
								itemID, 7, itemID, itemName));
								
						db:exec(string.format("INSERT INTO ItemDisplayDB VALUES (%d, '%s', '%s', '%s', '%s', 'icon', %d, %d, 0, 0, 0, 0, 0, 0, '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', 0);", 
								itemID, "", "", "", "", 0, nGeoSet-1, "", "", "", "", "", sTexFileName_LU, sTexFileName_LL, ""));
					--end
				end
			end
		end
	end
	search_result:Release();
	
	
	-- search all hand items
	local search_result = ParaIO.SearchFiles(sDir_HA, "*.dds", "", 0, nMaxNumFiles, 0);
	local nCount = search_result:GetNumOfResult();
	local i;
	for i = 0, nCount - 1 do
		
		local sTexFileName_HA = search_result:GetItem(i);
		
		if(sTexFileName_HA ~= nil) then
			
			local nGeoSetPos = string.find(sTexFileName_HA, "_HA_");
			nGeoSetPos = nGeoSetPos - 2;
			
			local sGeoSet = string.sub(sTexFileName_HA, nGeoSetPos, nGeoSetPos+1);
			local nGeoSet = commonlib.tonumber(string.gsub(sGeoSet, "_", ""));
			
			local itemName = string.sub(sTexFileName_HA, 1, string.find(sTexFileName_HA, sGeoSet) - 1);
			
			--db:exec(string.format("INSERT INTO ItemDatabase VALUES (%d, 0, 0, %d, %d, '%s');", 
					--itemID, 10, itemID, itemName));
					--
			--db:exec(string.format("INSERT INTO ItemDisplayDB VALUES (%d, '%s', '%s', '%s', '%s', 'icon', %d, %d, 0, 0, 0, 0, 0, 0, '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', 0);", 
					--itemID, "", "", "", "", nGeoSet-1, 0, "", "", sTexFileName_HA, "", "", "", "", ""));
			--
			--itemID = itemID + 1;
			
			local IDs = GetIDByItemName(itemName, 10);
			if(#IDs == 0) then
				--local i, ID;
				--local bExist = false;
				--for i, ID in ipairs(IDs) do
					--if(sTexFileName_HA == db_ItemDisplayDB[ID].TexHands) then
						--bExist = true;
					--end
				--end
				--if(bExist == false) then
					local itemID = maxItemID + 1;
					maxItemID = itemID;
					
					db:exec(string.format("INSERT INTO ItemDatabase VALUES (%d, 0, 0, %d, %d, '%s');", 
							itemID, 10, itemID, itemName));
							
					db:exec(string.format("INSERT INTO ItemDisplayDB VALUES (%d, '%s', '%s', '%s', '%s', 'icon', %d, %d, 0, 0, 0, 0, 0, 0, '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', 0);", 
							itemID, "", "", "", "", nGeoSet-1, 0, "", "", sTexFileName_HA, "", "", "", "", ""));
				--end
			end
		end
	end
	search_result:Release();
	
	
	-- search all foot items
	local search_result = ParaIO.SearchFiles(sDir_FO, "*.dds", "", 0, nMaxNumFiles, 0);
	local nCount = search_result:GetNumOfResult();
	local i;
	for i = 0, nCount - 1 do
		
		local sTexFileName_FO = search_result:GetItem(i);
		
		if(sTexFileName_FO ~= nil) then
			
			local nGeoSetPos = string.find(sTexFileName_FO, "_FO_");
			nGeoSetPos = nGeoSetPos - 2;
			
			local sGeoSet = string.sub(sTexFileName_FO, nGeoSetPos, nGeoSetPos+1);
			local nGeoSet = commonlib.tonumber(string.gsub(sGeoSet, "_", ""));
			
			local itemName = string.sub(sTexFileName_FO, 1, string.find(sTexFileName_FO, sGeoSet) - 1);
			
			--db:exec(string.format("INSERT INTO ItemDatabase VALUES (%d, 0, 0, %d, %d, '%s');", 
					--itemID, 8, itemID, itemName));
					--
			--db:exec(string.format("INSERT INTO ItemDisplayDB VALUES (%d, '%s', '%s', '%s', '%s', 'icon', %d, %d, 0, 0, 0, 0, 0, 0, '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', 0);", 
					--itemID, "", "", "", "", nGeoSet-1, 0, "", "", "", "", "", "", "", sTexFileName_FO));
			--
			--itemID = itemID + 1;
			
			local IDs = GetIDByItemName(itemName, 8);
			
			if(#IDs == 0) then
				--local i, ID;
				--local bExist = false;
				--for i, ID in ipairs(IDs) do
					--if(sTexFileName_FO == db_ItemDisplayDB[ID].TexFeet) then
						--bExist = true;
					--end
				--end
				--if(bExist == false) then
					local itemID = maxItemID + 1;
					maxItemID = itemID;
					
					db:exec(string.format("INSERT INTO ItemDatabase VALUES (%d, 0, 0, %d, %d, '%s');", 
							itemID, 8, itemID, itemName));
							
					db:exec(string.format("INSERT INTO ItemDisplayDB VALUES (%d, '%s', '%s', '%s', '%s', 'icon', %d, %d, 0, 0, 0, 0, 0, 0, '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', 0);", 
							itemID, "", "", "", "", nGeoSet-1, 0, "", "", "", "", "", "", "", sTexFileName_FO));
				--end
			end
		end
		
	end
	search_result:Release();
	
	
	
	
	-- object components
	
	local sDir_Head = "character/v3/Item/ObjectComponents/Head/";
	local sDir_Shoulder = "character/v3/Item/ObjectComponents/Shoulder/";
	local sDir_Weapon = "character/v3/Item/ObjectComponents/Weapon/";
	local sDir_Cape = "character/v3/Item/ObjectComponents/Cape/";
	
	
	
	-- search all head items
	local search_result = ParaIO.SearchFiles(sDir_Head, "*.x", "", 0, nMaxNumFiles, 0);
	local nCount = search_result:GetNumOfResult();
	local i;
	for i = 0, nCount - 1 do
		
		local sXFileName = search_result:GetItem(i);
		
		sXFileName = string.gsub(sXFileName, "(.*)%.x$", "%1") --  remove the x file extension
		
		if(sXFileName ~= nil) then
			
			local itemName = sXFileName;
			
			local IDs = GetIDByItemName(itemName, 1);
			if(table.getn(IDs) == 0) then
				local itemID = maxItemID + 1;
				maxItemID = itemID;
				
				db:exec(string.format("INSERT INTO ItemDatabase VALUES (%d, 0, 0, %d, %d, '%s');", 
						itemID, 1, itemID, itemName));
						
				db:exec(string.format("INSERT INTO ItemDisplayDB VALUES (%d, '%s', '%s', '%s', '%s', 'icon', %d, %d, 0, 0, 0, 0, 0, 0, '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', 0);", 
						itemID, sXFileName..".x", "", sXFileName..".dds", "", 0, 0, "", "", "", "", "", "", "", ""));
			end
		end
		
	end
	search_result:Release();
	
	-- search all shoulder items
	local search_result = ParaIO.SearchFiles(sDir_Shoulder, "*.x", "", 0, nMaxNumFiles, 0);
	local nCount = search_result:GetNumOfResult();
	
	--local i;
	--for i = 0, nCount - 1 do
		--local sXFileName = search_result:GetItem(i);
		--
		--if(string.find(sXFileName, "LShoulder_") == 1) then
			--sXFileName = string.gsub(sXFileName, "(.*)%.x$", "%1") --  remove the x file extension
		--end
		--
		--if(string.find(sXFileName, "RShoulder_") == 1) then
			--sXFileName = string.gsub(sXFileName, "(.*)%.x$", "%1") --  remove the x file extension
		--end
	--end
	
	local i;
	local rightShoulderNames = {};
	for i = 0, nCount - 1 do
		local sXFileName = search_result:GetItem(i);
		
		if(string.find(sXFileName, "RShoulder_") == 1) then
			sXFileName = string.gsub(sXFileName, "(.*)%.x$", "%1") --  remove the x file extension
			table.insert(rightShoulderNames, sXFileName);
		end
	end
	
	
	for i = 0, nCount - 1 do
		
		local sXFileName = search_result:GetItem(i);
		
		if(string.find(sXFileName, "LShoulder_") == 1) then
			sXFileName = string.gsub(sXFileName, "(.*)%.x$", "%1") --  remove the x file extension
			
			local sXFileNameRight = string.gsub(sXFileName, "LShoulder_", "RShoulder_");
			
			local j;
			local rightCount = table.getn(rightShoulderNames);
			for j = 1, rightCount do
				if(rightShoulderNames[j] == sXFileNameRight) then
					-- with right shoulder
					local itemName = sXFileName;
					
					local IDs = GetIDByItemName(itemName, 3);
					if(table.getn(IDs) == 0) then
						local itemID = maxItemID + 1;
						maxItemID = itemID;
						
						db:exec(string.format("INSERT INTO ItemDatabase VALUES (%d, 0, 0, %d, %d, '%s');", 
								itemID, 3, itemID, itemName));
							
						db:exec(string.format("INSERT INTO ItemDisplayDB VALUES (%d, '%s', '%s', '%s', '%s', 'icon', %d, %d, 0, 0, 0, 0, 0, 0, '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', 0);", 
								itemID, sXFileName..".x", sXFileNameRight..".x", sXFileName..".dds", sXFileNameRight..".dds", 0, 0, "", "", "", "", "", "", "", ""));
					end
					
					table.remove(rightShoulderNames, j);
					break;
				end
			end
			
			if(rightCount == table.getn(rightShoulderNames)) then
				-- right shoulder is not avaiable, left shoulder avaiable
				local itemName = sXFileName;
				
				local IDs = GetIDByItemName(itemName, 3);
				if(table.getn(IDs) == 0) then
					local itemID = maxItemID + 1;
					maxItemID = itemID;
					
					db:exec(string.format("INSERT INTO ItemDatabase VALUES (%d, 0, 0, %d, %d, '%s');", 
							itemID, 3, itemID, itemName));
						
					db:exec(string.format("INSERT INTO ItemDisplayDB VALUES (%d, '%s', '%s', '%s', '%s', 'icon', %d, %d, 0, 0, 0, 0, 0, 0, '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', 0);", 
							itemID, sXFileName..".x", "", sXFileName..".dds", "", 0, 0, "", "", "", "", "", "", "", ""));
				end
			end
		end
	end
	search_result:Release();
	
	local j;
	for j = 1, table.getn(rightShoulderNames) do
		
		-- left shoulder is not avaiable, right shoulder avaiable
		local sXFileName = rightShoulderNames[j];
		local itemName = sXFileName;
		local sXFileNameRight = sXFileName;
		
		local IDs = GetIDByItemName(itemName, 3);
		if(table.getn(IDs) == 0) then
			local itemID = maxItemID + 1;
			maxItemID = itemID;
			
			db:exec(string.format("INSERT INTO ItemDatabase VALUES (%d, 0, 0, %d, %d, '%s');", 
					itemID, 3, itemID, itemName));
				
			db:exec(string.format("INSERT INTO ItemDisplayDB VALUES (%d, '%s', '%s', '%s', '%s', 'icon', %d, %d, 0, 0, 0, 0, 0, 0, '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', 0);", 
					itemID, "", sXFileNameRight..".x", "", sXFileNameRight..".dds", 0, 0, "", "", "", "", "", "", "", ""));
		end
	end
	
	-- search all weapon items
	local search_result = ParaIO.SearchFiles(sDir_Weapon, "*.x", "", 0, nMaxNumFiles, 0);
	local nCount = search_result:GetNumOfResult();
	local i;
	for i = 0, nCount - 1 do
		
		local sXFileName = search_result:GetItem(i);
		sXFileName = string.gsub(sXFileName, "(.*)%.x$", "%1") --  remove the x file extension
		
		if(sXFileName ~= nil) then
			
			local itemName = sXFileName;
			
			local IDs = GetIDByItemName(itemName, 21);
			if(table.getn(IDs) == 0) then
				local itemID = maxItemID + 1;
				maxItemID = itemID;
				
				db:exec(string.format("INSERT INTO ItemDatabase VALUES (%d, 0, 0, %d, %d, '%s');", 
						itemID, 21, itemID, itemName));
						
				db:exec(string.format("INSERT INTO ItemDisplayDB VALUES (%d, '%s', '%s', '%s', '%s', 'icon', %d, %d, 0, 0, 0, 0, 0, 0, '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', 0);", 
						itemID, sXFileName..".x", "", sXFileName..".dds", "", 0, 0, "", "", "", "", "", "", "", ""));
			end
		end
		
	end
	search_result:Release();
	
	--
	--local tHeadX = {};
	--
	---- search all head items x files
	--local search_result = ParaIO.SearchFiles(sDir_Head, "*.x", "", 0, nMaxNumFiles, 0);
	--local nCount = search_result:GetNumOfResult();
	--local i;
	--for i = 0, nCount - 1 do
		--local sXFileName = search_result:GetItem(i);
		--sXFileName = string.gsub(sXFileName, "(.*)%.x$", "%1") --  remove the x file extension
		--table.insert(tHeadX, sXFileName);
	--end
	--search_result:Release();
	--
	--local tHeadDDS = {};
	--
	---- search all head items x files
	--local search_result = ParaIO.SearchFiles(sDir_Head, "*.dds", "", 0, nMaxNumFiles, 0);
	--local nCount = search_result:GetNumOfResult();
	--local i;
	--for i = 0, nCount - 1 do
		--local sDDSFileName = search_result:GetItem(i);
		--sDDSFileName = string.gsub(sDDSFileName, "(.*)%.dds$", "%1") -- remove the dds file extension
		--table.insert(tHeadDDS, sDDSFileName);
	--end
	--search_result:Release();
	
	local upgradeCartoonFace = false;
	
	if(upgradeCartoonFace == true) then
		
		-- clear all the records in cartoon face
		db:exec("DELETE FROM CartoonFaceDB WHERE CartoonFaceID > 0");
		
		-- cartoon face components
		local sDir_Eye = "character/v3/CartoonFace/eye/";
		local sDir_Eyebrow = "character/v3/CartoonFace/eyebrow/";
		local sDir_Face = "character/v3/CartoonFace/face/";
		local sDir_FaceDeco = "character/v3/CartoonFace/faceDeco/";
		local sDir_Mark = "character/v3/CartoonFace/mark/";
		local sDir_Mouth = "character/v3/CartoonFace/mouth/";
		local sDir_Nose = "character/v3/CartoonFace/nose/";
		
		local componentID = 1;
		
		-- search all eye component files
		local search_result = ParaIO.SearchFiles(sDir_Eye, "*.png", "", 0, nMaxNumFiles, 0);
		local nCount = search_result:GetNumOfResult();
		local i;
		for i = 0, nCount - 1 do
			local sFileName = search_result:GetItem(i);
			
			db:exec(string.format("INSERT INTO CartoonFaceDB VALUES (%d, %d, %d, '%s', '', '%s');", 
					componentID, 2, i, sFileName, sFileName));
			
			componentID = componentID + 1;
		end
		search_result:Release();
		
		-- search all eyebrow component files
		local search_result = ParaIO.SearchFiles(sDir_Eyebrow, "*.png", "", 0, nMaxNumFiles, 0);
		local nCount = search_result:GetNumOfResult();
		local i;
		for i = 0, nCount - 1 do
			local sFileName = search_result:GetItem(i);
			
			db:exec(string.format("INSERT INTO CartoonFaceDB VALUES (%d, %d, %d, '%s', '', '%s');", 
					componentID, 3, i, sFileName, sFileName));
			
			componentID = componentID + 1;
		end
		search_result:Release();
		
		-- search all face component files
		local search_result = ParaIO.SearchFiles(sDir_Face, "*.png", "", 0, nMaxNumFiles, 0);
		local nCount = search_result:GetNumOfResult();
		local i;
		for i = 0, nCount - 1 do
			local sFileName = search_result:GetItem(i);
			
			db:exec(string.format("INSERT INTO CartoonFaceDB VALUES (%d, %d, %d, '%s', '', '%s');", 
					componentID, 0, i, sFileName, sFileName));
			
			componentID = componentID + 1;
		end
		search_result:Release();
		
		-- add an empty wrinkle
		db:exec(string.format("INSERT INTO CartoonFaceDB VALUES (%d, %d, %d, '%s', '', '%s');", 
				componentID, 1, 0, "", ""));
		componentID = componentID + 1;
		
		-- search all wrinkle component files
		local search_result = ParaIO.SearchFiles(sDir_FaceDeco, "*.png", "", 0, nMaxNumFiles, 0);
		local nCount = search_result:GetNumOfResult();
		local i;
		for i = 1, nCount do
			local sFileName = search_result:GetItem(i);
			
			db:exec(string.format("INSERT INTO CartoonFaceDB VALUES (%d, %d, %d, '%s', '', '%s');", 
					componentID, 1, i, sFileName, sFileName));
			
			componentID = componentID + 1;
		end
		search_result:Release();
		
		-- add an empty mark
		db:exec(string.format("INSERT INTO CartoonFaceDB VALUES (%d, %d, %d, '%s', '', '%s');", 
				componentID, 6, 0, "", ""));
		componentID = componentID + 1;
		
		-- search all mark component files
		local search_result = ParaIO.SearchFiles(sDir_Mark, "*.png", "", 0, nMaxNumFiles, 0);
		local nCount = search_result:GetNumOfResult();
		local i;
		for i = 1, nCount do
			local sFileName = search_result:GetItem(i);
			
			db:exec(string.format("INSERT INTO CartoonFaceDB VALUES (%d, %d, %d, '%s', '', '%s');", 
					componentID, 6, i, sFileName, sFileName));
			
			componentID = componentID + 1;
		end
		search_result:Release();
		
		-- search all mouth component files
		local search_result = ParaIO.SearchFiles(sDir_Mouth, "*.png", "", 0, nMaxNumFiles, 0);
		local nCount = search_result:GetNumOfResult();
		local i;
		for i = 0, nCount - 1 do
			local sFileName = search_result:GetItem(i);
			
			db:exec(string.format("INSERT INTO CartoonFaceDB VALUES (%d, %d, %d, '%s', '', '%s');", 
					componentID, 4, i, sFileName, sFileName));
			
			componentID = componentID + 1;
		end
		search_result:Release();
		
		-- search all nose component files
		local search_result = ParaIO.SearchFiles(sDir_Nose, "*.png", "", 0, nMaxNumFiles, 0);
		local nCount = search_result:GetNumOfResult();
		local i;
		for i = 0, nCount - 1 do
			local sFileName = search_result:GetItem(i);
			
			db:exec(string.format("INSERT INTO CartoonFaceDB VALUES (%d, %d, %d, '%s', '', '%s');", 
					componentID, 5, i, sFileName, sFileName));
			
			componentID = componentID + 1;
		end
		search_result:Release();
	end
	
	-- close database
	db:close();
end


-- NOTE 2011/9/14: items with different qualitys with the same level shares the same model, we pick out the alternate model ids
local id_model_Alternate_mapping = {};
local id_model_name_mapping = {};

function DB.GetItemDatabaseModelAlternate()
	local db = sqlite3.open(DB.dbfile);
	if(db) then
		for row in db:rows("select id, model from ItemDatabase where id <> model") do
			local id = tonumber(row.id);
			local model = tonumber(row.model);
			if(id ~= model) then
				id_model_Alternate_mapping[id] = model;
			end
		end
		for row in db:rows("select id, name from ItemDatabase") do
			local id = tonumber(row.id);
			local name = row.name;
			id_model_name_mapping[id] = name;
		end
		db:close();
	end
end

function DB.GetAlternateModelFromID(id)
	local alter_id = id_model_Alternate_mapping[id];
	if(alter_id) then
		return {
			id = alter_id,
			name = id_model_name_mapping[alter_id],
		};
	end
end

-- get the inventory information according to tabgrid
function DB.GetInventoryDB2()
	
	NPL.load("(gl)script/kids/3DMapSystemUI/CCS/DB.lua");
	
	if(DB.AuraInventoryID and DB.AuraInventoryPreview) then
		log("Call DB.GetInventoryDB2() multiple times\n");
		return;
	end
	
	DB.AuraInventoryID = {
		[1] = {}, -- head		1
		[2] = {}, -- shouder	1
		[3] = {}, -- shirt		4
		[4] = {}, -- golves		2
		[5] = {}, -- pants		4
		[6] = {}, -- boots		4
		[7] = {}, -- hand left	1
		[8] = {}, -- hand right 1
		[9] = {}, -- cape		1
		};
	
	DB.AuraInventoryPreview = {
		[1] = {}, -- head		1
		[2] = {}, -- shouder	1
		[3] = {}, -- shirt		4
		[4] = {}, -- golves		2
		[5] = {}, -- pants		4
		[6] = {}, -- boots		4
		[7] = {}, -- hand left	1
		[8] = {}, -- hand right 1
		[9] = {}, -- cape		1
		};
	
	local db = sqlite3.open(DB.dbfile);
	
	local row;
	local i;
	local typeStr;
	for i = 1, 9 do
		if(i == 1) then
			-- Head
			typeStr = "1";
		elseif(i == 2) then
			-- Shoulder
			typeStr = "3";
		elseif(i == 3) then
			-- Shirt
			typeStr = "4";
		elseif(i == 4) then
			-- Gloves
			typeStr = "10";
		elseif(i == 5) then
			-- Pants
			typeStr = "7";
		elseif(i == 6) then
			-- Boots
			typeStr = "8";
		elseif(i == 7) then
			-- Hand Left
			typeStr = "11".." or ".."type = 12"
				.." or ".."type = 13".." or ".."type = 14"
				.." or ".."type = 18".." or ".."type = 21"
				.." or ".."type = 22".." or ".."type = 23"
				.." or ".."type = 24".." or ".."type = 25";
		elseif(i == 8) then
			-- Hand Right
			typeStr = "11".." or ".."type = 13"
				.." or ".."type = 15".." or ".."type = 21"
				.." or ".."type = 22".." or ".."type = 24"
				.." or ".."type = 25";
		elseif(i == 9) then
			-- Cape
			typeStr = "16";
		end
		
		local nCount = 1;
		for row in db:rows(string.format("select id from ItemDatabase where type=%s", typeStr)) do
			if(i == 3) then
				-- shirt
				if(nCount <= 3) then
					-- discard the first 3 shirts
				else
					DB.AuraInventoryID[i][nCount - 3] = tonumber(row.id);
				end
			elseif(i == 5) then
				-- pants
				if(nCount <= 4) then
					-- discard the first 4 pants
				else
					DB.AuraInventoryID[i][nCount - 4] = tonumber(row.id);
				end
			elseif(i == 6) then
				-- gloves
				if(nCount <= 1) then
					-- discard the first gloves
				else
					DB.AuraInventoryID[i][nCount - 1] = tonumber(row.id);
				end
			elseif(i == 4) then
				-- boots
				if(nCount <= 1) then
					-- discard the first boots
				else
					DB.AuraInventoryID[i][nCount - 1] = tonumber(row.id);
				end
			else
				DB.AuraInventoryID[i][nCount] = tonumber(row.id);
			end
			nCount = nCount + 1;
		end
		
		local j;
		for j = 1, 9 do
			if(j == 1 or j == 2 or j == 7 or j == 8 or j == 9) then
				-- Head Shoulder HandLeft/Right Cape
				local k, v;
				for k, v in pairs(DB.AuraInventoryID[j]) do
					local row;
					local model, skin;
					for row in db:rows(string.format("select Model, Skin from ItemDisplayDB where ItemDisplayID = %d", v)) do
						model = row.Model;
						skin = row.Skin;
					end
					
					if(string.find(string.lower(model), ".x") == nil) then
						model = model..".x";
					end
					
					if(string.find(string.lower(skin), ".dds") == nil) then
						skin = skin..".dds";
					end
					
					if(j == 1) then
						model = "character/v3/Item/ObjectComponents/Head/"..model;
					elseif(j == 2) then
						model = "character/v3/Item/ObjectComponents/Shoulder/"..model;
					elseif(j == 7 or j == 8) then
						model = "character/v3/Item/ObjectComponents/Weapon/"..model;
					elseif(j == 9) then
						-- TODO: unisex unirace cape model
						model = "character/v3/Item/ObjectComponents/Cape/"..model;
					end
					
					DB.AuraInventoryPreview[j][k] = {
						model = model,
						skin = {
						},
					};
				end
			elseif(j == 3) then
				-- Shirt
				local k, v;
				for k, v in pairs(DB.AuraInventoryID[j]) do
					local row;
					local texTU; -- Chest Upper;
					local texTL; -- Chest Lower;
					local texAU; -- Arm Upper;
					local texAL; -- Arm Lower;
					local geoSet;
					local modelName;
					for row in db:rows(string.format("select GeosetA, TexChestUpper, TexChestLower, TexArmUpper, TexArmLower from ItemDisplayDB where ItemDisplayID = %d", v)) do
						texTU = row.TexChestUpper;
						texTL = row.TexChestLower;
						texAU = row.TexArmUpper;
						texAL = row.TexArmLower;
						geoSet = tonumber(row.GeosetA);
					end
					
					if(texTU ~= nil and string.find(texTU, ".dds") == nil and string.find(texTU, ".DDS") == nil) then
						texTU = texTU..".dds";
					end
					if(texTL ~= nil and string.find(texTL, ".dds") == nil and string.find(texTL, ".DDS") == nil) then
						texTL = texTL..".dds";
					end
					if(texAU ~= nil and string.find(texAU, ".dds") == nil and string.find(texAU, ".DDS") == nil) then
						texAU = texAU..".dds";
					end
					if(texAL ~= nil and string.find(texAL, ".dds") == nil and string.find(texAL, ".DDS") == nil) then
						texAL = texAL..".dds";
					end
					
					if(texTU ~= nil) then
						texTU = "character/v3/Item/TextureComponents/TorsoUpperTexture/"..texTU;
					else
						--texTU = "texture/whitedot.PNG";
						--texTU = nil;
					end
					if(texTL ~= nil) then
						texTL = "character/v3/Item/TextureComponents/TorsoLowerTexture/"..texTL;
					else
						--texTL = "texture/whitedot.PNG";
						--texTL = nil;
					end
					if(texAU ~= nil) then
						texAU = "character/v3/Item/TextureComponents/ArmUpperTexture/"..texAU;
					else
						--texAU = "texture/whitedot.png";
						--texAU = nil;
					end
					if(texAL ~= nil) then
						texAL = "character/v3/Item/TextureComponents/ArmLowerTexture/"..texAL;
					else
						--texAL = "texture/whitedot.png";
						--texAU = nil;
					end
					
					if(geoSet == 0) then
						modelName = "model/common/ccs_unisex/shirt001_TU1_TL2_AU3_AL4.x";
						if(texAL == "character/v3/Item/TextureComponents/ArmLowerTexture/.dds") then
							texAL = nil;
						end
					elseif(geoSet == 1) then
						modelName = "model/common/ccs_unisex/shirt002_TU1_TL2_AU3.x";
						texAL = nil;
					elseif(geoSet == 2) then
						--modelName = "model/common/ccs_unisex/shirt002_TU1_TL2_AU3.x";
						--modelName = "model/common/ccs_unisex/shirt001_TU1_TL2_AU3_AL4.x";
						
						modelName = "model/common/ccs_unisex/shirt003_TU1_TL2.x";
						--texAU = "model/common/ccs_unisex/256_128.dds";
						--texAL = "model/common/ccs_unisex/256_128.dds";
						
						--local skin = {
							--[1] = texTU,
							--[2] = texTL,
							--[3] = texAU,
							--[4] = texAL,
						--};
						--commonlib.log(skin);
						
					elseif(geoSet == 3) then
						modelName = "model/common/ccs_unisex/shirt004_TU1_TL2_AU3_AL4.x";
						--modelName = "model/common/ccs_unisex/shirt003_TU1_TL2_AU3_AL4.x";
						
						--modelName = "model/common/ccs_unisex/shirt002_TU1_TL2_AU3.x";
						--texAL = nil;
						
					elseif(geoSet == 4) then
					end
					
					DB.AuraInventoryPreview[j][k] = {
						model = modelName,
						skin = {
							[1] = texTU,
							[2] = texTL,
							[3] = texAU,
							[4] = texAL,
						},
					};
					
					--if(geoSet == 0 or geoSet == 1) then
						--modelName = "model/common/ccs_unisex/shirt02_TU1_AU2_AL3.x";
						----modelName = "model/common/ccs_unisex/shirt002_TU1_TL2_AU3_AL4.x";
						--DB.AuraInventoryPreview[j][k] = {
							--model = modelName,
							--skin = {
								----[1] = texTU,
								----[2] = texTL,
								----[3] = texAU,
								----[4] = texAL,
								--[1] = texTU,
								--[2] = texAU,
								--[3] = texAL,
							--},
						--};
					--elseif(geoSet == 2) then
						--modelName = "model/common/ccs_unisex/shirt03_TU1_TL2_AU3_AL4.x";
						----modelName = "model/common/ccs_unisex/shirt003_TU1_TL2_AU3_AL4.x";
						--DB.AuraInventoryPreview[j][k] = {
							--model = modelName,
							--skin = {
								--[1] = texTU,
								--[2] = texTL,
								--[3] = texAU,
								--[3] = texAL,
							--},
						--};
					--elseif(geoSet == 3) then
						--modelName = "model/common/ccs_unisex/shirt04_TU1_AU2.x";
						----modelName = "model/common/ccs_unisex/shirt004_TU1_TL2_AU3_AL4.x";
						--DB.AuraInventoryPreview[j][k] = {
							--model = modelName,
							--skin = {
								--[1] = texTU,
								--[2] = texAU,
							--},
						--};
					--elseif(geoSet == 4) then
						--modelName = "model/common/ccs_unisex/shirt05_TU1_AU2_AL3.x";
						--DB.AuraInventoryPreview[j][k] = {
							--model = modelName,
							--skin = {
								--[1] = texTU,
								--[2] = texAU,
								--[3] = texAL,
							--},
						--};
					--elseif(geoSet == 5) then
						--modelName = "model/common/ccs_unisex/shirt06_TU1_TL2_AU3_AL4.x";
						--DB.AuraInventoryPreview[j][k] = {
							--model = modelName,
							--skin = {
								--[1] = texTU,
								--[2] = texTL,
								--[3] = texAU,
								--[3] = texAL,
							--},
						--};
					--end
				end
			elseif(j == 4) then
				-- Gloves
				local k, v;
				for k, v in pairs(DB.AuraInventoryID[j]) do
					local geoSet;
					local row;
					local texName;
					local modelName;
					for row in db:rows(string.format("select GeosetA, TexHands from ItemDisplayDB where ItemDisplayID = %d", v)) do
						
						geoSet = row.GeosetA;
						texName = row.TexHands;
						if(string.find(texName, ".dds") == nil and string.find(texName, ".DDS") == nil) then
							texName = texName..".dds";
						end
						texName = "character/v3/Item/TextureComponents/HandTexture/"..texName;
						modelName = "model/common/ccs_unisex/hand02_Hr2.x";
						
						if(geoSet == 0 or geoSet == 1) then
							modelName = "model/common/ccs_unisex/hand002_Hr2.x";
						elseif(geoSet == 2) then
							modelName = "model/common/ccs_unisex/hand003_Hr2.x";
						elseif(geoSet == 3) then
							modelName = "model/common/ccs_unisex/hand004_Hr2.x";
						end
					end
					
					DB.AuraInventoryPreview[j][k] = {
						model = modelName,
						skin = {
							[2] = texName,
						},
					};
				end
			elseif(j == 5) then
				-- Pants
				local k, v;
				for k, v in pairs(DB.AuraInventoryID[j]) do
					local row;
					local geoSet;
					local texLU; -- leg upper
					local texLL; -- leg lower
					local modelName;
					for row in db:rows(string.format("select GeosetB, TexLegUpper, TexLegLower from ItemDisplayDB where ItemDisplayID = %d", v)) do
						texLU = row.TexLegUpper or "";
						texLL = row.TexLegLower or "";
						geoSet = tonumber(row.GeosetB);
					end
					
					if(texLU ~= "" and string.find(texLU, ".dds") == nil and string.find(texLU, ".DDS") == nil) then
						texLU = texLU..".dds";
					end
					if(texLL ~= "" and string.find(texLL, ".dds") == nil and string.find(texLL, ".DDS") == nil) then
						texLL = texLL..".dds";
					end
					if(texLU ~= "") then
						texLU = "character/v3/Item/TextureComponents/LegUpperTexture/"..texLU;
					else
						--texLU = "texture/skill_bro.png";
					end
					if(texLL ~= "") then
						texLL = "character/v3/Item/TextureComponents/LegLowerTexture/"..texLL;
					else
						--texLL = "texture/skill_bro.png";
					end
					
					--if(geoSet == 0 or geoSet == 1) then
						--modelName = "model/common/ccs_unisex/pants02_LU1_LL2.x";
					--elseif(geoSet == 2) then
						--modelName = "model/common/ccs_unisex/pants03_LU1_LL2.x";
					--elseif(geoSet == 3) then
						--modelName = "model/common/ccs_unisex/pants04_LU1_LL2.x";
					--elseif(geoSet == 4) then
						--modelName = "model/common/ccs_unisex/pants05_LU1_LL2.x";
					--elseif(geoSet == 5) then
						--modelName = "model/common/ccs_unisex/pants06_LU1_LL2.x";
					--end
					
					if(geoSet == 0) then
						modelName = "model/common/ccs_unisex/pants001_LU1_LL2.x";
					elseif(geoSet == 1) then
						modelName = "model/common/ccs_unisex/pants002_LU1_LL2.x";
					elseif(geoSet == 2) then
						modelName = "model/common/ccs_unisex/pants003_LU1.x";
						texLL = nil;
					elseif(geoSet == 3) then
						modelName = "model/common/ccs_unisex/pants004_LU1_LL2.x";
					elseif(geoSet == 4) then
						modelName = "model/common/ccs_unisex/pants005_LU1.x";
						texLL = nil;
					elseif(geoSet == 5) then
						modelName = "model/common/ccs_unisex/pants006_LU1.x";
						texLL = nil;
					end
					
					DB.AuraInventoryPreview[j][k] = {
						model = modelName,
						skin = {
							[1] = texLU,
							[2] = texLL,
						},
					};
				end
			elseif(j == 6) then
				-- Boots
				local k, v;
				for k, v in pairs(DB.AuraInventoryID[j]) do
					local geoSet;
					local row;
					local texName;
					local modelName;
					for row in db:rows(string.format("select GeosetA, TexFeet from ItemDisplayDB where ItemDisplayID = %d", v)) do
						
						texName = row.TexFeet;
						geoSet = row.GeosetA;
						if(string.find(texName, ".dds") == nil and string.find(texName, ".DDS") == nil) then
							texName = texName..".dds";
						end
						texName = "character/v3/Item/TextureComponents/FootTexture/"..texName;
						
						if(geoSet == 0) then
							modelName = "model/common/ccs_unisex/boots001_FTr2.x";
						elseif(geoSet == 1) then
							modelName = "model/common/ccs_unisex/boots002_FTr2.x";
						elseif(geoSet == 2) then
							modelName = "model/common/ccs_unisex/boots003_FTr2.x";
						elseif(geoSet == 3) then
							modelName = "model/common/ccs_unisex/boots004_FTr2.x";
						elseif(geoSet == 4) then
							modelName = "model/common/ccs_unisex/boots005_FTr2.x";
						end
						
					end
					
					DB.AuraInventoryPreview[j][k] = {
						model = modelName,
						skin = {
							[2] = texName,
						},
						GeoSetA = geoSet,
					};
				end
			end
		end
	end
	db:close();
end