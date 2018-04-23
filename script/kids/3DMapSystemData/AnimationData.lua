 --[[
Title: The 3D Map System MainBar Data
Author(s): WangTian
Date: 2007/9/24
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemData/AnimationData.lua");
------------------------------------------------------------

]]

if(not Map3DSystem.UI.Animation) then Map3DSystem.UI.Animation = {} end

Map3DSystem.UI.Animation.DirectApply = false;
if(not Map3DSystem.UI.Animation.Style) then Map3DSystem.UI.Animation.Style = {} end

-- 8 timer calls
Map3DSystem.UI.Animation.Style.ColorFadeIn = 
	{
		FlatFadeIn = {25, 50, 75, 100, 125, 150, 175, 200};
	};
Map3DSystem.UI.Animation.Style.ColorFadeOut = 
	{
		FlatFadeOut = {200, 175, 150, 125, 100, 75, 50, 25};
	};
	
Map3DSystem.UI.Animation.Style.VisibleAlphaFadeIn = 
	{
		FlatFadeIn = {32, 64, 96, 128, 160, 192, 224, 255};
	};
Map3DSystem.UI.Animation.Style.VisibleAlphaFadeOut = 
	{
		FlatFadeOut = {255, 224, 192, 160, 128, 96, 64, 32};
	};
	
Map3DSystem.UI.Animation.Style.EnableAlphaFadeIn = 
	{
		FlatFadeIn = {20, 40, 60, 80, 100, 120, 140, 160};
	};
Map3DSystem.UI.Animation.Style.EnableAlphaFadeOut = 
	{
		FlatFadeOut = {160, 140, 120, 100, 80, 60, 40, 20};
	};
	
Map3DSystem.UI.Animation.Style.Create = 
	{
		FlatCreate16 = {2, 4, 6, 8, 10, 12, 14, 16};
		PopCreate16 = {3, 6, 9, 12, 14, 16, 18, 16};
	};
Map3DSystem.UI.Animation.Style.Destroy = 
	{
		FlatDestroy16 = {16, 14, 12, 10, 8, 6, 4, 2};
	};
	
Map3DSystem.UI.Animation.Style.Resize = 
	{
		FlatResize16 = {2, 4, 6, 8, 10, 12, 14, 16};
	};
	
Map3DSystem.UI.Animation.Style.Move = 
	{
		FlatMove16 = {2, 4, 6, 8, 10, 12, 14, 16};
		DecelerateMove16 = {0, 4, 7, 10, 12, 14, 15, 16};
	};
Map3DSystem.UI.Animation.Style["Flat"] = 
	{
		["EnableFadeIn"] = Map3DSystem.UI.Animation.Style.EnableAlphaFadeIn.FlatFadeIn,
		["EnableFadeOut"] = Map3DSystem.UI.Animation.Style.EnableAlphaFadeOut.FlatFadeOut,
		["VisibleFadeIn"] = Map3DSystem.UI.Animation.Style.VisibleAlphaFadeIn.FlatFadeIn,
		["VisibleFadeOut"] = Map3DSystem.UI.Animation.Style.VisibleAlphaFadeOut.FlatFadeOut,
		["FadeIn"] = Map3DSystem.UI.Animation.Style.ColorFadeIn.FlatFadeIn,
		["FadeOut"] = Map3DSystem.UI.Animation.Style.ColorFadeOut.FlatFadeOut,
		["Create"] = Map3DSystem.UI.Animation.Style.Create.FlatCreate16,
		["Destroy"] = Map3DSystem.UI.Animation.Style.Destroy.FlatDestroy16,
		["Resize"] = Map3DSystem.UI.Animation.Style.Resize.FlatResize16,
		["Move"] = Map3DSystem.UI.Animation.Style.Move.FlatMove16,
	};
	
	