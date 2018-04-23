--[[
Title: The emotion icons window used during chat
Author(s): WangTian
Date: 2008/10/26
Desc: It show/hide the emotion chat icons window. the emotion icon window displays a grid of chat icons or avatar actions, which can be used during chat. 
Implementation: this can be done either in pure NPL, or pure MCML.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/BBSChat/SentenceHistory.lua");
local sentence_history = commonlib.gettable("MyCompany.Aries.BBSChat.sentence_history");
------------------------------------------------------------
]]
-- a very simple class to provide a brief sentence or command history that user can browse backward or forward. 
-- 2009.1.20. by LiXizhi. This function is mostly for casual Movie Recording during movie play back mode. Users can quickly spell previously used sentences. 
local sentence_history = commonlib.createtable("MyCompany.Aries.BBSChat.sentence_history", {
	history = {},
	current_index = 1,
});

function sentence_history:PushSentence(text)
	if( text and text~="" ) then
		self.history[#(self.history)+1] = text;
		-- make the index to the next one whenever new sentences are pushed to history. 
		self.current_index = #(self.history)+1;
	end	
end

function sentence_history:PreviousSentence()
	self.current_index = self.current_index -1;
	if(self.current_index <= 0) then
		self.current_index = #(self.history);
	end
	return self.history[self.current_index];
end

function sentence_history:NextSentence()
	self.current_index = self.current_index + 1;
	if(self.current_index > #(self.history)) then
		self.current_index = 1;
	end
	return self.history[self.current_index];
end

function sentence_history:PeekLastSentence()
	local current_index = self.current_index -1;
	if(current_index <= 0) then
		current_index = #(self.history);
	end
	return self.history[current_index];
end
