--[[
Title: Environment Frame Page
Author(s): LiXizhi
Date: 2013/10/15
Desc: 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobileEnvFramePage.lua")
local MobileEnvFramePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Mobile.MobileEnvFramePage");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Areas/EnvFramePage.lua");
local EnvFramePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop.EnvFramePage");
local Desktop = commonlib.gettable("MyCompany.Aries.Creator.Game.Desktop");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon");
local MobileEnvFramePage = commonlib.gettable("MyCompany.Aries.Creator.Game.Mobile.MobileEnvFramePage");

local page;

MobileEnvFramePage.category_index = 1;
MobileEnvFramePage.Current_Item_DS = {};
-- this is a value between [100-255]
local block_light_scale = 180;
MobileEnvFramePage.shader_ds = {
	{value="1", text=L"关闭"},
	{value="2", text=L"开启"},
	{value="3", text=L"HDR"},
	{value="4", text=L"Dof/HDR"},
}

MobileEnvFramePage.uiversion = nil;
MobileEnvFramePage.colorpicker_name = nil;

function MobileEnvFramePage.OnInit(uiversion)
	MobileEnvFramePage.OneTimeInit();
	page = document:GetPageCtrl();

	MobileEnvFramePage.uiversion = uiversion;
	if(uiversion == 0) then
		MobileEnvFramePage.colorpicker_name = "BlockColorpicker";
		block_light_scale = 180;
	elseif(uiversion == 1) then
		MobileEnvFramePage.colorpicker_name = "EnvFramePage.NewBlockColorpicker";
		block_light_scale = 172;
	end

	local nRenderMethod = ParaTerrain.GetBlockAttributeObject():GetField("BlockRenderMethod", 1);
	for i, item in ipairs(MobileEnvFramePage.shader_ds) do
		if(i == nRenderMethod) then
			item.selected = true;
		else
			item.selected = nil;
		end
	end
	
	page:SetValue("comboShader",  tostring(math.min(math.max(1, nRenderMethod), 4)) );
	--page:SetValue("checkboxShadow", ParaTerrain.GetBlockAttributeObject():GetField("UseSunlightShadowMap", false) == true);
	--page:SetValue("checkboxReflection", ParaTerrain.GetBlockAttributeObject():GetField("UseWaterReflection", false) == true);

	page:SetValue("checkboxUIScaling", GameLogic.options.EnableAutoUIScaling);
	page:SetValue("checkboxViewBobbing", GameLogic.options.ViewBobbing);
	page:SetValue("checkboxLockMouseWheel", GameLogic.options.lock_mouse_wheel);
	page:SetValue("eye_bightness", GameLogic.options:GetEyeBrightness());
	page:SetValue("superRenderDist", GameLogic.options:GetSuperRenderDist());

	local render_dist = ParaTerrain.GetBlockAttributeObject():GetField("RenderDist", 100);
	if(render_dist < 30) then
		render_dist = 30
	elseif(render_dist > 200) then
		render_dist = 200;
	end
	page:SetValue("renderDist", render_dist);
	
	local color = ParaTerrain.GetBlockAttributeObject():GetField("BlockLightColor", GameLogic.options.BlockLightColor);
	page:SetNodeValue(MobileEnvFramePage.colorpicker_name, string.format("%d %d %d", color[1]*block_light_scale, color[2]*block_light_scale, color[3]*block_light_scale));
end

function MobileEnvFramePage.OneTimeInit()
	if(MobileEnvFramePage.is_inited) then
		return;
	end
	MobileEnvFramePage.is_inited = true;
end

-- clicked a block
function MobileEnvFramePage.OnClickBlock(block_id)
end

function MobileEnvFramePage.OnBlockColorChanged(r,g,b)
	if(r and g and b) then
		MobileEnvFramePage.cmd_light_color = string.format("/worldenv -lightcolor=%s,%s,%s -block_light_scale=%s",r,g,b,block_light_scale)
		GameLogic.RunCommand(MobileEnvFramePage.cmd_light_color)
	end
end

-- from night to noo by sliderbar
function MobileEnvFramePage.OnTimeSliderChanged(value)
	local cmdStr = nil
	if (value) then
		local time=(value/1000-0.5)*2;
		time = tostring(time);
		CommandManager:RunCommand("time", time);
		if EnvFramePage.changecb then
			EnvFramePage.changecb("time", time)
		end
		cmdStr = "/time "..time
	end	
	MobileEnvFramePage.cmd_time = cmdStr
end

local RGBTable = {
	["red"]        = {red_v = 255,green_v = 21, blue_v = 0,  },
	["yellow"]     = {red_v = 255,green_v = 182,blue_v = 0,  },
	["green"]      = {red_v = 107,green_v = 255,blue_v = 0,  },
	["light_blue"] = {red_v = 0,  green_v = 204,blue_v = 255,},
	["dark_blue"]  = {red_v = 0,  green_v = 30, blue_v = 255,},
	["purple"]	   = {red_v = 182,green_v = 0,  blue_v = 255,},
	["white"]	   = {red_v = 255,green_v = 255,blue_v = 255,},
	["black"]	   = {red_v = 0,  green_v = 0,  blue_v = 0,  },
}

function MobileEnvFramePage.SetLightColor(name)
	local color_name = string.match(name,"btn_(.*)");
	local rgb_item = RGBTable[color_name];
	if(rgb_item) then
		local red_value = rgb_item.red_v;
		local green_value = rgb_item.green_v;	
		local blue_value = rgb_item.blue_v;	
		page:SetUIValue(MobileEnvFramePage.colorpicker_name, string.format("%d %d %d", red_value, green_value, blue_value));		
		--page:Refresh(0.1);
		MobileEnvFramePage.OnBlockColorChanged(red_value, green_value, blue_value);
	end
end

function MobileEnvFramePage.OnToggleShader(name, value)
	local res = GameLogic.options:SetRenderMethod(value,true)
	if not res then
		if page then
			page:SetValue("comboShader", "1");
		end
	else
		if page then
			if value=="1" then
			end
			-- page:Refresh(0)
		end
	end
end

function MobileEnvFramePage.OnRenderDistChanged(value)
    GameLogic.options:SetRenderDist(value,true);
end

function MobileEnvFramePage.OnSuperRenderDistChanged(value)
    GameLogic.options:SetSuperRenderDist(value,true);
    if(value and value > GameLogic.options:GetRenderDist() and value>64) then
        GameLogic.options:SetFogEnd(value - 64);
    end
end

function MobileEnvFramePage.OnCloudnessChanged(value)
    GameLogic.options:SetCloudThickness(value,true);
end
    
function MobileEnvFramePage.OnChangeEyeBrightness(value)
    GameLogic.options:SetEyeBrightness(value,true);
end

function MobileEnvFramePage.ChangeWeather(name,mcmlNode)
	local weather = ""
    if(string.match(name,"sun")) then
		weather = "sun"
    elseif(string.match(name,"cloudy")) then
		weather = "cloudy"
    elseif(string.match(name,"rain")) then
		weather = "rain"
    elseif(string.match(name,"snow")) then
		weather = "snow"
    end
	MobileEnvFramePage.cmd_weather = string.format("/worldenv -weather=%s",weather)
	if EnvFramePage.changecb then
        EnvFramePage.changecb("cmd",MobileEnvFramePage.cmd_weather)
    end
	GameLogic.options:SetWeather(weather,true)
end

function MobileEnvFramePage.OnToggleAutoTimesGo(bChecked)
	GameLogic.options:SetTimesAutoGo(bChecked,true)
end

function MobileEnvFramePage.OnCopyCmd(name)
	local cmdStr = nil
	if name=="copy_weather" then
		local weather = GameLogic.options:GetWeather()
		cmdStr = string.format("/worldenv -weather=%s",weather)
	elseif name=="copy_light" then
		local now = GameLogic.RunCommand("/time now")
		now = math.floor(now*100)/100
		cmdStr = string.format("/worldenv -time=%s",now)
		if not GameLogic.options:IsTimesAutoGo() then
			cmdStr = cmdStr.." -isFreezetime=true"
		end
	elseif name=="copy_light_color" then
		local color = ParaTerrain.GetBlockAttributeObject():GetField("BlockLightColor");

		local r,g,b = color[1],color[2],color[3]
		r = math.floor(r*block_light_scale+0.5)
		g = math.floor(g*block_light_scale+0.5)
		b = math.floor(b*block_light_scale+0.5)
		if block_light_scale==172 then
			cmdStr = string.format("/worldenv -lightcolor=%s,%s,%s",r,g,b)
		else
			cmdStr = string.format("/worldenv -lightcolor=%s,%s,%s -block_light_scale=%s",r,g,b,block_light_scale)
		end
	elseif name=="copy_shader_effect" then
		local nRenderMethod = ParaTerrain.GetBlockAttributeObject():GetField("BlockRenderMethod", 1);
		local cloudThickness = ParaScene.GetAttributeObjectSky():GetField("CloudThickness",1)
		local eyeBrightness = GameLogic.options:GetEyeBrightness()
		local renderdist = GameLogic.options:GetRenderDist()
		local superrenderdist = GameLogic.options:GetSuperRenderDist()

		cloudThickness = math.floor(cloudThickness*100)/100
		eyeBrightness = math.floor(eyeBrightness*100)/100
		renderdist = math.floor(renderdist*100)/100
		superrenderdist = math.floor(superrenderdist*100)/100
		cmdStr = string.format("/worldenv -shader=%s -cloudThickness=%s -eyeBrightness=%s -renderdist=%s -superrenderdist=%s",nRenderMethod,cloudThickness,eyeBrightness,renderdist,superrenderdist)
	end
	if cmdStr and cmdStr~="" then
		ParaMisc.CopyTextToClipboard(cmdStr)
		GameLogic.AddBBS(nil,L"命令已复制")
	else

	end
end