--[[
Title: http constants
Author(s): LiXizhi
Date: 2008/2/23
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/http_constants.lua",
Map3DSystem.localserver.HttpConstants.DefaultSchemePortMapping
-------------------------------------------------------
]]


local HttpConstants = {
	-- HTTP status code
	HTTP_OK = 200,
    HTTP_NOT_MODIFIED = 304,
    HTTP_MOVED = 301,
    HTTP_FOUND = 302,
    
    -- default scheme port mapping
    DefaultSchemePortMapping = {
		["http"] = 80,
		["https"] = 443,
		["file"] = 0,
	},
	
	kCacheControlHeader = "Cache-Control",
	kContentDispositionHeader = "Content-Disposition",
	kContentLengthHeader = "Content-Length",
	kContentTypeHeader = "Content-Type",
	kCrLf = "\r\n",
	kCrLfAscii = "\r\n",
	kLastModifiedHeader = "Last-Modified",
	kLocationHeader = "Location",
	kIfModifiedSinceHeader ="If-Modified-Since",
	kUriHeader = "URI",
	kNoCache = "no-cache",
	kOKStatusLine = "HTTP/1.1 200 OK",
	kPragmaHeader = "Pragma",
	kHttpGET = "GET",
	kHttpGETAscii = "GET";
	kHttpHEAD = "HEAD",
	kHttpPOST = "POST",
	kHttpPUT = "PUT",
	kHttpScheme = "http",
	kHttpSchemeAscii = "http",
	kHttpsScheme = "https",
	kHttpsSchemeAscii = "https",
	kFileScheme = "file",
	kFileSchemeAscii = "file",
	kMimeTextPlain = "text/plain",
	kXCapturedFilenameHeader ="X-Captured-Filename",
};

commonlib.setfield("Map3DSystem.localserver.HttpConstants", HttpConstants)
