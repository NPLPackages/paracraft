--[[
Title: 
Author(s): Leio
Date: 2012/10/16
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_movie.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/XPath.lua");
NPL.load("(gl)script/ide/Director/Movie.lua");
local Movie = commonlib.gettable("Director.Movie");
NPL.load("(gl)script/ide/Director/MovieClip.lua");
local MovieClip = commonlib.gettable("Director.MovieClip");
local pe_movie = commonlib.gettable("MyCompany.Aries.mcml_controls.pe_movie");

function pe_movie.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout, css)
	local player_name = pe_movie.GetPlayerName(mcmlNode);
	local player = Movie.CreateOrGetPlayer(player_name);
	if(player)then
		local movie_start = mcmlNode:GetAttributeWithCode("begin");
		local movie_end = mcmlNode:GetAttributeWithCode("end");
		
		local function before_play_func(holder,event)
			--动态替换属性
			local movie_mcmlNode = event.movie_mcmlNode;--数据源 可以动态替换数据
			local pageCtrl = mcmlNode:GetPageCtrl();
			local line_node;
			for line_node in commonlib.XPath.eachNode(movie_mcmlNode, "//MotionLine") do
				local RenderParent = Movie.GetString(line_node,"RenderParent");
				if(RenderParent and RenderParent ~= "")then
					local obj = pageCtrl:FindControl(RenderParent);
					if(obj)then
						line_node.attr.RenderParent = obj.name;
					end
				end
			end
		end
		local function movie_start_func()
			Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, movie_start);
		end
		local function movie_end_func()
			Map3DSystem.mcml_controls.OnPageEvent(mcmlNode, movie_end);
		end
		player:AddEventListener("before_play",before_play_func,nil,"pe_movie before_play");
		if(movie_start)then
			player:AddEventListener("movie_start",movie_start_func,nil,"pe_movie movie_start");
		end
		if(movie_end)then
			player:AddEventListener("movie_end",movie_end_func,nil,"pe_movie movie_end");
		end
	end
end
function pe_movie.GetPlayerName(mcmlNode)
	local player_name =  mcmlNode:GetString("name");
	if(not player_name)then
		local url = "";
		local pageCtrl = mcmlNode:GetPageCtrl();
		if(pageCtrl)then
			url = pageCtrl.url;
		end
		player_name = mcmlNode:GetInstanceName(url);
	end
	return player_name;
end
function pe_movie.DoPlay(mcmlNode)
	local player_name = pe_movie.GetPlayerName(mcmlNode);
	local movie_str = mcmlNode:GetAttributeWithCode("DataSource",nil,true);
	if(not movie_str or movie_str == "")then
		return
	end
	if(type(movie_str) == "string")then
		Movie.DoPlay_ByString(player_name,movie_str);
		return;
	end
	local movie_mcmlNode = commonlib.XPath.selectNodes2(mcmlNode,"//Motions");
	if(movie_mcmlNode)then
		Movie.DoPlay_ByMcmlNode(player_name,movie_mcmlNode);
	end
end
function pe_movie.DoStop(mcmlNode)
	local player_name = pe_movie.GetPlayerName(mcmlNode);
	Movie.Clear(player_name);
end