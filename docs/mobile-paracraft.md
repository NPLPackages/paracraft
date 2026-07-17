# Mobile Paracraft

Mobile-specific code in `script/mobile/`.

## Paracraft mobile layer

```
script/mobile/paracraft/readme.txt    # "ParaCraft Mobile" — LiXizhi, 2014.9.2
script/mobile/protobuf/encoder.lua    # Protobuf encoding
```

The mobile layer provides protocol serialization for Paracraft mobile clients communicating with servers.

## Related package manifests

| Manifest | Purpose |
|----------|---------|
| `packages/redist/main_mobile_res-1.0.txt` | Mobile resource bundle |
| `packages/redist/main_script_complete_mobile-1.0.txt` | Complete mobile script build |
| `packages/redist/main_script_complete_mobile_src-1.0.txt` | Mobile source variant |

## Creator mobile UI

Paracraft Creator mobile registration and UI (inside Aries tree, not `script/mobile/`):

```
script/apps/Aries/Creator/Game/Mobile/MobileUIRegister.lua
script/apps/Aries/Creator/Game/Mobile/UserProtocolPre.lua
script/apps/Aries/Creator/Game/Login/PrepareApp/
script/apps/Aries/Creator/Game/Educate/Login/MainLoginMobileLogin.html
script/apps/Aries/Desktop/Dock/AriesMobilePage.lua
```

## Platform detection

```lua
-- ParaWorldCore.lua
options.IsMobilePlatform = (ParaEngine.GetAppCommandLineByParam("IsMobilePlatform", "false") == "true");
```

## Android-specific

`script/apps/Aries/Creator/Game/Android/Android.lua` — Android platform hooks in Creator.

## See also

- [Paracraft](paracraft.md)
- [Main Package](main-package.md) — mobile manifests
- [Packages and Build](packages-and-build.md)
