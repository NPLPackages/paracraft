local MuJoCoQuickTest = NPL.export();

function MuJoCoQuickTest.Run()
	local modelPath = ParaEngine.GetAppCommandLineByParam("mujoco_model", "");
	if modelPath == "" then
		LOG.std(nil, "error", "MuJoCoQuickTest", "mujoco_model is not specified");
		return;
	end

	local handle = ParaMuJoCo.LoadModel(modelPath);
	if handle == 0 then
		LOG.std(nil, "error", "MuJoCoQuickTest", "failed loading model: %s", ParaMuJoCo.GetLastError(0));
		return;
	end

	if ParaMuJoCo.GetControlCount(handle) > 0 then
		ParaMuJoCo.SetControl(handle, 0, 0);
	end
	ParaMuJoCo.Forward(handle);
	ParaMuJoCo.Step(handle, 5000);
	local pelvisId = ParaMuJoCo.FindBody(handle, "pelvis");
	local pelvisPosition = {
		ParaMuJoCo.GetBodyPosition(handle, pelvisId, 0),
		ParaMuJoCo.GetBodyPosition(handle, pelvisId, 1),
		ParaMuJoCo.GetBodyPosition(handle, pelvisId, 2),
	};
	local pelvisQuaternion = {
		ParaMuJoCo.GetBodyQuaternion(handle, pelvisId, 0),
		ParaMuJoCo.GetBodyQuaternion(handle, pelvisId, 1),
		ParaMuJoCo.GetBodyQuaternion(handle, pelvisId, 2),
		ParaMuJoCo.GetBodyQuaternion(handle, pelvisId, 3),
	};
	local pelvisParaPosition = {
		ParaMuJoCo.GetBodyParaPosition(handle, pelvisId, 0),
		ParaMuJoCo.GetBodyParaPosition(handle, pelvisId, 1),
		ParaMuJoCo.GetBodyParaPosition(handle, pelvisId, 2),
	};
	local pelvisParaQuaternion = {
		ParaMuJoCo.GetBodyParaQuaternion(handle, pelvisId, 0),
		ParaMuJoCo.GetBodyParaQuaternion(handle, pelvisId, 1),
		ParaMuJoCo.GetBodyParaQuaternion(handle, pelvisId, 2),
		ParaMuJoCo.GetBodyParaQuaternion(handle, pelvisId, 3),
	};

	LOG.std(nil, "info", "MuJoCoQuickTest", "passed: handle=%d nq=%d nv=%d nu=%d bodies=%d joints=%d contacts=%d time=%.3f pelvis=(%.3f,%.3f,%.3f) quat=(%.3f,%.3f,%.3f,%.3f) para=(%.3f,%.3f,%.3f) paraQuat=(%.3f,%.3f,%.3f,%.3f)",
		handle,
		ParaMuJoCo.GetQPosCount(handle),
		ParaMuJoCo.GetQVelCount(handle),
		ParaMuJoCo.GetControlCount(handle),
		ParaMuJoCo.GetBodyCount(handle),
		ParaMuJoCo.GetJointCount(handle),
		ParaMuJoCo.GetContactCount(handle),
		ParaMuJoCo.GetTime(handle),
		pelvisPosition[1], pelvisPosition[2], pelvisPosition[3],
		pelvisQuaternion[1], pelvisQuaternion[2], pelvisQuaternion[3], pelvisQuaternion[4],
		pelvisParaPosition[1], pelvisParaPosition[2], pelvisParaPosition[3],
		pelvisParaQuaternion[1], pelvisParaQuaternion[2], pelvisParaQuaternion[3], pelvisParaQuaternion[4]);

	MuJoCoQuickTest.handle = handle;
end

MuJoCoQuickTest.Run();

return MuJoCoQuickTest;