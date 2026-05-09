# Fatality.win-Lav-lua
# Watermark & Kill Say Script

A Fatality CS2 Lua script with two features: a customizable on-screen watermark and an automatic kill chat message.

---

## Watermark

Displays a live info bar in the top-right corner of your screen while you're in-game.

**Shows:**
- Your player name
- Current time (with adjustable timezone)
- Your ping in milliseconds
- Your kill and death count for the session

**Settings:**
- Turn it on or off with a checkbox
- Adjust corner rounding with a slider
- Set your timezone offset (−12 to +14 hours)
- Enable a glow effect that pulses around the watermark for 1.5 seconds every time you get a kill

---

## Say on kill

Automatically sends a message in chat whenever you get a kill.

**Three modes to choose from:**
- **Disabled** — turned off, does nothing
- **All kills** — sends a message every time you kill someone
- **Headshot / 1tap only** — only sends when you get a headshot or deal 100+ damage in one hit

**Custom message:**
- By default it just says `1` in chat
- Enable "Use custom text" and type whatever you want it to say instead

---

## Menu location

All settings appear directly inside the Fatality menu under the Lua tab, no separate window needed.
