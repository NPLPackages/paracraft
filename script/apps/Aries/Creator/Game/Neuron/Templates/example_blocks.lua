-- 示例文件: NPL script file

-- 立方体模型:{x,y,z,block_id}
cube_models = {
	{1,1,1,   4},
	{-1,1,1,  4},
	{-1,1,-1, 4},
	{1,1,-1,  4},
};

-- 在x,y,z的位置创建一个模型
-- @param model_data: 数据源
-- @param x,y,z: 原点
function CreateModel(model_data, x,y,z)
	for i, b in ipairs(model_data) do
		blocks.set(x+b[1], y+b[2], z+b[3], b[4]);
	end
end

-- entry function:
function main(msg)
	-- 在当前积木的上面： 创建ID=4的3个积木
	for i=3, 5 do
		-- 判断一下ID是否为0(空)
		if(blocks.get(this.x, this.y + i, this.z) == 0 ) then
			-- 使用Set方法在当前位置的上方一格创建
			blocks.set(this.x, this.y + i, this.z, 4);
		end
	end

	-- 在当前位置创建
	CreateModel(cube_models, this.x, this.y+4, this.z);

	-- 获取指定位置的脚本模块. 这里获取自己的. 
	local my_script = blocks.getscript(this.x, this.y, this.z);

	-- 更改一下cube_models中的块ID
	for i, b in ipairs(my_script.cube_models) do
		b[4] = b[4] % 100 + 1;
	end


	-- 选择block_id==4的积木(拿在右手中)
	select(cube_models[1][4]);

	-- 运行一条指令: 设置当前时间为中午 [-1,1]
	cmd("/time 0");

	-- 显示字幕
	movie.text("方块功能演示:每触发一次会改变周围的积木")

	-- 休眠5秒， 本方块不再接受任何请求，5秒后如果再次激活，每次创建的模型会不一样
	this:Sleep(5);
end





