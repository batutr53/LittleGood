# Actual emulator sample — 25 October 2026

Paused home scene with ambient animation, five-second warmup, five-second samples. Emulator performance is not physical-device performance. Neither target is certified.

| Cap | Measured FPS | Frame p95 ms | Process p95 ms | World update p95 ms | Draw calls | Static MB | Texture MB |
|---|---|---|---|---|---|---|---|
| 60.00 | 13.97 | 79.71 | 89.03 | 1.15 | 234.00 | 42.07 | 34.20 |
| 30.00 | 18.57 | 61.65 | 62.61 | 1.09 | 186.00 | 42.06 | 34.20 |

The process monitor includes engine/render work; it is not a measurement of the simulation alone. Home simulation is paused during this sample. Sustained-combat profiling remains open.

Cold Activity launch (ADB am start -W):

```text
Starting: Intent { cmp=org.littlegod.livinguniverse.rpgqa/com.godot.game.GodotAppLauncher }

Status: ok

LaunchState: COLD

Activity: org.littlegod.livinguniverse.rpgqa/com.godot.game.GodotApp

TotalTime: 1531

WaitTime: 1543

Complete
```

Full checks and APK hash: [verification.json](verification.json). Native tap smoke-test evidence: [native-smoke.json](native-smoke.json).
