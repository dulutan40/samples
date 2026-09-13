# Volfied

Flutter game for **iOS, Android, macOS, and web**. Claim the black field by cutting orthogonal trails. A giant-headed snake lives in the remaining dark and will poison an open path.

You start at **0%** (a one-cell rim). A clear run can reach about **99.9%**. This build treats **80%** as a stage clear so a first loop is finishable.

## Play

- Arrow keys (or WASD) move on the **border** between your land and the computer’s.
- Hold **space** and press an arrow to cut into enemy ground. Release space to walk the rim again, or backtrack the open trail.
- Close the trail on your own land to keep the partitioned region that does **not** contain the monster. Shapes are orthogonal: rectangles or even-sided polygons.
- If the monster touches you, you die.
- If it touches your open trail, poison races along the line toward you. Reach safety first and the poison dies. If it reaches you first, you die.
- The beast is **giant** most of the time (about 1/20 of the starting field, head about 1/3 of its body). After you claim enough, it shrinks (about 1/100 of the field, smaller head).

On a phone, use the on-screen pad and hold **HOLD SPACE**.

## Layout

Platform folders (`ios`, `android`, `macos`, `web`) stay platform-specific.

```text
assets/                 texts, images, styles, scripts, videos, hooks, fonts
lib/main.dart           app entry
lib/src/
  components/
    atoms/              packages only
    molecules/          packages + atoms
    microstructures/    packages + atoms + molecules
    macrostructures/    packages + atoms + molecules + microstructures
  containers/           screen sections
  screens/              full views
  services/             first responders; they use hooks and scripts
  helpers/              constants, fonts, theme, geometry
  hooks/                keyboard, hold, ticker
  scripts/              claim, monster, poison
  game/                 playfield and world
  models/
```

Dart has to compile from `lib/`. That is why `src` lives at `lib/src`. Static files stay under `assets/`.

## Run

```bash
cd dart/volfied
flutter run -d chrome
flutter run -d macos
flutter run
```
