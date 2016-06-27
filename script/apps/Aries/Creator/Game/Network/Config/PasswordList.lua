--[[
Title: PasswordList
Author(s): LiXizhi
Date: 2014/6/27
Desc: user passwords are stored here. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Network/Config/PasswordList.lua");
local PasswordList = commonlib.gettable("MyCompany.Aries.Game.Network.PasswordList");
local passwordList = PasswordList:new():Init();
passwordList:AddUser("LiXizhi", "1");
passwordList:AddUser("用户名", "密码");
if(passwordList:CheckUser("LiXizhi", "1") and passwordList:HasUser("用户名")) then
	echo("correct")
end
echo(passwordList:CheckUser("test", "1"));
passwordList:SaveToFile();
-------------------------------------------------------
]]
local PasswordList = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Network.PasswordList"));

function PasswordList:ctor()
	-- array of usernames. 
	self.filename = "config/ParaCraft/password.txt";
	self.theUserNameList = commonlib.UnorderedArraySet:new();
	self.password_map = {};
end

-- Sets the NetHandler. Server-only.
function PasswordList:Init(filename)
	self.filename = filename or self.filename;
	self:LoadPasswordList();
	return self;
end

function PasswordList:IsEmpty()
	return self.theUserNameList:empty();
end

-- return true if user and password match. 
function PasswordList:CheckUser(username, password)
	if(username and password and self.password_map[username] == password) then
		return true;
	end
end

-- return true if user exist
function PasswordList:HasUser(username)
	if(username and self.password_map[username]) then
		return true;
	end
end

-- it will add user or change password of existing user. 
function PasswordList:AddUser(username, password)
	if(username and password) then
		self.theUserNameList:add(username);
		self.password_map[username] = password;
		self:SetModified()
	end
end

function PasswordList:SetModified()
	self.isModified = true;

	NPL.load("(gl)script/ide/timer.lua");

	self.mytimer = self.mytimer or commonlib.Timer:new({callbackFunc = function(timer)
		self:SaveToFile();
	end})
	self.mytimer:Change(2000, nil);
end

-- it will add user or change password of existing user. 
function PasswordList:RemoveUser(username)
	if(self:HasUser(username)) then
		self.theUserNameList:removeByValue(username);
		self.password_map[username] = nil;
		self:SetModified()
	end
end

function PasswordList:LoadPasswordList()
	local file = ParaIO.open(self.filename, "r");
	if(file:IsValid()) then
		local theUserNameList = self.theUserNameList;
		local password_map = {}
		theUserNameList:clear();
		local linetext = file:readline();
		while (linetext) do
			local username, password = linetext:match("^(%S+)%s*=%s*(%S+)");
			if(username) then
				theUserNameList:add(username);
				if(not password_map[username]) then
					password_map[username] = password;
				else
					LOG.std(nil, "info", "PasswordList", "duplicated username found %s", username);
					self:SetModified()
				end
			else
				-- this is for comments, etc. 
				theUserNameList:add(linetext);
			end
			linetext = file:readline();
		end
		self.password_map = password_map;
		file:close();
	end
end

-- only save when modified. 
function PasswordList:SaveToFile()
	if(not self.isModified) then
		return;
	end
	self.isModified = nil;
	ParaIO.CreateDirectory(self.filename);

	local file = ParaIO.open(self.filename, "w");
	if(file:IsValid()) then
		LOG.std(nil, "debug", "PasswordList", "modified password file saved to %s", self.filename);
		local theUserNameList = self.theUserNameList;
		local password_map = self.password_map
		for i = 1, #theUserNameList do
			local username = theUserNameList[i];
			local password = password_map[username];
			if(password) then
				file:writeline(format("%s=%s", username, password));
			else
				-- this is for comments, etc. 
				file:writeline(username);
			end
		end
		file:close();
	end
end