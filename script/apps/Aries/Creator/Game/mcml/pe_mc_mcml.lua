--[[
Title: MC Main Login Procedure
Author(s):  LiXizhi
Company: ParaEnging
Date: 2013.10.14
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/pe_mc_mcml.lua");
MyCompany.Aries.Game.mcml_controls.register_all();
------------------------------------------------------------
]]
local mcml_controls = commonlib.gettable("MyCompany.Aries.Game.mcml_controls");

local is_init = false;
-- all this function to register all mcml tag
function mcml_controls.register_all()
	if(is_init) then
		return;
	end
	is_init = true;
	LOG.std("", "system", "mcml", "register mc related mcml tags");

	NPL.load("(gl)script/kids/3DMapSystemApp/mcml/mcml_controls.lua");

	NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/pe_mc_player.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/pe_mc_block.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/pe_mc_slot.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/pe_mc_entity_canvas.lua");
	NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/pe_checkbox_button.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/pe_nplbrowser.lua");
	NPL.load("(gl)script/apps/Aries/mcml/pe_aries_textsprite.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/keepwork/kp_item.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/keepwork/kp_slot.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/keepwork/kp_redtip.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/keepwork/kp_usertag.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/mcml/keepwork/kp_window.lua");


	-- mc tags
	Map3DSystem.mcml_controls.RegisterUserControl("pe:mc_player", MyCompany.Aries.Game.mcml.pe_mc_player);
	Map3DSystem.mcml_controls.RegisterUserControl("pe:mc_block", MyCompany.Aries.Game.mcml.pe_mc_block);
	Map3DSystem.mcml_controls.RegisterUserControl("pe:mc_slot", MyCompany.Aries.Game.mcml.pe_mc_slot);
	Map3DSystem.mcml_controls.RegisterUserControl("pe:mc_entity_canvas", MyCompany.Aries.Game.mcml.pe_mc_entity_canvas);
	Map3DSystem.mcml_controls.RegisterUserControl("pe:checkbox_button", MyCompany.Aries.Game.mcml.pe_checkbox_button);
	Map3DSystem.mcml_controls.RegisterUserControl("aries:textsprite", MyCompany.Aries.mcml_controls and MyCompany.Aries.mcml_controls.aries_textsprite);

	Map3DSystem.mcml_controls.RegisterUserControl("kp:item", MyCompany.Aries.Game.mcml.kp_item);
	Map3DSystem.mcml_controls.RegisterUserControl("kp:slot", MyCompany.Aries.Game.mcml.kp_slot);
	Map3DSystem.mcml_controls.RegisterUserControl("kp:redtip", MyCompany.Aries.Game.mcml.kp_redtip);
	Map3DSystem.mcml_controls.RegisterUserControl("kp:usertag", MyCompany.Aries.Game.mcml.kp_usertag);
	Map3DSystem.mcml_controls.RegisterUserControl("kp:window", MyCompany.Aries.Game.mcml.kp_window);
    local pe_nplbrowser = commonlib.gettable("NplBrowser.pe_nplbrowser");
    Map3DSystem.mcml_controls.RegisterUserControl("pe:nplbrowser", pe_nplbrowser);
end