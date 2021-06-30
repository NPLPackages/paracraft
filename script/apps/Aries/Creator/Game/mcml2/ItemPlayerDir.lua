local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
NPL.load("(gl)script/ide/System/Windows/UIElement.lua");
local ItemPlayerDir = commonlib.inherit(commonlib.gettable("System.Windows.UIElement"), commonlib.gettable("MyCompany.Aries.Game.mcml2.ItemPlayerDir"));
ItemPlayerDir:Property({"PlayerIconColor", "#ffffffcc"});
ItemPlayerDir:Property({"PlayerIcon", "Texture/Aries/Creator/keepwork/map/maparrow_32bits.png", auto=true});
ItemPlayerDir:Property({"PlayerIconSize", 32, auto=true});
ItemPlayerDir:Property({"PlayerIconCenterX", 16, auto=true});
ItemPlayerDir:Property({"PlayerIconCenterY", 19, auto=true});

function ItemPlayerDir:ctor()

end

function ItemPlayerDir:paintEvent(painter)
	local player = EntityManager.GetPlayer();
    if(player) then
        local bx, by, bz = player:GetBlockPos();
        local facing = ParaCamera.GetAttributeObject():GetField("CameraRotY", 0);
        painter:Save()
        painter:SetPen(self.PlayerIconColor);

        painter:PushMatrix()
        painter:Translate(self:x(), self:y() )
        painter:Rotate(facing / math.pi * 180)
        local iconSize = self.PlayerIconSize;
        painter:DrawRectTexture( - self.PlayerIconCenterX,  -self.PlayerIconCenterY, iconSize, iconSize, self.PlayerIcon)
        painter:PopMatrix()

        painter:Restore()
    end
end