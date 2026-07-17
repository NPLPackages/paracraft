-- Created by pbb
-- 2019/10/24 16:30:00
-- 脚本功能：商城图片保存上传工具
--[[
    uselib:
        local MallSaveUtil = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWorkMall/MallSaveUtil.lua");
        MallSaveUtil.OnShow()

        local MallSaveUtil = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWorkMall/MallSaveUtil.lua");
        MallSaveUtil.OnShow(2,{807,814,815,808})
]]
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWorkMall/MallManager.lua");
local MallManager = commonlib.gettable("MyCompany.Aries.Game.KeepWorkMall.MallManager");
local MallUtils = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWorkMall/MallUtils.lua");

--http://yapi.kp-para.cn/project/32/interface/api/192 --管理员登录
HttpWrapper.Create("keepwork.admins.login", "%MAIN%/core/v0/admins/login", "POST", true)

local MallSaveUtil = NPL.export()
MallSaveUtil.menu_select_index = 1
MallSaveUtil.SyncModelPictureIndex = 1
MallSaveUtil.IsCanLoadNewMenu = true
local page = nil

MallSaveUtil.ids_data = {}
MallSaveUtil.cur_item_data  = {}

local http_env = HttpWrapper.GetDevVersion()
function MallSaveUtil.OnInit()
    page = document:GetPageCtrl()
end

MallSaveUtil.save_type = 1 -- 1:批量修改图片，2：修改指定id的图片

function MallSaveUtil.OnInitUser()
    if not MallSaveUtil._username or not MallSaveUtil._password then
        if http_env == "STAGE" then
            MallSaveUtil._username = "pbb"
            MallSaveUtil._password = "pbb123"
        elseif http_env == "ONLINE" then
            MallSaveUtil._username = "bingbing.peng@paracraft.cn"
            MallSaveUtil._password = "pbb1136101"
        end
    end
end

function MallSaveUtil.adminLogin(username,password,callback)
    if username==nil or password==nil then
        if System.options.isInternal then
            MallSaveUtil.OnInitUser()
            username = MallSaveUtil._username
            password = MallSaveUtil._password
        else
            GameLogic.AddBBS(nil,L"管理员用户名和密码不能为空",5000,"255 0 0")
            return
        end
        
    end
    keepwork.admins.login({
        username = username,
        password = password,
    },function(err,msg,data)
        if err~=200 then
            LOG.std(nil, "info", "MallSaveUtil", "管理员登录失败 err"..(err or "nil"));
            echo(data,true)
            GameLogic.AddBBS(nil,L"管理员登录失败",5000,"255 0 0")
            return
        end
        MallSaveUtil._token = data.token
        MallSaveUtil._username = username
        MallSaveUtil._password = password
        if callback then
            callback(true)
        end
    end)
end

function MallSaveUtil.OnShow(save_type,ids)
    MallSaveUtil.save_type = save_type
    if MallSaveUtil.save_type == 1 then
        MallManager.getInstance():LoadMallMenuList(function(data)
            MallSaveUtil.menu_data_sources = data;
            MallSaveUtil.menu_select_index = 1
            MallSaveUtil.SyncModelPictureIndex = 1
            MallSaveUtil.IsCanLoadNewMenu = true
            MallSaveUtil.ShowPage()
        end)
    else
        MallSaveUtil.SyncModelPictureIndex = 1
        MallSaveUtil.ids_data = ids
        MallSaveUtil.cur_item_data = {}
        MallSaveUtil.ShowPage()
    end
end

function MallSaveUtil.ShowPage()
    MallSaveUtil.adminLogin(nil,nil,function(isSuccess)
        if isSuccess then
            MallSaveUtil.ShowView()
        end
    end)
end

function MallSaveUtil.ShowView()
    local params = {
        url = "script/apps/Aries/Creator/Game/KeepWorkMall/MallSaveUtil.html",
        name = "MallSaveUtil.Show", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        directPosition = true,
        DesignResolutionWidth = 1280,
        DesignResolutionHeight = 720,
        cancelShowAnimation = true,
        isTopLevel = true,
        align = "_fi",
        x = 0,
        y = 0,
        width = 0,
        height = 0,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
    if MallSaveUtil.save_type == 1 then
        MallSaveUtil.LoadMallList()
    else
        MallSaveUtil.LoadGoodsInfo()
    end
end

function MallSaveUtil.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
end

function MallSaveUtil.OnClickNextMenu()
    if MallSaveUtil.save_type == 1 then
        if MallSaveUtil.IsCanLoadNewMenu then
            MallSaveUtil.menu_select_index = MallSaveUtil.menu_select_index + 1
            if MallSaveUtil.menu_select_index > #MallSaveUtil.menu_data_sources then
                MallSaveUtil.menu_select_index = #MallSaveUtil.menu_data_sources
                return
            end
            MallSaveUtil.SyncModelPictureIndex = 1
            MallSaveUtil.LoadMallList()
        end
        return
    end
    if MallSaveUtil.save_type == 2 then
        MallSaveUtil.SyncModelPictureIndex = MallSaveUtil.SyncModelPictureIndex + 1
        if MallSaveUtil.SyncModelPictureIndex > #MallSaveUtil.ids_data then
            MallSaveUtil.SyncModelPictureIndex = #MallSaveUtil.ids_data
            GameLogic.AddBBS(nil,"没有下一个了")
            return
        end
        MallSaveUtil.LoadGoodsInfo()
    end
end

function MallSaveUtil.OnClickPrevMenu()
    if MallSaveUtil.save_type == 1 then
        if MallSaveUtil.IsCanLoadNewMenu then        
            MallSaveUtil.menu_select_index = MallSaveUtil.menu_select_index - 1
            if MallSaveUtil.menu_select_index < 1 then
                MallSaveUtil.menu_select_index = 1
                return
            end
            MallSaveUtil.SyncModelPictureIndex = 1
            MallSaveUtil.LoadMallList()
        end
        return
    end
    if MallSaveUtil.save_type == 2 then
        MallSaveUtil.SyncModelPictureIndex = MallSaveUtil.SyncModelPictureIndex - 1
        if MallSaveUtil.SyncModelPictureIndex < 1 then
            MallSaveUtil.SyncModelPictureIndex = 1
            GameLogic.AddBBS(nil,"没有上一个了")
            return
        end
        MallSaveUtil.LoadGoodsInfo()
    end
end

function MallSaveUtil.LoadGoodsInfo()
    local load_index = MallSaveUtil.SyncModelPictureIndex
    local itemId = MallSaveUtil.ids_data[load_index]
    if not itemId then
        GameLogic.AddBBS(nil,"没有找到对应的商品")
        return
    end
    local base_url = http_env == "STAGE" and "http://api-dev.kp-para.cn/core/v0/admins/mProducts/" or "https://api.keepwork.com/core/v0/admins/mProducts/"
    local input = {};
    input.url = base_url..itemId;
    input.method = "POST";
    input.json=true

    local headers = input.headers or {};
    local token = MallSaveUtil._token or ""
    headers["Authorization"] = string.format("Bearer %s",token);
    input.headers = headers;

    System.os.GetUrl(input, function(err, msg, data)
        print("UpdateModelIcon===========",err)
        echo(data,true)
        if (err == 200) then
            local v = data
            v.name = commonlib.GetLimitLabel(v.name,20)
            v.useCount = tonumber(v.useCount) or 0

            v.isLink = v.method == 1  or (v.purchaseUrl ~= nil and v.purchaseUrl ~= "") --购买方式，0：内部购买；1：外部购买
            v.hasIcon = v.icon ~= "" and v.icon ~= nil

            v.isLiveModel = v.modelType == "liveModel"
            v.hasPermission = true
            v.enabled = v.hasPermission
            v.vip_enabled = not v.hasPermission
            local modelUrl = v.modelUrl or ""
            local downloadUrl = v.modelUrl or ""
            v.isModelProduct = modelUrl ~= "" and modelUrl ~= nil

            if v.isModelProduct then
                v.modelType = (v.modelType and v.modelType~= "") and v.modelType or ""
            end

            v.needDownload = (downloadUrl~= nil and downloadUrl ~= "") and not downloadUrl:match("character/") and v.modelType ~= "blocks"
            local item_data = v
            if item_data.needDownload then
                MallUtils.LoadLiveModelXml(item_data,function (data)
                    item_data.xmlInfo = data.xmlInfo
                    item_data.tooltip = data.tooltip
                    item_data.hasLoad = true
                    MallSaveUtil.cur_item_data = item_data
                    if page then
                        page:Refresh(0.02)
                        print("refresh=========",0.02)
                    end
                    print("refresh=========")
                    echo(item_data,true)
                end)
            else
                MallSaveUtil.cur_item_data = item_data
                if page then
                    page:Refresh(0.02)
                    print("refresh=========000")
                end
            end
        end
    end)
end

function MallSaveUtil.GetCurMenuName()
    if MallSaveUtil.save_type == 1 then
        local menuData = MallSaveUtil.menu_data_sources[MallSaveUtil.menu_select_index] or {}
        return menuData.name or ""
    end
    return "单个物品处理"
end

function MallSaveUtil.LoadMallList()
    MallSaveUtil.IsCanLoadNewMenu = false
    MallSaveUtil.data_hits = {}
    local menuData = MallSaveUtil.menu_data_sources[MallSaveUtil.menu_select_index] or {}
    local menuId = menuData.id
    local menuName = menuData.name  
    local sortName = "useCount"
    local sortType = "desc"
    keepwork.mall.searchGoods({
		classifyId = menuId,
		sort = sortName,
		order = sortType,
		per_page = 10000,
		page = 1,
	},function(err,msg,data)
		-- echo(data,true)
		
		print("LoadMallList=================",data.total,#data.hits)
		if err == 200 then
			if data and data.hits and next(data.hits) ~= nil then
                for i,v in ipairs(data.hits) do
                    table.insert(MallSaveUtil.data_hits,v)
                end
                MallSaveUtil.HandleDataSources()
            end
		end
	end)
end

function MallSaveUtil.HandleDataSources()
    if not MallSaveUtil.data_hits or next(MallSaveUtil.data_hits) == nil then
        return
    end
    local count = 0
    for i,v in ipairs(MallSaveUtil.data_hits) do
        v.name = commonlib.GetLimitLabel(v.name,20)
        v.useCount = tonumber(v.useCount) or 0

        v.isLink = v.method == 1  or (v.purchaseUrl ~= nil and v.purchaseUrl ~= "") --购买方式，0：内部购买；1：外部购买
        v.hasIcon = v.icon ~= "" and v.icon ~= nil

        v.isLiveModel = v.modelType == "liveModel"
        v.hasPermission = true
        v.enabled = v.hasPermission
        v.vip_enabled = not v.hasPermission
        local modelUrl = v.modelUrl or ""
        local downloadUrl = v.modelUrl or ""
        v.isModelProduct = modelUrl ~= "" and modelUrl ~= nil

        if v.isModelProduct then
            v.modelType = (v.modelType and v.modelType~= "") and v.modelType or ""
        end

        v.needDownload = (downloadUrl~= nil and downloadUrl ~= "") and not downloadUrl:match("character/") and v.modelType ~= "blocks"
        if v.needDownload then
            count = count + 1
        end
    end


    local index = 1;
    local loadCount = 0;
    local loadFunc = nil;
    loadFunc = function (item_data)
        if index > #MallSaveUtil.data_hits then
            GameLogic.AddBBS(nil,"商品数据模型下载完毕")
            MallSaveUtil.StartModelSaveStep()
            return;
        end

        index = index + 1;
        if item_data.needDownload then
            MallUtils.LoadLiveModelXml(item_data,function (data)
                item_data.xmlInfo = data.xmlInfo
                item_data.tooltip = data.tooltip
                item_data.hasLoad = true
                loadCount = loadCount + 1
                if loadCount <= 40 then
                    loadFunc(MallSaveUtil.data_hits[index])
                else
                    if page then
                        page:Refresh(0)
                    end
                    commonlib.TimerManager.SetTimeout(function ()
                        MallSaveUtil.LoadElseModel(index + 1)
                    end, 1000)
                end
                
            end)
        else
            loadFunc(MallSaveUtil.data_hits[index])
        end
    end

    loadFunc(MallSaveUtil.data_hits[index]);
end

function MallSaveUtil.LoadElseModel(index)
    local loadFunc = nil
    loadFunc = function (item_data)
        if index > #MallSaveUtil.data_hits then
            GameLogic.AddBBS(nil,"商品数据模型下载完毕")
            if page then
                page:Refresh(0)
            end
            MallSaveUtil.StartModelSaveStep()
            return
        end
        index = index + 1
        if item_data.needDownload then
            MallUtils.LoadLiveModelXml(item_data,function (data)
                item_data.xmlInfo = data.xmlInfo
                item_data.tooltip = data.tooltip
                item_data.hasLoad = true
                loadFunc(MallSaveUtil.data_hits[index])
            end)
        else
            loadFunc(MallSaveUtil.data_hits[index])
        end
    end
    loadFunc(MallSaveUtil.data_hits[index])
end

function MallSaveUtil.StartModelSaveStep(bSkip)
    local progressStr = L"正在保存模型图片"
    progressStr = progressStr.. " (".. MallSaveUtil.SyncModelPictureIndex .. "/" .. #MallSaveUtil.data_hits .. ")"
    GameLogic.AddBBS(nil,progressStr)
    if page then
        page:Refresh(0)
        print("refresh=================")
    end
    commonlib.TimerManager.SetTimeout(function ()
        MallSaveUtil.SaveModelPicture()
    end, bSkip and 100 or 1200)
end

function MallSaveUtil.UpSingleModelIcon(filename,item_data)
    if not item_data or not filename then
        MallSaveUtil.SyncModelPictureIndex = MallSaveUtil.SyncModelPictureIndex + 1
        --MallSaveUtil.StartModelSaveStep()
        return
    end
    if not ParaIO.DoesFileExist(filename) then
        GameLogic.AddBBS(nil,L"文件不存在")
        MallSaveUtil.SyncModelPictureIndex = MallSaveUtil.SyncModelPictureIndex + 1
        --MallSaveUtil.StartModelSaveStep()
        return
    end
    MallSaveUtil.UpLoadFile(item_data,filename,function(url,size)
        if url then
            local base_url = http_env == "STAGE" and "http://api-dev.kp-para.cn/core/v0/admins/mProducts/" or "https://api.keepwork.com/core/v0/admins/mProducts/"
            local separator = url:find("?")
            local iconUrl = string.sub(url, 1, separator - 1)
            local input = {};
            input.url = base_url..item_data.id;
            input.method = "PUT";
            input.json=true
            input.form = {
                newIcon = iconUrl,
            };

            local headers = input.headers or {};
            
            local token = MallSaveUtil._token or ""
            headers["Authorization"] = string.format("Bearer %s",token);
            input.headers = headers;

            System.os.GetUrl(input, function(err, msg, data)
                print("UpdateModelIcon===========",err)
                echo(data,true)
                if (err == 200) then
                    MallSaveUtil.SyncModelPictureIndex = MallSaveUtil.SyncModelPictureIndex + 1
                    MallSaveUtil.LoadGoodsInfo()
                end
            end)
        else
            GameLogic.AddBBS(nil,L"上传失败")
        end
    end)
end

function MallSaveUtil.OnClickUpdateGood()
    local item_data = MallSaveUtil.GetModelData()
    if not item_data then
        return
    end
    MallSaveUtil.SaveSingleModelPicture(item_data)
end

function MallSaveUtil.SaveSingleModelPicture(item_data)
    if not item_data or not page then
        return
    end
    local picture_dir = ParaIO.GetCurDirectory(0).."temp/mallpics/user_custom/"
    if MallSaveUtil.CanShowCanva3d() then
        local filename = picture_dir..item_data.name..".png"

        local canvaControl = page:FindControl("MallSaveUtilCanvas3D")
        if canvaControl then
            canvaControl:SaveToFile(filename, 64)
            commonlib.TimerManager.SetTimeout(function ()
                print("SaveModelPicture=",filename,item_data.name)
                MallSaveUtil.UpSingleModelIcon(filename,item_data)
            end, 200)
            -- MallSaveUtil.SyncModelPictureIndex = MallSaveUtil.SyncModelPictureIndex + 1
            -- MallSaveUtil.StartModelSaveStep()
        else
            MallSaveUtil.SyncModelPictureIndex = MallSaveUtil.SyncModelPictureIndex + 1
            MallSaveUtil.StartModelSaveStep()
        end
        
    end
end

function MallSaveUtil.SaveModelPicture()
    if not page then
        return
    end
    local menuName = MallSaveUtil.GetCurMenuName()
    local picture_dir = ParaIO.GetCurDirectory(0).."temp/mallpics/"..menuName.."/"
    if MallSaveUtil.data_hits and next(MallSaveUtil.data_hits) ~= nil then
        if MallSaveUtil.SyncModelPictureIndex > #MallSaveUtil.data_hits then
            GameLogic.AddBBS(nil,L"当前分类数据全部保存成功")
            MallSaveUtil.IsCanLoadNewMenu = true
            MallSaveUtil.OnClickNextMenu()
        else
            local item_data = MallSaveUtil.data_hits[MallSaveUtil.SyncModelPictureIndex]
            if MallSaveUtil.CanShowCanva3d() then
                local filename = picture_dir..item_data.name..".png"
                local canvaControl = page:FindControl("MallSaveUtilCanvas3D")
                if canvaControl then
                    canvaControl:SaveToFile(filename, 64)
                    commonlib.TimerManager.SetTimeout(function ()
                        print("SaveModelPicture=",filename,item_data.name)
                        MallSaveUtil.UpdateModelIcon(filename,item_data)
                    end, 200)
                    -- MallSaveUtil.SyncModelPictureIndex = MallSaveUtil.SyncModelPictureIndex + 1
                    -- MallSaveUtil.StartModelSaveStep()
                else
                    MallSaveUtil.SyncModelPictureIndex = MallSaveUtil.SyncModelPictureIndex + 1
                    MallSaveUtil.StartModelSaveStep()
                end
            else
                MallSaveUtil.SyncModelPictureIndex = MallSaveUtil.SyncModelPictureIndex + 1
                MallSaveUtil.StartModelSaveStep(true)
            end
        end
    end
end

function MallSaveUtil.CanShowCanva3d(item_data)
    local item = item_data or MallSaveUtil.GetModelData()
    if item and item.isModelProduct and item.modelType =="bmax"  then
        if MallSaveUtil.save_type == 1 then
            return (item.newIcon and item.newIcon == "")
        end
        return true
    end
    return false
end

function MallSaveUtil.GetModelData()
    if MallSaveUtil.save_type == 1 then
        if not MallSaveUtil.data_hits then
            return {}
        end
        local item_data = MallSaveUtil.data_hits[MallSaveUtil.SyncModelPictureIndex]
        return item_data
    else
        return MallSaveUtil.cur_item_data 
    end 
end

function MallSaveUtil.UpdateModelIcon(filename,item_data)
    if not item_data or not filename then
        MallSaveUtil.SyncModelPictureIndex = MallSaveUtil.SyncModelPictureIndex + 1
        MallSaveUtil.StartModelSaveStep()
        return
    end
    if not ParaIO.DoesFileExist(filename) then
        GameLogic.AddBBS(nil,L"文件不存在")
        MallSaveUtil.SyncModelPictureIndex = MallSaveUtil.SyncModelPictureIndex + 1
        MallSaveUtil.StartModelSaveStep()
        return
    end
    MallSaveUtil.UpLoadFile(item_data,filename,function(url,size)
		if url then
            local base_url = http_env == "STAGE" and "http://api-dev.kp-para.cn/core/v0/admins/mProducts/" or "https://api.keepwork.com/core/v0/admins/mProducts/"
            local separator = url:find("?")
            local iconUrl = string.sub(url, 1, separator - 1)
            local input = {};
            input.url = base_url..item_data.id;
            input.method = "PUT";
            input.json=true
            input.form = {
                newIcon = iconUrl,
            };

            local headers = input.headers or {};
            local token = MallSaveUtil._token or ""
            headers["Authorization"] = string.format("Bearer %s",token);
            input.headers = headers;

            System.os.GetUrl(input, function(err, msg, data)
                print("UpdateModelIcon===========",err)
                echo(data,true)
                if (err == 200) then
                    MallSaveUtil.SyncModelPictureIndex = MallSaveUtil.SyncModelPictureIndex + 1
                    MallSaveUtil.StartModelSaveStep()
                end
            end)
        else
            GameLogic.AddBBS(nil,L"上传失败")
        end
	end)
end

-- 个人
function MallSaveUtil.UpLoadFile(item_data,filename,callback)
    local function _cb(url,size)
        Mod.WorldShare.MsgBox:Close()
        if callback then
            callback(url,size)
        end
    end

    local file = ParaIO.open(filename, "rb");
    if (not file:IsValid()) then
        file:close();
        print("-------文件读取失败")
        GameLogic.AddBBS(nil,L"文件读取失败");
        _cb(nil)
        return;
    end
    local size = file:GetFileSize();
    if size>1*1024*1024 then
        GameLogic.AddBBS(1,"上传的文件过大,请上传1M以内的文件")
        return
    end
    local sharekey = item_data and (item_data.namePinyin..item_data.id) or "model_icon"
    Mod.WorldShare.MsgBox:Show(L'正在获取上传凭证...')
    keepwork.shareToken.get({
        cache_policy = "access plus 12 second", 
		share=sharekey,
    },function(err, msg, data)
		if err==401 or err==403 then
            print("上传图片icon失败",err)
            return
        end
        if (err ~= 200 or (not data.data) or (not data.data.token) or (not data.data.key)) then
			print("上传图片icon失败,数据异常~~~~~~~~~~",err)
            return;
        end

		if err == 200 then
			local token = data.data.token;
			local key = data.data.key;
			local file_name = commonlib.Encoding.DefaultToUtf8(ParaIO.GetFileName(filename));
			
			local content = file:GetText(0, -1);
			file:close();
            -- print("key",key)
            -- print("file_name",file_name)
            Mod.WorldShare.MsgBox:Close()
            Mod.WorldShare.MsgBox:Show(L'正在上传文件..',1000*60*10)
			GameLogic.GetFilters():apply_filters(
				'qiniu_upload_file',
				token,
				key,
				file_name,
				content,
				function(result, err)
					print("-------上传结果xxx")
                    echo(result,true)
                    if result.message~="success" then
                        print("-------上传失败")
                        GameLogic.AddBBS(nil,L"上传失败")
                        _cb(nil)
                        return;
                    end
                    Mod.WorldShare.MsgBox:Close()
                    Mod.WorldShare.MsgBox:Show(L'正在获取文件链接...')

					keepwork.shareUrl.get({cache_policy = "access plus 0", key = key}, function(err, msg, data)
						if (err ~= 200 or (not data.data)) then
							print("获取模型url失败",err)
							_cb(nil)
							return;
						end
                        echo(data,true)
						print("模型上传成功，url====",data.data)
						_cb(data.data,size)					
					end);

					keepwork.shareFile.post({key = key}, function(err, msg, data)
						LOG.std(nil, "info", "MallSaveUtil", "%s: {error: %s, data: %s}", "keepwork.shareFile", tostring(err), commonlib.serialize(data));
					end);
				end
			)
		end
        collectgarbage("collect");
    end)
end
