--[[
Title: movie clip editors
Author(s): LiXizhi
Date: 2021/10/12
Desc: one can register new editors here
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieClipEditors.lua");
local MovieClipEditors = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClipEditors");
MovieClipEditors.SetDefaultMovieClipPlayer(MovieClipController or RolePlayMovieController)
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/GameRules/GameMode.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/MovieClipController.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/QuickSelectBar.lua");
local QuickSelectBar = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.QuickSelectBar");
local MovieClipController = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClipController");
local GameMode = commonlib.gettable("MyCompany.Aries.Game.GameLogic.GameMode");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local MovieManager = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieManager");
local MovieClip = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClip");

local MovieClipEditors = commonlib.gettable("MyCompany.Aries.Game.Movie.MovieClipEditors");

-- when a movie clip is activated in edit mode, we will use this editor to open it. 
-- @param movieClipPlayer: the class must implement movieClipPlayer.ShowPlayEditorForMovieClip(movieClip). 
-- if nil, it is MovieClipController. it can also be RolePlayMovieController
function MovieClipEditors.SetDefaultMovieClipPlayer(movieClipPlayer)
	MovieClipEditors.curMoviePlayer = movieClipPlayer;
	GameLogic.GetFilters():add_filter("beforeActivateMovieClip", MovieClipEditors.ShowPlayEditorForMovieClip);
end

function MovieClipEditors.GetMoviePlayer()
	return MovieClipEditors.curMoviePlayer or MovieClipController;
end

function MovieClipEditors.ShowPlayEditorForMovieClip(movieClip)
	MovieClipEditors.GetMoviePlayer().ShowPlayEditorForMovieClip(movieClip)
	return movieClip
end
