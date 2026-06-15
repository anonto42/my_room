# MyRoom Game Pages and Systems

This document explains which game page or scene uses which systems, and why those choices are the best fit for the current version.

## Main Game Page

Scene:

- `res://scenes/main.tscn`

Scripts:

- `res://scripts/main.gd`
- `res://scripts/game_state.gd`

Uses:

- `Node3D` root scene
- Procedural primitive room setup
- Data-driven city setup
- Runtime furniture setup
- Runtime player setup
- Runtime lighting setup
- Runtime HUD setup
- `GameState` autoload

Why these are the best fit:

- `Node3D` is the correct root for a 3D first-person game.
- Procedural primitive setup lets the game run now without waiting for final `.glb` models.
- Keeping setup in `main.gd` makes the current prototype easy to debug because the full playable world is created from one clear entry point.
- City dictionaries are the best current fit because districts, buildings, interaction points, and lights can be changed without rewriting builder logic.
- `GameState` is best for shared state like PC, fan, AC, sitting, sleeping, current zone, city visits, and story flags because multiple objects need to read or update those values.

Player experience:

- This is the main playable world page. The player spawns inside the safehouse room and can move out into New Harbor City through the gate.

## Player Page

Scene:

- `res://scenes/player.tscn`

Script:

- `res://scripts/player.gd`

Uses:

- `CharacterBody3D`
- `Camera3D`
- `RayCast3D`
- `AnimationPlayer`
- Tween-based transitions
- HUD prompt updates

Why these are the best fit:

- `CharacterBody3D` is the correct Godot 4 node for first-person movement with collisions.
- `Camera3D` under a `Head` node makes mouse-look simple and natural.
- `RayCast3D` is the best fit for first-person interaction because it checks exactly what the player is looking at.
- Tweens are the best fit for sit and sleep camera movement because these are short property transitions.
- `AnimationPlayer` is kept in the scene so hand and body animations can be expanded later without changing the player structure.

Player experience:

- WASD moves the player.
- Mouse controls the camera.
- E interacts with the object under the crosshair.
- Sitting and sleeping lock movement correctly.

## Room Page

Scene:

- `res://scenes/room.tscn`

Runtime builder:

- `scripts/main.gd`

Uses:

- `MeshInstance3D`
- `StaticBody3D`
- `CollisionShape3D`
- Box meshes for floor, walls, and ceiling

Why these are the best fit:

- Box meshes are the fastest and clearest way to block out a realistic room.
- Static bodies are correct for walls, floor, and ceiling because they do not move.
- Collision shapes match the visual boxes, which makes movement debugging straightforward.

Player experience:

- The player starts inside a 10m by 10m safehouse room.
- The south wall now has a gate opening that connects to the city.

## City Page

Runtime builder:

- `scripts/main.gd`

Scripts:

- `res://scripts/city_site.gd`
- `res://scripts/game_state.gd`

Uses:

- `CITY_DISTRICTS` dictionaries
- `CITY_BLOCKS` dictionaries
- `CITY_SITES` dictionaries
- `STREET_LIGHT_POSITIONS`
- `MeshInstance3D` placeholder geometry
- `StaticBody3D` collision
- `Area3D` city entry trigger
- `Marker3D` asset slots
- `Label3D` district and building labels
- `GameState.current_zone`
- `GameState.visited_city_sites`
- `GameState.city_story_flags`

Why these are the best fit:

- Dictionaries make the city flexible. To add a new district, building, or interaction site, add one data entry instead of duplicating scene-building code.
- Primitive meshes keep the city playable before final 3D assets exist.
- `Marker3D` asset slots give future imported models a stable place to attach without redesigning gameplay logic.
- `Area3D` is the right choice for zone detection because entering the city should react to player position, not a button press.
- `city_site.gd` keeps all city inspection points using the same interaction contract as room objects.

Player experience:

- The player opens the gate and walks into New Harbor City.
- The current city block includes Home Row, Maker Yards, Market Spine, and Civic Core.
- The player can inspect the city map, power grid, market board, transit node, and water station.
- Each inspected site records story progress in `GameState`.

How to update this page:

- Add a district in `CITY_DISTRICTS` when the city needs a new named ground area.
- Add a building in `CITY_BLOCKS` when the city needs a new visible structure.
- Add a site in `CITY_SITES` when the player needs a new interactable story, job, shop, or system point.
- Replace placeholders by instancing imported 3D assets at each node's `AssetSlot`.
- Keep gameplay state in `GameState`; keep local visuals inside the builder or the site script.

## Bed Page

Scene:

- `res://scenes/furniture/bed.tscn`

Script:

- `res://scripts/bed.gd`

Uses:

- Interactable group
- `SleepPosition` marker
- Player sleep method
- Fade overlay from HUD

Why these are the best fit:

- A marker is the best way to define the target camera pose for sleeping because designers can move it visually later.
- The bed delegates sleeping to the player script, which keeps player state and camera control in one place.
- Fade overlay is the right choice for sleep because it hides the camera teleport/reset cleanly.

Player experience:

- Looking at the bed shows the sleep prompt.
- Pressing E starts the sleep sequence.
- After the delay, E wakes the player.

## Fan Page

Scene:

- `res://scenes/furniture/fan.tscn`

Script:

- `res://scripts/fan.gd`

Uses:

- Interactable group
- Toggle state
- Rotating `FanBlade`
- Tweened spin speed
- Optional `AudioStreamPlayer3D`

Why these are the best fit:

- A boolean state is enough for an on/off fan.
- Rotating only the blade is cheaper and clearer than animating the whole object.
- Tweening blade speed is better than instantly stopping because it feels more physical.
- `AudioStreamPlayer3D` is correct for object-local sound because fan hum should come from the fan position.

Player experience:

- The prompt changes between turning the fan on and off.
- The blade spins when the fan is on and slows when turned off.

## AC Page

Scene:

- `res://scenes/furniture/ac.tscn`

Script:

- `res://scripts/ac.gd`

Uses:

- Interactable group
- Toggle state
- Optional `AudioStreamPlayer3D`
- Optional `CPUParticles3D`
- `GameState.ac_is_on`

Why these are the best fit:

- A toggle is the correct model for simple AC power.
- Particles are a good lightweight visual hint for cold air.
- `GameState` lets future temperature, comfort, and save systems read AC state.

Player experience:

- The prompt changes between turning the AC on and off.
- Cold air particles can show when AC is enabled.

## Computer Desk Page

Scene:

- `res://scenes/furniture/computer_desk.tscn`

Scripts:

- `res://scripts/computer.gd`
- `res://scripts/gaming_chair.gd`
- `res://scripts/screen_ui.gd`

Uses:

- Desk, keyboard, mouse, PC tower, and gaming chair nodes
- Four monitor nodes
- `SubViewport` per monitor
- `ViewportTexture` on monitor materials
- `OmniLight3D` monitor glow
- Player sit/stand methods

Why these are the best fit:

- `SubViewport` is the best Godot feature for rendering real UI onto 3D monitor screens.
- Separate viewports per monitor prepare the project for a future multi-monitor fake OS.
- `ViewportTexture` keeps the monitor UI live on the 3D screen mesh.
- `OmniLight3D` monitor glow sells the screen light in the room without needing expensive custom lighting.
- The chair controls sitting, while the player controls movement and camera state; this separation keeps each script responsible for one job.

Player experience:

- The player can sit at the desk even if the PC is off.
- The PC can be powered on and off.
- Monitors light up when the PC is on.
- Pressing E while sitting stands the player back up.

## Monitor UI Page

Scene:

- `res://scenes/ui/screen_ui.tscn`

Script:

- `res://scripts/screen_ui.gd`

Uses:

- `Control`
- `ColorRect` wallpaper
- `Panel` taskbar
- `Button` start button
- `Label` clock
- `GridContainer` desktop icons
- `WindowLayer` placeholder

Why these are the best fit:

- Godot `Control` nodes are the correct choice for UI because they handle layout, anchors, and text cleanly.
- A taskbar and clock make the monitors feel like an actual desktop.
- `WindowLayer` keeps future app windows isolated from the wallpaper and taskbar.
- `GridContainer` is a good fit for desktop icons because it can expand naturally as apps are added.

Player experience:

- When the PC is on, each monitor displays a simple desktop interface with icons and a live clock.

## HUD Page

Scene:

- `res://scenes/ui/hud.tscn`

Runtime builder:

- `scripts/main.gd`

Uses:

- `CanvasLayer`
- `Label` interaction prompt
- `ColorRect` fade overlay
- `ColorRect` crosshair

Why these are the best fit:

- `CanvasLayer` keeps HUD elements independent from 3D camera movement.
- A label is the simplest reliable way to show current interaction text.
- A full-screen `ColorRect` is the best fit for fade-to-black transitions.
- A small crosshair makes raycast targeting readable without adding visual clutter.

Player experience:

- The prompt appears only when the player looks at an interactable.
- The crosshair helps aim interactions.
- Sleep uses the fade overlay.

## Global State Page

Script:

- `res://scripts/game_state.gd`

Uses:

- Autoload singleton
- Shared booleans
- Signals
- Current city zone
- City story flags
- Visited city sites
- Active objectives

Why these are the best fit:

- An autoload is available everywhere without manually passing references between unrelated objects.
- Shared booleans are simple and clear for the current v1 states.
- Signals let future UI, audio, saving, and analytics systems react to state changes without tightly coupling to object scripts.
- City dictionaries and story flags prepare the project for save/load and quest tracking without building those full systems too early.

Current shared states:

- `player_is_sitting`
- `player_is_sleeping`
- `fan_is_on`
- `ac_is_on`
- `pc_is_on`
- `room_light_on`
- `current_time_of_day`
- `current_zone`
- `current_chapter`
- `city_reputation`
- `visited_city_sites`
- `city_story_flags`
- `active_objectives`

## Why This Architecture Is Good For The Current Version

- It runs without external models or audio assets.
- It keeps each gameplay object in its own script.
- It uses Godot 4-native systems: `CharacterBody3D`, `RayCast3D`, `SubViewport`, `Control`, `Tween`, and `CanvasLayer`.
- It is easy to replace primitive meshes with final assets later.
- It leaves clear extension points for fake OS apps, music, browser, save data, day/night cycle, district loading, shops, jobs, transit, and city simulation.
