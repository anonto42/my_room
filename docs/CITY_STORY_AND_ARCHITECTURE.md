# City Story and Architecture

This document explains the new city direction, which systems are used, why they are used, how to update them, and what we learned while moving from a single room to a larger-scale world.

## Basic Story

Working title:

- `New Harbor Nights`

Premise:

- The player starts in a safehouse room.
- New Harbor City is outside the gate.
- The city is waking up after a long quiet period.
- The player becomes a local systems keeper who explores districts, checks public systems, and slowly turns a placeholder city into a living city.

Why this story is best for this project:

- The original room still matters as the player hub.
- The city can grow in small updates without needing the whole open world finished at once.
- Every new mechanic can connect to a believable city need: power, water, transit, jobs, homes, shops, safety, music, internet, or social life.

## Current City Shape

The current playable city is a first block outside the safehouse gate.

Districts:

- `Home Row`
- `Maker Yards`
- `Market Spine`
- `Civic Core`

Important sites:

- City map kiosk
- Power grid cabinet
- Market request board
- Transit node
- Water pump station

Each site can be inspected with the same first-person interaction system already used by the room.

## Systems Used

`CITY_DISTRICTS` in `scripts/main.gd`:

- Defines named ground areas.
- Best for flexible layout because each district is one dictionary entry.

`CITY_BLOCKS` in `scripts/main.gd`:

- Defines placeholder buildings.
- Best for early production because size, position, material, and label are easy to change.

`CITY_SITES` in `scripts/main.gd`:

- Defines interactable city points.
- Best for story and mission expansion because every site has an id, title, story flag, hint, message, position, and visual material.

`Marker3D` asset slots:

- Added to districts, buildings, and city sites.
- Best for future 3D assets because final models can be attached at stable nodes without rewriting city logic.

`city_site.gd`:

- Handles city interactions.
- Best because all city command points share one script instead of many duplicated scripts.

`GameState`:

- Tracks `current_zone`, `current_chapter`, `city_reputation`, visited sites, story flags, and objectives.
- Best because city systems, UI, save/load, and quests will all need shared state later.

## How To Update The City

To add a district:

- Add one dictionary to `CITY_DISTRICTS`.
- Set `id`, `name`, `position`, `size`, `material`, and `label`.

To add a building:

- Add one dictionary to `CITY_BLOCKS`.
- Use the placeholder mass now.
- Later, attach the final imported model to the building `AssetSlot`.

To add an interactable city point:

- Add one dictionary to `CITY_SITES`.
- Give it a unique `id` and `story_flag`.
- Write the player-facing message in `message`.
- The builder will create collision, prompt text, marker visuals, and state updates automatically.

To replace placeholders with real 3D assets later:

- Import the asset into `assets/`.
- Instance it at the matching `AssetSlot`.
- Hide or remove the placeholder mesh only after collision and scale are checked.
- Keep the same `site_id`, `city_block_id`, or `district_id` metadata so save data and quest logic remain stable.

## Learning From This Update

- The single room worked because it was small enough to build directly.
- A city needs data-driven layout because hand-coding every object would become hard to maintain.
- Keeping the room and city in one playable scene is best right now because it avoids loading complexity while the prototype is still small.
- The gate is now a real gameplay bridge instead of a coming-soon sign.
- Story flags are better than hardcoded story steps because future missions can check them in any order.

## Next Best Updates

- Add a small city HUD panel for current zone, reputation, and active objective.
- Move city dictionaries into custom `Resource` files when the data grows too large for `main.gd`.
- Add save/load for `GameState`.
- Replace one placeholder building with a real 3D asset as the asset pipeline test.
- Add NPC placeholders after district layout feels good.
