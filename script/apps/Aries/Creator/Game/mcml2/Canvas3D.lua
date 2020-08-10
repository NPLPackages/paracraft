--[[
Title: Canvas3D
Author(s): chenjinxian
Date: 2020/8/6
Desc: A 3D canvas container for displaying picture, 3D scene, etc
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/mcml2//Canvas3D.lua");
local Canvas3D = commonlib.gettable("MyCompany.Aries.Game.mcml2.Canvas3D");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/CanvasCamConfig.lua");
local CanvasCamConfig = commonlib.gettable("MyCompany.Aries.CanvasCamConfig");
NPL.load("(gl)script/ide/System/Windows/UIElement.lua");
local Canvas3D = commonlib.inherit(commonlib.gettable("System.Windows.UIElement"), commonlib.gettable("MyCompany.Aries.Game.mcml2.Canvas3D"));
Canvas3D:Property("Name", "Canvas3D");
Canvas3D:Property({"BackgroundColor", "#ffffff", auto=true});
Canvas3D:Property({"Background", nil, auto=true});
	--how many degrees per pixel movement
Canvas3D:Property({"RotSpeed", 0.004, auto=true});
	-- how many degrees (in radian) to rotate around the Y axis per second. if nil or 0 it will not rotate. common values are 0.12
Canvas3D:Property({"AutoRotateSpeed", 0, auto=true});
	-- how many percentage of MaxZoomDist to pan for each mouse pixel movement
Canvas3D:Property({"PanSpeed", 0.001, auto=true});
	--model config camera name
Canvas3D:Property({"CameraName", nil, auto=true});
	-- the default came object distance, if nil, we will automatically calculate according to the bounding box. 
Canvas3D:Property({"DefaultCameraObjectDist", 7, auto=true});
Canvas3D:Property({"DefaultLiftupAngle", 0.25, auto=true});
Canvas3D:Property({"DefaultRotY", 0, auto=true});
	-- camera look at height. if nil, the bounding box of the asset will be used for height calculation. 
Canvas3D:Property({"LookAtHeight", 1.5, auto=true});
	-- camera lift up angle range in 3D mode. 
Canvas3D:Property({"MaxLiftupAngle", 1.3, auto=true});
Canvas3D:Property({"MinLiftupAngle", 0.1, auto=true});
	-- how many meters to zoom in and out in 3D mode. 
Canvas3D:Property({"MaxZoomDist", 20, auto=true});
Canvas3D:Property({"MinZoomDist", 0.01, auto=true});
	-- must be power of 2, like 128, 256. This is only used in ShowModel. 
	-- However, one can use the set size function miniscenegraph to specify both height and width.
Canvas3D:Property({"RenderTargetSize", 256, "GetRenderTargetSize", "SetRenderTargetSize"});
	-- the camera's field of view when a render target is used. 
	-- FieldOfView = 1.57,
	-- whether it will receive and responds to mouse event
Canvas3D:Property({"IsInteractive", true, auto=true});
	-- if not nil, it will render into Miniscenegraphname; if not nil, object will be rendered into an external mini scene graph with this name. 
	-- please refer to mcml tag pe:canvas3dui for example of using external scenes. 
Canvas3D:Property({"ExternalSceneName", nil, auto=true});
	-- in case ExternalSceneName is provided, this is the offset used for displaying the object. 
Canvas3D:Property({"ExternalOffsetX", 0, auto=true});
Canvas3D:Property({"ExternalOffsetY", 0, auto=true});
Canvas3D:Property({"ExternalOffsetZ", 0, auto=true});
	-- if not provided, it means "false". if true and ExternalSceneName is provided, we will set the external mini scene's camera according to this node's settings. 
Canvas3D:Property({"IgnoreExternalCamera", nil, auto=true});
	-- the miniscenegraph name to use if no one is specified. In case self.ExternalSceneName is provided, this is the object name in the external scene. 
Canvas3D:Property({"Miniscenegraphname", "Mcml2DefaultCanvas3D", auto=true});
Canvas3D:Property({"IsActiveRendering", false, auto=true});

function Canvas3D:ctor()
	-- mouse down position
	self.lastMouseDown = {x = 0, y=0}
	self.lastMousePos = {x = 0, y=0}
	-- whether any mouse button is down
	self.IsMouseDown = false;
	-- whether middle mouse button is down
	self.IsMidMouseDown = false;
	
	-- private: 
	-- 1. resourceType==nil means miniscenegraph, 
	-- 2. resource == 0 means image or swf or avi
	self.resourceType = nil;
	self.resourceName = nil;
end

function Canvas3D:GetRenderTargetSize()
	return self.RenderTargetSize;
end

function Canvas3D:SetRenderTargetSize(width, height)
	-- determine the render texture size. 
	local maxSize = math.max(width, height);
	local renderSize = 0;
	if(maxSize <= 32) then
		renderSize = 32;
	elseif(maxSize <= 64) then
		renderSize = 64;
	elseif(maxSize <= 128) then
		renderSize = 128;
	elseif(maxSize <= 256) then
		renderSize = 256;
	elseif(maxSize <= 512) then
		renderSize = 512;
	else
		renderSize = 1024;
	end
	self.RenderTargetSize = renderSize;
end

----------------------------------------------------
-- public methods
----------------------------------------------------

-- public: bind the canvas to an image. 
-- @param filename: the image file path or the image asset object. 
function Canvas3D:ShowImage(filename)
	if(not filename) then
		return
	end
	self.resourceType = 0;
	self.resourceName = filename;
	self:SetBackground(filename);
end

-- scale the bounding box
local function ScaleBoundingBox(bb, scale)
	if(bb and scale and scale~=1) then
		bb.min_x = bb.min_x*scale;
		bb.max_x = bb.max_x*scale;
		bb.min_y = bb.min_y*scale;
		bb.max_y = bb.max_y*scale;
		bb.min_z = bb.min_z*scale;
		bb.max_z = bb.max_z*scale;
	end
	return bb;
end

function Canvas3D:GetScene()
	return ParaScene.GetMiniSceneGraph(self.resourceName);
end
function Canvas3D:GetObject()
	local scene = ParaScene.GetMiniSceneGraph(self.resourceName);
	if(self.obj_name and scene and scene:IsValid())then
		return scene:GetObject(self.obj_name);
	end
end

-- public: bind the canvas to a given 3d model or character. it will reset the scene before adding the new model.
-- it will use the currently bind miniscene graph to display it. if no miniscene graph is bind, it will create a default one named "Canvas3D", which is 128*128 in size. 
-- @param obj: a newly created ParaObject or it can be objParams. Note: it can NOT be an object from the main scene or an attached object. 
-- @param bAutoAdjustCamera: true to automatically adjust camera to best view the obj. if nil, it means true. 
function Canvas3D:ShowModel(obj, bAutoAdjustCamera)
	if(bAutoAdjustCamera==nil) then
		bAutoAdjustCamera = true;
	end

	if(type(obj) == "table") then
		obj = ObjEditor.CreateObjectByParams(obj);
	end
	if(obj == nil or not obj:IsValid()) then
		-- if no model specified, remove all objects in the mini scene, otherwise the miniscene shows the last shown object
		if(self.resourceType == nil and self.resourceName~=nil and not self.ExternalSceneName) then
			local scene = ParaScene.GetMiniSceneGraph(self.resourceName);
			if(scene:IsValid()) then
				scene:DestroyChildren();
			end
		else
			-- self:ShowImage("")
		end
		return 
	end
	
	local scene;
	
	if(self.ExternalSceneName) then
		self.resourceName = self.ExternalSceneName;
		scene = ParaScene.GetMiniSceneGraph(self.resourceName);
	else
		if(self.resourceType == nil and self.resourceName~=nil) then
			scene = ParaScene.GetMiniSceneGraph(self.resourceName);
		else	
			-- create a default scene
			-------------------------
			-- a simple 3d scene using mini scene graph
			-------------------------
			local sceneName = self.Miniscenegraphname
			self.resourceName = sceneName;
			scene = ParaScene.GetMiniSceneGraph(sceneName);
		end	
	end	
	
	if(not self.ExternalSceneName and scene and (not scene:IsCameraEnabled() or scene:IsActiveRenderingEnabled() ~= self.IsActiveRendering)) then	
		------------------------------------
		-- init render target
		------------------------------------
		-- set size
		if(self.RenderTargetSize == nil) then
			scene:SetRenderTargetSize(128, 128);
		else
			scene:SetRenderTargetSize(self.RenderTargetSize, self.RenderTargetSize);
		end
		-- reset scene, in case this is called multiple times
		scene:Reset();
		-- enable camera and create render target
		scene:EnableCamera(true);
		-- render it each frame automatically. 
		scene:EnableActiveRendering(self.IsActiveRendering);
		
		local att = scene:GetAttributeObject();
		att:SetField("BackgroundColor", {1, 1, 1}); 
		att:SetField("ShowSky", false);
		att:SetField("EnableFog", false)
		att:SetField("EnableLight", false)
		att:SetField("EnableSunLight", false)
		-- set the transparent background color
		scene:SetBackGroundColor("127 127 127 0");
		att = scene:GetAttributeObjectCamera();
		if(self.FieldOfView) then
			att:SetField("FieldOfView", self.FieldOfView);
		end
		
		------------------------------------
		-- init camera
		------------------------------------
		scene:CameraSetLookAtPos(0,0.7,0);
		scene:CameraSetEyePosByAngle(0, 0.3, 5);
		
		if(self.mask_texture) then
			scene:SetMaskTexture(ParaAsset.LoadTexture("", self.mask_texture, 1));
		end
	end
	
	--if(not self.ExternalSceneName and scene) then
		-- bind to the mini scene graph
		--self:ShowMiniscene(scene:GetName())	
	--end
	
	if(scene:IsValid()) then
		if(not self.ExternalSceneName) then
			-- clear all. 
			scene:DestroyChildren();
		else
			-- clear just the object in the external scene.
			scene:DestroyObject(self.Miniscenegraphname);
			obj:SetName(self.Miniscenegraphname);
			if(scene:IsCameraEnabled()) then
				obj:SetFacing(self.DefaultRotY or 0);
			end
		end	
		-- set the object to center. 
		obj:SetPosition(0 + self.ExternalOffsetX,0 + self.ExternalOffsetY,0 + self.ExternalOffsetZ);
		self.obj_name = obj:GetName();
		scene:AddChild(obj);
		-- set camera
		if(not self.ExternalSceneName) then
			local asset = obj:GetPrimaryAsset();
			if(asset:IsValid())then
				local bb = {min_x = -0.5, max_x=0.5, min_y = -0.5, max_y=0.5,min_z = -0.5, max_z=0.5,};
				local scale = obj:GetScale();
				if(asset:IsLoaded() or (self.LookAtHeight and self.DefaultCameraObjectDist))then
					bb = asset:GetBoundingBox(bb);
					bb = ScaleBoundingBox(bb, scale);
				elseif(bAutoAdjustCamera) then
					-- we shall start a timer, to refresh the bounding box once the asset is loaded. 	
					NPL.load("(gl)script/ide/AssetPreloader.lua");
					self.loader = self.loader or commonlib.AssetPreloader:new({
						callbackFunc = function(nItemsLeft)
							if(nItemsLeft == 0) then
								-- NOTE: since asset object are never garbage collected, we will assume asset is still valid at this time. 
								-- However, this can not be easily assumed if I modified the game engine asset logics.
								if(self.asset_ and self.asset_:IsLoaded()) then
									local bb = self.asset_:GetBoundingBox(bb);
									bb = ScaleBoundingBox(bb, self.scale_ or 1);

									--todo:add camera name parameter 
									local camInfo = CanvasCamConfig.QueryCamInfo(self.asset_:GetKeyName(),self.cameraName);
									if(camInfo~=nil)then
										self:AdjustCamera(camInfo,bb,self.scale_ or 1);
									else
										self:AutoAdjustCameraByBoundingBox(bb);
									end
									self.asset_ = nil;
								end	
							end
						end
					});
					self.loader:clear();
					self.loader:AddAssets(asset);
					self.asset_ = asset
					self.scale_ = scale;
					self.loader:Start();
				end	

				if(bAutoAdjustCamera and not self.ExternalSceneName) then
					local key_filename = asset:GetKeyName();
					local camInfo = CanvasCamConfig.QueryCamInfo(key_filename,self.cameraName);
					if(camInfo~=nil)then
						self:AdjustCamera(camInfo,bb,scale);
					else					
						self:AutoAdjustCameraByBoundingBox(bb);
					end
				end	
			end
		else
			if(self.IgnoreExternalCamera and not scene:IsCameraEnabled()) then
				self:CameraSetEyePosByAngle(self.DefaultRotY, self.DefaultLiftupAngle, self.DefaultCameraObjectDist);
			end
		end	
	else
		commonlib.applog("warning: Canvas3D can not find a miniscene to render to \n")	;
	end
end

-- change background color, alpha channel is supported. 
-- @param color: such as "255 255 255 0".
function Canvas3D:SetBackgroundColor(color)
	if(self.resourceName and not self.ExternalSceneName) then
		local scene = ParaScene.GetMiniSceneGraph(self.resourceName);
		-- set the transparent background color
		scene:SetBackGroundColor(color or "255 255 255 0");
	end
end
-- set the facing of the current model if any. This function can be used to rotate the model. 
-- @param facing: facing value in rad. 
-- @param bIsDelta: if true, facing will be addictive. 
function Canvas3D:SetModelFacing(facing, bIsDelta)
	if(facing and self.resourceName) then
		local scene = ParaScene.GetMiniSceneGraph(self.resourceName);
		local obj = scene:GetObject(self.Miniscenegraphname);
		if(obj:IsValid()) then
			if(bIsDelta) then
				obj:SetFacing(obj:GetFacing()+facing);
			else
				obj:SetFacing(facing);
			end
		end
	end	
end

-- adjust the bounding box so that the camera can best view a given bounding box. 
-- @param bb: the bounding box {min_x = -0.5, max_x=0.5, min_y = -0.5, max_y=0.5,min_z = -0.5, max_z=0.5,} to be contained in the view. 
function Canvas3D:AutoAdjustCameraByBoundingBox(bb)
	if(self.resourceName and not self.ExternalSceneName) then
		local scene = ParaScene.GetMiniSceneGraph(self.resourceName);
		
		if(scene:IsValid()) then
			local x,y,z = (bb.max_x - bb.min_x), (bb.max_y - bb.min_y), (bb.max_z - bb.min_z)
			local dist = math.max(x,y,z)
			if(dist == 0) then
				dist = 3;
			end
			scene:CameraSetLookAtPos(0,self.LookAtHeight or (bb.max_y + bb.min_y)*0.618,0);
			--[[ 
			local cameradist = (dist+2);
			if(dist < 0.5) then
				cameradist = dist * 4;
			elseif(dist > 5 and dist <=10) then
				cameradist = dist*2 + math.max(x,z,2);
			elseif(dist > 10) then
				cameradist = dist*2;
			end]]
			local cameradist = math.max(z,y,0.5)*1.2 + math.max(x,z) * 0.5 + 0.5; -- x or z is the depth
			if(cameradist < self.MinZoomDist) then
				cameradist = self.MinZoomDist;
			end
			scene:CameraSetEyePosByAngle(self.DefaultRotY or 2.7, self.DefaultLiftupAngle or 0.3, self.DefaultCameraObjectDist or cameradist);
			self.MaxZoomDist = math.max(cameradist*3+self.MinZoomDist, self.MaxZoomDist or 0);
		end	
	end
end

-- adjust camera by camInfo and bounding box
function Canvas3D:AdjustCamera(camInfo,bb,scale)
	if(self.resourceName and not self.ExternalSceneName) then
		local scene = ParaScene.GetMiniSceneGraph(self.resourceName);
			
		if(scene:IsValid()) then
			local lookAtY;
			if(camInfo.lookAtY)then
				lookAtY = camInfo.lookAtY * scale;
			else
				lookAtY = self.LookAtHeight or (bb.max_y + bb.min_y)*0.618;
			end
			scene:CameraSetLookAtPos(0,lookAtY,0);			

			local cameradist;
			if(camInfo.dist)then
				cameradist = camInfo.dist * scale;
			else
				local x,y,z = (bb.max_x - bb.min_x), (bb.max_y - bb.min_y), (bb.max_z - bb.min_z)
				cameradist = math.max(z,y,0.5)*1.2 + math.max(x,z) * 0.5 + 0.5; -- x or z is the depth
			end
			if(cameradist < self.MinZoomDist) then
				cameradist = self.MinZoomDist;
			end


			local camRotY;
			if(camInfo.rotY)then
				camRotY = camInfo.rotY;
			else
				camRotY = self.DefaultRotY or 2.7;
			end

			local camLiftUp;
			if(camInfo.liftUp)then
				camLiftUp = camInfo.liftUp;
			else
				camLiftUp = self.DefaultLiftupAngle or 0.3;
			end
											
			scene:CameraSetEyePosByAngle(camRotY, camLiftUp, self.DefaultCameraObjectDist or cameradist);
			self.MaxZoomDist = math.max(cameradist*3+self.MinZoomDist, self.MaxZoomDist or 0);
		end	
	end
end

-- public: save the canvas content to file
-- @param filename: sFileName a texture file path to save the file to. 
--  we support ".dds", ".jpg", ".png" files. If the file extension is not recognized, ".png" file is used. 
-- @param nImageSize: if this is zero, the original size is used. If it is dds, all mip map levels are saved.
function Canvas3D:SaveToFile(filename, imageSize)
	commonlib.echo({filename, imageSize});
	if(self.resourceType == nil and not self.ExternalSceneName) then
		local scene = ParaScene.GetMiniSceneGraph(self.resourceName);
		if(scene:IsValid()) then
			imageSize = imageSize or 0;
			ParaIO.CreateDirectory(filename);
			return scene:SaveToFile(filename, imageSize);
		end	
	end	
end

-- adopt the mini scene graph position. 
function Canvas3D.AdoptMiniSceneCamera(scene)
	if(scene) then
		local fRotY, fLiftupAngle, fCameraObjectDist = scene:CameraGetEyePosByAngle();
		local att = ParaCamera.GetAttributeObject();
		att:SetField("CameraObjectDistance", fCameraObjectDist);
		att:SetField("CameraLiftupAngle", fLiftupAngle);
		att:SetField("CameraRotY", fRotY);
	end
end

-- directly set the camera look at position with engine api calls
function Canvas3D.CameraSetLookAtPos(fLookAtX, fLookAtY, fLookAtZ)
	if(self.resourceType == nil and not self.ExternalSceneName) then
		local scene = ParaScene.GetMiniSceneGraph(self.resourceName);
		if(scene:IsValid()) then
			scene:CameraSetLookAtPos(fLookAtX, fLookAtY, fLookAtZ);
		end
	end
end

-- directly set the camera angle with engine api calls
function Canvas3D:CameraSetEyePosByAngle(fRotY, fLiftupAngle, fCameraObjectDist)
	if(self.resourceType == nil) then
		local scene = ParaScene.GetMiniSceneGraph(self.resourceName);
		if(scene:IsValid()) then
			scene:CameraSetEyePosByAngle(fRotY, fLiftupAngle, fCameraObjectDist);
			
			if(self.ExternalSceneName and self.IgnoreExternalCamera and not scene:IsCameraEnabled()) then
				Canvas3D.AdoptMiniSceneCamera(scene);
			end
		end
	end
end

-- set the canvas mask texture
function Canvas3D:SetMaskTexture(textureFile)
	if(self.resourceType == nil and not self.ExternalSceneName) then
		local scene = ParaScene.GetMiniSceneGraph(self.resourceName);
		if(scene:IsValid()) then
			scene:SetMaskTexture(ParaAsset.LoadTexture("", textureFile, 1));
		end
	end
end

function Canvas3D:mousePressEvent(e)
	self.lastMouseDown.x = e:pos():x();
	self.lastMouseDown.y = e:pos():y();
	self.IsMouseDown = true;
	self.lastMousePos.x = e:pos():x();
	self.lastMousePos.y = e:pos():y();
	if (e:button() == "middle") then
		self.IsMidMouseDown = true;
	end
	e:accept();
end

function Canvas3D:mouseMoveEvent(e)
	if (self.IsMouseDown) then
		local mouse_dx, mouse_dy = e:pos():x() - self.lastMousePos.x, e:pos():y() - self.lastMousePos.y;
		if (mouse_dx ~= 0 or mouse_dy ~= 0) then
			if (self.resourceName ~= nil) then
				if (self.resourceType == nil) then
					local scene = ParaScene.GetMiniSceneGraph(self.resourceName);
					if(scene:IsValid()) then
						if(not self.ExternalSceneName) then
							-- rotate camera for local scene
							if(self.IsMidMouseDown) then
								-- if middle button is down, it is panning along the vertical position. 
								if(mouse_dy~=0) then
									local at_x, at_y, at_z = scene:CameraGetLookAtPos();
									local eye_x, eye_y, eye_z = scene:CameraGetEyePos();
									local fRotY, fLiftupAngle, fCameraObjectDist = scene:CameraGetEyePosByAngle();
									local deltaY = self.PanSpeed*math.max(fCameraObjectDist,0.1)*mouse_dy;
									at_y = at_y + deltaY;
									eye_y = eye_y + deltaY;
									scene:CameraSetLookAtPos(at_x, at_y, at_z);
									scene:CameraSetEyePos(eye_x, eye_y, eye_z);
								end	
							else
								-- left or right button is down, it is rotation around the current position
								
								local fRotY, fLiftupAngle, fCameraObjectDist = scene:CameraGetEyePosByAngle();
								fRotY = fRotY+mouse_dx*self.RotSpeed; --how many degrees per pixel movement
								fLiftupAngle = fLiftupAngle + mouse_dy*self.RotSpeed; --how many degrees per pixel movement
								if(fLiftupAngle>self.MaxLiftupAngle) then
									fLiftupAngle = self.MaxLiftupAngle;
								end
								if(fLiftupAngle<self.MinLiftupAngle) then
									fLiftupAngle = self.MinLiftupAngle;
								end
								scene:CameraSetEyePosByAngle(fRotY, fLiftupAngle, fCameraObjectDist);
							end	
						else
							-- TODO: rotate object for external scene. 
						end	
					end
				elseif (self.resourceType == 0) then
				end
			end
		end
		e:accept();
	end

	self.lastMousePos.x = e:pos():x();
	self.lastMousePos.y = e:pos():y();
end

function Canvas3D:mouseReleaseEvent(e)
	if (not self.IsMouseDown) then
		return;
	end
	self.IsMouseDown = false;
	self.IsMidMouseDown = false;
	local dragDist = (math.abs(self.lastMousePos.x-self.lastMouseDown.x) + math.abs(self.lastMousePos.y-self.lastMouseDown.y));
	if(dragDist<=2) then
		-- this is mouse click event if mouse down and mouse up distance is very small.
	end
	self.lastMousePos.x = e:pos():x();
	self.lastMousePos.y = e:pos():y();
	e:accept();
end

function Canvas3D:mouseWheelEvent(e)
	if (self.resourceName == nil) then
		return;
	end
	if (self.resourceType == nil) then
		--
		-- 3D scene
		--
		local scene = ParaScene.GetMiniSceneGraph(self.resourceName);
		if(scene:IsValid()) then
			if(not self.ExternalSceneName) then
				-- zoom camera for local scene
				local fRotY, fLiftupAngle, fCameraObjectDist = scene:CameraGetEyePosByAngle();
				fCameraObjectDist = fCameraObjectDist*math.pow(1.1, -e:GetDelta()); --how many scales per wheel delta movement
				if(fCameraObjectDist>self.MaxZoomDist) then
					fCameraObjectDist = self.MaxZoomDist;
				end
				if(fCameraObjectDist<self.MinZoomDist) then
					fCameraObjectDist = self.MinZoomDist;
				end
				scene:CameraSetEyePosByAngle(fRotY, fLiftupAngle, fCameraObjectDist);
			else
				-- TODO: scale character for external scene
			end	
		end
	elseif(self.resourceType == 0)then	
		--
		-- 2D image
		--
	end	
end

function Canvas3D:mouseEnterEvent(mouse_event)
end

function Canvas3D:mouseLeaveEvent(mouse_event)
end

function Canvas3D:paintEvent(painter)
	if (self.resourceName == nil) then
		return;
	end
	if(self.resourceType == nil) then
		local scene = ParaScene.GetMiniSceneGraph(self.resourceName);
		--
		-- 3D scene
		--
		if(not self.IsMouseDown and self.AutoRotateSpeed and self.AutoRotateSpeed~=0) then
			local scene = ParaScene.GetMiniSceneGraph(self.resourceName);
			if(scene:IsValid()) then
				if(not self.ExternalSceneName) then
					-- rotate camera for local scene
					local fRotY, fLiftupAngle, fCameraObjectDist = scene:CameraGetEyePosByAngle();
					fRotY = fRotY+self.AutoRotateSpeed*deltatime; --how many degrees per frame move
					scene:CameraSetEyePosByAngle(fRotY, fLiftupAngle, fCameraObjectDist);
				else
					-- rotate object for external scene
					local obj = scene:GetObject(self.Miniscenegraphname);
					if(obj:IsValid()) then
						local fRotY = obj:GetFacing();
						fRotY = fRotY+self.AutoRotateSpeed*deltatime; --how many degrees per frame move
						if(fRotY > 6.28) then
							fRotY = fRotY - 6.28;
						end
						obj:SetFacing(fRotY);
					end	
				end
			end	
		end

		if(scene:IsValid()) then
			scene:Draw(0);
			painter:SetPen(self:GetBackgroundColor());
			painter:DrawRectTexture(self:x(), self:y(), self:width(), self:height(), scene:GetTexture());
		end
	end
end