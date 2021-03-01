--[[
Title: Agent Editor Page
Author(s): LiXizhi
Date: 2021/2/17
Desc: it defines properties of agent package
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/AgentEditorPage.lua");
local AgentEditorPage = commonlib.gettable("MyCompany.Aries.Game.GUI.AgentEditorPage");
AgentEditorPage.ShowPage();
-------------------------------------------------------
]]
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local AgentEditorPage = commonlib.gettable("MyCompany.Aries.Game.Agent.AgentEditorPage");

local cur_entity;
local page;

AgentEditorPage.updateMethods = {
	{value="always", text=L"强制更新"},
	{value="never", text=L"从不更新", selected=true},
	{value="manual", text=L"手工更新"},
}

function AgentEditorPage.OnInit()
	page = document:GetPageCtrl();

	if(cur_entity) then
		local blocks = cur_entity:HighlightConnectedBlocks();
		if(blocks) then
			page:SetValue("blockCount", tostring(#blocks))
		end
		page:SetValue("agentPackageName", cur_entity:GetAgentName())
		page:SetValue("agentPackageVersion", cur_entity:GetVersion())
		page:SetValue("agentDependencies", cur_entity:GetAgentDependencies())
		page:SetValue("agentExternalFiles", cur_entity:GetAgentExternalFiles())
		page:SetValue("agentUrl", cur_entity:GetAgentUrl())
		page:SetValue("isGlobal", cur_entity:IsGlobal() == true)

		local updateMethod = cur_entity:GetUpdateMethod();
		for i, item in ipairs(AgentEditorPage.updateMethods) do
			if(item.value == updateMethod) then
				item.selected = true;
			else
				item.selected = nil;
			end
		end
	end
end

function AgentEditorPage.GetEntity()
	return cur_entity;
end

function AgentEditorPage.ShowPage(entity)
	if(not entity) then
		return;
	end
	
	if(cur_entity~=entity) then
		if(page) then
			page:CloseWindow();
		end
		cur_entity = entity;
	end

	local params = {
		url = "script/apps/Aries/Creator/Game/Agent/AgentEditorPage.html", 
		name = "AgentEditorPage.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		bToggleShowHide=false, 
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		enable_esc_key = true,
		bShow = true,
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		directPosition = true,
			align = "_lt",
			x = 0,
			y = 160,
			width = 200,
			height = 500,
	};
	
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	params._page.OnClose = function()
		if(cur_entity) then
			cur_entity:HighlightConnectedBlocks(false);
		end
		cur_entity = nil;
		page = nil;
	end
end

function AgentEditorPage.CloseWindow()
	if(page) then
		page:CloseWindow();
	end
end

function AgentEditorPage.OnClickOK()
	local entity = AgentEditorPage.GetEntity();
	if(entity) then
		local version = page:GetValue("agentPackageVersion");
		local agentName = page:GetValue("agentPackageName");
		local agentDependencies = page:GetValue("agentDependencies");
		local agentExternalFiles = page:GetValue("agentExternalFiles");
		local agentUrl = page:GetValue("agentUrl");
		local isGlobal = page:GetValue("isGlobal");
		local updateMethod = page:GetValue("updateMethod");
		entity:SetVersion(version);
		entity:SetGlobal(isGlobal);
		if(agentName~=entity:GetAgentName()) then
			entity:SetAgentName(agentName);
		end
		entity:ResetAgentUrl()
		
		entity:SetAgentDependencies(agentDependencies);
		entity:SetAgentExternalFiles(agentExternalFiles);
		
		
		entity:SetUpdateMethod(updateMethod);

		-- finally save to agent file
		if(entity:IsInCurrentWorld() or entity:IsOfficialModAgents()) then
			if(entity:SaveToAgentFile()) then
				GameLogic.AddBBS(nil, format(L"智能模块保存成功"), 5000, "0 255 00");
			end
		end
		entity:Refresh()
	end
	page:CloseWindow();
end

function AgentEditorPage.OnChangeGlobal()
	local entity = AgentEditorPage.GetEntity();
	if(entity and page) then
		entity:SetGlobal(page:GetValue("isGlobal") == true);
		entity:ResetAgentUrl()
		page:SetValue("agentUrl", entity:GetAgentUrl())
	end
end

function AgentEditorPage.OnClickOpenFolder()
	local entity = AgentEditorPage.GetEntity();
	if(entity) then
		local filename = entity:GetAgentFilename()
		if(filename) then
			filename = filename:gsub("[^/\\]*$","")
			System.App.Commands.Call("File.WinExplorer", filename);
		end
	end
end