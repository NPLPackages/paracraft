# Lobby Service Design

- date: 2018.12.19
- author: LiXizhi

## Introduction
UDP lobby will automatically connect to one another in Intranet, when user signed in to a game world with `registerNetworkEvent`. 
After peers are discovered, they communicate via TCP on the same port. 

## UDP Clients Discovery
Each game client is both a client and a server. If there are N players on the network, there are N*(N-1)/2 TCP connections. 
In other word, each computer has (N-1) outgoing or incomming connections. 
We can set a game to be full, if N is bigger than 8 or 16.

The lobby system uses UDP to discover all game clients on the Intranet, maintains the above TCP connection topologies between all connected computers. 
In this design, anyone can quit the network system, and everyone else on the Intranet will immediately detect it because everyone has a TCP connection to it. 
Therefore, there is no central server. 

The purpose of the UDP lobby system is to tell everyone on the Intranet who is on the network. 

## Code Block network design:
In code block network API, we will assume that all game client have identical game world running, and each are running full code logics locally. 
These parallel worlds can share data with one another only by broadcasting messages. 
Each parallel world decides how to render the data received from other worlds on their own.

### Example: Score Ranking
For example to create a simple score ranking system, one can write following code, everything else are automatically handled. 

```lua
registerNetworkEvent("updateScore", function(msg)
	_G[msg.nid] = msg.score;
     showVariable(msg.nid)
end)

registerNetworkEvent("connect", function(msg)
	broadcastNetworkEvent("updateScore", {score = 100})
end)

registerNetworkEvent("disconnect", function(msg)
	hideVariable(msg.nid)
end)

while(true) do
	broadcastNetworkEvent("updateScore", {score = 100})
	wait(1);
end
```

### Example: Players' Movement
The same is true for syncing player positions.
```lua
registerNetworkEvent("updatePlayerPos", function(msg)
     runForActor(msg.nid, function()
		moveTo(msg.x, msg.y, msg.z)
	 end)
end)

registerNetworkEvent("connect", function(msg)
	clone(nil, msg.nid)
end)

registerNetworkEvent("disconnect", function(msg)
	runForActor(msg.nid, function()
		delete();
	 end)
end)

while(true) do
	broadcastNetworkEvent("updatePlayerPos", {x = getX(), y=getY(), z=getZ()})
	wait(1);
end
```

### Example: Shared Data
To share a data that is unique on all clients, one needs to use a sequence number as a clue for how old is the data. 
So that we can use the sequence number to decide whether we should discard the data or update locally. 
The first one on the network decides the initial value. 
For example, suppose `time` is always increasing, so we can use the variable itself as the sequence number.  

```lua
_G.time = 0;
registerNetworkEvent("SharedTime", function(msg)
	setTime(msg.time)
end)

registerNetworkEvent("connect", function(msg)
	setTime(msg.time)
end)

function _G.setTime(time)
	if(time > _G.time) then
		_G.time = time;
		broadcastNetworkEvent("SharedTime", {time = time})
	end
end

while(true) do
	setTime(time+1);
	wait(1);
end
```
After a while, all clients will share the newest (largest) time. The same technique can be used for complex data structures, 
the client who has the largest sequence number of a given data structure decides the value for all clients on the network.

```
_G.sharedData = {
	seq = 1, 
	complex_data = {}, 
};

registerNetworkEvent("sharedData", function(msg)
	setData(msg.data)
end)

registerNetworkEvent("connect", function(msg)
	setData(msg.data)
end)

function setData(data)
	if(data.seq > sharedData.seq) then
		_G.sharedData = data;
		broadcastNetworkEvent("sharedData", {data = data})
	end
end

while(true) do
	sharedData.seq = sharedData.seq + 1;
	-- modify complex data here
	setData(sharedData);
	wait(1);
end

```

### Backlog
我们先以上面3个函数的实现为目标， 做出一个版本来。 
只要用户写了registerNetworkEvent，自动侦听+广播，并建立游戏ID的连接。 
使用世界的ProjectID或世界名字的CRC32作为游戏ID。 

未来有时间，再做列出局域网中所有小游戏的UI