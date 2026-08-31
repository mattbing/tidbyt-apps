# Poet Clock

A clock that tells the time in three-line poems. Every minute of the day
has its own poem (1,440 in all); the app shows the one written for right now.

## What it displays

The poem for the current minute in the tiny 4x6 `tom-thumb` font, left-aligned
and vertically centered, keeping the poem's own line breaks. Poems that fit in
five screen lines are a single still frame. Longer poems (about one in six)
hold at the top for a moment, drift up to reveal the last line, hold, and drift
back down, so the loop has no jump.

## Where the poems live

In the `POEMS` dict at the bottom of `poet-clock.star`, keyed by minute
(`"10:14am"`) and grouped by hour, with `\n` for line breaks. Edit them there.

## Configuration

| Option     | Description                                                        |
|------------|--------------------------------------------------------------------|
| `location` | Used for the time zone. Falls back to the device's `$tz`.          |
| `color`    | Text color. Default `#FFF1D0` (warm white).                        |
| `time`     | Preview aid, not in the schema: render a given minute, e.g. `10:14am`. |

No API keys needed.

## Previewing

```sh
pixlet render apps/poet-clock/poet-clock.star time=10:14am -m 8
pixlet serve apps/poet-clock/poet-clock.star
```
