local SceneHelper = NPL.load("Mod/NplCad2/SceneHelper.lua");
local ShapeBuilder = NPL.load("Mod/NplCad2/Blocks/ShapeBuilder.lua");
local NplCad = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/NplCad/NplCad.lua");
if (not NplCad.IsPluginLoaded()) then
	local isFinished = false;
	SceneHelper.LoadPlugin(co:MakeCallbackFuncAsync(function()
		isFinished = true;
		resume();
	end))
	if(not isFinished) then
		yield();
	end
end
ShapeBuilder.create();
NplCad.InstallMethods(codeblock:GetCodeEnv(), ShapeBuilder);

local SaveModel;
SaveModel = function(block_name)
	block_name = block_name or codeblock:GetBlockName();
	if(not block_name or block_name == "")then
		block_name = NplCad.AutoFindNonExistBlockName()
		codeblock:SetBlockName(block_name)
	end
	local relativePath = NplCad.GetRelativeFileNameByBlockName(block_name);

	NplCad.SetCodeBlockActorAsset(codeblock, relativePath);
	local filepath = GameLogic.GetWorldDirectory()..relativePath;

	codeblock:GetEntity():Disconnect("afterRunThisBlock", nil, SaveModel);
    local result = SceneHelper.saveSceneToParaX(filepath, ShapeBuilder.getScene(), ShapeBuilder.liner, ShapeBuilder.angular);
	NplCad.ExportToFile(ShapeBuilder.getScene(), filepath, ShapeBuilder.liner, ShapeBuilder.angular);
	if(result)then
		setActorValue("assetfile", relativePath);
		setActorValue("showBones", true);
		NplCad.RefreshFile(relativePath);
	end
	-- NplCad.StopCodeBlock(codeblock)
	GameLogic.AddBBS("NPLCAD", format("saved to:%s", relativePath), 5000, "255 0 0")
end
codeblock:GetEntity():Disconnect("afterRunThisBlock");
codeblock:GetEntity():Connect("afterRunThisBlock", SaveModel)

