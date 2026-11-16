# Hill Game

An offline, physics-driven hill-climb racer for Android, built with [Godot](https://godotengine.org) 4.7 (GDScript).
You drive a car over endless, seeded terrain, collect coins and fuel, land flips and big jumps for bonus coins,
and spend the coins on new vehicles, new stages and upgrades. There are no ads, no network code and no in-app
purchases, and nothing in it is random-reward or pay-to-roll: coins come from driving and every price is fixed.

All graphics and all sound are generated in code. The repository contains no image, audio or font files other than
the app icon (`game/icon.svg`, a hand-written SVG).

This is a prototype. See [Status](#status) for what works and what does not yet.

## What is in it

- **Driving physics**: script-driven spring-and-damper suspension on groove joints, per-vehicle drive and grip
  tuning, a crash-test dummy that is ejected on a head hit, and slow motion on crash. Godot's built-in 2D physics
  at 120 Hz with interpolation.
- **Four vehicles**: hatchback (starter), 4x4 pickup, monster truck, supercar. Each has its own physics numbers
  and code-drawn art (`game/scripts/vehicles/`).
- **Four stages**, each with its own gravity, ground friction, sky and parallax scenery: Meadow, Desert, Arctic
  (icy flats, low grip) and Moon (low gravity, craters and ramps). Terrain is generated from a seed in chunks
  around the player and freed behind them.
- **Stunts**: air time and flips pay coins, with a combo multiplier for tricks landed back to back.
- **Garage, stages and settings screens**: browse vehicles, buy and select them, buy four upgrade types
  (engine, suspension, tyres, fuel tank) in ten levels each, pick a stage, toggle music and sound, and erase
  progress. Progress is saved to the app's own data folder (`user://save.cfg`) and a damaged save is set aside
  instead of crashing.
- **Synthesised audio** (`game/scripts/audio/`): a four-layer engine sound that follows wheel speed, sound effects
  (coin, fuel, landings, crash, trick, UI) and percussion-only background music with one groove per stage. See
  [Status](#status) for how much of it is hooked up.
- **Tests**: 93 headless checks (`game/tests/run_all.gd`) for upgrade costs, upgrade effects, terrain determinism
  and flip counting, plus a separate headless audio check (`game/scripts/audio/audio_test.gd`).

## Controls

Touch: hold the right half of the screen for gas and the left half for brake/reverse; the two on-screen pedals
light up to show what is pressed. On desktop: Right arrow for gas, Left arrow for brake (clicking the left or
right half of the window also works, because mouse clicks are emulated as touches). In the air the same inputs
rotate the vehicle.

## Build and run

You need Godot 4.7 (the standard build, not .NET). The project uses the GL Compatibility renderer.

Open `game/project.godot` in the Godot editor and press play, or from a terminal:

```bash
godot --path game
```

Run the tests headless:

```bash
godot --headless --path game --import
godot --headless --path game -s res://tests/run_all.gd
```

`build.sh` does the import, the tests and a debug Android export (`./build.sh test` stops after the tests).
It reads its settings from environment variables, listed at the top of `env.sh`:

| Variable | What for |
|---|---|
| `GODOT` | Path to the Godot 4.7 binary (default: `godot` on your `PATH`) |
| `JAVA_HOME` | JDK 17 or newer, for the APK export |
| `ANDROID_HOME` | Android SDK folder, for the APK export |
| `GODOT_ANDROID_KEYSTORE_DEBUG_PATH`, `_USER`, `_PASSWORD` | The debug keystore Godot signs the APK with. Path and alias default to the usual debug-keystore location and alias; the password is never stored in the repo, so export it yourself |

The APK export also needs the Godot 4.7 Android export templates and the Android SDK build tools installed.
`./build.sh install` additionally installs and launches the APK over `adb`. The app id is `com.hillgame.demo`.

## Status

Prototype, not a finished game. What was checked on the current tree (on a Mac, with Godot 4.7.2):

- The 93 headless checks pass, and the audio check passes.
- The run scene was driven by its built-in test bot for 20 s of game time headless: no physics instability, tricks
  fired.
- `build.sh` exported a debug-signed APK (about 28 MB).

What is not done or not verified:

- **Vehicle choice and upgrades do not reach the run yet.** The garage lets you buy, select and upgrade vehicles
  and the vehicle code supports it (`Vehicle.setup(id, upgrades)`), but the run scene currently spawns the starter
  hatchback with stock upgrades whichever vehicle is selected. Fuel time in the run is a fixed constant.
- **The audio is not wired into the game.** It is implemented and tested on its own, but the run and the menus do
  not play it yet, so the music and sound toggles in Settings are saved but have no audible effect.
- **Nothing has been re-measured on a phone for this version.** An earlier build ran on a physical Android phone;
  frame rate with several vehicles, other devices and the final audio mix have not been checked.
- The screens are laid out for a wide landscape viewport (1280 x 720, scaled).

## Layout

```
game/
  project.godot, main.tscn       run scene (main.gd): terrain, vehicle, HUD, pickups, stunts
  ui/menu.tscn                   main scene: home, garage, stages and settings screens
  scripts/
    game_state.gd                autoload: coins, owned items, upgrades, best distances, settings, save file
    catalog.gd                   shared data: vehicles, stages, upgrades, prices
    vehicle.gd, vehicles/        suspension, drive, dummy; one spec and art file per vehicle
    stages/                      stage data, terrain height functions, decoration, sky and parallax
    ui/                          menu screens and widgets, all drawn in code
    audio/                       synthesised engine, sound effects and percussion music, plus audio_test.gd
  tests/run_all.gd               headless test runner
build.sh, env.sh                 import, test and Android export
```

## Credits and licence

Everything in this repository was written for it: the code, the generated graphics and sound, and the icon.
No third-party art, sound, font or shader files are included. It is built with the
[Godot Engine](https://godotengine.org) (MIT licence), which is not bundled.

Released under the [MIT licence](LICENSE).
