--[[
Title: Bone controllers
Author(s): LiXizhi
Date: 2015/9/25
Desc: Bone controllers are transforms vectors into multiple bones's parameters, it is mostly used in facial expression. 
Controllers in animation files(such as bmax, fbx, x) can be specified in an xml file using same model filename. 
for example, if model file is test.bmax, then we will automatically look for test.bmax.xml for controller file. 

---++ controller meta file format
<verbatim>
the meta file may contains other informations, so the controller section should be at xpath "mesh/controller"
<mesh>
	<controllers>
		<controller name="mouth">
			<input type="vector2" min_value="-1" max_value="1">
				<output bone="upper_lip_trans" converter="">
					<converter>
						output[2]=input[2]*0.02;output[3]=input[1]*0.02;
					</converter>
				</output>
				<output bone="lower_lip_trans" converter="output[2]=input[2]*0.02"/>
			</input>
		</controller>
	</controllers>
</mesh>
</verbatim>
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/BoneController.lua");
local BoneController = commonlib.gettable("MyCompany.Aries.Game.Movie.BoneController");
BoneController.ShowPage()
-------------------------------------------------------
]]
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")

local BoneController = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("MyCompany.Aries.Game.Movie.BoneController"));

function BoneController:ctor()
end

local page;
function BoneController.OnInit()
	page = document:GetPageCtrl();
end

-- @param OnClose: function(values) end 
-- @param last_values: {text, ...}
function BoneController.ShowPage()
	BoneController:InitSingleton();
	local params = {
			url = "script/apps/Aries/Creator/Game/Movie/BoneController.html", 
			name = "BoneController.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = true,
			click_through = false, 
			enable_esc_key = true,
			bShow = true,
			isTopLevel = true,
			app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
			directPosition = true,
				align = "_rt",
				x = -10,
				y = 50,
				width = 200,
				height = 400,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

-- @param filename: the x, fbx, or parax file name or the meta file
function BoneController:LoadFromFile(filename)
	if(filename:match("%s+$") ~= "xml") then
		filename = filename..".xml";
	end
end
