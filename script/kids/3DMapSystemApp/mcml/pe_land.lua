

--[[

This file is **deprecated** !!! see script/kids/3DMapSystemUI/Map/pe_land.lua and 
script/kids/3DMapSystemUI/Map/pe_land.html for new land window

--]]

----------------------------------------------------------------------
-- pe_land: handles MCML tag <pe:land>
----------------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemUI/Map/Map3DAppDataPvd.lua");

if(not Map3DSystem.mcml_controls) then Map3DSystem.mcml_controls = {}; end
local pe_land = {};
Map3DSystem.mcml_controls.pe_land = pe_land;

-- display land tile info
function pe_land.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	--local instName;
	--if(mcmlNode:GetAttribute("name") or mcmlNode:GetAttribute("id")) then
		--instName = mcmlNode:GetInstanceName(rootName);
	--end

	pe_land.CreateUI(rootName,mcmlNode,_parent,items);
	Map3DSystem.mcml_controls.pe_simple_styles.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout);

	local id = mcmlNode:GetAttribute("value") or mcmlNode:GetInnerText();
	id = tonumber(id);
	if(id == nil)then
		return;
	end

	mcmlNode.tileId = tonumber(id);
	pe_land.Update(mcmlNode);
end

function pe_land.SetTileID(mcmlNode,tileID)
	local node = mcmlNode;
	if(node.name ~= "pe:land")then
		node = mcmlNode:GetParent("pe:land");
	end
	if(node == nil)then
		return;
	end
	
	node.tileId = tileID;
end

--update data form web service
function pe_land.Update(mcmlNode)
	local node = mcmlNode;
	if(node.name ~= "pe:land")then
		node = mcmlNode:GetParent("pe:land");
	end
	if(node == nil)then
		return;
	end
	
	if(node.tileId ~= nil)then
		Map3DApp.DataPvd.GetTileByID(node.tileId,node,pe_land.SetData);
	end
end

--public:bind data to ui
--this fucntion will be invoked when web service return;
function pe_land.SetData(mcmlNode,tileInfo)
	if(mcmlNode == nil or tileInfo == nil)then
		return;
	end

	local pageInstName = mcmlNode:GetPageCtrl().name;
	if(pageInstName == nil)then
		return;
	end

	--land name
	local pe_land = Map3DSystem.mcml_controls.pe_land;
	local node = mcmlNode:SearchChildByAttribute("name","landName");
	if(node)then
		if(tileInfo.name)then
			node:SetValue(tileInfo.name);
		else
			node:SetValue("未命名土地");
		end
		pe_land.RefreshNode(node,pageInstName);
	end
	
	--city name
	node = mcmlNode:SearchChildByAttribute("name","city");
	if(node)then
		if(tileInfo.cityName)then
			node:SetValue(tileInfo.cityName);
		else
			node:SetValue("无名之城");
		end
		pe_land.RefreshNode(node,pageInstName);
	end
	
	--owner name
	node = mcmlNode:SearchChildByAttribute("name","owner");
	if(node)then
		if(tileInfo.ownerUserName)then
			node:SetValue(tileInfo.ownerUserName);
		else
			node:SetValue("ParaEngine");
		end
		pe_land.RefreshNode(node,pageInstName);
	end
	
	--user name 
	node = mcmlNode:SearchChildByAttribute("name","user");
	if(node)then
		if(tileInfo.username)then
			node:SetValue(tileInfo.username);
		else
			node:SetValue(tileInfo.ownerUserName or "ParaEngine");
		end
		pe_land.RefreshNode(node,pageInstName);
	end

	--price
	node = mcmlNode:SearchChildByAttribute("name","price");
	if(node)then
		if(tileInfo.price)then
			node:SetValue(tileInfo.price);
		else
			node:SetValue("0");
		end
		pe_land.RefreshNode(node,pageInstName);
	end
	
	--land state
	node = mcmlNode:SearchChildByAttribute("name","landState");
	if(node)then
		if(tileInfo.tileState)then
			node:SetValue(Map3DApp.DataPvd.TranslateTileState(tileInfo.tileState));
		else
			node:SetValue("未开放土地");
		end
		pe_land.RefreshNode(node,pageInstName);
	end

	-- land id
	node = mcmlNode:SearchChildByAttribute("name","landID");
	if(node)then
		if(tileInfo.id)then
			if(tileInfo.id == 0)then
				node:SetValue(tostring(mcmlNode.tileId) or tostring(tileInfo.id));
			else
				node:SetValue(tostring(tileInfo.id));
			end
		else
			node:SetValue("0");
		end
		pe_land.RefreshNode(node,pageInstName);
	end
	
	--TODO:display world name,register onclick event and open world download window;
	--for now,the tileInfo.world is always a nil value,you can hard code one to test;
	node = mcmlNode:SearchChildByAttribute("name","myWorld");
	if(node)then
		if(tileInfo.world)then
			--set world name here
			node:SetValue()
			--set event 
			node:SetAttribute("onclick","");
		else
			node:SetValue("未设置世界");
			node:SetAttribute("onclick","");
		end
		pe_land.RefreshNode(node,pageInstName);
	end
	
	pe_land.ShowEditBtn(mcmlNode,pageInstName,tileInfo);
end

--private:create all control
function pe_land.CreateUI(rootName,mcmlNode,_parent)
	local node;	
	local formNode = Map3DSystem.mcml.new(nil,{name="pe:container"});
	formNode:SetAttribute("style","width:220;height:380");
	formNode:SetAttribute("name","ctnName");
	mcmlNode:AddChild(formNode,nil);
	
	node = Map3DSystem.mcml.new(nil,{name="label"});
	node:SetInnerText("土地信息");
	node:SetAttribute("style", "color:#006699;height:16px;margin-top:0px;margin-left:80px;margin-right:10px;width:50px;text-align:center");
	formNode:AddChild(node,nil);

	node = Map3DSystem.mcml.new(nil,{name="hr"});
	formNode:AddChild(node,nil);

	--decide which items to show
	local items =  pe_land.ItemFilter(mcmlNode);
	 
	local formHeight = 60;
	if(items.name)then
		node = Map3DSystem.mcml.new(nil,{name="div"});
		node:SetAttribute("style","color:#535353;width:55px;float:left;text-align:right");
		node:SetInnerText("土地名:");
		formNode:AddChild(node);

		node = Map3DSystem.mcml.new(nil,{name="label"});
		node:SetAttribute("style","margin-left:4px;width:140px;height:18;");
		node:SetAttribute("name","landName");
		formNode:AddChild(node);
	
		node = Map3DSystem.mcml.new(nil,{name="br"});
		formNode:AddChild(node);
		formHeight = formHeight + 25;
	end
	
	if(items.owner)then
		node = Map3DSystem.mcml.new(nil,{name="div"});
		node:SetAttribute("style","color:#535353;width:55px;float:left;text-align:right");
		node:SetInnerText("所有者:");
		formNode:AddChild(node);
		
		node = Map3DSystem.mcml.new(nil,{name="label"});
		node:SetAttribute("style","margin-left:4px;width:140px;height:18;");
		node:SetAttribute("name","owner");
		formNode:AddChild(node);
		
		node = Map3DSystem.mcml.new(nil,{name="br"});
		formNode:AddChild(node);
		formHeight = formHeight + 25;
	end
	
	if(items.user)then	
		node = Map3DSystem.mcml.new(nil,{name="div"});
		node:SetInnerText("使用者:");
		node:SetAttribute("style","color:#535353;width:55px;float:left;text-align:right");
		formNode:AddChild(node);
		
		node = Map3DSystem.mcml.new(nil,{name="label"});
		node:SetAttribute("style","margin-left:4px;width:140px;height:18;");
		node:SetAttribute("name","user");
		formNode:AddChild(node);
		
		node = Map3DSystem.mcml.new(nil,{name="br"});
		formNode:AddChild(node);
		formHeight = formHeight + 25;
	end
	
	if(items.city)then
		node = Map3DSystem.mcml.new(nil,{name="div"});
		node:SetAttribute("style","color:#535353;width:55px;float:left;text-align:right;");
		node:SetInnerText("所属城市:");
		formNode:AddChild(node);
		
		node = Map3DSystem.mcml.new(nil,{name="label"});
		node:SetAttribute("name","city");
		node:SetAttribute("style","margin-left:4px;width:140px;height:18;");
		formNode:AddChild(node);
		
		node = Map3DSystem.mcml.new(nil,{name="br"});
		formNode:AddChild(node);
		formHeight = formHeight + 25;
	end
	
	if(items.state)then
		node = Map3DSystem.mcml.new(nil,{name="div"});
		node:SetAttribute("style","color:#535353;width:55px;float:left;text-align:right");
		node:SetInnerText("土地状态:");
		formNode:AddChild(node);
		
		node = Map3DSystem.mcml.new(nil,{name="label"});
		node:SetAttribute("style","margin-left:4px;width:140px;height:18;");
		node:SetAttribute("name","landState");
		formNode:AddChild(node);
		
		node = Map3DSystem.mcml.new(nil,{name="br"});
		formNode:AddChild(node);
		formHeight = formHeight + 25;
	end
	
	if(items.price)then
		node = Map3DSystem.mcml.new(nil,{name="div"});
		node:SetAttribute("style","color:#535353;width:55px;float:left;text-align:right");
		node:SetInnerText("售价:");
		formNode:AddChild(node);
		
		node = Map3DSystem.mcml.new(nil,{name="label"});
		node:SetAttribute("style","margin-left:4px;width:140px;height:18;");
		node:SetAttribute("name","price");
		formNode:AddChild(node);
		
		node = Map3DSystem.mcml.new(nil,{name="br"});
		formNode:AddChild(node);
		formHeight = formHeight + 25;
	end
	
	if(items.rank)then
		node = Map3DSystem.mcml.new(nil,{name="div"});
		node:SetAttribute("style","color:#535353;width:55px;float:left;text-align:right");
		node:SetInnerText("土地评级:");
		formNode:AddChild(node);
		
		node = Map3DSystem.mcml.new(nil,{name="img"});
		node:SetAttribute("style",";margin-left:4px;background:url(Texture/3DMapSystem/3DMap/stars.png);width:100px;height:16");
		formNode:AddChild(node);
		
		node = Map3DSystem.mcml.new(nil,{name="br"});
		formNode:AddChild(node);
		formHeight = formHeight + 25;
	end
	
	if(items.landID)then
		node = Map3DSystem.mcml.new(nil,{name="div"});
		node:SetAttribute("style","color:#535353;width:55px;float:left;text-align:right");
		node:SetInnerText("土地编号:");
		formNode:AddChild(node);
		
		
		node = Map3DSystem.mcml.new(nil,{name="label"});
		node:SetAttribute("style","margin-left:4px;width:140px;height:18;");
		node:SetAttribute("name","landID");
		formNode:AddChild(node);

		node = Map3DSystem.mcml.new(nil,{name="br"});
		formNode:AddChild(node);
		formHeight = formHeight + 25;
	end

	if(items.homeWorld)then
		node = Map3DSystem.mcml.new(nil,{name="div"});
		node:SetAttribute("style","margin-top:2px;color:#535353;width:55px;float:left;text-align:right");
		node:SetInnerText("家园世界:");
		formNode:AddChild(node);
		
		node = Map3DSystem.mcml.new(nil,{name="input"});
		node:SetAttribute("type","button");
		node:SetAttribute("name","myWorld");
		node:SetAttribute("style", "margin-top:0px;color:#000066;background:;background2:url(Texture/3DMapSystem/common/href.png:2 2 2 2)");
		node:SetAttribute("value","未设置世界")
		formNode:AddChild(node);
		
		node = Map3DSystem.mcml.new(nil,{name="br"});
		formNode:AddChild(node);
		
		node = Map3DSystem.mcml.new(nil,{name="img"});
		node:SetAttribute("style","margin-left:10;background:url(Texture/productcover_exit_cn.png);width:192px;height:108");
		formNode:AddChild(node);
		
		node = Map3DSystem.mcml.new(nil,{name="br"});
		formNode:AddChild(node);
		formHeight = formHeight + 25;
	end
	
	node = Map3DSystem.mcml.new(nil,{name="input"});
	node:SetAttribute("type","button");
	node:SetAttribute("name","editBtn");
	node:SetAttribute("style","margin-top:4px;margin-left:120;width:80px;height:20px");
	node:SetAttribute("value","");
	--node:SetAttribute("onclick","Map3DSystem.mcml_controls.pe_land.Test");
	formNode:AddChild(node,nil);
	
	formNode:SetAttribute("style",string.format("hegiht:%s;width:220",formHeight));
end

--private:decide which items to be show
function pe_land.ItemFilter(mcmlNode)
	local items = {name=false,city=false,owner=false,user=false,price=false,state=false,landID=false,rank=false,homeWorld=false};
	
	local option = mcmlNode:GetAttribute("items");
	if(option == nil or option == "")then
		--show all item
		items.name = true;
		items.city = true;
		items.owner = true;
		items.user = true;
		items.price = true;
		items.state = true;
		items.landID = true;
		items.rank = true;
		items.homeWorld = true;
	else
		for s in string.gfind(option,"%a+")do
			if(s == "name")then
				items.name = true;
			elseif(s == "city")then
				items.city = true;
			elseif(s == "owner")then
				items.owner = true;
			elseif(s == "user")then
				items.user = true;
			elseif(s == "price")then
				items.price = true;
			elseif(s == "state")then
				items.state = true;
			elseif(s == "landID")then
				items.landID = true;
			elseif(s == "rank")then
				items.rank = true;
			elseif(s == "homeWorld")then
				items.homeWorld = true;
			end
		end
	end
	return items;
end

--private:refresh control display
function pe_land.RefreshNode(node,pageInstName)
	local ctr = node:GetControl(pageInstName);
	if(ctr)then
		ctr.text = node:GetValue();
	end
end

--private
function pe_land.ShowEditBtn(mcmlNode,pageInstName,tileInfo)
	local btnNode  = mcmlNode:SearchChildByAttribute("name","editBtn");
	if(btnNode == nil)then
		return;
	end
	
	local btn = btnNode:GetControl(pageInstName);
	if(btn == nil)then
		return;
	end
	
	btn.visible = false;
	if(tileInfo.tileState == Map3DApp.TileState.sale)then
		btn.visible = true;
		btn.text = "立即购买";
		--btn.onclick = 
	elseif(tileInfo.tileState == Map3DApp.TileState.sold)then
		local user = Map3DSystem.App.profiles.ProfileManager.GetUserID();
		if(user == nil or user == "" or tileInfo.ownerUserID == nil)then
			return;
		else
			if(user == tileInfo.ownerUserID)then
				btn.visible = true;
				btn.text = "编辑";
				--btn.onclick = 
			end
		end
	elseif(tileInfo.tileState == Map3DApp.TileState.rented)then
		local user = Map3DSystem.App.profiles.ProfileManager.GetUserID();
		if(user == nil or user == "" or tileInfo.userUserID == nil)then
			return;
		elseif(user == tileInfo.userUserID)then
			btn.visible = true;
			btn.text = "编辑";
			--btn.onclick = 
		end
	elseif(tileInfo.tileState == Map3DApp.TileState.rent)then
		btn.visible = true;
		btn.text = "我要租";
		--btn.onclick = ;
	end
end


--[[
<verbatim>
	<pe:land>
		<div name="name"/>
		<div name="position"/>
		<img name="homeworld" />
		<label name="page" style="height:18px;margin:4px"/>
	</pe:land>
	
	<pe:land ReadOnly="true" ShowBuyButton="true" ShowHomeWorld="true" ShowPosition="true" ShowGotoMapButton="true" />
</verbatim>
--]]