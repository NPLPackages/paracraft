--[[
Title: Loading bar
Author(s): LiXizhi
Date: 2014/10/22
Desc: display progress bar when light is being calculated during world load time. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Login/SwfLoadingBar.lua");
local SwfLoadingBar = commonlib.gettable("MyCompany.Aries.Game.GUI.SwfLoadingBar");
SwfLoadingBar.ShowForLightCalculation();
-------------------------------------------------------
]]
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon");
local SwfLoadingBarPage =  commonlib.gettable("Map3DSystem.App.MiniGames.SwfLoadingBarPage");
local SwfLoadingBar = commonlib.gettable("MyCompany.Aries.Game.GUI.SwfLoadingBar");

SwfLoadingBar.percentage = 0;
SwfLoadingBar.lighting_tickcount = 0;

-- precalculate lighting for some seconds before presenting the world to the user. 
-- call this function immediately when block engine is enabled. 
function SwfLoadingBar.ShowForLightCalculation(onFinishCallback)
	SwfLoadingBar.onFinishCallback = onFinishCallback;
	SwfLoadingBarPage.ShowPage({ top = -50, show_background = true, worldname = WorldCommon.GetWorldTag("name") });
	SwfLoadingBar.ShowProgress(L"正在计算光照信息, 请耐心等待...", 10);
	SwfLoadingBar.tracking_target = "LightCalculation";
	SwfLoadingBar.lighting_tickcount = 0;

	local attr = ParaTerrain.GetBlockAttributeObject();
	attr:SetField("RenderBlocks", false);
	attr:SetField("LightCalculationStep", 300);
	SwfLoadingBar.mytimer = SwfLoadingBar.mytimer or commonlib.Timer:new({callbackFunc = function(timer)
		SwfLoadingBar.OnTick();
	end})
	SwfLoadingBar.mytimer:Change(300, 300);
end

function SwfLoadingBar.OnTick()
	if(SwfLoadingBar.tracking_target == "LightCalculation") then
		local attr = ParaTerrain.GetBlockAttributeObject();
		local nDirtyBlockCount = attr:GetField("DirtyBlockCount", 0);
		local NumOfLockedBlockRegion = attr:GetField("NumOfLockedBlockRegion", 0);	
		if(NumOfLockedBlockRegion > 0)  then
			-- reset start time. 
			SwfLoadingBar.lighting_tickcount = 0
			local TotalNumOfLoadedChunksInLockedBlockRegion = attr:GetField("TotalNumOfLoadedChunksInLockedBlockRegion", 0);	
			SwfLoadingBar.ShowProgress(string.format(L"正在加载世界, 请耐心等待... (%d:%d)", NumOfLockedBlockRegion, TotalNumOfLoadedChunksInLockedBlockRegion), SwfLoadingBar.percentage);	
		else
			SwfLoadingBar.lighting_tickcount = SwfLoadingBar.lighting_tickcount + 1;
			if(SwfLoadingBar.lighting_tickcount > 3*3) then
				-- at most wait 3 seconds. 
				SwfLoadingBar.ClosePage();
				return;
			end
			
			if(nDirtyBlockCount == 0) then
				SwfLoadingBar.ShowProgress(nil, 100);
			else
				if(SwfLoadingBar.percentage > 50) then
					if(SwfLoadingBar.percentage < 99) then
						SwfLoadingBar.percentage = SwfLoadingBar.percentage + 1;
					else
						-- we will remain at 99%. 
					end
				else
					SwfLoadingBar.percentage = SwfLoadingBar.percentage + 5;
				end
				SwfLoadingBar.ShowProgress(string.format(L"正在计算光照信息, 请耐心等待... (%d)", nDirtyBlockCount), SwfLoadingBar.percentage);
			end
		end
	end
end

-- @param delay_time: default to 100ms. if 0, it will be closed immediately without showing the last percentage.
function SwfLoadingBar.ClosePage(delay_time)
	if(SwfLoadingBar.mytimer) then
		SwfLoadingBar.mytimer:Change();
	end
	delay_time = delay_time or 100;
	if(delay_time == 0) then
		SwfLoadingBar.ClosePageImp();
	else
		local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
			SwfLoadingBar.ClosePageImp();
		end})
		mytimer:Change(delay_time);	
	end
	SwfLoadingBar.OnFinish();
end

function SwfLoadingBar.ClosePageImp()
	SwfLoadingBarPage.UpdateText(nil);
	SwfLoadingBarPage.ClosePage();
end

function SwfLoadingBar.OnFinish()
	if(SwfLoadingBar.tracking_target == "LightCalculation") then
		local attr = ParaTerrain.GetBlockAttributeObject();
		attr:SetField("RenderBlocks", true);
		attr:SetField("LightCalculationStep", 0);
	end
	if(SwfLoadingBar.onFinishCallback) then
		SwfLoadingBar.onFinishCallback();
	end
end

-- display current progress. Pass nil to all params like SwfLoadingBar.ShowProgress(); will hide UI. 
-- @param msg: message string. If nil, it means 100% finished. 
-- @param percentage: value in [0,100]. If nil, it will just increase the self.percentage by step or 10. 
-- @param step: the step to increase when percentage is nil. default to 10. 
function SwfLoadingBar.ShowProgress(msg, percentage, step)
	if(percentage) then
		SwfLoadingBar.percentage = percentage;
	else
		SwfLoadingBar.percentage = SwfLoadingBar.percentage + (step or 10);
		if(SwfLoadingBar.percentage >= 100) then
			SwfLoadingBar.percentage = 99
		end
	end
	if(not msg) then
		SwfLoadingBar.percentage = 100;
	end
	
	local p = SwfLoadingBar.percentage or 0;
	if(p == 0)then
		SwfLoadingBarPage.ShowPage(
			{ top = -50 }
		);
	else
		SwfLoadingBarPage.ShowPage({top = -50});
	end
	p = p / 100;
	SwfLoadingBarPage.Update(p);
	SwfLoadingBarPage.UpdateText(msg);
	if(p == 1)then
		SwfLoadingBar.ClosePage();
	end
end

