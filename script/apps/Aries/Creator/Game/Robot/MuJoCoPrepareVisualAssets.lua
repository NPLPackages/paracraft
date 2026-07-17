local MuJoCoPrepareVisualAssets = NPL.export();
local MuJoCoH1VisualConfig = NPL.load("(gl)script/apps/Aries/Creator/Game/Robot/MuJoCoH1VisualConfig.lua");

local function getDirectory(path)
	return path:match("^(.*[/\\])") or "";
end

function MuJoCoPrepareVisualAssets.Run()
	local modelPath = ParaEngine.GetAppCommandLineByParam("mujoco_model", "");
	if modelPath == "" then
		LOG.std(nil, "error", "MuJoCoPrepareVisualAssets", "mujoco_model is not specified");
		return;
	end
	if not ParaAsset.ConvertGLB then
		LOG.std(nil, "error", "MuJoCoPrepareVisualAssets", "ParaAsset.ConvertGLB is unavailable");
		return;
	end

	local modelDirectory = getDirectory(modelPath);
	local meshDirectory = modelDirectory .. "meshes/";
	local outputDirectory = modelDirectory .. "visual/";
	ParaIO.CreateDirectory(outputDirectory);
	local convertedCount = 0;
	local failedCount = 0;
	local convertedMeshes = {};
	for _, body in ipairs(MuJoCoH1VisualConfig.Bodies) do
		local meshName = body.mesh;
		if not convertedMeshes[meshName] then
			convertedMeshes[meshName] = true;
			local inputPath = meshDirectory .. meshName .. ".STL";
			local outputPath = outputDirectory .. meshName .. ".fbx";
			if ParaIO.DoesAssetFileExist(inputPath, true) then
				ParaAsset.ConvertGLB(string.format("%s,0 -1 0 0 0 0 1 0 1 0 0 0,%s", inputPath, outputPath));
				if ParaIO.DoesAssetFileExist(outputPath, true) then
					convertedCount = convertedCount + 1;
				else
					failedCount = failedCount + 1;
					LOG.std(nil, "error", "MuJoCoPrepareVisualAssets", "conversion produced no output: %s", meshName);
				end
			else
				failedCount = failedCount + 1;
				LOG.std(nil, "error", "MuJoCoPrepareVisualAssets", "missing STL: %s", inputPath);
			end
		end
	end
	LOG.std(nil, failedCount == 0 and "info" or "error", "MuJoCoPrepareVisualAssets", "finished: converted=%d failed=%d output=%s", convertedCount, failedCount, outputDirectory);
end

MuJoCoPrepareVisualAssets.Run();

return MuJoCoPrepareVisualAssets;