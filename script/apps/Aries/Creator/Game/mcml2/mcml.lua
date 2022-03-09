--[[
Title: MC Main Login Procedure
Author(s): chenjinxian
Company: ParaEnging
Date: 2020.08.08
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml2/mcml.lua");
MyCompany.Aries.Game.mcml2.mcml_controls.register_all();
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
local mcml_controls = commonlib.gettable("MyCompany.Aries.Game.mcml2.mcml_controls");

local is_init = false;
-- all this function to register all mcml2 extension tag
function mcml_controls.register_all()
	if(is_init) then
		return;
	end
	is_init = true;
	LOG.std("", "system", "mcml2", "register mcml2 extension tags");

	NPL.load("(gl)script/apps/Aries/Creator/Game/mcml2/keepwork/kp_usertag.lua");
	MyCompany.Aries.Game.mcml2.kp_usertag:RegisterAs("kp:usertag");

	NPL.load("(gl)script/apps/Aries/Creator/Game/mcml2/pe_mc_player.lua");
	MyCompany.Aries.Game.mcml2.pe_mc_player:RegisterAs("pe:mc_player");

	NPL.load("(gl)script/apps/Aries/Creator/Game/mcml2/pe_mc_slot.lua");
	MyCompany.Aries.Game.mcml2.pe_mc_slot:RegisterAs("pe:mc_slot");

	NPL.load("(gl)script/apps/Aries/Creator/Game/mcml2/pe_mc_block.lua");
	MyCompany.Aries.Game.mcml2.pe_mc_block:RegisterAs("pe:mc_block");

	NPL.load("(gl)script/apps/Aries/Creator/Game/mcml2/pe_player_dir.lua");
	MyCompany.Aries.Game.mcml2.pe_player_dir:RegisterAs("pe:player_dir");

	NPL.load("(gl)script/apps/Aries/Creator/Game/mcml2/pe_canvas3d.lua");
	MyCompany.Aries.Game.mcml2.pe_canvas3d:RegisterAs("pe:canvas3d");
end