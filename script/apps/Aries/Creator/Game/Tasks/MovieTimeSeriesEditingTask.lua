--[[
Title: Editing time series
Author(s): LiXizhi
Date: 2014/4/7
Desc: provides undo/redo for movie time series editing
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/MovieTimeSeriesEditingTask.lua");
local MovieTimeSeriesEditing = commonlib.gettable("MyCompany.Aries.Game.Tasks.MovieTimeSeriesEditing");
local task = MovieTimeSeriesEditing:new()
task:BeginModify(movieclip, itemstack);
-- to any kinds of modifications to itemstack.
task:EndModify();
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/UndoManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieManager.lua");
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
local UndoManager = commonlib.gettable("MyCompany.Aries.Game.UndoManager");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local TaskManager = commonlib.gettable("MyCompany.Aries.Game.TaskManager")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local MovieTimeSeriesEditing = commonlib.inherit(commonlib.gettable("MyCompany.Aries.Game.Task"), commonlib.gettable("MyCompany.Aries.Game.Tasks.MovieTimeSeriesEditing"));

function MovieTimeSeriesEditing:ctor()
end


function MovieTimeSeriesEditing:BeginModify(movieclip, itemstack)
	self.movieclip = movieclip;
	self.itemstack = itemstack;
	if(self.movieclip and self.itemstack) then
		self.old_item_stack = self.itemstack:Copy();
		self.start_time = self.movieclip:GetTime();
	end
end

function MovieTimeSeriesEditing:EndModify()
	if(self.movieclip and self.itemstack) then
		if(not self.itemstack:IsSameItem(self.old_item_stack)) then
			self.new_item_stack = self.itemstack:Copy();
			self.end_time = self.movieclip:GetTime();
			self.finished = true;
			UndoManager.PushCommand(self);
		end
	end
end

function MovieTimeSeriesEditing:Redo()
	local movieclip = MovieManager:GetActiveMovieClip();
	if(movieclip and movieclip == self.movieclip) then
		local actor = movieclip:GetActorFromItemStack(self.itemstack);
		if(actor and (actor == movieclip:GetSelectedActor() or actor:IsKeyFrameOnly())) then
			self.itemstack:Swap(self.new_item_stack:Copy());
			actor:SetItemStack(self.itemstack);
			if(self.end_time) then
				movieclip:SetTime(self.end_time);
			end
		end
	end
end

function MovieTimeSeriesEditing:Undo()
	local movieclip = MovieManager:GetActiveMovieClip();
	if(movieclip and movieclip == self.movieclip) then
		local actor = movieclip:GetActorFromItemStack(self.itemstack);
		if(actor and (actor == movieclip:GetSelectedActor() or actor:IsKeyFrameOnly())) then
			self.itemstack:Swap(self.old_item_stack:Copy());
			actor:SetItemStack(self.itemstack);
			if(self.start_time) then
				movieclip:SetTime(self.start_time);
			end
		end
	end
end