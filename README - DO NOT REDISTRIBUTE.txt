F-15EX V3 (2026-11-01)
==================

This is a new version of the F-15EX mod. It is not made or supported by Eagle Dynamics.

DO NOT REDISTRIBUTE
-------------------
This build is for your own use only. All rights reserved.
You may install and fly it yourself. You may not share, upload, re-host, sell or pass on these files or any part of
them (DLL, Lua scripts, models, textures, sounds), modified or not, and you may not reuse any part of them in other
projects, without written permission from the mod's authors. Delete it when asked to.

INSTALL
-------
1. Remove any older F-15EX mod folder from Saved Games\DCS\Mods\aircraft (e.g. "F-15EX V2.33").
2. Copy the "Mods" and "Scripts" folders from this package into Saved Games\DCS (merge with the folders there).
   Scripts\Hooks\F15EX_HMD_hook.lua passes mission data to the jet (IFF, our missiles in flight, the bullseye).
   Scripts\Hooks\F15EX_DL_relay_hook.lua brings friendly fighters' datalink tracks to you in multiplayer.
3. Run the model app once (see FIRST: BUILD THE EXTERNAL MODEL below), then start DCS. The jets are
   F-15EX (after the app), F-15EX (CFTs) and F-15IA.

FIRST: BUILD THE EXTERNAL MODEL
-------------------------------
This package ships no external 3D model and no model LOD tables.
1. Open Tools\F-15E CFT Removal and run F-15E CFT Removal.exe.
2. Step 1: choose the external model file you want to use.
3. Step 2: choose this mod's folder, Saved Games\DCS\Mods\aircraft\F-15EX V3.
4. Step 3: press "Build and install". It writes the LOD tables, installs both models and enables
   the non-CFT F-15EX. Start DCS afterwards. The app never writes into the DCS install folder.

MULTIPLAYER SERVERS
-------------------
Friendly AI fighters' datalink tracks are made on the server, so the server passes them on to F-15EX players of the
same coalition over its own TCP port (default 10320). On the server (dedicated or hosting), install the mod and BOTH
hooks into the server's Saved Games folder, and allow TCP port 10320 in through its firewall / router. Each F-15EX
player gets one chat line naming the address. To change the port or name the server's public address, add lines to
Mods\aircraft\F-15EX V3\bin\F15EX_MslLink.cfg on the server (create it if missing):
   dl_relay_port=10320
   dl_relay_addr=your.public.address
Without the relay, players still get datalink tracks from AWACS and friendly positions.

MANUAL
------
Open "F-15EX V3 Manual.html" (one file, any browser): the pilot's guide with pictures of every display, the keys
and the setup steps.

REPORTING A PROBLEM
-------------------
Right after the flight, before starting DCS again (DCS overwrites it), send Saved Games\DCS\Logs\dcs.log and
the track file (.trk) of the flight, and say which jet, which mission, and roughly when in the flight it happened.
