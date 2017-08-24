# Welcome to Paracraft
- Official website: www.paracraft.cn

## start pure server
This is working under both linux and windows. Note: The world must exist and have home point set. 
```
[your_exe] servermode="true" world="worlds/DesignHouse/test" ip="0.0.0.0" port="6001" autosave="10" mc="true" bootstrapper="script/apps/Aries/Creator/Game/main.lua"
```
The above command will automatically load the given world and `/startserver 0.0.0.0 6001`. 
It will also enable autosave every 10 minutes on the server side. 
