tunnel service design
======================

date: 2016.3.4
author: LiXizhi

How to User Tunnel Server
======================

* `/tunnelserver ` command to start a tunnel server
* `/startserver -tunnel room_test ` command to start a server in a given room of the given tunnel server
* `/connect -tunnel room_test ` command to connect to the server in a given room of the the given tunnel server


Module Overview
======================
## gateway
  * gateway:login
  * lobbyserver: 
    - {room_key, {nid, ...}}
    - {tunnelserver}
    - API:
    	- lobbyserver.API.registerTunnelServer
    	- lobbyserver.API.createRoom, joinRoom, .... : return room_key, nid,...


> room_key is a like a session_key. 
> virtual_nid is composed of {room_key}_{nid}, which is used by the tunnel client which is uniquely identified by the virtual_nid


## tunnelserver    	
   * {room_key, {nid, ...}}
   * API:b
      * for gateway: tunnelserver.API.upsertRoom({room_key, {nid, ...}})  (updateAndInsert)
      * for tunnelclient: tunnelserver.API.relayMsg({room_key})

## tunnelclient
   * API: 
      * tunnelclient.API.connect(room_key,...)  to a tunnelserver
      * tunnelserver.API.sendMessage(room_key, target_nid, ...)

## client
   * TCPConnectionBase
       * SetTunnelProxy(tunnelclient)
       * filters: Send, Receive(activate)

