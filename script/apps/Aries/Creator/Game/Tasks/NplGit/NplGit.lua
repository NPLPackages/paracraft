--[[
Title: NplGit 
Author(s): leio
Date: 2021/3/24
Desc: loading "plugins/nplgit.dll" by luajit ffi
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/NplGit/NplGit.lua");
local NplGit = commonlib.gettable("NplGit");
NplGit.Load();

-- luagit2 api: https://luagit2.readthedocs.io/en/latest/basic/index.html
-- check version
local major,minor,rev = luagit2.libgit2_version();
commonlib.echo({major,minor,rev});


NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/NplGit/NplGit.lua");
local NplGit = commonlib.gettable("NplGit");
NplGit.AddOrUpdateFiles("hello_world", { 
				{ filepath = "test/a.txt" , content = "hello world a" },
				{ filepath = "test/b.txt" , content = "hello world b" },
				{ filepath = "test/test/c.txt" , content = "hello world c" },
			});


NplGit.DeleteFiles("hello_world", { 
				"test/a.txt",
				"test/b.txt",
				"test/test/c.txt"
});
------------------------------------------------------------
--]]
local NplGit = commonlib.gettable("NplGit");
NplGit.is_started = false;
NplGit.gitPath = "git_repo";
NplGit.default_name = "zhangleio";
NplGit.default_email = "zhangleio@outlook.com";

NplGit.system_names = {
	".git"
}
function NplGit.IsSystemFile(filename)
	if(not filename)then
		return
	end
	filename = string.lower(filename);
	for k,name in ipairs(NplGit.system_names) do
		if(name == filename)then
			return true;
		end
	end
end
function NplGit.IsStarted()
	return NplGit.is_started;
end
function NplGit.Start()
	if(NplGit.is_started)then
		return
	end
	if(luagit2)then
		----------------------------------------------------------
		-- The necessary funation call for initializing
		-- Libgit2's global state & threading
		----------------------------------------------------------
		luagit2.init()
		NplGit.is_started = true;
	end
end
function NplGit.Stop()
	if(not NplGit.is_started)then
		return
	end
	if(luagit2)then
		----------------------------------------------------------
		--
		-- Shutdown the libgit2's threading and global state
		----------------------------------------------------------
		luagit2.shutdown()
		NplGit.is_started = false;
	end
end
function NplGit.Load(libName)
	if(NplGit.IsStarted())then
		return
	end
	libName = libName or "plugins/nplgit.dll"
	local nplgit_dev = ParaEngine.GetAppCommandLineByParam("nplgit_dev", true);
	if(nplgit_dev == "true" or nplgit_dev == true)then
		libName = "plugins/nplgit_d.dll"
	end
	if(not ParaIO.DoesFileExist(libName))then
	    LOG.std(nil, "error", "NplGit", "the file isn't existed: %s", libName);
		return
	end
	local use_ffi = jit and jit.version 
	if(not use_ffi)then
		return
	end
	local ffi = require("ffi")
	ffi.cdef([[
	int luaopen_git2_by_int(uint64_t luaState);
	]])


	local function LoadSharedLib(libName)
		local libNamespace;
		local func = loadstring(string.format([[local ffi = require("ffi"); return ffi.load("%s")]], libName));
		if(func) then
			local result, param1 = pcall(func);
			if(result) then
				libNamespace = param1;
			end
		end
		if(libNamespace) then
	        LOG.std(nil, "info", "NplGit", "ffi loaded shared lib: %s", libName);
		else
	        LOG.std(nil, "error", "NplGit", "warn: ffi failed to load shared lib: %s", libName);
		end
		return libNamespace;
	end

	local luagit2_module = LoadSharedLib(libName);

	if(not luagit2_module)then
	    LOG.std(nil, "error", "NplGit", "warn: ffi failed to load shared lib: %s", libName);
		return
	end

	local lua_state = NPL.GetLuaState("",{});
	LOG.std(nil, "info", "NplGit get lua_state", lua_state);
	local r = luagit2_module.luaopen_git2_by_int(lua_state.value);
	if(r ~= 1)then
	    LOG.std(nil, "error", "NplGit", "luaopen_git2_by_int failed");
		return
	end
	if(not luagit2 or not luagit2.libgit2_version)then
	    LOG.std(nil, "error", "NplGit", "luagit2 is nil");
		return
	end
	local major,minor,rev = luagit2.libgit2_version();
	LOG.std(nil, "info", "NplGit", "luagit2 is loaded, the version is: %s", commonlib.serialize({major,minor,rev}));

	NplGit.Start();
end

-- check if .git directory is existed in repopath
-- @repopath: the relative path for root of git_repo
function NplGit.RepoIsExisted(repopath)
	if(not repopath)then
		return
	end
	local path = commonlib.ResolvePath(NplGit.gitPath, repopath, ".git");
	LOG.std(nil, "info", "NplGit.RepoIsExisted", "check path: %s", path);
	local result = ParaIO.DoesFileExist(path .. "/");
	LOG.std(nil, "info", "NplGit.RepoIsExisted", result);
	return result;
end
-- create a new repo
-- @repopath: the relative path for root of git_repo
-- @return true if successful
function NplGit.CreateRepo(repopath)
	if(not repopath)then
		return
	end
	NplGit.Load();
	if(not NplGit.IsStarted())then
		return
	end
	
	if(NplGit.RepoIsExisted(repopath))then
		return
	end
	local path = commonlib.ResolvePath(NplGit.gitPath,repopath);

	local repo = luagit2.repository_init(path, 0);
	LOG.std(nil, "info", "NplGit", "created repo: %s", path);

	----------------------------------------------------------
	-- 
	-- Create an initial commit.
	--
	-- initializing parameters.
	----------------------------------------------------------
	local repo_index = luagit2.repository_index(repo)
	local index_write_tree_oid = luagit2.index_write_tree(repo_index)
	local tree = luagit2.tree_lookup(repo,index_write_tree_oid)
	local author_sign = luagit2.signature_default(repo)
	local committer_sign = luagit2.signature_default(repo)
	-------------------------------------------------------------------------
	--
	-- Creating an initial commit is different as there is no parent commit 
	-- present so, use commit_create_initial() to make an initial commit.
	-------------------------------------------------------------------------
	local new_commit_id = luagit2.commit_create_initial(repo,author_sign,
				committer_sign,"Initial commit",tree) 

	local new_commit_str = luagit2.oid_tostr(new_commit_id)
	LOG.std(nil, "info", "NplGit", "Newly created commit's id: %s", tostring(new_commit_str));

	-- at this point, if you run a git log in the new created
	-- repo, you should see a complete log for initial commit.
	--
	--
	-- must free the used repository, tree & index to prevent
	-- memory leaks
	----------------------------------------------------------
	luagit2.tree_free(tree)
	luagit2.index_free(repo_index)
	luagit2.repository_free(repo)
	return true;
	
end
-- add files to repo
-- @param {string} repopath: the relative path for root of git_repo
-- @param {array} files: the file info list
-- @param {string} item.filepath: 
-- @param {string} item.content: 
-- @return true if successful
function NplGit.AddOrUpdateFiles(repopath,files)
	if(not repopath or not files)then
		return
	end
	if(len == 0)then
		return
	end
	NplGit.Load();
	if(not NplGit.IsStarted())then
		return
	end
	if(not NplGit.RepoIsExisted(repopath))then
		return
	end
	local cur_repopath = commonlib.ResolvePath(NplGit.gitPath, repopath);
	
	-- init
	LOG.std(nil, "info", "NplGit.AddFiles", "luagit2.init");
	luagit2.init()
	-- open repo
	LOG.std(nil, "info", "NplGit.AddFiles", "luagit2.repository_open");
	local repo = luagit2.repository_open(cur_repopath);
	-- get the repository's current index
	local repo_index = luagit2.repository_index(repo)
	LOG.std(nil, "info", "NplGit.AddFiles", "luagit2.repository_index: %s", tostring(repo_index));
	-- add  the files to current index
	local len = #files;
	for k, v in ipairs(files) do
		local filepath = commonlib.ResolvePath(v.filepath);
		local content = v.content or "";
		local dest_filepath = commonlib.ResolvePath(NplGit.gitPath, repopath, filepath)
		LOG.std(nil, "info", "NplGit.AddFiles", "dest_filepath: %s", dest_filepath);
		ParaIO.CreateDirectory(dest_filepath);
		local file = ParaIO.open(dest_filepath, "w");
		if(file:IsValid()) then
			file:write(content,#content);
			file:close();
		end
		LOG.std(nil, "info", "NplGit.AddFiles", "add: %s", filepath);
		luagit2.index_add_bypath(repo_index,filepath);
	end
	-- finally write the added files onto the disk
	luagit2.index_write(repo_index)
	-- push commit
	local message = string.format("changed files:%d", len);
	NplGit.PushCommit(repo, repo_index, message);
	-- free the used repository and index to prevent memory leaks
	luagit2.index_free(repo_index)
	luagit2.repository_free(repo)
	return true
end
-- delete files to repo
-- @param {string} repopath: the relative path for root of git_repo
-- @param {array} files: the filepath  list
-- @return true if successful
function NplGit.DeleteFiles(repopath,files)
	if(not repopath or not files)then
		return
	end
	local len = #files;
	if(len == 0)then
		return
	end
	NplGit.Load();
	if(not NplGit.IsStarted())then
		return
	end
	if(not NplGit.RepoIsExisted(repopath))then
		return
	end
	local cur_repopath = commonlib.ResolvePath(NplGit.gitPath, repopath);
	
	-- init
	LOG.std(nil, "info", "NplGit.DeleteFiles", "luagit2.init");
	luagit2.init()
	-- open repo
	LOG.std(nil, "info", "NplGit.DeleteFiles", "luagit2.repository_open");
	local repo = luagit2.repository_open(cur_repopath);
	-- get the repository's current index
	local repo_index = luagit2.repository_index(repo)
	LOG.std(nil, "info", "NplGit.DeleteFiles", "luagit2.repository_index: %s", tostring(repo_index));
	-- delete files
	for k, v in ipairs(files) do
		local filepath = commonlib.ResolvePath(v);
		local dest_filepath = commonlib.ResolvePath(NplGit.gitPath, repopath, filepath)
		LOG.std(nil, "info", "NplGit.DeleteFiles", "dest_filepath: %s", dest_filepath);
		if(not NplGit.IsSystemFile(filepath))then
			local r = ParaIO.DeleteFile(dest_filepath);
			LOG.std(nil, "info", "NplGit.DeleteFiles", "delete: %s, resutl: %d", dest_filepath, r);
		else
			LOG.std(nil, "waring", "NplGit.DeleteFiles", "can't delete system file:%s",dest_filepath);
		end
		luagit2.index_remove_bypath(repo_index,filepath);
	end
	-- finally write the added files onto the disk
	luagit2.index_write(repo_index)
	-- push commit
	local message = string.format("delete files:%d", len);
	NplGit.PushCommit(repo, repo_index, message);
	-- free the used repository and index to prevent memory leaks
	luagit2.index_free(repo_index)
	luagit2.repository_free(repo)
	return true
end
-- get the latest one log
-- @param {repository} repo: the instance of repository
-- @param {string} name: "HEAD"
-- @return { id_new = id_new, id_old = id_old, message = message, name = name, email = email, }
function NplGit.GetLatestReflog(repo,name)
	name = name or "HEAD"
	if(not repo)then
		return
	end
	local ref_log = luagit2.reflog_read(repo, name);
	if(ref_log)then
		local cnt = luagit2.reflog_entrycount(ref_log)
		if(cnt > 0)then
			-- 0 is the latest index for reflog
			local reflog_entry = luagit2.reflog_entry_byindex(ref_log, 0)
			local id_old = luagit2.reflog_entry_id_old(reflog_entry)
			local id_new = luagit2.reflog_entry_id_new(reflog_entry)
			local message = luagit2.reflog_entry_message(reflog_entry)
			local committer = luagit2.reflog_entry_committer(reflog_entry)

			local name, email = luagit2.get_signature_details(committer)
			local obj = {
				id_new = luagit2.oid_tostr_s(id_new),
				id_old = luagit2.oid_tostr_s(id_old),
				message = message,
				name = name,
				email = email,
			}
			return obj;
		end
	end
end
-- get all logs 
-- @param {repository} repo: the instance of repository
-- @param {string} name: "HEAD"
-- @return result = { { id_new = id_new, id_old = id_old, message = message, name = name, email = email, }, ... }
function NplGit.GetReflogDetails(repo,name)
	name = name or "HEAD"
	if(not repo)then
		return
	end
	local ref_log = luagit2.reflog_read(repo, name);
	if(ref_log)then
		local result = {};
		local cnt = luagit2.reflog_entrycount(ref_log)
		if(cnt > 0)then
			for k = 1, cnt do
				local reflog_entry = luagit2.reflog_entry_byindex(ref_log, k - 1)
				local id_old = luagit2.reflog_entry_id_old(reflog_entry)
				local id_new = luagit2.reflog_entry_id_new(reflog_entry)
				local message = luagit2.reflog_entry_message(reflog_entry)
				local committer = luagit2.reflog_entry_committer(reflog_entry)

				local name, email = luagit2.get_signature_details(committer)

				table.insert(result,{
					id_new = luagit2.oid_tostr_s(id_new),
					id_old = luagit2.oid_tostr_s(id_old),
					message = message,
					name = name,
					email = email,
				});
			end
		end
		return result;
	end

end
function NplGit.GetRepo(repopath)
	if(not repopath)then
		return
	end
	NplGit.Load();
	if(not NplGit.IsStarted())then
		return
	end
	if(not NplGit.RepoIsExisted(repopath))then
		return
	end
	repopath = commonlib.ResolvePath(NplGit.gitPath,repopath);

	local repo = luagit2.repository_open(repopath);
	return repo;
end
function NplGit.PushCommit(repo, repo_index, message)
	if(not repo or not repo_index)then
		return
	end
	local ref_log = NplGit.GetLatestReflog(repo);
	if(not ref_log)then
		return
	end
	local oid = ref_log.id_new;

	local commit_oid = luagit2.oid_fromstr(oid)
	local parent_commit = luagit2.commit_lookup(repo, commit_oid)

	if(not parent_commit)then
		return
	end
	message =  message or "changed"
	local index_write_tree_oid = luagit2.index_write_tree(repo_index)
	local tree = luagit2.tree_lookup(repo,index_write_tree_oid)
	local author_sign = luagit2.signature_default(repo)
	local committer_sign = luagit2.signature_default(repo)
	local new_commit_id = luagit2.commit_create_update_head(
								repo,
								author_sign,
								committer_sign,
								message,
								tree,
								parent_commit
							) 

	local new_commit_str = luagit2.oid_tostr(new_commit_id)
	LOG.std(nil, "info", "NplGit", "pushed commit: %s", new_commit_str);

	luagit2.tree_free(tree)
end


function NplGit.GetFileInfoList(repo)
	if(not repo)then
		return
	end
	local repo_index = luagit2.repository_index(repo)
	local cnt = luagit2.index_entrycount(repo_index);
	local result = {};
	for k = 1 ,cnt do
		local index_entry = luagit2.index_get_byindex(repo_index, k - 1);
		local entry_filemode = luagit2.index_entry_get_filemode(index_entry);
		local entry_filesize = luagit2.index_entry_get_filesize(index_entry);
		local entry_path = luagit2.index_entry_get_path(index_entry);
		local oid = luagit2.index_entry_get_oid_str(index_entry);

		--local entry_stage = luagit2.index_entry_get_stage(index_entry);

--		local dev, ino = luagit2.index_entry_get_dev_inode(index_entry);
--		local uid, gid = luagit2.index_entry_get_UID_GID(index_entry);
--		local blob = luagit2.blob_lookup(repo, luagit2.oid_fromstr(oid));
--		local is_binary = luagit2.blob_is_binary(blob);
--		local buffer = luagit2.blob_rawcontent(blob);
--		local content = luagit2.buf_long_details(buffer)
--		local content_size = luagit2.buf_size(buffer)
		
		table.insert(result,{
			oid = oid,
			filemode = entry_filemode,
			filesize = entry_filesize,
			filepath = entry_path,
		})
	end
	luagit2.index_free(repo_index)

	return result;
end
function NplGit.GetFileRawByRepo(repo, oid)
	if(not repo or not oid)then
		return
	end
	local blob = luagit2.blob_lookup(repo, luagit2.oid_fromstr(oid));
	if(blob)then
		local result;
		local buffer = luagit2.blob_rawcontent(blob);
		if(buffer)then
			local is_binary = luagit2.blob_is_binary(blob);
			local content = luagit2.buf_long_details(buffer)
			local content_size = luagit2.buf_size(buffer);
			result = {
				oid = oid,
				is_binary = is_binary,
				content = content,
				content_size = content_size,
			}
		end
		luagit2.blob_free(blob);
		return result;
	end
end
function NplGit.Test(repopath)
	local repo = NplGit.GetRepo(repopath);
	if(not repo)then
		return
	end
	local fileinfo_list = NplGit.GetFileInfoList(repo)
	echo("================fileinfo_list");
	for k,v in ipairs(fileinfo_list) do
		echo(v);
		local oid = v.oid;
		local filepath = v.filepath;
		local file_raw = NplGit.GetFileRawByRepo(repo, oid)
		if(file_raw)then
			local content = file_raw.content;
			local content_size = file_raw.content_size;
			local test_filename = commonlib.ResolvePath("temp/repo", filepath);
			ParaIO.CreateDirectory(test_filename);
			local file = ParaIO.open(test_filename, "w");
			if(file:IsValid()) then
				echo({ writedto = test_filename });
				file:write(content,content_size);
				file:close();
			end
		end
	end
	luagit2.repository_free(repo)
end

function NplGit.Dump(repopath)
	local repo = NplGit.GetRepo(repopath);
	if(not repo)then
		return
	end
	commonlib.echo("=============ref log latest: HEAD");
	commonlib.echo(NplGit.GetLatestReflog(repo), true);
	commonlib.echo("=============ref log  latest: master");
	commonlib.echo(NplGit.GetLatestReflog(repo,"master"), true);

	commonlib.echo("=============ref log: HEAD");
	commonlib.echo(NplGit.GetReflogDetails(repo), true);
	commonlib.echo("=============ref log: master");
	commonlib.echo(NplGit.GetReflogDetails(repo,"master"), true);



	local ref = luagit2.reference_lookup(repo,"refs/heads/master")
	commonlib.echo("=============ref");
	commonlib.echo(ref,true);

	commonlib.echo("=============reference_is_branch");
	commonlib.echo(luagit2.reference_is_branch(ref));
	
	commonlib.echo("=============reference_is_remote");
	commonlib.echo(luagit2.reference_is_remote(ref));

	commonlib.echo("=============reference_is_tag");
	commonlib.echo(luagit2.reference_is_tag(ref));

	commonlib.echo("=============reference_is_note");
	commonlib.echo(luagit2.reference_is_note(ref));

	local ref_name = luagit2.reference_name(ref);
	commonlib.echo("=============ref_name");
	commonlib.echo(ref_name);
	local ref_id = luagit2.reference_name_to_id(repo, ref_name);
	commonlib.echo("=============ref_id");
	commonlib.echo(ref_id);

	luagit2.reference_free(ref)
	luagit2.repository_free(repo)
end