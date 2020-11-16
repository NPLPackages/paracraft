--[[
Title: 
Author(s): chenjinxian
Date: 2020/10/28
Desc: 
use the lib:
------------------------------------------------------------
local ParaWorldNPC = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldNPC.lua");
ParaWorldNPC.ShowPage();
-------------------------------------------------------
]]
local TeachingQuestLinkPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/TeachingQuestLinkPage.lua");
local TeachingQuestPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/TeachingQuest/TeachingQuestPage.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityNPC.lua");
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.world.lua");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local EntityNPC = commonlib.gettable("MyCompany.Aries.Game.EntityManager.EntityNPC");
local ParaWorldNPC = NPL.export();

ParaWorldNPC.npcList = {};

local entityList = {};
local page;
function ParaWorldNPC.OnInit()
	page = document:GetPageCtrl();
end

function ParaWorldNPC.CreateDefaultNPC(x, y, z)
	for i = #ParaWorldNPC.npcList, 1, -1 do
		ParaWorldNPC.npcList[i] = nil;
	end
	ParaWorldNPC.npcList[1] = {npcName = "班主任", npcType = "head_teacher", npcModel = "character/CC/02human/paperman/girl04.x", x = x, y = y, z = z+10, show = true};
	ParaWorldNPC.npcList[2] = {npcName = "编程导师", npcType = "program", npcModel = "character/CC/02human/paperman/girl05.x", x = x+5, y = y, z = z+5, show = true};
	ParaWorldNPC.npcList[3] = {npcName = "动画导师", npcType = "animation", npcModel = "character/CC/02human/paperman/Male_teacher.x", x = x-5, y = y, z = z+5, show = true};
	ParaWorldNPC.npcList[4] = {npcName = "CAD", npcType = "CAD", npcModel = "character/CC/02human/paperman/Female_teachers.x", x = x+5, y = y, z = z-5, show = true};
	ParaWorldNPC.npcList[5] = {npcName = "玩学课堂", npcType = "code_war", npcModel = "character/CC/codewar/sunbinjunshixingtai_movie.x", x = x-5, y = y, z = z-5, show = true};
	ParaWorldNPC.npcList[6] = {npcName = "实战导师", npcType = "code_learn", npcModel = "character/CC/02human/paperman/nuannuan.x", x = x, y = y, z = z-10, show = true};
	for i = 1, #ParaWorldNPC.npcList do
		entityList[i] = ParaWorldNPC.CreateNPCImp(ParaWorldNPC.npcList[i]);
	end
end

function ParaWorldNPC.LoadNPCFromHomePoint(node)
	for i = #ParaWorldNPC.npcList, 1, -1 do
		ParaWorldNPC.npcList[i] = nil;
	end
	for i = 1, #node do
		if (node[i].name == "npc") then
			ParaWorldNPC.npcList[#ParaWorldNPC.npcList + 1] = node[i].attr;
			local npc = ParaWorldNPC.npcList[#ParaWorldNPC.npcList];
			npc.show = (npc.show == nil or npc.show == "true");
		end
	end
	if (#ParaWorldNPC.npcList > 0) then
		for i = 1, #ParaWorldNPC.npcList do
			entityList[i] = ParaWorldNPC.CreateNPCImp(ParaWorldNPC.npcList[i]);
		end
	else
		commonlib.TimerManager.SetTimeout(function() 
			local x, y, z = GameLogic.GetHomePosition();
			if (not x) then
				x, y, z = GameLogic.GetPlayerPosition();
			end
			x,y,z = BlockEngine:block(x,y+0.1,z);
			ParaWorldNPC.CreateDefaultNPC(x, y, z);
		end, 3000);
	end
end

function ParaWorldNPC.CreateNPCImp(npc)
	if (not npc.show) then return end
	local x, y, z = BlockEngine:ConvertToRealPosition_float(npc.x, npc.y, npc.z);
	local entity = EntityManager.EntityNPC:Create({x=x,y=y-0.5,z=z, item_id = block_types.names["villager"]});
	local assetfile = EntityManager.PlayerAssetFile:GetValidAssetByString(npc.npcModel);
	if (npc.f) then
		entity:SetFacing(npc.f % math.pi);
	end
	entity:SetPersistent(false);
	entity:SetServerEntity(false);
	entity:SetCanRandomMove(false);
	entity:EnablePhysics(false);
	entity.bContinueMoveOnCollision = false;
	entity:SetMainAssetPath(assetfile);
	entity:Attach();

	if (npc.npcType == "program" or npc.npcType == "animation" or npc.npcType == "CAD") then
		ParaWorldNPC.CreateTeacherNPC(entity, npc.npcName, npc.npcType);
	elseif (npc.npcType == "head_teacher") then
		entity:Say(L"欢迎来到Paracraft小课堂，请点击不同的老师进入对应的课堂", -1);
		entity.OnClick = function(entity, x, y, z, mouse_button)
			entity:Say(L"欢迎来到Paracraft小课堂，请点击不同的老师进入对应的课堂", -1);
			return true;
		end
	elseif (npc.npcType == "code_war") then
		local headon_mcml = string.format(
			[[<pe:mcml><div style="margin-left:-100px;margin-top:-60px;width:200px;height:20px;">
				<div style="margin-top:20px;width:200px;height:20px;text-align:center;font-size:15px;base-font-size:15;font-weight:bold;shadow-quality:8;color:%s;shadow-color:#8000468e;text-shadow:true">%s</div>
			</div></pe:mcml>]],
			npc.npcColor or "#fcf73c", npc.npcName);
		entity:SetHeadOnDisplay({url=ParaXML.LuaXML_ParseString(headon_mcml)})
		entity.OnClick = function(entity, x, y, z, mouse_button)
			GameLogic.RunCommand("/loadworld -force 19405");
			return true;
		end
	elseif (npc.npcType == "code_learn") then
		for i = 4, #TeachingQuestPage.TaskTypeNames do
			ParaWorldNPC.CreateTeacherNPC(nil, nil, TeachingQuestPage.TaskTypeNames[i]);
		end
		local headon_mcml = string.format(
			[[<pe:mcml><div style="margin-left:-100px;margin-top:-60px;width:200px;height:20px;">
				<div style="margin-top:20px;width:200px;height:20px;text-align:center;font-size:15px;base-font-size:15;font-weight:bold;shadow-quality:8;color:%s;shadow-color:#8000468e;text-shadow:true">%s</div>
			</div></pe:mcml>]],
			npc.npcColor or "#fcf73c", npc.npcName);
		entity:SetHeadOnDisplay({url=ParaXML.LuaXML_ParseString(headon_mcml)})
		entity.OnClick = function(entity, x, y, z, mouse_button)
			TeachingQuestLinkPage.ShowPage();
			return true;
		end
	end

	return entity;
end

function ParaWorldNPC.CreateTeacherNPC(entity, npcName, npcType)
	local function getTaskFromUrl(taskName, callback)
		keepwork.rawfile.get({
			cache_policy =  "access plus 0",
			router_params = {
				repoPath = "official%%2Fparacraft",
				filePath = "official%%2Fparacraft%%2Fconfig%%2F"..taskName..".md",
			}
		},function(err, msg, data)
			local result = commonlib.LoadTableFromString(data);
			if (result and callback) then
				callback(result);
			end
		end)
	end

	local function runExternalFunc(func)
		if (type(func) == "string" and func ~= "") then
			NPL.DoString(func);
		end
	end

	local function showHeadOn(obj, name, state, npcColor)
		if (not obj) then return end
		if (state == TeachingQuestPage.AllFinished) then
			local headon_mcml = string.format(
				[[<pe:mcml><div style="margin-left:-100px;margin-top:-60px;width:200px;height:20px;">
					<div style="margin-top:20px;width:200px;height:20px;text-align:center;font-size:15px;base-font-size:15;font-weight:bold;shadow-quality:8;color:%s;shadow-color:#8000468e;text-shadow:true">%s</div>
				</div></pe:mcml>]],
				npcColor or "#fcf73c", name);
			obj:SetHeadOnDisplay({url=ParaXML.LuaXML_ParseString(headon_mcml)})
		else
			local state_img = {"Texture/Aries/HeadOn/exclamation.png", "Texture/Aries/HeadOn/question.png"};
			local left = {"92px", "84px"};
			local width = {"16px", "32px"};
			local headon_mcml = string.format(
				[[<pe:mcml><div style="margin-left:-100px;margin-top:-120px;width:200px;height:80px;">
					<img style="margin-left:%s;width:%s;height:64px;background:url(%s);background-animation:url(script/UIAnimation/CommonBounce.lua.table#ShakeUD);" />
					<div style="margin-top:20px;width:200px;height:20px;text-align:center;font-size:15px;base-font-size:15;font-weight:bold;shadow-quality:8;color:%s;shadow-color:#8000468e;text-shadow:true">%s</div>
				</div></pe:mcml>]],
				left[state], width[state], state_img[state], npcColor or "#fcf73c", name);
			obj:SetHeadOnDisplay({url=ParaXML.LuaXML_ParseString(headon_mcml)})
		end
	end

	getTaskFromUrl(npcType, function(data)
		TeachingQuestPage.RegisterTasksChanged(function(state)
			if (entity) then
				showHeadOn(entity, npcName, state, data.npcColor);
			end
		end, TeachingQuestPage.TaskTypeIndex[npcType]);
		TeachingQuestPage.AddTasks(data.npcTasks, TeachingQuestPage.TaskTypeIndex[npcType]);
		if (not entity) then
			return;
		end
		entity.OnClick = function(entity, x, y, z, mouse_button)
			if (data.npcScript) then
				runExternalFunc(data.npcScript);
			end
			return true;
		end
	end);
end

function ParaWorldNPC.ShowPage()
	local params = {
		url = "script/apps/Aries/Creator/Game/Tasks/ParaWorld/ParaWorldNPC.html",
		name = "ParaWorldNPC.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = false,
		enable_esc_key = true,
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		directPosition = true,
		align = "_ctt",
		x = 0,
		y = 20,
		width = 360,
		height = 220,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function ParaWorldNPC.OnClose()
	page:CloseWindow();
end

function ParaWorldNPC.MoveNPC(index)
	local entity = entityList[index];
	local player = EntityManager.GetPlayer()
	if(entity and player) then
		local x, y, z = player:GetBlockPos();
		local facing = player:GetFacing();
		entity:SetBlockPos(x, y, z);
		entity:SetFacing(facing);
		ParaWorldNPC.npcList[index].x = x;
		ParaWorldNPC.npcList[index].y = y;
		ParaWorldNPC.npcList[index].z = z;
		ParaWorldNPC.npcList[index].f = facing;
	end
end

function ParaWorldNPC.RenameNPC(index)
	local RenameNPC = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaWorld/RenameNPC.lua");
	RenameNPC.ShowPage(function(result)
		if (result) then
			ParaWorldNPC.npcList[index].npcName = result;
			if (entityList[index]) then
				entityList[index]:Destroy();
				entityList[index] = ParaWorldNPC.CreateNPCImp(ParaWorldNPC.npcList[index]);
			end
			if (page) then
				page:Refresh(0);
			end
		end
	end);
end

function ParaWorldNPC.ShowNPC(checked)
	for i = 1, #ParaWorldNPC.npcList do
		local check = page:GetUIValue(string.format("check_%d", i), false);
		if (ParaWorldNPC.npcList[i].show ~= check) then
			ParaWorldNPC.npcList[i].show = check;
			if (check) then
				entityList[i] = ParaWorldNPC.CreateNPCImp(ParaWorldNPC.npcList[i]);
			else
				if (entityList[i]) then
					entityList[i]:Destroy();
				end
			end
		end
	end
end