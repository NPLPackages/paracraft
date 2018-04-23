--[[
Title: code behind page for AssetManifestPage.html
Author(s): LiXizhi, Spring Yan
Date: 2009/10/11  Modified Date: 2010/02/09
Desc: 
<verbatim>
; 如果需要编辑通配符, 格式为:
; [search] aaa/*.x 
; 表示 目录 aaa 下的所有 *.x 文件，包括其子目录下的 *.x 文件。
; [search1] aaa/*.x 
; 表示 目录 aaa 下本级目录所有 *.x 文件，不包括其子目录下的 *.x 文件。
;
; 含 [search] xxx/*.x 的行必须放在 _assetmanifest.ftp.uploader.txt 的顶部。
; 在发布窗口，编辑后按"保存", 程序将自动过滤掉被该通配符包含的其他行, 如 xxx/aaa/a.x 将被滤除, 避免重复上传。

; 本地文件说明：
; _assetmanifest.ftp.uploader.txt: 手工编辑的需上传的 asset 文件列表
; _assetmanifest.ftp.uploader0.txt: _assetmanifest.ftp.uploader.txt 的 copy, 用于本次上传的编辑处理
; _assetmanifest.ftp.list.txt: 当前 ftp 上传后, 在服务器所新创建的目录
; assets_ftp_success.txt: ftp 上传成功日志
; assets.log: 当前 Taraus 操作，所生成的 asset 文件日志
; assets_ftp.log: assets.log 的copy, 用于本次上传的处理
;

</verbatim>

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/Assets/AssetManifestPage.lua");
-------------------------------------------------------
]]

local AssetManifestPage = {};
commonlib.setfield("Map3DSystem.App.Assets.AssetManifestPage", AssetManifestPage)

---------------------------------
-- page event handlers
---------------------------------
local curDir = ParaIO.GetCurDirectory(0);

local config = {
	ftp_address = "192.168.0.228",
	ftp_user = "ftpasset",
	ftp_passwd = "ftpparaengine",	 
	uploadURL="http://192.168.0.228/cgi-bin/upload_asset.sh",
--	ftplistURL="ftp://ftpasset:ftpparaengine@192.168.0.228/ftpsvrlist.txt",	
	ftplistURL="http://192.168.0.228/assetdownload/list/ftpsvrlist.txt",	
	ftplist0URL="http://192.168.0.228/assetdownload/list/ftpsvrlist0.txt"	
}

--[[
local config = {
	ftp_address = "192.168.0.252",
	ftp_user = "ftpuser1",
	ftp_passwd = "123",	 
	uploadURL="http://192.168.0.252/cgi-bin/upload_asset.sh",
	ftplistURL="ftp://ftpuser1:123@192.168.0.252/asset/ftpsvrlist.txt",	
	ftplist0URL="http://192.168.0.252/assetdownload/list/ftpsvrlist0.txt"	
}
]]

--- ftp download a file by url, return the filename as a big string "result"
local function ftpdownload(url)
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

-- get Skip list into array "ds0" from textarea line by line
local function getSkipList(s,ds0)
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
local function getdir(d0,s)
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

-- Search a string "dr" is included in an wildcard string array "ds0", if find return true, otherwise return false
local function IsInFArray(dr,ds0)
	local pattern1="^(.*)/(.*)$";
	local d_1=string.lower(string.gsub(dr,pattern1,"%1")); 
	local d_2=string.lower(string.gsub(dr,pattern1,"%2")); 
	local ii,x_s,x0=0,"",nil;

	for ii,x_s in pairs(ds0) do      
	-- get substring from string "x_s" before last char "/"
		x_s1=string.lower(string.gsub(x_s,pattern1,"%1"));
		x_s2=string.lower(string.gsub(x_s,pattern1,"%2")); -- get suffix of filename x_s
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

-- judge if string "dr" is in array "ds0"(its value as xxx/*.xxx ) , is in big string "s_fr"
-- if string "dr" include filename, and the filename is .*,*.*,*,'', we skip whole "dr" directory 
-- if filename is *.xxx, we skip x_s1/*.xxx  
--   dr: filename with relative path
--   ds0: file pattern array of skip files (its value as xxx/*.xxx )
--   s_fr: bigstring of processing filenames
local function judgeWrite(dr,ds0,s_fr)
	local x0,x=nil,nil;
	local pattern1="^(.*)/(.*)$";
	local d_1=string.gsub(dr,pattern1,"%1"); 
	local d_2=string.gsub(dr,pattern1,"%2"); 
	d_2=string.gsub(d_2,"(.-)%s*","%1");

	if (d_2=="") then
		x=string.find(s_fr,dr);
	end
	x0=IsInFArray(dr,ds0);
	if ((not x) and (not x0)) then
		return true;
	else 
		return false;  
	end;       
end

-- filter search patterns, get directory from bigstring "s_fr" into Array "d_g" 
local function GetMlistToArray(d_g,s_fr)
	local s=s_fr;
	local p1,lines = 0,"";
	local pattern2="^%[search%](.*)/(.*)$";
	local pattern21="^%[search1%](.*)/(.*)$";
	local patternRem="%-%-";	
    local x0,x00,t_s,t_s1=nil,nil,nil,nil;
    
	while true do
		x0,t_s,t_s1=nil,nil,nil;
		p1=string.find(s,"\r");
		if not p1 then break end;
		lines=string.sub(s,1,p1-1);
		t_s=string.find(lines,"%[search%]");
		t_s1=string.find(lines,"%[search1%]");
		t_p=string.find(lines,patternRem);
		if (not t_s) and (not t_s1) and (not t_p) and (lines ~="") then       
            x0=IsInFArray(lines,d_g); 			
		else
			if t_s then  
				lines_g = string.gsub(lines,pattern2,"%1/%2");
				d_g[lines_g]=string.lower(lines_g);
			end;
			if t_s1 then
				lines_g = string.gsub(lines,pattern21,"%1/%2");
				d_g[lines_g]=string.lower(lines_g);
			end;
		end;		
		s=string.sub(s,p1+2);
	end
	lines=s;	
	
	if (not t_s) and (not t_s1) and (not t_p) and (lines ~="") then       
        x0=IsInFArray(lines,d_g); 			
	else
		if t_s then  
			lines_g = string.gsub(lines,pattern2,"%1/%2");
			d_g[lines_g]=string.lower(lines_g);
		end;
		if t_s1 then
			lines_g = string.gsub(lines,pattern21,"%1/%2");
			d_g[lines_g]=string.lower(lines_g);
		end;
	end;		
end

-- According search level, write searched files (not in fs_fr) into fw
-- fw:  file write handle
-- fs_fr: string
-- lines: string
-- level: search level
local function generate_search(fw,fs_fr,lines,patternSearch,level,dd)
	local dr,d0,d00,dd_b="",{},{},{};
	local s,i,j,s_0,ss0,ss1,dn,id_dir,p_dr;
	local patternRem1="%s*([\\-]*)(.*)";
	local f_fn0,w_fn0,w_fn1,w_fn00="","","","";
	local l_filesize=0;
						
	ss0,ss1=string.find(lines,patternSearch);
	s_f=string.sub(lines,ss1+1);     
	d00={};
	getdir(d00,s_f);
	dn=table.getn(d00);
	for i=0,dn-1 do
		dr= "/"..d00[0];
		for j=1,i do
			dr=dr.."/"..d00[j];
		end;         
	end;
	dr=dr.."/";
   
	local files = {};
	--local parentDir = Map3DSystem.App.Assets.app:GetAppDirectory();
	commonlib.SearchFiles(files, dr, d00[dn], level, 5000, true);
    --commonlib.echo(files);

	for i0,dd0 in ipairs(files) do
		d0={};
		id_dir=nil;
		getdir(d0,dd0);
		dn=table.getn(d0);
		for i=0,dn-1 do
			drr=d0[0].."/";
			drr= string.lower(drr);
			if not dd[drr] then 
				dd[drr]=drr;
				p_dr=string.gsub(drr,"%(","%%(");
				p_dr=string.gsub(p_dr,"%)","%%)");
				p_dr=string.gsub(p_dr,"%-","%%-");
				p_dr= "\n"..p_dr;					
				if not string.find(fs_fr,p_dr) then -- if directory "drr" doesnot exist in file ftpsvrlist.txt
					fw:WriteString('mkdir "'..drr..'"\n'); 
				end;	
			end;
			for j=1,i do
				drr=drr..d0[j].."/";
				drr= string.lower(drr);
				if not dd[drr] then 
					dd[drr]=drr;
					p_dr=string.gsub(drr,"%(","%%(");
					p_dr=string.gsub(p_dr,"%)","%%)");
					p_dr=string.gsub(p_dr,"%-","%%-");					
					if not string.find(fs_fr,p_dr) then -- if directory "drr" doesnot exist in file ftpsvrlist.txt
						fw:WriteString('mkdir "'..drr..'"\n');            
					end;	
				end;
			end;  -- for j       
		end; -- for i
	
		dr0=string.gsub(curDir..drr,"/","\\");
		d0[dn] = string.lower(d0[dn]);
		w_fn0=drr..d0[dn];
		f_fn0="";		
		l_filesize=0;
		p_w_fn0="";
		local outlines0 = commonlib.Files.Find({}, "", 1, 1, w_fn0) -- get writedate and filesize of file "w_fn0"
		-- commonlib.echo(w_fn0);
		
		for ii,file0 in pairs(outlines0) do
			if (file0.fileattr~=16) then  -- if w_fn0 not a directory
				id_dir=nil;
				l_filesize=file0.filesize;
				w_fn00=w_fn0.."._dat"..file0.writedate.."_l"..file0.filesize;      -- w_fn00: filename with fullpath add date & filesize
				y=string.match(file0.writedate,"%d+");
				m=string.match(file0.writedate,"%-(%d+)");
				d=string.match(file0.writedate,"%-%d+-(%d+)");			
				hr=string.match(file0.writedate,"%-%d+-%d+-(%d+)");
				min=string.match(file0.writedate,"(%d+)$");
			
			-- make chars such as "(",")","-" in filename "w_fn0" be searched
				p_w_fn0=string.gsub(w_fn0,"%(","%%(");
				p_w_fn0=string.gsub(p_w_fn0,"%.","%%.");
				p_w_fn0=string.gsub(p_w_fn0,"%)","%%)");
				p_w_fn0=string.gsub(p_w_fn0,"%-","%%-");								
				w_fn01=p_w_fn0.."%._dat"..y.."%-"..m.."%-"..d.."%-"..hr.."%-"..min.."_l"..file0.filesize;	-- w_fn01: full filename add date & filesize for string.find()					
			else
				if not dd[w_fn0] then
					dd[w_fn0]=w_fn0;
					if not string.find(fs_fr,p_w_fn0) then -- if directory "w_fn0" doesnot exist in file ftpsvrlist.txt
						fw:WriteString('mkdir "'..w_fn0..'"\n');            
					end;					
				end;
				id_dir=1;
			end;		
		end;			
		if ((not id_dir) and (d0[dn]~="thumbs.db")) then				
			if ((not string.find(fs_fr,w_fn01)) and (l_filesize > 0)) then   -- if file "w_fn00" doesnot exist in file ftpsvrlist.txt
				fw:WriteString('put "'..dr0..d0[dn]..'" "'..w_fn00..'"\n');         
				if string.find(fs_fr,p_w_fn0) then    -- search w_fn0(full path filename) in fs_fr, if find delete the file
				  del_p=p_w_fn0.."%._dat%d+%-%d+%-%d+-%d+-%d+_l%d+";  
				  w_fn1=string.match(fs_fr,del_p);
				  -- commonlib.echo(del_p); 
				  fw:WriteString('delete "'..w_fn1..'"\n');
				end;
			end;	
		end; -- if id_dir	
	end;   -- for dd0       
end;


-- Click "Generate FTP" button, generate ftp script (ftp.txt), and call ftp to upload files to ftpserver, and then call http URL of upload_asset.sh, to generate asset files manifest.
function AssetManifestPage.OnClickGenerateFtp(name, values)
	local dr,d0,dd,dd_b="","",{},{};
	local s,i,j,s_0,t_s,t_s1,p,s0;
	local patternRem1="%s*([\\-]*)(.*)";
	local l_filesize=0;

	s=ftpdownload(config.ftplist0URL); -- get ftpsvrlist0 from httpserver
	if s then
		fs_fr=s;
	else
		fs_fr="";		
	end;

	local cp_id=ParaIO.CopyFile("_assetmanifest.ftp.uploader.txt","_assetmanifest.ftp.uploader0.txt",true);
	if not cp_id then
		commonlib.echo("copy _assetmanifest.ftp.uploader.txt failed!"); 
	end;
			
	local fin = ParaIO.open("_assetmanifest.ftp.uploader0.txt", "r");
	local fw=ParaIO.open("ftp.txt","w");
	local f_fn0,w_fn0,w_fn1,w_fn00="","","","";
	
	if fw then
		fw:WriteString("open "..config.ftp_address.."\n");
		fw:WriteString(config.ftp_user.."\n");
		fw:WriteString(config.ftp_passwd.."\n");

--		fw:WriteString("cd asset\n");
		s0=ftpdownload(config.ftplistURL); -- get ftpsvrlist from ftpserver

		if s0 then -- if download file successfully		
		-- delete all files in ftpserver
			while true do
				p=string.find(s0,"\n");
				if not p then break end;
				lines=string.sub(s0,1,p-1);
				s0=string.sub(s0,p+1);
				if lines~="" then
					d0={};
					dr="";
					getdir(d0,lines);   
					dn=table.getn(d0);
					for i=0,dn-1 do
						dr=d0[0];
						for j=1,i do
							dr=dr.."/"..d0[j];
						end;         
					end;  
					if (dr~="") then
						fw:WriteString('delete "'..dr..'/'..d0[dn]..'"\n');
					else
						fw:WriteString('delete "'..d0[dn]..'"\n');
					end;			
				end;	
			end;
		end; -- if s0 then		
		
		dd={}; -- store all subdirectory path into table "dd", dd[subdir]=subdir
		while true do
			local lines = fin:readline();
			if not lines then break end;
			-- all ftp files are lower cased to prevent duplications. 
			lines = string.lower(lines);
			patternSearch="%[search%]";
			patternSearch1="%[search1%]";
			
			s_0=string.gsub(lines,patternRem1,"%1");
			if (s_0=="") then   -- skip comment line, leading with "--"
				if ( string.match(lines,".*/$") )then
					dd[lines]=lines;
					p_lines=string.gsub(lines,"%(","%%(");
					p_lines=string.gsub(p_lines,"%)","%%)");
					p_lines=string.gsub(p_lines,"%-","%%-");					
					if not string.find(fs_fr,p_lines) then -- if directory "lines" doesnot exist in file ftpsvrlist.txt
						fw:WriteString('mkdir "'..lines..'"\n');
					end;	
				else  
				    t_s=string.find(lines,patternSearch);
				    t_s1=string.find(lines,patternSearch1);
					if ((not t_s) and (not t_s1)) then
						d0={};
						getdir(d0,lines);   
						dn=table.getn(d0);
						for i=0,dn-1 do
							dr= d0[0].."/";
							if not dd[dr] then 
								dd[dr]=dr;
								p_dr=string.gsub(dr,"%(","%%(");
								p_dr=string.gsub(p_dr,"%)","%%)");
								p_dr=string.gsub(p_dr,"%-","%%-");					
								if not string.find(fs_fr,p_dr) then -- if directory "dr" doesnot exist in file ftpsvrlist.txt
									fw:WriteString('mkdir "'..dr..'"\n'); 
								end;	
							end;										
							for j=1,i do
								dr=dr..d0[j].."/";
								if not dd[dr] then 
									dd[dr]=dr;
									p_dr=string.gsub(dr,"%(","%%(");
									p_dr=string.gsub(p_dr,"%)","%%)");
									p_dr=string.gsub(p_dr,"%-","%%-");					
									if not string.find(fs_fr,p_dr) then -- if directory "drr" doesnot exist in file ftpsvrlist.txt
										fw:WriteString('mkdir "'..dr..'"\n');            
									end;	
								end;							
							end;         
						end;  
 					 
						dr0=string.gsub(curDir..dr,"/","\\");
						l_filesize=0;
						p_lines="";
						local outlines0 = commonlib.Files.Find({}, "", 1, 1, lines)    -- get writedate and filesize of file "lines"
						f_fn0,w_fn0,w_fn1="","","";
						for ii,file0 in pairs(outlines0) do
							l_filesize=file0.filesize;
							w_fn0=lines.."._dat"..file0.writedate.."_l"..file0.filesize;
							y=string.match(file0.writedate,"%d+")
							m=string.match(file0.writedate,"%-(%d+)")
							d=string.match(file0.writedate,"%-%d+-(%d+)");			
							hr=string.match(file0.writedate,"%-%d+-%d+-(%d+)");
							min=string.match(file0.writedate,"(%d+)$");
					
							p_lines=string.gsub(lines,"%(","%%(");
							p_lines=string.gsub(p_lines,"%.","%%.");
							p_lines=string.gsub(p_lines,"%)","%%)");
							p_lines=string.gsub(p_lines,"%-","%%-");					
							w_fn1=p_lines.."%._dat"..y.."%-"..m.."%-"..d.."%-"..hr.."%-"..min.."_l"..file0.filesize;	-- full filename with date and filesize for string.find()						
						end;						
					
						if ((not string.find(fs_fr,w_fn1)) and (l_filesize > 0)) then   -- if file "w_fn1" doesnot exist in file ftpsvrlist.txt											    
							fw:WriteString('put "'..dr0..d0[dn]..'" "'..w_fn0..'"\n');
							if string.find(fs_fr,p_lines) then
							  del_p=p_lines.."%._dat%d+%-%d+%-%d+-%d+-%d+_l%d+";  
							  w_fn1=lines..string.match(fs_fr,del_p);
							  fw:WriteString('delete "'..w_fn1..'"\n');
							end;
						end;	
	
					else    -- lines include "[search]", the following processing wildcard files
						if t_s then
							generate_search(fw,fs_fr,lines,patternSearch,10,dd);
						end;
						if t_s1 then
							generate_search(fw,fs_fr,lines,patternSearch1,0,dd);
						end;
					end;  -- if ((not t_s) and (not t_s1))       					
				end;  -- if ( string.match(lines,".*/$") )
			end; --	if (s_0=="") then
		end  --while    
	else
		log(tostring("there is no _assetmanifest.ftp.uploader0.txt!\n"));
	end; 

	fw:WriteString("bye\n");         

	fin:close();
	fw:close();

	log(tostring("uploading assets files to ftp server!\n"));
	
	local date = ParaGlobal.GetDateFormat("yyyyMMdd"); 
	ftppara="-s:"..curDir.."ftp.txt";
	
	if (ParaGlobal.ShellExecute("open", "ftp.exe", ftppara, curDir, 5)) then 
		log(tostring("assets files uploaded successfully !\n"));
		local fw=ParaIO.open("assets_ftp_success.txt","w");
		fw:WriteString("FTP success! "..date);
		fw:close();
	end;      

	local fa=ParaIO.open("_assetmanifest.ftp.list.txt","a");
	local ii,d_r=0,"";
	for ii,d_r in pairs(dd) do
		fa:WriteString(d_r.."\n");
	end;
	fa:close();

--- write success message into asset_ftp_success.txt
--[[
	local today = ParaGlobal.GetDateFormat("yyyyMMdd"); 
	local ff0=ParaIO.open("assets_ftp_success.txt","r");
	local ff0_s=ff0:GetText();
    ff0:close();	
	local x=string.find(ff0_s,today);
	if x then
		_guihelper.MessageBox("ftp assets files sucessfully!");
	else  
		_guihelper.MessageBox("ftp assets files failed!");
	end;
]]

	ParaGlobal.ShellExecute("open", "iexplore.exe", config.uploadURL,"", 1);
	
--[[	_guihelper.MessageBox("Do you want to generate zip files on server & generate new ftp filelist, now?", function()
	if (ParaGlobal.ShellExecute("open", "iexplore.exe", config.uploadURL,"", 1)) then
			_guihelper.MessageBox("Generate assets full list & copy files to publish URL in Server sucessfully!");	
		end;
	end);
]]
end