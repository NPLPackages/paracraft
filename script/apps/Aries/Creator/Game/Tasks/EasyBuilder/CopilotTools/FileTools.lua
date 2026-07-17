--[[
Title: FILE Tool Manager for EasyAIChat
Author: Paracraft Assistant
Date: 2025/01/12
Desc: Manages FILE UPLOAD OR DOWNLOAD
UseLib:
    NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/EasyBuilder/CopilotTools/FileTools.lua");
    local FileTools = commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.FileTools");
]]
local HttpWrapper = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/HttpWrapper.lua");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");

local FileTools = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Tasks.EasyBuilder.CopilotTools.FileTools"));

function FileTools.UpLoadVisionFile(filepath,callback)
    if not filepath then 
        if callback then
            callback("")
        end
        return;
    end
    local userId = Mod.WorldShare and Mod.WorldShare.Store and Mod.WorldShare.Store:Get('user/userId')
    local sUUID = System.Encoding.guid.uuid()
    local uuid = ParaMisc.md5(sUUID)
    local key = string.format("tempvision_%s_%s", userId or uuid, ParaMisc.md5(filepath))
    keepwork.shareBlock.getToken({
        router_params = {
            id = key,
        },
        bucketName = "tempvision"
    },function(err, msg, data)
		if err == 200 then
			local token = data.data.token
			local file_name = commonlib.Encoding.DefaultToUtf8(ParaIO.GetFileName(filepath));
			local file = ParaIO.open(filepath, "rb");
			if (not file:IsValid()) then
				file:close();
                if callback then
                    callback("")
                end
				return;
			end
			local content = file:GetText(0, -1);
			file:close();
			GameLogic.GetFilters():apply_filters(
				'qiniu_upload_file1',
				token,
				key,
				file_name,
				content,
				function(result, err)
                    if err ~= 200 then
                        if callback then
                            callback("")
                        end
                        return;
                    end
					local base_template_url = "https://tempvision.keepwork.com/"
					if HttpWrapper.GetDevVersion() == "STAGE" then
						base_template_url = "https://tempvision.kp-para.cn/"
					end
					local template_url = base_template_url .. key
                    if callback then
                        callback(template_url)
                    end
				end
			)
		end
    end)
end