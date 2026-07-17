--[[
    Title: MallUtils
    Author(s):  pbb
    CreateDate: 2023.12.6
    Desc:
    Use Lib:
    -------------------------------------------------------
    local MallUtils = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWorkMall/MallUtils.lua");
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerSkins.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWorkMall/MallManager.lua");
local MallManager = commonlib.gettable("MyCompany.Aries.Game.KeepWorkMall.MallManager");
local PlayerSkins = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerSkins");
local PlayerAssetFile = commonlib.gettable("MyCompany.Aries.Game.EntityManager.PlayerAssetFile")
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")

local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local MallMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWorkMall/MallMainPage.lua");
local MallOtherPage = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWorkMall/MallOtherPage.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local Pinyin = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWorkMall/Pinyin.lua");
local wholeScale = 0.75;
local MallUtils = NPL.export();

function MallUtils.FormatCount(count)
    count = tonumber(count);
    if not count then
        return 0;
    end
    if  count < 9999 then
        return count;
    elseif count < 99999 then
        return string.format("%.1fK", math.floor((count/1000)*10)/10);
    elseif count < 9999999 then
        return string.format("%.1fM", math.floor((count/1000000)*10)/10);
    else
        return string.format("%.1fB", math.floor((count/1000000000)*10)/10)
    end
end

local needFilterList = {"character/CC/artwar/furnitures/motianlun.x"}
function MallUtils.IsInFilterList(filename)
    for key, value in pairs(needFilterList) do
        if tostring(filename) ==value then
            return true
        end
    end
    return false
end

function MallUtils.IsSpecialModel(item_data)
    local model_url = (item_data and item_data.modelUrl)
    return MallUtils.IsInFilterList(model_url)
end

function MallUtils.CanUseCanvas3dIcon(item_data)
    return not item_data.hasIcon or (not item_data.hasIcon and item_data.isLiveModel) or item_data.isLiveModel
end

function MallUtils.GetIcon(item_data)
    if not item_data or item_data.isLiveModel then
        return nil
    else
        local model_url = (item_data and item_data.modelUrl)
        local filename = ""
        if model_url and model_url:match("^https?://") then
            filename = item_data.tooltip
        elseif model_url and model_url:match("character/") then
            filename = model_url
        elseif item_data.id == -1 and item_data.userId == 0 then --本地目录下的
            filename = model_url
            --print("get icon==========",filename)
        else
            return nil
        end
        local filepath 
        if not GameLogic.isRemote then
            filepath = PlayerAssetFile:GetValidAssetByString(filename)
        end
        if item_data.id > 0 and item_data.userId and item_data.userId > 0 then
            filepath = nil
        end
        if (not filepath and filename) or (GameLogic.isRemote and filename) then
            if not filename:match("character/") then
                filepath = Files.GetTempPath()..filename
            else
                filepath = filename
            end
            ParaAsset.LoadParaX("", filepath):UnloadAsset();
        end
    
        local ReplaceableTextures, CCSInfoStr, CustomGeosets;
    
        local skin = nil
        if skin then
            CustomGeosets = skin
        elseif(PlayerAssetFile:IsCustomModel(filepath)) then
            CCSInfoStr = PlayerAssetFile:GetDefaultCCSString(filepath)
        elseif(PlayerSkins:CheckModelHasSkin(filepath)) then
            -- TODO:  hard code worker skin here
            ReplaceableTextures = {[2] = PlayerSkins:GetSkinByID(12)};
        end
        local iconParams = {
            AssetFile = filepath, IsCharacter=true, x=0, y=0, z=0,
            ReplaceableTextures=ReplaceableTextures, CCSInfoStr=CCSInfoStr, CustomGeosets = CustomGeosets
        }
        return iconParams
    end
end

function MallUtils.CheckHasPermission(item_data)
    if item_data and item_data.isPublic == 1 then
        return true
    else
        local UserPermission = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/UserPermission.lua");
        local enabled = UserPermission.CheckUserPermission("onlinestore")
        return enabled ~= nil and enabled or false
    end
end

function MallUtils.LoadLiveModelXml(item_data,cb,bForceLoad)
    if item_data and item_data.needDownload then
        local model_url = item_data.modelUrl
        local name = item_data.name
        if not item_data.isLiveModeland and not item_data.modelType then
            return
        end
        local base_path = "onlinestore/"
        if item_data.id > 0 and item_data.userId and item_data.userId > 0 then
            base_path = "personnalstore/"
        end
        local filename = item_data.isLiveModel and base_path..name..".blocks.xml" or  base_path..name.."."..item_data.modelType
        if model_url:match("^https?://") then
            MallUtils.LoadBlocksXmlToLocal(filename,model_url,function (data)
                if data.xmlInfo then
                    data.xmlInfo.wholeScale = wholeScale
                end
                cb(data)
            end,item_data.isLiveModel,bForceLoad)
        end
    end
end



function MallUtils.LoadBlocksXmlToLocal(filename,url,cb,isLiveModel,bForceLoad)
    local dest = ""
    if filename:match("^onlinestore/") or filename:match("^personnalstore/") then
        dest = Files.GetTempPath()..commonlib.Encoding.Utf8ToDefault(filename)
    else
        dest = Files.WorldPathToFullPath(commonlib.Encoding.Utf8ToDefault(filename))
    end
    
    local func = function ()
        if isLiveModel then
            MallUtils.ParseXml(dest,cb)
        else
            cb({tooltip = commonlib.Encoding.Utf8ToDefault(filename)})
        end
    end
    if(ParaIO.DoesFileExist(dest, true) and not bForceLoad) then
        func()
    else
        NPL.load("(gl)script/ide/System/localserver/factory.lua");
        local cache_policy = System.localserver.CachePolicy:new("access plus 1 year");
        local ls = System.localserver.CreateStore();
        if(not ls) then
            log("error: failed creating local server resource store \n")
            return
        end
        ls:GetFile(cache_policy, url, function(entry)
            if(entry and entry.entry and entry.entry.url and entry.payload and entry.payload.cached_filepath) then
                ParaIO.CreateDirectory(dest);
                if(ParaIO.CopyFile(entry.payload.cached_filepath, dest, true)) then
                    Files.NotifyNetworkFileChange(dest)
                    LOG.std(nil, "info", "CommandInstall", "success to copy from %s to %s", entry.payload.cached_filepath, dest);
                    func()
                else
                    LOG.std(nil, "warn", "CommandInstall", "failed to copy from %s to %s", entry.payload.cached_filepath, dest);
                end
            end
        end)
    end

end

function MallUtils.ParseXml(path,cb)
    local xmlRoot = ParaXML.LuaXML_ParseFile(path);
    if xmlRoot then
        local root_node = commonlib.XPath.selectNode(xmlRoot, "/pe:blocktemplate");
        if(root_node and root_node[1]) then
            local node = commonlib.XPath.selectNode(root_node, "/references");
            if(node) then
                for _, fileNode in ipairs(node) do
                    local filename = fileNode.attr.filename
                    local filepath = GameLogic.GetWorldDirectory()..commonlib.Encoding.Utf8ToDefault(filename);
                    if(not ParaIO.DoesFileExist(filepath, true)) then
                        local text = fileNode[1];
                        NPL.load("(gl)script/ide/System/Encoding/base64.lua");
                        text = System.Encoding.unbase64(text)
                        ParaIO.CreateDirectory(filepath)
                        local file = ParaIO.open(filepath, "w")
                        if(file:IsValid()) then
                            file:WriteString(text, #text);
                            file:close();
                        else
                            LOG.std(nil, "warn", "MallUtils", "failed to write file to: %s", filepath);
                        end
                    else
                        LOG.std(nil, "warn", "MallUtils", "load template ignored existing world file: %s", filename);
                    end
                end
            end
            local node = commonlib.XPath.selectNode(root_node, "/pe:entities");
            if(node) then
                local entities = NPL.LoadTableFromString(node[1])
                local liveEntities = commonlib.copy(entities)
                if(entities and #entities > 0) then
                    for _, entity in ipairs(entities) do
                        if entity.attr.linkTo == nil then
                            local _xmlInfo = entity
                            local xmlInfo = MallUtils.GetXmlNodeWithAllLinkedInfo(_xmlInfo,liveEntities)
                            cb({xmlInfo = xmlInfo})
                            break
                        end
                    end
                end
            end
        end
    end
end

function MallUtils.GetXmlNodeWithAllLinkedInfo(_xmlInfo,entities)
    local getXmlInfo
    getXmlInfo = function (xmlInfo)
        xmlInfo.linkList = {}
        for key, entity in pairs(entities) do
            if entity.attr.linkTo == xmlInfo.attr.name then
                getXmlInfo(entity)
                local result =  commonlib.split(entity.attr.linkTo,"::")
                table.insert(xmlInfo.linkList,{
                    mountIdx = nil, --如果是插件点上的点，记录是本节点的哪个插件点
                    xmlInfo = entity,
                    linkInfo = {
                        boneName = result[2],
                        pos = nil,
                        rot = nil,
                    },
                    nodeInfo = { --记录相对与本节点的位移
                        x = (entity.attr.x - xmlInfo.attr.x)*wholeScale,
                        y = (entity.attr.y - xmlInfo.attr.y)*wholeScale,
                        z = (entity.attr.z - xmlInfo.attr.z)*wholeScale,
                    }
                })
            end
        end
    end
    getXmlInfo(_xmlInfo)
    return _xmlInfo
end

function MallUtils.UseGood(goodId)
    if MallOtherPage.type == "personnal" then
        return
    end
    keepwork.mall.useGood({
        router_params = {id = goodId}
    }, function(err, msg, data)
        if err ~= 200 then
            GameLogic.AddBBS(nil,"商品使用失败，错误码是"..err)
        end
    end);
end

function MallUtils.AddUseHistroy(data)
    if MallOtherPage.type == "personnal" then
        return
    end
    MallManager.getInstance():AddMallHistory(data)
end

function MallUtils.UseGoodImp(item_data)
    local name = string.format("click.resource.%s",item_data.name)
    GameLogic.GetFilters():apply_filters("user_behavior", 1, name, {useNoId=true});

    if item_data.isLink then
        ParaGlobal.ShellExecute("open", item_data.purchaseUrl, "", "", 1); 
        return
    end

    if item_data.enabled == false then
        if item_data.vip_enabled  then
            GameLogic.IsVip("VipGoods", true, function(result)
                if result then
                    if (GameLogic.IsVip()) then
                        MallOtherPage.type = ""
                        MallMainPage.OnRefreshPage()
                    end
                end
            end)
        end
        return
    end

    if item_data.isModelProduct or item_data.vip_enabled == false then
        if not GameLogic.GameMode:IsEditor() then
            return
        end
        local model_url =  item_data.modelUrl
        local name =  item_data.name
        local fileType =  item_data.modelType
        if fileType == "cad" then
            fileType = "blocks"
        end
        local filename = item_data.name
        -- model_url = "character/CC/05effect/fire.x"
        if model_url:match("^https?://") or model_url:match("worlds/DesignHouse/") then
            NPL.load("(gl)script/apps/Aries/Desktop/GameMemoryProtector.lua");
            local GameMemoryProtector = commonlib.gettable("MyCompany.Aries.Desktop.GameMemoryProtector");
            local downloadList = GameLogic.GetPlayerController():LoadLocalData("mall_download_list",{})
            local needReload = false
            local md5 = GameMemoryProtector.hash_func_md5(item_data)
            if downloadList[name] ~= md5 then
                downloadList[name] = md5
                GameLogic.GetPlayerController():SaveLocalData("mall_download_list",downloadList)
                needReload = true
            end
            local hideinhand = false
            local hidetip = false
            if (fileType == "blocks" or fileType == "blocks.xml") then
                hideinhand = true
                hidetip = true
            end
            local eventname = "installed_model"
            if hideinhand then
                GameLogic.GetFilters():add_filter(eventname, MallUtils.OnInstalledModel);
            end
            local command = string.format("/install -event %s -hideinhand %s -hidetip %s -ext %s -reload %s -filename %s %s",eventname,
                tostring(hideinhand), tostring(hidetip), tostring(fileType), tostring(needReload), "temp/onlinestore/"..filename, model_url)

            if item_data.id == -1 and item_data.userId and item_data.userId == 0 then --本地目录下的
                command = string.format("/install -event %s -hideinhand %s -hidetip %s -ext %s -filename %s %s",eventname,
                tostring(hideinhand), tostring(hidetip), tostring(fileType), filename, model_url)
            end
            if item_data.id > 0 and item_data.userId and item_data.userId > 0 then
                command = string.format("/install -event %s -hideinhand %s -hidetip %s -ext %s -reload %s -filename %s %s",eventname,
                tostring(hideinhand), tostring(hidetip), tostring(fileType), tostring(needReload), "temp/personnalstore/"..filename, model_url)
            end
            GameLogic.RunCommand(command)
        elseif model_url:match("character/") then         
            GameLogic.RunCommand(string.format("/take BlockModel {tooltip=%q}", model_url));  
            MallOtherPage.type = ""
            MallMainPage.OnRefreshPage()
        end
        
        MallUtils.AddUseHistroy(item_data)
        
        commonlib.TimerManager.SetTimeout(function()
            local base = (not MallOtherPage.type or MallOtherPage.type ==  "") and "MallPage." or "MallOtherPage."
            local uiname = base..item_data.id..item_data.name
            local node = ParaUI.GetUIObject(uiname)
            local x, y
            if node and node:IsValid() then
                x,y = node:GetAbsPosition();
            end
            MallMainPage.CloseView()
            local good_id = item_data.id
            if good_id and good_id > 0 then
                MallUtils.UseGood(good_id)
            end
            --
            if x and y then				
                local KeepWorkSingleItem = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWorkSingleItem.lua")
                KeepWorkSingleItem.ShowNotification(item_data,{x=x,y=y})
            end
        end,200)
        return
    end
end

function MallUtils.OnClickUseGood(item_data)
    if not item_data then
        return
    end
    if not item_data.hasPermission then
        GameLogic.IsVip("VipGoods", true, function(result)
            if result then
                MallUtils.UseGoodImp(item_data)
            end
        end)
        return 
    end
    MallUtils.UseGoodImp(item_data)
end

function MallUtils.OnInstalledModel(msg)
    GameLogic.GetFilters():remove_filter("installed_model",MallUtils.OnInstalledModel);
    local filename = msg.filename
    local dir = msg.dir
    filename = filename:gsub("[.]+$","")
    local name = dir:match("[^/\\]+$")
    if dir:match("%.blocks%.xml$") then
        ParaIO.CreateDirectory(filename)
        name = name:gsub(".blocks.xml","")
        name = name:gsub("[.]+$","")
        local dest = filename.."/"..name..".blocks.xml"
        dest = commonlib.Encoding.Utf8ToDefault(dest)
        if(ParaIO.CopyFile(dir, dest, true)) then
            local xmlRoot = ParaXML.LuaXML_ParseFile(dest);
			if(xmlRoot) then
				local node = commonlib.XPath.selectNode(xmlRoot, "/pe:blocktemplate/pe:blocks");
				if(node and node[1]) then
					local blocks = NPL.LoadTableFromString(node[1]);
					if(blocks and #blocks > 0) then
                        NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/BlockTemplatePage.lua");
		                local BlockTemplatePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.BlockTemplatePage");
                        local taskfilename = filename.."/"..name..".xml"
						local bsucceed = BlockTemplatePage.CreateBuildingTaskFile(taskfilename, dest, commonlib.Encoding.DefaultToUtf8(filename), blocks)
                        if bsucceed then
                            NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/BuildQuestTask.lua");
							local task = MyCompany.Aries.Game.Tasks.BuildQuestProvider.task_class:new():Init(taskfilename);
							if(task) then
                                task:SetLoadTemplate(dest)
								MyCompany.Aries.Game.Tasks.BuildQuest:new({task=task}):Run();
							end
                        end
					end
				end
			end
        end
    end
end

function MallUtils.GetPinyin(str,isReturnStr,separator)
    return Pinyin.GetPinyin(str,isReturnStr,separator)
end




