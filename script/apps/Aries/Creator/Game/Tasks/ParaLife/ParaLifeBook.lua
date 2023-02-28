--[[
Title: Paralife Book for in-game help
Author(s): LiXizhi, pbb
Date: 2022/2/18
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeBook.lua");
local ParaLifeBook = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeBook")
ParaLifeBook.AddPage(name,iconFileName,leftContent,rightContent,pageIndex)
ParaLifeBook.ShowPage(true)
------------------------------------------------------------
]]
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local ParaLifeBook = commonlib.gettable("MyCompany.Aries.Game.Tasks.ParaLife.ParaLifeBook")
local Markdown = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/ParaLife/Markdown.lua");
local page_datas = {}
local cur_page_data = {}
local page_size = 0
local page;
local self = ParaLifeBook;
ParaLifeBook.page_index = 1

function ParaLifeBook.OnInit()
	page = document:GetPageCtrl();
	GameLogic:Connect("WorldUnloaded", ParaLifeBook, ParaLifeBook.OnWorldUnload, "UniqueConnection");
end

function ParaLifeBook.ClosePage()
	if (page) then
		page:CloseWindow()
		page = nil
		cur_page_data = {}
	end
end

function ParaLifeBook.ShowPage(bShow)
	if(bShow==false) then
		ParaLifeBook.ClosePage()
		return
	end
	ParaLifeBook.InitPageData()
	ParaLifeBook.GetCurPageData()
	local width, height = 1024, 720
	local params = {
			url = "script/apps/Aries/Creator/Game/Tasks/ParaLife/ParaLifeBook.html", 
			name = "ParaLifeBook.ShowPage", 
			isShowTitleBar = false,
			DestroyOnClose = true,
			bToggleShowHide=false, 
			style = CommonCtrl.WindowFrame.ContainerStyle,
			allowDrag = false,
			bShow = bShow~=false,
			click_through = true, 
			cancelShowAnimation = true,
			directPosition = true,
				zorder = 2,
				align = "_ct",
				x = -width/2,
				y = -height/2,
				width = width,
				height = height,
		};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function ParaLifeBook.OnWorldUnload()
	GameLogic:Disconnect("WorldUnloaded", ParaLifeBook, ParaLifeBook.OnWorldUnload);
	page_datas = {}
	page_size = 0
	ParaLifeBook.IsInit = false
	ParaLifeBook.ShowPage(false)
	self.page_index = 1;
end


function ParaLifeBook.InitPageData()
	
	local function isHave(name)
		return page_datas[name] ~= nil and true or false
	end
	ParaLifeBook.IsInit = isHave("manual") and isHave("copyright")
	if not ParaLifeBook.IsInit then
		ParaLifeBook.IsInit = true
		local name = "manual"
		local leftContent = [[
			# 操作指南

			![413x208](Texture/Aries/Creator/keepwork/Paralife/help/operate_icon6.png)

			![110x100](Texture/Aries/Creator/keepwork/Paralife/help/operate_icon1.png)
			<div style="position:relative;width:200px;height:140px;margin-left:140px;margin-top:-60px">
				拨动地球移动
			</div>

			![72x72](Texture/Aries/Creator/keepwork/Paralife/help/operate_icon2.png)
			<div style="position:relative;width:200px;height:140px;margin-left:140px;margin-top:-46px">
				点击任意位置瞬移
			</div>
			![72x72](Texture/Aries/Creator/keepwork/Paralife/help/operate_icon3.png)
			<div style="position:relative;width:200px;height:140px;margin-left:140px;margin-top:-46px">
				拖动旋转视角
			</div>
		]]
		local rightContent =[[

			![415x233](Texture/Aries/Creator/keepwork/Paralife/help/operate_icon5.png)


			![150x180](Texture/Aries/Creator/keepwork/Paralife/help/operate_icon4.png)
			<div style="position:relative;width:220px;height:180px;margin-left:154px;margin-top:-140px">
			可以多人，多指拖动或点击场景中的任意物品
			</div>
			]]
		ParaLifeBook.AddPage(name,"",leftContent,rightContent)

		name = "copyright"
		leftContent=string.format([[
			# 制作人员
  
  			%s
  
  
  
			## 时间：2022年，深圳
		]],System.User.username)
		rightContent=[[
			# 声明

			本产品使用Paracraft软件制作。

			帕拉卡Paracraft是一款易学易用的3D动画与编程创作工具。

			通过电脑，让7-14岁的孩子学会编程，制作动画，创造属于自己的3D世界。

			官网 https://paracraft.cn]]
		ParaLifeBook.AddPage(name,"",leftContent,rightContent)
	end
end

function ParaLifeBook.AddPage(name,iconFileName,leftContent,rightContent,pageIndex)
	local isHave = page_datas[name] ~= nil and true or false
	page_datas[name] = {}
	page_datas[name].leftContent = leftContent
	page_datas[name].rightContent = rightContent
	page_datas[name].icon = iconFileName
	page_datas[name].pageIndex = pageIndex
	if not isHave then
		page_size = page_size + 1
	end

	if page_datas["manual"] then
		page_datas["manual"].pageIndex = 1
	end
	if page_datas["copyright"] then
		page_datas["copyright"].pageIndex = page_size
	end	
end

function ParaLifeBook.GetCurPageData()
	for k,v in pairs(page_datas) do
		if v.pageIndex == self.page_index then
			cur_page_data = v
			self.page_index = v.pageIndex
			return k,v
		end
	end
end

function ParaLifeBook.ShowPageWithName(name)
	if page_datas and page_datas[name] then
		cur_page_data = page_datas[name]
		self.page_index = cur_page_data.pageIndex
		if ParaLifeBook.IsVisible() then
			ParaLifeBook.RefreshPage()
		else
			ParaLifeBook.ShowPage(true)
		end
	end
end

function ParaLifeBook.RefreshPage()
	if page then
		page:Refresh(0)
	end
end

function ParaLifeBook.IsVisible()
	return page and page:IsVisible()
end


function ParaLifeBook.GoNextPage(pageChange)
	self.page_index = self.page_index + pageChange
	if self.page_index < 1 then
		self.page_index = page_size
	end
	if self.page_index > page_size then
		self.page_index = 1
	end
	local page_name ,data  = ParaLifeBook.GetCurPageData()
	ParaLifeBook.ShowPageWithName(page_name)
end

function ParaLifeBook.SetIcon(name)
	
end

function ParaLifeBook.ShowIcon(name)
	ParaLifeBook.SetIcon(name)
	ParaLifeBook.ShowPageWithName(name)
end

function ParaLifeBook.GetLeftPageHtml()
	return cur_page_data.leftContent --Markdown:render(cur_page_data.leftContent) or ""
end

function ParaLifeBook.GetRightPageHtml()
	return cur_page_data.rightContent--Markdown:render(cur_page_data.rightContent) or ""
end

function ParaLifeBook.GetLeftPageIndex()
	local pageIndex = cur_page_data.pageIndex  or 1 
	return ""..pageIndex*2 - 1
end

function ParaLifeBook.GetRightPageIndex()
	local pageIndex = cur_page_data.pageIndex  or 1 
	return ""..pageIndex*2
end