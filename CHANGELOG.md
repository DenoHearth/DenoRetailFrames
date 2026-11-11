# Changelog

## v0.10.4 — 2026-11-11

- Target and focus frames: the circle shows either the level number or the skull, never both on top of each other

## v0.10.3 — 2026-11-11

- Target and focus frames: the level number is back in the small circle at the bottom right of the portrait, for friendly and enemy targets alike; the circle was empty
- The skull for targets too high to tell now sits in that circle as well, instead of over the start of the name
- The name uses the space the level number left free, so longer names fit

## v0.10.2 — 2026-11-08

- The gold glow while resting, the red glow in combat and the red aggro flash now sit exactly on the round player frame; they were drawn a few pixels to the left and too low
- Incoming heals, absorb shields and the mana a cast will cost now fill the full height of the bar on the player and target frames, instead of a thin strip

## v0.10.1 — 2026-11-07

- Party and raid frames are drawn at full strength again. An imported Edit Mode layout set their opacity to about half, so members in range looked faded too; the game's own fade for members out of range stays
- Every party and raid member now gets a power bar, not only healers: the game's "Display Only Healer Power Bars" setting is switched off at login

## v0.9.0 — 2026-11-05

- New: "Always Show XP Bar Text", on by default. The experience bar shows its numbers all the time, not only under the mouse. It is the game's own setting (xpBarText), which Forever's Options have no checkbox for; switching the option off puts the game's setting back as it was
- New options page: game Options, AddOns, Deno Retail Frames (or /drf)

## v0.8.0 — 2026-10-21

- First public release
- Retail layout on the game's own player, target and focus frames: name, level, health and mana bars, round portrait ring on the player frame
- Retail bar fill art without gaps
- Class colour behind a player's name on the target and focus frames
- Absorb shields on the player, target and focus frames are white instead of blue
