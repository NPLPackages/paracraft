# Networking Stacks Overview

This repo contains **four distinct networking layers** built over different eras. Use this page to pick the right stack when reading or modifying code.

## Comparison

| Stack | Location | Era | Transport | Primary use |
|-------|----------|-----|-----------|-------------|
| **Aries TCP Network** | `Creator/Game/Network/` | 2014+ | TCP packets | Paracraft multiplayer, classroom |
| **GGS / GeneralGameServerMod** | `Mod/GeneralGameServerMod/` | 2016+ | Mod RPC | GI sandbox games, extended multiplayer |
| **JGSL** | `kids/3DMapSystemNetwork/` | 2008–2012 | Jabber/XMPP JIDs | Legacy ParaWorld distributed mesh |
| **Kids Online (KM)** | `script/network/` + `script/server/` | 2007–2009 | Custom KM messages | World browser, upload, chat |
| **GameServer GSL** | `apps/GameServer/` | 2009+ | REST + NPLRouter | Haqi MMO backend, auth, world SVN |

## Decision tree

```
What are you working on?
│
├─ Paracraft world multiplayer / LAN / classroom
│   └─► Creator/Game/Network/  (+ TunnelService for NAT)
│
├─ Haqi login, world list, REST DB, trading
│   └─► GameServer/ (GSL) + DBServer + NPLRouter
│
├─ WorldShare cloud sync / Keepwork login
│   └─► Mod/WorldShare/ (HTTP APIs, not game packets)
│
├─ GI / Blockly sandbox multiplayer
│   └─► Mod/GeneralGameServerMod/
│
├─ Legacy ParaWorld quest/JGSL agent
│   └─► kids/3DMapSystemNetwork/ (JGSL)
│
└─ Legacy world browser / KM upload
    └─► script/network/ + script/server/
```

## How stacks relate

- **Haqi client (`Aries/main_loop.lua`)** uses GameServer REST for MMO backend and may use JGSL indirectly via Quest (`Quest/main.lua` loads `3DMapSystemQuest`).
- **Paracraft Creator** uses **Aries TCP Network** as a transparent plugin (`Network/readme.txt`); optionally **TunnelService** when direct TCP fails (NAT).
- **WorldShare** is HTTP/cloud layer on top — orthogonal to in-world packets.
- **JGSL** and **KM network** are largely superseded for new Paracraft features but still loaded by platform code paths.

## See also

- [Creator Network](aries/creator-network.md) — TCP packets + tunnel
- [JGSL Networking](jgsl-networking.md)
- [Game Server and Networking](game-server-and-networking.md) — GSL, REST, DBServer
- [Legacy Client Networking](legacy-client-networking.md) — script/network/
- [Mods](mods.md) — GGS, WorldShare
