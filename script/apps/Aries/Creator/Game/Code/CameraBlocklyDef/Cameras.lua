--[[
Title: All camera manager
Author(s): LiXizhi
Date: 
Desc: 
use the lib:
-------------------------------------------------------
local Cameras = NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CameraBlocklyDef/Cameras.lua");
-------------------------------------------------------
]]
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Cameras = NPL.export();

-- get and set Camera code block
local cameras = {};
Cameras.eyeDist = 3;
Cameras.currentId = 0;
Cameras.totalTimes = 0;
Cameras.currentTime = 0;

function Cameras.clear()
	for i = 1, #cameras do
		local camera = cameras[i]
		if(camera) then
			if(EntityManager.GetFocus() == camera) then
				EntityManager.SetFocus(EntityManager.GetPlayer());
			end
			camera:Destroy();
		end
	end
	cameras = {}
	Cameras.setCurrentCameraId(0)
	Cameras.setTotalTimes(0);
end

function Cameras.getMaxTime()
	return 20;
end

function Cameras.setTargetTime(time)
	Cameras.targetTime = time;
end

function Cameras.getTargetTime()
	return Cameras.targetTime or -1;
end


function Cameras.getAllCameras()
	return cameras;
end

function Cameras.addCamera(camera)
	cameras[#cameras+1] = camera;
end

function Cameras.getCurrentCamera()
	return cameras[Cameras.currentId];
end

function Cameras.getCurrentCameraId()
	return Cameras.currentId;
end

function Cameras.setCurrentCameraId(id)
	Cameras.currentId = id;
end

function Cameras.getTotalTimes()
	return Cameras.totalTimes;
end

function Cameras.setTotalTimes(t)
	Cameras.totalTimes = t;
end

function Cameras.getDefaultCameraCount()
	return 4;
end
