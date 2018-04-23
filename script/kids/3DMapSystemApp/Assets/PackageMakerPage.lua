--[[
Title: code behind page for PackageMakerPage.html
Author(s): LiXizhi
Date: 2008/5/6
Desc: make a zip package
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/Assets/PackageMakerPage.lua");
local PackageMakerPage = commonlib.gettable("Map3DSystem.App.Assets.PackageMakerPage");
PackageMakerPage.BuildPackageByGroupPath({"packages/redist/main_script_complete_mobile-1.0.txt"},"installer/test.zip")
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/FileExplorerCtrl.lua");
local PackageMakerPage = {
	--记录在每个根目录下面所选中的文件路径
	folderList = {},
	--记录通过文本文件加载后的文件路径
	loadTxtPathList = {},
	
	--生成文本文件的路径
	txtFilePath = nil,
	--压缩包名称
	packageName = nil,
	--压缩包版本
	packageVersion = nil,
	--压缩包路径
	packagePath = nil,
	
	--已经被引擎使用的文件列表
	FileInUseList = {},
	--预览的类型 "current_folder" or "all_folder"
	radio_folderType="current_folder", 
	
	document = nil,
	fileBrowserIsCreated = false,
	importFileTabitemCreated = false,
	-- 用户最后选择要过滤的文件类型，在打包的时候将会以它的值来打包
	curentSelectedFilter = nil,
	ifHadSavedTextFile = false,
	--加载一个文本文件后，记录它的filterlist，它的值将会应用在filebrowserCtl.filter
	afterLoadTextFile_filter = nil,
	};
commonlib.setfield("Map3DSystem.App.Assets.PackageMakerPage", PackageMakerPage)

-- whether to allow exclusion in input files. 
PackageMakerPage.enable_exclude_option = true;

---------------------------------
-- page event handlers
---------------------------------

-- first time init page
function PackageMakerPage.OnInit()
	PackageMakerPage.document = document;
	
	PackageMakerPage.folderList = {};
	PackageMakerPage.loadTxtPathList = {};
	PackageMakerPage.txtFilePath = nil;
	PackageMakerPage.packageName = nil;
	PackageMakerPage.packageVersion = nil;
	PackageMakerPage.packagePath = nil;
	PackageMakerPage.FileInUseList = {};
	PackageMakerPage.radio_folderType="current_folder";
	PackageMakerPage.fileBrowserIsCreated = false;
	PackageMakerPage.importFileTabitemCreated = false;
	PackageMakerPage.ifHadSavedTextFile = false;
	PackageMakerPage.afterLoadTextFile_filter = nil;
	
	local tabpage = document:GetPageCtrl():GetRequestParam("tab");
    if(tabpage and tabpage~="") then
        document:GetPageCtrl():SetNodeValue("PackageMakerTabs", tabpage);
    end
end
--FileBrowser在第一次被创建
--注意：在刷新mcml页面后，filebrowserCtl的父类TreeView可能出错，找不到 local _parent = ParaUI.GetUIObject(self.name);
function PackageMakerPage.OnCreate()
	local document = PackageMakerPage.document;
	
	local filebrowserCtl = document:GetPageCtrl():FindControl("FileBrowser");	
	if(filebrowserCtl) then
		if(PackageMakerPage.fileBrowserIsCreated==false)then
			document:GetPageCtrl():SetUIValue("selectedFolderName","");
			document:GetPageCtrl():SetUIValue("previewFolderMembers","");
			
			
			PackageMakerPage.OnSelectFile("", "")
			local folderPath = filebrowserCtl.rootfolder;
			PackageMakerPage.OnSelectFolder("", folderPath)
			
			local CurFilter = document:GetPageCtrl():FindControl("CurFilter");
			if(PackageMakerPage.afterLoadTextFile_filter and CurFilter)then
					
				document:GetPageCtrl():SetUIValue("CurFilter",PackageMakerPage.afterLoadTextFile_filter);	
			end
			local filter = filebrowserCtl.filter
			PackageMakerPage.OnSelectFilter("", filter)	
			
			PackageMakerPage.fileBrowserIsCreated = true;
		end
	end
end
function PackageMakerPage.ClearAll(loadText)
	PackageMakerPage.OnInit();
	local document = PackageMakerPage.document;
	local pageCtrl = document:GetPageCtrl();
	pageCtrl:SetUIValue("selectedFolderName","");
	pageCtrl:SetUIValue("previewFolderMembers","");
	pageCtrl:SetUIValue("newPackageName","");
	pageCtrl:SetUIValue("new_result", "请输入发型包名称");
	pageCtrl:SetUIValue("newPackageFolder","packages/redist");	
	pageCtrl:SetUIValue("newPackageVersion","1.0");
	if(loadText == nil)then
		pageCtrl:SetUIValue("currentPackageFile","");	
	end	
	local print_txt = pageCtrl:FindControl("print_txt");
	if(print_txt)then
		print_txt:SetText("");
	end
	local package_txt = pageCtrl:FindControl("package_txt");
	if(package_txt) then 
		package_txt:SetText("");
	end
	local progressbar = pageCtrl:FindControl("progressbar");
	if(progressbar) then 
		pageCtrl:SetUIValue("progressbar",0 );
	end
	local onlySaveText_result = pageCtrl:FindControl("onlySaveText_result");
	if(onlySaveText_result) then 
		pageCtrl:SetUIValue("onlySaveText_result","");
	end
	
end

-- Create package
function PackageMakerPage.OnCreatePackage(name, values)
	local document = PackageMakerPage.document;
	local self = document:GetPageCtrl();
	if(values["newPackageName"]==nil or values["newPackageName"]=="") then
		self:SetUIValue("new_result", "请输入发型包名称");
		return 
	end
	local temp_packageName = values["newPackageName"];
	local temp_packagePath = values["newPackageFolder"];
	local temp_packageVersion = values["newPackageVersion"];
	
	values["newPackageFolder"] = values["newPackageFolder"].."/";
	local path = string.format("%s%s-%s.txt", values["newPackageFolder"], values["newPackageName"], values["newPackageVersion"]);
	if(ParaIO.DoesFileExist(path)) then
		_guihelper.MessageBox(string.format("发行包 %s 已经存在, 是否覆盖它?", path), function()
			if(PackageMakerPage.OnCreatePackage_imp(path,temp_packageName,temp_packagePath,temp_packageVersion)) then
				self:SetUIValue("new_result", string.format("发行包 %s 创建成功!", path));
				PackageMakerPage.packageName = temp_packageName;
				PackageMakerPage.packagePath = temp_packagePath;
				PackageMakerPage.packageVersion = temp_packageVersion;
				PackageMakerPage.txtFilePath = path;
				self:SetUIValue("currentPackageFile","");
				self:SetUIValue("loadTxtPath_result", "");
				PackageMakerPage.fileBrowserIsCreated = false;
				PackageMakerPage.importFileTabitemCreated = false;
				PackageMakerPage.loadTxtPathList = {};
				PackageMakerPage.folderList = {};
			end
		end);
	else
			
		if(PackageMakerPage.OnCreatePackage_imp(path,temp_packageName,temp_packagePath,temp_packageVersion)) then
			self:SetUIValue("new_result", string.format("发行包 %s 创建成功!", path));
			PackageMakerPage.packageName = temp_packageName;
			PackageMakerPage.packagePath = temp_packagePath;
			PackageMakerPage.packageVersion = temp_packageVersion;
			PackageMakerPage.txtFilePath = path;
			self:SetUIValue("currentPackageFile","");
			self:SetUIValue("loadTxtPath_result", "");
			PackageMakerPage.fileBrowserIsCreated = false;
			PackageMakerPage.importFileTabitemCreated = false;
			PackageMakerPage.loadTxtPathList = {};
			PackageMakerPage.folderList = {};
			
		end
	end	
	
end

-- return true if created successfully
function PackageMakerPage.OnCreatePackage_imp(filepath,packageName,packagePath,packageVersion)
	ParaIO.CreateDirectory(filepath);
	local file = ParaIO.open(filepath, "w")
	if(file:IsValid()) then
		file:WriteString("-- Package File Automatically generated by ParaEngine Package Maker. \r\n-- One can manually edit this file or open and edit it using package maker\r\n");
		file:WriteString("[packageName]="..packageName.."\r\n");
		file:WriteString("[packageVersion]="..packageVersion.."\r\n");
		file:WriteString("[packagePath]="..packagePath.."\r\n");
		file:close();
		return true;
	else
		commonlib.log("warning: unable to create package file at %s\n", filepath);
	end
end

-- User clicks a file
function PackageMakerPage.OnSelectFile(name, filepath)
	local document = PackageMakerPage.document;
	document:GetPageCtrl():SetUIValue("selectedFolderName",filepath);
	PackageMakerPage.UpdateFloderMembersTreeView()	
end

-- user selects a new folder
function PackageMakerPage.OnSelectFolder(name, folderPath)
	local document = PackageMakerPage.document;
	local filebrowserCtl = document:GetPageCtrl():FindControl("FileBrowser");
	if(filebrowserCtl and folderPath) then
		if(folderPath ~= filebrowserCtl.rootfolder )then
			--备份在当前根目录下面的记录
			local dest ;
			if(PackageMakerPage.folderList[filebrowserCtl.rootfolder] ==nil )then
				dest = {};
				commonlib.mincopy(dest, filebrowserCtl.CheckedPathList)
				PackageMakerPage.folderList[filebrowserCtl.rootfolder] = dest;
			end
		end
		--更换根目录
		filebrowserCtl.rootfolder = folderPath;		
		filebrowserCtl:ResetTreeView();
		

		if(PackageMakerPage.folderList[filebrowserCtl.rootfolder] ==nil )then
			dest = {};
			filebrowserCtl:SetCheckedPathList(dest);
			PackageMakerPage.folderList[filebrowserCtl.rootfolder] = filebrowserCtl.CheckedPathList;
		else
			dest = PackageMakerPage.folderList[filebrowserCtl.rootfolder];
			filebrowserCtl:SetCheckedPathList(dest);
		end
		
		filebrowserCtl:SetFromTxtPathList(PackageMakerPage.loadTxtPathList);
		
		filebrowserCtl.LastClickedNode = nil;
		PackageMakerPage.OnSelectFile("", "")

	end
end

-- user selects a new filter
function PackageMakerPage.OnSelectFilter(name, filter)
	local document = PackageMakerPage.document;
	local filebrowserCtl = filebrowserCtl or document:GetPageCtrl():FindControl("FileBrowser");
	if(filebrowserCtl and filter) then
		filebrowserCtl.filter = filter;
		
		filebrowserCtl:ResetTreeView();
		
		--通过后缀名过滤文件
		--PackageMakerPage.OnSelectFilterInPathList(filter)
		
		local dest;
		if(PackageMakerPage.folderList[filebrowserCtl.rootfolder] ==nil )then
			dest = {};
			filebrowserCtl:SetCheckedPathList(dest);
			PackageMakerPage.folderList[filebrowserCtl.rootfolder] = filebrowserCtl.CheckedPathList;
		else
			dest = PackageMakerPage.folderList[filebrowserCtl.rootfolder];
			filebrowserCtl:SetCheckedPathList(dest);
		end
		filebrowserCtl:SetFromTxtPathList(PackageMakerPage.loadTxtPathList);
		
		
		
	end
end
--通过后缀名过滤文件
function PackageMakerPage.OnSelectFilterInPathList(filter)
	for f in string.gfind(filter, "([^%s;]+)") do
		if(f~="*.*")then
				f = string.gsub(f,"*","");
				local folder,data , txt;
				--从FileExplorerCtrl中获取
				for folder,data in pairs(PackageMakerPage.folderList) do
					for nodePath,txt in pairs(data) do					
						if(not string.find(txt,f.."$"))then						
							if(data[nodePath]~=nil)then
								data[nodePath] = nil;
							end
						end
					end
				end
				
				--从已有文本文件中获取
				for __,txt in pairs(PackageMakerPage.loadTxtPathList) do
						if(not string.find(txt,f.."$"))then
							if(PackageMakerPage.loadTxtPathList[txt]~=nil)then
								PackageMakerPage.loadTxtPathList[txt] = nil;
							end
						end
				end
		end		
	end
end
-- use checks a file 
function PackageMakerPage.OnCheckFile(name, treeNode, filepath, Checked)
	local document = PackageMakerPage.document;
	if(treeNode and filepath) then
		local filebrowserCtl = document:GetPageCtrl():FindControl("FileBrowser");
		local nodePath = treeNode:GetNodePath();
		local txt = filebrowserCtl:GetAbsoluteNodeTxt(nodePath);
		if(filebrowserCtl.rootfolder ~= "/")then
				txt = filebrowserCtl.rootfolder.."/";
			end
		if(PackageMakerPage.FileInUseList[txt])then
			if(treeNode.Checked)then
				treeNode.TextColor = "#20a420";
			else
				treeNode.TextColor = "#ff0000";
			end
		end
	end
end

-- when a file node created. we can modify its display to give some hints, such as 
-- 1. whether the file is being used by the system or not. 
-- 1. whether the file is previously included by the system or not
function PackageMakerPage.OnCreateFileNode(name, treeNode, filepath)
	local document = PackageMakerPage.document;
	if(treeNode and filepath) then
		if(string.find(filepath, "lua$"))then
			-- check all *.lua file and make the text blue
			--treeNode.TextColor = "#0066cc";
			--treeNode.Checked = true;
		end
		
		local filebrowserCtl = document:GetPageCtrl():FindControl("FileBrowser");
		local nodePath = treeNode:GetNodePath();
		local txt = filebrowserCtl:GetAbsoluteNodeTxt(nodePath);
		if(filebrowserCtl.rootfolder ~= "/")then
				txt = filebrowserCtl.rootfolder.."/";
			end
		if(PackageMakerPage.FileInUseList[txt])then
			if(treeNode.Checked)then
				treeNode.TextColor = "#20a420";
			else
				treeNode.TextColor = "#ff0000";
			end
		end
	end
end

-- refresh the file currently in used. 
function PackageMakerPage.OnClickRefreshFileInUse(name, values)
	local document = PackageMakerPage.document;
	local path = "temp/asset.txt"
	ParaAsset.PrintToFile(path, 7);
	local line	
		local file = ParaIO.open(path, "r");
		if(file:IsValid()) then
				  line=file:readline();
			while line~=nil do 		
					PackageMakerPage.FileInUseList[line] = line;		
					line=file:readline();
			end
		else
			log("error:PackageMakerPage.OnClickRefreshFileInUse \n");
		end
		file:close();
	
	local filebrowserCtl = document:GetPageCtrl():FindControl("FileBrowser");
	local node = filebrowserCtl.RootNode;
		  PackageMakerPage.SetFileInUseStyle(filebrowserCtl,node)
		  filebrowserCtl:Update();
	
	PackageMakerPage.radio_folderType = values["folderType"];
	PackageMakerPage.UpdateFloderMembersTreeView()
end
-- set FileInUse Style
function PackageMakerPage.SetFileInUseStyle(filebrowserCtl,node)
	local self = filebrowserCtl;
	if(not node or not node.Nodes or not self)then return; end
	local k , child;
		for k,child in ipairs(node.Nodes) do
			local child_path = child:GetNodePath();
			local nodeTxt = self:GetAbsoluteNodeTxt(child_path)
			if(self.rootfolder ~= "/")then
				nodeTxt = self.rootfolder.."/";
			end	
			
			if(PackageMakerPage.FileInUseList[nodeTxt])then
				if(child.Checked)then
					child.TextColor = "#20a420";
				else
					child.TextColor = "#ff0000";
				end
			end
			PackageMakerPage.SetFileInUseStyle(self,child)
		end
end
-- print result to UI
function PackageMakerPage.OnPrint(name, filter)
	local namelist = PackageMakerPage.GetPrintList();
	PackageMakerPage.DoPrint(namelist,PackageMakerPage.FileInUseList,"print_txt",true,nil)
end
--@param namelist: 选中的路径列表
--@param fileInUseList: 被引擎使用的文件列表
--@param print_txt_name: 文本控件名称
--@param showAllSelected: true 显示all selected file
--@param rootFolderPath: if not nil then cut the head of filepath
function PackageMakerPage.DoPrint(namelist,fileInUseList,print_txt_name,showAllSelected,rootFolderPath)
	local document = PackageMakerPage.document;
	local print_txt = document:GetPageCtrl():FindControl(print_txt_name);
	if(not namelist or not print_txt or not fileInUseList)then return; end
	fileInUseList = PackageMakerPage.SortList(fileInUseList);
	if(print_txt) then
		--local namelist = PackageMakerPage.GetPrintList();
		local inuseButUnselected_list = {}
		local inuseAndSelected_list = {}
		local k,v;
		for k,v in ipairs(fileInUseList) do		
			local innamelist = PackageMakerPage.IfInNameList(namelist,v)
			if(rootFolderPath)then
					v = string.gsub(v,"^"..rootFolderPath.."/","");
					v = "/"..v;
					--v = string.gsub(v,rootFolderPath,"");
				if(innamelist)then		
					table.insert(inuseAndSelected_list,v);	
				else
					table.insert(inuseButUnselected_list,v);	
				end	
			end
					
		end
		txt = "";
		local len = table.getn(inuseButUnselected_list);
		--some file not selected but in use		
			txt = txt.."-----------------------------------------------------\n";
			txt = txt.."some file not selected but in use\n";
			txt = txt.."-----------------------------------------------------\n";
			if(len >0)then
			k =1
				for k,len in ipairs(inuseButUnselected_list) do
					txt = txt..inuseButUnselected_list[k].."\n";
				end
			else
				txt = txt.."nil\n"
			end
		 len = table.getn(inuseAndSelected_list);
		 --file selected and in use
			txt = txt.."-----------------------------------------------------\n";
			txt = txt.."file selected and in use\n";
			txt = txt.."-----------------------------------------------------\n";
			if(len >0)then
			k=1;
				for k,len in ipairs(inuseAndSelected_list) do
					txt = txt..inuseAndSelected_list[k].."\n";
				end
			else
				txt = txt.."nil\n"
			end
		if(showAllSelected)then
			--all selected file
			txt = txt.."-----------------------------------------------------\n";
			txt = txt.."all selected file\n";
			txt = txt.."-----------------------------------------------------\n";
			for k,v in ipairs(namelist) do
				txt = txt..v.."\n";
			end
		end
		print_txt:SetText(txt);
	else
		log("warning: invalid FileBrowser or print_txt control in page");
	end	
end
--FileInUseList 里面的文件是否被选中，选中返回true
--因为namelist里面可能包含 FileInUseList里面路径的 父文件夹，所以一旦找到父文件夹存在，就返回true
function PackageMakerPage.IfInNameList(namelist,path)
	local f;
	local temp="";
		for f in string.gfind(path, "([^/]+)") do
			temp = temp.."/"..f;
			local __,__,ff = string.find(temp,"^/(.+)");
			local k,path
			for k,path in ipairs(namelist) do
				if(ff == path)then
				--if(namelist[ff])then
					return true;
				end
			end
		end
end
-- make package
function PackageMakerPage.OnPackage()
	local document = PackageMakerPage.document;
	local pageCtrl = document:GetPageCtrl();  
	local packageName = PackageMakerPage.packageName;
	local packagePath = PackageMakerPage.packagePath;
	local packageVersion = PackageMakerPage.packageVersion;
	local errormsg ,fileName =PackageMakerPage.ValidateName(packageName)
	if(errormsg~="")then
		_guihelper.MessageBox(commonlib.serialize(errormsg));
		return;
	end
		
	if(packagePath =="" or packagePath==nil)then
		 errormsg = "目录不能为空！\n" ;
		 _guihelper.MessageBox(commonlib.serialize(errormsg));
		
		 return;
	end
	
	local namelist = PackageMakerPage.GetPrintList();
		  --生成压缩文件
		  local name = packageName.."-"..packageVersion; 
		  PackageMakerPage.DoSaveZipFile(name,packagePath,namelist);

end
function PackageMakerPage.OnlySaveTextFile()
	local namelist = PackageMakerPage.GetPrintList();
	if(not namelist)then 
		pageCtrl:SetUIValue("onlySaveText_result", "出错！数据为空");
		return ; 
	end;
	local document = PackageMakerPage.document;
	local pageCtrl = document:GetPageCtrl();
	local filebrowserCtl = pageCtrl:FindControl("FileBrowser");
	local filepath = PackageMakerPage.txtFilePath;
	local file = ParaIO.open(filepath, "w")
	if(file:IsValid()) then
		local packageName = PackageMakerPage.packageName;
		local packageVersion = PackageMakerPage.packageVersion;
		local packagePath = PackageMakerPage.packagePath;
		file:WriteString("[packageName]="..packageName.."\r\n");
		file:WriteString("[packageVersion]="..packageVersion.."\r\n");
		file:WriteString("[packagePath]="..packagePath.."\r\n");
		file:WriteString("[filterList]="..filebrowserCtl.filter.."\r\n");
		file:WriteString("---------------------------------------------------------\r\n");
		local k , v ;
		for k , v in ipairs(namelist) do
			file:WriteString(v.."\r\n");
		end
		file:close();
		pageCtrl:SetUIValue("onlySaveText_result", "文本文件生成成功！");
	else
		pageCtrl:SetUIValue("onlySaveText_result", "出错！生成文本文件出错");
		commonlib.log("warning: unable to create package path list at %s\n", filepath);
	end
end
-- create the package file.
function PackageMakerPage.DoSaveZipFile(name,packagePath,namelist)
	local document = PackageMakerPage.document;
	local pageCtrl = document:GetPageCtrl();  
	local filebrowserCtl = pageCtrl:FindControl("FileBrowser");
	if(not namelist)then 
		pageCtrl:SetUIValue("package_result", "出错！数据为空");
		return ; 
	end;
	
	pageCtrl:SetUIValue("package_result", "稍等片刻，正在生成中。。。");
	local txt = "开始\n";
	
	local package_txt = pageCtrl:FindControl("package_txt");
	if(not package_txt) then return end
	local rootPath = ParaIO.GetCurDirectory(0);
	local fullPath = rootPath..packagePath.."/"..name..".zip";
	fullPath = string.gsub(fullPath, "/", "\\");
	
	PackageMakerPage.OnlySaveTextFile();
	
	local writer = ParaIO.CreateZip(fullPath,"");
	local k , v ;
	--local temp = {}
	--for k ,v in pairs(namelist) do
		--table.insert(temp,v);
	--end
	--namelist = temp
	local len = table.getn(namelist);
	if(len>0)then
		for k , v in ipairs(namelist) do
			--如果找到有同配符的路径
			local __,__,temp_path = string.find(v,"(.+)%*%.(.+)");
			if(temp_path)then
				txt = txt..v.."\n";	
				writer:AddDirectory(temp_path,v,300);
			else
				local path = rootPath..v;
				
				local search_result = ParaIO.SearchFiles(path.."/","*", "", 0, 1, 0);
				local nCount = search_result:GetNumOfResult();
				if(nCount>0) then
					
					--如果是目录
					local filter = filebrowserCtl.filter;
					local f;
					for f in string.gfind(filter, "([^%s;]+)") do
						 local t_path= path.."/"..f;
						 --path= path.."/*.*";
						 local t_v = v.."/";	
						 txt = txt..t_path.."\n";				
						 writer:AddDirectory(t_v,t_path,300);
					end
				else
					txt = txt..path.."\n";
					
					--如果不是目录
					 path= string.gsub(path, "/", "\\");
					 writer:ZipAdd(v,path);
				end
			end
			package_txt:SetText(txt);
			local index = 100*k/len
			pageCtrl:SetUIValue("progressbar",index );
		end
	else
		pageCtrl:SetUIValue("progressbar",100 );
	end
	writer:close();
	pageCtrl:SetUIValue("package_result", "完成");
	txt = txt.."完成\n"
	package_txt:SetText(txt);
end

function PackageMakerPage.OnPackageStep(mcmlNode, step)
	ParaEngine.ForceRender(); ParaEngine.ForceRender();
end

--获取要打印的列表
function PackageMakerPage.GetPrintList()
		local list = {};
		local txt;
		local fullPath="";
		
		local folder,data;
		--从FileExplorerCtrl中获取
		for folder,data in pairs(PackageMakerPage.folderList) do
			if(folder ~= "/")then
				fullPath = folder.."/";
			end
			
			for __,txt in pairs(data) do	
				txt = fullPath..txt;
				list[txt] = txt;
			end
		end
		
		--从已有文本文件中获取
		for folder,data in pairs(PackageMakerPage.loadTxtPathList) do				
				list[data] = data;
		end	
		list = PackageMakerPage.SortList(list);
		return list;
end
-- use clicks to open a new folder
function PackageMakerPage.NewPkgSelectFolder(name, filter)
	local document = PackageMakerPage.document;
	NPL.load("(gl)script/ide/OpenFolderDialog.lua");
	local dialog = CommonCtrl.OpenFolderDialog:new();
	local pageCtrl = document:GetPageCtrl();
	dialog.OnSelected = function (sCtrlName,path)
			
		pageCtrl:SetUIValue("newPackageFolder",path);	
	end;
	dialog:Show();
end

--显示选中文件夹中 被引擎使用的文件
function PackageMakerPage.UpdateFloderMembersTreeView()
	local document = PackageMakerPage.document;
	local previewFolderMembers = document:GetPageCtrl():FindControl("previewFolderMembers");
	local filebrowserCtl = document:GetPageCtrl():FindControl("FileBrowser");	
	
	if(previewFolderMembers and filebrowserCtl )then
		local node = filebrowserCtl.LastClickedNode;
		local list = PackageMakerPage.GetUseFileByFolderNode(filebrowserCtl,node)
		local namelist = PackageMakerPage.GetPrintList();
		local folderPath = filebrowserCtl:GetNodeNamePath(node);
		PackageMakerPage.DoPrint(namelist,list,"previewFolderMembers",false,folderPath)	
	end
end

--加载压缩包的文本配置文件
function PackageMakerPage.LoadTxtPathList()
	PackageMakerPage.ClearAll(true);
	local document = PackageMakerPage.document;
	local pageCtrl = document:GetPageCtrl();
	local path = pageCtrl:GetUIValue("currentPackageFile");
	if(string.find(path,"(.+).txt$"))then
		PackageMakerPage.txtFilePath =path;
		
		local line	
		local file = ParaIO.open(path, "r");
		if(file:IsValid()) then
			local temp = {};
				  line=file:readline();
			while line~=nil do 		
				if(string.find(line, "%[packageName%]")~=nil) then
					local __,__,packageName = string.find(line,"%s-%[packageName%]%s-=%s-([^%s]+)%s-");
					PackageMakerPage.packageName = packageName;
					
				elseif(string.find(line, "%[packagePath%]")~=nil) then
					local __,__,packagePath = string.find(line,"%s-%[packagePath%]%s-=%s-([^%s]+)%s-");
					PackageMakerPage.packagePath = packagePath;
					
				elseif(string.find(line, "%[packageVersion%]")~=nil) then
					local __,__,packageVersion = string.find(line,"%s-%[packageVersion%]%s-=%s-([^%s]+)%s-");
					PackageMakerPage.packageVersion = packageVersion;
				elseif(string.find(line, "%[filterList%]")~=nil) then
					local __,__,_filterStr = string.find(line,"%s-%[filterList%]%s-=%s-([^%s]+)%s-");
					--commonlib.echo(_filterStr);
					PackageMakerPage.afterLoadTextFile_filter = _filterStr;
				else
					if(line~="")then
						line = PackageMakerPage.CutFilter(line);		
						temp[line] = line;
					end
				end
				
				line=file:readline();
			end
			PackageMakerPage.loadTxtPathList = temp;
			
		else
			pageCtrl:SetUIValue("loadTxtPath_result", string.format("加载 %s 失败!", path));
			log("error:PackageMakerPage.LoadTxtPathList \n");
			file:close();
			return;
		end
		file:close();
		
		--更新filebrowser
		local filebrowserCtl = pageCtrl:FindControl("FileBrowser");	
		if(filebrowserCtl)then
			--清空记录在每个根目录下面所选中的文件路径
			PackageMakerPage.folderList = {};
		end
		----过滤掉所有重复的路径
		PackageMakerPage.DeleteFilterAllList()
		
		PackageMakerPage.fileBrowserIsCreated = false;
		--PackageMakerPage.OnCreate();	
		pageCtrl:SetUIValue("loadTxtPath_result", string.format("加载 %s 成功!", path));
		
		--更新 newPackageName， newPackageFolder， newPackageVersion
		local packageName = PackageMakerPage.packageName;
		local packagePath = PackageMakerPage.packagePath;
		local packageVersion = PackageMakerPage.packageVersion;
		if(packageName)then
			pageCtrl:SetUIValue("newPackageName",packageName);
		end
		if(packagePath)then
			pageCtrl:SetUIValue("newPackageFolder",packagePath);	
		end
		if(packageVersion)then
			pageCtrl:SetUIValue("newPackageVersion",packageVersion);	
		end
		PackageMakerPage.importFileTabitemCreated = false;
	else
		pageCtrl:SetUIValue("loadTxtPath_result", string.format("加载 %s 类型错误!", path));
		return;
	end
end
--验证字符串
function PackageMakerPage.ValidateName(str)	
	local errormsg="";
	if(not str or str=="")then 
	 errormsg = errormsg.."内容不能为空！\n" ;
	 return errormsg,str;
	 end;
	local reservedName = "";
		str = string.gsub(str,"%s*$","");
		str = string.gsub(str,"^%s*","");
		str = string.gsub(str,"%.*$","");
		str = string.gsub(str,"^%.*","");
		
	if(string.find(str,"[%c~!@#$%%^&*()=+%[\\%]{}''\";:/?,><`|!￥…（）-、；：。，》《]")) then
			errormsg = errormsg.."不能含有特殊字符\n"
	end
	
	if(string.len(str)<1) then
			errormsg = errormsg.."名称太短\n"
	end
	return errormsg,str;
end
--选中后，把引擎使用的文件加入到 PackageMakerPage.loadTxtPathList
function PackageMakerPage.CheckedUseFile()
	local document = PackageMakerPage.document;
	local filebrowserCtl = document:GetPageCtrl():FindControl("FileBrowser");
	local node = filebrowserCtl.LastClickedNode;
	local list = PackageMakerPage.GetUseFileByFolderNode(filebrowserCtl,node)
	local k,v;
	if(list)then
			for k,v in pairs(list) do
				PackageMakerPage.loadTxtPathList[v] = v;
			end	
			filebrowserCtl:SetFromTxtPathList(PackageMakerPage.loadTxtPathList);
	end
	PackageMakerPage.UpdateFloderMembersTreeView()
end
--获取在某个选中的文件夹下面 被引擎使用的文件
--如果是 PackageMakerPage.radio_folderType=="current_folder"，只返回它目录下面 被引擎使用的文件，不包含子目录
--否则 返回它目录下面所有  被引擎使用的文件，包含子目录
function PackageMakerPage.GetUseFileByFolderNode(filebrowserCtl,node)
	if(not filebrowserCtl or not node) then return ; end
	local list = {}	
		if(PackageMakerPage.radio_folderType=="current_folder")then
			if(node.Nodes)then
				local nSize = table.getn(node.Nodes);
				local i, child_node;
				for i=1, nSize do
					child_node = node.Nodes[i];
					local folderPath = filebrowserCtl:GetNodeNamePath(child_node);
					if(PackageMakerPage.FileInUseList[folderPath]~=nil)then
						list[folderPath] = PackageMakerPage.FileInUseList[folderPath];
					end
				end	
				
			end
		else
			local folderPath = filebrowserCtl:GetNodeNamePath(node);
			local k,v;
			for k,v in pairs(PackageMakerPage.FileInUseList) do
				local temp_v = string.lower(v).."/";
				local temp_folderPath =  string.lower(folderPath).."/";
				if(string.find(temp_v,"^"..temp_folderPath))then
					list[v] = v
				end
				--if(string.find(v,folderPath))then
					--list[v] = v
				--end
			end
		end	
		
		return list;
end

----------------------------------------------------------------------------------
--ImportFileTabitemOnclick
function PackageMakerPage.ImportFileTabitemOnclick()
	local document = PackageMakerPage.document;
	local pageCtrl = document:GetPageCtrl();
	if(PackageMakerPage.importFileTabitemCreated == false)then
		PackageMakerPage.importFileTabitemCreated = true;
		pageCtrl:SetUIValue("import_currentPackageFile","");
		pageCtrl:SetUIValue("import_print_txt","");
	end
end

--导入文本文件
function PackageMakerPage.import_LoadTxtPathList()
	local document = PackageMakerPage.document;
	local pageCtrl = document:GetPageCtrl();
	
	local packageName = PackageMakerPage.packageName;
	local packageVersion = PackageMakerPage.packageVersion;
	local packagePath = PackageMakerPage.packagePath;
	if(not packageName or not packageVersion or not packagePath)then
		pageCtrl:SetUIValue("import_print_txt","请新建一个安装包，或者打开一个安装包！\n");
		return;
	end
	local path = pageCtrl:GetUIValue("import_currentPackageFile");
	local temp = {};
	local txt = pageCtrl:GetUIValue("import_print_txt");
	if(string.find(path,"(.+).txt$"))then
		local line	
		local file = ParaIO.open(path, "r");
		if(file:IsValid()) then
				  line=file:readline();
			while line~=nil do 		
				if(string.find(line, "%[packageName%]")~=nil) then
					
					
				elseif(string.find(line, "%[packagePath%]")~=nil) then
					
					
				elseif(string.find(line, "%[packageVersion%]")~=nil) then
					
				else
					if(line~="")then
						line = PackageMakerPage.CutFilter(line);			
						temp[line] = line;
					end
				end
				
				line=file:readline();
			end
			
		else
			txt = txt ..string.format("注意：加载 %s 失败!\n", path);
			pageCtrl:SetUIValue("import_print_txt",txt );
			file:close();
			return;
		end
		file:close();
		
		txt = txt ..string.format("加载 %s 成功!\n", path);
		pageCtrl:SetUIValue("import_print_txt",txt );
		
		local k,v;
		for k,v in pairs(temp) do
			PackageMakerPage.loadTxtPathList[v] = v;
		end
		----过滤掉所有重复的路径
		PackageMakerPage.DeleteFilterAllList();
		
		PackageMakerPage.fileBrowserIsCreated = false;
	else
		txt = txt ..string.format("注意：加载 %s 类型错误!\n", path);
		pageCtrl:SetUIValue("import_print_txt",txt );
		return;
	end
end

--转换通配符"*.*"
function PackageMakerPage.CutFilter(path)
	path = string.gsub(path,"/%*%.%*$","");
	return path;
end

function PackageMakerPage.DeleteFilterAllList()
	local txt_pathList = PackageMakerPage.loadTxtPathList;
	--PackageMakerPage.DeleteFilter(pathList);
	
	for __,pathList in pairs(PackageMakerPage.folderList) do
		PackageMakerPage.DeleteFilter(txt_pathList,pathList);
	end
end
--过滤掉所有重复的路径
function PackageMakerPage.DeleteFilter(txt_pathList,pathList)
	local k,path,k_2,path_2;
	for k,path in pairs(txt_pathList) do
		local __,__,temp_path,temp_filter = string.find(path,"(.+)/%*%.(.+)");
		if(temp_path and temp_filter)then
			for k_2,path_2 in pairs(pathList) do
				if(path~=path_2)then
					local __,__,name = string.find(path_2,temp_path.."/(.+)%."..temp_filter);				
					if(name)then	
						--k_2 是nodePath path_2是filepath				
						if(pathList[k_2])then
							pathList[k_2] = nil;
						end
					end
				end
			end
		end
	end
end
function PackageMakerPage.SortList(list)
	if(not list) then return end;
	local temp = {};
	local k,v;
	for k,v in pairs(list) do
		table.insert(temp,{path = v});
	end
	table.sort(temp,PackageMakerPage.GenerateLessCFByField("path"));
	local temp_2 = {};
	for k,v in ipairs(temp) do
		local path = v.path;
		table.insert(temp_2,path);	
	end
	return temp_2;
end
-- generate a less compare function according to a node field name. 
-- @param fieldName: the name of the field, such as "Text", "Name", etc
function PackageMakerPage.GenerateLessCFByField(fieldName)
	fieldName = fieldName or "Text";
	return function(node1, node2)
		if(node1[fieldName] == nil) then
			return true
		elseif(node2[fieldName] == nil) then
			return false
		else
			 return string.lower(node1[fieldName]) < string.lower(node2[fieldName])
		end	
	end
end

-- generate a greater compare function according to a node field name. 
-- @param fieldName: the name of the field, such as "Text", "Name", etc
function PackageMakerPage.GenerateGreaterCFByField(fieldName)
	fieldName = fieldName or "Text";
	return function(node1, node2)
		if(node2[fieldName] == nil) then
			return true
		elseif(node1[fieldName] == nil) then
			return false
		else
			return string.lower(node1[fieldName]) > string.lower(node2[fieldName])
		end	
	end
end

function PackageMakerPage.GenerateFileList(list, filterStr)
	
	if(PackageMakerPage.enable_exclude_option) then
		NPL.load("(gl)script/ide/Files.lua");
		local output = {};
		for _, searchpath in pairs(list) do
			local exclude_option = searchpath:match("^%[(%w+)%]");
			if(not exclude_option) then
				local parent_dir, file_pattern = searchpath:match("^(.*)/([^/]+)$");
				if(parent_dir and file_pattern) then
					local result = commonlib.Files.Find({}, parent_dir, 20, 50000, file_pattern)
					for _, item in ipairs(result) do
						local filename = parent_dir.."/"..item.filename;
						output[filename] = filename;
					end
					LOG.std(nil, "info", "PackageMakerPage", "adding %d files in %s", #result, searchpath);
				end
			end
		end
		for _, searchpath in pairs(list) do
			local exclude_option, searchpath = searchpath:match("^%[(%w+)%](.*)$");
			if(exclude_option) then
				local parent_dir, file_pattern = searchpath:match("^(.*)/([^/]+)$");
				if(parent_dir and file_pattern) then
					local result = commonlib.Files.Find({}, parent_dir, if_else(exclude_option=="exclude1", 0, 20), 50000, file_pattern)
					for _, item in ipairs(result) do
						local filename = parent_dir.."/"..item.filename;
						output[filename] = nil;
					end
					LOG.std(nil, "info", "PackageMakerPage", "excluding %d files in %s", #result, searchpath);
				end
			end
		end
		return output, filterStr;
	else
		return list, filterStr;
	end
end

-------------------------------------------------------------------------
--@param txtPathList:一个文本路径的集合 {"a/b/1.txt","a/b/2.txt",}
--@param zipPath:生成压缩包的路径 c/d/test.zip
--[[
NPL.load("(gl)script/kids/3DMapSystemApp/Assets/PackageMakerPage.lua");
local txtPathList = {
	"packages/redist/1-1.0.txt",
	"packages/redist/2-1.0.txt",
	"packages/redist/3-1.0.txt"
}
local zipPath = "packages/redist/test.zip";
local PackageMakerPage = Map3DSystem.App.Assets.PackageMakerPage;
PackageMakerPage.BuildPackageByGroupPath(txtPathList,zipPath)
--]]
function PackageMakerPage.BuildPackageByGroupPath(txtPathList,zipPath)
	if(type(txtPathList)~="table") then return ; end;
	local allPathList = {list = nil,filterList = nil};
	local k,v;
	for k,path in ipairs(txtPathList) do
		
		local list,filterStr = PackageMakerPage.GetPathFromTxtFile(path)
		list, filterStr = PackageMakerPage.GenerateFileList(list, filterStr);

		if(not list ) then
			log("load "..path.."失败！\n");
		else
			if(not filterStr) then 
				log("注意："..path.." 的[filterList]为空，你可能要手工修改一下这个文件！格式为[filterList]=*.x;*.png;*.dds \n   [filterList]只对目录起作用，不影响其他的文件路径\n");
				filterStr = "*.*";
			end
			local filterList = {};
			local f;
			for f in string.gfind(filterStr, "([^%s;]+)") do
				table.insert(filterList,f);
			end
			table.insert(allPathList,{list = list,filterList = filterList})		
		end
	end
	if(#allPathList > 0) then
		NPL.load("(gl)script/installer/BuildParaWorld.lua");
		if(commonlib.BuildParaWorld.BUILD_FROM_MAC)then
			PackageMakerPage.BuildPackageByGroupPath_DoMakeZipFile_temp(allPathList,zipPath)	
		else
			PackageMakerPage.BuildPackageByGroupPath_DoMakeZipFile(allPathList,zipPath)	
		end
	end
end

function PackageMakerPage.BuildPackageByGroupPath_OnStartEvent()
	--commonlib.echo("PackageMakerPage.BuildPackageByGroupPath_OnStartEvent()");
end
function PackageMakerPage.BuildPackageByGroupPath_OnProgressEvent(percent)
	--commonlib.echo(percent);
end
function PackageMakerPage.BuildPackageByGroupPath_OnEndEvent()
	--commonlib.echo("PackageMakerPage.BuildPackageByGroupPath_OnEndEvent()");
end
-- return: 路径列表 和 通配符
function PackageMakerPage.GetPathFromTxtFile(txtPath)
	local path = txtPath;
	if(string.find(path,"(.+).txt$"))then
		PackageMakerPage.txtFilePath =path;
		
		local line;
		local file = ParaIO.open(path, "r");
		local filterStr;
		if(file:IsValid()) then
			local temp = {};
			line=file:readline();
			while line~=nil do 		
				if(string.find(line, "%[packageName%]")~=nil) then
								
				elseif(string.find(line, "%[packagePath%]")~=nil) then
								
				elseif(string.find(line, "%[packageVersion%]")~=nil) then
				
				elseif(string.find(line, "%[filterList%]")~=nil) then
					local __,__,_filterStr = string.find(line,"%s-%[filterList%]%s-=%s-([^%s]+)%s-");
					filterStr= _filterStr
				else
					if(line~="")then
						--line = PackageMakerPage.CutFilter(line);		
						temp[line] = line;
					end
				end
				
				line=file:readline();
			end
			file:close();
			return temp,filterStr;
		else
			file:close();
			return;
		end		
	else
		return;
	end
end

function PackageMakerPage.BuildPackageByGroupPath_DoMakeZipFile(allPathList,zipPath)
	if(not allPathList)then 
		log("PackageMakerPage.BuildPackageByGroupPath_DoMakeZipFile 出错！数据为空\n");
		return ; 
	end;
	--"开始";
	PackageMakerPage.BuildPackageByGroupPath_OnStartEvent()
	
	local rootPath = ParaIO.GetCurDirectory(0);
	local fullPath = rootPath..zipPath
	fullPath = string.gsub(fullPath, "/", "\\");
	local writer = ParaIO.CreateZip(fullPath,"");
		
	PackageMakerPage.StartDoMakeGroupZipFile_index = 1;
	local len = table.getn(allPathList)
	local obj = allPathList[PackageMakerPage.StartDoMakeGroupZipFile_index];
	local list = obj.list;
	local filterList = obj.filterList;
	
	PackageMakerPage.BuildPackageByGroupPath_writer(writer,list,filterList,allPathList,rootPath)
	
	writer:close();
	--"完成";
	PackageMakerPage.BuildPackageByGroupPath_OnEndEvent();
end

function PackageMakerPage.BuildPackageByGroupPath_writer(writer,namelist,filterList,allPathList,rootPath)
	local allPathList_len = table.getn(allPathList);
	if(PackageMakerPage.StartDoMakeGroupZipFile_index >allPathList_len) then return; end
	local k , v ;
	local temp = {}
	for k ,v in pairs(namelist) do
		table.insert(temp,v);
	end
	namelist = temp
	local len = table.getn(namelist);
	if(len>0)then
		for k , v in ipairs(namelist) do
			--如果找到有同配符的路径
			local __,__,temp_path = string.find(v,"(.+)%*%.(.+)");
			if(temp_path)then
				writer:AddDirectory(temp_path,v,300);
			else
				local path = rootPath..v;
				
				local search_result = ParaIO.SearchFiles(path.."/","*", "", 0, 1, 0);
				local nCount = search_result:GetNumOfResult();
				if(nCount>0) then
					
					--如果是目录
					local f;
					for __,f in ipairs(filterList) do
						local t_path= path.."/"..f;
						 --path= path.."/*.*";
						 local t_v = v.."/";	
						 writer:AddDirectory(t_v,t_path,300);
					end
					
				else		
					--如果不是目录
					 path= string.gsub(path, "/", "\\");
					 writer:ZipAdd(v,path);
				end
			end		
			local index = 100*k/len
			index = index *(PackageMakerPage.StartDoMakeGroupZipFile_index/allPathList_len)
			PackageMakerPage.BuildPackageByGroupPath_OnProgressEvent(index)
			--pageCtrl:SetUIValue("progressbar",index );
		end
		
		PackageMakerPage.StartDoMakeGroupZipFile_index = PackageMakerPage.StartDoMakeGroupZipFile_index + 1;
		if(PackageMakerPage.StartDoMakeGroupZipFile_index >allPathList_len) then return; end
		local obj = allPathList[PackageMakerPage.StartDoMakeGroupZipFile_index];
		local list = obj.list;
		local filterList = obj.filterList;		
		PackageMakerPage.BuildPackageByGroupPath_writer(writer,list,filterList,allPathList,rootPath)
	end
end
function PackageMakerPage.BuildPackageByGroupPath_DoMakeZipFile_temp(allPathList,zipPath)
	if(not allPathList)then 
		log("PackageMakerPage.BuildPackageByGroupPath_DoMakeZipFile 出错！数据为空\n");
		return ; 
	end;
	--"开始";
	PackageMakerPage.BuildPackageByGroupPath_OnStartEvent()
	
	local rootPath = ParaIO.GetCurDirectory(0);
	local fullPath = rootPath..zipPath
	fullPath = string.gsub(fullPath, "/", "\\");
	local writer = {};
		
	PackageMakerPage.StartDoMakeGroupZipFile_index = 1;
	local len = table.getn(allPathList)
	local obj = allPathList[PackageMakerPage.StartDoMakeGroupZipFile_index];
	local list = obj.list;
	local filterList = obj.filterList;
	
	PackageMakerPage.BuildPackageByGroupPath_writer_temp(writer,list,filterList,allPathList,rootPath)

	local pkg_file = ParaIO.open("pkg_file.txt", "w");
	local k,v;
	for k,v in ipairs(writer) do
		pkg_file:WriteString(v.."\n");
	end
	pkg_file:close();
	--"完成";
	PackageMakerPage.BuildPackageByGroupPath_OnEndEvent();
end
-- @param writer: a table which stored path list
function PackageMakerPage.BuildPackageByGroupPath_writer_temp(writer,namelist,filterList,allPathList,rootPath)
	local allPathList_len = table.getn(allPathList);
	if(PackageMakerPage.StartDoMakeGroupZipFile_index >allPathList_len) then return; end
	local k , v ;
	local temp = {}
	for k ,v in pairs(namelist) do
		table.insert(temp,v);
	end
	namelist = temp
	local len = table.getn(namelist);
	if(len>0)then
		for k , v in ipairs(namelist) do
			--如果找到有同配符的路径
			local __,__,temp_path = string.find(v,"(.+)%*%.(.+)");
			if(temp_path)then
				PackageMakerPage.AddDirectory(writer,temp_path,v,300);
			else
				local path = rootPath..v;
				
				local search_result = ParaIO.SearchFiles(path.."/","*", "", 0, 1, 0);
				local nCount = search_result:GetNumOfResult();
				if(nCount>0) then
					
					--如果是目录
					local f;
					for __,f in ipairs(filterList) do
						local t_path= path.."/"..f;
						 --path= path.."/*.*";
						 local t_v = v.."/";	
						 PackageMakerPage.AddDirectory(writer,t_v,t_path,300);
					end
					
				else		
					--如果不是目录
					 path= string.gsub(path, "/", "\\");
					 PackageMakerPage.ZipAdd(writer,v,path);
				end
			end		
			local index = 100*k/len
			index = index *(PackageMakerPage.StartDoMakeGroupZipFile_index/allPathList_len)
			PackageMakerPage.BuildPackageByGroupPath_OnProgressEvent(index)
			--pageCtrl:SetUIValue("progressbar",index );
		end
		
		PackageMakerPage.StartDoMakeGroupZipFile_index = PackageMakerPage.StartDoMakeGroupZipFile_index + 1;
		if(PackageMakerPage.StartDoMakeGroupZipFile_index >allPathList_len) then return; end
		local obj = allPathList[PackageMakerPage.StartDoMakeGroupZipFile_index];
		local list = obj.list;
		local filterList = obj.filterList;		
		PackageMakerPage.BuildPackageByGroupPath_writer_temp(writer,list,filterList,allPathList,rootPath)
	end
end
function PackageMakerPage.AddDirectory(writer,destFolder,filePattern,subLevel)
	if(not writer)then return end
	local rootpath = ParaIO.GetParentDirectoryFromPath(filePattern,0);
	local search_result = ParaIO.SearchFiles(rootpath,ParaIO.GetFileName(filePattern), "", subLevel, 10000000, 0);
	local nCount = search_result:GetNumOfResult();
	local i;
	for i = 0, nCount-1 do 
		local filename = search_result:GetItem(i);
		local ext = commonlib.Files.GetFileExtension(filename);
		if(ext and ext ~= "")then
			local full_path = rootpath..filename;
			table.insert(writer,full_path);
		end
	end
	search_result:Release();
end
function PackageMakerPage.ZipAdd(writer,destFolder,filename)
	table.insert(writer,destFolder);
end
