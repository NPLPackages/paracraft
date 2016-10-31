--[[
Title: BlockDataCodec
Author(s): LiXizhi
Date: 2016/10/31
Desc: from my code in BlockDataCodec.cpp of NPLRuntime
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/BlockDataCodec.lua");
local BlockDataCodec = commonlib.gettable("MyCompany.Aries.Game.Common.BlockDataCodec");
local IntegerEncoder = commonlib.gettable("MyCompany.Aries.Game.Common.IntegerEncoder");
local SameIntegerEncoder = commonlib.gettable("MyCompany.Aries.Game.Common.SameIntegerEncoder");

local file = ParaIO.open("<memory>", "w");
local encoder = SameIntegerEncoder:new():init(file);
encoder:Append(1);
encoder:Append(2);
encoder:Append(2, 100);
echo(#file:GetText(0, -1));
file:close();
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/bit.lua");
local rshift = mathlib.bit.rshift;
local lshift = mathlib.bit.lshift;
local band = mathlib.bit.band;
local bor = mathlib.bit.bor;

local BlockDataCodec = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Common.BlockDataCodec"));


local g_buffer = {};

function BlockDataCodec:ctor()
end

local IntegerEncoder = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Common.IntegerEncoder"));

-- static: 
-- @param source: CParaFile object
function IntegerEncoder:TryDecodeUInt32(source, value, nByteRead)
	-- TODO: 
end

-- @return int:
function IntegerEncoder:EncodeUInt32(value, buffer, stream)
	local count = 0;
	local index = 0;
	buffer = buffer or g_buffer;
	repeat
		index = index + 1;
		buffer[index] = bor(band(value, 0x7F), 0x80);
		value = rshift(value, 7);
		count = count + 1;
	until (value == 0);
	buffer[index] = band(buffer[index], 0x7F);
	stream:WriteBytes(count, buffer);
	return count;
end


-- here we will use skip 1 algorithm to compress the data, since the result is sorted integer.
-- More advanced one is PForDelta algorithm, which is discussed in part here
-- http://stackoverflow.com/questions/283299/best-compression-algorithm-for-a-sequence-of-integers
-- Example:
-- to compress: 1-100, 110-160:
-- "skip 1" (assume start at zero as it makes things easier), "take 100", "skip 9", "take 51"; subtract 1 from each, giving (as decimals)
-- result: 0,99,8,50
function IntegerEncoder:EncodeSkipOne(stream, data)
	local nCount = #data;
	if (nCount == 0) then 
		return 0;
	end
	
	local last = -1;
	local len = 0;
	for i = 1, count do 
		local gap = data[i] - 2 - last;
		local size = 0;
		while ( i < nCount and data[i+1] == data[i] + 1) do
			size = size + 1;
			i = i + 1;
		end
		last = data[i];
		len = len + self:EncodeUInt32(gap, nil, stream) + self:EncodeUInt32(size, nil, stream);
	end
	return len;
end

-- return true, if more than half of the input is continuous integer with step 1. if true, we prefer using EncodeSkipOne.
function IntegerEncoder:IsSkipOneBetter(data)
	local nCount = #data;
	if (nCount < 2) then 
		return false;
	end

	local nSkipCount = 0;
	local nHalfCount = rshift(nCount, 1);

	local i = 1;
	while (i < nCount and nSkipCount <= nHalfCount) do
		if (data[i+1] == (data[i] + 1)) then
			nSkipCount = nSkipCount + 1;
		end
		i = i + 1;
	end
	return nSkipCount >= nHalfCount;
end

-- @return len;		
function IntegerEncoder:EncodeIntDeltaArray(stream, data)
	local nCount = #data;
	if (nCount == 0) then
		return 0;
	end
	local len = self:EncodeUInt32(data[1], nil, stream);

	for i = 2, nCount do
		len = len + self:EncodeUInt32(data[i] - data[i - 1], nil, stream);
	end
	return len;
end

		
--Author: LiXizhi
--if the input array contains, many data of the same value.
--1,1,1,2,2,2,2,3,3,3,3 is saved as 1,3,2,4,3,4 (value, count, value, count, ... value)
function IntegerEncoder:EncodeSameInteger(stream, data)
	local nCount = #data;
	if (nCount == 0) then
		return 0;
	end
	local len = 0;
	local last = data[1];
	local size = 0;
	len = self:EncodeUInt32(last, nil, stream);

	local i = 1;
	while (i<=nCount) do
		size = 0;
		local cur_last = last;
		
		while (true) do
			i = i + 1;
			if(i <= nCount) then
				cur_last = data[i];
				if(cur_last == last) then
					size = size + 1;
				else
					break;
				end
			else
				break;
			end
		end

		len = len + self:EncodeUInt32(size, nil, stream);
		if (last ~= cur_last) then
			last = cur_last;
			len = len + self:EncodeUInt32(last, nil, stream);
		end
	end
	return len;
end
		
function IntegerEncoder:IsSameIntegerBetter(data)
	local nCount = #data;
	if (nCount == 0) then
		return false;
	end
	local last = data[1];
	local len = 0;
	local size = 0;
	local i = 1;
	while (i <= nCount and len<nCount) do 
		size = 0;
		local cur_last = last;
		while (true) do
			i = i + 1;
			if(i <= nCount) then
				cur_last = data[i];
				if(cur_last == last) then
					size = size + 1;
				else
					break;
				end
			else
				break;
			end
		end
		last = cur_last;
		len = len + 2;
	end
	return len<nCount;
end

-- @return len;
function IntegerEncoder:EncodeIntArray(stream, data)
	local nCount = #data;
	if (nCount == 0) then
		return 0;
	end
	local len = 0;
	for i = 1, nCount do
		len = len + self:EncodeUInt32(data[i], nil, stream);
	end
	return len;
end

--if the input array contains, many data of the same value.
--1,1,1,2,2,2,2,3,3,3,3 is saved as 1,3,2,4,3,4 (value, count, value, count, ... value)
local SameIntegerEncoder = commonlib.inherit(nil, commonlib.gettable("MyCompany.Aries.Game.Common.SameIntegerEncoder"));

function SameIntegerEncoder:ctor()
	self.m_bIsFirst = true;
	self.m_nLastValueCount = 0;
	self.m_nLastValue= 0;
end

-- @param pStream: CParaFile object
function SameIntegerEncoder:init(pStream)
	self.m_pStream = pStream;
	return self;
end

function SameIntegerEncoder:Reset()
	self.m_bIsFirst = true;
	self.m_nLastValue = 0;
	self.m_nLastValueCount = 0;
end

-- @param nCount: must be larger than 1
function SameIntegerEncoder:Append(nValue, nCount)
	nCount = nCount or 1;
	if (not self.m_bIsFirst) then
		if (self.m_nLastValue == nValue) then
			self.m_nLastValueCount = self.m_nLastValueCount + nCount;
		else
			self:Finalize();
			self.m_nLastValue = nValue;
			self.m_nLastValueCount = nCount;
		end
	else
		self.m_nLastValue = nValue;
		self.m_nLastValueCount = nCount;
		self.m_bIsFirst = false;
	end
end

-- call this function when last element is added. 
function SameIntegerEncoder:Finalize()
	if (self.m_nLastValueCount > 0) then
		IntegerEncoder:EncodeUInt32(self.m_nLastValue, nil, self.m_pStream);
		IntegerEncoder:EncodeUInt32(self.m_nLastValueCount - 1, nil, self.m_pStream);
	else
		LOG.std(nil, "error", "SameIntegerEncoder", "Error: invalid call to finalize with nothing to finalize");
	end
end
