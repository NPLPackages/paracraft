--[[
Title: Local textures
Author(s): LiXizhi
Date: 2014/3/10
Desc: internally defined textures
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Materials/LocalTextures.lua");
local LocalTextures = commonlib.gettable("MyCompany.Aries.Game.Materials.LocalTextures");
local filename = LocalTextures:GetByFileName(LocalTextures.names.TextureInvalid);
local filename = LocalTextures:GetBlockTexture(filename)
-------------------------------------------------------
]]
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local LocalTextures = commonlib.gettable("MyCompany.Aries.Game.Materials.LocalTextures");

local names = commonlib.gettable("MyCompany.Aries.Game.Materials.LocalTextures.names");

-- internally defined textures 
names.TextureTransparent = "Texture/Transparent.png";
names.TextureInvalid = "Texture/blocks/cake_top.png";

-- @filename: first search in predefined names, then absolute path, then relative to local world path. 
function LocalTextures:GetByFileName(filename)
	local name = names[filename];
	if(name) then
		return name;
	else
		if(not ParaIO.DoesAssetFileExist(filename, true)) then
			filename = GameLogic.current_worlddir..filename;
			if(not ParaIO.DoesAssetFileExist(filename, true)) then
				return names.TextureInvalid;
			end
		end
		return filename;
	end
end

-- currently only mobile version need this 
-- @param filename: default is used if nil. 
function LocalTextures:LoadBlockReplacebleTexture(filename, bIsMobileVersion)
	local blocktextures = {};
	if(System.options.IsMobilePlatform or bIsMobileVersion) then
		filename = filename or "config/Aries/creator/local_texture_replace.xml";
		local root = ParaXML.LuaXML_ParseFile(filename);
		if(root) then
			local count = 0;
			for node in commonlib.XPath.eachNode(root, "/textures/texture") do
				local attr = node.attr;
				if(attr and attr.src_texture and attr.dest_texture) then
					blocktextures[attr.src_texture] = attr.dest_texture;
					count = count + 1;
				end
			end
			LOG.std(nil, "info", "LocalTextures", "%d replace textures loaded from %s", count, filename);
		else
			LOG.std(nil, "error", "LocalTextures", "can not find file at %s", filename);
		end
	end
	return blocktextures;
end

function LocalTextures:SetBlockReplacebleTexture(textures)
	self.blocktextures = textures;
end

function LocalTextures:GetBlockTexture(filename)
	if(filename) then
		if(not self.blocktextures) then
			self:SetBlockReplacebleTexture(self:LoadBlockReplacebleTexture());
		end
		return self.blocktextures[filename] or filename;
	end
end
