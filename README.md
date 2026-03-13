# HPH — Honor Per Hour Tracker

A lightweight, single-file WoW addon (Turtle WoW / 1.12) that tracks your PvP honor earnings in real time.

## Display

A small draggable frame shows five stats, updated every second:

| Line | Color | Stat |
|------|-------|------|
| Week | Light blue | Honor earned this week (via game API) |
| Last hour | Orange | Honor earned in the rolling past 60 minutes |
| Session | White | Honor earned since login |
| Honor/h | Yellow | Current session rate (honor per hour) |
| Time | Gray | Session duration |

## Commands

| Command | Action |
|---------|--------|
| `/hph` | Toggle the frame on/off |
| `/hph reset` | Move the frame back to the screen center |

## Notes

- No libraries required — single `.lua` file.
- Frame position is saved per character (`HPH_db`).
- Honor is detected from combat log and system messages, including French client messages.
