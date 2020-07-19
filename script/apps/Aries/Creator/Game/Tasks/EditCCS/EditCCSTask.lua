--[[
Title: advanced CCS modification page
Author(s): WangTian, LiXizhi
Date: 2020/7/16
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EditCCS/EditCCSTask.lua");
local EditCCSTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.EditCCSTask");
-- method1:
local task = EditCCSTask:new({entity=entity, callbackFunc=function(ccs) end});
task:Run();
-- method2:
EditCCSTask:ShowPage(entity, function(ccs)
end);
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
NPL.load("(gl)script/kids/3DMapSystemUI/CCS/ccs.lua");
local CCS = commonlib.gettable("Map3DSystem.UI.CCS");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

-- create class
local EditCCSTask = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.EditCCSTask"));

local curInstance;
local curPlayer;
local page;
-- this is always a top level task. 
EditCCSTask.is_top_level = true;

function EditCCSTask:ctor()
end


function EditCCSTask:GetPlayer()
	return curPlayer;
end

function EditCCSTask:Run()
	curInstance = self;
	self.finished = false;
	self:ShowPage(self.entity, self.callbackFunc);
end

function EditCCSTask:OnExit()
	self:SetFinished();
	curInstance = nil;
	if(page) then
		page:CloseWindow();
	end
end

-- this function can be called as a static function. 
-- @param callbackFunc: function(ccs) end
function EditCCSTask:ShowPage(entity, callbackFunc)
	entity = entity or EntityManager.GetPlayer()
	if(not entity:IsCustomModel()) then
		entity:SetMainAssetPath("character/v3/Elf/Female/ElfFemale.xml")
	end
	curPlayer = entity:GetInnerObject();


	NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
	local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
	local viewport = ViewportManager:GetSceneViewport();
	local parent = viewport:GetUIObject(true)

	
	local width, height = 400, 600;
	local params = {
		url="script/apps/Aries/Creator/Game/Tasks/EditCCS/EditCCSTask.html",
		name="EditCCSTask", 
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		isShowTitleBar = false,
		bShow = true,
		DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		isTopLevel = true, 
		directPosition = true,
			align = "_ctl",
			x = 10,
			y = 0,
			width = width,
			height = height,
	}
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	params._page.OnClose = function(bDestroy)
		local ccsString = CCS.GetCCSInfoString(curPlayer);
		curPlayer = nil;
		page = nil;
		if(curInstance) then
			curInstance:OnExit()
		end
		if(callbackFunc) then
			callbackFunc(ccsString);
		end
	end
end



-- on init show the current avatar in pe:avatar
function EditCCSTask.OnInit()
	page = document:GetPageCtrl();
end

function EditCCSTask.UpdateDragonSkin_Purple()
	EditCCSTask.UpdateDragonSkin(1)
end

function EditCCSTask.UpdateDragonSkin_Red()
	EditCCSTask.UpdateDragonSkin(2)
end

function EditCCSTask.UpdateDragonSkin_Green()
	EditCCSTask.UpdateDragonSkin(3)
end

function EditCCSTask.UpdateDragonSkin_Orange()
	EditCCSTask.UpdateDragonSkin(4)
end

function EditCCSTask.UpdateDragonSkin_DarkPurple()
	EditCCSTask.UpdateDragonSkin(5)
end

function EditCCSTask.UpdateDragonSkin_DarkRed()
	EditCCSTask.UpdateDragonSkin(6)
end

function EditCCSTask.UpdateDragonSkin(i)
	local replaceable_r1;
	local assetname = curPlayer:GetPrimaryAsset():GetKeyName();
	if(string.find(assetname, "character/v3/PurpleDragonMajor/Female/")) then
		replaceable_r1 = "character/v3/PurpleDragonMajor/Female/SkinColor0"..i..".dds";
	end
	if(replaceable_r1) then
		curPlayer:SetReplaceableTexture(1, ParaAsset.LoadTexture("", replaceable_r1, 1));
	end
end

function EditCCSTask.OnChangeAsset()
	--local _obj = Map3DSystem.obj.GetObject(Map3DSystem.App.Creator.target);
	local _obj = curPlayer;
	if(_obj ~= nil and _obj:IsValid())then
		local newasset = document:GetPageCtrl():GetUIValue("newasset");
		if(newasset) then
			local asset = ParaAsset.LoadParaX("", newasset);
			_obj:ToCharacter():ResetBaseModel(asset);
		end
	end	
end

function EditCCSTask.ClickDBUpdate()
	_guihelper.MessageBox("确认更新数据库？\n\n请确认database/characters.db文件为只读，数据更新需要花些时间，请耐心等待\n", function ()
				Map3DSystem.UI.CCS.DB.AutoGenerateItems();
				_guihelper.CloseMessageBox();
			end);
end

function EditCCSTask.ClickLeftHandUpdate(name, mcmlNode)
	if(mcmlNode) then
        local gsid = mcmlNode:GetNumber("gsid");
        if(gsid) then
			EditCCSTask.HandUpdate(gsid, 0);
		end
	end
end

function EditCCSTask.ClickRightHandUpdate(name, mcmlNode)
	if(mcmlNode) then
        local gsid = mcmlNode:GetNumber("gsid");
        if(gsid) then
			EditCCSTask.HandUpdate(gsid, 1);
		end
	end
end

function EditCCSTask.ClickHatUpdate(name, mcmlNode)
	if(mcmlNode) then
        local gsid = mcmlNode:GetNumber("gsid");
        if(gsid) then
			local playerChar = curPlayer:ToCharacter();
			playerChar:SetCharacterSlot(0, 0);
		end
	end
end

function EditCCSTask.ClickBackUpdate(name, mcmlNode)
	if(mcmlNode) then
        local gsid = mcmlNode:GetNumber("gsid");
        if(gsid) then
			local playerChar = curPlayer:ToCharacter();
			playerChar:SetCharacterSlot(26, 0);
		end
	end
end

function EditCCSTask.HandUpdate(gsid, hand)
	local playerChar = curPlayer:ToCharacter();
	if(gsid and hand == 0) then
		playerChar:SetCharacterSlot(11, gsid);
	elseif(gsid and hand == 1) then
		playerChar:SetCharacterSlot(10, gsid);
	end
end

function EditCCSTask.ClickAvaterUpdate(name, mcmlNode)
    if(mcmlNode) then
        local gsid = mcmlNode:GetNumber("gsid");
        local slot = mcmlNode:GetNumber("slot");
        if(gsid and slot) then
			local playerChar = curPlayer:ToCharacter();

			playerChar:SetCharacterSlot(slot, gsid);

        elseif(gsid) then
			local playerChar = curPlayer:ToCharacter();
			
			if(gsid == 10) then
				playerChar:SetCharacterSlot(16, 10);
			elseif(gsid == 11) then
				playerChar:SetCharacterSlot(16, 11);
			end
			
			if(gsid == 1001) then
				playerChar:SetCharacterSlot(16, 1001);
			elseif(gsid == 1002) then
				playerChar:SetCharacterSlot(17, 1002);
			elseif(gsid == 1003) then
				playerChar:SetCharacterSlot(18, 1003);
			elseif(gsid == 1004) then
				playerChar:SetCharacterSlot(19, 1004);
			elseif(gsid == 1005) then
				playerChar:SetCharacterSlot(16, 1005);
			elseif(gsid == 1006) then
				playerChar:SetCharacterSlot(17, 1006);
			elseif(gsid == 1007) then
				playerChar:SetCharacterSlot(19, 1007);
			elseif(gsid == 1008) then
				playerChar:SetCharacterSlot(16, 1008);
			elseif(gsid == 1009) then
				playerChar:SetCharacterSlot(17, 1009);
			elseif(gsid == 1010) then
				playerChar:SetCharacterSlot(19, 1010);
			elseif(gsid == 1011) then
				playerChar:SetCharacterSlot(0, 1011);
				
			elseif(gsid == 1021) then
				playerChar:SetCharacterSlot(20, 1021);
				
			elseif(gsid == 1023) then
				playerChar:SetCharacterSlot(16, 1023);
			elseif(gsid == 1024) then
				playerChar:SetCharacterSlot(19, 1024);
			elseif(gsid == 1025) then
				playerChar:SetCharacterSlot(0, 1025);
			elseif(gsid == 1026) then
				playerChar:SetCharacterSlot(17, 1026);
			elseif(gsid == 1027) then
				playerChar:SetCharacterSlot(16, 1027);
			elseif(gsid == 1028) then
				playerChar:SetCharacterSlot(17, 1028);
			elseif(gsid == 1029) then
				playerChar:SetCharacterSlot(17, 1029);
			elseif(gsid == 1030) then
				playerChar:SetCharacterSlot(19, 1030);
			elseif(gsid == 1031) then
				playerChar:SetCharacterSlot(19, 1031);
			elseif(gsid == 1032) then
				playerChar:SetCharacterSlot(18, 1032);
			elseif(gsid == 1033) then
				playerChar:SetCharacterSlot(19, 1033);
			elseif(gsid == 1034) then
				playerChar:SetCharacterSlot(16, 1034);
			elseif(gsid == 1035) then
				playerChar:SetCharacterSlot(17, 1035);
			elseif(gsid == 1036) then
				playerChar:SetCharacterSlot(17, 1036);
			elseif(gsid == 1037) then
				playerChar:SetCharacterSlot(16, 1037);
			elseif(gsid == 1038) then
				playerChar:SetCharacterSlot(17, 1038);
			elseif(gsid == 1039) then
				playerChar:SetCharacterSlot(16, 1039);
			elseif(gsid == 1040) then
				playerChar:SetCharacterSlot(17, 1040);
			end
			
			if(gsid == 11001) then
				playerChar:SetCharacterSlot(22, 11001);
			elseif(gsid == 11002) then
				playerChar:SetCharacterSlot(23, 11002);
			elseif(gsid == 11003) then
				playerChar:SetCharacterSlot(24, 11003);
			elseif(gsid == 11004) then
				playerChar:SetCharacterSlot(25, 11004);
			elseif(gsid == 11005) then
				playerChar:SetCharacterSlot(22, 11005);
			elseif(gsid == 11006) then
				playerChar:SetCharacterSlot(23, 11006);
			elseif(gsid == 11007) then
				playerChar:SetCharacterSlot(24, 11007);
			elseif(gsid == 11008) then
				playerChar:SetCharacterSlot(25, 11008);
			end
			
			if(gsid == 1041) then
				playerChar:SetCharacterSlot(16, 1041);
			elseif(gsid == 1043) then
				playerChar:SetCharacterSlot(17, 1043);
			elseif(gsid == 1045) then
				playerChar:SetCharacterSlot(19, 1045);
			elseif(gsid == 1042) then
				playerChar:SetCharacterSlot(16, 1042);
			elseif(gsid == 1044) then
				playerChar:SetCharacterSlot(17, 1044);
			elseif(gsid == 1046) then
				playerChar:SetCharacterSlot(19, 1046);
			elseif(gsid == 1047) then
				playerChar:SetCharacterSlot(16, 1047);
			elseif(gsid == 1048) then
				playerChar:SetCharacterSlot(17, 1048);
			elseif(gsid == 1049) then
				playerChar:SetCharacterSlot(19, 1049);
			end
			
			if(gsid == 1050) then
				playerChar:SetCharacterSlot(16, 1050);
			elseif(gsid == 1051) then
				playerChar:SetCharacterSlot(17, 1051);
			elseif(gsid == 1052) then
				playerChar:SetCharacterSlot(19, 1052);
			elseif(gsid == 1053) then
				playerChar:SetCharacterSlot(16, 1053);
			elseif(gsid == 1054) then
				playerChar:SetCharacterSlot(17, 1054);
			elseif(gsid == 1055) then
				playerChar:SetCharacterSlot(19, 1055);
			elseif(gsid == 1056) then
				playerChar:SetCharacterSlot(16, 1056);
			elseif(gsid == 1057) then
				playerChar:SetCharacterSlot(17, 1057);
			elseif(gsid == 1058) then
				playerChar:SetCharacterSlot(19, 1058);
			elseif(gsid == 1059) then
				playerChar:SetCharacterSlot(16, 1059);
			elseif(gsid == 1060) then
				playerChar:SetCharacterSlot(17, 1060);
			elseif(gsid == 1061) then
				playerChar:SetCharacterSlot(19, 1061);
			elseif(gsid == 1062) then
				playerChar:SetCharacterSlot(16, 1062);
			elseif(gsid == 1063) then
				playerChar:SetCharacterSlot(17, 1063);
			elseif(gsid == 1064) then
				playerChar:SetCharacterSlot(19, 1064);
			elseif(gsid == 1103) then
				playerChar:SetCharacterSlot(16, 1103);
			elseif(gsid == 1104) then
				playerChar:SetCharacterSlot(17, 1104);
			elseif(gsid == 1105) then
				playerChar:SetCharacterSlot(19, 1105);
			end
			
			if(gsid == 1065) then
				playerChar:SetCharacterSlot(21, 1065);
			end
			
			if(gsid == 1066) then
				playerChar:SetCharacterSlot(16, 1066);
			elseif(gsid == 1067) then
				playerChar:SetCharacterSlot(17, 1067);
			elseif(gsid == 1068) then
				playerChar:SetCharacterSlot(19, 1068);
			elseif(gsid == 1069) then
				playerChar:SetCharacterSlot(16, 1069);
			elseif(gsid == 1070) then
				playerChar:SetCharacterSlot(17, 1070);
			elseif(gsid == 1071) then
				playerChar:SetCharacterSlot(19, 1071);
			elseif(gsid == 1072) then
				playerChar:SetCharacterSlot(16, 1072);
			elseif(gsid == 1073) then
				playerChar:SetCharacterSlot(17, 1073);
			elseif(gsid == 1074) then
				playerChar:SetCharacterSlot(19, 1074);
			elseif(gsid == 1075) then
				playerChar:SetCharacterSlot(16, 1075);
			elseif(gsid == 1076) then
				playerChar:SetCharacterSlot(17, 1076);
			elseif(gsid == 1077) then
				playerChar:SetCharacterSlot(19, 1077);
			elseif(gsid == 1078) then
				playerChar:SetCharacterSlot(0, 1078);
			elseif(gsid == 1079) then
				playerChar:SetCharacterSlot(18, 1079);
			elseif(gsid == 1080) then
				playerChar:SetCharacterSlot(16, 1080);
			elseif(gsid == 1081) then
				playerChar:SetCharacterSlot(17, 1081);
			end
			
			if(gsid == 1082) then
				playerChar:SetCharacterSlot(0, 1082);
			elseif(gsid == 1083) then
				playerChar:SetCharacterSlot(16, 1083);
			elseif(gsid == 1084) then
				playerChar:SetCharacterSlot(17, 1084);
			elseif(gsid == 1085) then
				playerChar:SetCharacterSlot(0, 1085);
			elseif(gsid == 1086) then
				playerChar:SetCharacterSlot(16, 1086);
			elseif(gsid == 1087) then
				playerChar:SetCharacterSlot(0, 1087);
			elseif(gsid == 1088) then
				playerChar:SetCharacterSlot(16, 1088);
			elseif(gsid == 1089) then
				playerChar:SetCharacterSlot(17, 1089);
			elseif(gsid == 1090) then
				playerChar:SetCharacterSlot(0, 1090);
			elseif(gsid == 1091) then
				playerChar:SetCharacterSlot(16, 1091);
			elseif(gsid == 1092) then
				playerChar:SetCharacterSlot(16, 1092);
			elseif(gsid == 1093) then
				playerChar:SetCharacterSlot(17, 1093);
			elseif(gsid == 1094) then
				playerChar:SetCharacterSlot(17, 1094);
			elseif(gsid == 1095) then
				playerChar:SetCharacterSlot(19, 1095);
			elseif(gsid == 1096) then
				playerChar:SetCharacterSlot(0, 1096);
			elseif(gsid == 1097) then
				playerChar:SetCharacterSlot(16, 1097);
			elseif(gsid == 1098) then
				playerChar:SetCharacterSlot(17, 1098);
			elseif(gsid == 1099) then
				playerChar:SetCharacterSlot(19, 1099);
			elseif(gsid == 1100) then
				playerChar:SetCharacterSlot(19, 1100);
			elseif(gsid == 1101) then
				playerChar:SetCharacterSlot(17, 1101);
			elseif(gsid == 1102) then
				playerChar:SetCharacterSlot(18, 1102);
			elseif(gsid == 1103) then
				playerChar:SetCharacterSlot(16, 1103);
			elseif(gsid == 1104) then
				playerChar:SetCharacterSlot(17, 1104);
			elseif(gsid == 1105) then
				playerChar:SetCharacterSlot(19, 1105);
			elseif(gsid == 1106) then
				playerChar:SetCharacterSlot(26, 1106);
			end
			
			if(gsid == 1107) then
				playerChar:SetCharacterSlot(16, 1107);
			elseif(gsid == 1108) then
				playerChar:SetCharacterSlot(17, 1108);
			elseif(gsid == 1109) then
				playerChar:SetCharacterSlot(19, 1109);
			elseif(gsid == 1110) then
				playerChar:SetCharacterSlot(18, 1110);
			elseif(gsid == 1111) then
				playerChar:SetCharacterSlot(16, 1111);
			elseif(gsid == 1112) then
				playerChar:SetCharacterSlot(17, 1112);
			elseif(gsid == 1113) then
				playerChar:SetCharacterSlot(19, 1113);
			elseif(gsid == 1114) then
				playerChar:SetCharacterSlot(18, 1114);
			elseif(gsid == 1115) then
				playerChar:SetCharacterSlot(16, 1115);
			elseif(gsid == 1116) then
				playerChar:SetCharacterSlot(17, 1116);
			elseif(gsid == 1117) then
				playerChar:SetCharacterSlot(19, 1117);
			elseif(gsid == 1118) then
				playerChar:SetCharacterSlot(18, 1118);
				
			elseif(gsid == 1119) then
				playerChar:SetCharacterSlot(16, 1119);
			elseif(gsid == 1120) then
				playerChar:SetCharacterSlot(17, 1120);
			elseif(gsid == 1121) then
				playerChar:SetCharacterSlot(19, 1121);
			--elseif(gsid == 1122) then
				--playerChar:SetCharacterSlot(18, 1122);
			elseif(gsid == 1123) then
				playerChar:SetCharacterSlot(16, 1123);
			elseif(gsid == 1124) then
				playerChar:SetCharacterSlot(17, 1124);
			elseif(gsid == 1125) then
				playerChar:SetCharacterSlot(19, 1125);
			--elseif(gsid == 1126) then
				--playerChar:SetCharacterSlot(18, 1126);
			elseif(gsid == 1127) then
				playerChar:SetCharacterSlot(16, 1127);
			elseif(gsid == 1128) then
				playerChar:SetCharacterSlot(17, 1128);
			elseif(gsid == 1129) then
				playerChar:SetCharacterSlot(19, 1129);
			--elseif(gsid == 1130) then
				--playerChar:SetCharacterSlot(18, 1130);
			elseif(gsid == 1131) then
				playerChar:SetCharacterSlot(19, 1131);
			elseif(gsid == 1132) then
				playerChar:SetCharacterSlot(19, 1132);
			elseif(gsid == 1133) then
				playerChar:SetCharacterSlot(19, 1133);
			elseif(gsid == 1134) then
				playerChar:SetCharacterSlot(19, 1134);
			end
			
			if(gsid == 1021) then
				playerChar:SetCharacterSlot(20, 1021);
			elseif(gsid == 1135) then
				playerChar:SetCharacterSlot(20, 1135);
			end
			
			if(gsid == 1138) then
				playerChar:SetCharacterSlot(16, 1138);
			elseif(gsid == 1139) then
				playerChar:SetCharacterSlot(17, 1139);
			elseif(gsid == 1140) then
				playerChar:SetCharacterSlot(19, 1140);
			elseif(gsid == 1148) then
				playerChar:SetCharacterSlot(18, 1148);
			elseif(gsid == 1141) then
				playerChar:SetCharacterSlot(16, 1141);
			elseif(gsid == 1142) then
				playerChar:SetCharacterSlot(17, 1142);
			elseif(gsid == 1143) then
				playerChar:SetCharacterSlot(19, 1143);
			elseif(gsid == 1149) then
				playerChar:SetCharacterSlot(18, 1149);
			elseif(gsid == 1144) then
				playerChar:SetCharacterSlot(16, 1144);
			elseif(gsid == 1145) then
				playerChar:SetCharacterSlot(17, 1145);
			elseif(gsid == 1146) then
				playerChar:SetCharacterSlot(19, 1146);
			end
			
			if(gsid == 1136) then
				playerChar:SetCharacterSlot(0, 1136);
			elseif(gsid == 1137) then
				playerChar:SetCharacterSlot(0, 1137);
			end
			
			if(gsid == 1150) then
				playerChar:SetCartoonFaceComponent(6, 0, 1150);
			end
			
			if(gsid == 1151) then
				playerChar:SetCharacterSlot(16, 1151);
			elseif(gsid == 1152) then
				playerChar:SetCharacterSlot(17, 1152);
			elseif(gsid == 1153) then
				playerChar:SetCharacterSlot(19, 1153);
			elseif(gsid == 1154) then
				playerChar:SetCharacterSlot(16, 1154);
			elseif(gsid == 1155) then
				playerChar:SetCharacterSlot(17, 1155);
			end
			
			if(gsid == 1158) then
				playerChar:SetCharacterSlot(16, gsid);
			elseif(gsid == 1159) then
				playerChar:SetCharacterSlot(17, gsid);
			elseif(gsid == 1160) then
				playerChar:SetCharacterSlot(19, gsid);
			elseif(gsid == 1161) then
				playerChar:SetCharacterSlot(16, gsid);
			elseif(gsid == 1162) then
				playerChar:SetCharacterSlot(17, gsid);
			elseif(gsid == 1163) then
				playerChar:SetCharacterSlot(19, gsid);
			elseif(gsid == 1164) then
				playerChar:SetCharacterSlot(16, gsid);
			elseif(gsid == 1165) then
				playerChar:SetCharacterSlot(17, gsid);
			elseif(gsid == 1166) then
				playerChar:SetCharacterSlot(19, gsid);
			elseif(gsid == 1167) then
				playerChar:SetCharacterSlot(16, gsid);
			elseif(gsid == 1168) then
				playerChar:SetCharacterSlot(17, gsid);
			elseif(gsid == 1169) then
				playerChar:SetCharacterSlot(19, gsid);
			elseif(gsid == 1170) then
				playerChar:SetCharacterSlot(16, gsid);
			elseif(gsid == 1171) then
				playerChar:SetCharacterSlot(17, gsid);
			elseif(gsid == 1172) then
				playerChar:SetCharacterSlot(19, gsid);
			elseif(gsid == 1173) then
				playerChar:SetCharacterSlot(16, gsid);
			elseif(gsid == 1174) then
				playerChar:SetCharacterSlot(17, gsid);
			elseif(gsid == 1175) then
				playerChar:SetCharacterSlot(19, gsid);
			elseif(gsid == 1176) then
				playerChar:SetCharacterSlot(16, gsid);
			elseif(gsid == 1177) then
				playerChar:SetCharacterSlot(17, gsid);
			--elseif(gsid == 1178) then
				-- used as a new flamingcrystalguy gear
				--playerChar:SetCharacterSlot(19, gsid);
			elseif(gsid == 1179) then
				playerChar:SetCharacterSlot(16, gsid);
			elseif(gsid == 1180) then
				playerChar:SetCharacterSlot(17, gsid);
			elseif(gsid == 1181) then
				playerChar:SetCharacterSlot(19, gsid);
			elseif(gsid == 1182) then
				playerChar:SetCharacterSlot(16, gsid);
			elseif(gsid == 1183) then
				playerChar:SetCharacterSlot(17, gsid);
			elseif(gsid == 1184) then
				playerChar:SetCharacterSlot(19, gsid);
			elseif(gsid == 1185) then -- watermelon hat
				playerChar:SetCharacterSlot(0, gsid);
			elseif(gsid == 1186) then -- watermelon hat
				playerChar:SetCharacterSlot(18, gsid);
			end
			
			if(gsid == 1190) then
				playerChar:SetCharacterSlot(16, 1190);
			elseif(gsid == 1191) then
				playerChar:SetCharacterSlot(0, 1191);
			elseif(gsid == 1192) then
				playerChar:SetCharacterSlot(16, 1192);
			elseif(gsid == 1193) then
				playerChar:SetCharacterSlot(17, 1193);
			elseif(gsid == 1194) then
				playerChar:SetCharacterSlot(18, 1194);
			elseif(gsid == 1195) then
				playerChar:SetCharacterSlot(19, 1195);
			elseif(gsid == 1196) then
				playerChar:SetCharacterSlot(0, 1196);
			elseif(gsid == 1197) then
				playerChar:SetCharacterSlot(16, 1197);
			elseif(gsid == 1198) then
				playerChar:SetCharacterSlot(17, 1198);
			elseif(gsid == 1199) then
				playerChar:SetCharacterSlot(18, 1199);
			elseif(gsid == 1200) then
				playerChar:SetCharacterSlot(19, 1200);
			elseif(gsid == 1201) then
				playerChar:SetCharacterSlot(0, 1201);
			elseif(gsid == 1202) then
				playerChar:SetCharacterSlot(16, 1202);
			elseif(gsid == 1203) then
				playerChar:SetCharacterSlot(17, 1203);
			elseif(gsid == 1204) then
				playerChar:SetCharacterSlot(18, 1204);
			elseif(gsid == 1205) then
				playerChar:SetCharacterSlot(19, 1205);
			elseif(gsid == 1206) then
				playerChar:SetCharacterSlot(0, 1206);
			elseif(gsid == 1207) then
				playerChar:SetCharacterSlot(16, 1207);
			elseif(gsid == 1208) then
				playerChar:SetCharacterSlot(17, 1208);
			elseif(gsid == 1209) then
				playerChar:SetCharacterSlot(18, 1209);
			elseif(gsid == 1210) then
				playerChar:SetCharacterSlot(19, 1210);
			elseif(gsid == 1211) then
				playerChar:SetCharacterSlot(0, 1211);
			elseif(gsid == 1212) then
				playerChar:SetCharacterSlot(16, 1212);
			elseif(gsid == 1213) then
				playerChar:SetCharacterSlot(17, 1213);
			elseif(gsid == 1214) then
				playerChar:SetCharacterSlot(18, 1214);
			elseif(gsid == 1215) then
				playerChar:SetCharacterSlot(19, 1215);
			end
			
			if(gsid == 1216) then
				playerChar:SetCharacterSlot(0, 1216);
			elseif(gsid == 1217) then
				playerChar:SetCharacterSlot(16, 1217);
			elseif(gsid == 1218) then
				playerChar:SetCharacterSlot(17, 1218);
			elseif(gsid == 1219) then
				playerChar:SetCharacterSlot(19, 1219);
			elseif(gsid == 1220) then
				playerChar:SetCharacterSlot(0, 1220);
			elseif(gsid == 1221) then
				playerChar:SetCharacterSlot(16, 1221);
			elseif(gsid == 1222) then
				playerChar:SetCharacterSlot(17, 1222);
			elseif(gsid == 1223) then
				playerChar:SetCharacterSlot(19, 1223);
			elseif(gsid == 1224) then
				playerChar:SetCharacterSlot(0, 1224);
			elseif(gsid == 1225) then
				playerChar:SetCharacterSlot(16, 1225);
			elseif(gsid == 1226) then
				playerChar:SetCharacterSlot(0, 1226);
			elseif(gsid == 1227) then
				playerChar:SetCharacterSlot(16, 1227);
			elseif(gsid == 1228) then
				playerChar:SetCharacterSlot(17, 1228);
			elseif(gsid == 1229) then
				playerChar:SetCharacterSlot(19, 1229);
			elseif(gsid == 1230) then
				playerChar:SetCharacterSlot(18, 1230);
			end
			
			if(gsid >= 1231 and gsid <= 1240) then
				playerChar:SetCharacterSlot(0, gsid);
			end
			
			if(gsid >= 1241 and gsid <= 1250) then
				playerChar:SetCharacterSlot(16, gsid);
			end
			
			if(gsid >= 1251 and gsid <= 1260) then
				playerChar:SetCharacterSlot(19, gsid);
			end
			
			if(gsid >= 1266 and gsid <= 1276) then
				playerChar:SetCharacterSlot(18, gsid);
			end
			
			if(gsid == 1278 or gsid == 1281 or gsid == 1284 or gsid == 1287) then
				playerChar:SetCharacterSlot(0, gsid);
			end
			if(gsid == 1279 or gsid == 1282 or gsid == 1285 or gsid == 1288) then
				playerChar:SetCharacterSlot(16, gsid);
			end
			if(gsid == 1280 or gsid == 1283 or gsid == 1286 or gsid == 1289) then
				playerChar:SetCharacterSlot(19, gsid);
			end
			if(gsid == 12850 or gsid == 12851 or gsid == 12880) then
				playerChar:SetCharacterSlot(27, gsid);
			end
			if(gsid == 12881) then
				playerChar:SetCharacterSlot(27, 0);
			end
			
			if(gsid >= 12811 and gsid <= 12835) then
				playerChar:SetCharacterSlot(29, gsid);
			end
			
			if(gsid >= 12886 and gsid <= 12887) then
				playerChar:SetCharacterSlot(29, gsid);
			end
			
			if(gsid >= 11721 or gsid <= 11727) then
				playerChar:SetCharacterSlot(27, gsid);
			end
			
			if(gsid >= 11728 or gsid <= 11729) then
				playerChar:SetCharacterSlot(27, gsid);
			end

			
			if(gsid >= 1301 and gsid <= 1311) then
				playerChar:SetCharacterSlot(0, gsid);
			end
			if(gsid >= 1312 and gsid <= 1322) then
				playerChar:SetCharacterSlot(16, gsid);
			end
			if(gsid >= 1323 and gsid <= 1333) then
				playerChar:SetCharacterSlot(19, gsid);
			end
			
			if(gsid >= 1334 and gsid <= 1345) then
				playerChar:SetCharacterSlot(0, gsid);
			end
			if(gsid >= 1346 and gsid <= 1357) then
				playerChar:SetCharacterSlot(16, gsid);
			end
			if(gsid >= 1358 and gsid <= 1369) then
				playerChar:SetCharacterSlot(19, gsid);
			end
			
			if(gsid == 1178) then
				playerChar:SetCharacterSlot(16, gsid);
			end
			if(gsid >= 1370 and gsid <= 1384) then
				playerChar:SetCharacterSlot(0, gsid);
			end
			if(gsid >= 1385 and gsid <= 1399) then
				playerChar:SetCharacterSlot(16, gsid);
			end
			if(gsid >= 1400 and gsid <= 1414) then
				playerChar:SetCharacterSlot(19, gsid);
			end
			if(gsid >= 1415 and gsid <= 1424) then
				playerChar:SetCharacterSlot(21, gsid);
			end
			if(gsid >= 1425 and gsid <= 1429) then
				playerChar:SetCharacterSlot(26, gsid);
			end
			
			if(gsid >= 1450 and gsid <= 1452) then
				playerChar:SetCharacterSlot(0, gsid);
			end
			if(gsid >= 1453 and gsid <= 1455) then
				playerChar:SetCharacterSlot(16, gsid);
			end
			if(gsid >= 1456 and gsid <= 1458) then
				playerChar:SetCharacterSlot(19, gsid);
			end
			if(gsid >= 1459 and gsid <= 1461) then
				playerChar:SetCharacterSlot(21, gsid);
			end
			
			if(gsid >= 1470 and gsid <= 1470) then
				playerChar:SetCharacterSlot(0, gsid);
			end
			if(gsid >= 1471 and gsid <= 1471) then
				playerChar:SetCharacterSlot(16, gsid);
			end
			if(gsid >= 1472 and gsid <= 1472) then
				playerChar:SetCharacterSlot(19, gsid);
			end
			
			if(gsid == 1473 or gsid == 1476 or gsid == 1479 or gsid == 1483) then
				playerChar:SetCharacterSlot(0, gsid);
			end
			if(gsid == 1474 or gsid == 1477 or gsid == 1480 or gsid == 1484) then
				playerChar:SetCharacterSlot(16, gsid);
			end
			if(gsid == 1475 or gsid == 1478 or gsid == 1481 or gsid == 1485) then
				playerChar:SetCharacterSlot(19, gsid);
			end
			if(gsid >= 1486 and gsid <= 1486) then
				playerChar:SetCharacterSlot(21, gsid);
			end
			if(gsid >= 1482 and gsid <= 1482) then
				playerChar:SetCharacterSlot(26, gsid);
			end
			
			if(gsid >= 1487 and gsid <= 1491) then
				playerChar:SetCharacterSlot(0, gsid);
			end
			if(gsid >= 1492 and gsid <= 1496) then
				playerChar:SetCharacterSlot(16, gsid);
			end
			if(gsid >= 1497 and gsid <= 1501) then
				playerChar:SetCharacterSlot(19, gsid);
			end
			if(gsid >= 1502 and gsid <= 1506) then
				playerChar:SetCharacterSlot(21, gsid);
			end
			
			if(gsid >= 1522 and gsid <= 1538) then
				playerChar:SetCharacterSlot(0, gsid);
			end
			if(gsid >= 1539 and gsid <= 1555) then
				playerChar:SetCharacterSlot(16, gsid);
			end
			if(gsid >= 1556 and gsid <= 1572) then
				playerChar:SetCharacterSlot(19, gsid);
			end
			if(gsid >= 1573 and gsid <= 1589) then
				playerChar:SetCharacterSlot(21, gsid);
			end
			
			if(gsid >= 1612 and gsid <= 1620) then
				playerChar:SetCharacterSlot(0, gsid);
			end
			if(gsid >= 1621 and gsid <= 1628) then
				playerChar:SetCharacterSlot(16, gsid);
			end
			if(gsid >= 1629 and gsid <= 1634) then
				playerChar:SetCharacterSlot(19, gsid);
			end
			if(gsid >= 1635 and gsid <= 1639) then
				playerChar:SetCharacterSlot(21, gsid);
			end

			
			if(gsid >= 1651 and gsid <= 1652) then
				playerChar:SetCharacterSlot(0, gsid);
			end
			if(gsid >= 1653 and gsid <= 1654) then
				playerChar:SetCharacterSlot(16, gsid);
			end
			if(gsid == 1655 or gsid == 1658) then
				playerChar:SetCharacterSlot(19, gsid);
			end
			if(gsid >= 1656 and gsid <= 1657) then
				playerChar:SetCharacterSlot(26, gsid);
			end
			
			if(gsid >= 1659 and gsid <= 1663) then
				playerChar:SetCharacterSlot(0, gsid);
			end
			if(gsid >= 1664 and gsid <= 1668) then
				playerChar:SetCharacterSlot(16, gsid);
			end
			if(gsid >= 1669 and gsid <= 1673) then
				playerChar:SetCharacterSlot(19, gsid);
			end
			if(gsid >= 1674 and gsid <= 1678) then
				playerChar:SetCharacterSlot(26, gsid);
			end
			
			if(gsid == 1689 or gsid == 1692) then
				playerChar:SetCharacterSlot(0, gsid);
			end
			if(gsid == 1690 or gsid == 1693) then
				playerChar:SetCharacterSlot(16, gsid);
			end
			if(gsid == 1691 or gsid == 1694) then
				playerChar:SetCharacterSlot(19, gsid);
			end
			
			if(gsid == 1705 or gsid == 1706) then
				playerChar:SetCharacterSlot(0, gsid);
			end
			if(gsid == 1707 or gsid == 1708) then
				playerChar:SetCharacterSlot(16, gsid);
			end
			if(gsid == 1709 or gsid == 1710) then
				playerChar:SetCharacterSlot(19, gsid);
			end
			
			if(gsid >= 1711 and gsid <= 1713) then
				playerChar:SetCharacterSlot(26, gsid);
			end
			
			
			if(gsid >= 1714 and gsid <= 1720) then
				playerChar:SetCharacterSlot(0, gsid);
			end
			if(gsid >= 1721 and gsid <= 1727) then
				playerChar:SetCharacterSlot(16, gsid);
			end
			if(gsid >= 1728 and gsid <= 1734) then
				playerChar:SetCharacterSlot(19, gsid);
			end
			if(gsid >= 1735 and gsid <= 1739) then
				playerChar:SetCharacterSlot(26, gsid);
			end
			
			if(gsid >= 1771 and gsid <= 1772) then
				playerChar:SetCharacterSlot(0, gsid);
			end
			
			if(gsid == 1789 or gsid == 1792) then
				playerChar:SetCharacterSlot(0, gsid);
			end
			if(gsid == 1790 or gsid == 1793) then
				playerChar:SetCharacterSlot(16, gsid);
			end
			if(gsid == 1791 or gsid == 1794) then
				playerChar:SetCharacterSlot(19, gsid);
			end
			if(gsid >= 1795 and gsid <= 1796) then
				playerChar:SetCharacterSlot(26, gsid);
			end
			
			if(gsid >= 1812 and gsid <= 1812) then
				playerChar:SetCharacterSlot(26, gsid);
			end
			
			-- S2
			if(gsid == 1822 or gsid == 1833 or gsid == 1840 or gsid == 1848 or gsid == 1856) then
				playerChar:SetCharacterSlot(0, gsid);
			end
			if(gsid == 1819 or gsid == 1827 or gsid == 1837 or gsid == 1847 or gsid == 1855) then
				playerChar:SetCharacterSlot(16, gsid);
			end
			if(gsid == 1821 or gsid == 1834 or gsid == 1835 or gsid == 1843 or gsid == 1853) then
				playerChar:SetCharacterSlot(19, gsid);
			end
			if(gsid == 1820 or gsid == 1832 or gsid == 1839 or gsid == 1844 or gsid == 1851) then
				playerChar:SetCharacterSlot(26, gsid);
			end
			
			if(gsid == 1859) then
				playerChar:SetCharacterSlot(26, 1859);
			end

			-- 8/29 炫彩
			if(gsid == 2055 or gsid == 2058 or gsid == 2061 or gsid == 2064 or gsid == 2067 or gsid == 2070) then
				playerChar:SetCharacterSlot(0, gsid);
			end
			if(gsid == 2056 or gsid == 2059 or gsid == 2062 or gsid == 2065 or gsid == 2068 or gsid == 2071) then
				playerChar:SetCharacterSlot(16, gsid);
			end
			if(gsid == 2057 or gsid == 2060 or gsid == 2063 or gsid == 2066 or gsid == 2069 or gsid == 2072) then
				playerChar:SetCharacterSlot(19, gsid);
			end
			
			-- S3
			if(gsid == 2075 or gsid == 2082 or gsid == 2089 or gsid == 2096 or gsid == 2103) then
				playerChar:SetCharacterSlot(0, gsid);
			end
			if(gsid == 2077 or gsid == 2084 or gsid == 2091 or gsid == 2098 or gsid == 2105) then
				playerChar:SetCharacterSlot(16, gsid);
			end
			if(gsid == 2078 or gsid == 2085 or gsid == 2092 or gsid == 2099 or gsid == 2106) then
				playerChar:SetCharacterSlot(19, gsid);
			end
			if(gsid == 2076 or gsid == 2083 or gsid == 2090 or gsid == 2097 or gsid == 2104) then
				playerChar:SetCharacterSlot(26, gsid);
			end
			
			-- 万圣节
			if(gsid == 2112) then
				playerChar:SetCharacterSlot(0, gsid);
			end
			if(gsid == 2113) then
				playerChar:SetCharacterSlot(16, gsid);
			end
			if(gsid == 2114) then
				playerChar:SetCharacterSlot(21, gsid);
			end
			
			if(gsid == 2115 or gsid == 2116) then
				playerChar:SetCharacterSlot(0, gsid);
			end
        end
		local playerChar = curPlayer:ToCharacter();
		if(playerChar:GetCharacterSlotItemID(0) > 1) then -- IT_Head
			playerChar:SetBodyParams(-1, -1, 0, 0, -1); -- int hairColor, int hairStyle
		end
    end
end

function EditCCSTask.DS_Func_Hairs(index)
	if(index ~= nil) then
		local style = math.floor((index-1)/7) + 1;
		local color = math.mod(index-1, 7) + 1;
		if(index > 56) then
			return;
		end
		local filename = "character/v3/Elf/Hair0"..style.."_0"..color..".dds";
		if(ParaIO.DoesFileExist(filename)==true) then
			return {img = filename, style = style, color = color, tooltip = filename};
		else
			return {img = "Texture/Taurus/Question.png", style = style, color = color, tooltip = filename};
		end
	elseif(index == nil) then
		return 56;
	end
end

function EditCCSTask.TestHair(style, color)
	
	local player = curPlayer;
	local playerChar = player:ToCharacter();
	playerChar:SetBodyParams(-1, -1, -1, style, -1);
	
	playerChar:SetBodyParams(-1, -1, color-1, -1, -1);
end

function EditCCSTask.DS_Func_BaseSkins(index)
	if(index ~= nil) then
		if(index == 1) then
			return {img = "character/v3/Elf/Female/ElfFemaleSkin00_00.dds", color = index-1};
		elseif(index == 2) then
			return {img = "character/v3/Elf/Female/ElfFemaleSkin00_01.dds", color = index-1};
		elseif(index == 3) then
			return {img = "character/v3/Elf/Female/ElfFemaleSkin00_02.dds", color = index-1};
		elseif(index == 4) then
			return {img = "character/v3/Elf/Female/ElfFemaleSkin00_03.dds", color = index-1};
		elseif(index == 5) then
			return {img = "character/v3/Elf/Female/ElfFemaleSkin00_04.dds", color = index-1};
		elseif(index == 6) then
			return {img = "character/v3/Elf/Female/ElfFemaleSkin00_05.dds", color = index-1};
		elseif(index == 7) then
			return {img = "character/v3/Elf/Female/ElfFemaleSkin00_06.dds", color = index-1};
		elseif(index == 8) then
			return {img = "character/v3/Elf/Female/ElfFemaleSkin00_07.dds", color = index-1};
		elseif(index == 9) then
			return {img = "character/v3/Elf/Female/ElfFemaleSkin00_08.dds", color = index-1};
		elseif(index == 10) then
			return {img = "character/v3/Elf/Female/ElfFemaleSkin00_09.dds", color = index-1};
		elseif(index == 11) then
			return {img = "character/v3/Elf/Female/ElfFemaleSkin00_10.dds", color = index-1};
		end
	elseif(index == nil) then
		return 11;
	end
end

function EditCCSTask.TestSkin(color)
	local player = curPlayer;
	local playerChar = player:ToCharacter();
	playerChar:SetBodyParams(color, -1, -1, -1, -1);
	playerChar:SetCartoonFaceComponent(0, 0, color);
end

function EditCCSTask.TestEyeAddon(index)
	index = tonumber(index);
	local player = curPlayer;
	local playerChar = player:ToCharacter();
	if(index == 0) then
		playerChar:SetBodyParams(-1, -1, -1, -1, 1);
	elseif(index == 1) then
		playerChar:SetBodyParams(-1, index, -1, -1, 2);
	elseif(index == 2) then
		playerChar:SetBodyParams(-1, index, -1, -1, 2);
	end
end

function EditCCSTask.TestWings(index)
	index = tonumber(index);
	local player = curPlayer;
	local playerChar = player:ToCharacter();
	if(index == 0) then
		playerChar:SetCharacterSlot(21, 0)
	elseif(index == 1) then
		playerChar:SetCharacterSlot(21, 1065)
	elseif(index == 2) then
		playerChar:SetCharacterSlot(21, 341)
	end
end

function EditCCSTask.GetDS_Func_CartoonFace(index_Func)
	return function (index)
		if(index ~= nil) then
			if(index_Func == 1) then
				if(index > 40) then
					return;
				end
				local filename = "character/v3/CartoonFace/FaceDeco/marks_"..string.format("%02d", index-1)..".png";
				return {img = filename, tooltip = filename, type = index_Func, style = index,};
			elseif(index_Func == 6) then
				if(index > 11) then
					return;
				end
				local filename = "character/v3/CartoonFace/Mark/marks_"..string.format("%02d", index+9)..".png";
				return {img = filename, tooltip = filename, type = index_Func, style = index,};
			else
				if(index > 100) then
					return;
				end
				if(index_Func == 2) then
					local filename = "character/v3/CartoonFace/Eye/Eye_"..string.format("%02d", index-1)..".png";
					return {img = filename, tooltip = filename, type = index_Func, style = index,};
				elseif(index_Func == 3) then
					local filename = "character/v3/CartoonFace/Eyebrow/Eyebrow_"..string.format("%02d", index-1)..".png";
					return {img = filename, tooltip = filename, type = index_Func, style = index,};
				elseif(index_Func == 4) then
					local filename = "character/v3/CartoonFace/Mouth/mouth_"..string.format("%02d", index-1)..".png";
					return {img = filename, tooltip = filename, type = index_Func, style = index,};
				elseif(index_Func == 5) then
					local filename = "character/v3/CartoonFace/Nose/nose_"..string.format("%02d", index-1)..".png";
					return {img = filename, tooltip = filename, type = index_Func, style = index,};
				end
			end
		elseif(index == nil) then
			if(index_Func == 1) then
				return 40;
			elseif(index_Func == 6) then
				return 11;
			else
				return 100;
			end
		end
	end
end

function EditCCSTask.TestCartoonFace(type, style)

	local player = curPlayer;
	local playerChar = player:ToCharacter();
	-- set to cartoon face
	playerChar:SetBodyParams(-1, -1, -1, -1, 1);
	if(type == 6) then
		playerChar:SetCartoonFaceComponent(type, 0, style);
	else
		playerChar:SetCartoonFaceComponent(type, 0, style - 1);
	end
	
    local _this = ParaUI.GetUIObject("Custom_ComposedFace");
    if(_this:IsValid() == true) then
		_this.background = curPlayer:GetReplaceableTexture(7):GetFileName();
    end
end

local FaceTexSize = 256;

function EditCCSTask.Custom_ComposedFace(params)
	
	ParaUI.Destroy("Custom_ComposedFace");
	
    local _this = ParaUI.CreateUIObject("container", "Custom_ComposedFace", params.alignment, params.left, params.top, params.width, params.height);
	_this.background = curPlayer:GetReplaceableTexture(7):GetFileName();
	_this.enabled = false;
	params.parent:AddChild(_this);
	
	-- tricky show the eye component on compose face texture init
	EditCCSTask.ClickCartoonFaceComponent("Eye");
end

function EditCCSTask.ClickCartoonFaceComponent(value)
    local _composed = ParaUI.GetUIObject("Custom_ComposedFace");
    if(_composed:IsValid() == true) then
        _composed:RemoveAll();
        
        if(value == "Wrinkle" or value == "Mark") then
            local _guide = ParaUI.CreateUIObject("container", "Wrinkle", "_lt", 0, 0, FaceTexSize, FaceTexSize);
	        _guide.background = "texture/alphadot.png";
	        _composed:AddChild(_guide);
        elseif(value == "Eye") then
            local _guide = ParaUI.CreateUIObject("container", "Eye", "_lt", FaceTexSize*3/8-30, FaceTexSize*3/8, FaceTexSize/4, FaceTexSize/4);
	        _guide.background = "texture/alphadot.png";
	        _composed:AddChild(_guide);
    	    
            local _guide = ParaUI.CreateUIObject("container", "Eye", "_lt", FaceTexSize*3/8+30, FaceTexSize*3/8, FaceTexSize/4, FaceTexSize/4);
	        _guide.background = "texture/alphadot.png";
	        _composed:AddChild(_guide);
        elseif(value == "Eyebrow") then
            local _guide = ParaUI.CreateUIObject("container", "Eyebrow", "_lt", FaceTexSize*3/8-33, FaceTexSize*3/8-20, FaceTexSize/4, FaceTexSize/4);
	        _guide.background = "texture/alphadot.png";
	        _composed:AddChild(_guide);
    	    
            local _guide = ParaUI.CreateUIObject("container", "Eyebrow", "_lt", FaceTexSize*3/8+33, FaceTexSize*3/8-20, FaceTexSize/4, FaceTexSize/4);
	        _guide.background = "texture/alphadot.png";
	        _composed:AddChild(_guide);
        elseif(value == "Mouth") then
            local _guide = ParaUI.CreateUIObject("container", "Mouth", "_lt", FaceTexSize*3/8, FaceTexSize*3/8+41, FaceTexSize/4, FaceTexSize/4);
	        _guide.background = "texture/alphadot.png";
	        _composed:AddChild(_guide);
        elseif(value == "Nose") then
            local _guide = ParaUI.CreateUIObject("container", "Nose", "_lt", FaceTexSize*3/8, FaceTexSize*3/8+12, FaceTexSize/4, FaceTexSize/4);
	        _guide.background = "texture/alphadot.png";
	        _composed:AddChild(_guide);
        end
    end
end


function EditCCSTask.GetDS_Func_CharacterSlot(index_Func)
	return function (index)
		if(index ~= nil) then
			if(index_Func == 1) then
				-- head
				if(index > 40) then
					return;
				end
				return {img = "character/v3/CartoonFace/FaceDeco/marks_"..string.format("%02d", index-1)..".png", type = index_Func, style = index,};
			elseif(index_Func == 6) then
				if(index > 11) then
					return;
				end
				return {img = "character/v3/CartoonFace/Mark/marks_"..string.format("%02d", index+9)..".png", type = index_Func, style = index,};
			else
				if(index > 100) then
					return;
				end
				if(index_Func == 2) then
					return {img = "character/v3/CartoonFace/Eye/Eye_"..string.format("%02d", index-1)..".png", type = index_Func, style = index,};
				elseif(index_Func == 3) then
					return {img = "character/v3/CartoonFace/Eyebrow/Eyebrow_"..string.format("%02d", index-1)..".png", type = index_Func, style = index,};
				elseif(index_Func == 4) then
					return {img = "character/v3/CartoonFace/Mouth/mouth_"..string.format("%02d", index-1)..".png", type = index_Func, style = index,};
				elseif(index_Func == 5) then
					return {img = "character/v3/CartoonFace/Nose/nose_"..string.format("%02d", index-1)..".png", type = index_Func, style = index,};
				end
			end
		elseif(index == nil) then
			if(index_Func == 1) then
				return 40;
			elseif(index_Func == 6) then
				return 11;
			else
				return 100;
			end
		end
	end
end

function EditCCSTask.TestCharacterSlot(type, style)

	local player = curPlayer;
	local playerChar = player:ToCharacter();
	-- set to cartoon face
	playerChar:SetBodyParams(-1, -1, -1, -1, 1);
	playerChar:SetCartoonFaceComponent(type, 0, style);
	
    --local _this = ParaUI.GetUIObject("Custom_ComposedFace");
    --if(_this:IsValid() == true) then
		--_this.background = curPlayer:GetReplaceableTexture(7):GetFileName();
    --end
end

--local SkinTexSize = 256;
--
--function EditCCSTask.Custom_ComposedSkin(params)
--end



--function EditCCSTask.TestNameConvention()
	---- get the current character 
	---- check the naming and convension in the character directory
	--local player = curPlayer;
	--local playerAsset = player:GetPrimaryAsset():GetKeyName();
	--if(playerAsset ~= nil) then
		--local ext = string.lower(ParaIO.GetFileExtension(playerAsset));
		--local fileName;
		--local directory;
		--if(ext ~= "x") then
			---- this is a Para-X file
			--fileName = ParaIO.GetFileName(playerAsset);
			--directory = string.gsub(playerAsset, fileName, "");
		--elseif(ext ~= "xml") then
			---- this is an xml desc character file with LoD
			--fileName = ParaIO.GetFileName(playerAsset);
			--directory = string.gsub(playerAsset, fileName, "");
		--else
			---- not an engine acceptable file extension
		--end
			--
		--local nMaxNumFiles = 5000;
		---- check the base skins
		--local search_result = ParaIO.SearchFiles(directory, "*.dds", "", 0, nMaxNumFiles, 0);
		--local nCount = search_result:GetNumOfResult();
		--local i = 0;
		--for i = 0, nCount - 1 do
			--local skins = search_result:GetItem(i);
			--
			--local nGeoSetPos = string.find(sTexFileName_TU, "Hairs_");
			--
			--search_result
		--end
		--if(search_result) then
		--end
		--
		--searchfiles
		--directory
		--
		---- check the hair styles
		--
		---- check the wings styles
		--
		---- check the wings styles
			--
	--end
--end





-- take screen shot of the character pe:avatar. 
function EditCCSTask.TakeAvatarSnapshot()
	-- taking the snapshot calling the AvatarRegPage.lua function
	NPL.load("(gl)script/kids/3DMapSystemUI/CCS/AvatarRegPage.lua");
	Map3DSystem.App.CCS.AvatarRegPage.TakeAvatarSnapshot();
end

-- load the current player to canvas
function EditCCSTask.OnRefreshAvatar()
	local self = document:GetPageCtrl();
	if(not self) then 
		log("warning: page control not found\n")
		return 
	end
	
	local ctl = self:FindControl("avatar");
	if(ctl and curPlayer:IsValid()) then
		ctl:ShowModel({
			["IsCharacter"] = true,
			["y"] = 0,
			["x"] = 0,
			["facing"] = -1.57,
			["name"] = "avatar",
			["z"] = 0,
			["AssetFile"] = curPlayer:GetPrimaryAsset():GetKeyName(),
			["CCSInfoStr"] = Map3DSystem.UI.CCS.GetCCSInfoString(curPlayer),
		});
	end
end

-- save the user avatar information
function EditCCSTask.OnClickSave()

	local self = document:GetPageCtrl();
	if(not self) then 
		log("warning: page control not found")
		return 
	end
	
	if(name ~= Map3DSystem.User.Name) then
		-- LXZ: is it really needed? 2008.6.21
		-- paraworld.ShowMessage("请先切换到你的主角\n");
		-- return 
	end
	
	local player = curPlayer;
	local name = curPlayer.name;
	
	local PlayerAsset = player:GetPrimaryAsset():GetKeyName();
	local ccsinfo = Map3DSystem.UI.CCS.GetCCSInfoString(player);
	
	local profile = Map3DSystem.App.CCS.app:GetMCMLInMemory() or {};
	if(type(profile) ~= "table") then
		profile = {};
	end
	profile.CharParams = profile.CharParams or {};
	
	-- modified lxz 2008.6.21
	local CharParams = {
		AssetFile = PlayerAsset,
		CCSInfoStr = ccsinfo,
	}
	if(not commonlib.partialcompare(profile.CharParams, CharParams)) then
		self:SetUIValue("result", "正在更新, 请稍候...");
		commonlib.partialcopy(profile.CharParams, CharParams);
		
		Map3DSystem.App.CCS.app:SetMCML(nil, profile, function (uid, appkey, bSucceed)
			if(bSucceed) then
				self:SetUIValue("result", "更新成功！ 谢谢！")
			else
				self:SetUIValue("result", "暂时无法更新，请稍候再试")
			end	
		end)
	else
		self:SetUIValue("result", "您并没有做任何修改")
	end	
end



















-- 26 for IT_MASK, CS_FACE_ADDON


function EditCCSTask.Custom_OriginalCCSMain(params)
    
    ParaUI.Destroy("Custom_OriginalCCSMain");
    
    local _this = ParaUI.CreateUIObject("container", "Custom_OriginalCCSMain", params.alignment, params.left, params.top, params.width, params.height);
	_this.background = "";
	params.parent:AddChild(_this);
	
	local _parent = _this;
	
	NPL.load("(gl)script/kids/3DMapSystemUI/InGame/TabGrid.lua");
	
	NPL.load("(gl)script/kids/3DMapSystemUI/CCS/DB.lua");
	
	local _tab_INV = ParaUI.CreateUIObject("container", "Tab_INV", "_mr", 0, 0, 60, 0);
	_tab_INV.background = "";
	_parent:AddChild(_tab_INV);
	
	local _inventorySelector = ParaUI.CreateUIObject("container", "Selector", "_fi", 0, 0, 60, 0);
	_inventorySelector.background = "";
	_parent:AddChild(_inventorySelector);
	
	
	NPL.load("(gl)script/ide/TreeView.lua");
	local tabPagesNode_INV = CommonCtrl.TreeNode:new({Name = "CCS_TabControlRootNode_INV"});
	tabPagesNode_INV:AddChild(CommonCtrl.TreeNode:new({tooltip = "Hat", icon = "Texture/3DMapSystem/CCS/RightPanel/IT_Head.png"}));
	tabPagesNode_INV:AddChild(CommonCtrl.TreeNode:new({tooltip = "Shoulder", icon = "Texture/3DMapSystem/CCS/RightPanel/IT_Shoulder.png"}));
	tabPagesNode_INV:AddChild(CommonCtrl.TreeNode:new({tooltip = "Shirt", icon = "Texture/3DMapSystem/CCS/RightPanel/IT_Chest.png"}));
	tabPagesNode_INV:AddChild(CommonCtrl.TreeNode:new({tooltip = "Gloves", icon = "Texture/3DMapSystem/CCS/RightPanel/IT_Gloves.png"}));
	tabPagesNode_INV:AddChild(CommonCtrl.TreeNode:new({tooltip = "Pants", icon = "Texture/3DMapSystem/CCS/RightPanel/IT_Pants.png"}));
	tabPagesNode_INV:AddChild(CommonCtrl.TreeNode:new({tooltip = "Boots", icon = "Texture/3DMapSystem/CCS/RightPanel/IT_Boots.png"}));
	tabPagesNode_INV:AddChild(CommonCtrl.TreeNode:new({tooltip = "LeftHand", icon = "Texture/3DMapSystem/CCS/RightPanel/IT_HandLeft.png"}));
	tabPagesNode_INV:AddChild(CommonCtrl.TreeNode:new({tooltip = "RightHand", icon = "Texture/3DMapSystem/CCS/RightPanel/IT_HandRight.png"}));
	tabPagesNode_INV:AddChild(CommonCtrl.TreeNode:new({tooltip = "Tabard", icon = "Texture/3DMapSystem/CCS/RightPanel/IT_Cape.png"}));
	
	NPL.load("(gl)script/ide/TabControl.lua");
    
    CommonCtrl.DeleteControl("CCS_TabControl_Inventory");
    
	local ctl = CommonCtrl.TabControl:new{
			name = "CCS_TabControl_Inventory",
			parent = _tab_INV,
			background = nil,
			alignment = "_fi",
			wnd = nil,
			left = 0,
			top = 0,
			width = 0,
			height = 0,
			zorder = 0,
			
			TabAlignment = "Right", -- Left|Right|Top|Bottom, Top if nil
			TabPages = tabPagesNode_INV, -- CommonCtrl.TreeNode object, collection of tab pages
			TabHeadOwnerDraw = function(_parent, tabControl) 
					local _head = ParaUI.CreateUIObject("container", "Item", "_fi", 0, 0, 0, 0);
					_head.background = "Texture/3DMapSystem/Creator/tabcontrol_bg_32bits.png;32 0 32 14:20 13 11 0";
					_head.enabled = false;
					_parent:AddChild(_head);
					local _head = ParaUI.CreateUIObject("button", "Item", "_lb", 20, -40, 32, 32);
					_head.background = "Texture/3DMapSystem/Creator/PageUp.png";
					_head.onclick = ";CommonCtrl.TabControl.PageBackward(\""..tabControl.name.."\");";
					_parent:AddChild(_head);
				end, --function(_parent, tabControl) end, -- area between top/left border and the first item
			TabTailOwnerDraw = function(_parent, tabControl) 
					local _tail = ParaUI.CreateUIObject("container", "Item", "_fi", 0, 0, 0, 0);
					_tail.background = "Texture/3DMapSystem/Creator/tabcontrol_bg_32bits.png;32 52 32 12:20 0 11 11";
					_tail.enabled = false;
					_parent:AddChild(_tail);
					local _tail = ParaUI.CreateUIObject("button", "Item", "_lt", 20, 8, 32, 32);
					_tail.background = "Texture/3DMapSystem/Creator/PageDown.png";
					_tail.onclick = ";CommonCtrl.TabControl.PageForward(\""..tabControl.name.."\");";
					_parent:AddChild(_tail);
				end, --function(_parent, tabControl) end, -- area between the last item and buttom/right border
			TabStartOffset = 40, -- start of the tabs from the border
			TabItemOwnerDraw = function(_parent, index, bSelected, tabControl) 
					if(bSelected == true) then
						local _item = ParaUI.CreateUIObject("container", "Item", "_fi", 0, 0, 0, 0);
						_item.background = "Texture/3DMapSystem/Creator/tabcontrol_bg_32bits.png;32 14 32 37:17 16 14 16";
						_item.enabled = false;
						_parent:AddChild(_item);
					else
						local _item = ParaUI.CreateUIObject("container", "Item", "_fi", 0, 0, 0, 0);
						_item.background = "Texture/3DMapSystem/Creator/tabcontrol_bg_32bits.png;32 11 32 3:20 1 11 1";
						_item.enabled = false;
						_parent:AddChild(_item);
					end
					local node = tabControl.TabPages:GetChild(index);
					local _item = ParaUI.CreateUIObject("button", "Item", "_lt", 22, 8, 32, 32);
					_item.background = node.icon;
					_item.onclick = string.format(";CommonCtrl.TabControl.OnClickTab(%q, %s);", tabControl.name, index);
					_parent:AddChild(_item);
				end, --function(_parent, index, bSelected, tabControl) end, -- owner draw item
			TabItemWidth = 60, -- width of each tab item
			TabItemHeight = 48, -- height of each tab item
			MaxTabNum = 8, -- maximum number of the tabcontrol, pager required when tab number exceeds the maximum
			OnSelectedIndexChanged = function(fromIndex, toIndex)
				local ctl = CommonCtrl.GetControl("InventoryTabGrid");
				if(ctl ~= nil) then
					ctl:SetLevelIndex(toIndex);
				end
			end,
		};
	ctl:Show(true);
	
	-- default to shirt
	ctl:SetSelectedIndex(3);
	
	-- unmount the item according to current character slot on the current character
	function OnClickUnmountCurrentCharacterSlot()
		
		local ctl = CommonCtrl.GetControl("InventoryTabGrid");
		if(ctl ~= nil) then
			local level1index, _ = ctl:GetLevelIndex();
			local component;
			if(level1index == 1) then
				component = Map3DSystem.UI.CCS.DB.CS_HEAD;
			elseif(level1index == 2) then
				component = Map3DSystem.UI.CCS.DB.CS_SHOULDER;
			elseif(level1index == 3) then
				component = Map3DSystem.UI.CCS.DB.CS_SHIRT;
			elseif(level1index == 4) then
				component = Map3DSystem.UI.CCS.DB.CS_GLOVES;
			elseif(level1index == 5) then
				component = Map3DSystem.UI.CCS.DB.CS_PANTS;
			elseif(level1index == 6) then
				component = Map3DSystem.UI.CCS.DB.CS_BOOTS;
			elseif(level1index == 7) then
				component = Map3DSystem.UI.CCS.DB.CS_HAND_LEFT;
			elseif(level1index == 8) then
				component = Map3DSystem.UI.CCS.DB.CS_HAND_RIGHT;
			elseif(level1index == 9) then
				component = Map3DSystem.UI.CCS.DB.CS_CAPE;
			end
			
			
			Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_SelectObject, obj = curPlayer});
			
			-- temporarily directly mount the item on the selected character
			local player, playerChar = Map3DSystem.UI.CCS.DB.GetPlayerChar();
			if(playerChar~=nil) then
				playerChar:SetCharacterSlot(component, 0);
			end
			
			-- TODO: general implementation
			-- mount the default shirt or pant for human female and male
			local player = curPlayer;
			local assetName = player:GetPrimaryAsset():GetKeyName();
			
			if(string.find(assetName, "HumanFemale.x") ~= nil) then
				if(component == Map3DSystem.UI.CCS.DB.CS_SHIRT) then
					playerChar:SetCharacterSlot(component, 10);
				elseif(component == Map3DSystem.UI.CCS.DB.CS_PANTS) then
					playerChar:SetCharacterSlot(component, 12);
				end
			end
			
			if(string.find(assetName, "HumanMale.x") ~= nil) then
				if(component == Map3DSystem.UI.CCS.DB.CS_SHIRT) then
					playerChar:SetCharacterSlot(component, 11);
				elseif(component == Map3DSystem.UI.CCS.DB.CS_PANTS) then
					playerChar:SetCharacterSlot(component, 13);
				end
			end
			
			Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_DeselectObject, obj = nil});
		end
	end
	
	CommonCtrl.DeleteControl("InventoryTabGrid");
	local ctl = CommonCtrl.GetControl("InventoryTabGrid");
	if(ctl == nil) then
		local param = {
			name = "InventoryTabGrid",
			parent = _inventorySelector,
			background = "Texture/3DMapSystem/Creator/tabcontrol_bg_32bits.png;0 0 32 64:16 16 1 16",
			wnd = wnd,
			
			----------- CATEGORY REGION -----------
			Level1 = "Right",
			Level1BG = "",
			Level1HeadBG = "Texture/3DMapSystem/Desktop/RightPanel/BarBGTop.png; 0 0 50 24",
			Level1TailBG = "Texture/3DMapSystem/Desktop/RightPanel/BarBGBottom.png; 0 0 50 64: 1 0 1 63",
			Level1Offset = 24,
			Level1ItemWidth = 0,
			Level1ItemHeight = 50,
			--Level1ItemGap = 8,
			
			Level1ItemOwnerDraw = function (_parent, level1index, bSelected, tabGrid)
				-- background
				if(bSelected) then
					local _back = ParaUI.CreateUIObject("container", "back", "_fi", 0, 0, 0, 0);
					_back.background = tabGrid.GetLevel1ItemSelectedBackImage(level1index);
					_parent:AddChild(_back);
				else
					local _back = ParaUI.CreateUIObject("container", "back", "_fi", 0, 0, 0, 0);
					_back.background = tabGrid.GetLevel1ItemUnselectedBackImage(level1index);
					_parent:AddChild(_back);
				end
				
				-- icon
				local _btn = ParaUI.CreateUIObject("button", "btn"..level1index, "_lt", 11, 9, 32, 32);
				if(bSelected) then
					_btn.background = tabGrid.GetLevel1ItemSelectedForeImage(level1index);
				else
					_btn.background = tabGrid.GetLevel1ItemUnselectedForeImage(level1index);
				end
				_btn.onclick = string.format([[;Map3DSystem.UI.TabGrid.OnClickCategory("%s", %d, nil);]], 
						tabGrid.name, level1index);
				_parent:AddChild(_btn);
			end,
			
			--Level2 = "Top",
			--Level2Offset = 48,
			--Level2ItemWidth = 32,
			--Level2ItemHeight = 48,
			--Level2ItemGap = 0,
			
			----------- GRID REGION -----------
			nGridBorderLeft = 0,
			nGridBorderTop = 8,
			nGridBorderRight = 0,
			nGridBorderBottom = 0,
			
			nGridCellWidth = 48,
			nGridCellHeight = 48,
			nGridCellGap = 8, -- gridview gap between cells
			
			----------- PAGE REGION -----------
			pageRegionHeight = 48,
			pageNumberWidth = 40,
			pageDefaultMargin = 16,
			pageNumberColor = "0 0 0",
			
			pageLeftImage = "Texture/3DMapSystem/Desktop/RightPanel/PreviousPage32.png",
			pageLeftWidth = 24,
			pageLeftHeight = 24,
			
			pageRightImage = "Texture/3DMapSystem/Desktop/RightPanel/NextPage32.png",
			pageRightWidth = 24,
			pageRightHeight = 24,
			
			isAlwaysShowPager = true,
			
			isGridView3D = true, -- show 3D grid
			
			----------- FUNCTION REGION -----------
			GetLevel1ItemCount = function() return 9; end,
			GetLevel1ItemSelectedForeImage = function(index)
					if(index == 1) then return "Texture/3DMapSystem/CCS/RightPanel/IT_Head.png";
					elseif(index == 2) then return "Texture/3DMapSystem/CCS/RightPanel/IT_Shoulder.png";
					elseif(index == 3) then return "Texture/3DMapSystem/CCS/RightPanel/IT_Chest.png";
					elseif(index == 4) then return "Texture/3DMapSystem/CCS/RightPanel/IT_Gloves.png";
					elseif(index == 5) then return "Texture/3DMapSystem/CCS/RightPanel/IT_Pants.png";
					elseif(index == 6) then return "Texture/3DMapSystem/CCS/RightPanel/IT_Boots.png";
					elseif(index == 7) then return "Texture/3DMapSystem/CCS/RightPanel/IT_HandLeft.png";
					elseif(index == 8) then return "Texture/3DMapSystem/CCS/RightPanel/IT_HandRight.png";
					elseif(index == 9) then return "Texture/3DMapSystem/CCS/RightPanel/IT_Cape.png";
					end
				end,
			GetLevel1ItemSelectedBackImage = function(index)
					return "Texture/3DMapSystem/Desktop/RightPanel/TabSelected.png; 0 0 50 64: 24 16 12 12";
				end,
			GetLevel1ItemUnselectedForeImage = function(index)
					if(index == 1) then return "Texture/3DMapSystem/CCS/RightPanel/IT_Head.png";
					elseif(index == 2) then return "Texture/3DMapSystem/CCS/RightPanel/IT_Shoulder.png";
					elseif(index == 3) then return "Texture/3DMapSystem/CCS/RightPanel/IT_Chest.png";
					elseif(index == 4) then return "Texture/3DMapSystem/CCS/RightPanel/IT_Gloves.png";
					elseif(index == 5) then return "Texture/3DMapSystem/CCS/RightPanel/IT_Pants.png";
					elseif(index == 6) then return "Texture/3DMapSystem/CCS/RightPanel/IT_Boots.png";
					elseif(index == 7) then return "Texture/3DMapSystem/CCS/RightPanel/IT_HandLeft.png";
					elseif(index == 8) then return "Texture/3DMapSystem/CCS/RightPanel/IT_HandRight.png";
					elseif(index == 9) then return "Texture/3DMapSystem/CCS/RightPanel/IT_Cape.png";
					end
				end,
			GetLevel1ItemUnselectedBackImage = function(index)
					return "Texture/3DMapSystem/Desktop/RightPanel/TabUnSelected.png; 0 0 50 64";
				end,
			
			
			GetGridItemEnabled = function()
					return true;
				end,
			
			GetGridItemCount = function(level1index, level2index)
					return table.getn(Map3DSystem.UI.CCS.DB.AuraInventoryID[level1index]);
				end,
			GetGrid3DItemModel = function(level1index, level2index, itemindex)
					return Map3DSystem.UI.CCS.DB.AuraInventoryPreview[level1index][itemindex].model;
				end,
			GetGrid3DItemSkin = function(level1index, level2index, itemindex)
					return Map3DSystem.UI.CCS.DB.AuraInventoryPreview[level1index][itemindex].skin;
				end,
			
			OnClickItem = function(level1index, level2index, itemindex)
					
					if(mouse_button == "right") then
						local param = {
							AssetFile = Map3DSystem.UI.CCS.DB.AuraInventoryPreview[level1index][itemindex].model, 
							x = 0, y = 0, z = 0, 
							ReplaceableTextures = {
								[2] = Map3DSystem.UI.CCS.DB.AuraInventoryPreview[level1index][itemindex].skin[1],
								[3] = Map3DSystem.UI.CCS.DB.AuraInventoryPreview[level1index][itemindex].skin[2],
								[4] = Map3DSystem.UI.CCS.DB.AuraInventoryPreview[level1index][itemindex].skin[3],
								[5] = Map3DSystem.UI.CCS.DB.AuraInventoryPreview[level1index][itemindex].skin[4],},
						};
						Map3DSystem.UI.Creator.ShowPreview(param);
					elseif(mouse_button == "left") then
						local component;
						if(level1index == 1) then
							component = Map3DSystem.UI.CCS.DB.CS_HEAD;
						elseif(level1index == 2) then
							component = Map3DSystem.UI.CCS.DB.CS_SHOULDER;
						elseif(level1index == 3) then
							component = Map3DSystem.UI.CCS.DB.CS_SHIRT;
						elseif(level1index == 4) then
							component = Map3DSystem.UI.CCS.DB.CS_GLOVES;
						elseif(level1index == 5) then
							component = Map3DSystem.UI.CCS.DB.CS_PANTS;
						elseif(level1index == 6) then
							component = Map3DSystem.UI.CCS.DB.CS_BOOTS;
						elseif(level1index == 7) then
							component = Map3DSystem.UI.CCS.DB.CS_HAND_LEFT;
						elseif(level1index == 8) then
							component = Map3DSystem.UI.CCS.DB.CS_HAND_RIGHT;
						elseif(level1index == 9) then
							component = Map3DSystem.UI.CCS.DB.CS_CAPE;
						end
						
						Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_SelectObject, obj = curPlayer});
						
						-- temporarily directly mount the item on the selected character
						local player, playerChar = Map3DSystem.UI.CCS.DB.GetPlayerChar();
						if(playerChar~=nil) then
							--playerChar:SetCharacterSlot(component, Map3DSystem.UI.CCS.DB.AuraInventoryID[level1index][itemindex]);
							Map3DSystem.UI.CCS.Inventory.SetCharacterSlot(player, component, Map3DSystem.UI.CCS.DB.AuraInventoryID[level1index][itemindex]);
						end
						
						Map3DSystem.SendMessage_obj({type = Map3DSystem.msg.OBJ_DeselectObject, obj = nil});
						
					end
				end,
		};
		ctl = Map3DSystem.UI.TabGrid:new(param);
	end
	
	ctl:Show(true);
	
	-- default to shirt 
	ctl:SetLevelIndex(3);
	
	local _tools = ParaUI.CreateUIObject("container", "Tools", "_lb", 4, -44, 245, 40);
	_tools.background = "Texture/3DMapSystem/Creator/container_32bits.png:7 7 7 7";
	_parent:AddChild(_tools);
	
	-- remove item button
	local _remove = ParaUI.CreateUIObject("button", "Remove", "_lt", 4, 4, 32, 32);
	_remove.background = "Texture/3DMapSystem/common/reset.png";
	_remove.onclick = ";OnClickUnmountCurrentCharacterSlot();";
	_remove.tooltip = "卸下当前装备";
	_tools:AddChild(_remove);
end