# Autonomous Animation Using Time Series

## Design
- When there is no matching position, we can increase the deviation threshold until one is found. 
- Creativity is the result of repetitive thinking plus deviation threshold. 
- We can reward deviation actions (creativity) that lead to familiar situations.  It is like finding the way to a solution. A solution is the activation path to a target situation. 
- Memory blocks are always associated with emotions. 
- Languages are special auxiliary tags. Vocabularies in natural language is rich enough to describe almost everything.  
- When memory block is activated, it is inactive for some time. 
- We match both initial position and speed in movie blocks. Initial speed is calculated as mass point speed at the start of the animation. 
- When player moves to initial position, if target movie block has no initial speed, we will walk to the position and stops before starting the new animation. If the avatar in movie block has speed, we will walk to it and immediately start playing. 

工作原理如下：

包含两个关键模块：
- 电影驱动现实：用电影方块中的内容驱动现实中的虚拟人物
- 电影触发器：通过实现制作好的许多电影方块中的人物的初始空间位置，以及一些其它输入条件，自动启动符合条件的一个电影方块并驱动现实中的虚拟人物。

### 电影驱动现实
用电影方块，驱动同名的真实物体。
例如可以用电影方块控制BMAX模型的门的开和关闭; 控制主角和NPC的真实行为。

### 电影触发器
当现实中的物品与某个电影方块中的物品的初始位置接近时，自动触发电影方块中的内容，并驱动现实物品
这个功能可以用于制作Action & Puzzle Game。

### 研究方向与意义
未来可以形成闭环并加入物理仿真。 用户的行为又可以变成新的时间序列。 最终可以让人物在一个变化的环境中自主运动和生存。

### 道与人工智能的相似关系
尝试建立`道`， `人工智能`， `生物大脑`之间的相似关系。这个是系统，能量层次的相似，已经不是神经元形态的局部相似。
- 道： 在Paracraft的人工智能中，它本质是一个无限大的没有绝对时间起点的时空序列的大集合：Memory。目前认为Hipocampus（神经元密度最高的一个大脑组织，如图）和长期记忆有关。
- 出有： 相似原理：根据注意力（attention），对齐时间起点， 形成Working Memory( in concious mind 意识)， 大脑皮层（面积最大）。
- 归无： Working memory又消亡为没有绝对时间起点的时空序列，long term Memory。Decay parameters。

对于`出有`（形成意识）有一个非常重要的器官是杏核体(如图)，它主要控制人类的情感Emotion。Emotion是为“出有”（形成意识）提供能量（原动力）的重要器官，如果分泌过多，会影响人脑归无的能力。
归无能力出现问题的时候： 人们会反复的思考一个问题， 不停的播放同一段影像。造成重复思考和抑郁症 （例如刚刚看到的人物会反复的做一个动作）。
`归无`（形成无意识下的长期记忆）是人脑的基本工作机制，为了节约能量，相似的内容链接越通常，熵值变小，链接在不断减少， 14-25岁形成了成年人大脑的主要模式。


## Code Architecture
MemoryContext is the entry point for an AI brain. It can be assigned to a player entity to provide memory based actions.

This is like the AI brain of the player entity. 
All long term Memory is stored in memory clips inside memory context. 
Memory clips can be played in parallel but always in one direction.

MemoryContext contains MovieClips, PlayerContext, VisionContext, etc. 

A MemoryClip can be time series of multiple actors. EntityMovieClip can be assigned and used as a read-only data source of memory clip. 
MemoryClip may be activated according to a set of rules or explicitly. 
Once activated, MemoryClip uses MemoryActor to play its memory into the 3d virtual world using the current PlayerContext.

PlayerContext manages major sensor input origin of the current player entity that the memory context belongs to. 

One major component of player context is the VisionContext of the player entity. 
The vision context generates Attention Objects for nearby observed objects in the virtual world. 
Attention Objects are automatically created and expired according to eye position of the player entity.
Two points of attentions are honored, one is the mouse cursor, the other is the block close to the player.

MemoryContext uses Attention Objects to activate the proper memory clip plus a number of other complex rules. 

## The Theory 

