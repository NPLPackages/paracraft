--[[
Title: code behind page for coreManifestPage.html
Author(s): Spring Yan
Date: 2009/10/11  Modified Date: 2010/03/14
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/test/coreManifestPage.lua");
-------------------------------------------------------
]]

if(not coreManifestPage) then coreManifestPage = {}; end
--local coreManifestPage = {};
commonlib.setfield("Map3DSystem.Test.coreManifestPage", coreManifestPage);

---------------------------------
-- page event handlers
---------------------------------
local curDir = ParaIO.GetCurDirectory(0);
local config = {
	ftp_address = "192.168.0.228",
	ftp_user = "ftpuser1",
	ftp_passwd = "ftpparaengine",	 
	uploadURL="http://192.168.0.228/cgi-bin/upload2.sh",
--	ftplistURL="ftpcorelist.txt",
--	ftplistURL="ftp://ftpuser1:ftpparaengine@192.168.0.228/ftpcorelist.txt",
	ftplistURL="http://192.168.0.228/coredownload/list/ftpcorelist.txt",
	curverURL="http://192.168.0.228/coredownload/version.txt",
	curAssetListURL="http://192.168.0.228/assetdownload/list/full.txt",
	clientprog="ParaEngineClient.exe",
	updateprog="AutoUpdater.dll",
	corelist="Aries_installer_v1.txt",
	outfile="_coremanifest.ftp.uploader.txt"  
}

--- ftp download a file by url, return the filename as a big string "result"
function coreManifestPage.ftpdownload(url)
	local fw_lst=ParaIO.open("ftpdown_cmd.txt","w");
	local result;
	if fw_lst then
		fw_lst:WriteString("open "..config.ftp_address.."\n");
		fw_lst:WriteString(config.ftp_user.."\n");
		fw_lst:WriteString(config.ftp_passwd.."\n");
		fw_lst:WriteString("get ftpcorelist.txt\n");				
	else
		log(tostring("there is no getcoreftplist.txt!\n"));
	end; 
	fw_lst:WriteString("bye\n");         
	fw_lst:close();
	
	local ftppara="-s:"..curDir.."ftpdown_cmd.txt";
	if (ParaGlobal.ShellExecute("open", "ftp.exe", ftppara, curDir, 5)) then 
		log(tostring("ftpdown_cmd download successfully !\n"));
	end;  	
	
    local fin=ParaIO.open(curDir..url,"r");
    result=fin:read("*all");
    fin:close();
--[[
	luaopen_cURL();
	local c = cURL.easy_init()
	local result;
	
	c:setopt_url(url);
	c:perform({writefunction = function(str) 
		if(result) then
			result = result..str;
		else
			result = str;
		end	
	end});
]]	
	return result;
end;

--- http download a file by url, return the filename as a big string "result"
function coreManifestPage.httpdownload(url)
	luaopen_cURL();
	local c = cURL.easy_init()
	local result;
	
	c:setopt_url(url);
	c:perform({writefunction = function(str) 
		if(result) then
			result = result..str;
		else
			result = str;
		end	
	end});
	return result;
end;

-- calculate minutes of y(year),m(month),d(day), hr(hour),min(minutes)
function coreManifestPage.getmin(y,m,d,hr,min)
	local result=0;	  
	local m0={31,28,31,30,31,30,31,31,30,31,30,31}; 
	local m1={31,29,31,30,31,30,31,31,30,31,30,31}; -- leap year
	
	if ((y/4)~=math.floor(y/4)) then  -- if y is leap year
		result=y*365*24*60;
		for i=1,m do 
			result=result+m0[i]*24*60;
		end;
		result=result+d*24*60+hr*60+min;
	else
		result=y*366*24*60;
		for i=1,m do 
			result=result+m1[i]*24*60;
		end;
		result=result+d*24*60+hr*60+min;
	end;
	return result;
end;

-- get Skip list into array "ds0" from textarea line by line
function coreManifestPage.getSkipList(s)
	local a,n=s,0;
	while true do
		s1=string.find(a,"\r");
		if not s1 then break end;
		s2=string.sub(a,1,s1-1);
		a=string.sub(a,s1+2);
		ds0[n]=s2;
		n=n+1;
	end
	ds0[n]=a;
end

-- From a string such as; aa/bb/cc/dd.txt, get directory into array d0{}
function coreManifestPage.getdir(d0,s)
	local a,n=s,0;
	while true do
		s1=string.find(a,"/");
		if not s1 then break end;
		s2=string.sub(a,1,s1-1);
		a=string.sub(a,s1+1);
		d0[n]=s2;
		n=n+1;
	end;
	d0[n]=a;
end

-- Search a string "dr" in an array "ds0", if find return true, otherwise return false
function coreManifestPage.IsInFArray(dr,ds0)
	local pattern1="^(.*)/(.*)$";
	local d_1=string.lower(string.gsub(dr,pattern1,"%1")); 
	local d_2=string.lower(string.gsub(dr,pattern1,"%2")); 
	local ii,x_s,x0=0,"",nil;

	for ii,x_s in pairs(ds0) do      
	-- get substring from string "x_s" before last char "/"
		x_s1=string.lower(string.gsub(x_s,pattern1,"%1"));
		x_s2=string.lower(string.gsub(x_s,pattern1,"%2"));
		if ((x_s2==".*") or (x_s2=="*") or (x_s2=="*.*") or (x_s2=="")) then
			if string.find(dr,x_s1) then
				x0=1;
				break;
			end   
		else
			if string.find(x_s2,"*") then
				x_s2=string.sub(x_s2,2)
			end;
			if (string.find(d_1,x_s1) and string.find(d_2,x_s2)) then
				x0=1;
				break;
			end;
			if (d_2=="") then
				if (string.find(d_1,x_s1)) then
					x0=1;
					break;
				end;
			end;			
		end  
	end;  
	if (not x0) then
		return false
	else
		return true
	end;  	
end

-- judge if string "dr" is in array "ds0"(its value as xxx/*.xxx ) , is in string "s_fr"
-- if string "dr" include filename, and the filename is .*,*.*,*,'', we skip whole "dr" directory 
-- if filename is *.xxx, we skip x_s1/*.xxx
--   dr: filename with relative path
--   ds0: file pattern array of skip files (its value as xxx/*.xxx )
--   s_fr: bigstring of processing filenames  
function coreManifestPage.judgeWrite(dr,ds0,s_fr)
	local x0,x=nil,nil;
	local pattern1="^(.*)/(.*)$";
	local d_1=string.gsub(dr,pattern1,"%1"); 
	local d_2=string.gsub(dr,pattern1,"%2"); 
	d_2=string.gsub(d_2,"(.-)%s*","%1");

	if (d_2=="") then
		x=string.find(s_fr,dr);
	end
	x0=coreManifestPage.IsInFArray(dr,ds0);
	if ((not x) and (not x0)) then
		return true;
	else 
		return false;  
	end       
end

-- first time init page
function coreManifestPage.OnInit()
	local self = document:GetPageCtrl();

	do
		-- do not download now: 2014.11.13   LiXizhi
		return;
	end

	local ver0=coreManifestPage.httpdownload(config.curverURL); -- get current ver. from httpserver
	local vers="";
	vers=string.match(ver0 or "","<UpdateVersion>\n(.*)\n</UpdateVersion>");
	self:SetValue("vercore0", vers);
	self:SetValue("vercore", vers);  
  	
  self:SetValue("getlist", "Downloading installer/Aries/Assets_manifest0.txt ...");
  local assetList=coreManifestPage.httpdownload(config.curAssetListURL); --get current asset files full list
  local assetFile="installer/Aries/Assets_manifest0.txt";
  local fw = ParaIO.open(assetFile, "w");
	fw:WriteString(assetList);
	fw:close();
--	commonlib.echo(assetList);
  assetList=nil;  	
  self:SetValue("getlist", "Downloaded installer/Aries/Assets_manifest0.txt successfull!");
  		
	local fin = ParaIO.open("_coremanifest.ftp.uploader.txt", "r");
	if not fin then
	  commonlib.echo("cannot open _coremanifest.ftp.uploader.txt!");	
	else
		local flists="";
		while true do
		  local lines =fin:readline();
		  if not lines then break end;
		  flists=flists..lines.."\r";
	  end  
		self:SetValue("coreflist", flists);      
	end;
	fin:close();
	
	local y,m,d,hr,min,tf1,tf2=0,0,0,0,0,0,0;
	local ft0 = commonlib.Files.Find({}, "", 1, 1, config.clientprog);
	for ii,file0 in pairs(ft0) do
		y=string.match(file0.writedate,"%d+")
		m=string.match(file0.writedate,"%-(%d+)")
		d=string.match(file0.writedate,"%-%d+-(%d+)");			
		hr=string.match(file0.writedate,"%-%d+-%d+-(%d+)");
		min=string.match(file0.writedate,"(%d+)$");
	end;			
--	commonlib.echo({ft0});
	tf1=coreManifestPage.getmin(y,m,d,hr,min);
	
	local ft1 = commonlib.Files.Find({}, "", 1, 1, config.updateprog);
	for ii,file0 in pairs(ft1) do
		y=string.match(file0.writedate,"%d+")
		m=string.match(file0.writedate,"%-(%d+)")
		d=string.match(file0.writedate,"%-%d+-(%d+)");			
		hr=string.match(file0.writedate,"%-%d+-%d+-(%d+)");
		min=string.match(file0.writedate,"(%d+)$");
	end;	
--	commonlib.echo({ft1});
	tf2=coreManifestPage.getmin(y,m,d,hr,min);
--	commonlib.echo(tf1.."|"..tf2);	
	if tf2<tf1 then
		_guihelper.MessageBox("Warning: AutoUpdate.dll is older than ParaEngineClient.exe !!!");	
	end;
	
end

-- compile file
function coreManifestPage.OnClickCompile(name, values)
	NPL.DoString(values.compileSrcCode);
end

function coreManifestPage.OnClickMakeAriesFile()
	NPL.load("(gl)script/installer/BuildParaWorld.lua");
	commonlib.BuildParaWorld.BuildAries();
end

function coreManifestPage.OnClickMakeSDKFile()
	NPL.load("(gl)script/installer/BuildParaWorld.lua");
	commonlib.BuildParaWorld.BuildTaurus();
end


function coreManifestPage.OnClickMakeSrcComplete()
	NPL.load("(gl)script/installer/BuildParaWorld.lua");
	local error_count = commonlib.BuildParaWorld.BuildSrcComplete();

	_guihelper.MessageBox(format("error_count: %d. main_src.pkg generated", error_count or 0), function()
		local absPath = string.gsub(ParaIO.GetCurDirectory(0).."installer/", "/", "\\");
		ParaGlobal.ShellExecute("open", "explorer.exe", absPath, "", 1);
	end)
end


function coreManifestPage.OnClickMakeCompleteFile()
	NPL.load("(gl)script/installer/BuildParaWorld.lua");
	local error_count = commonlib.BuildParaWorld.BuildComplete();
	if(ParaIO.DoesFileExist("installer/publish_main_full_to_AB.bat")) then
		ParaGlobal.ShellExecute("open", "installer\\publish_main_full_to_AB.bat", "", "", 1);
		_guihelper.MessageBox(format("error_count: %d. main_full.pkg已经生成并覆盖好了，请上传AB. by installer/publish_main_full_to_AB.bat", error_count or 0), function()
			local absPath = string.gsub(ParaIO.GetCurDirectory(0).."installer/", "/", "\\");
			ParaGlobal.ShellExecute("open", "explorer.exe", absPath, "", 1);
		end)
	end
end
function coreManifestPage.OnClickMakeMobileScript()
	NPL.load("(gl)script/installer/BuildParaWorld.lua");
	local error_count = commonlib.BuildParaWorld.BuildComplete_Mobile();
	_guihelper.MessageBox(format("error_count: %d. main_full_mobile.pkg已经生成并覆盖好了，请上传AB. ", error_count or 0), function()
		local absPath = string.gsub(ParaIO.GetCurDirectory(0).."installer/", "/", "\\");
		ParaGlobal.ShellExecute("open", "explorer.exe", absPath, "", 1);
	end)
end

function coreManifestPage.OnClickMakeMobileRes()
	NPL.load("(gl)script/installer/BuildParaWorld.lua");
	local error_count = commonlib.BuildParaWorld.MakeZipPackage({"main_mobile_res"}) or 0;
	commonlib.BuildParaWorld.EncryptZipFiles({"main_mobile_res"});
	_guihelper.MessageBox(format("error_count: %d. main_mobile_res.pkg已经生成并覆盖好了，请上传AB. ", error_count or 0), function()
		local absPath = string.gsub(ParaIO.GetCurDirectory(0).."installer/", "/", "\\");
		ParaGlobal.ShellExecute("open", "explorer.exe", absPath, "", 1);
	end)
end

function coreManifestPage.OnClickCleanupBuild()
	NPL.load("(gl)script/ide/Files.lua");
	local root_folder = "bin/script/";
	local result = commonlib.Files.Find({}, "bin/script", 20, 50000, "*.o")
	-- delete old version files
	for _, file in ipairs(result) do
		ParaIO.DeleteFile(root_folder..file.filename);
	end; 
	_guihelper.MessageBox(format("%d files cleaned up", #result));
end

-- user clicks the button. 
function coreManifestPage.OnClickGenerate(name, values)
	local s=values.vercore0;
	
	config.corelist = values.srcfile;
	
	local patternPath="SetOutPath";
	local patternPath_I="INSTDIR\\(.*)%s";
	local patternFile="File";
	local patternStart="Core ParaEngine";
	local patternEnd="Post setup";
	local patternRem1="^(%s+);--"
	local patternRem2="^(%s+)#";
	local patternRem3="^(%s+);";
	local pattern_x="(.*)\\(.*)(%s+);pefile=(%d+)"    -- pattern of filename with wildcard
	local patternFile_oname="oname=";
	local patternFile_r="/r";
	local patternFile_x="/x";
	local patternFile_o1="(.*)oname=([0-9A-Za-z_\\/]*)%.([0-9A-Za-z_\\.]*)%s*(.*)";
	local patternFile_x1="(.*)/x%s*(%*.%l*)%s*(.*)";
	local patternFile_r1="(.*)/r%s*(.*)";
	local fr=ParaIO.open(config.corelist,"r");
	local lpath="";
	
	if fr then
		local fw=ParaIO.open("version.txt","w");
		fw:WriteString("ver="..s.."\n");
		fw:close();

		local fw=ParaIO.open(config.outfile,"w");
		local p1,p2,startID=0,0,nil;

		while true do  
			local lines=fr:readline();
			if not lines then break end;
			p1=string.find(lines,patternStart);
			if string.find(lines,patternEnd) then break end;
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
				p1_r1=string.find(lines,patternRem1);
				p1_r2=string.find(lines,patternRem2);
				p1_r3=string.find(lines,patternRem3);
				if ((not p1_r1) and (not p1_r2) and (not p1_r3)) then   -- if not rem line
					if string.find(lines,patternPath) then
						lpath=string.match(lines,patternPath_I)
						if not lpath then
						  lpath="";
						end;  
						commonlib.echo(lpath);
					end;
					p2=string.find(lines,patternFile);  
					if p2 then                -- search include File line
						p2_1=string.find(lines,patternFile_oname);
						p2_r1=string.find(lines,patternFile_r);
						p2_r2=string.find(lines,patternFile_x);
						if (not p2_1) and (not p2_r1) then
							s=string.sub(lines,p2+5);
							fw:WriteString(s.."\n");
						end;
						if p2_1 then   -- include "oname="
							if not string.find(lines,"release_enUS.txt") then
								lines=string.gsub(lines,'"',"");
								s_0=string.gsub(lines,patternFile_o1,"%2.%3");
								s_1=string.gsub(lines,patternFile_o1,"%4");
								s_1=string.gsub(s_1,"(.-)%s*","%1");
								commonlib.echo(s_0);
								if (lpath~="") then
									fw:WriteString("oname="..lpath.."\\"..s_0.." "..s_1.."\n");
								else
									fw:WriteString("oname="..s_0.." "..s_1.."\n");
								end;	
							end  
						end;
						if p2_r1 then  -- include "/r" means searching files in all subdir
							lines=string.gsub(lines,'"',"");
							local files = {};
							local s_0,dr_d,dr_f="","","";
							if p2_r2 then     	-- "/x" means not include files like 
								s_0=string.gsub(lines,patternFile_x1,"%2");
								s_1=string.gsub(lines,patternFile_x1,"%3");
								dr_d=string.gsub(s_1,pattern_x,"%1").."\\";
								dr_f=string.gsub(s_1,pattern_x,"%2");     
								dr_f=string.gsub(dr_f,"%s","");
								dr_ftype=string.gsub(s_1,pattern_x,"%4");
							else
								s_1=string.gsub(lines,patternFile_r1,"%2");  
								dr_d=string.gsub(s_1,pattern_x,"%1").."\\";
								dr_f=string.gsub(s_1,pattern_x,"%2");
								dr_f=string.gsub(dr_f,"%s","");
								dr_ftype=string.gsub(s_1,pattern_x,"%4");
							end;
							--commonlib.echo(s_1.."|"..dr_d.."|"..dr_f.."|"..dr_ftype);
							
							commonlib.SearchFiles(files, dr_d, dr_f, 5, 1000, true);
							for ii,d_f in ipairs(files) do
								d_f=string.gsub(d_f,"/","\\");
								if string.find(s_0,"*") then  -- include "/x" option
									c_0=string.sub(s_0,2);  -- get suffix of s_0 ( exclude files )
									local p_c="(.*)%.(.*)";
									if (string.gsub(d_f,p_c,"%2")~=c_0) then -- if d_f isnot suffix of exclude file
										if (not string.find(d_f,"%.")) then  -- if d_f is a subdir
											fw:WriteString(dr_d..d_f.."\\\n");     			      
										else
											fw:WriteString(dr_d..d_f.." ;pefile="..dr_ftype.."\n");
										end;  
									end;
								else
									if (not string.find(d_f,"%.")) then
										fw:WriteString(dr_d..d_f.."\\\n");     			      
									else
										fw:WriteString(dr_d..d_f.." ;pefile="..dr_ftype.."\n");
									end;	
								end;  
							end; --for ii,d_f
						end; -- if p2_r1
					end;  -- if p2  
				end;   -- if (not p1_r1) and (not p1_r2) and (not p1_r3)		
			end; -- if (not startID) and (not p1)
		end; -- while

		fw:close();

	else
		commonlib.echo("aries.nsi not exist!");  
	end;  -- if fr

	fr:close();  

	-- update textarea of tab "publish"
	local page = document:GetPageCtrl();

	local fin = ParaIO.open("version.txt", "r");
	if not fin then
		commonlib.echo("cannot open _coremanifest.ftp.uploader.txt!");	
	else	
		local vers="";
		while true do
			local lines =fin:readline();
			if not lines then break end;
			vers=string.gsub(lines,"ver=(.*)","%1");
		end;
		page:SetValue("vercore", vers);  
	end;
	-- fin:close(); 

	local fin = ParaIO.open("_coremanifest.ftp.uploader.txt", "r");
	if not fin then
		commonlib.echo("cannot open _coremanifest.ftp.uploader.txt!");	
	else
		local flists="";
		while true do
			local lines =fin:readline();
			if not lines then break end;
			flists=flists..lines.."\r";
		end;	
		page:SetValue("coreflist", flists);  
	end;
	fin:close();   

	--	local page0 = document:GetPageCtrl();   
	_guihelper.MessageBox("_coremanifest.ftp.uploader.txt is generated successfully, please goto publish tab to modify or upload these files!");

end


-- save modified textarea contents into file "_assetmanifest.ftp.uploader.txt"
function coreManifestPage.OnClickSaveFile(name, values)
	local s=values.coreflist;   
	local p1,lines,x_s = 0,"","";
	local fw=ParaIO.open("_coremanifest.ftp.uploader.txt","w");
	local d_g={};
	local pattern1="^(.*)/(.*)$";
	local pattern2="^%[search%] (.*)/(.*)$";
  
	while true do
		local x0=nil;
		p1=string.find(s,"\r");
		if not p1 then break end;
		if (not string.find(s,"%[search%]")) then       
			lines=string.sub(s,1,p1-1);
            x0=IsInFArray(lines,d_g); 			
			if (not x0) then
				fw:WriteString(lines.."\n");
			end	
		else
			lines=string.sub(s,1,p1-1);	
			lines_g = string.gsub(lines,pattern2,"%1/%2");
			d_g[lines_g]=lines_g;
			fw:WriteString(lines.."\n");
		end;		
		s=string.sub(s,p1+2);
	end
	lines=s;
	
	x0=IsInFArray(lines,d_g);
	if (not x0) then
		fw:WriteString(lines.."\n");
	end	

	fw:close();

-- update textarea of tab "publish"
	local fin = ParaIO.open("_coremanifest.ftp.uploader.txt", "r");
	if not fin then
		commonlib.echo("cannot open _coremanifest.ftp.uploader.txt!");	
	end;
	local flists="";
	while true do
		local lines =fin:readline();
		if not lines then break end;
		flists=flists..lines.."\r";
	end;
	fin:close();   

	local page = document:GetPageCtrl();
	page:SetValue("coreflist", flists);  
	_guihelper.MessageBox("_coremanifest.ftp.uploader.txt is saved successfully");
end


-- call ftp_s.lua to upload files to ftp server
function coreManifestPage.OnClickGenerateFtp(name, values)

	local fin = ParaIO.open("_coremanifest.ftp.uploader.txt", "r");
	local fw=ParaIO.open("coreftp.txt","w");
	local patternFile_oname="oname=";
	local dr,d0,dd,dd_b="","",{},{};
	local s,i,j;

	if fw then
		fw:WriteString("open "..config.ftp_address.."\n");
		fw:WriteString(config.ftp_user.."\n");
		fw:WriteString(config.ftp_passwd.."\n");
	    fw:WriteString("delete ftpcorelist.txt \n");
	    	
--		s=coreManifestPage.ftpdownload(config.ftplistURL); -- get ftpcorelist from ftpserver
		s=coreManifestPage.httpdownload(config.ftplistURL); -- get ftpcorelist from ftpserver
		
		dd={}; -- store all subdirectory path of ftplist into table "dd", dd[subdir]=subdir

		if s then -- if download file successfully
		
		   commonlib.echo(s);
		    
		-- delete all files in ftpserver
			while true do
				p=string.find(s,"\n");
				if not p then break end;
				lines=string.sub(s,1,p-1);
				s=string.sub(s,p+1);
				if lines~="" then
					d0={};
					dr="";
					coreManifestPage.getdir(d0,lines);   
					dn=table.getn(d0);
					for i=0,dn-1 do
						dr=d0[0];
						for j=1,i do
							dr=dr.."/"..d0[j];
						end;         
						if not dd[dr] then
						  dd[dr]=dr;		  
						end;  
					end;  
					if (dr~="") then
						fw:WriteString("delete "..dr.."/"..d0[dn].."\n");
					else
						fw:WriteString("delete "..d0[dn].."\n");
					end;			
				end;	
			end;

			dd_b={}; -- transfer table dd[subdir]=subdir into table dd_b[n]=subdir, use id instead of string key
			dn=0; -- caculate number of subdirectories
			s="__"; -- transfer table dd to a big string s, each item separate with "__". use to search quickly.
			for ii,ai in pairs(dd) do
				dn=dn+1;
				dd_b[dn]=ai;
				s=s..ai.."__";
			end;
			
			i=1;  
			j=1; -- loop number
			
			-- generate ftpscript: delete all subdirectory in ftpserver
			while (dn>0) do -- if table dd_b not null
			   p0="__"..dd_b[i].."__";
			   s0=string.gsub(s,p0,"__=__");  -- use "__=__" to replace searched subdir
			   if (not string.find(s0,dd_b[i])) and (dd_b[i]~="#") then
					fw:WriteString("rmdir "..dd_b[i].."\n"); 
					s=s0;
					dd_b[i]="#";  -- when delete the subdir, make a mark of letting its dd_b[i]="#"
					if (j==dn) then break end;
					j=j+1;
					i=0;
			   end;
			   i=i+1;
			end;
		end; -- if s then

		dd={}; -- store all subdirectory path of corefile manifest into table "dd", dd[subdir]=subdir
		while true do
			local lines = fin:readline();
			if not lines then break end;
			-- all ftp files are lower cased to prevent duplications. 
			lines = string.lower(lines);
			patternSearch="%[search%]";

		  commonlib.echo(lines);
			
			if ( string.match(lines,".*/$") ) then
				dd[lines]=lines;
				fw:WriteString("mkdir "..lines.."\n");
			else  
				if not string.find(lines,patternSearch) then
				  local file_type="";
					if string.find(lines,patternFile_oname) then
					  r_name=string.match(lines,"oname=(.+)%s");     							--remote filename
					  l_name,file_type=string.match(lines,"%s(.+);pefile=(%d+)"); --local filename, filetype (0,1,2)
					else
					  r_name,file_type=string.match(lines,"(.+);pefile=(%d+)");
					  l_name=r_name;
					end;
					r_name=string.gsub(r_name,"%s","");
					l_name=string.gsub(l_name,"%s","");

 				  commonlib.echo(l_name.."|"..file_type);

					r_name=string.gsub(r_name,"\\","/"); -- change "\" to "/" in r_name
					d0={};
					coreManifestPage.getdir(d0,r_name);   -- get subdir of r_name to array d0
					dn=table.getn(d0);
					for i=0,dn-1 do
						dr= d0[0];
						for j=1,i do
							dr=dr.."/"..d0[j];
						end;         						
						if not dd[dr] then
						  dd[dr]=dr;
						  fw:WriteString("mkdir "..dr.."\n");  -- create subdir level by level
						end;  
					end;
					dr0=string.gsub(curDir..l_name,"/","\\"); -- get full path of l_name
					
					r_name=r_name.."._P_E_"..file_type;   -- add filetype to r_name
					
					if not dr then
						fw:WriteString("put "..dr0.." "..r_name.."\n");
					else  
						fw:WriteString("put "..dr0.." "..r_name.."\n");
					end;  
				else    
					ss0,ss1=string.find(lines,patternSearch);
					s_f=string.sub(lines,ss1+2);     
					d0={};
					coreManifestPage.getdir(d0,s_f);
					dn=table.getn(d0);
					for i=0,dn-1 do
						dr= "/"..d0[0];
						for j=1,i do
							dr=dr.."/"..d0[j];
						end;         
					end;
					dr=dr.."/";

					local files = {};
					commonlib.SearchFiles(files, dr, d0[dn], 5, 1000, true);
					for i,dd0 in ipairs(files) do
						d0={};
						coreManifestPage.getdir(d0,dd0);
						dn=table.getn(d0);
						for i=0,dn-1 do
							drr= d0[0].."/";
							drr= string.lower(drr);
							if not dd[drr] then 
								dd[drr]=drr;
								fw:WriteString("mkdir "..drr.."\n"); 
							end;
							for j=1,i do
								drr=drr..d0[j].."/";
								drr= string.lower(drr);
								if not dd[drr] then 
									dd[drr]=drr;
									fw:WriteString("mkdir "..drr.."\n");            
								end;
							end;  -- for j       
						end; -- for i

						dr0=string.gsub(curDir..drr,"/","\\");
						d0[dn]=string.lower(d0[dn]);
						fw:WriteString("put "..dr0..d0[dn].." "..drr..d0[dn].."\n");         
					end;   -- for dd0       
				end;  -- if        
			end;  -- if p1==p2
		end  --while    
	else
		log(tostring("there is no _coremanifest.ftp.uploader.txt!\n"));
	end; 

	fw:WriteString("bye\n");         

	fin:close();
	fw:close();

--- ftp upload core files to LAN ftp svr 228
	log(tostring("uploading core files to ftp server!\n"));
	local date = ParaGlobal.GetDateFormat("yyyyMMdd"); 
	local ftppara="-s:"..curDir.."coreftp.txt";
	if (ParaGlobal.ShellExecute("open", "ftp.exe", ftppara, curDir, 5)) then 
		log(tostring("core files uploaded successfully !\n"));
		local fw=ParaIO.open("core_ftp_success.txt","w");
		fw:WriteString("FTP success! "..date);
		fw:close();
	end;      

	fa=ParaIO.open("_coremanifest.ftp.list.txt","a");
	local ii,d_r=0,"";
	for ii,d_r in pairs(dd) do
		fa:WriteString(d_r.."\n");
	end;
	fa:close();
		
--- write success message into asset_ftp_success.txt
	local today = ParaGlobal.GetDateFormat("yyyyMMdd"); 
	local ff0=ParaIO.open("core_ftp_success.txt","r");
	local ff0_s=ff0:GetText();
    ff0:close();	
	local x=string.find(ff0_s,today);
	if x then
		_guihelper.MessageBox("ftp core files sucessfully!");
	else  
		_guihelper.MessageBox("ftp core files failed!");
	end;

-- call url to run upload2.sh and generate zip files & patch list on web server
	_guihelper.MessageBox("Do you want to generate zip files on server, now?", function()
	if (ParaGlobal.ShellExecute("open", "iexplore.exe", config.uploadURL,"", 1)) then
			_guihelper.MessageBox("Generate assets full list & copy files to publish URL in Server sucessfully!");	
		end;
	end);

end