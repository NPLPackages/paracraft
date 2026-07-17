--[[
    author:{author}
    time:2025-09-27 16:03:30
    useLib: 
        local MiniGameEditableWorld = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameEditableWorld.lua")
        MiniGameEditableWorld.ShowEditableWebPage()
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGameMgr.lua")
local MiniGameMgr = commonlib.gettable("MyCompany.Aries.Game.Tasks.MiniGame.MiniGameMgr")
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/EasyEditableWorld.lua");
local EasyEditableWorld = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyEditableWorld");

local env
if (type(System.os.IsEmscripten) == 'function' and System.os.IsEmscripten()) then
    env = 'asIframeInWebParacraft'
else
    env = 'asWebviewInParacraftClient'
end
local base_url = string.format("https://keepwork.com/public/resource/miniGameProxy.html?projectPath=maisi/maisi/webgames/data&gameName=model_world_manager&%s=true",env)

local MiniGamePage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MiniGame/MiniGamePage.lua")
local MiniGameEditableWorld = NPL.export()

local function strip_url_params(url)
    if type(url) ~= "string" then
        return url
    end
    return url:gsub("%?.*$", "")
end

function MiniGameEditableWorld.ShowEditableWebPage()
    local userId = Mod.WorldShare.Store:Get('user/userId') or ""
    local currentTag = EasyEditableWorld.GetCurrentTag()
    local url = base_url .. "&userId=" .. userId .. "&tag=" .. currentTag
    MiniGamePage.OpenBrowser(url,function()
        
    end)
end

function MiniGameEditableWorld.CloseEditableWebPage()
    MiniGamePage.ClosePage()
end

function MiniGameEditableWorld.OnRecvMessage(msg)
    if msg and msg.type == "requestModelUrl" then
        EasyEditableWorld.UpLoadCurrentWorld(function(url,size)
            local sendMsg = {
                type = "modelUrlResponse",
                result = false
            }
            if url and size then
                local modelUrl = strip_url_params(url)
                sendMsg.modelUrl = modelUrl
                sendMsg.size = size
                sendMsg.result = true
            end
            MiniGameEditableWorld.SendMessage(sendMsg)
        end)
    elseif msg and msg.type == "loadModel" then
        local modelData = msg.modelData
        if modelData and modelData.modelUrl and modelData.modelUrl ~= "" then
            MiniGameEditableWorld.DownLoadModel(modelData)
            MiniGameEditableWorld.CloseEditableWebPage()
        end
    end
end

function MiniGameEditableWorld.GetSavedWorldPath(modeId)
    if not modeId or modeId == "" then
        return ""
    end
    local dist = ParaIO.GetWritablePath().. "temp/editableworlds_downloads/"
    local path = dist .. modeId .. ".blocks.xml"
    return path
end

function MiniGameEditableWorld.DownLoadModel(modelData)
    if modelData and modelData.modelUrl and modelData.modelUrl ~= "" then
        local tag = modelData.tag or ""
        local dest = MiniGameEditableWorld.GetSavedWorldPath(modelData.id)
        if not dest or dest == "" then
            print("=======================")
            return
        end
        NPL.load("(gl)script/ide/System/localserver/factory.lua");
        local cache_policy = System.localserver.CachePolicy:new("access plus 1 day");
        local ls = System.localserver.CreateStore();
        if(not ls) then
            log("error: failed creating local server resource store \n")
            return
        end
        ls:GetFile(cache_policy, modelData.modelUrl, function(entry)
            if(entry and entry.entry and entry.entry.url and entry.payload and entry.payload.cached_filepath) then
                ParaIO.CreateDirectory(dest);
                if(ParaIO.CopyFile(entry.payload.cached_filepath, dest, true)) then
                    LOG.std(nil, "info", "MiniGameEditableWorld", "success to copy from %s to %s", entry.payload.cached_filepath, dest);
                    GameLogic.AddBBS(nil,L"加载成功")
                    EasyEditableWorld.loadWorldFromFile(dest, modelData.subtag)
                else
                    LOG.std(nil, "warn", "MiniGameEditableWorld", "failed to copy from %s to %s", entry.payload.cached_filepath, dest);
                    GameLogic.AddBBS(nil,L"加载失败")
                end
            end
        end)
    end
end

function MiniGameEditableWorld.SendMessage(data)
    local msg = {
        type="setGameConfig", 
        data = data
    }
    MiniGameMgr:SendMessage("userEditableWorld",msg)
end