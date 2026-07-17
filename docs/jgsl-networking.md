# JGSL Networking

**JGSL (Jabber Game Server Lite)** — legacy distributed game networking for ParaWorld, built on Jabber/XMPP-style JIDs.

Location: `script/kids/3DMapSystemNetwork/` (~18 core files + tests)

Public API: `Map3DSystem.JGSL`, `Map3DSystem.JGSL_client` (per `JGSL_doc.txt`)

## vs other stacks

| | JGSL | Aries TCP Network | GameServer GSL |
|---|------|-------------------|----------------|
| Transport | Jabber JIDs | TCP packets | REST + NPLRouter |
| Topology | Multi-server mesh | Client-server | Standalone world server |
| Status | Legacy, still used by Quest | Active (Paracraft) | Active (Haqi MMO) |

See [Networking Stacks Overview](networking-stacks.md).

## Topology

```
Clients
    ↓ (JID)
Gateway  (load balancing)
    ↓
Grid nodes  (JID + id)  ← preferred server type
    ↓
Session keys invalidate stale connections
```

A PC can act as **client**, **server**, or **both**. Grid servers preferred over deprecated dedicated servers.

## Core files

| File | Role |
|------|------|
| `JGSL.lua` | Public entry, session reset, login API |
| `JGSL_doc.txt` | **Full design document** |
| `JGSL_client.lua` | Client implementation |
| `JGSL_clientproxy.lua` | Client proxy |
| `JGSL_client_emu.lua` | Emulated clients |
| `JGSL_server.lua` | Server core |
| `JGSL_serverproxy.lua` | Server proxy |
| `JGSL_servermode.lua` | Server mode setup |
| `JGSL_servermode_loop.lua` | Server main loop |
| `JGSL_gateway.lua` | Gateway load balancing |
| `JGSL_grid.lua` | Grid node simulation |
| `JGSL_agent.lua` | Agent logic |
| `JGSL_agentstream.lua` | Agent streaming |
| `JGSL_opcode.lua` | Opcode definitions |
| `JGSL_msg_def.lua` | Message definitions |
| `JGSL_config.lua` | Configuration |
| `JGSL_query.lua` | Query interface |
| `JGSL_history.lua` | History tracking |
| `JGSL_stringmap.lua` | String interning |
| `Authentification.lua` | Auth |
| `EmuUsers.lua` | Emulated user support |
| `ValueTracker.lua` | Value tracking |
| `Test/JGSL_StressTest.lua` | Stress test |

## Activation

Command-line flags in `ParaWorldCore.lua` (partially commented):

```
servermode="true"      → JGSL server mode
questservermode="true" → Quest server loop
```

Bytecode for this folder is **excluded** from standard `main_script` bin builds; source remains for development.

## Emulated users

Emulated clients read from runtime config:

```
config/EmuUsersDB.xml
```

(not in this script repo — runtime install path)

Aries module: `script/apps/Aries/EmuUsers/`

## Quest integration

`script/apps/Aries/Quest/main.lua` loads `kids/3DMapSystemQuest/Main.lua`, which ties into JGSL agent model.

Each GSL agent holds a reference to a `QuestPlayer` instance.

## See also

- [Networking Stacks Overview](networking-stacks.md)
- [ParaWorld Platform](paraworld-platform.md)
- [Quest System](aries/quest-system.md)
- [Game Server and Networking](game-server-and-networking.md)
- Source: `script/kids/3DMapSystemNetwork/JGSL_doc.txt`
