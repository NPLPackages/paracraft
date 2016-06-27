--[[
Title: Experience point and level mapping 
Author(s): LiXizhi
Date: 2013/11/20
Desc:  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/API/ExpTable.lua");
local ExpTable = commonlib.gettable("MyCompany.Aries.Creator.Game.API.ExpTable");
echo(ExpTable.GetLevel(10))
echo(ExpTable.GetLevel(3020))
echo(ExpTable.GetExpToNextLevel(3020))
echo(ExpTable.GetExpAtLevel(6))
echo(ExpTable.GetThisLevelExp(70));
-------------------------------------------------------
]]

local ExpTable = commonlib.gettable("MyCompany.Aries.Creator.Game.API.ExpTable");

-- level to exp map
local exp_levels = {
0,
20,
70,
155,
190,
465,
1150,
2000,
3000,
4550,
4900,
5300,
5700,
6100,
6600,
7100,
7600,
8200,
8800,
9500,
10000,
11000,
12000,
13000,
14000,
15000,
17000,
19000,
21000,
23000,
25000,
27000,
29000,
31000,
33000,
35000,
38000,
41000,
44000,
47000,
50000,
52000,
54000,
56000,
58000,
60000,
62000,
64000,
66000,
68000,
70000,
72000,
74000,
76000,
78000,
80000,
100000,
120000,
150000,
200000,
}

function ExpTable.Init()
	
end

-- @param exp: 
function ExpTable.GetLevel(exp)
	local nStart = 1
	local nEnd = #exp_levels;
			
	if(exp >= exp_levels[nEnd]) then
		return nEnd;
	elseif(exp <= exp_levels[nStart]) then 
		return nStart;
	end
	
	local pos;
	while(true) do
		if(nStart >= nEnd) then
			-- if no item left.
			pos = nStart;
			break;
		end
				
		local nMid;
		if( ((nStart + nEnd) % 2) == 1 ) then
			nMid = (nStart + nEnd - 1)/2;
		else
			nMid = (nStart + nEnd)/2;
		end
				
		local startP = (exp_levels[nMid]);
		local endP = (exp_levels[nMid + 1]);

		if(startP <= exp and exp < endP ) then
			-- if (middle item is target)
			pos = nMid;
			break;
		elseif(exp < startP ) then
			-- if (target < middle item)
			nEnd = nMid;
		elseif(exp >= endP) then
			-- if (target >= middle item)
			nStart = nMid+1;
		end
	end -- while(nStart<=nEnd)
	return pos;
end

function ExpTable.GetExpToNextLevel(exp)
	local level = ExpTable.GetLevel(exp);
	return exp_levels[math.min(level+1, #exp_levels)] - exp;
end

function ExpTable.GetThisLevelExp(exp)
	local level = ExpTable.GetLevel(exp)
	if(level > 2) then
		return exp - exp_levels[level]
	else
		return exp;
	end
end

function ExpTable.GetExpAtLevel(level)
	if(level > 2) then
		return exp_levels[level] - exp_levels[level-1]
	else
		return exp_levels[level];
	end
end