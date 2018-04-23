--[[
Title: pkgPreProcess.lua
Author(s): Spring Yan
Date: 2010/03/02  Modified Date: 2010/03/02
Desc: 
<verbatim>

对于增量版本，修改 zip 压缩包制作路径为 mainpkg_dir/temp/

--------------------------------------------------------------------------
-- 生成与大版本 main.pkg 比较的增量版本 mainYYMMDD.pkg
NPL.load("(gl)script/kids/3DMapSystemApp/Assets/pkgPreProcess.lua");
-- 编译当前 script/*.lua 到 bin/script/*.o
NPL.CompileFiles("script/*.lua", nil, 10); 

-- 备份当前main.pkg 源文件到 mainpkg_dir/cur/
pkgPreProcess.GetMainfile(pkgPreProcess.config.mainpkg_lst,pkgPreProcess.config.curscript_dir)

-- 将当前main.pkg 源文件(mainpkg_dir/cur/)比较大版本 main.pkg 源文件(mainpkg_dir/ver/)，并删除mainpkg_dir/temp/ 相同的文件
src_dr=pkgPreProcess.config.curscript_dir;
dst_dr=pkgPreProcess.config.verscript_dir;
zip_dr=pkgPreProcess.config.tmpscript_dir;
last_dr=pkgPreProcess.config.lastscript_dir;
fileflt="*.*"

pkgPreProcess.ScriptToBak(src_dr,zip_dr,fileflt);
pkgPreProcess.compare_file(src_dr,dst_dr,zip_dr,fileflt)

--------------------------------------------------------------------------
-- 将当前发布版本正式转存为已发布备份版本到 mainpkg_dir/last/
NPL.load("(gl)script/kids/3DMapSystemApp/Assets/pkgPreProcess.lua");
src_dr=pkgPreProcess.config.curscript_dir;
last_dr=pkgPreProcess.config.lastscript_dir;
fileflt="*.*"
pkgPreProcess.ScriptToBak(src_dr,last_dr,fileflt);

--------------------------------------------------------------------------
-- 生成与上一版本mainYYMMDD.pkg 比较的增量版本 mainYYMMDD.pkg
NPL.load("(gl)script/kids/3DMapSystemApp/Assets/pkgPreProcess.lua");
-- 编译当前 script/*.lua 到 bin/script/*.o
NPL.CompileFiles("script/*.lua", nil, 10); 

-- 备份当前main.pkg 文件到 mainpkg_dir/cur/
pkgPreProcess.GetMainfile(pkgPreProcess.config.mainpkg_lst,pkgPreProcess.config.curscript_dir)

-- 将当前main.pkg 源文件(mainpkg_dir/cur/)比较前版本 main.pkg 源文件(mainpkg_dir/last/)，并删除 mainpkg_dir/temp/ 相同的文件
src_dr=pkgPreProcess.config.curscript_dir;
dst_dr=pkgPreProcess.config.lastscript_dir;
zip_dr=pkgPreProcess.config.tmpscript_dir;
last_dr=pkgPreProcess.config.lastscript_dir;
fileflt="*.*"
pkgPreProcess.ScriptToBak(src_dr,zip_dr,fileflt);
pkgPreProcess.compare_file(src_dr,dst_dr,zip_dr,fileflt)

</verbatim>

call with:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/Assets/pkgPreProcess.lua");
------------------------------------------------------------
]]

if(not pkgPreProcess) then pkgPreProcess={}; end

pkgPreProcess.config = {
	script_dir = "bin/script/",          -- dir of current compiled files for making zip file
	tmpscript_dir = "mainpkg_dir/temp/",  -- dir of current compiled files for comparing 
	curscript_dir = "mainpkg_dir/cur/",  -- dir of current compiled files for comparing 
	lastscript_dir = "mainpkg_dir/last/", -- dir of last ver. published compiled files
	verscript_dir = "mainpkg_dir/ver/",	 -- dir of big ver. published compiled files
	mainpkg_lst= "packages/redist/main_script-1.0.txt" -- source files list of current main.pkg
}

-- compare the file(fileflt) of same name in subdir src_dr, dst_dr, if their crc32 is the same one, delete the file in cur_dr.
function pkgPreProcess.compare_file(src_dr,dst_dr,cur_dr,fileflt)						
	local file_src,file_dst,patternS = "","","";
	local crc_src,crc_dst = "","";
	local pattern = "%*";

	i,j=string.find(fileflt,pattern);
	if (i) then
		patternS = "[.]"..string.sub(fileflt,j+2,string.len(fileflt))
	else
		patternS = fileflt;	
	end;
		
	local files = {};
	local parentDir = Map3DSystem.App.Assets.app:GetAppDirectory();
	commonlib.SearchFiles(files, src_dr, fileflt, 10, 5000, true);
    --commonlib.echo(files);
	
	for i0,dd0 in ipairs(files) do

		file_src=src_dr..dd0;
		file_dst=dst_dr..dd0;		
		file_compile=cur_dr..dd0;
		if (string.find(dd0,patternS) ~= nil ) then 		
			if ParaIO.DoesFileExist(file_dst) then
				crc_src=ParaIO.CRC32(file_src);
				crc_dst=ParaIO.CRC32(file_dst);
				if (crc_src == crc_dst) then
					if ParaIO.DoesFileExist(file_compile) then
						ParaIO.DeleteFile(file_compile);				
					end;	
				end;
			end;
		end;	
	end;   -- for dd0       		
end;

-- backup files(fileflt) in subdir src_dr to dst_dr, if there are files in dst_sr already, delete them first.
function pkgPreProcess.ScriptToBak(src_dr,dst_dr,fileflt)
	local file_src,file_dst,patternS="","","";
	local n=0;
	local pattern="%*";
	
	i,j=string.find(fileflt,pattern);
	if i then
		patternS="[.]"..string.sub(fileflt,j+2,string.len(fileflt))
	else
		patternS=fileflt;	
	end;
	
	commonlib.echo(patternS);
--	commonlib.echo(dst_dr);
	
	if ParaIO.DoesFileExist(dst_dr) then
		local files = {};	
		local parentDir = Map3DSystem.App.Assets.app:GetAppDirectory();
		commonlib.SearchFiles(files, dst_dr, fileflt, 10, 5000, true);
		-- delete old version files
		for i0,dd0 in ipairs(files) do
			if (string.find(dd0,patternS) ~= nil ) then 
	--			ParaIO.DeleteFile(dst_dr..dd0);				
				ParaIO.DeleteFile(dst_dr.."*.*");				
			end;
		end; 
	end;
		
	if not ParaIO.DoesFileExist(dst_dr) then
   		ParaIO.CreateDirectory(dst_dr);
	end;
	
	local files = {};	
	local parentDir = Map3DSystem.App.Assets.app:GetAppDirectory();
	commonlib.SearchFiles(files, src_dr, fileflt, 10, 5000, true);
	
  -- copy to new version files
	for i0,dd0 in ipairs(files) do
		file_src=src_dr..dd0;  			   
		file_dst=dst_dr..dd0;
		if ( string.find(file_dst,patternS) == nil) then
			if not ParaIO.DoesFileExist(file_dst) then
	  			ParaIO.CreateDirectory(file_dst);
			end;	  
		else	
			ParaIO.CopyFile(file_src,file_dst,true);	
			n=n+1;			
		end;	
	end; 	
	return n;
end;

-- from source files list(lstfile) of main.pkg,copy files current main.pkg to dst_dr0
function pkgPreProcess.GetMainfile(lstfile,dst_dr0)
	local fr=ParaIO.open(lstfile,"r");
	local patternStart="%[filterList%]";
	local n0,n1,p1,startID,s_dir,s_file,dst_dr=0,0,0,nil,"","","";

	local lines=fr:readline();
	p1=string.find(lines,patternStart);

	while true do  
		if not lines then break end;
		-- search core file start line
		if (not startID) and (not p1) then
			while true do
				lines=fr:readline();
				p1=string.find(lines,patternStart);
				if p1 then 
				   startID=1;
				   break;
				end;  
			end
		else
			-- get subdir, files of the list 
			i,j=string.find(lines,".*/");			
			s_dir=string.sub(lines,1,j);
			s_file=string.sub(lines,j+1,string.len(lines));	
					
			-- copy current source files to dst_dr0
			dst_dr=dst_dr0..s_dir;
			commonlib.echo(dst_dr);
			
			n1=pkgPreProcess.ScriptToBak(s_dir,dst_dr,s_file);
			n0=n1+n0;			
		end; -- if (not startID) and (not p1)
		lines=fr:readline();
	end;
	fr:close();
	_guihelper.MessageBox("Current main.pkg script files, copy to bin/script_temp/ files, Total:"..n0.."\n");
end;