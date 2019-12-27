--[[
Title: EditCode Page
Author(s): LiXizhi
Date: 2014/1/21
Desc: # is used as the line seperator \r\n. Space key is replaced by _ character. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/EditCodePage.lua");
local EditCodePage = commonlib.gettable("MyCompany.Aries.Game.GUI.EditCodePage");
EditCodePage.ShowPage(itemStack, OnClose);
-------------------------------------------------------
]]
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local NeuronManager = commonlib.gettable("MyCompany.Aries.Game.Neuron.NeuronManager");
local EditCodePage = commonlib.gettable("MyCompany.Aries.Game.GUI.EditCodePage");

local curItemStack;
local page;

function EditCodePage.OnInit()
	page = document:GetPageCtrl();

	EditCodePage.lastCode = EditCodePage.GetCode();			
	
	page:SetValue("content", EditCodePage.lastCode or "");
end

function EditCodePage.GetItemID()
	return curItemStack.id;
end

function EditCodePage.GetItemStack()
	return curItemStack;
end

function EditCodePage.GetCode()
	local filename = EditCodePage.GetFullPath();
	if(filename) then
		local file = ParaIO.open(filename, "r");
	    if(file:IsValid()) then
		    local text = file:GetText();
		    file:close();
			return text;
        else
			return format("file %s is NOT found", filename);
	    end	
    end
end

function EditCodePage.OnClose()
	if(page) then
		page:CloseWindow();
	end
end

function EditCodePage.SetCode(code)
	-- TODO: 
end

-- get relative to SDK root directory path
function EditCodePage.GetFullPath()
	local filename = EditCodePage.GetScriptFileName();
	if(filename) then
		return NeuronManager.GetScriptFullPath(filename);
	end
end


function EditCodePage.OnClickSave()
	-- open the script using a text editor
	local filename = EditCodePage.GetScriptFileName();

	local newCode; 
	if(page) then
		newCode = page:GetValue("content");
	end

	if(EditCodePage.lastCode ~= newCode) then
		local filenameDisk = EditCodePage.GetFullPath();
		if(filenameDisk) then
			-- instead of open file, just open the containing directory. 
			local file = ParaIO.open(filenameDisk, "w")
			if(file and file:IsValid()) then
				if(newCode and newCode~="") then
					file:WriteString(newCode, #newCode);
				end
				file:close();
				GameLogic.AddBBS(nil, format(L"成功保存到:%s", filename));
			else
				GameLogic.AddBBS(nil, format(L"无法保存到:%s", filename));
			end
		end
	end
	EditCodePage.OnClose();
end

-- edit in npl code wiki editor
function EditCodePage.OnClickEdit()
    local filename = EditCodePage.GetFullPath();
    if(filename) then
		filename = commonlib.Encoding.url_encode(commonlib.Encoding.DefaultToUtf8(filename));
        GameLogic.RunCommand("/open npl://editcode?src="..filename);
    end
end

function EditCodePage.OnEditScript()
	-- open the script using a text editor
	local filename = EditCodePage.GetFullPath();
	if(filename) then
		-- instead of open file, just open the containing directory. 
		if(mouse_button == "right") then
			-- open containing folder
			Map3DSystem.App.Commands.Call("File.WinExplorer", {filepath = filename:gsub("[^/\\]+$", ""), silentmode=true});
		else
			-- open file 
			Map3DSystem.App.Commands.Call("File.WinExplorer", {filepath = filename, silentmode=true});
		end
	end
end

function EditCodePage.GetScriptFileName()
	local content = curItemStack:GetData();
	if(type(content) == "string" and (content:match("%.lua$") or content:match("%.npl$"))) then
		return content;
	end
end

function EditCodePage.SetScriptFileName(filename)
	curItemStack:SetScript(filename);
end

function EditCodePage.OnCreateNewFile()
	NPL.load("(gl)script/apps/Aries/Creator/Game/Neuron/CreateNewNeuronScriptFile.lua");
	local CreateNewNeuronScriptFile = commonlib.gettable("MyCompany.Aries.Game.Tasks.CreateNewNeuronScriptFile");
	CreateNewNeuronScriptFile.ShowPage(function(filename)
		if(filename) then
			if(EditCodePage.GetScriptFileName()~=filename) then
				EditCodePage.SetScriptFileName(filename);
				if(page) then
					page:Refresh(0.1);
				end
			end
		end
	end)
end

function EditCodePage.GetTitle()
    return format(L"%s(Ctrl+右键执行)", EditCodePage.GetItemStack():GetDisplayName());
end

function EditCodePage.OnFileChangedFilter(msg)
	if(msg and msg.fullname == EditCodePage.GetFullPath()) then
		if(page) then
			page:Refresh(0.1);
		end
	end
	return msg;
end

function EditCodePage.ShowPage(itemStack, OnClose)
	if(not itemStack) then
		return;
	end
	curItemStack = itemStack;

	GameLogic:GetFilters():add_filter("worldFileChanged", EditCodePage.OnFileChangedFilter);

	local params = {
			url = "script/apps/Aries/Creator/Game/GUI/EditCodePage.html", 
			name = "EditCodePage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			click_through = false, 
			enable_esc_key = true,
			bShow = true,
			zorder = -1,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_ct",
				x = -180,
				y = -200,
				width = 360,
				height = 400,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
	params._page.OnClose = function()
		if(OnClose) then
			OnClose();
		end
		GameLogic:GetFilters():remove_filter("worldFileChanged", EditCodePage.OnFileChangedFilter);
	end
end
