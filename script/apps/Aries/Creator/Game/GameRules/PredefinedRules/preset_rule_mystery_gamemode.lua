--[[ 
---++ 游戏规则
   * 不要用编辑模式
   * 不要破坏任何方块
   * 不用瞬移功能
   * 顺利通关
]]

-- 是否可以自动走到积木上
this:AddRule("Player", "AutoWalkupBlock false");

-- 只能将拉杆放到萤石块上
this:AddRule("Block", "CanPlace Lever Glowstone");
