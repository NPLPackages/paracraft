--[[
Title: read me file for local server application
Author(s): LiXizhi
Date: 2008/2/25
Desc: developer guide and samples for local server app
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/localserver/readme.lua");
-------------------------------------------------------
]]

--[[ Local server wiki page:
---+ what is a local server?
The LocalServer module allows a web application to cache and serve its HTTP resources locally, without a network connection.

---++ Overview
The LocalServer module is a specialized URL cache that the web application controls. Requests for URLs in the LocalServer's cache are intercepted and served locally from the user's disk.

---++Resource stores 
A resource store is a container of URLs. Using the LocalServer module, applications can create any number of resource stores, and a resource store can contain any number of URLs.

There are two types of resource stores:
	- ResourceStore - for capturing ad-hoc URLs using JavaScript. The ResourceStore allows an application to capture user data files that need to be addressed with a URL, such as a PDF file or an image. 
	- ManagedResourceStore - for capturing a related set of URLs that are declared in a manifest file, and are updated automatically. The ManagedResourceStore allows the set of resources needed to run a web application to be captured. 
For both types of stores, the set of URLs captured is explicitly controlled by the web application.

---+ Architecture & Implementation Notes
all sql database manipulation functions are exposed via WebCacheDB, whose implementation is split in WebCacheDB* files. 
localserver is the based class for two servers: ResourceStore and ManagedResourceStore. 

---+ Using Local server as a local database
One can use local server as a simple (name, value) pair database with cache_policy functions.

To query a database entry call below, here we will use web service store
<verbatim>
	local ls = Map3DSystem.localserver.CreateStore(nil, 2);
	if(not ls) then
		return 
	end
	cache_policy = cache_policy or Map3DSystem.localserver.CachePolicy:new("access plus 1 week");
	
	local url = Map3DSystem.localserver.UrlHelper.WS_to_REST(fakeurl_query_miniprofile, {JID=JID}, {"JID"});
	local item = ls:GetItem(url)
	if(item and item.entry and item.payload and not cache_policy:IsExpired(item.payload.creation_date)) then
		-- NOTE:item.payload.data is always a string, one may deserialize from it to obtain table object.
		local profile = item.payload.data;
		if(type(callbackFunc) == "function") then
			callbackFunc(JID, profile);
		end
	else
		
	end
</verbatim>	

To add(update) a database entry call below
<verbatim>
	local ls = Map3DSystem.localserver.CreateStore(nil, 2);
	if(not ls) then
		return 
	end
	-- make url
	local url = Map3DSystem.localserver.UrlHelper.WS_to_REST(fakeurl_query_miniprofile, {JID=JID}, {"JID"});

	-- make entry
	local item = {
		entry = Map3DSystem.localserver.WebCacheDB.EntryInfo:new({
			url = url,
		}),
		payload = Map3DSystem.localserver.WebCacheDB.PayloadInfo:new({
			status_code = Map3DSystem.localserver.HttpConstants.HTTP_OK,
			data = msg.profile,
		}),
	}
	-- save to database entry
	local res = ls:PutItem(item) 
	if(res) then 
		log("ls put JID mini profile for "..url.."\n")
	else
		log("warning: failed saving JID profile item to local server.\n")
	end
<verbatim>


---++ Lazy writing 

For the URL history, this transaction commit overhead is unacceptably high(0.05s for the most simple write commit). 
On some systems, the cost of committing a new page to the history database was as high as downloading the entire page 
and rendering the page to the screen. As a result, ParaEngine's localserver has implemented a lazy sync system. 

Please see  https://developer.mozilla.org/en/Storage/Performance, for a reference

Localserver has relaxed the ACID requirements in order to speed up commits. In particular, we have dropped durability. 
This means that when a commit returns, you are not guaranteed that the commit has gone through. If the power goes out 
right away, that commit may (or may not) be lost. However, we still support the other (ACI) requirements. 
This means that the database will not get corrupted. If the power goes out immediately after a commit, the transaction 
will be like it was rolled back: the database will still be in a consistent state. 

]]