# Lobby Service Design

- date: 2018.12.19
- author: LiXizhi

## Introduction
UDP lobby will automatically connect to one another in Intranet, when user signed in to a game world with `registerNetworkEvent`. 
After peers are discovered, they communicate via TCP on the same port. 

## Code Block network design:


```lua
registerNetworkEvent("updateScore", function(msg)
     showVariable(msg.nid, msg.score)
end)

broadcastNetworkEvent("updateScore", {score = 100})

registerNetworkEvent("connect|disconnect", function(msg)
    tip(msg.nid.." joined | left ")
end)
```

我们先以上面3个函数的实现为目标， 做出一个版本来。 
只要用户写了registerNetworkEvent，自动侦听+广播，并建立游戏ID的连接。 
使用世界的ProjectID或世界名字的CRC32作为游戏ID。 

未来有时间，再做列出局域网中所有小游戏的UI