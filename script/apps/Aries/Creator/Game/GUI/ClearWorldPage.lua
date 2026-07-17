--[[
Title: CLear World's files 
Author(s): pbb
Date: 2024/12/10
Desc: This script is used to clear the world's files.
use the lib:
------------------------------------------------------------
local ClearWorldPage = NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/ClearWorldPage.lua");
ClearWorldPage.ShowPage(option)
-------------------------------------------------------
]]

local ClearWorldPage = NPL.export()
local page
ClearWorldPage.fileExtenstions = {}
ClearWorldPage.clearSilient = false
ClearWorldPage.ExcludedFiles = {}
function ClearWorldPage.OnInit()
    page = document:GetPageCtrl()
end

function ClearWorldPage.ShowPage(option)
    ClearWorldPage.ParseOptions(option)
    ClearWorldPage.InitWorldFiles()
    ClearWorldPage.FindAllUsedFiles()
    ClearWorldPage.HandleClearDatas()
end

--{{fileExt="bmax",checked=true,},{fileExt="stl",checked=true,},{fileExt="txt",checked=true,},}
--解析需要清除的文件类型
function ClearWorldPage.ParseOptions(option)
    ClearWorldPage.fileExtenstions = {}
    if option then
        if option.exts and option.exts ~= "" then
            for fileExt in string.gmatch(option.exts, "[^,]+") do
                ClearWorldPage.fileExtenstions[#ClearWorldPage.fileExtenstions + 1] = { fileExt = fileExt, checked = true }
            end
        end
        if option.excludes and option.excludes ~= "" then
            for exclude in string.gmatch(option.excludes, "[^,]+") do
                ClearWorldPage.ExcludedFiles[#ClearWorldPage.ExcludedFiles + 1] = exclude
            end
        end
        ClearWorldPage.clearSilient = option.silient == true
    end
end

function ClearWorldPage.InitWorldFiles()
    ClearWorldPage.InitWorldBaseFiles()
    local worldPath = ParaWorld.GetWorldDirectory()
    local files = {};
    if ClearWorldPage.fileExtenstions and #ClearWorldPage.fileExtenstions > 0 then
        local result = commonlib.Files.Find({}, worldPath, 10, 5000, function(item)
            local isMatch = false
            for i, fileExt in ipairs(ClearWorldPage.fileExtenstions) do
                local regex = "%."..fileExt.fileExt.."$"
                if(item.filename:match(regex)) then
                    isMatch = true;
                    break;
                end
            end
			return isMatch;
		end)
        for i = 1, #result do
            local filename = result[i].filename
            local fileAttr = result[i].fileattr
            if not ClearWorldPage.CheckNeedExclude(filename) and fileAttr == 32 then
                files[#files + 1] = result[i]
            end
        end
    else
        local result = commonlib.Files.Find({}, worldPath, 10, 5000, function(item)
            return true;
        end)
        for i = 1, #result do
            local filename = result[i].filename
            local fileAttr = result[i].fileattr
            if not ClearWorldPage.CheckNeedExclude(filename) and fileAttr == 32 then
                files[#files + 1] = result[i]
            end
        end
    end
    ClearWorldPage.world_files = files;
end

function ClearWorldPage.FindAllUsedFiles()
    local findResult = {};
    local entities = GameLogic.EntityManager.FindEntities({category="all", }) or {};
	for i, entity in ipairs(entities) do
        local modelFile  = string.lower((entity and entity.GetModelFile) and entity:GetModelFile() or "")
        if(modelFile and modelFile~="") then
            findResult[modelFile] = true;
        end
    end
    ClearWorldPage.findResult = findResult;
    echo("find==============")
    echo(findResult,true)
end

function ClearWorldPage.CheckNeedExclude(filename)
    return ClearWorldPage.CheckIsBaseFile(filename) or ClearWorldPage.CheckIsExcludedFile(filename)
end

function ClearWorldPage.CheckIsBaseFile(filename)
    local region_key = filename:match("^blockWorld.lastsave/(%d+_%d+).region.xml$")
    local raw_key = filename:match("^blockWorld.lastsave/(%d+_%d+).raw$")
    return region_key or raw_key or ClearWorldPage.IsBaseFile[filename]
end

function ClearWorldPage.CheckIsExcludedFile(filename)
    for k, v in pairs(ClearWorldPage.ExcludedFiles) do
        if filename and filename:find(v) then
            return true
        end
    end
    return false
end

function ClearWorldPage.InitWorldBaseFiles()
    if ClearWorldPage.IsBaseFile and next(ClearWorldPage.IsBaseFile) then
        return ClearWorldPage.IsBaseFile
    end
    local baseWorldFiles = {
        {
            filename="find_history.xml",
        },
        {
            filename="tag.xml",
        },
        {
            filename="LocalNPC.xml",
        },
        {
            filename="entity.xml",
        },
        {
            filename="miniworld.template.xml",
        },
        {
            filename="stats/block_hotVal_map.xml",
        },
        {
            filename="stats/user_action_path.xml",
        },
        {
            filename="players/0.entity.xml",
        },
        {
            filename="blockWorld.lastsave/neurons.xml",
        },
        {
            filename="revision.xml",
        },
        {
            filename="blockWorld.lastsave/customblocks.xml",
        },
        {
            filename="stats/user_code_data.xml",
        },
        {
            filename="blockWorld.lastsave/blockMaterial.xml",
        },
        {
            filename="stats/user_bones_data.xml",
        },
        {
            filename="README.md",
        },
        {
            filename="mod/WorldShare.xml",
        },
        {
            filename="flat.txt",
        },
        {
            filename="NPC.db",
        },
        {
            filename="preview.jpg",
        },
        {
            filename="attribute.db",
        },
        {
            filename="worldconfig.txt",
        },
    }
    ClearWorldPage.IsBaseFile = {}
    for i, file in ipairs(baseWorldFiles) do
        ClearWorldPage.IsBaseFile[file.filename] = true
    end
end

function ClearWorldPage.CheckFileUsed(filename)
    if not filename or filename == "" then
        return false
    end
    local isUsed = false
    for file, result in pairs(ClearWorldPage.findResult) do
        if file and file ~= "" and filename:find(file) then
            isUsed = true
            break
        end
    end
    return isUsed
end

function ClearWorldPage.HandleClearDatas()
    if not ClearWorldPage.world_files or #ClearWorldPage.world_files == 0 then
        GameLogic.AddBBS(nil,L"当前世界没有需要清除的文件")
        return;
    end
    local resultDs = {}
    for i, file in ipairs(ClearWorldPage.world_files) do
        local name = file.filename
        if not ClearWorldPage.CheckFileUsed(name) then
            resultDs[#resultDs + 1] = file
        end
    end
    table.sort(resultDs, function(a, b)
        return a.filesize > b.filesize
    end)
    print("HandleClearDatas=5===============")
    ClearWorldPage.clearResult = resultDs
    if ClearWorldPage.clearSilient then
        ClearWorldPage.ClearAll()
        return
    end
    ClearWorldPage.ShowClearResult(resultDs)
end

function ClearWorldPage.ShowClearResult(resultDs)
    
    local width, height = 512, 400;
    local params = {
		url = "script/apps/Aries/Creator/Game/GUI/ClearWorldPage.html", 
		name = "ClearWorldPage.ShowPage", 
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		isShowTitleBar = false,
		cancelShowAnimation = true,
		DestroyOnClose = true, -- prevent many ViewProfile pages staying in memory
		style = CommonCtrl.WindowFrame.ContainerStyle,
		zorder = 1,
		allowDrag = true,
		enable_esc_key = true,
		directPosition = true,
			align = "_ctt",
			x = 0,
			y = 0,
			width = width,
			height = height,
	}
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function ClearWorldPage.GetDataSource()
    return ClearWorldPage.clearResult
end

function ClearWorldPage.OnClose()
    if page then
        page:CloseWindow()
        page = nil
    end
    ClearWorldPage.clearResult = nil
    ClearWorldPage.world_files = nil
    ClearWorldPage.findResult = nil
end

function ClearWorldPage.RefreshPage()
    if page then
        page:Refresh(0)
    end
end

function ClearWorldPage.ClearAll()
    if ClearWorldPage.clearResult and #ClearWorldPage.clearResult > 0 then
        for i, file in ipairs(ClearWorldPage.clearResult) do
            local worldPath = ParaIO.GetWritablePath()..ParaWorld.GetWorldDirectory()
            local filePath = worldPath .. "/" .. file.filename
            if (ParaIO.DoesFileExist(filePath)) then
                ParaIO.DeleteFile(filePath);
            end
        end
        ClearWorldPage.clearResult = nil
        ClearWorldPage.world_files = nil
        ClearWorldPage.findResult = nil
    end
end

function ClearWorldPage.OnClickDeleteFile(index)
    local fileIndex = tonumber(index)
    if fileIndex then
        local file = ClearWorldPage.clearResult[fileIndex]
        if file then
            local worldPath = ParaIO.GetWritablePath()..ParaWorld.GetWorldDirectory()
            local filePath = worldPath .. "/" .. file.filename
            if (ParaIO.DoesFileExist(filePath)) then
                ParaIO.DeleteFile(filePath);
                table.remove(ClearWorldPage.clearResult, fileIndex)
                ClearWorldPage.RefreshPage()
                GameLogic.AddBBS(nil,file.filename..","..L"文件删除成功")
            end
        end
    end
end

function ClearWorldPage.OnClickOpenFile(index)
    if System.os.GetPlatform() == "win32" then
        local fileIndex = tonumber(index)
        if fileIndex then
            local file = ClearWorldPage.clearResult[fileIndex]
            if file then
                local worldPath = ParaIO.GetWritablePath()..ParaWorld.GetWorldDirectory()
                local filePath = worldPath .. file.filename
                if (ParaIO.DoesFileExist(filePath)) then
                    local obj_path = filePath:match("^(.*)/");
                    ParaGlobal.ShellExecute("open", obj_path, "", "", 1); 
                end
            end
        end
        return
    end
    GameLogic.AddBBS(nil,L"暂不支持此操作")
end
