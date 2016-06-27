--[[
Title: The dock page
Author(s): LiXizhi
Date: 2012/12/28
Desc:  
There dock has 2 mode: one for editor and one for creator
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/GoalTracker.lua");
local GoalTracker = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.GoalTracker");
GoalTracker.ShowPage(true)
GoalTracker.SetText("hi")
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/headon_speech.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/API/UserProfile.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/API/ExpTable.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/API/UserProfile.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Effects/ObtainItemEffect.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildQuestTask.lua");
local BuildQuest = commonlib.gettable("MyCompany.Aries.Game.Tasks.BuildQuest");
local ObtainItemEffect = commonlib.gettable("MyCompany.Aries.Game.Effects.ObtainItemEffect");
local UserProfile = commonlib.gettable("MyCompany.Aries.Creator.Game.API.UserProfile");
local ExpTable = commonlib.gettable("MyCompany.Aries.Creator.Game.API.ExpTable");
local UserProfile = commonlib.gettable("MyCompany.Aries.Creator.Game.API.UserProfile");
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local GoalTracker = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.GoalTracker");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local names = commonlib.gettable("MyCompany.Aries.Game.block_types.names")

GoalTracker.tip_text = "";
local newuser_tip_text = L"点击我,开始你的创造之旅";

local page;
function GoalTracker.OnInit()
	page = document:GetPageCtrl();

	if(GoalTracker.tip_text == "") then
		local profile = UserProfile.GetUser();
		NPL.load("(gl)script/apps/Aries/Creator/Game/API/ExpTable.lua");
		local ExpTable = commonlib.gettable("MyCompany.Aries.Creator.Game.API.ExpTable");
		if(false and ExpTable.GetThisLevelExp(profile:GetExp())<=2) then
			-- disabled
			GoalTracker.tip_text = newuser_tip_text;
		else
			GoalTracker.tip_text = nil;
		end
	end
	GameLogic.events:AddEventListener("OnCollectItem", GoalTracker.OnCollectItem, GoalTracker, "GoalTracker");

	local profile = UserProfile.GetUser();
	--profile:GetEvents():AddEventListener("OnExpChanged", GoalTracker.OnExpChanged, GoalTracker, "GoalTracker");
	--profile:GetEvents():AddEventListener("OnLevelChanged", GoalTracker.OnLevelChanged, GoalTracker, "GoalTracker");
	--profile:GetEvents():AddEventListener("OnWaterChanged", GoalTracker.OnWaterChanged, GoalTracker, "GoalTracker");
	--profile:GetEvents():AddEventListener("OnGoldChanged", GoalTracker.OnGoldChanged, GoalTracker, "GoalTracker");
	--profile:GetEvents():AddEventListener("OnStaminaChanged", GoalTracker.OnStaminaChanged, GoalTracker, "GoalTracker");
	profile:GetEvents():AddEventListener("BuildProgressChanged", GoalTracker.OnBuildProgressChanged, GoalTracker, "GoalTracker");
	GameLogic.GetEvents():AddEventListener("CreateBlockTask", GoalTracker.OnCreateBlock, GoalTracker, "GoalTracker");
	GameLogic.GetEvents():AddEventListener("game_mode_change", GoalTracker.OnGameModeChanged, GoalTracker, "GoalTracker");
end

function GoalTracker.ShowPage(bShow)
	if(System.options.IsMobilePlatform) then
		return
	end
	if(not GameLogic.GameMode:IsShowGoalTracker() and bShow) then
		return;
	end

	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Game/Areas/GoalTracker.html", 
			name = "GoalTracker.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			bShow = bShow,
			zorder = -2,
			click_through = true,
			directPosition = true,
				align = "_mt",
				x = 0,
				y = 0,
				width = 0,
				height = 163,
		});
	if(bShow) then
		GoalTracker.Refresh();
	end
end

-- set cody's text
-- @param text: any text
-- @param target: nil or "<player>"
-- @return true if text changed. 
function GoalTracker.SetText(text, target, duration)
	if(text == "") then
		text = nil;
	end
	if(text~=GoalTracker.tip_text) then
		if(text and text~="") then
			GoalTracker.tip_text = text;
			if(page) then
				page:FindControl("tip").visible = true;
				page:SetValue("text", text or "");
			end
		else
			if(page) then
				page:FindControl("tip").visible = false;
			end
			GoalTracker.tip_text = nil;
		end

		if(target) then
			if(GoalTracker.tip_text) then
				-- local mcml_text = format("<div>%s</div>", text);
				--headon_speech.Speek(target, mcml_text, duration or 5);
				headon_speech.Speek(target, text, duration or 12, true);
			end
		end
		return true;
	end
end

-- hide cody's text
function GoalTracker.HideTipText(target)
	if(page) then
		page:FindControl("tip").visible = false;
	end
	GoalTracker.tip_text = nil;

	if(target) then
		headon_speech.Speek(target, "", 0, true);
	end
	return true;
end

function GoalTracker:OnGameModeChanged()
	if(page) then
		local ctl = page:FindControl("editor");
		if(ctl) then
			ctl.visible = (GameLogic.GameMode:IsEditor()) and not GameLogic.options.has_real_terrain;
		end
		local ctl = page:FindControl("game");
		if(ctl) then
			ctl.visible = (not GameLogic.GameMode:IsEditor()) and not GameLogic.options.has_real_terrain;
		end

		if(page:IsVisible()) then 
			if(not GameLogic.GameMode:IsShowGoalTracker()) then
				GoalTracker.ShowPage(false);
			end
		else
			if(GameLogic.GameMode:IsShowGoalTracker()) then
				GoalTracker.ShowPage(true);
			end
		end
	end
end

function GoalTracker:OnCollectItem(event)
	if(not page) then
		return;
	end
	local item = ItemClient.GetItem(event.block_id);
	if(item and item.gold_count and item.gold_count>0) then
		GameLogic.GetProfile():AddGold(item.gold_count);
	end
end

function GoalTracker.GetExpTip(Exp)
	if(not Exp) then
		Exp = UserProfile.GetUser():GetExp();
	end
	local level = ExpTable.GetLevel(Exp);
	local levelup_exp = ExpTable.GetExpToNextLevel(Exp);
	return format(L"还需%d xp 到达%d级", levelup_exp, level);
end

function GoalTracker:OnExpChanged(event)
	if(page and event.value) then
		local btn = page:FindControl("Exp");
		if(btn) then
			btn.text = tostring(ExpTable.GetThisLevelExp(event.value));
			btn.tooltip = GoalTracker.GetExpTip(event.value);
			if(event.delta and event.delta > 0) then
				local max_count = math.min(10,event.delta);
				-- at most 
				for count = 1, max_count do
					ObtainItemEffect:new({background="Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png;488 42 18 18", duration=1800, color="#ffffffff", width=18,height=18, 
						from_3d={}, to_2d={x=btn.x+8,y=btn.y+16},}):Play((count-1)*100);
				end
				ObtainItemEffect:new({text=format("+%d XP",event.delta), duration=2000, color="#835ba6", width=100,height=18, 
						from_2d={x=btn.x+48,y=btn.y+96}, to_2d={x=btn.x+8,y=btn.y+16}, fadeOut=200, fadeIn=200}):Play(max_count*100+1200);
			end
		end
	end
end

function GoalTracker:OnBuildProgressChanged(event)
	if(page) then
		if(event.status == "start" or event.status == "end") then
			page:Refresh();

		elseif(event.value) then
			local btn = page:FindControl("cody");
			if(btn) then
				local max_count = 8;
				-- at most 
				for count = 1, max_count do
					ObtainItemEffect:new({background="Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png;464 43 18 18", duration=1800, color="#ffffffff", width=18,height=18, 
						from_3d={}, to_2d={x=btn.x+48,y=btn.y+24},}):Play((count-1)*100);
				end

				ObtainItemEffect:new({background="", text=L"教学完成", duration=3000, color="#33ff33", width=150,height=25, 
						from_2d={x=btn.x+128,y=btn.y+64}, to_2d={x=btn.x+48,y=btn.y+24}, fadeOut=300, fadeIn=300}):Play(max_count*100+1200);
				GameLogic.SetTipText(nil);
			end
		end
	end
end

function GoalTracker:OnLevelChanged(event)
	if(page and event.value) then
		local btn = page:FindControl("Level");
		if(btn) then
			page:SetUIValue("Level", tostring(event.value));
		end
	end
end

function GoalTracker:OnStaminaChanged(event)
	if(page and event.value) then
		page:SetValue("Stamina", tostring(event.value));
	end
end

function GoalTracker:OnGoldChanged(event)
	if(page and event.value) then
		local btn = page:FindControl("Gold");
		if(btn) then
			btn.text = tostring(event.value);
			if(event.delta and event.delta > 0) then
				local max_count = math.min(10,event.delta);
				-- at most 
				for count = 1, max_count do
					ObtainItemEffect:new({background="Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png;488 42 18 18", duration=1800, color="#ffffffff", width=18,height=18, 
						from_3d={}, to_2d={x=btn.x+8,y=btn.y+16},}):Play((count-1)*100);
				end
			end
		end
	end
end

function GoalTracker:OnWaterChanged(event)
	if(page and event.value) then
		page:SetValue("Water", tostring(event.value));
	end
end

function GoalTracker:OnCreateBlock(event)
	local profile = UserProfile.GetUser();
	profile:AddCreateBlock(1);
end

function GoalTracker.Refresh()
	if(page) then
		page:Refresh(0.01);
	end
end

-- whether there are active task. 
function GoalTracker.IsTaskActive()
	return BuildQuest.IsTaskUnderway();
end

function GoalTracker.OnClickCody()
	if(GoalTracker.IsTaskActive()) then
		local task = BuildQuest.GetCurrentQuest().task;
		if(task) then
			_guihelper.MessageBox(string.format(L"【%s】正在建造中,是否放弃?",task.name),function(msg)
				if(msg == _guihelper.DialogResult.Yes)then
						BuildQuest.EndEditing();
					else
					end
			end,_guihelper.MessageBoxButtons.YesNo)
		end
		return;
	end
	GameLogic.SetTipText(nil);

	GameLogic.RunCommand("/menu help.help");

	--if(GameLogic.options.has_real_terrain) then
		--_guihelper.MessageBox("建议您新建世界, 并选择积木世界来完成这里的任务");
	--end
end
