-- Created by pbb
-- 2025/01/14 16:30:00
-- 脚本功能：商城图片保存上传工具
--[[
    uselib:
        local MallSaveUtil = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWorkMall/MallSaveUtilV1.lua");
        MallSaveUtil.OnShow("username","password")
]]
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWorkMall/MallManager.lua");
local MallManager = commonlib.gettable("MyCompany.Aries.Game.KeepWorkMall.MallManager");
local MallUtils = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWorkMall/MallUtils.lua");

--http://yapi.kp-para.cn/project/32/interface/api/192 --管理员登录
HttpWrapper.Create("keepwork.admins.login", "%MAIN%/core/v0/admins/login", "POST", true)

local MallSaveUtil = NPL.export()

local page = nil

MallSaveUtil.cur_item_data  = {}

local http_env = HttpWrapper.GetDevVersion()
function MallSaveUtil.OnInit()
    page = document:GetPageCtrl()
end

function MallSaveUtil.adminLogin(username,password,callback)
    if username==nil or password==nil then
        GameLogic.AddBBS(nil,L"管理员用户名和密码不能为空",5000,"255 0 0")
        return
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
        if callback then
            callback(true)
        end
    end)
end

function MallSaveUtil.OnShow(username,password)
    MallSaveUtil._username = username
    MallSaveUtil._password = password
    MallSaveUtil.cur_item_data = {}
    MallSaveUtil.ShowPage()
end

function MallSaveUtil.ShowPage()
    MallSaveUtil.adminLogin(MallSaveUtil._username,MallSaveUtil._password ,function(isSuccess)
        if isSuccess then
            MallSaveUtil.ShowView()
        end
    end)
end

function MallSaveUtil.ShowView()
    local params = {
        url = "script/apps/Aries/Creator/Game/KeepWorkMall/MallSaveUtilV1.html",
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
end

function MallSaveUtil.ClosePage()
    if page then
        page:CloseWindow()
        page = nil
    end
end

function MallSaveUtil.OnClickRefreshGood()
    MallSaveUtil.LoadGoodsInfo()
end


function MallSaveUtil.OnIdTextChange()
    if page then
        local itemId = page:GetValue("itemId")
        itemId = tonumber(itemId)
        if itemId and itemId > 0 then
            MallSaveUtil.goodId = itemId
        end
    end
end

function MallSaveUtil.OnRotateTextChange()
    if page then
        local rotY = page:GetValue("itemrotate")
        print("rotY===============",rotY)
        rotY = tonumber(rotY)
        if rotY and rotY >= -1.57 and rotY <= 1.57 then
            MallSaveUtil.defaultRotY = rotY
        end
    end
end

function MallSaveUtil.OnDistTextChange()
    if page then
        local distance = page:GetValue("itemdist")
        print("distance==============",distance)
        distance = tonumber(distance)
        if distance and distance > 0 and distance <= 10 then
            MallSaveUtil.defaultCameraObjectDist = distance
        end
    end
end

function MallSaveUtil.LoadGoodsInfo()
    if not page then
        return
    end
    if not MallSaveUtil.goodId or MallSaveUtil.goodId == 0 then
        GameLogic.AddBBS(nil,"没有找到对应的商品")
        return
    end
    local itemId = MallSaveUtil.goodId
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
                    MallSaveUtil.ReOpenPage()
                end)
            else
                MallSaveUtil.cur_item_data = item_data
                MallSaveUtil.ReOpenPage()
            end
        end
    end)
end

function MallSaveUtil.ReOpenPage()
    if not page then
        return
    end
    MallSaveUtil.ClosePage()
    MallSaveUtil.ShowView()
end

function MallSaveUtil.GetGoodId()
    if not MallSaveUtil.goodId then
        return ""
    end
    return tostring(MallSaveUtil.goodId) or ""
end

function MallSaveUtil.GetDefaultRotY()
    if not MallSaveUtil.defaultRotY then
        return -0.785
    end
    return MallSaveUtil.defaultRotY
end

function MallSaveUtil.GetDefaultCameraObjectDist()
    if not MallSaveUtil.defaultCameraObjectDist then
        return 3.0
    end
    return MallSaveUtil.defaultCameraObjectDist
end

function MallSaveUtil.UpSingleModelIcon(filename,item_data)
    if not item_data or not filename then
        return
    end
    if not ParaIO.DoesFileExist(filename) then
        GameLogic.AddBBS(nil,L"文件不存在")
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
                    GameLogic.AddBBS(nil,L"更新图片成功")
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
        end
        
    end
end

function MallSaveUtil.CanShowCanva3d(item_data)
    local item = item_data or MallSaveUtil.GetModelData()
    if item and item.isModelProduct and item.modelType =="bmax"  then
        return true
    end
    return false
end

function MallSaveUtil.GetModelData()
    return MallSaveUtil.cur_item_data
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
