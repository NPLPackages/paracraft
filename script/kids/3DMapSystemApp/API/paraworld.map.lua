--[[
Title: a central place per application for selling and buying tradable items. 
Author(s): LiXizhi, CYF
Date: 2008/1/21
Desc: file, world, map(obsoleted API)
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/API/ParaworldAPI.lua");
-------------------------------------------------------
]]

-- create class
commonlib.setfield("paraworld.map", {});

-----------------------------------------------------
-- file related
-----------------------------------------------------

--[[
	/// <summary>
	/// 上传文件
	/// 每次上传操作最多只能上传不大于1M的文件，对于大于1M的文件，需要分成多次进行上传。
	/// 对于图像图片的上传（即需要生成缩略图的用户图像），总文件大小不能大于1M
	/// 若要将一个文件分成多次进行上传，则必须提供totalbyte参数，并且值必须大于0，第一次上传成功后会返回一个filepath节点（若在第一次上传时提供了filepath参数，则此返回值即提供的filepath参数），在其后的每次上传中都必须提供此参数。
	/// 若 frombyte == 0 && frombyte + 当前上传数据的二进制数组的长度 == totalbyte，则会将此次上传操作视为非分批上传，即将一个文件一次性上传完成。
	/// </summary>
	/// <param name="msg">
	///		msg = {
	///			sessionkey : string (*) 用户凭证
	///			file : string (*) 文件的Base64表示形式中的一段或全部，若没提供frombyte和totalbyte参数，则为全部
	///			frombyte : long 此次上传的数据在整个文件的二进制数组中的起始位置，当分多次上传一个文件时，若非第一次上传，则必须有frombyte、totalbyte、filepath参数
	///			totalbyte : long 上传文件的二进制数组的总大小，如果isphoto==true，则totalbyte不可大于1024*1024
	///			extension : string  文件的后缀名，如（.jpg .txt 等，若未提供，则从参数filepath中获取，若extension和filepath都没有值，则没有后缀名）
	///			isphoto: boolean  是否是头像图片，如果是，则会生成一个原图（原图最大宽度若大于256，则会适度缩小）和一个小图，默认值为false
	///			filepath: string 逻辑路径。若未指定，则会默认为 “upload/[当前日期]/[随机文件名][后缀名]”0：否，1：是
	///			overwrite : int 若指定的指定的物理路径已存在文件，是否覆盖它（即删除旧文件，保存新文件），0：否，1：是。如果为0，当指定物理路径中已存在文件时，会返回错误码：410
	///		}
	/// </param>
	/// <returns>
	/// msg = {
	///		fileURL = string,
	///		filepath = stirng,
	///		fileSize = long 已上传文件的大小
	///		[ fileURL_Small ] = string, 如果上传的是头像图片，则返回值中有此数据
	///		fileCrc32 = string
	///		[ errorcode ] (int)  错误码。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  497：数据不存在或已被删除   496：未登录      （更多errorcode见WIKI）
	///		[ info ] = string
	/// } 
	///</returns>
]]
-- we will break input file to 100KB blocks and send via web services. 
local MaxFileBlock = 1024*100;
paraworld.CreateRESTJsonWrapper("paraworld.map.UploadFile", "%FILE%/UploadFile.ashx", 
	function(self, msg, id, callbackFunc, callbackParams)
		msg.request_timeout = msg.request_timeout or 60000
		return paraworld.prepLoginRequried(self, msg, id, callbackFunc, callbackParams)
	end);

-- it is similar to paraworld.map.UploadFile, except that it will automatically break a large file to blocks and send via web services. 
-- @param msg: msg.src must be a valid file path, otherwise it will default to use paraworld.map.UploadFile
-- @param callbackFunc: the callback will be called each time a block of the file is successfully sent. 
function paraworld.map.UploadFileEx(msg, id, callbackFunc, callbackParams)
	if(not msg.frombyte and msg.src) then
		-- we need to break the input file into smaller files if its file size exceed the maximum file block size.
		local filepath = msg.src;
		local frombyte = 0;
		
		local function UploadCallBack(msg_r)
			callbackFunc(msg_r, callbackParams);
			if(msg_r and msg_r.fileSize) then
				-- performance alert: we will open/close the file in memory, each time a block is sent. 
				-- TODO: This may have be performance problem when the file is super large such as 100MB. consider, using disk IO, instead of memory file.
				local file = ParaIO.open(filepath, "r");
				if(file:IsValid()) then
					local res;
					local totalbyte = file:GetFileSize();
					if(tonumber(msg_r.fileSize) ~= frombyte) then
						-- file block size mismatched, report error. 
						UploadCallBack({info = "transmission errors: "..filepath});	
					elseif(frombyte<totalbyte) then
						-- upload the next file block
						file:SetSegment(frombyte, MaxFileBlock);
						msg.file = file;
						msg.frombyte = frombyte;
						msg.totalbyte = totalbyte;
						frombyte = frombyte + MaxFileBlock;
						if(frombyte>totalbyte) then
							frombyte = totalbyte;
						end
						res = paraworld.map.UploadFile(msg, id, UploadCallBack);
					else
						-- upload completed	
					end
					file:close();
					return res;
				else
					UploadCallBack({info = "unable to open file: "..filepath});	
				end	
			end
		end
		UploadCallBack({fileSize = 0});
	else
		return paraworld.map.UploadFile(msg, id, callbackFunc, callbackParams);
	end
end

--[[
	/// <summary>
	/// 删除一个用户文件
	/// </summary>
	/// <param name="msg">
	/// msg = {
	///		sessionkey = string (*) 用户凭证
	///		filepath = string (*) 需要被删除的文件的逻辑路径
	/// }
	/// </param>
	/// <returns>
	/// msg = {
	///		issuccess = boolean  删除文件操作是否成功
	///		[ errorcode ] = int (当发生异常时会有此节点，0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  497：数据不存在或已被删除   496：未登录)
	/// }
	/// </returns>
]]
paraworld.CreateRESTJsonWrapper("paraworld.file.DeleteFile", "%FILE%/Delete.ashx", paraworld.prepLoginRequried);


--[[
	/// <summary>
	/// 依据文件ID或文件逻辑地址取得一个用户文件的数据
	/// </summary>
	/// <param name="msg">
	/// msg = {
	///		sessionkey = string (*) 用户凭证
	///		[ filepath ] = string 文件的逻辑地址，filepath和fileID中必须有一个有值
	///		[ fileID ] = int 文件ID，filepath和fileID中必须有一个有值
	///		[ ownerUID ] = string 文件所有者的用户ID，若不传此参数，则指当前用户
	/// }
	/// </param>
	/// <returns>
	/// msg = {
	///		id（用户文件的ID）
	///		fileURL（文件的URL地址）
	///		filepath（文件的物理地址）
	///		createDate（文件的创建时间）
	///		uid（用户ID）
	///		[ errorcode ] = int (当发生异常时会有此节点，0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  497：数据不存在或已被删除   496：未登录)
	/// }
	/// </returns>
]]
paraworld.CreateRESTJsonWrapper("paraworld.file.GetFile", "%FILE%/Get.ashx", paraworld.prepLoginRequried);


--[[
	/// <summary>
	/// 修改指定文件的文件名（逻辑地址）
	/// </summary>
	/// <param name="msg">
	/// msg = {
	///		sessionkey = string (*) 用户凭证
	///		filepath = string (*) 需要修改的文件的逻辑地址
	///		newFilePath = string (*) 新的逻辑地址
	/// }
	/// </param>
	/// <returns>
	/// msg = {
	///		issuccess = boolean  删除操作是否成功
	///		[ errorcode ] = int (当发生异常时会有此节点，0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  497：数据不存在或已被删除   496：未登录)
	/// }
	/// </returns>
]]
paraworld.CreateRESTJsonWrapper("paraworld.file.RenameFile", "%FILE%/Rename.ashx", paraworld.prepLoginRequried);



--[[
	/// <summary>
	/// 创建用户文件。
	/// </summary>
	/// <param name="msg">
	/// msg = {
	///		sessionkey = string (*) 用户凭证
	///		fileUrl = string (*) 该文件所在的URL地址
	///		filepath = string (*) 该文件所在的逻辑地址
	///		overwrite = int 若指定目录中已存在同名的文件，是否用新的文件覆盖旧的文件。0：否，1：是。如果为否，当存在同名文件时，创建文件的操作将会失败，并返回410错误
	/// }
	/// </param>
	/// <returns>
	/// msg = {
	///		issuccess = boolean  创建文件操作是否成功
	///		[ errorcode ] = int (当发生异常时会有此节点，0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  497：数据不存在或已被删除   496：未登录  409：该位置已存在同名的文件夹	410：该位置已存在同名的文件)
	/// }
	/// </returns>
]]
paraworld.CreateRESTJsonWrapper("paraworld.file.CreateFile", "%FILE%/Create.ashx", paraworld.prepLoginRequried);



--[[
	/// <summary>
	/// 依据指定的逻辑地址查找用户文件
	/// </summary>
	/// <param name="msg">
	/// msg = {
	///		sessionkey = string (*) 用户凭证
	///		filepath = string (*) 需要查找的文件的逻辑地址，可带通配符（?:单个任意字符;*:多个任意字符）
	///     [ ownerUID ] = string 文件所有者的用户ID，若不传此参数，则指当前用户
	/// }
	/// </param>
	/// <returns>
	/// msg = {
	///		files[list] = {
	///			id（用户文件的ID）
	///			fileURL（文件的URL地址）
	///			filepath（文件的物理地址）
	///			createDate（文件的创建时间）
	///			uid（用户ID）
	///		}
	///		[ errorcode ] = int (当发生异常时会有此节点，0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  497：数据不存在或已被删除   496：未登录)
	/// }
	/// </returns>
]]
paraworld.CreateRESTJsonWrapper("paraworld.file.FindFile", "%FILE%/Find.ashx", paraworld.prepLoginRequried);


-----------------------------------------------------
-- map related
-----------------------------------------------------
-- Return a given official 2D map mcml. Official map is just map of a given admin user, using ParaWorld.Map.getUserMap. It only returns an xml file path instead of the xml content.
paraworld.CreateRPCWrapper("paraworld.map.OfficialMap", "http://map.paraengine.com/OfficialMap.asmx");

-- Get/set the 2D map mcml of a given user
-- It only get/set an xml file path instead of the xml content.
paraworld.CreateRPCWrapper("paraworld.map.UserMap", "http://map.paraengine.com/UserMap.asmx");

---------------------------------------------------------------------------------------
----------------------------for tile manipulate----------------------------------------
---------------------------------------------------------------------------------------
--[[
    /// <summary>
    /// 取得一个区域内所有的Tile
    /// </summary>
    /// <param name="msg">
    /// msg = {
	///	    "x" = double,
	///	    "y" = double,
	///	    "width" = double,
	///	    "height" = double
    ///    }
    /// </param>
    /// <returns>
    ///     "resultCount" = int,
    ///     tiles = [list]
    ///     {
    ///         <param>
	///			    checkChangeL(long)  时间戳，用来判断数据是否已有改变
    ///             id(int)		tileID
	///             tileName (string)  Tile的名称
    ///             x(double)		坐标x
    ///             y(double)		坐标y
	///				z(double)       坐标z
	///				ownerUID(string) 所有者用户ID
	///				ownerUName(string) 所有者用户名
	///				useUID (string) 使用者用户ID
	///				useUName (string) 使用者用户名
    ///             terrainStyle(int)		土地样式
    ///             tileType(int)		土地类型
    ///             models(string)		十六格中的模型ID
	///				texture (string)  地形纹理
	///				rotation (double)  土地旋转角度
    ///         </param>
    ///     }
	///		[ errorcode ] (int)  错误码。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  497：数据不存在或已被删除   496：未登录
    /// </returns>
]]
--paraworld.CreateRPCWrapper("paraworld.map.GetTilesInRegion", "http://map.paraengine.com/GetTilesInRegion.asmx");
paraworld.CreateRPCWrapper("paraworld.map.GetTilesInRegion", "%MAP%/GetTilesInRegion.asmx");

--[[
	/// <summary>
	/// 新增一个Tile
	/// </summary>
	/// <param name="msg">
	///     msg = {
	///	        "sessionkey" = string (*)
	///	        "x" = double, (*)
	///	        "y" = double, (*)
	///			"z" = double, (*)
	///         "tileType" = int,
	///	        "terrainType" = int,
	///			"texture" = string,
	///			"rotation" = double,
	///	        "price" = decimal,
	///         "price2" = decimal,
	///         "price2StartTime" = datetime,
	///         "price2EndTime" = datetime,
	///	        "rentPrice" = decimal,
	///	        "ranking" = int,
	///         "logo" = string,
	///	        "models" = string,
	///	        "cityName" = string,
	///         "ageGroup" = int
	///         "allowEdit" = boolean
	///     }
	/// </param>
	/// <returns>
	///     msg =
	///     {
	///         isSucceed(boolean) 操作是否成功完成
	///			errorcode = int //错误码。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  497：数据不存在或已被删除   496：未登录
	///         info = [ optional ] 注释、说明信息
	///     }
	/// </returns>
]]
paraworld.CreateRPCWrapper("paraworld.map.AddTile", "%MAP%/AddTile.asmx");


--[[
	/// <summary>
	/// 依据Tile的ID取得一个Tile的信息
	/// </summary>
	/// <param name="msg">
	/// if(operation = "get")
	///     msg = {
	///         "tileID" = int,
	///    }
	/// </param>
	/// <returns>
	/// if operation = "get"
	///     msg = 
	///     {
	///         tileID(int)	tileID
	///         tileName (string) Tile的名称
	///         x(int)	坐标x
	///         y(int)	坐标y
	///         ownerUID(Guid,用string代替)	拥有者ID
	///			ownerUName (拥有者的用户名)
	///			useUID (string) 使用者的用户ID
	///			useUName(string) 使用者的用户名
	///         terrainStyle(int)	土地样式
	///         tileType(int)		土地类型
	///         price(decimal)	价格
	///         rentPrice(decimal)	月租
	///         rank(int)	级别
	///         models(string)		十六格中的模型ID
	///         cityName(string)	城市名称
	///         community(string)	社团 
	///         ageGroup(int)	ESRP级别： 
	///			[ errorcode ] (int)  错误码。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  497：数据不存在或已被删除   496：未登录
	///     }
	/// </returns>
]]
--TODO:uncomment this line
local tile_get_cache_policy = System.localserver.CachePolicy:new("access plus 1 day");
--local tile_get_cache_policy = System.localserver.CachePolicy:new("access plus 0");
paraworld.CreateRPCWrapper("paraworld.map.GetTileByID", "%MAP%/GetTileByID.asmx",
function(self,msg,id,callbackFunc,callbackParams)
	msg.sessionkey = msg.sessionkey or Map3DSystem.User.sessionkey;
	--local cache_policy = msg.cache_policy or tile_get_cache_policy;
	local cache_policy = tile_get_cache_policy;
	if(type(cache_policy)=="string")then
		cache_policy = Map3DSyste.localserver.CachePolicy:new(cache_policy);
		
	end
	if(cache_policy:IsCacheEnabled())then
		local ls = System.localserver.CreateStore(nil,2);
		if(ls)then
			ls:CallWebserviceEx(cache_policy,self.GetUrl(),msg,{"tileID"},
				callbackFunc,callbackParams);
		else
			log("error: unable to open default local server store \n");
		end
		return true;
	end
end)

	
	
--[[
	/// <summary>
	/// 修改指定的Tile
	/// </summary>
	/// <param name="msg">
	///     msg = {
	///	        "sessionkey" = string (*)
	///	        "tileID" = int,  (*)
	///			"tileName" = string //（2008年5月30日）新增
	///	        "x" = double,//（2008年5月30日）废弃
	///	        "y" = double,//（2008年5月30日）废弃
	///			"z" = double,
	///	        "ownerUserID" = GUID,用string代替,
	///         "tileType" = int,
	///	        "terrainType" = int,
	///			"texture" = string,
	///			"rotation" = double,
	///	        "price" = decimal,
	///	        "rentPrice" = decimal,
	///	        "ranking" = int,
	///	        "models" = string,
	///	        "cityName" = string,
	///         "ageGroup" = int
	///	        "communityID" = int,
	///     }
	/// </param>
	/// <returns>
	///     msg = 
	///     {
	///         isSucceed(boolean) 操作是否成功完成
	///			[ errorcode ] (int)  错误码。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  497：数据不存在或已被删除   496：未登录
	///         info = [ optional ] 注释、说明信息
	///     }
	/// </returns>
]]
paraworld.CreateRPCWrapper("paraworld.map.UpdateTile", "%MAP%/UpdateTile.asmx");


--[[
	/// <summary>
	/// 购买Tile
	/// </summary>
	/// <param name="msg">
	///     msg = {
	///	        "sessionkey" = string (*)
	///			"id" = int,
	///	        "x" = double, (*)
	///	        "y" = double, (*)
	///			"z" = double,
	///	        "terrainType" = int,
	///			"texture" = string
	///     }
	/// </param>
	/// <returns>
	///     msg =
	///     {
	///         issuccess(boolean) 操作是否成功完成
	///			tileID (int) //当前Tile的ID
	///			errorcode = int //错误码。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  497：数据不存在或已被删除   496：未登录
	///     }
	/// </returns>
]]
paraworld.CreateRPCWrapper("paraworld.map.BuyTile", "%MAP%/BuyTile.asmx");

------------------------------------------------------------------------
-----------------------for mark manipulate------------------------------
------------------------------------------------------------------------
--[[
    /// <summary>
    /// 取得某用户的某种类型的MapMark中某一页的数据
    /// </summary>
    /// <param name="msg">
    /// if(operation = "get")
    ///     msg = {
    ///         ownerUserID = Guid,(*) (用string代替)
    ///         markType = int, (*) Mark类型，若为0，则不计
    ///         pagesize int, (*) 每页的数量
    ///         pageindex int, (*) 第几页，从0开始计
    ///     }
    /// </param>
    /// <returns>
    ///if(operation = "get") 
    /// {
    ///     msg =
    ///     {
    ///         pagecount int, //共有多少页
    ///         marks[list]
    ///         {
    ///             <param>
    ///                 markID(int)		标记ID
    ///                 markType(int)		标记类型
    ///                 markTitle(string)		标记名称
    ///                 markStyle(int)		标记样式
    ///                 x(double)		x坐标
    ///                 y(double)		y坐标
    ///                 isApproved(boolean)		是否通过审核
    ///             </param>
    ///         }
	///			[ errorcode ] (int)  错误码。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  497：数据不存在或已被删除   496：未登录
    ///     }
    /// }
    ///</returns>
]]
paraworld.CreateRPCWrapper("paraworld.map.GetMapMarkOfPage", "%MAP%/GetMapMarkOfPage.asmx");

--[[
    /// <summary>
    /// 返回指定区域内指定类型,指定数量的map mark,按标记等级从高到底排序
    /// </summary>
    /// <param name="msg">
    /// msg = {
	///	“operation” =[“get”],
    ///	“x” = double, (*) 起始坐标的X坐标
    ///	“y” = double, (*) 起始坐标的Y坐标
    ///	“width”=double, (*) 建议小于一个Block的宽度
    ///	“height”=double, (*) 建议小于一个Block的高度
    ///	“markType”= int,要取得的标记的类型，若为0,则返回所有类型的标记
    ///	“markNum”= int,要取得的标记的数量，若为0,则返回当前区域内所有标记
    ///	“isApproved” = boolean,标记是否通过审核，若为null，则返回所有
	///	}
    /// </param>
    /// <returns>
    /// if operation = "get"
    ///     msg = {
    ///         “resultCount” = int，返回的数据量
    ///         "marks"[list]:
    ///             <param>
    ///                 markID(int)		标记ID
    ///                 markType(int)		标记类型
    ///                 markTitle(string)		标记名称
    ///                 markStyle(int)		标记样式
    ///                 x(double)		x坐标
    ///                 y(double)		y坐标
    ///                 isApproved(boolean)		是否通过审核
	///					checkChangeL(long)   时间戳，用来判断数据是否已改变
    ///             </param>
    ///     }
    /// </returns>
]]
paraworld.CreateRPCWrapper("paraworld.map.GetMapMarksInRegion", "%MAP%/GetMapMarksInRegion.asmx");

--[[
	/// <summary>
	/// 新增一个MapMark
	/// </summary>
	/// <param name="msg">
	///     msg = {
	///	        "sessionkey" = string, (*)
	///	        "markType" = int, (*)
	///	        "markStyle" = int, (*)
	///	        "markTitle" = string, (*)
	///	        "startTime" = dateTime, (*)
	///	        "endTime" = dateTime,
	///	        "x" = double, (*)
	///	        "y" = double, (*)
	///	        "cityName" = string,
	///	        "rank" = int, (*)
	///	        "logo" = string, 
	///	        "signature" = string,
	///	        "desc" = string,
	///	        "ageGroup" = int, (*)
	///	        "isApproved" = boolean,
	///	        "version" = string,
	///         "ownerUserID" = GUID，用string代替,
	///	        "allowEdit" = boolean
	///     }
	/// </param>
	/// <returns>
	///     msg = 
	///     {
	///         isSucceed(boolean) 操作是否成功完成
	///         info = [optional] 注释、说明信息
	///     }
	/// </returns>
]]
paraworld.CreateRPCWrapper("paraworld.map.AddMapMark", "%MAP%/AddMapMark.asmx");

--[[
	/// <summary>
	/// 更新一个MapMark
	/// </summary>
	/// <param name="msg">
	///     msg = {
	///	        "sessionkey" = string, (*)
	///	        "markID" = int, (*)
	///	        "markType" = int,
	///	        "markStyle" = int,
	///	        "markTitle" = string,
	///	        "startTime" = dateTime,
	///	        "endTime" = dateTime,
	///	        "x" = double,
	///	        "y" = double,
	///	        "cityName" = string,
	///	        "rank" = int,
	///	        "logo" = string,
	///	        "signature" = string,
	///	        "desc" = string,
	///	        "ageGroup" = int,
	///	        "isApproved" = boolean,
	///	        "version" = string,
	///         "ownerUserID" = GUID，用string代替,
	///	        "clickCnt" = int,
	///         "worldid" = int,
	///	        "allowEdit" = boolean,
	///     }
	/// </param>
	/// <returns>
	///     msg = 
	///     {
	///         isSucceed(boolean) 操作是否成功完成
	///         info = [ optional ] 注释、说明信息
	///     }
	/// </returns>
]]
paraworld.CreateRPCWrapper("paraworld.map.UpdateMapMark", "%MAP%/UpdateMapMark.asmx");

--[[
	/// <summary>
	/// 依据ID取得一个MapMark
	/// </summary>
	/// <param name="msg">
	///     msg = {
	///         "markID" = int (*)
	///    }
	/// </param>
	/// <returns>
	///     msg = 
	///     {
	///         markID(int)		标记ID
	///         markType(int)		标记类型
	///         markTitle(string)		标记名称
	///         markStyle(int)		标记样式
	///         startTime(dateTime)		标记持续时间
	///         endTime(dateTime)		标记结束时间
	///         x(double)		x坐标
	///         y(double)		y坐标
	///         cityName(string)		所属城市名称
	///         rank(int)		标记等级
	///         logo(String)		玩家头像
	///         signature(string)		玩家签名
	///         desc(string)		详细描述信息
	///         ageGroup(int)		ESRP级别
	///         worldid(int)    标记所属的世界的ID		
	///         isApproved(boolean)		是否通过审核
	///         version(string)		支持的引擎版本
	///         clickCnt(int)		点击数
	///         ownerUserID(Guid,用string代替)		所有者ID
	///         url(string)  若MarkType为1(玩家标记),则为玩家的世界地址; 若MarkType为2(事件标记),则为事件的地址;若MarkType为3(城市标记),则无意义;若MarkType为4(广告标记),则代表广告的一个超链接
	///     }
	/// </returns>
]]
paraworld.CreateRPCWrapper("paraworld.map.GetMapMarkByID", "%MAP%/GetMapMarkByID.asmx");

--[[
	/// <summary>
	/// 删除一个MapMark
	/// </summary>
	/// <param name="msg">
	///     msg = {
	///			"sessionkey" = string, (*)
	///         "markID" = int (*)
	/// }
	/// </param>
	/// <returns>
	///     msg =
	///     {
	///         isSucceed(boolean) 操作是否成功完成
	///         info = [optional] 注释、说明信息
	///     }
	/// </returns>
]]
paraworld.CreateRPCWrapper("paraworld.map.RemoveMapMark", "%MAP%/RemoveMapMark.asmx");

--[[
    /// <summary>
    /// 返回符合或包含关键字的第N页的map mark, 按标记等级从高到底排序
    /// </summary>
    /// <param name="msg">
    /// msg = {
	///		"keywords" = string, (*)
    ///		"type" = string,要搜索的标记的类型（MarkTilte，Desc），默认为“MarkTitle”
    ///		"pageindex" = int, 第几页的数据，默认为1
	///		"pageNum" = int,   每页多少条数据，默认为10
	///		"isApproved" = boolean  是否经过审核，默认为false
    ///	}
    /// </param>
    /// <returns>
    /// if operation = "get"
    ///     msg = {
    ///         "resultCount" = int,
    ///         "totalResult" = int,
    ///         "marks"[list]:
    ///             <param>
    ///                 markID(int)		标记ID
    ///                 markType(int)		标记类型
    ///                 markTitle(string)		标记名称
    ///                 markStyle(int)		标记样式
    ///                 x(double)		x坐标
    ///                 y(double)		y坐标
    ///                 isApproved(boolean)		是否通过审核
	///					checkChangeL(double)  时间戳，用来判断数据是否已改变
    ///             </param>
	///			[info] 说明信息。若不能成功搜索数据，此节点描述原因。若能成功搜索，则不会有此节点
    ///     }
    /// </returns>
]]
paraworld.CreateRPCWrapper("paraworld.map.SearchMapMark", "%MAP%/SearchMapMark.asmx");


-----------------------for model manipulate-------------------------------
--[[
    /// <summary>
    /// 依据一组MapModel的ID取出这些MapModel的相关信息
    /// </summary>
    /// <param name="msg">
    /// msg = {
    ///    “operation” =[“get”],
    ///     "modelIDs"[list]
    ///         {
    ///             <modelID></modelID>
    ///             <modelID></modelID>
    ///             <modelID></modelID>
    ///             ........................
    ///         }
    ///    }
    /// </param>
    /// <returns>
    /// if operation = “get”
    ///     msg[list] = 
    ///     {
    ///         <param>
    ///             modelID(int)  模型ID
    ///             modelType(int)	模型类型
    ///             picURL(string)	MODEL对应的图片的URL,
    ///             version(string)	支持的引擎版本
    ///         </param>
    ///     }
    /// </returns>
]]
paraworld.CreateRPCWrapper("paraworld.map.GetMapModelByIDs", "%MAP%/GetMapModelByIDs.asmx");

--[[
    /// <summary>
    /// 取得Model的某一页的数据
    /// </summary>
    /// <param name="msg">
    /// if(operation = "get")
    ///     msg =
    ///     {
    ///         operation = "get",(*)
    ///         pageNum = int,(*) 每页的数据量
    ///         pageindex = int,(*) 第几页
    ///     }
    /// </param>
    /// <returns>
    ///if(operation = "get") 
    ///     msg =
    ///     {
    ///         pagecount int  共有多少页
    ///         models[list] Model集合
    ///         {
    ///             <param>
    ///                 modelID = int,
    ///                 modelType = int,
    ///                 picURL = string,
    ///                 manufacturerType = int,
    ///                 manufacturerID = Guid(用string代替),
    ///                 manufacturerName = string,
    ///                 price = decimal,
    ///                 price2 = decimal,
    ///                 price2StartTime datetime,
    ///                 price2EndTime datetime,
    ///                 adddate datetime,
    ///                 ownerUserID = GUID,用string代替
    ///                 ownerUserName = string,
    ///                 version = string,
    ///                 modelPath = string,
    ///                 texturePath = string,
    ///                 package = string,
    ///                 allowEdit = boolean,
    ///                 userData1 = string  这个Model有哪几种朝向，0：东；1：东南；2：南；......每种方向以英文逗号（,）分隔
    ///             </param>   
    ///         }
    ///     }
    ///</returns>
]]


paraworld.CreateRPCWrapper("paraworld.map.GetMapModelOfPage", "%MAP%/GetMapModelOfPage.asmx")
--paraworld.CreateRPCWrapper("paraworld.map.GetMapModelOfPage", "%MAP%/GetMapModelOfPage.asmx",
	---- serve locally 
	--function(self, msg, id, callbackFunc, callbackParams) 
		--
		--local output = {
			--models_db[1],
			--models_db[2],
		--};
		--callbackFunc(output, callbackParams);
		---- since we process via local server, there is no need to call RPC. 
		--return true;
	--end);

--[[
	/// <summary>
	/// 新增一个Model
	/// </summary>
	/// <param name="msg">
	/// msg ={
	///     sessionkey = string, (*)
	///     modelType = int, (*)
	///     picURL = string,  (*)
	///     manufacturerType = int, (*) 1:ParaEngine, 2: 玩家  3:第三方生产商
	///     manufacturerID = Guid（用string代替）,
	///     manufacturerName = string,
	///     price = decimal, 
	///     price2 = decimal,
	///     price2StartTime datetime,
	///     price2EndTime datetime,
	///     ownerUserID = GUID,用string代替
	///     ownerUserName = string,
	///     version = string,
	///     modelPath = string,
	///     texturePath = string,
	///     package = string,
	///     allowEdit = boolean,
	///     directions = string  该模型的朝向集合，0为东，1为东南，2为南，3为西南，以此类推。每个朝向之间以英文逗号“,”分隔
	/// }
	/// </param>
	/// <returns>
	///     msg =
	///     {
	///         isSucceed(boolean) 操作是否成功完成
	///         info = [ optional ] 注释、说明信息
	///     }
	/// </returns>
]]
paraworld.CreateRPCWrapper("paraworld.map.AddModel", "%MAP%/AddModel.asmx");

--[[
	/// <summary>
	/// 依主键获得一个Model的信息
	/// </summary>
	/// <param name="msg">
	/// msg = {
	///     "modelID" = int (*)
	///		"isSimple" = boolean 若要返回精简模式的数据，则为True，若要返回全部字段数据，则为False。默认值为False
	/// }
	/// </param>
	/// <returns>
	///     msg = 
	///     {
	///         modelID = int,
	///         modelType = int,
	///         picURL = string,
	///			texturePath = string,
	///         package = string,
	///			version = string, //此字段及以上字段为精简模式的数据
	///         manufacturerType = int,
	///         manufacturerID = Guid（用string代替）,
	///         manufacturerName = string,
	///         price = decimal,
	///         price2 = decimal,
	///         price2StartTime datetime,
	///         price2EndTime datetime,
	///         adddate datetime,
	///         ownerUserID = GUID,用string代替
	///         ownerUserName = string,
	///         modelPath = string,
	///         allowEdit = boolean,
	///         directions = string  该模型的朝向集合，0为东，1为东南，2为南，3为西南，以此类推。每个朝向之间以英文逗号“,”分隔
	///			[info] = string  关于此次操作的说明信息，比如：异常信息等，若能正常取出数据，则不会有此字段
	///			[ errorcode ] (int)  错误码。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  497：数据不存在或已被删除   496：未登录
	///     }
	/// </returns>
]]
paraworld.CreateRPCWrapper("paraworld.map.GetModelByID", "%MAP%/GetModelByID.asmx");

--[[
	/// <summary>
	/// 修改一个Model
	/// </summary>
	/// <param name="msg">
	/// msg = {
	///     sessionkey = string, (*)
	///     modelID = int, (*)
	///     modelType = int,
	///     picURL = string,
	///     manufacturerType = int,
	///     manufacturerID = Guid(用string代替),
	///     manufacturerName = string,
	///     price = decimal,
	///     price2 = decimal,
	///     price2StartTime datetime,
	///     price2EndTime datetime,
	///     ownerUserID = GUID,用string代替
	///     ownerUserName = string,
	///     version = string,
	///     modelPath = string,
	///     texturePath = string,
	///     package = string,
	///     allowEdit = boolean,
	///     directions = string  该模型的朝向集合，0为东，1为东南，2为南，3为西南，以此类推。每个朝向之间以英文逗号“,”分隔
	/// }
	/// </param>
	/// <returns>
	///     msg =
	///     {
	///         isSucceed(boolean) 操作是否成功完成
	///         [info] = [ optional ] 注释、说明信息
	///     }
	/// </returns>
]]
paraworld.CreateRPCWrapper("paraworld.map.UpdateModel", "%MAP%/UpdateModel.asmx");

--[[
	/// <summary>
	/// 删除一个Model
	/// </summary>
	/// <param name="msg">
	/// msg = {
	///		"sessionkey" = string (*)
	///     "modelID" = int (*)
	/// }
	/// </param>
	/// <returns>
	///     msg =
	///     {
	///         isSucceed(boolean) 操作是否成功完成
	///         info = [ optional ] 注释、说明信息
	///     }
	/// </returns>
]]
paraworld.CreateRPCWrapper("paraworld.map.RemoveModel", "%MAP%/RemoveModel.asmx");



-----------------------------------------------------
-- world related
-----------------------------------------------------
--[[
	/// <summary>
	/// 发布（即新增）一个World
	/// </summary>
	/// <param name="msg">
	///     msg = {
	///	        "sessionkey" = string (*)
	///	        "name" = string,(*)世界名称
	///	        "desc" = string,描述
	///         "version" = string,引擎版本
	///         "spaceServer" = string, 空间服务器
	///         "jabberGSL" = string, 用“;”分隔的Jabber精简游戏服务器地址
	///         "gsl" = string, 精简游戏服务器地址
	///	        "gameServer" = string,游戏服务器IP或URL
	///	        "ageGroup" = int, ESRP
    ///         "preview " = string,世界截图的URL
    ///         "type" = int,类别，默认值为0，表示没有设置类别
    ///         "location"= string, 地理位置
	///	        "price" = int, 价格
	///     }
	/// </param>
	/// <returns>
	///     msg =
	///     {
	///         issuccess(boolean) 操作是否成功完成
	///			[ errorcode ] (int)  错误码。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  497：数据不存在或已被删除   496：未登录
	///     }
	/// </returns>
]]
paraworld.CreateRESTJsonWrapper("paraworld.map.PublishWorld", "%MAP%/PublishWorld.ashx");


--[[
	/// <summary>
	/// 依据ID取得一个World
	/// </summary>
	/// <param name="msg">
	///     msg = {
	///         "worldid" = int　（*） 要取得的World的ID
	///    }
	/// </param>
	/// <returns>
	///     msg = 
	///     {
	///         worldid(int)	worldid
	///         name(string)	3D世界名称
	///         desc(string)	3D世界描述
	///         lastModifiedDate(datetime)	上次修改时间
	///         lastVisitDate(datetime)	上次访问时间
	///         version(string)		引擎版本
	///         approved(boolean)	是否通过审核
	///         ownerID(GUID,用string代替)	所有者的用户ID
	///         ownerUserName(string)	所有者的用户名
	///         spaceServer(string)		空间服务器URL地址
	///         jabberGSL(string)	Jabber精简游戏服务器地址，用“;”分隔的JID
	///         GSL(string)	精简游戏服务器地址：Web Service URL
	///         gameServer(string)	游戏服务器IP或URL
	///         visits(int)   访问次数
	///         ranking(int)   级别
	///         ageGroup(int)  ESRP级别：1，儿童；2，青少年；3，成人；4，大众
	///         gameData(string) GSL游戏内容
	///     }
	/// </returns>
]]
local world_get_cache_policy = System.localserver.CachePolicy:new("access plus 1 day");
paraworld.CreateRESTJsonWrapper("paraworld.map.GetWorldByID", "%MAP%/GetWorldByID.ashx",
	function(self,msg,id,callbackFunc,callbackParams, postMsgTranslator) 
		msg.sessionkey = msg.sessionkey or Map3DSystem.User.sessionkey;
		local cache_policy = msg.cache_policy or world_get_cache_policy;
		if(type(cache_policy)=="string")then
			cache_policy = Map3DSyste.localserver.CachePolicy:new(cache_policy);
		end
		if(cache_policy:IsCacheEnabled())then
			local ls = System.localserver.CreateStore(nil,3);
			if(ls)then
				ls:GetURL(cache_policy,
					NPL.EncodeURLQuery(self.GetUrl(), {"format", msg.format, "worldid", msg.worldid,}),
					callbackFunc, callbackParams, postMsgTranslator
				);
			else
				log("error: unable to open default local server store \n");
			end
			return true;
		end
	end
)


--[[
	/// <summary>
	/// 修改一个World
	/// </summary>
	/// <param name="msg">
	///     msg = {
	///	        "sessionkey" = string, (*)
	///	        "worldid" = int,　(*)　World　ID
	///	        "name" = string,　世界名称
    ///	        "desc" = string,　描述
    ///	        "version" = string, 引擎版本
    ///	        "spaceServer" = string, 空间服务器
    ///	        "jabberGSL" = string, 用“;”分隔的Jabber精简游戏服务器地址
    ///	        "gsl" = string, 精简游戏服务器地址
    ///	        "gameServer" = string, 游戏服务器IP或URL
    ///         "ageGroup" = int,　ESRP
    ///         "preview " = string,世界截图的URL
    ///         "type" = int,类别，默认值为0，表示没有设置类别
    ///         "location"= string, 地理位置
    ///         "price" = int,  价格,-1表示不设置设置价格
	///     }
	/// </param>
	/// <returns>
	///     msg = 
	///     {
	///         issuccess(boolean) 操作是否成功完成
	///			[ errorcode ] (int)  错误码。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  497：数据不存在或已被删除   496：未登录
	///     }
	/// </returns>
]]
paraworld.CreateRESTJsonWrapper("paraworld.map.UpdateWorld", "%MAP%/UpdateWorld.ashx");

--[[
	/// <summary>
	/// 删除指定的World
	/// </summary>
	/// <param name="msg">
	///     msg = {
	///         sessionkey = string,(*)
	///         worldid = int(*) 要删除的World的ID
	///     }
	/// </param>
	/// <returns>
	///     msg =
	///     {
	///         issuccess(boolean) 操作是否成功完成
	///         info = [ optional ] 注释、说明信息
	///     }
	/// </returns>
]]
paraworld.CreateRESTJsonWrapper("paraworld.map.RemoveWorld", "%MAP%/RemoveWorld.ashx");

--[[
	/// <summary>
	/// 取得指定用户上传的所有世界
	/// </summary>
	/// <param name="msg">
	///     msg = {
	///         "uid" = string(*) 用户ID
	///    }
	/// </param>
	/// <returns>
	///     msg = 
	///     {
	///			worlds[list]
	///			{
	///				worldid(int)	worldid
	///				name(string)	3D世界名称
	///				desc(string)	3D世界描述
	///				lastModifiedDate(datetime)	上次修改时间
	///				lastVisitDate(datetime)	上次访问时间
	///				version(string)		引擎版本
	///				approved(boolean)	是否通过审核
	///				ownerID(GUID,用string代替)	所有者的用户ID
	///				ownerUserName(string)	所有者的用户名
	///				spaceServer(string)		空间服务器URL地址
	///				jabberGSL(string)	Jabber精简游戏服务器地址，用“;”分隔的JID
	///				GSL(string)	精简游戏服务器地址：Web Service URL
	///				gameServer(string)	游戏服务器IP或URL
	///				visits(int)   访问次数
	///				ranking(int)   级别
	///				ageGroup(int)  ESRP级别：1，儿童；2，青少年；3，成人；4，大众
	///				gameData(string) GSL游戏内容
	///			}
	///			[ errorcode ] (int)  错误码，发生异常时会有此节点。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  497：数据不存在或已被删除   496：未登录
	///     }
	/// </returns>
]]
paraworld.CreateRESTJsonWrapper("paraworld.map.GetWorlds", "%MAP%/GetWorlds.ashx");

--[[
    /// <summary>
	/// 某用户加入指定的World，即成为此World的一个成员
	/// </summary>
	/// <param name="msg">
	///     msg = {
	///	        "sessionkey" = string (*)
	///	        "worldid" = int,(*)世界ID
	///     }
	/// </param>
	/// <returns>
	///     msg =
	///     {
	///         issuccess(boolean) 操作是否成功完成
	///			[ errorcode ] (int)  错误码。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  497：数据不存在或已被删除   496：未登录
	///     }
	/// </returns>
]]
paraworld.CreateRESTJsonWrapper("paraworld.map.JoinWorld", "%MAP%/JoinWorld.ashx");

--[[
    /// <summary>
    /// 某用户离开指定的World，即不再是此World的成员
    /// </summary>
    /// <param name="msg">
    ///     msg = {
    ///	        "sessionkey" = string (*)
    ///	        "worldid" = int,(*)世界ID
    ///     }
    /// </param>
    /// <returns>
    ///     msg =
    ///     {
    ///         issuccess(boolean) 操作是否成功完成
    ///			[ errorcode ] (int)  错误码。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  497：数据不存在或已被删除   496：未登录
    ///     }
    /// </returns>
]]
paraworld.CreateRESTJsonWrapper("paraworld.map.LeaveWorld", "%MAP%/LeaveWorld.ashx");

--[[
    /// <summary>
    /// 某用户访问指定的World
    /// </summary>
    /// <param name="msg">
    ///     msg = {
    ///	        "sessionkey" = string (*)
    ///	        "worldid" = int,(*)世界ID
    ///     }
    /// </param>
    /// <returns>
    ///     msg =
    ///     {
    ///         issuccess(boolean) 操作是否成功完成
    ///			[ errorcode ] (int)  错误码。0：无异常  500：未知错误  499：提供的数据不完整  498：非法的访问  497：数据不存在或已被删除   496：未登录
    ///     }
    /// </returns>
]]
paraworld.CreateRESTJsonWrapper("paraworld.map.VisitWorld", "%MAP%/VisitWorld.ashx");




