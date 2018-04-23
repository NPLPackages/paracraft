 --[[
Title: Character Animation Manager for 3D Map system
Author(s): WangTian
Date: 2007/11/8, added facing 2008.7.16. and uses mapping by lxz
Desc: UI Animation functions
to play animation, call below
<verbatim>
	Map3DSystem.Animation.SendMeMessage({
		type = Map3DSystem.msg.ANIMATION_Character,
		animationName = "CCSBoot",
		obj_params = nil,
		facingTarget = {x=,y=0,z=0}, -- optional
		filename = string, animation file name
	});
	-- short version
	Map3DSystem.Animation.SendMeMessage({type = Map3DSystem.msg.ANIMATION_Character,animationName = "Summon"});
</verbatim>
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemAnimation/AnimationManager.lua");
------------------------------------------------------------

]]

NPL.load("(gl)script/kids/3DMapSystem_Data.lua");

function Map3DSystem.Animation.InitAnimationManager()
	
	Map3DSystem.Animation.InitMessageSystem();
end

-- init message system: call this function at animation manager initialization
function Map3DSystem.Animation.InitMessageSystem()
	NPL.load("(gl)script/ide/os.lua");
	local _app = CommonCtrl.os.CreateGetApp("AnimationManager");
	Map3DSystem.Animation.App = _app;
	Map3DSystem.Animation.MainWnd = _app:RegisterWindow("AnimationManagerWnd", nil, Map3DSystem.Animation.MSGProc);
end

-- send a message to AnimationManager:AnimationManagerWnd window handler
-- e.g. Map3DSystem.Animation.SendMeMessage({type = Map3DSystem.msg.ANIMATION_Character})
function Map3DSystem.Animation.SendMeMessage(msg)
	msg.wndName = Map3DSystem.Animation.MainWnd.name;
	Map3DSystem.Animation.App:SendMessage(msg);
end

NPL.load("(gl)script/ide/Encoding.lua");
local F = commonlib.Encoding.Utf8ToDefault;
-- TODO: rename to English names, AB has already done it. change here. LXZ 2010.1.27
local anim_map = {
	["CreateCharacter"] = "character/Animation/v3/CreatingCharacters.x",
	["CCSEnd"]=F"character/Animation/v3/换装结束.x",
	["CCSUpper"]=F"character/Animation/v3/换装上身.x",
	["CCSHead"]=F"character/Animation/v3/换装头部.x",
	["LowerTerrain"]="character/Animation/v3/Lower.x",
	["RaiseTerrain"]="character/Animation/v3/Uplift.x",
	["ModifyNature"]="character/Animation/v3/ModifyTheNatural.x",
	["ModifyTerrainTexture"]="character/Animation/v3/ModifyTheSurfaceTexture.x",
	["ModifyObject"]="character/Animation/v3/ModifyObjects.x",
	["SelectObject"]="character/Animation/v3/SelectObjects.x",
	["CharacterBorn"]="character/Animation/v3/PeopleBorn.x",
	["Throw"]="character/Animation/v5/Throw.x",
	["Break"]="character/Animation/v5/ElfFemale_Break.x",

	["CCSBoot"]=F"character/Animation/v3/换装鞋子.x",
	["CCSPant"]=F"character/Animation/v3/换装裤子.x",
	["CCSShoulder"]=F"character/Animation/v3/换装肩膀.x",
	["CCSGlove"]=F"character/Animation/v3/换装手部.x",
	["LeftChangeSword"]=F"character/Animation/v3/左手换剑.x",
	["RightChangeSword"]=F"character/Animation/v3/右手换剑.x",

	["Sword"]=F"character/Animation/v3/出剑.x",
	["Fist"]=F"character/Animation/v3/出拳.x",
	["LayDown"]=F"character/Animation/v3/倒地.x",
	["Jitter"]=F"character/Animation/v3/抖动.x",
	["SitOnFloor"]=F"character/Animation/v3/蹲下.x",
	["Club"]=F"character/Animation/v3/挥棒.x",
	["Blade"]=F"character/Animation/v3/劈刀.x",
	["Celebrate"]=F"character/Animation/v3/庆祝.x",
	["Seed"]=F"character/Animation/v3/扔种子.x",
	["Dodge"]=F"character/Animation/v3/闪避.x",
	["Shoot"]=F"character/Animation/v3/射击.x",
	["Victory"]=F"character/Animation/v3/胜利.x",
	["Magic"]=F"character/Animation/v3/施展魔法.x",
	["Bow"]=F"character/Animation/v3/弯腰痛苦.x",
	
	["Summon"]=F"character/Animation/v3/欢呼.x",
	["Goodbye"]=F"character/Animation/v3/再见.x",
	["Chat"]=F"character/Animation/v3/讨论.x",
	["Nervous"]=F"character/Animation/v3/紧张.x",
	["Plaud"]=F"character/Animation/v3/鼓掌.x",
	["Chat"]=F"character/Animation/v3/讨论.x",
	["Welcome"]=F"character/Animation/v3/欢迎.x",
	["Cheer"]=F"character/Animation/v3/欢呼.x",
	["Angry"]=F"character/Animation/v3/愤怒.x",
	["Cry"]=F"character/Animation/v3/哭泣.x",
	["Depressed"]=F"character/Animation/v3/垂头丧气.x",
	["Nod"]=F"character/Animation/v3/点头.x",
	["Disappointed"]=F"character/Animation/v3/失望.x",
}

-- AnimationManager: AnimationManager window handler
function Map3DSystem.Animation.MSGProc(window, msg)
	if(msg.type == Map3DSystem.msg.ANIMATION_Character) then
		-- play animation according to the params
		local player;
		if(msg.obj_params == nil) then
			player = ParaScene.GetPlayer();
		else
			local obj = ObjEditor.GetObjectByParams(msg.obj_params);
			
			if(obj == nil or obj:IsCharacter() == false) then
				log("warning: invalid last create object when trying to play animation\n");
				return;
			end
			if(obj:ToCharacter():IsCustomModel() == true) then
				player = obj;
			else
				player = obj;
				return;
			end
		end
		
		-- Added by LiXizhi 2008.6.22. Facing the target. 
		if(msg.facingTarget and msg.facingTarget.x) then
			if(Map3DSystem.App.CCS and Map3DSystem.App.CCS.CharacterFaceTarget) then
				Map3DSystem.App.CCS.CharacterFaceTarget(player, msg.facingTarget.x,msg.facingTarget.y,msg.facingTarget.z);
			end
		end
		if(player:ToCharacter():IsCustomModel() == true) then
			local filename = msg.filename or anim_map[msg.animationName]
			if(filename) then
				Map3DSystem.Animation.PlayAnimationFile(filename, player);
			end
		end
	end
end

-- play a given animation file on character (player). It will only load the animation file once on first call
-- e.g. 
--		Map3DSystem.Animation.PlayAnimationFile("character/Animation/v5/Solute.x")
--		Map3DSystem.Animation.PlayAnimationFile({"character/Animation/v5/Solute.x", "character/Animation/v5/LoopedDance.x"})
--		Map3DSystem.Animation.PlayAnimationFile({10000, 10001})
-- @param filename: animation file name.  
-- it can also be a table like {"character/Animation/v5/Solute.x", "character/Animation/v5/LoopedDance.x"}. currently only two are supported. The first one is usually a non-loop, and second one can be loop or non-loop. 
function Map3DSystem.Animation.PlayAnimationFile(filenames, player)
	local anims;
	if(type(filenames) == "string") then
		local nAnimID = ParaAsset.CreateBoneAnimProvider(-1, filenames, filenames, false);
		if(nAnimID>0) then
			anims = nAnimID;
		end
	elseif(type(filenames) == "table") then	
		local _, filename
		for _, filename in ipairs(filenames) do
			if(type(filename) == "string") then
				anims = anims or {};
				anims[#anims + 1] = ParaAsset.CreateBoneAnimProvider(-1, filename, filename, false);
			elseif(type(filename) == "number") then	
				anims = anims or {};
				anims[#anims + 1] = filename;
			end	
		end
	end	
	if(anims) then
		if(not player) then
			player = ParaScene.GetPlayer();
		end
		player:GetAttributeObject():SetField("HeadTurningAngle", 0);
		player:ToCharacter():PlayAnimation(anims);
	end
end