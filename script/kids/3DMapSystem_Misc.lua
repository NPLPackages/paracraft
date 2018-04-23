--[[
Title: Misc functions for 3D Map system
Author(s): WangTian
Date: 2007/8/31
Desc: 3D Map system misc functions
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystem_Misc.lua");
Map3DSystem.Misc.xxx();
------------------------------------------------------------
]]

commonlib.setfield("Map3DSystem.Misc", {})

Map3DSystem.Misc.IsExclusiveMessageBoxEnabled = false;

-------------------------------------------------
-- TODO: move to NPL.IDE: commonlib
-------------------------------------------------

-- NOTE: DON'T copy table with nested table reference. e.g. a = {}; a.ref = a;
function Map3DSystem.Misc.CopyTable( tableSource )

	local copy_table = {};
	local copy_k, copy_v;

	for k, v in pairs(tableSource) do
		if ( type( k ) == 'table' ) then
			copy_k = Map3DSystem.CopyTable( k );
		else
			copy_k = k;
		end
		if ( type( v ) == 'table' ) then
			copy_v = Map3DSystem.CopyTable( v );
		else
			copy_v = v;
		end
		copy_table[ copy_k ] = copy_v;
	end
	return copy_table;
end

-- NOTE: show a message box that wait for specific script action. e.g. web service call, file transfer
function Map3DSystem.Misc.ShowExclusiveMessageBox( message )


	local _width, _height = 370,150;
	local _this, _parent;
	_this = ParaUI.CreateUIObject("container","Map3D_ExclusiveMessageBox", "_fi",0,0,0,0);
	_this:AttachToRoot();
	_this.background="";
	_parent = _this;
	
	_this = ParaUI.CreateUIObject("container","Map3D_ExclusiveMessageBox_BG", "_ct",-_width/2,-_height/2-50,_width,_height);
	_parent:AddChild(_this);
	_this.background="Texture/msg_box.png";
	_this:SetTopLevel(true);
	_parent = _this;
	
	_this=ParaUI.CreateUIObject("text","Map3D_EscPopup_Text", "_lt",15,10,_width-30,20);
	_this.text = L(message);
	_this.autosize=true;
	_this:DoAutoSize();
	_parent:InvalidateRect();
	_parent:AddChild(_this);
	
	Map3DSystem.Misc.IsExclusiveMessageBoxEnabled = true;

end

function Map3DSystem.Misc.DestroyExclusiveMessageBox( )

	if(Map3DSystem.Misc.IsExclusiveMessageBoxEnabled == true) then
		ParaUI.Destroy("Map3D_ExclusiveMessageBox");
	elseif(Map3DSystem.Misc.IsExclusiveMessageBoxEnabled == false) then
		log("Exclusive message box already disabled.\r\n");
	else
		--TODO: got nil
	end
end

function Map3DSystem.Misc.SaveTableToFile()
end


-- serialize to string
-- serialization will be well organized and easy to read the table structure
-- e.g. print(commonlib.serialize(o, 1))
function Map3DSystem.Misc.serialize2(o, lvl)
	if type(o) == "number" then
		return (tostring(o))
	elseif type(o) == "nil" then
		return ("nil")
	elseif type(o) == "string" then
		return (string.format("%q", o))
	elseif type(o) == "boolean" then	
		if(o) then
			return "true"
		else
			return "false"
		end
	elseif type(o) == "function" then
		return (tostring(o))
	elseif type(o) == "userdata" then
		return ("userdata")
	elseif type(o) == "table" then
	
		local forwardStr = "";
		for i = 0, lvl do
			forwardStr = "\t"..forwardStr;
		end
		local str = "{\r\n"
		local k,v
		for k,v in pairs(o) do
			nextlvl = lvl + 1;
			str = str..forwardStr..("\t[")..Map3DSystem.Misc.serialize2(k, nextlvl).."] = "..Map3DSystem.Misc.serialize2(v, nextlvl)..",\r\n"
		end
		str = str..forwardStr.."}";
		return str
	else
		log("-- cannot serialize a " .. type(o).."\r\n")
	end
end

-- this function will record a table to a specific file. 
-- different to SaveTableToFile is that this file will be well organized and easy to read the table structure
-- local t = {test=1};
-- commonlib.SaveTableToFile(t, "temp/t.txt");
function Map3DSystem.Misc.SaveTableToFile(o, filename)
	local succeed;
	local file = ParaIO.open(filename, "w");
	if(file:IsValid()) then
		file:WriteString(Map3DSystem.Misc.serialize2(o,0));
		succeed = true;
	end	
	file:close();
	return succeed;
end

-- Exceptions:
--
--	local t1, t2 = {}, {};
--	t1.A = nil;
--	t2.B = nil;
--	Map3DSystem.Misc.IsEqualTable(t1, t2); <--  return true
--
function Map3DSystem.Misc.IsEqualTable(t1, t2)
	if type(t1) == "number" then
		return (tostring(t1) == tostring(t2))
	elseif type(t1) == "nil" then
		return (t1 == t2)
	elseif type(t1) == "string" then
		return (t1 == t2)
	elseif type(t1) == "boolean" then
		return (t1 == t2)
	elseif type(t1) == "function" then
		return (tostring(t1) == tostring(t2))
	elseif type(t1) == "userdata" then
		-- !!!CAUTION!!!: can't compare userdata
		return true;
	elseif type(t1) == "table" then
	
		local len1 = table.getn(t1);
		local len2 = table.getn(t2);
		if(len1 ~= len2) then
			return false;
		end
		
		local k,v
		for k,v in pairs(t1) do
			-- assume we don't have table for key entry
			if(Map3DSystem.Misc.IsEqualTable(t1[k], t2[k]) == false) then
				return false;
			end
		end
		
		return true;
	else
		log("-- cannot serialize a " .. type(o).."\r\n")
		return false;
	end
end
