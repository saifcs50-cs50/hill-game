# Hill Game

An offline 2D hill-climb racing game for Android, made with [Godot](https://godotengine.org) 4.7 and GDScript. You
drive over endless hills, collect coins and fuel, earn extra coins for flips and long jumps, and spend them on
vehicles, stages and upgrades. I'm building it towards a Play Store release; this repository is the prototype.

There are no ads, no in-app purchases and no network code. Coins only come from driving and every price is fixed, so
nothing is a random reward or a paid roll. All graphics and sound are made in code: apart from the app icon
(`game/icon.svg`, a hand-written SVG) there are no image, audio or font files.

## Driving

Godot's built-in 2D physics runs at 120 Hz with interpolation. Each wheel sits on a groove joint with a spring and
damper driven by script, and each vehicle has its own drive and grip numbers. The driver is a crash-test dummy that
is thrown out when the car lands on its head, and the crash plays in slow motion.

The first demo felt too planted when I played it, as if the car was stuck to the hill. I retuned it with gravity at
820 px/s² on the normal stages (100 px is one metre), softer and longer suspension, more power, some bounce in the
tyres and extra kickers in the terrain.

## Vehicles, stages and stunts

Four vehicles: a hatchback (the starter), a 4x4 pickup, a monster truck and a supercar, each with its own physics
numbers and code-drawn art in `game/scripts/vehicles/`.

Four stages, each with its own gravity, ground friction, sky and parallax scenery: Meadow, Desert, Arctic (icy flats,
low grip) and Moon (low gravity, craters and ramps). Terrain is generated from a seed in chunks around the car and
freed behind it. Air time and flips pay coins, with a combo multiplier for tricks landed back to back.

## Menus and saving

The garage sells vehicles and four upgrades (engine, suspension, tyres, fuel tank) with ten levels each. Other screens
pick a stage, switch music and sound, and erase progress. Progress is saved to `user://save.cfg` in the app's own data
folder, and a damaged save is set aside instead of crashing the game.

## Sound

`game/scripts/audio/` synthesises a four-layer engine sound that follows wheel speed, effects (coin, fuel, landings,
crash, trick, UI) and percussion-only music with one groove per stage. It isn't connected to the game yet (see
[What works so far](#what-works-so-far)).

## Controls

Hold the right half of the screen for gas and the left half for brake and reverse; the two on-screen pedals light up
when pressed. On a computer, use the Right and Left arrows, or click either half of the window (mouse clicks are
emulated as touches). In the air, the same inputs rotate the vehicle.

## Build and run

You need Godot 4.7 (the standard build, not .NET). The project uses the GL Compatibility renderer.

Open `game/project.godot` in the Godot editor and press play, or from a terminal:

```bash
godot --path game
```

The tests are 93 headless checks in `game/tests/run_all.gd` (upgrade costs and effects, terrain determinism, flip counting)
plus a separate audio check in `game/scripts/audio/audio_test.gd`:

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

The APK export also needs the Godot 4.7 Android export templates and the Android SDK build tools.
`./build.sh install` then installs and launches the APK over `adb`. The app id is `com.hillgame.demo`.

## What works so far

Checked on the current tree, on a Mac with Godot 4.7.2:

- The 93 headless checks pass, and so does the audio check.
- The run scene's test bot drove for 20 s of game time, headless: no physics instability, and tricks fired.
- `build.sh` exported a debug-signed APK of about 28 MB.

Not done or not checked:

- Vehicle choice and upgrades don't reach the run. The garage and the vehicle code support them
  (`Vehicle.setup(id, upgrades)`), but the run scene always spawns the starter hatchback with stock upgrades. Fuel
  time in the run is a fixed constant.
- The audio isn't wired in. It is built and tested on its own, but nothing plays it, so the music and sound switches
  in Settings are saved and change nothing you can hear.
- This version hasn't been measured on a phone. An earlier build ran on a real Android phone, but frame rate with
  several vehicles, other devices and the final audio mix are unchecked.
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

The code, the generated graphics and sound, and the icon were all written for this repository. There are no
third-party art, sound, font or shader files. It is built with the [Godot Engine](https://godotengine.org) (MIT
licence), which is not bundled.

Released under the [MIT licence](LICENSE).
