--++ Network System
Author: LiXizhi@yeah.net
Date:2014.7
Company: ParaEngine Co.

---++ Achitecture
The entire network system acts like a plugin or a transparent module inside the ParaCraft tool environment. 
Because of this, networking is a standalone system that almost has nothing to do with the rest of the system,
and client and server can be disabled/enabled via commands at any time.  

| *filename*			| *desc |
| NetworkMain.lua		| main class to turn the network system on/off |
|						||
| ServerManager.lua		| singleton on server side to manager all client side connections and ACL, and assign them to entities. It owns the default WorldServer |
| ServerManagerDedicated.lua |  same as ServerManager, except that it may be running on a linux pure NPL server |
|						||
| WorldServer.lua		| present the world(s) that the server are currently serving. |
| EntityTracker.lua		| tracking all entities in the WorldServer |
| EntityTrackerEntry.lua | a single tracked entity|
| PlayerManager.lua		| Ensure all players are watching changes in nearby ChunkObservers.  | 
| ChunkObserver.lua		| it keeps all server side block changes in this chunk column as well as a list of all interested players observing this chunk. | 
| WorldTrackerServer.lua| trackering all block changes in the world and inform ChunkObserver to broadcast to players watching the chunk. | 
|						||
| WorldClient.lua		| present the remote world that the client is currently in. |
| WorldTrackerClient.lua| trackering all block changes only when advanced editing is enabled on client and send to server.  | 
|						||
| NetHandler.lua		| base class for handle packets. |
| NetClientHandler.lua	| handle client side network commands. each client has one such object |
| NetServerHandler.lua	| handle server side network commands on behalf of an authenticated player. Multiple such objects on server. |
| NetLoginHandler.lua	| only used on server side to handle an authenticated connection. |
| NetListener.lua		| processing incoming unauthenticated connections on the server side |
|						||
| ConnectionBase.lua	| base class for a connection. Each connection is associated with a handler. One handler may transfer connection to another handler. | 
| ConnectionTCP.lua		| used on both client/server to represent a remote end point. It provides queues and basic translation for known packets |
|						||
| Packet_Types.lua		| all packet types |
| Packet.lua			| base class for all packet. Packet is a wrapper to raw NPL message for a given purpose. |
| PacketXXX.lua			| a given kind of packet. |

---+++ Client side: 
	NetworkMain --> NetworkMain:Connect(ip, port, username, password) --> local worldclient = self:GetClient("default"); -->
	worldclient:Login --> 
		self.net_handler = NetClientHandler:new():Init(ip, port, username, password)-->
			self.connection = ConnectionTCP:new():Init(nid, nil, self) -->
			self.connection:AddPacketToSendQueue(Packets.PacketLogin:new():Init(username, password)); -->
		{ NetClientHandler:handleXXX, ... }
	On client side, the NetClientHandler spawns the connection and handle any messages thereafterwards. 

---+++ Server side: 
	NetworkMain --> NetworkMain:StartServer(host, port) -->
	self.server_manager = ServerManager.GetSingleton():Init(host, port); -->
		ServerListener:Init(); --> self:Tick(); -->
		ServerListener:OnAcceptIncomingConnection(msg) -->
			NetLoginHandler:new():Init(msg.tid); -->
				self.playerConnection = ConnectionTCP:new():Init(tid, nil, self); -->
			NetLoginHandler:handleLogin -->
				NetLoginHandler:TransferConnectionToPlayer(self.playerConnection); -->
					NetworkMain:GetServerManager()-->InitConnectionToPlayer(playerConnection); -->
						players[#players+1] = NetServerHandler:new():Init(playerConnection, ...) -->
						{ NetServerHandler:handleXXX(), ... }

	On the server side, the NetLoginHandler spawns the connection object on any incoming connections, 
	once authenticated, it will transfer ownership of the connection to NetServerHandler. 

---+++ Entity logics
	| *Standalone*			| *client*											| *server*									|
	| EntityPlayer*1		|													|											|
	|						|  EntityPlayerClient  * 1	(main player with tcp)	|											|
	|						|  EntityPlayerMPOther * N	(agent of other players)|											|
	|						|													| EntityPlayerMP * 1 (main player: NO tcp)  |
	|						|													| EntityPlayerMP * N (players: with tcp)    |
	|						|													|											|
	|						|													|											|
	| EntityXXX 			|  EntityXXX (GameLogic.isRemote==true)				| EntityXXX (GameLogic.isServer==true)		|
	|						|													|											|

Any standard EntityXXX (with "isServerEntity" attribute) is expected to behave differently according to three world states: standalone, client, and server. We can use following handy function to determine which state it is in:
   * Standalone:GameLogic.isRemote==false	and GameLogic.isServer==false
   * Client:	GameLogic.isRemote==true	and GameLogic.isServer==false
   * Server:	GameLogic.isRemote==false	and GameLogic.isServer==true

The main player in above three world states are EntityPlayer, EntityPlayerClient, and EntityPlayerMP. 
The most tricky class is EntityPlayerMP, which is also used to represent any client agent on the server side. 
The only difference is that the main player of EntityPlayerMP has no valid TCP connection object sociated. 

---+++ Packet logics
The core logics behind the synchronization is: 
   1. the server world is comprised of large number of entities (also items and blocks). 
   1. each entity will broadcast changes to subscribed observers (currently the only observer is EntityPlayerMP)
   1. each entity will automatically add/remove observers when they are in visible range. 
	  (there is an outer range for removal, and an inner range for adding)
   1. when an observer is newly added to an entity tracker entry, a Spawn packet is sent to client with complete information to reconstruct it on the client. 
   1. when an observer is removed to an entity tracker entry, a packet is sent to client to delete it on the client. 
   1. each entity (tracker entry) will broadcast Relative Packet to all observers after the spawn packet to synchronize any changes like position, rotation, riding, action, watched data, etc. 

Hence there are three kinds of packets
   1. Spawn packet: containing complete information which is sent to observer(EntityPlayerMP) when it is newly added (within inner view range).
   2. Relative packet: containing all delta changes of server entities after the spawn packet
   3. Command packet: any kind of interactions between client/server. 
Blocks are handled in the same way but slightly different. Block's spawn packet are always sent via binary compressed chunk columns; Block's relative packets are sent in three ways depending on the number of blocks changed after the spawn packet. For few blocks, either SingleBlock or MultiBlock packet is sent, for many blocks, a compressed chunk column is sent. Chunk data compression is done in C++ in binary format, all other packet data are sent in plain text table. 

---+++ Guide lines for adding network entities
   * Your class has to be derived from Entity, and set entity.isServerEntity to true. 
   * Send your spawn packet in EntityTracker:AutoAddEntityToTracker and EntityTrackerEntry:GetPacketForThisEntity()
   * handle your spawn packet in NetClientHandler:handleMovableSpawn or any custom handlers. 
   * In your entity class, turn off interaction and simulation when GameLogic.isRemote is true. Usually do so inside entity:FrameMove(), entity:ApplyEntityCollision(), etc.
   * If your entity has special information to send regularly, send it in entity:FrameMove() only if it is in the server world (GameLogic.isServer==true). And implement a handler in NetClientHandler:handleXXX and NetServerHandler:handleYYY. 
   * on client world. where GameLogic.isRemote is true), disable entity creation or send command to server for entity spawn. This is usually inside ItemXXX:OnCreate method. 
   * using data watcher for asynchronizing attributes which the client can freely modify: 
	  * call GetDataWatcher():AddField() to add a watched data field.
	  * The server entity should be able to update the watched data fields (such as in framemove when GameLogic.isServer is true), so that changed data are automatically sent to client.
	  * The client entity's should also update changed data to its view (such as in framemove when GameLogic.isRemote is true).
	  * please note, watched data are only sent relative to server spawn, so during client spawn, the server need to send the complete watched data to client. 

See following example for details
---++++ Example of EntityMob
Asset model, etc is sent via DataWatcher interface.
see `EntityMob:FrameMove` and `PacketEntityMobSpawn.lua` for example.

---++++ Example of EntityRailcar
Railcar networking features: 
   1. physics on the server  
   1. mount/unmount command between client/server  
   1. broadcast ridingEntity whenever it changes to clients
   1. spawn a new type of railcar entity. 
   1. position/rotation predication to show smoothed animation at lower network sync rate. 


---++  Changes
	- 2014.7.18: major implementation done
	- 2014.6.26: initial design and placeholders done.