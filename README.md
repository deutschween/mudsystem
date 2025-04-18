# Mud System

A server-authoritative system for applying movement penalties when players traverse mud-covered terrain.

## Features

- **Material-based Detection**: Uses raycasting to detect mud material (Enum.Material.Mud)
- **Configurable Parameters**: Adjustable accumulation rates, speed penalties, and detection settings
- **Network Optimized**: Uses RemoteEvents for efficient client communication
- **Visual Debugging**: Optional debug spheres for development testing
- **Server-Side Authority**: All calculations happen on the server for anti-cheat protection
- **Accumulation**: Mud is increased via levels, with each level making walkspeed slower.

## Installation
1. Make a new script in "ServerScriptService"
2. Copy MudSystem.lua
3. Paste the code to `Script`.

## Configuration
Modify the SETTINGS table at the top of the script:
```
local SETTINGS = {
    MudMaterial = Enum.Material.Mud,
    CheckHeight = {
        Offset = Vector3.new(0, -2.5, 0),  -- Detection center offset
        RaycastDistance = 3                 -- Downward ray length
    },
    Accumulation = {
        EnterTime = 30,    -- Seconds to reach max mud level
        ExitTime = 30,     -- Seconds to clear mud penalties
        Rate = 1           -- Mud level change per cycle
    },
    SpeedReduction = {
        PerLevel = 5,      -- Speed penalty per mud level
        MaxLevel = 3,      -- Maximum mud accumulation
        MinSpeed = 1       -- Minimum allowed movement speed
    }
}
```

## Network Communication
The system uses a RemoteEvent structure:
```
MudModifierEvent:FireClient(player, speedModifier)
```

## Debugging
This system has visual sphere debugging for detecting terrain material:
```
local DEBUG_VISUAL = true
```
