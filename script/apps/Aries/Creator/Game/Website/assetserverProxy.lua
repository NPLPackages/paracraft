--[[
Title: asset server proxy
Author(s): LiXizhi
Date: 2021/9/8
Desc: a local proxy for asset manifest file server. Better run in a single worker thread or main thread. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Website/assetserverProxy.lua");
local assetserverProxy = commonlib.gettable("MyCompany.Aries.Game.assetserverProxy")
assetserverProxy.GetFile("texture/whitedot.png.p,dcd40f18341aba7f389ee0c7d57d02d1,94", function(localFilename, fileContent)
	echo({localFilename,  #fileContent});
end)
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/os/GetUrl.lua");
NPL.load("(gl)script/ide/timer.lua");
local ArrayMap = commonlib.gettable("commonlib.ArrayMap");
local assetserverProxy = commonlib.gettable("MyCompany.Aries.Game.assetserverProxy")

-- how many files to cache in memory. 
local maxMemoryFilesCached = 100;
local maxOverstoreCount = 20
local memcached = ArrayMap:new();
local localAssetServer = ParaAsset.GetAssetServerUrl()
local cachePath = ParaIO.GetWritablePath().."temp/assetserver/"
ParaIO.CreateDirectory(cachePath);

function assetserverProxy.SetMaxMemoryCacheFileCount(maxCount)
	maxMemoryFilesCached = maxCount;
end

function assetserverProxy.GetRemoteUrl(filename)
	return localAssetServer..filename;
end

function assetserverProxy.GetLocalFile(filename)
	return cachePath..filename;
end

function assetserverProxy.SetAssetServerUrl(url)
	if (url == localAssetServer) then return end 
	localAssetServer = url;
	ParaAsset.SetAssetServerUrl(localAssetServer);
end

function assetserverProxy.GetAssetServerUrl()
	return localAssetServer;
end

function assetserverProxy.AddToMemcache(filename, data)
	if(data) then
		memcached:push(filename, {data = data, hitTime = commonlib.TimerManager.timeGetTime()})

		if(memcached:size() > (maxMemoryFilesCached + maxOverstoreCount)) then
			memcached:valueSort(function(a, b)
				return a.hitTime >= b.hitTime 
			end)
			memcached:resize(maxMemoryFilesCached)
		end
	end
end

function assetserverProxy.GetFromMemcache(filename)
	if(filename) then
		local data = memcached[filename]
		if(data) then
			data.hitTime = commonlib.TimerManager.timeGetTime()
			return data.data;
		end
	end
end

-- it will download and cache file from local ParaAsset.GetAssetServerUrl(), and serve file from there afterwards
--@param callbackFunc: function(localFilename) end
function assetserverProxy.GetFile(filename, callbackFunc)
	if(filename and callbackFunc) then
		local filename = filename:gsub("^/", "")
		local urlPath = assetserverProxy.GetRemoteUrl(filename)
		local cacheFilename = assetserverProxy.GetLocalFile(filename)

		local data = assetserverProxy.GetFromMemcache(filename)
		if(data) then
			callbackFunc(cacheFilename, data)
			return;
		end

		if(ParaIO.DoesFileExist(cacheFilename, false)) then
			local file = ParaIO.open(cacheFilename, "r")
			local data = file:GetText(0, -1)
			file:close();
			assetserverProxy.AddToMemcache(filename, data)
			callbackFunc(cacheFilename, data)
		else
			System.os.GetUrl(urlPath, function(err, msg, data)
				if(msg.rcode == 200) then
					LOG.std(nil, "info", "assetserverProxy", "remote file saved to %s", cacheFilename);
					-- TODO: verify md5?
				
					-- save to local cache folder
					ParaIO.CreateDirectory(cacheFilename);
					local file = ParaIO.open(cacheFilename, "w")
					file:WriteString(data, #data)
					file:close();

					-- callback 
					assetserverProxy.AddToMemcache(filename, data)
					callbackFunc(cacheFilename, data)
				end
			end);
		end
	end
end