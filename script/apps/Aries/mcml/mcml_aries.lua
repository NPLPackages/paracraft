--[[
Title: register controls for Aries specific tags
Author(s): LiXizhi
Date: 2009/8/3
Desc: all aries specific tags
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/mcml/mcml_aries.lua");
MyCompany.Aries.mcml_controls.register_all();
-------------------------------------------------------
]]
local mcml_controls = commonlib.gettable("MyCompany.Aries.mcml_controls");

local is_init = false;
-- all this function to register all mcml tag
function mcml_controls.register_all()
	if(is_init) then
		return;
	end
	is_init = true;
	LOG.std("", "system", "mcml", "register Aries related mcml tags");

	NPL.load("(gl)script/kids/3DMapSystemApp/mcml/mcml_controls.lua");

	
	NPL.load("(gl)script/apps/Aries/mcml/pe_aries_window.lua");
	Map3DSystem.mcml_controls.RegisterUserControl("aries:window", mcml_controls.pe_aries_window);
	if(System.options.mc) then
		return;
	end

	NPL.load("(gl)script/apps/Aries/mcml/pe_aries.lua");
	NPL.load("(gl)script/apps/Aries/mcml/pe_aries2.lua");
	NPL.load("(gl)script/apps/Aries/mcml/pe_avatar.lua");
	NPL.load("(gl)script/apps/Aries/mcml/pe_locationtracker.lua");
	NPL.load("(gl)script/apps/Aries/mcml/pe_aries_quest.lua");
	NPL.load("(gl)script/apps/Aries/mcml/pe_aries_map.lua");
	NPL.load("(gl)script/apps/Aries/mcml/pe_aries_combatpet.lua");
	NPL.load("(gl)script/apps/Aries/mcml/pe_aries_lobbyservice.lua");
	NPL.load("(gl)script/apps/Aries/mcml/pe_aries_textsprite.lua");
	NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_movie.lua");
	NPL.load("(gl)script/apps/Aries/mcml/pe_goal_pointer.lua");
	NPL.load("(gl)script/apps/Aries/mcml/pe_aries_share.lua");
	NPL.load("(gl)script/apps/Aries/mcml/pe_aries_user.lua");
	
	-- aries tags
	Map3DSystem.mcml_controls.RegisterUserControl("aries:mountpetname", mcml_controls.aries_mountpetname);
	Map3DSystem.mcml_controls.RegisterUserControl("aries:userinfo", mcml_controls.aries_userinfo);
	Map3DSystem.mcml_controls.RegisterUserControl("aries:textsprite", mcml_controls.aries_textsprite);
	Map3DSystem.mcml_controls.RegisterUserControl("aries:mountpet", mcml_controls.aries_mountpet);
	Map3DSystem.mcml_controls.RegisterUserControl("aries:followpet", mcml_controls.aries_followpet);
	Map3DSystem.mcml_controls.RegisterUserControl("aries:mountpet-health", mcml_controls.aries_mountpet_health);
	Map3DSystem.mcml_controls.RegisterUserControl("aries:mountpet-level", mcml_controls.aries_mountpet_level);
	Map3DSystem.mcml_controls.RegisterUserControl("aries:mountpet-status", mcml_controls.aries_mountpet_status);
	Map3DSystem.mcml_controls.RegisterUserControl("aries:mountpet-status2", mcml_controls.aries_mountpet_status2);
	Map3DSystem.mcml_controls.RegisterUserControl("aries:mountpet-combatschool", mcml_controls.aries_mountpet_combatschool);
	Map3DSystem.mcml_controls.RegisterUserControl("aries:vip-sign", mcml_controls.aries_vip_sign);
	Map3DSystem.mcml_controls.RegisterUserControl("aries:statslabel", mcml_controls.aries_statslabel);

	-- aries2 tags
	Map3DSystem.mcml_controls.RegisterUserControl("aries:userhead", mcml_controls.aries_userhead);
	Map3DSystem.mcml_controls.RegisterUserControl("aries:onlinestatus", mcml_controls.aries_onlinestatus);
	Map3DSystem.mcml_controls.RegisterUserControl("aries:miniscenecameramodifier", mcml_controls.aries_miniscenecameramodifier);
	Map3DSystem.mcml_controls.RegisterUserControl("aries:questobjectivestatus", mcml_controls.aries_questobjectivestatus);

	Map3DSystem.mcml_controls.RegisterUserControl("aries:quest", mcml_controls.pe_aries_quest);
	Map3DSystem.mcml_controls.RegisterUserControl("aries:quest_item", mcml_controls.pe_aries_quest_item);
	Map3DSystem.mcml_controls.RegisterUserControl("aries:quest_repeat_item", mcml_controls.pe_aries_quest_repeat_item);

	
	Map3DSystem.mcml_controls.RegisterUserControl("aries:combatpet", mcml_controls.pe_aries_combatpet);
	Map3DSystem.mcml_controls.RegisterUserControl("aries:combatpet_item", mcml_controls.pe_aries_combatpet_item);

	Map3DSystem.mcml_controls.RegisterUserControl("aries:lobbyservice_template", mcml_controls.pe_aries_lobbyservice_template);
	Map3DSystem.mcml_controls.RegisterUserControl("aries:lobbyservice_template_item", mcml_controls.pe_aries_lobbyservice_template_item);
	Map3DSystem.mcml_controls.RegisterUserControl("aries:lobbyservice", mcml_controls.pe_aries_lobbyservice);
	Map3DSystem.mcml_controls.RegisterUserControl("aries:lobbyservice_item", mcml_controls.pe_aries_lobbyservice_item);

	-- override avatar tags
	Map3DSystem.mcml_controls.RegisterUserControl("pe:player", mcml_controls.pe_player);
	Map3DSystem.mcml_controls.RegisterUserControl("pe:avatar", mcml_controls.pe_avatar);

	-- pe location tracker
	Map3DSystem.mcml_controls.RegisterUserControl("pe:locationtracker", mcml_controls.pe_locationtracker);
	Map3DSystem.mcml_controls.RegisterUserControl("pe:arrowpointer", mcml_controls.pe_arrowpointer);

	-- pe maps
	Map3DSystem.mcml_controls.RegisterUserControl("pe:aries_map", mcml_controls.pe_aries_map);

	--aries:window
	Map3DSystem.mcml_controls.RegisterUserControl("aries:window", mcml_controls.pe_aries_window);
	Map3DSystem.mcml_controls.RegisterUserControl("aries:movie", mcml_controls.pe_movie);

	-- goal pointer
	Map3DSystem.mcml_controls.RegisterUserControl("pe:goalpointer", mcml_controls.pe_goalpointer);
	
	-- pe:mcworld
	Map3DSystem.mcml_controls.RegisterUserControl("pe:mcworld", mcml_controls.pe_mcworld);
	Map3DSystem.mcml_controls.RegisterUserControl("aries:user", mcml_controls.pe_aries_user);
end