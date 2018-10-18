--[[
Title: Aries app_main
Author(s):  CYF
Company: ParaEngine
Date: 2009/4/7
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Partners/PartnerPlatforms.lua");
local Platforms = commonlib.gettable("MyCompany.Aries.Partners.Platforms");
Platforms.Init();
Platforms.CallMethod("postToFeed", {title="test", url="www.paraengine.com", comment="text content",  summary="text summary", images="http://res.61.com/images/comm/banner/b_haqi.png" }, function(errCode) end)
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/socket/url.lua");
NPL.load("(gl)script/kids/3DMapSystemApp/API/ParaworldAPI.lua");
local ItemManager = commonlib.gettable("System.Item.ItemManager");

local Platforms = commonlib.gettable("MyCompany.Aries.Partners.Platforms");

local PLATS = {FB = 1, QQ = 2, Sina = 3, BaiduTieba = 4, KEEPWORK = 7, };
Platforms.PLATS = PLATS;

local HOST_MAIN = "http://haqi2.paraengine.com";

local PLAT_CNF_QQ = {
--[[ this has to be a trusted url. http://connect.qq.com/manage/  (QQ:756449515)
ParaEngine
http://qqlogin.paraengine.com
APP ID：100302176
KEY：31cfef471381c101ad2adbe70123a598
]]
	client_id = "100302176",
	auth_callback_url = "http://share.paraengine.com/qq_callback.htm",
	--auth_callback_url = "http://qqlogin.paraengine.com/qq_callback.htm",
};

local PLAT_CNF_FB = {
	client_id = "122316571254636",
	callback_url = "http://share2.paraengine.com/fb_callback.htm"
};

-- init from xml node. call this to alter callback url from platform nodes. 
-- @param xmlNode: array of platform XML nodes. if nil, System.options.platforms will be used. 
function Platforms.Init(xmlNode)
	xmlNode = xmlNode or System.options.platforms;
	if(xmlNode and #xmlNode>0) then
		local _, node
		for _, node in ipairs(xmlNode) do
			local attr = node.attr;
			if(attr and attr.name) then
				if(attr.name == "taomee") then
				elseif(attr.name == "QQ") then
					PLAT_CNF_QQ.auth_callback_url = attr.auth_callback_url or PLAT_CNF_QQ.auth_callback_url;
					PLAT_CNF_QQ.client_id = attr.client_id or PLAT_CNF_QQ.client_id;
				elseif(attr.name == "FB") then
					PLAT_CNF_FB.auth_callback_url = attr.auth_callback_url or PLAT_CNF_FB.auth_callback_url;
					PLAT_CNF_FB.client_id = attr.client_id or PLAT_CNF_FB.client_id;
				end
			end
		end
	end
end


function Platforms.SetPlat(pPlatId)
	System.User.Plat = pPlatId;
end

function Platforms.GetPlat()
	return System.User.Plat or PLATS.QQ;
end

function Platforms.SetOID(pOID)
	System.User.OID = pOID;
end

function Platforms.GetOID()
	return System.User.OID;
end

function Platforms.SetToken(pToken)
	System.User.Token = pToken;
end

function Platforms.GetToken()
	return System.User.Token;
end

function Platforms.SetAppId(pAppId)
	System.User.AppId = pAppId;
end

function Platforms.GetAppId()
	return System.User.AppId;
end


function Platforms.show_login_window(callbackFunc)
	local p = Platforms.GetPlat();
	if p == PLATS.QQ then
		local url = commonlib.gettable("commonlib.socket.url");
		local str = "http://openapi.qzone.qq.com/oauth/show?which=ConfirmPage&client_id=" .. PLAT_CNF_QQ.client_id .. "&response_type=token&scope=all&redirect_uri=" .. url.escape(PLAT_CNF_QQ.auth_callback_url);

		if(ParaEngine.GetAttributeObject():GetField("IsFullScreenMode", false)) then
			ParaGlobal.ShellExecute("open", str, "", "", 1);
		else
			NPL.load("(gl)script/apps/Aries/Partners/QQ/QQLogin.lua");
			local QQLogin = commonlib.gettable("MyCompany.Aries.Partners.QQ.QQLogin");
			str = str .. '&state=2';
			QQLogin.ShowPage(str, callbackFunc)
		end
	elseif p == PLATS.FB then
		local url = commonlib.gettable("commonlib.socket.url");
		local str = "http://www.facebook.com/dialog/oauth/?client_id=" .. PLAT_CNF_FB.client_id .. "&scope=email&response_type=token&display=popup&redirect_uri=" .. url.escape(PLAT_CNF_FB.callback_url);
		
		if(ParaEngine.GetAttributeObject():GetField("IsFullScreenMode", false)) then
			ParaGlobal.ShellExecute("open", str, "", "", 1);
		else
			NPL.load("(gl)script/apps/Aries/Partners/facebook/FacebookLogin.lua");
			local FacebookLogin = commonlib.gettable("MyCompany.Aries.Partners.Facebook.FacebookLogin");
			str = str .. '&state=2';
			FacebookLogin.ShowPage(str, callbackFunc)
		end
	elseif (p == PLATS.KEEPWORK) then
        NPL.load("(gl)script/apps/Aries/Partners/keepwork/KeepWorkLogin.lua");
        local KeepWorkLogin = commonlib.gettable("MyCompany.Aries.Partners.keepwork.KeepWorkLogin");
        KeepWorkLogin.ShowPage(callbackFunc);
	end
end

function Platforms.add_pending_login(callbackFunc)
	Platforms.pending_login_callback = callbackFunc;
end


-- called when user has logged in. 
function Platforms.OnLoginCallback()
	if(Platforms.pending_login_callback) then
		Platforms.pending_login_callback();
		Platforms.pending_login_callback = nil;
	end
end

-- @param callbackFunc: the function to be called only after successfully logged in.  
function Platforms.CheckLogin(callbackFunc)
	NPL.load("(gl)script/apps/Aries/Partners/InstallUrlProtocol.lua");

	local function StartLogin_()
		if(not Platforms.GetOID()) then
			Platforms.show_login_window();
			Platforms.add_pending_login(callbackFunc);
		else
			if(callbackFunc) then
				callbackFunc();
			end
		end
	end

	if(ParaEngine.GetAttributeObject():GetField("IsFullScreenMode", false)) then
		local InstallUrlProtocol = commonlib.gettable("MyCompany.Aries.Partners.InstallUrlProtocol");
		InstallUrlProtocol.CheckInstallWithUI(StartLogin_);
	else
		StartLogin_();
	end
end

-- invoke a given platform method by name
function Platforms.CallMethod(method_name, ...)
	local method = Platforms[method_name];
	if(type(method) == "function" ) then
		local args = {...};
		if(method_name == "postToFeed_window") then
			method(unpack(args));
			return;
		end
		Platforms.CheckLogin(function()
			method(unpack(args));
		end)
	end
end

local share_awards = {
		{gsid=50345, exid = 1810},
		{gsid=50346, exid = 1811},
	}

-- try sending award when we have successfully share a feed.
-- @return true if award is sent.otherwise it is nil.
function Platforms.TryGiveShareAward()
	if(System.options.version == "kids") then
		local _, award;
		for _, award in ipairs(share_awards) do
			local times = ItemManager.GetGSObtainCntInTimeSpanInMemory(award.gsid);
			if(times and times.inday==0) then
				ItemManager.ExtendedCost( award.exid, nil, nil, function(msg)end, function(msg)
					if(msg and msg.issuccess == true)then
						_guihelper.MessageBox("谢谢帮助我们宣传魔法哈奇！送出惊喜大礼一份请查收~");
						LOG.std(nil, "info", "Platforms" ,"sharing award is received. got gsid %d", award.gsid);
						paraworld.PostLog({action = "share_sns_award", nid=System.User.nid, }, "share_sns_award", function(msg)end);
					end
				end);
				return true;
			end
		end
	end
end

-- default handler when user has post a feed.
function Platforms.DefaultFeedHandler(errorCode)
	local re = errorCode;
	if re == 0 then
		if(Platforms.TryGiveShareAward()) then
			_guihelper.MessageBox("你的作品分享成功！每日前2次分享魔法星和普通用户都有惊喜大礼哦~");
		else
			_guihelper.MessageBox("你的作品分享成功！谢谢～");
		end
		-- TODO: dispatch reward here. 
	elseif re == 1 then
		_guihelper.MesageBox("分享失败了, 因为文字中包含敏感词汇");
	elseif re == 2 then
		_guihelper.MesageBox("分享失败了, 因为分享频率太高了");
	elseif re == 3 then
		_guihelper.MesageBox("抱歉, 分享服务今天不可用");
	elseif re == 4 then
		_guihelper.MesageBox("分享失败了, 您需要重新登录才能正常分享~");
	elseif re == 5 then
		_guihelper.MesageBox("抱歉， 上传图片失败了");
	else
		_guihelper.MesageBox(format("分享出现了未知错误:%s", tostring(re)));
	end
end


function Platforms.IncreaseCounter()
	Platforms.upload_count = (Platforms.upload_count or 0) + 1;
end

-- mapping from uploaded file crc32 code to filename
local uploaded_files = {};

-- if pMsg.images contains local file, it will return true and then it will upload the image to our temp server, and then calls pCallbackFun(pMsg, ...), where pMsg.images will be replaced by server url.
-- if pMsg.images does not contain any local file, it will return nil and does nothing.
function Platforms.PrepareImages(pMsg, pCallbackFun, param1, param2)
	if(pMsg and pMsg.images and not pMsg.images:match("^http://")) then
		-- if image is a local file, we will first upload to server first. 
		if(ParaIO.DoesFileExist(pMsg.images)) then
			local crc32 = ParaIO.CRC32(pMsg.images);
			if(uploaded_files[crc32]) then
				local url = uploaded_files[crc32];
				pMsg.images = url;
				LOG.std(nil, "info", "postToFeed", "image already uploaded before in url: %s", url);
				if(pCallbackFun) then
					pCallbackFun(pMsg, param1, param2);
				end
				return;
			end
			local photo_name = ParaGlobal.GetDateFormat("yyMMdd").."_"..ParaGlobal.GetTimeFormat("Hmmss");
			local msg = {
				src = pMsg.images,
				overwrite = 1,
				ispic = 1,
				filepath = "photos/"..photo_name..".jpg",
			};
			_guihelper.MessageBox("正在上传图片, 请稍候...");
			local res = paraworld.file.UploadFileEx(msg, "SharePhoto", function(msg)
				if(msg) then
					if(msg.issuccess and msg.url and msg.is_finished) then
						_guihelper.MessageBox(nil);
						Platforms.IncreaseCounter();
						local url = msg.url:gsub("^http://192.168.0.51:81", "http://qqlogin.paraengine.com:81"); -- this is only for testing 
						pMsg.images = url;
						if(url:match("^http://")) then
							Platforms.last_image_url = url;
							uploaded_files[crc32] = url;
							LOG.std(nil, "info", "postToFeed", "image is uploaded to our server url: %s", url)
							if(pCallbackFun) then
								pCallbackFun(pMsg, param1, param2);
							end
						end
					end
				end
				if(not msg or msg.errorcode~=nil) then
					_guihelper.MessageBox("暂时无法上传图片, 是否不带图片分享？", function(res)
						if(res and res == _guihelper.DialogResult.Yes) then
							-- pressed YES
							pMsg.images = "http://res.61.com/images/comm/banner/b_haqi.png";
							if(pCallbackFun) then
								pCallbackFun(pMsg, param1, param2);
							end
						end
					end, _guihelper.MessageBoxButtons.YesNo);
				end
			end)
			if(res == paraworld.errorcode.RepeatCall) then
				Platforms.DefaultFeedHandler(errorCode);
			end
		end
		return true;
	end
end

--[[ Platform method: post a feed
pMsg: table
	title (*) 标题
	url (*) 分享的网址，必须以http开头
	comment 用户评论内容
	summary 摘要
	images 图片地址集，多张图片以竖线（|）分隔
@param pCallbackFun: 可选，分享后的回调方法，其有一个参数，为分享状态码。0:成功；1:敏感词汇；2:分享频率太高；3:空间被封；4:需重新登录; 5: failed to upload image file; 6:超过本日最多次数
	if nil, this is the Platforms.DefaultFeedHandler
]]
function Platforms.postToFeed(pMsg, pCallbackFun)
	if(Platforms.PrepareImages(pMsg, Platforms.postToFeed, pCallbackFun)) then
		return;
	end

	local p = Platforms.GetPlat();
	pCallbackFun = pCallbackFun or Platforms.DefaultFeedHandler
	if p == PLATS.QQ then
		if not paraworld.postFeedQQ then
			paraworld.CreateRESTJsonWrapper("paraworld.postFeedQQ", "https://graph.qq.com/share/add_share", 
				function (self, msg, id, callback_func, callbackParams, postMsgTranslator)
					--
				end,
				function (self, msg)
					--
				end
			);
		end
		pMsg.access_token = Platforms.GetToken();
		pMsg.oauth_consumer_key = Platforms.GetAppId();
		pMsg.openid = Platforms.GetOID();
		paraworld.postFeedQQ(pMsg, "myfeed", function(msg)
			-- NPL.FromJson(msg, out)
			-- commonlib.Json.Encode
			if msg then
				log("paraworld.postFeedQQ callback msg: " .. commonlib.Json.Encode(msg));
				local re = msg.ret;
				if re == 3006 then
					re = 1;
				elseif re == 3006 or re == 3046 then
					re = 2;
				elseif re == 3034 then
					re = 3;
				elseif re == 100013 or re == 100014 or re == 100015 or re == 100016 then
					re = 4;
				end
				if pCallbackFun then
					pCallbackFun(re);
				end
			end
		end);
	end
end

--[[ Platform method: post a feed
pMsg: table
	title (*) 标题
	url (*) 分享的网址，必须以http开头
	comment 用户评论内容
	summary 摘要
	images 图片地址集，多张图片以竖线（|）分隔
	platform: 分享到哪个平台。可选。默认为当前登录的平台。
@param pCallbackFun: this is not supported yet. 
]]
function Platforms.postToFeed_window(pMsg, pCallbackFun)
	if(Platforms.PrepareImages(pMsg, Platforms.postToFeed_window, pCallbackFun)) then
		return;
	end
	local p = pMsg.platform or Platforms.GetPlat();
	if p == PLATS.QQ then
		local url = commonlib.gettable("commonlib.socket.url");
		local str = "http://sns.qzone.qq.com/cgi-bin/qzshare/cgi_qzshare_onekey?showcount=0&style=101&width=142&height=30&site="..if_else(System.options.version=="kids", "魔法哈奇", "魔法哈奇2") .. "&url=" .. url.escape(pMsg.url) .. "&showcount=0&otype=share&title=" .. url.escape(pMsg.title);
		if pMsg.comment then
			str = str .. "&desc=" .. url.escape(pMsg.comment);
		end
		if pMsg.summary then
			str = str .. "&summary=" .. url.escape(pMsg.summary);
		end
		if pMsg.images then
			str = str .. "&pics=" .. url.escape(pMsg.images);
		end
		ParaGlobal.ShellExecute("open", str, "", "", 1);
	elseif p == PLATS.Sina then
		local url = commonlib.gettable("commonlib.socket.url");
		local str = "http://service.weibo.com/share/share.php?url=" .. url.escape(pMsg.url) .. "&title=" .. url.escape(pMsg.title) .. if_else(System.options.version=="kids", "&ralateUid=1920014513", "&ralateUid=2548231564");
		if pMsg.images then
			str = str .. "&pic=" .. url.escape(pMsg.images);
		end
		ParaGlobal.ShellExecute("open", str, "", "", 1);
	elseif p == PLATS.BaiduTieba then
		local url = commonlib.gettable("commonlib.socket.url");
		local str = "http://tieba.baidu.com/f/commit/share/openShareApi?&title=" .. url.escape("My Creations In Haqi");
		if pMsg.images then
			str = str .. "&url=" .. url.escape(pMsg.url);
		end
		if pMsg.images then
			str = str .. "&pic=" .. url.escape(pMsg.images);
		end
		if pMsg.comment then
			str = str .. "&desc=" .. url.escape("My 3D creation in haqi");
		end
		ParaGlobal.ShellExecute("open", str, "", "", 1);
	end
end


--[[解除某个平台的帐户绑定
pMsg : table。如果为NULL，则使用当前默认数据
	plat 平台ID
	oid 平台用户名
	token 使用该平台帐户登录后的token
pCallbackFun : function。调用API后的回调方法。带一个参数，如果为０，表示成功
]]
function Platforms.URelationOtherAccount(pMsg, pCallbackFun)
	if not paraworld.users.UnRelationOtherAccount then
		paraworld.create_wrapper("paraworld.users.UnRelationOtherAccount", "%MAIN%/API/Users/UnRelationOtherAccount",
			function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator)
				LOG.std(nil, "debug", "UnRelationOtherAccount", "begin binding");
			end,
			function (self, msg, id, callbackFunc, callbackParams, postMsgTranslator, raw_msg, inputMsg)
				LOG.std(nil, "debug", "UnRelationOtherAccount", "end binding");
			end
		);
	end

	if not pMsg then
		pMsg = {plat = Platforms.GetPlat(), oid = Platforms.GetOID(), token = Platforms.GetToken()};
	end
	paraworld.users.UnRelationOtherAccount(pMsg, "users.UnRelationOtherAccount", function(msg)
		local _err = msg.errorcode;
		if _err == 0 then -- 解除绑定成功
			-- 
		end
		if not pCallbackFun then
			pCallbackFun(_err);
		end
	end);
end




