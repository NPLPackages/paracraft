-- 示例文件: NPL script file



function main(msg)
	movie.text("hello world");
end

function run_examples()
	-- 显示字幕
	movie.text("hello worlds");

	-- 加载模块
	local MovieText = mod("MovieText");

	-- 写入游戏目录下的log.txt
	echo(MovieText.version);
end




