--[[
Title: CreateAssetBagPage.html code-behind script
Author(s): LiXizhi
Date: 2010/2/2
Desc: This page is only used by Aries Developers to create the bag xml file. 
A bag xml file is a descriptive file for all objects that a user can create in a given bag. 
For example, see "temp/mybag/helloassets/grass.bag.xml"
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Assets/CreateAssetBagPage.lua");
local CreateAssetBagPage = commonlib.gettable("MyCompany.Aries.Creator.CreateAssetBagPage")
CreateAssetBagPage.ShowPage()
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Assets/AssetsCommon.lua");
local ObjEditor = commonlib.gettable("ObjEditor");
local CreateAssetBagPage = commonlib.gettable("MyCompany.Aries.Creator.CreateAssetBagPage")

local page;

CreateAssetBagPage.CurBagPath = "temp/mybag/aries/grass.bag.xml";

function CreateAssetBagPage.ShowPage()
	System.App.Commands.Call("File.MCMLWindowFrame", {
			url = "script/apps/Aries/Creator/Assets/CreateAssetBagPage.html", 
			name = "CreateAssetBagPage.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			enable_esc_key = true,
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			--isTopLevel = true,
			directPosition = true,
				align = "_ct",
				x = -540/2,
				y = -400/2,
				width = 540,
				height = 400,
		});
end

function CreateAssetBagPage.OnInit()
	page = document:GetPageCtrl();	
	page:SetValue("bag_path", CreateAssetBagPage.CurBagPath);
end

function CreateAssetBagPage.GetCurBagDS_Func()
	return MyCompany.Aries.Creator.AssetsCommon.Get_DS_Func_FromAssetsXMLFile(CreateAssetBagPage.CurBagPath, true);
end

-- select a given bag
function CreateAssetBagPage.OnClickSelectBag(name, values)
	CreateAssetBagPage.CurBagPath = values.bag_path;
	page:Refresh(0);
end

function CreateAssetBagPage.OnBagChanged(name, value)
	if(value and value~="") then
		CreateAssetBagPage.CurBagPath = value;
		page:Refresh(0);
	end	
end

-- add the currently selected mesh or character to the bag. 
function CreateAssetBagPage.OnClickAddSelection()
	-- add selection to bag
	local dataSource = CreateAssetBagPage.CurBagPath;

	local objParams;
	if(ParaSelection.GetItemNumInGroup(2) > 0) then
		local obj = ParaSelection.GetObject(2, 0);
		if(obj and obj:IsValid()) then
			objParams = ObjEditor.GetObjectParams(obj);
		end
	end

	if(not objParams) then
		objParams = System.obj.GetObjectParams("selection");
	end

	local filename;
	local isCharacter;
	if(objParams and objParams.AssetFile) then 
		filename = objParams.AssetFile;
		isCharacter = objParams.IsCharacter;
	else
		filename = page:GetUIValue("model_filename", "");
		filename = filename:gsub("%s", "");
		if(filename:match("^model/.*%.x$")) then
			isCharacter = false;
		elseif(filename:match("^character/.*%.x$")) then
			isCharacter = true;
		else
			_guihelper.MessageBox("请先在3D场景中选择一个要添加的物体或输入模型路径");
			return;
		end
		if(not ParaIO.DoesAssetFileExist(filename, true)) then
			_guihelper.MessageBox(format("%s 文件不存在", filename));
		end
	end
	if(type(dataSource) == "string") then
		if(string.match(dataSource, "http://")) then
			-- TODO: remote xml or web serivce bag
		else
			-- local disk xml file. 
			local xmlRoot = ParaXML.LuaXML_ParseFile(dataSource);
			if(not xmlRoot) then 
				commonlib.log("pe:bag xml file %s is created. \n", dataSource);
				xmlRoot = {name="pe:mcml"}
			end
			NPL.load("(gl)script/ide/XPath.lua");
			local fileNode, bagNode;
			local result = commonlib.XPath.selectNodes(xmlRoot, string.format("//pe:asset[@src='%s']", filename));
			if(result and #result > 0) then
				_guihelper.MessageBox("当前选择的物品已经在背包中了");
				return;
			end
			-- add to the last bag in the file
			for fileNode in commonlib.XPath.eachNode(xmlRoot, "//pe:bag") do
				bagNode = fileNode;
			end
			if(not bagNode) then
				bagNode = {name="pe:bag"};
				xmlRoot[#xmlRoot+1] = bagNode;
			end
			-- add new asset node. 
			local newNode = {name="pe:asset", attr={}};
			
			newNode.attr["src"] = filename;
			if(isCharacter) then
				newNode.attr["type"] = "char";
			end
			newNode.attr["DisplayName"] = string.match(filename, "/([%w_]+)%.") ;
			
			bagNode[#bagNode+1] = newNode;
			
			-- output project file.
			ParaIO.CreateDirectory(dataSource);
			local file = ParaIO.open(dataSource, "w");
			if(file:IsValid()) then
				file:WriteString("<?xml version=\"1.0\" encoding=\"utf-8\"?>\r\n");
				file:WriteString(commonlib.Lua2XmlString(xmlRoot, true));
				file:close();
			else
				_guihelper.MessageBox(format("无法写入文件:%s", dataSource))
			end
			-- refresh the page. 
			page:Refresh(0.01);
		end
	end
	-- TODO: need to update bag and play some marker animation perhaps.
end

function CreateAssetBagPage.OnClickViewBagSourceFile()
	-- onclick view source code. 
	local filepath = ParaIO.GetParentDirectoryFromPath(CreateAssetBagPage.CurBagPath,0);
	ParaIO.CreateDirectory(filepath);
	Map3DSystem.App.Commands.Call("File.WinExplorer", filepath);
end

function CreateAssetBagPage.OnDeleteAsset(obj_params)
	local dataSource = CreateAssetBagPage.CurBagPath;

	-- local disk xml file. 
	local xmlRoot = ParaXML.LuaXML_ParseFile(dataSource);
	if(not xmlRoot) then 
		commonlib.log("pe:bag xml file %s is created. \n", dataSource);
		xmlRoot = {name="pe:mcml"}
	end
	NPL.load("(gl)script/ide/XPath.lua");
	local fileNode, bagNode;
	
	-- add to the last bag in the file
	for fileNode in commonlib.XPath.eachNode(xmlRoot, "//pe:bag") do
		bagNode = fileNode;
	end
	if(not bagNode) then
		bagNode = {name="pe:bag"};
		xmlRoot[#xmlRoot+1] = bagNode;
	end
	local filename = obj_params.AssetFile;
	local i;	
	local nRemoveIndex;
	for i, fileNode in ipairs(bagNode) do
		if(fileNode.attr and fileNode.attr.src == filename) then
			nRemoveIndex = i;
			break;
		end
	end
	if(nRemoveIndex) then
		commonlib.removeArrayItem(bagNode,nRemoveIndex);
		-- output project file.
		ParaIO.CreateDirectory(dataSource);
		local file = ParaIO.open(dataSource, "w");
		if(file:IsValid()) then
			file:WriteString("<?xml version=\"1.0\" encoding=\"utf-8\"?>\r\n");
			file:WriteString(commonlib.Lua2XmlString(xmlRoot, true));
			file:close();
		else
			_guihelper.MessageBox(format("无法写入文件:%s", dataSource))
		end
		-- refresh the page. 
		page:Refresh(0.01);
	end
end

function CreateAssetBagPage.OnClickItem(obj_params)
	if(mouse_button=="middle") then
		local filepath = obj_params.AssetFile;
		NPL.load("(gl)script/kids/3DMapSystemUI/Creator/Objects/ObjectInspectorPage.lua");
		-- display object inspector page to generate thumbnail icon, etc.  
		Map3DSystem.App.Commands.Call("File.MCMLWindowFrame", {
			url="script/apps/Aries/Creator/Assets/ObjectInspectorPage.html",
			name="Aries.ObjectInspectorPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			text = "查看物品",
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			zorder = 10,
			directPosition = true,
				align = "_ct",
				x = -140/2,
				y = -300/2,
				width = 140,
				height = 300,
		});
		Map3DSystem.App.Creator.ObjectInspectorPage.SetModel(filepath);
	elseif(mouse_button=="left") then
		NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateModelTask.lua");
		local task = MyCompany.Aries.Game.Tasks.CreateModel:new({obj_params=obj_params})
		task:Run();
	elseif(mouse_button=="right") then
		-- delete this object
		_guihelper.MessageBox("确定要删除这个物品么？", function(res)
				if(res and res == _guihelper.DialogResult.Yes) then
					-- pressed YES
					CreateAssetBagPage.OnDeleteAsset(obj_params);
				end
			end, _guihelper.MessageBoxButtons.YesNo);
	end	
end
