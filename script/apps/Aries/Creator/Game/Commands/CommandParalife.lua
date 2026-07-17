--[[
Title: CommandParalife
Author(s): hyz
Date: 2015/7/22
Desc: entity walk action
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandParalife.lua");
-------------------------------------------------------
]]
local SlashCommand = commonlib.gettable("MyCompany.Aries.SlashCommand.SlashCommand");
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local block = commonlib.gettable("MyCompany.Aries.Game.block")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Commands = commonlib.gettable("MyCompany.Aries.Game.Commands");
local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLife.lua");
local ParaLife = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLife")
local ParalifeLiveModel = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParalifeLiveModel.lua");

NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeBuy.lua");
local ParaLifeBuy = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Paralife")
local ParaLifeFrontPage = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeFrontPage")

--根据活动模型名字或者电影方块位置找到entity
local function _parseEntityByPosOrName(cmd_text, fromEntity)
    local name,x,y,z
    x,y,z, cmd_text = CmdParser.ParsePos(cmd_text, fromEntity);
    if x==nil or y==nil or z==nil then
        name,cmd_text = CmdParser.ParseString(cmd_text, fromEntity)
        if name then
            return EntityManager.GetEntity(name),cmd_text
        end
    else
        local entities = EntityManager.GetEntitiesInBlock(x, y, z);
        if(entities) then
            for entity,_ in pairs(entities) do
                if(entity:GetType() == EntityManager.EntityLiveModel.class_name or entity:GetType() == EntityManager.EntityMovieClip.class_name) then
                    return entity,cmd_text
                end
            end
        end
    end
    return nil,cmd_text
end

Commands["paralife"] = {
	name="paralife", 
	quick_ref="/paralife [show|hide|buy|checkbuy|openbook] [-addbag|-askonce|setbag|setbagtype|pickbagitem|clearbag|showbag|-mobilepad]", 
	desc=[[paralife logic. 
@param show: show paralife mode [-showplayer -noedit -nobackbutton -nobookbutton]
@param hide: hide paralife mode
@param setbag [x|name],[y],[z]: set the data source of paralife bag with a movie entity's pos or live entity's name
@param addbag [x|name],[y],[z]: add a paralife bag data source with a live entity
@param clearbag: clear the paralife bag
@param buy [-askonce] product_id: buy a product by product_id. Product is bound to mac address.  
  if -askonce is not specified, we will block the user until payment is done.
@param checkbuy|buy product_id: return true if the given product(product_id) is already purchased.
@param openbook: open the default manul book. 
@param pathfinding: handles pathfinding logic. [-jumpHeightWhileHidden] set jump height while hidden
e.g.
/paralife show -showplayer -noedit -nobackbutton -nobookbutton -nofacial -nobag
/paralife show -mobilepad  this command is equal (/paralife show -noedit -nobackbutton -nobookbutton -nofacial -nobag)
/paralife hide
/paralife setbagtype grid
/paralife setbagtype gridbottom  |  gridtop  [-count=8] [-size=48]
/paralife showbag
/paralife setbag 19200 11 19200
/paralife addbag myLiveModelName
/paralife pickbagitem staticTag|templates/xxx.bmx
/paralife clearbag
/paralife checkbuy project_123123
/paralife buy -askonce project_123123
/paralife openbook
/paralife pathfinding -jumpHeightWhileHidden 4
/paralife set_bag_enable_human false
]], 
	handler = function(cmd_name, cmd_text, cmd_params, fromEntity)
		local sub_cmd,entity
		sub_cmd, cmd_text = CmdParser.ParseString(cmd_text, fromEntity);
		if sub_cmd=="show" then
            local options
            local option, cmd_text = CmdParser.ParseOption(cmd_text);
            if option == "mobilepad" then
                options= {noedit =  true,nobookbutton = true,nobackbutton = true,nofacial = true,nobag = true}
                ParaLife:SetShowOptions(options)
                ParaLife:SetEnabled(true)
            else
                
                options, cmd_text = CmdParser.ParseOptions(cmd_text);
                -- print("-------options")
                -- for k,v in pairs(options) do
                --     print("-----k,v",k,v,type(v))
                -- end
                ParaLife:SetShowOptions(options)
                ParaLife:SetEnabled(true)
            end
        elseif sub_cmd=="hide" then
			ParaLife:SetEnabled(false)
        elseif sub_cmd=="setbag" then
            entity, cmd_text = _parseEntityByPosOrName(cmd_text, fromEntity)
            if entity then 
                ParalifeLiveModel.SetBagDataWithEntity(entity)
            end
            -- ParaLife:Show()
            -- ParalifeLiveModel.ShowView()
            -- ParalifeLiveModel.SwitchOperateButton("switchrole")
        elseif sub_cmd=="addbag" then
            entity, cmd_text = _parseEntityByPosOrName(cmd_text, fromEntity)
            if entity then 
                local options;
                options,cmd_text = CmdParser.ParseOptions(cmd_text);
                ParalifeLiveModel.AddBagDataWithEntity(entity,options)
            end
        elseif sub_cmd=="clearbag" then
            ParalifeLiveModel.ClearBag()
            GameLogic.AddBBS(nil,L"背包已清理")
        elseif sub_cmd=="hidebagbtn" then
            local isHide = false;
            isHide, cmd_text = CmdParser.ParseBool(cmd_text);

            ParaLife:SetNoBagBtn(isHide or false)
            ParalifeLiveModel.RefreshPage()
        elseif sub_cmd=="showbag" or sub_cmd=="openbag" then
            ParaLife:SetEnabled(true)
            ParaLifeFrontPage.OnClickPlay()
            ParalifeLiveModel.SwitchOperateButton("switchrole")
            ParaLife:SetNoBagBtn(isHide or false)
            ParalifeLiveModel.RefreshPage()
        elseif sub_cmd=="pickbagitem" then --根据模型名字或者静态标签拾取背包物品（如果是手动拖进去背包的，也可以直接通过name），返回一个函数调用
            local nameOrTag;
            nameOrTag, cmd_text = CmdParser.ParseString(cmd_text);
            return ParalifeLiveModel.PickBagItemByModelNameOrStaticTag(nameOrTag or false)
		elseif sub_cmd=="openbook" then
            NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeBook.lua");
			local ParaLifeBook = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeBook")
			ParaLifeBook.ShowPage(true)
        elseif sub_cmd=="buy" then
            local options
            options, cmd_text = CmdParser.ParseOptions(cmd_text);
            local loopAsk = true
            if options.askonce == true then
                loopAsk = false
            end
            ParaLifeBuy:Buy(cmd_text,loopAsk)
        elseif sub_cmd=="checkbuy" then
            local options
            options, cmd_text = CmdParser.ParseOptions(cmd_text);
            return ParaLifeBuy:CheckBuy(cmd_text)
        elseif sub_cmd=="setbagtype" then
            local _type,options;
            _type,cmd_text = CmdParser.ParseString(cmd_text, fromEntity)
            if _type=="grid" then
                ParalifeLiveModel.SetBagTypeGird()
            elseif _type=="gridbottom" then
                options, cmd_text = CmdParser.ParseOptions(cmd_text);
                ParalifeLiveModel.SetBagTypeBottom(options)
            elseif _type=="gridtop" then
                options = CmdParser.ParseOptionsNameValue(cmd_text);
                ParalifeLiveModel.SetBagTypeTop(options)
            else
                ParalifeLiveModel.SetBagTypeDefault()
            end
        elseif sub_cmd=="set_bag_enable_human" then
            local enable,options;
            enable,cmd_text = CmdParser.ParseString(cmd_text, fromEntity)
            enable = enable~="false"
            NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParalifeBagPage.lua");
            local ParalifeBagPage = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParalifeBagPage");
            ParalifeBagPage.SetEnableHuman(enable)
        elseif sub_cmd=="remove" then
            entity, cmd_text = _parseEntityByPosOrName(cmd_text, fromEntity)
            if entity then 
                entity:SetDead()
                local options;
                options, cmd_text = CmdParser.ParseOptions(cmd_text);
                if options.tip then
                    GameLogic.AddBBS(nil,L"成功删除一个模型实体")
                end
            end
        elseif sub_cmd=="pathfinding" then
            local options, cmd_text = CmdParser.ParseOptions(cmd_text);
            if options.jumpHeightWhileHidden then
                local jump_height = tonumber(cmd_text)
                ParaLife:SetLinePathJumpHeightWhileHidden(jump_height)
            end
        end
	end,
};