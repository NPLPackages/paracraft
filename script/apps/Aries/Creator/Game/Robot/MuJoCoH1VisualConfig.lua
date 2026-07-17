local MuJoCoH1VisualConfig = NPL.export();

MuJoCoH1VisualConfig.Bodies = {
	{ name = "pelvis", showLabel = true },
	{ name = "left_hip_yaw_link" },
	{ name = "left_hip_pitch_link" },
	{ name = "left_hip_roll_link" },
	{ name = "left_knee_link" },
	{ name = "left_ankle_pitch_link" },
	{ name = "left_ankle_roll_link" },
	{ name = "right_hip_yaw_link" },
	{ name = "right_hip_pitch_link" },
	{ name = "right_hip_roll_link" },
	{ name = "right_knee_link" },
	{ name = "right_ankle_pitch_link" },
	{ name = "right_ankle_roll_link" },
	{ name = "torso_link" },
	{ name = "left_shoulder_pitch_link" },
	{ name = "left_shoulder_roll_link" },
	{ name = "left_shoulder_yaw_link" },
	{ name = "left_elbow_link" },
	{ name = "left_wrist_roll_link" },
	{ name = "left_wrist_pitch_link" },
	{ name = "left_wrist_yaw_link", mesh = "wrist_yaw_link" },
	{ name = "right_shoulder_pitch_link" },
	{ name = "right_shoulder_roll_link" },
	{ name = "right_shoulder_yaw_link" },
	{ name = "right_elbow_link" },
	{ name = "right_wrist_roll_link" },
	{ name = "right_wrist_pitch_link" },
	{ name = "right_wrist_yaw_link", mesh = "wrist_yaw_link" },
};

for _, body in ipairs(MuJoCoH1VisualConfig.Bodies) do
	body.mesh = body.mesh or body.name;
	body.label = body.name;
	body.scale = 0.12;
end

return MuJoCoH1VisualConfig;