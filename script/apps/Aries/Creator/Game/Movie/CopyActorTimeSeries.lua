--[[
Title: copy actor time series
Author(s): LiXizhi
Date: 2020/3/9
Desc: copy and paste actor time series
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/CopyActorTimeSeries.lua");
local CopyActorTimeSeries = commonlib.gettable("MyCompany.Aries.Game.Movie.CopyActorTimeSeries");
CopyActorTimeSeries.ShowPage(actor, fromTime, toTime)
CopyActorTimeSeries.PasteToActor(actor)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieClipTimeLine.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Clipboard.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/TimeSeries.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieUISound.lua");
local MovieUISound = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieUISound");
local TimeSeries = commonlib.gettable("MyCompany.Aries.Game.Common.TimeSeries");
local Clipboard = commonlib.gettable("MyCompany.Aries.Game.Common.Clipboard");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local MovieClipTimeLine = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClipTimeLine");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")

local CopyActorTimeSeries = commonlib.gettable("MyCompany.Aries.Game.Movie.CopyActorTimeSeries");

local page;
local nameDS = {};
CopyActorTimeSeries.isSelectAll = true;
CopyActorTimeSeries.isRelativePos = true;

function CopyActorTimeSeries.OnInit()
	page = document:GetPageCtrl();
end

function CopyActorTimeSeries.GetDs(index)
	if(not index) then
		return #nameDS;
	else
		return nameDS[index];
	end
end

function CopyActorTimeSeries.CreatePropertyDs(actor)
	local ds = {};
	if(actor) then
--		if(actor:CanShowCommandVariables()) then
--			local cmdActor = MovieClipTimeLine:GetCmdActor(true);
--			if(cmdActor) then
--				for index, name in ipairs(cmdActor:GetEditableVariableList()) do
--					if(name ~= "---") then
--						ds[#ds+1] = {name=name, displayName = MovieClipTimeLine:GetVariableDisplayName(name), checked = CopyActorTimeSeries.isSelectAll};
--					end
--				end
--			end
--		end
		for index, name in ipairs(actor:GetEditableVariableList()) do
			if(name ~= "---") then
				local checked = CopyActorTimeSeries.isSelectAll;
				if(name == "pos") then
					-- checked = false;
				end
				ds[#ds+1] = {name=name, displayName = MovieClipTimeLine:GetVariableDisplayName(name), checked = checked};
			end
		end
	end
	return ds
end

function CopyActorTimeSeries.GetItemStack()
	return CopyActorTimeSeries.itemStack
end

function CopyActorTimeSeries.GetActor()
	return CopyActorTimeSeries.actor;
end

function CopyActorTimeSeries.ToggleSelect(bSelectAll)
	CopyActorTimeSeries.isSelectAll = bSelectAll;
	local checked = bSelectAll
	echo({checked})
	for _, item in ipairs(nameDS) do
		item.checked = checked
	end
	if(page) then
		page:CallMethod("nameGvw", "DataBind")
	end
end

-- @param OnOK: function(values) end 
-- @param old_value: {name="ximi", isAgent=true, isServer=false}
function CopyActorTimeSeries.ShowPage(actor, fromTime, toTime)
	CopyActorTimeSeries.result = nil;
	
	actor = actor or MovieClipTimeLine:GetSelectedActor();
	if(not actor) then
		return
	end
	nameDS = CopyActorTimeSeries.CreatePropertyDs(actor)
	CopyActorTimeSeries.itemStack = actor:GetItemStack();
	CopyActorTimeSeries.actor = actor;

	local params = {
		url = "script/apps/Aries/Creator/Game/Movie/CopyActorTimeSeries.html", 
		name = "CopyActorTimeSeries.ShowPage", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		bToggleShowHide=false, 
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		click_through = false, 
		enable_esc_key = true,
		bShow = true,
		isTopLevel = true,
		app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		directPosition = true,
			align = "_ct",
			x = -256,
			y = -200,
			width = 512,
			height = 400,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);

	if(page) then
		page:SetUIValue("fromTime", tostring(fromTime or 0))
		page:SetUIValue("toTime", tostring(toTime or ""))
	end
end


function CopyActorTimeSeries.UpdateUIFromValue(values)
	if(page and values) then
		page:SetValue("name", values.name or "");
	end
end

function CopyActorTimeSeries.ToggleVariable(bChecked, mcmlNode)
	local item = mcmlNode:GetPreValue("this", true);
	if(item and item.checked~=nil) then
		item.checked = bChecked;
	end
end

-- return true if clipboard obj contains the actor's variable's data. 
-- @param obj: obj = CopyActorTimeSeries.GetClipBoardData()
-- @param actor: the actor object. 
-- @param varName: such as "pos", "facing", etc
function CopyActorTimeSeries.CheckIfObjContainsVariable(obj, actor, varName)
	local data = obj and obj.data;
	if(data and varName and actor and actor:GetItemStack().id == obj.itemId) then
		if(data[varName]) then
			return true;
		else
			local varMulti = actor:GetEditableVariableByName(varName);
			if(varMulti and varMulti.GetVariable) then
				local i=1
				while(true) do
					local subVar = varMulti:GetVariable(i);
					if(subVar) then
						i = i + 1;
						if(not data[subVar.name]) then
							return
						end
					else
						break;
					end
				end
				return true;
			end
		end
	end
end


-- @param varNames: array of var names to copy
-- @param isRelativePos: whether to use relative positioning
-- @param selectionOnly: whether to copy selected bones only. 
function CopyActorTimeSeries.CopyActorTimeSeries(actor, varNames, fromTime, toTime, isRelativePos, selectionOnly)
	if(actor) then
		local itemStack = actor:GetItemStack();
		local v = {};
		local mainTs = actor:GetTimeSeries()
		for _, name in ipairs(varNames) do
			local var = mainTs:GetVariable(name);
			if(not var) then
				local ts = mainTs:GetChild(name);
				if(ts) then
					if(ts.SaveToTable) then
						var = ts:SaveToTable();
						-- only copy selected bone variables
						if(selectionOnly and var and name == "bones") then
							local boneVar = actor:GetBonesVariable():GetSelectedBone();
							if(boneVar) then
								local varsSelected = {isContainer = true}
								for name, value in pairs(var) do
									if(boneVar:GetVarByName(name)) then
										varsSelected[name] = value
									end
								end
								var = varsSelected;
							end
						end
					end
				else
					local varMulti = actor:GetEditableVariableByName(name);
					if(varMulti and varMulti.GetVariable) then
						local i=1
						while(true) do
							local subVar = varMulti:GetVariable(i);
							if(subVar) then
								i = i + 1;
								local var2 = mainTs:GetVariable(subVar.name);
								if(var2) then
									v[subVar.name] = var2;
								end
							else
								break;
							end
						end
					end
				end
			end
			v[name] = var;
		end
		if(next(v)) then
			local data = {data = v, fromTime=fromTime, toTime = toTime, itemId = itemStack.id};
			if(isRelativePos and actor:GetMovieClipEntity()) then
				data.isRelativePos = true;
				data.bx, data.by, data.bz = actor:GetMovieClipEntity():GetBlockPos();
			end
			Clipboard.Save("ActorTimeSeries", data)	
			MovieUISound.PlayAddKey();
			return true;
		end
	end
end

function CopyActorTimeSeries.OnClickCopy()
	local actor = CopyActorTimeSeries.GetActor();
	if(page and actor) then
		local varNames = {};
		local mainTs = actor:GetTimeSeries()
		for _, item in ipairs(nameDS) do
			if(item.checked) then
				varNames[#varNames+1] = item.name;
			end
		end
		local fromTime = tonumber(page:GetUIValue("fromTime", 0));
		local toTime = tonumber(page:GetUIValue("toTime", 0));
		CopyActorTimeSeries.isRelativePos = page:GetValue("isRelativePos", true);
		

		if(CopyActorTimeSeries.CopyActorTimeSeries(actor, varNames, fromTime, toTime, CopyActorTimeSeries.isRelativePos)) then
			-- GameLogic.AddBBS(nil, L"", 4000, "0 255 0")
		end
		page:CloseWindow();
	end
end

function CopyActorTimeSeries.GetClipBoardData()
	local obj = Clipboard.LoadByType("ActorTimeSeries")
	return obj;
end

local function offset_time_variable(var, offset)
	if(var and var.data) then
		local data = var.data;
		for i = 1, #(data) do
			data[i] = data[i] + offset;
		end
	end
end

-- @param offset_x, offset_y, offset_z: in real coordinate
function CopyActorTimeSeries.OffsetTimeSeriesPositions(itemId, timeSeries, offset_x, offset_y, offset_z)
	if(not timeSeries) then
		return;
	end
	if(itemId == block_types.names.TimeSeriesNPC or itemId == block_types.names.TimeSeriesOverlay) then
		offset_time_variable(timeSeries:GetVariable("x"), offset_x);
		offset_time_variable(timeSeries:GetVariable("y"), offset_y);
		offset_time_variable(timeSeries:GetVariable("z"), offset_z);
		local blockVar = timeSeries:GetVariable("block")
		if(blockVar and blockVar.data) then
			local data = blockVar.data;
			for i = 1, #(data) do
				local blocks = data[i];
				local new_blocks = {};
				for sparse_index, b in pairs(blocks) do
					if(b[1]) then
						b[1] = b[1] + offset_bx;
						b[2] = b[2] + offset_by;
						b[3] = b[3] + offset_bz;
						new_blocks[BlockEngine:GetSparseIndex(b[1], b[2], b[3])] = b;
					end
				end
				data[i] = new_blocks;
			end
		end
	elseif(itemId == block_types.names.TimeSeriesCamera) then
		offset_time_variable(timeSeries:GetVariable("lookat_x"), offset_x);
		offset_time_variable(timeSeries:GetVariable("lookat_y"), offset_y);
		offset_time_variable(timeSeries:GetVariable("lookat_z"), offset_z);
	elseif(itemId == block_types.names.TimeSeriesCommands) then
		local blockVar = timeSeries:GetVariable("block")
		if(blockVar and blockVar.data) then
			local data = blockVar.data;
			for i = 1, #(data) do
				local blocks = data[i];
				local new_blocks = {};
				for sparse_index, b in pairs(blocks) do
					if(b[1]) then
						b[1] = b[1] + offset_bx;
						b[2] = b[2] + offset_by;
						b[3] = b[3] + offset_bz;
						new_blocks[BlockEngine:GetSparseIndex(b[1], b[2], b[3])] = b;
					end
				end
				data[i] = new_blocks;
			end
		end
	end
end

-- public method:
-- @param destVar: if nil it will paste everything in clipboard, if not, we will only paste on this variable.
function CopyActorTimeSeries.PasteToActor(actor, destVar, pasteFromTime)
	actor = actor or MovieClipTimeLine:GetSelectedActor();
	if(not actor) then
		return
	end
	local destVars;
	-- just in case destVar is a compositive variable like "pos" and "rot"
	if(destVar and destVar.name) then
		local varMulti = actor:GetEditableVariableByName(destVar.name);
		if(varMulti and varMulti.GetVariable) then
			local i=1
			while(true) do
				local subVar = varMulti:GetVariable(i);
				if(subVar) then
					i = i + 1;
					destVars = destVars or {}
					destVars[subVar.name] = true;
				else
					break;
				end
			end
		end
	end

	local function isDestVar_(var)
		if(var) then
			if(not destVar) then
				return true;
			elseif(destVar.name == "bones") then
				if(destVar:GetSelectedBone()) then
					return destVar:GetSelectedBone():GetVarByName(var.name) ~= nil;
				else
					return true;
				end
			elseif(destVar.name == var.name) then
				return true
			elseif(destVars and destVars[var.name]) then
				return true
			end
		end
	end

	local itemStack = actor:GetItemStack();
	local obj = Clipboard.LoadByType("ActorTimeSeries")
	if(obj and itemStack) then
		if(obj.itemId == itemStack.id) then
			actor:BeginUpdate();
			actor:BeginModify();
			local fromTime = obj.fromTime or 0;
			local toTime = obj.toTime;
			pasteFromTime = pasteFromTime or actor:GetTime() or 0;
			local ts = TimeSeries:new();
			ts:LoadFromTable(obj.data);

			-- check if we are pasting on to the selected bone. 
			if(destVar and destVar.name == "bones") then
				if(destVar:GetSelectedBone()) then
					local tsBones = ts:GetChild("bones");
					if(tsBones) then
						if(tsBones:GetVariableCount() <= 3) then
							local selectedBone = destVar:GetSelectedBone()
							local lastBoneBaseName;
							for i=1, tsBones:GetVariableCount() do
								local boneName = tsBones:GetVariableName(i)
								local boneBaseName;
								boneBaseName = boneBaseName or boneName:match("^(.+)_rot$")
								boneBaseName = boneBaseName or boneName:match("^(.+)_trans$")
								boneBaseName = boneBaseName or boneName:match("^(.+)_scale$")
								if( (boneBaseName or lastBoneBaseName) ~= boneBaseName) then
									lastBoneBaseName = nil;
									break;
								end
								lastBoneBaseName = boneBaseName;
							end
							if(lastBoneBaseName) then
								-- tricky: we will rename the clipboard bone name to the selected bone names
								for i=1, tsBones:GetVariableCount() do
									local boneName = tsBones:GetVariableName(i)
									if(boneName:match("^(.+)_rot$")) then
										tsBones:RenameVariable(boneName, selectedBone:GetRotName())
									elseif(boneName:match("^(.+)_trans$")) then
										tsBones:RenameVariable(boneName, selectedBone:GetTransName())
									elseif(boneName:match("^(.+)_scale$")) then
										tsBones:RenameVariable(boneName, selectedBone:GetScaleName())
									end
								end	
							end
						end
					end
				end
			end

			if(obj.isRelativePos and obj.bx and actor:GetMovieClipEntity()) then
				local bx, by, bz = actor:GetMovieClipEntity():GetBlockPos()
				local offset_x, offset_y, offset_z = BlockEngine:real_min(bx - obj.bx), BlockEngine:real_min(by - obj.by), BlockEngine:real_min(bz - obj.bz);

				CopyActorTimeSeries.OffsetTimeSeriesPositions(obj.itemId, ts, offset_x, offset_y, offset_z)
			end

			for i=1, ts:GetVariableCount() do
				local fromVar = ts:GetVariableByIndex(i);
				local var = actor:GetVariable(ts:GetVariableName(i));

				if(var and fromVar and isDestVar_(var)) then
					if(toTime) then
						var:RemoveKeysInTimeRange(pasteFromTime, pasteFromTime + toTime - fromTime);
					end
					for time, v in fromVar:GetKeys_Iter(1, fromTime-1, toTime or fromVar:GetLastTime()) do
						var:UpsertKeyFrame(pasteFromTime-fromTime+time, v)
					end
				end
			end
			
			local tsBones = ts:GetChild("bones");
			
			if(tsBones and (not destVar or destVar.name == "bones") and actor.GetBonesVariable) then
				local boneVars = actor:GetBonesVariable();
				if(boneVars) then
					for i=1, tsBones:GetVariableCount() do
						local fromVar = tsBones:GetVariableByIndex(i);
						local boneName = tsBones:GetVariableName(i)
						local var = boneVars:GetBoneAttributeVariableByName(boneName);
						-- only pasting on matching bone names
						if(var and fromVar and isDestVar_(var)) then
							if(toTime) then
								var:RemoveKeysInTimeRange(pasteFromTime, pasteFromTime + toTime - fromTime);
							end
							for time, v in fromVar:GetKeys_Iter(1, fromTime-1, toTime or fromVar:GetLastTime()) do
								var:UpsertKeyFrame(pasteFromTime-fromTime+time, v)
							end
						end
					end
				end
			end
			actor:EndModify();
			actor:EndUpdate();
			actor:FrameMovePlaying(0);
			GameLogic.AddBBS(nil, L"成功粘贴参数", 4000, "0 255 0");
			MovieUISound.PlayAddKey();
		else
			local item = ItemClient.GetItem(obj.itemId);
			if(item) then
				_guihelper.MessageBox(format(L"目标类型不匹配, 请选择 %s 粘贴", item:GetDisplayName()));
			end
		end
	end
end


function CopyActorTimeSeries.CopyVarInRangeStarted(var, actor, fromTime, toTime)
	local varNames = {};
	varNames[#varNames+1] = var.name;
	return CopyActorTimeSeries.CopyActorTimeSeries(actor, varNames, fromTime, toTime, nil, true)
end

function CopyActorTimeSeries.PasteVarInRangeStarted(var, actor, fromTime)
	return CopyActorTimeSeries.PasteToActor(actor, var, fromTime)
end

function CopyActorTimeSeries.OnClose()
	page:CloseWindow();
end
