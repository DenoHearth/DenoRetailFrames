# Deno Retail Frames

Puts the retail layout back on the game's own player and target frames: level number top right, name on the left, full-height health bar.

[![Latest release](https://img.shields.io/github/v/release/DenoHearth/DenoRetailFrames?label=download&style=for-the-badge)](https://github.com/DenoHearth/DenoRetailFrames/releases/latest)

A World of Warcraft: Forever addon (interface 16001).

## What it does

Forever's player, target and focus frames use the same art as retail, only laid out
differently. This addon puts the retail layout back on the game's own frames:

- **Player frame:** name on the left, level number top right in gold, a full-height health
  bar and the round portrait ring of the target frame, mirrored.
- **Target and focus frames:** retail name and reputation strip positions, with the
  strip behind a player's name in their class colour. The level number (or the skull) stays
  in the game's small circle at the bottom right of the portrait.
- **Retail bar art:** the bars fill edge to edge, without the gaps Forever's own fill art has.
- **White absorb shields:** the game already shows incoming heals and shields on these
  frames; the shield is now white instead of blue.
- **XP bar text:** the experience bar shows its numbers all the time (option "Always Show XP Bar
  Text", on by default; game Options, AddOns, Deno Retail Frames, or /drf).

Blizzard's own frames stay in place, so clicks, menus and Edit Mode work as before. Nothing
is moved during combat.

## Install

1. Download the zip from the [latest release](https://github.com/DenoHearth/DenoRetailFrames/releases/latest).
2. Extract the `DenoRetailFrames` folder into your client's `Interface\AddOns\` directory.
3. Restart the client, or type `/reload` if it is already running.

## Compatibility

- World of Warcraft: Forever, interface version **16001**.
- Forever only. It uses that client's API and will not load on retail or the Classic clients.

## Changelog

What changed in each version: [CHANGELOG.md](CHANGELOG.md).

## License

MIT — see [LICENSE](LICENSE).  Current version: 0.8.0.
