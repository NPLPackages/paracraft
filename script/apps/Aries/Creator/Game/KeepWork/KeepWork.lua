--[[
Title: Keepwork files
Author(s): LiXizhi
Date: 2022/12/13
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWork.lua");
local KeepWork = commonlib.gettable("MyCompany.Aries.Game.GameLogic.KeepWork")
KeepWork.GetRawFile("https://keepwork.com/official/open/lessons/ParentMeeting/award_config_202212", function(err, msg, data)
	echo(data)
end, "access plus 10 seconds")
-------------------------------------------------------
]]
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.rawfile.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
local KeepWork = commonlib.gettable("MyCompany.Aries.Game.GameLogic.KeepWork")
local env = HttpWrapper.GetDevVersion()
-- @param url: such as "https://keepwork.com/official/open/lessons/ParentMeeting/award_config_202212" or "official/open/lessons/ParentMeeting/award_config_202212"
-- @param callbackFunc: function(err, msg, data) end
-- @param cache_policy: default to "access plus 10 seconds"
function KeepWork.GetRawFile(url, callbackFunc, cache_policy)
	url = url or "";
	local regStr = "^https?://keepwork.com/"
	if env == "STAGE" then
		regStr = "^https?://keepwork-dev.kp-para.cn/"
	end
	url = url:gsub(regStr, "")
	local sitePath, filePath = url:match("^/?([^/]+/[^/]+)/(.+)$");
	if(sitePath and filePath) then
		filePath = (sitePath.."/"..filePath):gsub("/" ,"%%%%2F")
		sitePath = sitePath:gsub("/" ,"%%%%2F")

		keepwork.rawfile.get({
				cache_policy =  cache_policy or "access plus 10 seconds",
				router_params = {
					repoPath = sitePath,
					filePath = filePath..".md",
				}
		}, callbackFunc);
	end
end

-- the url is https://keepwork-dev.kp-para.cn/deng123457/changelog/paracraft
-- path such as deng123457/changelog/paracraft
-- 因为上面的方法中，https://keepwork-dev.kp-para.cn/,这个链接会替换失败
function KeepWork.GetRawFileByPath(path,callbackFunc,cache_policy)
	if not path or path == "" then
		return
	end
	local sitePath, filePath = path:match("^/?([^/]+/[^/]+)/(.+)$");

	if(sitePath and filePath) then
		filePath = (sitePath.."/"..filePath):gsub("/" ,"%%%%2F")
		sitePath = sitePath:gsub("/" ,"%%%%2F")

		keepwork.rawfile.get({
				cache_policy =  cache_policy or "access plus 10 seconds",
				router_params = {
					repoPath = sitePath,
					filePath = filePath..".md",
				}
		}, callbackFunc);
	end
end
