# Design of Code Block
Author:LiXizhi, 2018.5.16

## Introduction: 
In addition to object-oriented programming(OOP), paracraft code block features an memory-oriented-programming(MOP) model. 
The smallest memory unit is an animation clip over time. So we can also call it animation-oriented programming model. 
In MOP, A program is made up of code blocks, where each code block is associated with one movie block, which contains a short animation
clip for an actor. Code block exposes a `CodeAPI` that can programmatically control the actor inside the movie block. 


> Core Algorithm： Use code block to control actors inside movie blocks. 
Movie block is a memory unit which is used like a template file to art asset. 

Every CodeBlock can control or clone the character in its adjacent movie block. 
We can use a wire signal to turn on and off CodeBlock logics, so that we can debug logics inside each CodeBlock. 
When Code Block is not powered, all related actor entities will be erased, this will allow us to easily reboot 
Code Block. 

> please note, when we save a powered code block to disk, the logics will be automatically loaded and activated 
when game world restart. 

We regard all games to be comprised of scene and actors, where code and animation belongs to each individual actor. 
The code logics is distributed, where one can turn on and off at will. This is like the human brain,
we can turn off some memory without breaking down the whole brain system. 

Paracraft has provided many visual tools for scene and animation creation. 
When we design the Code Block for young programmers, we are considering controlling actor animation using code. 
However, it is too complex to create 3d actor with code, that is why we use a movie block to do this task 
without code. A movie block contains actor preset at time 0 and possible many animation clips too. 
So what the code needs to do is just telling how to create an instance of the actor inside the movie and react
to external input. This is like how our brain control our memories and replay them in given orders, and we 
can even recreate multiple copies of the same memory in the brain. This is what the Code Block will do
using simple code. 

## Basic functions: 

CodeBlock can has many buildin functions, most of them is to control actor animations, such as 
move(x,y[,z]), turn(x[,y,z]), etc. It can also define private functions, but not global function. 
The important thing is that you do not need to specify which actor it is controlling, because it will 
always control the first actor in its adjacent movie blcok. 

Next, the code does not need to manage the life time of the actor, when the block is activated, 
the actor will be recreated using the actor state at time=0 inside the movie block (such as appearance and position). 
When the block is not powered or deleted, all actors will be automatically erased. 
This will allow us to clone and move, turn on and off, or share those code blocks at will. 

When Code block is not connected to a movie block, it will by default control the current player. 

Because of the modular nature of Code Block, we can focus working on one code block at a time, and then 
put all of them together to form a game. 

Basic sandbox functions we will support in v1.0:

- Motion: move, turn , point towards, goto, glide, changePos, setPos,
- Events: activate, onKeyPressed, onClick, OnEvent, sendEvent, callEvent
- Looks: say, think, show, shide, setTime, setAnim, setColor, setSize,
- Control: wait, repeat, forever, if then else, stop, onInit(a clone), delete(this clone), create(clone of something)
- Sound: play
- Sensing: touching, distanceTo, askAndWait, answer, isMouseDown, isKeyPressed, getMousePos, timer, resetTimer
- Operators: + - / * < > = ,and, or, random, not, join, letter of, length of, mod, round, math.XXX
- Data: setValue, changeValue, showVariable, hideVariable
- Private Custom Functions: user defined private functions


### About callback and delayed functions 
Some function has callbacks like onKeyPressed, and some function's execution takes some time before it can return, 
such as `wait`. To write synchronous code in async environment, we will use run all function and callbacks inside a 
coroutine, which belongs to the code block. So it is legal to write any code like below 
without going into an infinite loop.
```
onKeyPressed("DIK_SPACE", function()
   for i=1, 10 do
     self:goto(10,0,10);
     self:wait(2);
     self:goto(1,0,0);
   end
end)

while(true) do
   say("hi");
   wait(2);
end
```

### Data storage. 
Each code block has an entity, which has its unique private ENV object for its sandbox API. 
When code block is deleted, this ENV object is also deleted. When codeblock content changes, 
the ENV is also recreated. All registered global event, local functions will also be deleted along side the ENV
Code block communicate with each other only via global event and variables

The actual data stored inside the code block's entity object may looks like:

```
{ 
  storage = "[entity|file]",
  body = [[
function activate()
   self:move(0, 0, 10)
end
]]
}
```
The code inside code block is saved in Entity XML, not an external file. 
This is different from codeitem, which uses a real filename on disk. The advantage of saving to EntityXML is:

- Young programmers do not need to manage real disk files. They use the build-in text editor. But we do allow `include(file)` command in future
- Copy and paste code block is easy in this way. 
- Suitable to read in a zipped world and logics can be broadcasted in the network. 
- we may support file storage in future. Two storage types: entity or file.

### On Timer
Do not use system timer, they are not deleted when world exits. Instead we use a local timer that belongs to the code block itself.

## Tests

### Animation Tests
```
teleport(19257,5,19174);
play(10, 2000); -- play animation between 10-2000
wait(3)
walk(1, 0);
say("hi", 3); -- say hi for 3 seconds
anim(4, 2); -- set animtion to 4(walk) and wait 2 seconds
playLoop(10, 2000);
```

### Loop Tests
```
walk(-3, 0); -- to 3 blocks along negative x.
wait(2); -- wait 2 seconds before our next command
for i=1, 200 do
	move(0.02, 0); -- move 0.02 meters per tick
end
```

Automatic yielding tests with looping
```
local function test()
	local count = 0;
	for i=1, 100 do
		count = count + i;
	end
	say(count);
	local times = 0;
	while(true) do
		times = times + 1;
		if((times % 1000) == 0) then
			log(times)
		end
	end
end
test()
```