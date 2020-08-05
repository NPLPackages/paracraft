--[[
Title: help to code by giving examples
Author(s): leio
Date: 2020/7/16
Desc: 
use the lib:
-------------------------------------------------------
local NplCadLibPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCadLibPage.lua");
NplCadLibPage:ToggleVisible();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
NPL.load("(gl)script/ide/XPath.lua");
local XPath = commonlib.XPath;
local NplCadLibPage = NPL.export();

NplCadLibPage.name = "CodeCadTipPage_instance";
NplCadLibPage.mcml_url = "script/apps/Aries/Creator/Game/Code/NplCadLibPage.html";
NplCadLibPage.menus = nil;
NplCadLibPage.asset_list_map = {};
NplCadLibPage.selected_menu_index = 1;
NplCadLibPage.Current_Item_DS_Menus = {};
NplCadLibPage.Current_Item_DS = {};
function NplCadLibPage:OnInit()
    self.page = document:GetPageCtrl();
end

function NplCadLibPage:Show()
	local params = {
			url = self.mcml_url,
			name = self.name, 
			isShowTitleBar = false,
			DestroyOnClose = false,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			enable_esc_key = true,
			directPosition = true,
				align = "_lt",
				x = 5,
				y = 5,
				width = 400,
				height = 520,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

    self:LoadMenuData(function(data)
        self.menus = data;
        self.Current_Item_DS_Menus = data;
        self:OnSelectedMenu(self.selected_menu_index);
    end)
end
function NplCadLibPage:ToggleVisible()
    if(self.page)then
        if(self.page:IsVisible())then
            self.page:CloseWindow();
        else
            self:Show();
        end
    else
        self:Show();
    end
end
function NplCadLibPage:OnSelectedMenu(index)
    self.selected_menu_index = index;
    self:LoadAssetList(function(asset_list)
        self.Current_Item_DS = asset_list;
        self:OnRefresh();
    end);
end
function NplCadLibPage:LoadAssetList(callback)
    local index = NplCadLibPage.selected_menu_index;
    local menu = self.menus[index];
    if(menu)then
        local id = menu.id;
        local asset_list = NplCadLibPage.asset_list_map[id];
        if(asset_list)then
            if(callback)then
                callback(asset_list);
            end
            return
        end
        nplcad3.asset.get({
            cache_policy =  "access plus 0",
            router_params = {
                filepath = id .. ".json",
            }
        },function(err, msg, data)
            if(err ~= 200)then
                return
            end
            local asset_list = data;
            NplCadLibPage.asset_list_map[id] = asset_list;
	        if(callback)then
                callback(asset_list);
            end
        end)
    end
end
function NplCadLibPage:OnRefresh()
    if(self.page)then
        self.page:Refresh(0);
    end
end
-- only load once
function NplCadLibPage:LoadMenuData(callback)
    if(self.menus)then
        if(callback)then
            callback(self.menus);
        end
        return
    end
    nplcad3.asset.get({
        cache_policy =  "access plus 0",
        router_params = {
            filepath = "menus.json",
        }
    },function(err, msg, data)
        if(err ~= 200)then
            return
        end
	    if(callback)then
            callback(data);
        end
    end)
end
function NplCadLibPage:GetImage(index)
    local icon = self:GetIcon(index)
    local name = node.name or "";
    local s = string.format([[<div style="width:80px;height:45px;background:url(%s)" tooltip="%s" onclick="OnSelected" name="%d"/>]],icon,name,index)
    return s;
end
function NplCadLibPage:OnSelected(index)
    index = tonumber(index);
    local node = NplCadLibPage.Current_Item_DS[index];
    local filepath = node.filepath;
    nplcad3.asset.get({
        router_params = {
            filepath = filepath,
        }
    },function(err, msg, data)
        if(err ~= 200)then
            return
        end
        if(data and data.codes)then
            local codes_block = data.codes.block;
            local codes_lua = data.codes.lua;
            
            local codeEntity = CodeBlockWindow.GetCodeEntity() or {};
            local languageConfigFile = codeEntity.languageConfigFile;
            if(not codeEntity or not CodeBlockWindow.IsVisible() or languageConfigFile ~= "npl_cad")then
                _guihelper.MessageBox(L"请打开 npl block cad")
                return
            end
            _guihelper.MessageBox(L"你是否要使用代码库的源码？", function(res)
	            if(res and res == _guihelper.DialogResult.Yes) then
                    CodeBlockWindow.UpdateBlocklyCode(codes_block, codes_lua)
	            end
            end, _guihelper.MessageBoxButtons.YesNo);
        end
    end)
end
function NplCadLibPage:GetNode(index)
    index = tonumber(index);
    local node = NplCadLibPage.Current_Item_DS[index];
    return node;
end
function NplCadLibPage:GetIcon(index)
    local node = self:GetNode(index);
    if(node)then
        local icon = node.icon or "";
        icon = string.format("https://cdn.keepwork.com/NplCadCodeLib/nplcad3/%s",icon);
        return icon;
    end
end