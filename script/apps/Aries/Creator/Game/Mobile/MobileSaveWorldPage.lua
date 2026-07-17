--[[
author:{ygy}
time:2022-11-3

local MobileSaveWorldPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobileSaveWorldPage.lua")
MobileSaveWorldPage.ShowPage("save_world")
]]
NPL.load("(gl)script/apps/Aries/Creator/WorldCommon.lua");
local EnterGamePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.EnterGamePage");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
local MobileSaveWorldPage = NPL.export()
local Desktop = commonlib.gettable('MyCompany.Aries.Creator.Game.Desktop')
-- local filePath = "Texture/Aries/Creator/keepwork/Mobile/help/"
MobileSaveWorldPage.default_desc = ""
MobileSaveWorldPage.desc_upload = true
local isModified = false

local page
function MobileSaveWorldPage.OnInit()
    page = document:GetPageCtrl();
    page.OnClose = MobileSaveWorldPage.OnClose

	MobileSaveWorldPage.worldname = WorldCommon.GetWorldTag("name");
    local node_name = GameLogic.IsReadOnly() and "worldname" or "edit_worldname"
	page:SetValue(node_name, MobileSaveWorldPage.worldname)

	if(MobileSaveWorldPage.image_filepath) then
		page:SetValue("WorldImage", MobileSaveWorldPage.image_filepath);
	end    
    isModified = WorldCommon.IsModified()
end

function MobileSaveWorldPage.OnClose()
    MobileSaveWorldPage.is_in_sysnc = false
end

-- button_type: "save_world", "upload_world", "exit_world","commit_work"(提交作业)
function MobileSaveWorldPage.ShowPage(button_type, exit_world_callback)
    local width = 880
    local height = 642

    MobileSaveWorldPage.button_type = button_type or "exit_world"
    MobileSaveWorldPage.exit_world_callback = exit_world_callback
    local parentDir = GameLogic.GetWorldDirectory();
    local path = string.format("%s%s", parentDir, "page/code/MobileSaveWorldPage.html")
    local params = {
        url = "script/apps/Aries/Creator/Game/Mobile/MobileSaveWorldPage.html",
        -- url = path,
        name = "MobileSaveWorldPage.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        zorder = 1,
        directPosition = true,
        click_through=false,
        -- DesignResolutionWidth = 880,
        -- DesignResolutionHeight = 642,
        cancelShowAnimation = true,
        withBgMask=true,
        align = "_ct",
        x = -width/2,
        y = -height/2,
        width = width,
        height = height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);

    MobileSaveWorldPage.TakeImage(true);

    local world_data = GameLogic.GetFilters():apply_filters('store_get', 'world/currentWorld')

    local desc_node_name = GameLogic.IsReadOnly() and "save_world_multilineedit" or "edit_save_world_multilineedit"
    if world_data and world_data.kpProjectId and world_data.kpProjectId ~= 0 then
        
        keepwork.world.detail({router_params = {id = world_data.kpProjectId}}, function(err, msg, data)
            if err == 200 then
                -- print("dddddddddxx")
                -- echo(data, true)
                MobileSaveWorldPage.desc_upload = false
                if data and data.description and data.description ~= "" and page then
                    MobileSaveWorldPage.default_desc = data.description
                    MobileSaveWorldPage.desc_upload = true
                    MobileSaveWorldPage.default_desc = string.gsub(MobileSaveWorldPage.default_desc, "<p>", "")
                    MobileSaveWorldPage.default_desc = string.gsub(MobileSaveWorldPage.default_desc, "</p>", "")
                    
                    page:SetValue(desc_node_name, MobileSaveWorldPage.default_desc)
                end
            end
        end);
    else
        MobileSaveWorldPage.desc_upload = false
        MobileSaveWorldPage.default_desc = WorldCommon.GetWorldTag("world_desc");
        page:SetValue(desc_node_name, MobileSaveWorldPage.default_desc)
    end
end

function MobileSaveWorldPage.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
end

function MobileSaveWorldPage.OnEditValueChange()
    -- local edit_node = page:FindControl("save_world_multilineedit")
    -- -- edit_node.SelectedNode.Text = edit_node.SelectedNode.Text .. "mmm"
    -- local thisLine = ParaUI.GetUIObject(edit_node.SelectedNode.editor_id);
    -- thisLine.text = edit_node.SelectedNode.Text .. "mmm"
    -- print("ppppppxxx", edit_node.SelectedNode.GetNextNode)
    --edit_node:RefreshUI()
end

function MobileSaveWorldPage.TakeImage(bTakeIfFileDoesNotExist)
	--local page = MobileSaveWorldPage.sharepage;
	local filepath = MobileSaveWorldPage.GetPreviewImagePath("preview.jpg");
	MobileSaveWorldPage.image_filepath = filepath;
	
	local function SaveAsWorldPreview()
		NPL.load("(gl)script/ide/System/Util/ScreenShot.lua");
		local ScreenShot = commonlib.gettable("System.Util.ScreenShot");
		if(ScreenShot.TakeSnapshot(filepath,300,200, false)) then
			--page:SetUIValue("result", string.format("世界截图保存成功:%s", filepath));
			page:SetUIValue("WorldImage", filepath);
		end
	end
	
	if(ParaIO.DoesFileExist(filepath, true)) then
		if(not bTakeIfFileDoesNotExist) then
			SaveAsWorldPreview();
			ParaAsset.LoadTexture("",filepath,1):UnloadAsset();
		else
			page:SetUIValue("WorldImage", filepath);
		end

        --[[
		_guihelper.MessageBox(string.format("世界预览图已经存在, 是否要覆盖它?"), function()
			SaveAsWorldPreview();
			ParaAsset.LoadTexture("",filepath,1):UnloadAsset();
		end);
        ]]
	else
		SaveAsWorldPreview();
	end
end
function MobileSaveWorldPage.OnSaveWorld()
	local function callback()     
        MobileSaveWorldPage.SaveName()   
        GameLogic.QuickSave();
        MobileSaveWorldPage.SaveDesc()
	end

	if GameLogic.GetFilters():apply_filters("SaveWorld", false, callback) then
		return false
	end

	callback()
end

function MobileSaveWorldPage.OnSaveWorldAndExit()
    if MobileSaveWorldPage.is_in_sysnc then
        return
    end

	local function callback()     
        MobileSaveWorldPage.SaveName()   
        GameLogic.QuickSave();
        MobileSaveWorldPage.SaveDesc()

        local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon")
        local isHomeWorkWorld = WorldCommon.GetWorldTag("isHomeWorkWorld");
        if isHomeWorkWorld then
            MobileSaveWorldPage.is_in_sysnc = true
            GameLogic.SysncHomeWorkWorld(MobileSaveWorldPage.OnExitWorld,isModified)
        else
            MobileSaveWorldPage.OnExitWorld()
        end 
	end

	if GameLogic.GetFilters():apply_filters("SaveWorld", false, callback) then
		return false
	end

	callback()
end

function MobileSaveWorldPage.on_exit_to_login()
    Mod.WorldShare.MsgBox:Close()
    local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")
    CreateNewWorld.profile = nil
    System.options.cmdline_world = nil
    MyCompany.Aries.Game.MainLogin:set_step({HasInitedTexture = true}); 
    MyCompany.Aries.Game.MainLogin:set_step({IsPreloadedTextures = true}); 
    MyCompany.Aries.Game.MainLogin:set_step({IsLoadMainWorldRequested = true}); 
    MyCompany.Aries.Game.MainLogin:set_step({IsCreateNewWorldRequested = true});
    MyCompany.Aries.Game.MainLogin:next_step({IsLoginModeSelected = false})
end

function MobileSaveWorldPage.on_exit_game()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
    local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
    CustomCharItems:Init();
    local Game = commonlib.gettable("MyCompany.Aries.Game")
    if(Game.is_started) then
        Game.Exit()
    end

    GameLogic.GetFilters():apply_filters("OnKeepWorkLogout", true)

    local CreateNewWorld = commonlib.gettable("MyCompany.Aries.Game.MainLogin.CreateNewWorld")
    CreateNewWorld.profile = nil
    ParaUI.GetUIObject('root'):RemoveAll()
    NPL.load("(gl)script/ide/TooltipHelper.lua");
    local BroadcastHelper = commonlib.gettable("CommonCtrl.BroadcastHelper");
    if(type(BroadcastHelper.Reset) == "function") then
        BroadcastHelper.Reset();
    end
    AudioEngine.Init()

    NPL.load("(gl)script/apps/Aries/Creator/Game/Login/MainLogin.lua");
    local MainLogin = commonlib.gettable("MyCompany.Aries.Game.MainLogin");
    if MainLogin then
        MainLogin:SetWindowTitle()
    end
end

function MobileSaveWorldPage.OnExitWorld()
    MobileSaveWorldPage.is_in_sysnc = false
    if System.options.isOffline then
        MobileSaveWorldPage.ClosePage()
        MobileSaveWorldPage.on_exit_game()
        MobileSaveWorldPage.on_exit_to_login()
        return 
    end
    local WorldExitDialog = NPL.load('(gl)Mod/WorldShare/cellar/WorldExitDialog/WorldExitDialog.lua')
    -- if MobileSaveWorldPage.exit_world_callback then
    --     local WorldExitDialogPage = Mod.WorldShare.Store:Get('page/Mod.WorldShare.WorldExitDialog')
    --     WorldExitDialogPage.callback = MobileSaveWorldPage.exit_world_callback
    -- end
    MobileSaveWorldPage.ClosePage()
    WorldExitDialog.OnDialogResult(_guihelper.DialogResult.No)
end

function MobileSaveWorldPage.SaveName()
    local node_name = GameLogic.IsReadOnly() and "worldname" or "edit_worldname"
    local name = page and page:GetUIValue(node_name) or "";
    if name ~= MobileSaveWorldPage.worldname then
        local temp = MyCompany.Aries.Chat.BadWordFilter.FilterString2(name);
        if temp~=name then 
            _guihelper.MessageBox(L"该世界名称不可用，请重新设定");
            return
        end
        local len = ParaMisc.GetUnicodeCharNum(name);
        local count = 0
        for uchar in string.gfind(name, '([%z\1-\127\194-\244][\128-\191]*)') do
            if #uchar ~= 1 then
                count = count + 2
            else
                count = count + 1
            end
        end
        
        if count > 66 then
            _guihelper.MessageBox(format(L'世界名字超过%d个字符, 请重新输入', 66))
            return
        end

        local world_data = GameLogic.GetFilters():apply_filters('store_get', 'world/currentWorld') or {}
        world_data.text = name
        local curr_world = Mod.WorldShare.Store:Get('world/currentEnterWorld') or {}
        curr_world.text = name
        curr_world.name = name
        WorldCommon.SetWorldTag("name", name);
        GameLogic.options:ResetWindowTitle()
        MobileSaveWorldPage.worldname = name;
    end
end

function MobileSaveWorldPage.SaveDesc(desc)
    if not desc or desc == "" then
        local desc_node_name = GameLogic.IsReadOnly() and "save_world_multilineedit" or "edit_save_world_multilineedit"
        desc = page and page:GetValue(desc_node_name)
    end
    
    if desc ~= MobileSaveWorldPage.default_desc or not MobileSaveWorldPage.desc_uploa then
        local world_data = GameLogic.GetFilters():apply_filters('store_get', 'world/currentWorld')
        if world_data and world_data.kpProjectId and world_data.kpProjectId ~= 0 then
            keepwork.project.update({
                router_params = {
                    id = world_data.kpProjectId,
                },
                description=desc,
            },function(err,msg,data)
                if err == 200 then
                    MobileSaveWorldPage.default_desc = desc
                    WorldCommon.SetWorldTag("world_desc", desc);
                end
            end)
        else
            WorldCommon.SetWorldTag("world_desc", desc);
        end
    end
end

function MobileSaveWorldPage.GetPreviewImagePath(img_name)
    if not ParaWorld.GetWorldDirectory() then
        return ''
    end

    if System.os.GetPlatform() ~= 'win32' then
        return ParaIO.GetWritablePath() .. ParaWorld.GetWorldDirectory() .. img_name
    else
        return ParaWorld.GetWorldDirectory() .. img_name
    end
end

function MobileSaveWorldPage.OnFocuseIn(name, index)
    local ctrl, linde_node = CommonCtrl.MultiLineEditbox.GetCtrlAndLineNode(name, index)
    if(ctrl.SelectedNode) then
        local thisLine = ParaUI.GetUIObject(ctrl.SelectedNode.editor_id);
        if(thisLine:IsValid()) then
            thisLine:SetCaretPosition(-1);
        end
    end	
end

function MobileSaveWorldPage.GetTitle()
    if MobileSaveWorldPage.button_type == "exit_world" then
        return "退出世界"
    elseif MobileSaveWorldPage.button_type == "commit_work" then
        return "提交作业"
    else
        return "保存世界"
    end
end