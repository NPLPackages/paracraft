--[[
Title: NplModLoader
Author(s): leio
Date: 2021/1/7
Desc: define nplm config 
use the lib:
------------------------------------------------------------
local NplModLoader = NPL.load("(gl)script/apps/Aries/Creator/Game/NplMod/NplModLoader.lua");
------------------------------------------------------------
--]]

local NplModLoader = NPL.export();

NplModLoader.mod_maps = {};
NplModLoader.storage_root = "npl_extensions"
function NplModLoader:loadConfig(url, callback)
    if(not url)then
        return
    end
    commonlib.echo("==========url");
    commonlib.echo(url);
    github.get({
        filepath = url
    },function(err, msg, data)
        commonlib.echo("==========github.get");
        commonlib.echo(err);
        commonlib.echo(msg);
        commonlib.echo(data);
    end)
end
-- @param options {table}
-- @param options.name {string}: "WinterCam2021"
-- @param options.type {string}: "github"
-- @param options.nplm {string}: "https://raw.githubusercontent.com/NPLPackages/WinterCamp2021/main/nplm.json"
-- @param options.source {string}: "https://codeload.github.com/NPLPackages/WinterCamp2021/zip/main"
function NplModLoader:loadMod(options, callback)
    if(not options)then
        if(callback)then
            callback();
        end
        return
    end

    local nplm = options.nplm;
    local name = options.name;
    NplModLoader:loadConfig(nplm);
    local mod_zip = NplModLoader.mod_maps[name];
    if(not mod_zip)then

        local filepath = self:getModZipPath(name);
        
        if(ParaIO.DoesFileExist(filepath, true))then
            commonlib.echo("==================filepath");
            commonlib.echo(filepath);
            local config = self:readConfigInZip(name, filepath);
            NplModLoader.mod_maps[name] = config;
            if(callback)then
                callback(config);
            end
            return
        end

        local type = options.type or "github";
        local source = options.source;
        System.os.GetUrl(source, function(err, msg, data)  
            if(err ~= 200)then
                if(callback)then
                    callback();
                end
                return
            end
            commonlib.echo("==================filepath 111");
            commonlib.echo(filepath);
            commonlib.echo(#data);
		    ParaIO.CreateDirectory(filepath);
            local file = ParaIO.open(filepath, "w");
	        if(file:IsValid() == true) then
			    file:write(data,#data);
		        file:close();
	        end
            
            local config = self:readConfigInZip(name, filepath);
            NplModLoader.mod_maps[name] = config;
            if(callback)then
                callback(config);
            end

        end);

        return
    end
    if(callback)then
        callback();
    end
end
function NplModLoader:getStorageRoot()
    return self.storage_root;
end
function NplModLoader:getModZipPath(name)
    if(not name)then
        return
    end
    local s = string.format("%s/%s.zip", self:getStorageRoot(), name);
    return s;
end

function NplModLoader:readConfigInZip(name,filepath)
	ParaAsset.OpenArchive(filepath, false);
    local bSetBase = false;
    local search_path = "nplm.json";
    local filesout = commonlib.Files.Find(filesout, "", 0, 10000, search_path, filepath) or {};
    local len = #filesout;
    if(len == 0)then
        search_path = "*/nplm.json";
        filesout = commonlib.Files.Find(filesout, "", 0, 10000, search_path, filepath);
    end
    if(filesout and #filesout > 0)then
        local item = filesout[1];
        local filename = item.filename;
        filename = string.gsub(filename,"\\", "/");
        local dir,_name = commonlib.Files.splitPath(filename)
        _name = string.lower(_name or "");
        if(_name == "nplm.json")then
            local file = ParaIO.open(filename, "r");
	        if(file:IsValid() == true) then
			    local txt = file:GetText();
		        file:close();
                local out={};
                if(NPL.FromJson(txt, out)) then
                    if(dir and dir ~= "")then
                        local zip_archive = ParaEngine.GetAttributeObject():GetChild("AssetManager"):GetChild("CFileManager"):GetChild(filepath);
                        local zipParentDir = zip_archive:GetField("BaseDirectory", "");
					    zip_archive:SetField("SetBaseDirectory", dir);
                    end
                    return out;
                end
                
	        end
        end
    end
end


