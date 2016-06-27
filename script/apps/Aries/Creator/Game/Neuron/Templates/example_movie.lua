-- 示例文件: NPL script file

local count = 0;

-- 触发函数
function main(msg)
	count = (count + 1);
	if(count > 3) then 
		count = 1 
	end

	-- 轮流播放3个音乐
	if(count == 1) then
		-- 积木坐标转到实数坐标
		local x, y, z = real(this.x, this.y, this.z);
		-- 官方定义过的声音
		audio.play("portal", x, y, z);
		audio.stop("fire");
		movie.text("带上你的耳机, 可以听到声音, 再次激活可以听见不同的音乐")
	elseif(count == 2) then
		audio.stop("portal");
		-- 支持 map3, ogg, wav 等文件, 文件放在当前世界目录下
		-- 不传位置代表2D声音, 否则是3D声音
		audio.play("audio/test.mp3", nil, nil, nil, true);
		movie.text("Playing 'audio/test.mp3' 支持 map3, ogg, wav 等文件, 文件放在当前世界目录下")
	elseif(count == 3) then
		local x, y, z = real(this.x, this.y, this.z);
		audio.stop("audio/test.mp3");
		-- 最后一个参数true是循环播放
		audio.play("fire", x, y, z, true);
		movie.text("立体3D音效,WASD键转动摄影机可以听见声音的位置")
	end
	-- 休息5秒
	this:Sleep(5);
end
