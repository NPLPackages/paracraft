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
Multiple code block next to each other can share the same movie block(actor) within 16 blocks.

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

When Code block is not connected to a movie block, it will control no one. 

Because of the modular nature of Code Block, we can focus working on one code block at a time, and then 
put all of them together to form a game. 

### About callback and delayed functions 
Some function has callbacks like registerClickEvent, and some function's execution takes some time before it can return, 
such as `wait`. To write synchronous code in async environment, we will run all function and callbacks inside a 
coroutine, which belongs to the code block. So it is legal to write any code like below 
without going into an infinite loop.
```
registerClickEvent("space", function()
   while(true) do
     move(0.01);
   end
end)

while(true) do
   say("hi");
   wait(2);
end
```
We will inject checkyield() to all looping and recursive function calls during the compile phase. When a certain instruction count is reached, we will force 
the coroutine to yield for 1 tick. 

### Data storage. 
Each code block has an entity, which has its unique private ENV object for its sandbox API. 
When code block is deleted, this ENV object is also deleted. When codeblock content changes, 
the ENV is also recreated. All registered global event, local functions will also be deleted along side the ENV
Code block communicate with each other only via global event and variables

The code inside code block is saved in Entity XML, not an external file. 
This is different from codeitem, which uses a real filename on disk. The advantage of saving to EntityXML is:

- Young programmers do not need to manage real disk files. They use the build-in text editor. But we do allow `include(file)` command in future
- Copy and paste code block is easy in this way. 
- Suitable to read in a zipped world and logics can be broadcasted in the network. 
- we may support file storage in future. Two storage types: entity or file.

### On Timer
Do not use system timer, they are not deleted when world exits. Instead we use a local timer that belongs to the code block itself.
Most actions taken by actors like move() are ticked by at least 1 tick. 

## Tests

### Animation Tests
```
moveTo(19257,5,19174);
play(10, 2000); -- play animation between 10-2000
wait(3)
walk(1, 0);
say("hi", 3); -- say hi for 3 seconds
anim(4, 2); -- set animtion to 4(walk) and wait 2 seconds
playLoop(10, 2000);
wait(4)
stop();
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

```
local a = {1, 2}
for i, k in ipairs(a) do
   echo(i)
end
```

### test world Globals
One can get globals via `_G.a`, `a` or `get("a")`, but one must set globals using `_G.a` or `set`.
```
_G.a = _G.a or 1;
for i=1, 10 do
  _G.a = a + 1;
  set("a", get("a") + 1)
end
say(a)
```

### test Clone Event
```
move(1,0);
registerCloneEvent(function(a)
   move(-a,0);
   say(a);
   for i=1, 100 do
      move(0, 0.02)
   end
end)
clone("myself", 1);
clone("myself", 2);
say("hi", 2);
say("bye");
```

### test Clone two blocks Event
this is box
```
registerCloneEvent(function(msg)
    move(0, msg.y, 0)
end)
```
this is from another code block
```
wait(0.1)
for i=1, 10 do
	clone("box", {y=i})
end
```

### test Broadcast Event
```
move(1,0);
clone();
msg = "hi";
registerBroadcastEvent("hi", function()
	say(msg)
end)

for i=1, 100 do
	broadcast("hi")
	wait(2)
	msg = "hi"..i;
end
```

Receive it in another block 
```
local a=0
registerBroadcastEvent("hi", function()
    say("hello "..a)
    a = a + 1
end)
```

### test start Event

One can start by calling `/sendevent start`
```
registerBroadcastEvent("start", function()
    for i=1, 100 do
        say(tostring(i), 1)
    end
end)
```

### test actor click Event
One can have multiple click event per actor.
```
registerCloneEvent(function()
   say("click me!")
   move(-a,0);
end)

say("click me!")
for i=1, 2 do 
    a = i
    clone();
end

registerClickEvent(function()
    say("move on!", 0.8);
end)

registerClickEvent(function()
    for i=1, 100 do
        move(0.01, 0)
    end
end)
```

### test delete actor
```
move(1,0)
say("Default actor will be deleted!", 1)
delete();

registerCloneEvent(function()
   say("This clone will be deleted!", 1)
   delete();
end)

for i=1, 100 do
	clone();
	wait(2);
end
```

### test show/hide actor
```
playLoop(10, 2000)
say("blink")
for i=1, 100 do
    show();
    wait(0.1);
    hide();
    wait(0.1);
end
```

### test turning
```
turnTo(30);
for i=1, 100 do
	turn(2)
end
```

### test move with time
```
say("jump and shift")
while(true) do
    move(0, 1,0, 0.5);
	move(0,-1,0, 0.5);
	move(1,0,0, 0.5);
	move(-1,0,0, 0.5);
end
```

### test key pressed event
```
registerKeyPressedEvent("z", function(keyname)
    say("you pressed Z key");
    wait(3);
    say("pressed any key!");
end)

registerKeyPressedEvent("any", function(keyname)
    wait(1)
    say("you pressed some key!");
    wait(1)
    say("");
end)

say("press Z key!")
```

### test Animation Time event
```
registerAnimationEvent(10, function()
	say("anim started", 3)
	say("click me!")
end)

registerAnimationEvent(1000, function()
	say("anim stopped", 1)
end)

registerClickEvent(function()
	play(10, 1000)
end);
say("click me!")
walk(1,0);
clone();
```

### test Broadcast And Wait Event
```
registerBroadcastEvent("jump", function()
	move(0,1,0)
	wait(1)
	move(0,-1,0)
end)

registerClickEvent(function()
	broadcastAndWait("jump")
	say("That was fun!", 2);
end)

say("click to jump!")
```
Another actor
```
registerBroadcastEvent("jump", function()
	move(0,2,0)
	wait(1.5)
	move(0,-2,0)
end)
```

### test scaling 
```
registerClickEvent(function()
	for i=1, 20 do
		scale(10);
	end
	for i=1, 20 do
		scale(-10);
	end
end)
say("click me to scale!")
scaleTo(200);
```

### test isTouching Event
a frog that moves back and forth
```
local i=0;
local dist = 20*2
while(true) do
    i=i+1
    if(i<=dist) then
        move(0.05, 0)
    elseif(i<=dist*2) then
        move(-0.05, 0)
    else
        i = 0;
    end
   if(isTouching("@a")) then
      say("oops!")
   else
      say("")
   end
end
```
A dog that meet the frog
```
while(true) do
   if(isTouching("frog")) then
      say("A Frog!");
   else
	  say("");
   end
   if(isTouching("block")) then
      turn(180);
   end
   moveForward(0.05);
end
```

### test getX
```
say("click me to run");
registerClickEvent(function()
	turn(90);
	while(true) do
		moveForward(0.03);
		say(string.format("%d %d %d", getX(), getY(), getZ()))
	end
end)
```

### test follow mouse or player
```
registerBroadcastEvent("trackMouse", function()
	while(true) do
		if(isMouseDown()) then
			moveTo("mouse-pointer");
			wait(0.3);
		end
	end
end)
broadcast("trackMouse");
tip("click anywhere to teleport");

while(true) do
	if(distanceTo("mouse-pointer") < 3) then
		say("follow mouse-pointer")
		turnTo("mouse-pointer");
		walkForward(1);
		wait(0.5);
	elseif(distanceTo("@p") < 10) then
		say("follow player")
		turnTo("@p");
		walkForward(1);
		wait(0.5);
	elseif(distanceTo("@p") > 10) then
		moveTo("@p");
	end
end
```

### test run threads
follow mouse cursor
```
run(function()
	say("follow mouse pointer!")
	while(true) do
		if(distanceTo("mouse-pointer") < 7) then
			turnTo("mouse-pointer");
			say("OK!", 1);
		end
	end
end)

run(function()
	while(true) do
		moveForward(0.02);
	end
end)
```

### test Bounce With Pong Game
```
turnTo(45);
while(true) do
	moveForward(0.1);
	if(isTouching("block")) then
		bounce();
	elseif(isTouching("box")) then
		bounce();
	end
end
```

create a box, use LEFT/RIGHT key to move
```
say("press left/right key to move me!")
while(true) do
    if(isKeyPressed("left")) then
        move(0, 0.1);
        say("")
    elseif(isKeyPressed("right")) then
        move(0, -0.1);
        say("")
    end
end
```

## On Networking
`BecomeAgent` is the only API required to support networking. Because everything runs on the server side, 
all we need to do is three things
- make all keyboard and mouse input from the agent's client computer available to the agent actor on server side
- broadcast all actors' dynamic states from server to connected clients
- copy static data like movie blocks and bmax models to connected clients

All user interface items are also actors, so everything 3d and 2d are shared among clients. 

`focus()` API will cause all agent to focus on a given actor. 

