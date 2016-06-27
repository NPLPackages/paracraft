--[[
Title: Environment sky page
Author(s): LiXizhi
Date: 2010/1/26
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Env/SkyPage.lua");
------------------------------------------------------------
]]
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
local SkyPage = commonlib.gettable("MyCompany.Aries.Creator.SkyPage")

SkyPage.Name = "SkyPage";

local cur_sky_id = 1;

-- skybox db table
SkyPage.skyboxes = {
	[1] = {name = "sim1", is_simulated=true, text="仿真天空", file = "", bg = "Texture/Aries/WorldMaps/TownMap/SunShineStation2_off_32bits.png"},
	[2] = {name = "skybox15", text="阳光明媚", file = "model/skybox/skybox15/skybox15.x", bg = "model/skybox/skybox15/skybox15.x.png"},
	[3] = {name = "skybox6", text="月夜星空", file = "model/skybox/skybox6/skybox6.x", bg = "model/skybox/skybox6/skybox6.x.png"},
	[4] = {name = "skybox7", text="云雾朦胧", file = "model/skybox/skybox7/skybox7.x", bg = "model/skybox/skybox7/skybox7.x.png"},
	[5] = {name = "rain_1", text="下雨1", file = "model/skybox/skybox16/skybox16.x", bg = "model/skybox/skybox16/skybox16.x.png"},
	[6] = {name = "rain_2", text="下雨2", file = "model/skybox/skybox17/skybox17.x", bg = "model/skybox/skybox17/skybox17.x.png"},
	[7] = {name = "rain_3", text="下雨3", file = "model/skybox/skybox38/skybox38.x", bg = "model/skybox/skybox38/skybox38.x.png"},
	[8] = {name = "rain_4", text="下雨4", file = "model/skybox/skybox54/skybox54.x", bg = "model/skybox/skybox54/skybox54.x.png"},

};

-- whether we have searched all skyboxes in disk folder "model/Skybox"
SkyPage.DiskSkyBoxAppended = nil;

-- add disk sky box to SkyPage.skyboxes
function SkyPage.AppendDiskSkybox()
	if(SkyPage.DiskSkyBoxAppended == nil) then
		SkyPage.DiskSkyBoxAppended = true;
		local rootFolder = "model/Skybox"
		local output = commonlib.Files.Find({}, rootFolder, 10, 500, "*.x")
		if(output and #output>0) then
			local function HasSkyBox(filename)
				local _, skybox
				for _,skybox in ipairs(SkyPage.skyboxes)  do
					if(string.lower(skybox.file) == filename) then
						return true;
					end
				end
			end
			
			local _, item;
			for _, item in ipairs(output) do
				
				local skyBox = {};
				local utfFileName = commonlib.Encoding.DefaultToUtf8(string.gsub(item.filename,".*[/\\]", ""))
				skyBox.name = string.gsub(utfFileName, "%.x$", "");
				skyBox.text = skyBox.name;
				skyBox.file = string.lower(string.format("%s/%s", rootFolder,item.filename))
				skyBox.bg = skyBox.file..".png";
				if(not HasSkyBox(skyBox.file)) then
					SkyPage.skyboxes[(#SkyPage.skyboxes)+1] = skyBox;
				end	
			end
		end
	end
end

-- datasource function for pe:gridview
function SkyPage.DS_SkyBox_Func(index)
	SkyPage.AppendDiskSkybox();
	
	if(index == nil) then
		return #(SkyPage.skyboxes);
	else
		return SkyPage.skyboxes[index];
	end
end

-- called to init page
function SkyPage.OnInit()
	local self = SkyPage;
	self.ClearDataBind();
	local Page = document:GetPageCtrl();
	self.page = Page;
	-- update time slider UI
	Page:SetNodeValue("TimeSlider", (ParaScene.GetTimeOfDaySTD()/2+0.5)*100);
	
	local att = ParaScene.GetAttributeObject();
	if(att~=nil) then
		-- update sky color UI
		local color = ParaScene.GetAttributeObjectSky():GetField("SkyColor", {1, 1, 1});
		Page:SetNodeValue("SkyColorpicker", string.format("%d %d %d", color[1]*255, color[2]*255, color[3]*255));
		
		-- update fog color UI
		color = att:GetField("FogColor", {1, 1, 1});
		Page:SetNodeValue("FogColorpicker", string.format("%d %d %d", color[1]*255, color[2]*255, color[3]*255));
	end	
end

function SkyPage.DataBind(bindTarget)
	local self = SkyPage;
	if(not bindTarget or not self.page)then return; end
	
	self.bindTarget = bindTarget;
	self.bindingContext = commonlib.BindingContext:new();	
	--self.bindingContext:AddBinding(bindTarget, "Timeofday", self.page.name, commonlib.Binding.ControlTypes.MCML_node, "TimeSlider")
	--self.bindingContext:AddBinding(bindTarget, "S_Color", self.page.name, commonlib.Binding.ControlTypes.MCML_node, "SkyColorpicker")
	--self.bindingContext:AddBinding(bindTarget, "F_Color", self.page.name, commonlib.Binding.ControlTypes.MCML_node, "FogColorpicker")
	self.bindingContext:UpdateDataToControls();
	
end

function SkyPage.ClearDataBind()
	local self = SkyPage;
	self.bindTarget = nil;
	self.bindingContext = nil;
end

------------------------
-- page events
------------------------

-- called when the sky box need to be changed
function SkyPage.OnChangeSkybox(nIndex)
	cur_sky_id = nIndex;
	local self = SkyPage;
	local item = SkyPage.skyboxes[nIndex];
	if(item ~= nil) then
		if(Map3DSystem.Animation) then
			Map3DSystem.Animation.SendMeMessage({
					type = Map3DSystem.msg.ANIMATION_Character,
					obj_params = nil, --  <player>
					animationName = "ModifyNature",
					});
		end
		if(not item.is_simulated) then
			CommandManager:RunCommand("/sky "..item.file);

			if(self.bindingContext and self.bindTarget)then
				self.bindTarget.UseSimulatedSky = false;
				self.bindTarget.SkyBoxFile = item.file;
				self.bindTarget.SkyBoxName = item.name;
			end
		else
			local function ChangeToSimulated_()
				CommandManager:RunCommand("/sky sim");
				
				if(self.bindingContext and self.bindTarget)then
					self.bindTarget.UseSimulatedSky = true;
				end
			end
			local ps_version = MyCompany.Aries.GetShaderVersion();
			if(ps_version>=2) then
				ChangeToSimulated_();
			else
				_guihelper.MessageBox("很抱歉, 您机器的显卡无法支持仿真天空");
			end
		end	
	end
end

function SkyPage.GetCurrentSkyID()
	return cur_sky_id;
end

-- called when time slider changes
function SkyPage.OnTimeSliderChanged(value)
	local self = SkyPage;
	if (value) then
		local fTime=(value/100-0.5)*2;
		Map3DSystem.SendMessage_env({type = Map3DSystem.msg.SKY_SET_Sky, timeofday = fTime})

		if(ParaTerrain.SetBlockWorldSunIntensity) then
			ParaTerrain.SetBlockWorldSunIntensity(1-math.abs(fTime));
		end

		if(self.bindingContext and self.bindTarget)then
			self.bindTarget.Timeofday = fTime;
		end
	end	
end

-- called when the fog color changes
function SkyPage.OnFogColorChanged(r,g,b)
	local self = SkyPage;
	if(r and g and b) then
		r = r/255;
		g = g/255;
		b = b/255 
		Map3DSystem.SendMessage_env({type = Map3DSystem.msg.SKY_SET_Sky, fog_r = r, fog_g = g, fog_b = b,})
		
		CommandManager:RunCommand("day", "infinite");

		if(self.bindingContext and self.bindTarget)then
			self.bindTarget.FogColor_R = r;
			self.bindTarget.FogColor_G = g;
			self.bindTarget.FogColor_B = b;
			self.bindTarget.F_Color = string.format("%d %d %d", r, g, b)
		end
	end
end

-- called when the sky color changes
function SkyPage.OnSkyColorChanged(r,g,b)
	local self = SkyPage;
	if(r and g and b) then
		r = r/255;
		g = g/255;
		b = b/255 
		Map3DSystem.SendMessage_env({type = Map3DSystem.msg.SKY_SET_Sky, sky_r = r, sky_g = g, sky_b = b,})
		
		CommandManager:RunCommand("day", "infinite");

		if(self.bindingContext and self.bindTarget)then
			self.bindTarget.SkyColor_R = r;
			self.bindTarget.SkyColor_G = g;
			self.bindTarget.SkyColor_B = b;
			self.bindTarget.S_Color = string.format("%d %d %d", r, g, b)
		end
	end
end

function SkyPage.SetTimeMorning()
	SkyPage.page:SetValue("TimeSlider", 20);
	SkyPage.OnTimeSliderChanged(20)
end

function SkyPage.SetTimeNoon()
	SkyPage.page:SetValue("TimeSlider", 50);
	SkyPage.OnTimeSliderChanged(50)
end

function SkyPage.SetTimeNight()
	SkyPage.page:SetValue("TimeSlider", 90);
	SkyPage.OnTimeSliderChanged(95)
end
