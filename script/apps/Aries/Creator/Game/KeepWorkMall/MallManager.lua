--[[
Title: MallManager
Author(s): pbb
Date: 2023/12/4
Desc: paracraft mall manager
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWorkMall/MallManager.lua");
local MallManager = commonlib.gettable("MyCompany.Aries.Game.KeepWorkMall.MallManager");
MallManager.getInstance():Init()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWorkMall/MallApi.lua");
local MallApi = commonlib.gettable("MyCompany.Aries.Game.KeepWorkMall.MallApi");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local MallManager = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.KeepWorkMall.MallManager"));
MallManager.sync_user_model = false
local page_size = 40;
function MallManager:ctor()
	self.mall_list = {};
	self.mall_menu_list = {};
	self.mall_collection_list = {};
	self.mall_collectionId_list = {}
	self.mall_search_list = {};
	self.sync_user_model = false
end

function MallManager:Init()
	GameLogic.GetFilters():add_filter("file_exported", MallManager.filter_file_exported);
	GameLogic.GetFilters():add_filter("file_sync", MallManager.filter_file_sync);
end

function MallManager.filter_file_sync(bSync)
	MallManager.sync_user_model = bSync 
	LOG.std(nil,"info","MallManager","sync user model value is %s",tostring(bSync))
	-- print("filter_file_sync============",bSync)
	return bSync
end

function MallManager.filter_file_exported(id,filename)
	print("filter_file_exported============",id,filename)
	if MallManager.sync_user_model then
		MallManager.StartSyncModel(id,filename)
	end
	return id,filename
end

function MallManager.StartSyncModel(id,filename)
	local path = filename
	if((id == "bmax" or id == "template" or id == "x") and filename) then
		filename = Files.GetRelativePath(filename)
		filename = commonlib.Encoding.DefaultToUtf8(filename)
	elseif(id == "STL" and filename) then
		local output_file_name = filename;
		if(not commonlib.Files.IsAbsolutePath(filename)) then
			output_file_name = ParaIO.GetWritablePath()..filename;
		end
		filename = Files.GetRelativePath(filename)
		filename = commonlib.Encoding.DefaultToUtf8(filename);		
	end
	local displayName = filename:match("([^/]+)%.%w+$");
	if id == "template" then
		displayName = displayName:gsub(".blocks","")
	end
	if id == "x" then
		path = path:gsub(".xml",".x")
	end
	MallManager:SyncWorldTemplate(displayName,path,function(err,data)
		print("StartSyncModel============",err)
		echo(data)
	end)
	print("StartSyncModel==========",displayName,filename,path)
end

function MallManager:Clear()
	self.mall_list = {};
	self.mall_menu_list = {};
	self.mall_collection_list = {};
	self.mall_collectionId_list = {}
end

function MallManager.getInstance()
	if not MallManager.sInstance then
		MallManager.sInstance = MallManager:new();
	end
	
	return MallManager.sInstance;
end

function MallManager:LoadMallList(curPage,menuId,sortName,sortOrder,callbackFunc)
	local key = "mall_list_"..curPage.."_"..menuId
	if sortName and sortName ~= "" then
		key = key.."_"..sortName
	end
	if sortOrder and sortOrder ~= "" then
		key = key.."_"..sortOrder
	end
	-- print("LoadMallList==============0",key)
	-- if self.mall_list and self.mall_list[key] and next(self.mall_list[key]) ~= nil then
	-- 	if type(callbackFunc) == "function" then
	-- 		callbackFunc(self.mall_list[key],key);
	-- 	end
	-- 	return;
	-- end
	-- print("LoadMallList==============1")
	keepwork.mall.searchGoods({
		classifyId = menuId,
		sort = sortName,
		order = sortOrder,
		per_page = page_size,
		page = curPage,
	},function(err,msg,data)
		-- echo(data,true)
		
		-- print("LoadMallList=================",key,data.total,#data.hits)
		if err == 200 then
			self.mall_list[key] = data
			if type(callbackFunc) == "function" then
				callbackFunc(self.mall_list[key],key);
			end
		end
	end)
end


--搜索商城商品
-- params 
--[[
q	        否	    关键词,纯数字则根据id搜索
classifyId	否	    分类id可以不传
per_page    是	20  一页的个数
page        是	1   第几页，从1开始
modelType	否	
sort	    否	    排序字段， name、userCount、updatedAt
order	    否	    顺序：asc、desc
]]
function MallManager:SearchMallList(curPage,keyword,sortName,sortOrder,callbackFunc)
	if  not keyword or keyword == "" then
		if type(callbackFunc) == "function" then
			callbackFunc();
		end
		return
	end
	local key = "mall_search_list_"..curPage
	if keyword and keyword~="" then
		key = key.."_"..keyword
	end
	if sortName and sortName ~= "" then
		key = key.."_"..sortName
	end
	if sortOrder and sortOrder ~= "" then
		key = key.."_"..sortOrder
	end
	-- if self.mall_search_list and self.mall_search_list[key] and next(self.mall_search_list[key]) ~= nil then
	-- 	if type(callbackFunc) == "function" then
	-- 		callbackFunc(self.mall_search_list[key],key);
	-- 	end
	-- 	return;
	-- end
	local params = {
		page = curPage,
		per_page = page_size,
	}
	if keyword and keyword~="" then
		params.q = keyword;
	end
	if sortName and sortName ~= "" then
		params.sort = sortName;
	end
	if sortOrder and sortOrder ~= "" then
		params.order = sortOrder;
	end
	echo(params)
	print("MallManager===========================")
	keepwork.mall.searchGoods(params,function(err,msg,data)
		if data and next(data) ~= nil then
			self.mall_search_list[key] = data;
			if type(callbackFunc) == "function" then
				callbackFunc(self.mall_search_list[key],key);
			end
		end
	end)
end

function MallManager:GetMallList()
	return self.mall_list;
end

function MallManager:LoadMallMenuList(callbackFunc)
	if self.mall_menu_list and next(self.mall_menu_list) ~= nil then
		if type(callbackFunc) == "function" then
			callbackFunc(self.mall_menu_list);
		end
		return;
	end
	MallApi.getInstance():LoadMallMenuList(function(err,data)
		if err == 200 and type(data) == "table" then
			self.mall_menu_list = data;
			-- print("LoadMallMenuList=================")
			-- echo(data,true)
			if type(callbackFunc) == "function" then
				callbackFunc(data);
			end
			return;
		end
		if err == 401 then
			LOG.std(nil, "info", "MallManager", "LoadMallMenuList", "token is invalid");
		else
			LOG.std(nil, "info", "MallManager", "LoadMallMenuList", "err ======== %s", tostring(err));
		end
		
	end);
end

----收藏

function MallManager:LoadCollectList(curPage,sortName,sortType,keyword,callbackFunc)
	local key = "mall_collect_list_"..curPage
	if sortName and sortName ~= "" then
		key = key.."_"..sortName
	end
	if sortType and sortType ~= "" then
		key = key.."_"..sortType
	end
	if keyword and keyword ~= "" then
		key = key.."_"..keyword
	end
	
	print("key=============,key",key,sortName,sortType)
	-- if  self.mall_collection_list and self.mall_collection_list[key] and next(self.mall_collection_list[key]) ~= nil then
	-- 	if type(callbackFunc) == "function" then
	-- 		callbackFunc(self.mall_collection_list[key],key);
	-- 	end
	-- 	return;
	-- end
	MallApi.getInstance():LoadMallCollectList(curPage,sortName,sortType,keyword,function(err,data)
		if err == 200 and type(data) == "table" then
			self.mall_collection_list[key] = data or {};
			print("LoadMallCollectList=================")
			if type(callbackFunc) == "function" then
				callbackFunc(self.mall_collection_list[key],key);
			end
			return;
		end
		if err == 401 then
			LOG.std(nil, "info", "MallManager", "LoadMallCollectList", "token is invalid");
		else
			LOG.std(nil, "info", "MallManager", "LoadMallCollectList", "err ======== %s", tostring(err));
		end
	end)
end

function MallManager:LoadMallColletIdList(callbackFunc)
	if self.mall_collectionId_list and next(self.mall_collectionId_list) ~= nil then
		if type(callbackFunc) == "function" then
			callbackFunc(self.mall_collectionId_list);
		end
		return;
	end
	MallApi.getInstance():LoadMallColletIdList(function(err,data)
		if err == 200 and type(data) == "table" then
			self.mall_collectionId_list = data.ids or {};
			-- print("LoadMallColletIdList=================")
			-- echo(data,true)
			if type(callbackFunc) == "function" then
				callbackFunc(data.ids);
			end
			return;
		end
		if err == 401 then
			LOG.std(nil, "info", "MallManager", "LoadMallColletIdList", "token is invalid");
		else
			LOG.std(nil, "info", "MallManager", "LoadMallColletIdList", "err ======== %s", tostring(err));
		end
	end)
end

function MallManager:CheckIsCollected(good_id)
	local isCollect = false
	for i,v in ipairs(self.mall_collectionId_list) do
		if good_id and v == tonumber(good_id) then
			isCollect = true
			break
		end
	end
	return isCollect
end

function table.removebyvalue(tab, value)
	for i,v in ipairs(tab) do
		if v == value then
			table.remove(tab, i)
			break
		end
	end
end

function MallManager:CollectMallGood(good_id,callbackFunc)
	if not good_id then
		return
	end
	local isCollect = not self:CheckIsCollected(good_id)
	if isCollect then
		table.insert(self.mall_collectionId_list,good_id)
		MallApi.getInstance():CollectMallGoods(good_id,function(err,data)
			-- echo(data)
			if err==400 then
				if(type(data) == "string") then
					data = commonlib.Json.Decode(data) or data;
				end
				if data and data.message then
					GameLogic.AddBBS(nil,data.message,nil,"255 0 0")
				else
					GameLogic.AddBBS(nil,L"收藏失败",nil,"255 0 0")
				end
			end
			if err == 200 then
				print("collect mall goods success:",err)
			else
				print("collect mall goods failed:", err)
				--接口收藏失败，修正数值
				table.removebyvalue(self.mall_collectionId_list, good_id)
				self:RemoveFromCollection(good_id)
				if callbackFunc and type(callbackFunc) == "function" then
					callbackFunc(false)
				end
			end
		end)
	else
		table.removebyvalue(self.mall_collectionId_list, good_id)
		self:RemoveFromCollection(good_id)
		MallApi.getInstance():UnCollectMallGoods(good_id, function(data, err)
			if err == 200 then
				print("uncollect mall goods success:", err)
			else
				print("uncollect mall goods failed:", err)
				if callbackFunc and type(callbackFunc) == "function" then
					callbackFunc(false)
				end
			end
		end)
	end
end

function MallManager:RemoveFromCollection(good_id)
	local index = -1
	local key = ""
	for k,v in pairs(self.mall_collection_list) do
		local goods = v.rows 
		for j,good in pairs(goods) do
			if good.mProductId == good_id then
				index = j
				key = k
				break
			end
		end
	end
	if index > -1 and key ~= "" then
		table.remove(self.mall_collection_list[key].rows, index)
		-- self:SaveMallCollection()
	end
end

--历史
local history_key = "mall_history"
function MallManager:LoadMallHistory()
	local username = GameLogic.GetFilters():apply_filters('store_get', 'user/username') or ""
	if username ~= "" then
		history_key = "mall_history_"..username
		self.mall_history_list = GameLogic.GetPlayerController():LoadRemoteData(history_key,{})
		-- echo(self.mall_history_list,true)
		print("load========================",history_key)
	else
		self.mall_history_list = {}
	end
end

function MallManager:SaveMallHistory()
	local username = GameLogic.GetFilters():apply_filters('store_get', 'user/username') or ""
	if username ~= "" then
		history_key = "mall_history_"..username
		print("save=========================")
		-- echo(self.mall_history_list,true)
		GameLogic.GetPlayerController():SaveRemoteData(history_key,self.mall_history_list or {});
	end
end

function MallManager:AddMallHistory(data)
	if not data or next(data) == nil then
		return
	end
	if not self.mall_history_list or next(self.mall_history_list) == nil then
		self:LoadMallHistory()
	end
	
	

	local isFind,index = false,nil
	for i,v in ipairs(self.mall_history_list) do
		if v.id == data.id then
			isFind = true
			index = i
			break
		end
	end
	if isFind then
		table.remove(self.mall_history_list,index)
		table.insert(self.mall_history_list,1,data)
	else
		local historyNum = #self.mall_history_list
		if historyNum >= 20 then
			table.remove(self.mall_history_list)
		end
		table.insert(self.mall_history_list,1,data)
	end
end

function MallManager:GetMallHistory()
	if not self.mall_history_list or next(self.mall_history_list) == nil then
		self:LoadMallHistory()
	end
	return self.mall_history_list or {}
end

--搜索历史
local search_history_key = "search_mall_history"
function MallManager:LoadMallSearchHistory()
	local username = GameLogic.GetFilters():apply_filters('store_get', 'user/username') or ""
	if username ~= "" then
		search_history_key = "search_mall_history_"..username
		if not self.search_menu_history_list then
			self.search_menu_history_list = {}
		end
		self.search_menu_history_list = GameLogic.GetPlayerController():LoadRemoteData(search_history_key,{})
	else
		self.search_menu_history_list = {}
	end
end

function MallManager:SaveMallSearchHistory()
	local username = GameLogic.GetFilters():apply_filters('store_get', 'user/username') or ""
	if username ~= "" then
		search_history_key = "search_mall_history_"..username
		if not self.search_menu_history_list then
			self.search_menu_history_list = {}
		end
		GameLogic.GetPlayerController():SaveRemoteData(search_history_key,self.search_menu_history_list);
	end
end

function MallManager:AddMallSearchHistory(search_key)
	if not search_key or search_key == "" then
		return
	end
	if not self.search_menu_history_list or next(self.search_menu_history_list) == nil then
		self:LoadMallSearchHistory()
	end
	
	local is_exist = false
	local children = self.search_menu_history_list.children
	if children and next(children) ~= nil then
		is_exist = true
	end
	if is_exist then
		local num = #children
		local isFind,finIndex = false,0
		if num > 0 then
			for i = 1,num do
				if children[i].name == search_key then
					isFind = true
					finIndex = i
					break
				end
			end
		end
		if isFind then
			table.remove(children,finIndex)
		elseif num >= 10 then
			table.remove(children)
		end
		table.insert(children, 1, {
			name = search_key,
			id = os.time(),
			createdAt = os.date("%Y-%m-%d %H:%M:%S"),
			platform = 1,
			updatedAt = os.date("%Y-%m-%d %H:%M:%S"),
			tag = "",
			type = "search",
			parentId = 99999,
		})
		self.search_menu_history_list.children = children
	else
		self.search_menu_history_list = {
			iconActive = "Texture/Aries/Creator/keepwork/Mall1/search_activate_32x32_32bits.png",
			iconUnactive = "Texture/Aries/Creator/keepwork/Mall1/search_unactivate_32x32_32bits.png",
			id = 99999,
			parentId = 0,
			name = L"历史",
			tag = "",
			createdAt = os.date("%Y-%m-%d %H:%M:%S"),
			platform = 1,
			updatedAt = os.date("%Y-%m-%d %H:%M:%S"),
			children = {
				{
					name = search_key,
					id = os.time(),
					createdAt = os.date("%Y-%m-%d %H:%M:%S"),
					platform = 1,
					updatedAt = os.date("%Y-%m-%d %H:%M:%S"),
					tag = "",
					type = "search",
					parentId = 99999,
				},
			}
		}
	end
	
	self:SaveMallSearchHistory()
end

function MallManager:GetMallSearchHistory()
	if not self.search_menu_history_list or next(self.search_menu_history_list) == nil then
		self:LoadMallSearchHistory()
	end
	return self.search_menu_history_list
end

-- 个人
-- @ params maxSize mb
function MallManager:UpLoadFile(filename,callback,maxSize,key)
	local userId = GameLogic.GetFilters():apply_filters('store_get', 'user/userId');
	if not userId then
		return
	end

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
	local max_size = maxSize or 1
    if size>max_size*1024*1024 then
        GameLogic.AddBBS(1,"上传的文件过大,请上传"..max_size.."M以内的文件")
		_cb(nil)
        return
    end

    GameLogic.AddBBS("token",L'正在获取上传凭证...')
	local save_key = (key and key ~= "") and key or "upload_model"
    keepwork.shareToken.get({
        cache_policy = "access plus 12 second", 
		share= save_key,
    },function(err, msg, data)
		GameLogic.AddBBS("token",nil)
		if err==401 or err==403 then
            print("上传模型失败",err)
			_cb(nil)
            return
        end
        if (err ~= 200 or (not data.data) or (not data.data.token) or (not data.data.key)) then
			print("上传模型失败,数据异常~~~~~~~~~~",err)
			_cb(nil)
            return;
        end

		if err == 200 then
			local token = data.data.token;
			local key = data.data.key;
			local file_name = commonlib.Encoding.DefaultToUtf8(ParaIO.GetFileName(filename));
			
			local content = file:GetText(0, -1);
			file:close();

            GameLogic.AddBBS("file",L'正在上传文件..')
			GameLogic.GetFilters():apply_filters(
				'qiniu_upload_file',
				token,
				key,
				file_name,
				content,
				function(result, err)
					-- print("-------上传结果xxx")
                    -- echo(result,true)
					GameLogic.AddBBS("file",nil)
                    if result.message~="success" then
                        print("-------上传失败")
                        GameLogic.AddBBS(nil,L"上传失败")
                        _cb(nil)
                        return;
                    end
                    GameLogic.AddBBS("file",L'正在获取文件链接...')

					keepwork.shareUrl.get({cache_policy = "access plus 0", key = key}, function(err, msg, data)
						GameLogic.AddBBS("file",nil)
						if (err ~= 200 or (not data.data)) then
							print("获取模型url失败",err)
							_cb(nil)
							return;
						end
						print("模型上传成功，url====",data.data)
						_cb(data.data,size)					
					end);

					keepwork.shareFile.post({key = key}, function(err, msg, data)
						LOG.std(nil, "info", "MallManager", "%s: {error: %s, data: %s}", "keepwork.shareFile", tostring(err), commonlib.serialize(data));
					end);
				end
			)
		end
        collectgarbage("collect");
    end)
end


local modelTypes = {
	xml = "blocks",
	bmax = "bmax",
	x = "x",
	stl="stl",
}
function MallManager:SyncWorldTemplate(name,filename,callbackFunc)
	if not filename or filename == "" then
		GameLogic.AddBBS(nil,L"同步失败，文件不存在")
		return
	end
	if not ParaIO.DoesFileExist(filename) then
		GameLogic.AddBBS(nil,L"同步失败，文件不存在")
		return
	end

	local fileDir,postfix = string.match(filename,"(.+)%.(.+)$");
	local model_type = modelTypes[postfix] or "bmax"
	-- print("SyncWorldTemplate===============",model_type)
	self:UpLoadFile(filename,function(url,size)
		if url then
			-- print("add model =====",name,model_type,size,url)
			MallApi.getInstance():AddMineModel(name,model_type,size,url,function(err,data)
				if err == 200 then
					if type(callbackFunc) == "function" then
						callbackFunc(err,data);
					end
					return
				end
				if err==400 then
					if(type(data) == "string") then
						data = commonlib.Json.Decode(data) or data;
					end
					if data and data.message then
						GameLogic.AddBBS(nil,data.message,nil,"255 0 0")
					else
						GameLogic.AddBBS(nil,L"存储个人模型失败",nil,"255 0 0")
					end
				end
				if err == 401 then
					LOG.std(nil, "info", "MallManager", "SyncWorldTemplate", "token is invalid");
				else
					LOG.std(nil, "info", "MallManager", "SyncWorldTemplate", "err ======== %s", tostring(err));
				end
			end)
		else
			GameLogic.AddBBS(nil,L"同步失败，文件上传失败")
		end
	end)
end

function MallManager:UpdateModelByFile(model_data,filename,callbackFunc)
	if not filename or filename == "" then
		GameLogic.AddBBS(nil,L"替换失败，文件不存在")
		return
	end
	if not ParaIO.DoesFileExist(filename) then
		GameLogic.AddBBS(nil,L"替换失败，文件不存在")
		return
	end
	if not model_data or next(model_data) == nil then
		GameLogic.AddBBS(nil,L"替换失败，模型数据不存在")
		return
	end
	local model_id = model_data.id
	local fileDir,postfix = string.match(filename,"(.+)%.(.+)$");
	local model_type = modelTypes[postfix] or "bmax"
	self:UpLoadFile(filename,function(url,size)
		if url then
			self:UpdateModelUrl(model_id,url,function(err,data)
				if err == 200 then
					if type(callbackFunc) == "function" then
						local newData = model_data
						newData.modelUrl = url
						callbackFunc(err,newData);
					end
					return
				end
				if err==400 then
					if(type(data) == "string") then
						data = commonlib.Json.Decode(data) or data;
					end
					if data and data.message then
						GameLogic.AddBBS(nil,data.message,nil,"255 0 0")
					else
						GameLogic.AddBBS(nil,L"修改个人模型失败",nil,"255 0 0")
					end
				end
				if err == 401 then
					LOG.std(nil, "info", "MallManager", "UpdateModelByFile", "token is invalid");
				else
					LOG.std(nil, "info", "MallManager", "UpdateModelByFile", "err ======== %s", tostring(err));
				end
			end)
		else
			GameLogic.AddBBS(nil,L"替换模型失败，原因：文件上传失败")
		end
	end)
end

function MallManager:UpdateModel(model_id,name,callbackFunc)
	if not model_id or not name then
		return
	end
	if name == "" then
		GameLogic.AddBBS(nil,L"名称不能为空")
		return
	end
	MallApi.getInstance():UpdateModel(model_id,name,function(err,data)
		if err == 200 then
			GameLogic.AddBBS(nil,L"修改成功")
			echo(data,true)
			if type(callbackFunc) == "function" then
				callbackFunc(true)
			end
		else
			GameLogic.AddBBS(nil,L"修改失败")
			if type(callbackFunc) == "function" then
				callbackFunc(false)
			end
		end
	end)
end

function MallManager:UpdateModelUrl(model_id,url,callbackFunc)
	if not model_id or not url then
		return
	end
	if url == "" then
		GameLogic.AddBBS(nil,L"链接不能为空")
		return
	end
	MallApi.getInstance():UpdateModelUrl(model_id,url,function(err,data)
		if err == 200 then
			GameLogic.AddBBS(nil,L"修改成功")
			echo(data,true)
			if type(callbackFunc) == "function" then
				callbackFunc(err,data)
			end
		else
			GameLogic.AddBBS(nil,L"修改失败")
			if type(callbackFunc) == "function" then
				callbackFunc(err,data)
			end
		end
	end)
end

function MallManager:DeleteModel(model_id,callbackFunc)
	MallApi.getInstance():DeleteModel(model_id,function(err,data)
		if err == 200 then
			GameLogic.AddBBS(nil,L"删除成功")
			if type(callbackFunc) == "function" then
				callbackFunc(true)
			end
		else
			GameLogic.AddBBS(nil,L"删除失败")
			if type(callbackFunc) == "function" then
				callbackFunc(false)
			end
		end
	end)
end

function MallManager:LoadPersonalList(curpage,sortName,sortOrder,keyword,callbackFunc)
	MallApi.getInstance():LoadMineModelList(curpage,sortName,sortOrder,keyword,function(err,data)
		if err == 200 and type(data) == "table" then
			if type(callbackFunc) == "function" then
				callbackFunc(data)
			end
			return
		end
		if err == 401 then
			LOG.std(nil, "info", "MallManager", "LoadPersonalList", "token is invalid");
		else
			LOG.std(nil, "info", "MallManager", "LoadPersonalList", "err ======== %s", tostring(err));
		end
	end)
end

function MallManager:CheckUniqueName(name,callbackFunc)
	local params = {
        ["x-per-page"] = 1000,
        ["x-page"] = 1,
    }
    if name and name ~= "" then
        params.name = name
    end
	keepwork.mall.modelList(params,function(err,msg,data)
        print("err====================",err)
        if type(callbackFunc) == "function" then
            callbackFunc(err,data);
        end
    end)
end



	