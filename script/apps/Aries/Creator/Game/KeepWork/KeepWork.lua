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
NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/keepwork.rawfile.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/PlayerAssetFile.lua");
local KeepWork = commonlib.gettable("MyCompany.Aries.Game.GameLogic.KeepWork")

-- @param url: such as "https://keepwork.com/official/open/lessons/ParentMeeting/award_config_202212" or "official/open/lessons/ParentMeeting/award_config_202212"
-- @param callbackFunc: function(err, msg, data) end
-- @param cache_policy: default to "access plus 10 seconds"
function KeepWork.GetRawFile(url, callbackFunc, cache_policy)
	url = url or "";
	url = url:gsub("^https?://keepwork.com/", "")
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
