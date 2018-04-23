--[[
Title: File management such as file uploading
Author(s): LiXizhi
Date: 2010/2/8
Desc: file uploading
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/ParaworldAPI.lua");
-------------------------------------------------------
]]

-- create class
paraworld.file = commonlib.gettable("paraworld.file");

-----------------------------------------------------
-- file related
-----------------------------------------------------

--[[
/// <summary>
/// 用户上传文件
/// 接收参数：
///     nid  ejabbers session
///     [ name ]  用户给上传文件起的名字，若无此参数，则使用随机名
///     [ extension ] 文件后缀，如 .jpg  .gif
///     file  二进制数据的Base64字符串，若没提供from和total参数，则为全部文件内容
///     [ from ]  此次上传的数据在整个文件的二进制数组中的起始位置，当分多次上传一个文件时，若非第一次上传，则必须有from、total、filepath参数
///     total  上传文件的二进制数组的总大小，上传文件的总大小不可大于50M
///     [ ispic ]  是否是图片，如果上传的文件是图片，则会生成一个缩略图
///     [ filepath ]  逻辑路径。若未指定，则会默认为 “upload/[当前日期]/[随机文件名][后缀名]”
///     [ overwrite ]  若已存在该文件（filepath相同），是否覆盖它（即删除旧文件，保存新文件），0：否，1：是。如果为0，当已存在文件时，会返回错误码：410，默认为0
///     [ tag ]  记录和其关联的领地世界
/// 返回值：
///     issuccess
///     [ url ]  访问上传文件的URL
///     [ url2 ]  若在参数中指定了ispic，则会生成一个缩略图，这里是访问该缩略图的url
///     [ filepath ]  逻辑路径，除了首次上传，每次上传都需带上此值
///     [ size ]  已上传文件的大小
///     [ errorcode ]
/// </summary>
]]
-- we will break input file to 50KB blocks and send via web services. 
local MaxFileBlock = 1024*50;
paraworld.CreateRESTJsonWrapper("paraworld.file.UploadFile", "%FILE%/API/Upload", 
	function(self, msg, id, callbackFunc, callbackParams)
		msg.request_timeout = msg.request_timeout or 60000
		msg.nid = tonumber(msg.nid or Map3DSystem.User.nid);
		--log("UploadFile: 111111111111111111111\n")
		--commonlib.echo(msg)
	end);

-- it is similar to paraworld.map.UploadFile, except that it will automatically break a large file to blocks and send via web services. 
-- @param msg: msg.src must be a valid file path, otherwise it will default to use paraworld.map.UploadFile
-- @param callbackFunc: the callback will be called each time a block of the file is successfully sent. 
-- function(msg) {issuccess, url, url2, filepath, size, errorcode, is_finished}
function paraworld.file.UploadFileEx(msg, id, callbackFunc, callbackParams)
	if(not msg.from and msg.src) then
		-- we need to break the input file into smaller files if its file size exceed the maximum file block size.
		local filepath = msg.src;
		local from = 0;
				
		local function UploadCallBack(msg_r)
			if(msg_r and msg_r.size) then
				-- performance alert: we will open/close the file in memory, each time a block is sent. 
				-- TODO: This may have be performance problem when the file is super large such as 100MB. consider, using disk IO, instead of memory file.
				local file = ParaIO.open(filepath, "r");
				if(file:IsValid()) then
					local res;
					local total = file:GetFileSize();
					if(tonumber(msg_r.size) ~= from) then
						-- file block size mismatched, report error. 
						UploadCallBack({info = "transmission errors: "..filepath});	
						commonlib.echo(msg_r)
					elseif(from<total) then
						-- upload the next file block
						file:SetSegment(from, MaxFileBlock);
						msg.file = file;
						msg.from = from;
						msg.total = total;
						from = from + MaxFileBlock;
						if(from>total) then
							from = total;
						end
						res = paraworld.file.UploadFile(msg, id, UploadCallBack);
					else
						-- upload completed	
						msg_r.is_finished = true;
					end
					file:close();
					
					callbackFunc(msg_r, callbackParams);
					
					return res;
				else
					UploadCallBack({info = "unable to open file: "..filepath});	
					commonlib.echo(msg_r)
				end
			end
			callbackFunc(msg_r, callbackParams);
		end
		UploadCallBack({size = 0});
	else
		return paraworld.file.UploadFile(msg, id, callbackFunc, callbackParams);
	end
end

