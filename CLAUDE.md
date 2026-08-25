# Tidbyt Apps

This repository is an archive of Tidbyt apps written in Starlark using the Pixlet SDK. It is read and updated by the user's Tronbyt device.

## App Structure

Each app lives in its own directory under `apps/`:

```
apps/app-name/
  app-name.star    # The Starlark source file
  README.md        # Description, screenshot, and usage notes
```

## Creating a New App

1. Create a directory named after the app (lowercase, hyphens for spaces)
2. Write the Starlark app as `app-name.star` inside that directory
3. Include a `README.md` with:
   - App name and brief description
   - What it displays on the Tidbyt
   - Any configuration options or API keys needed
   - Screenshot if available

## Starlark / Pixlet Basics

- Tidbyt apps are written in **Starlark** (a Python-like language), not Python
- The entry point is a `main()` function that returns a `render.Root` widget
- The Tidbyt display is **64x32 pixels** with RGB color
- Common imports: `render`, `schema`, `http`, `cache`, `encoding/json`, `time`
- Use `pixlet render apps/app-name/app-name.star` to render locally
- Use `pixlet serve apps/app-name/app-name.star` to preview in a browser

## Starlark Constraints

- No `import` — use `load()` statements instead
- No classes, only functions and structs
- No `while` loops — use `for` with `range()`
- No `try/except` — handle errors via return values
- No mutating global state
- Strings are not iterable

## Pixlet Render Widgets

Common widgets: `Root`, `Box`, `Column`, `Row`, `Stack`, `Text`, `Image`,
`Marquee`, `Animation`, `Padding`, `WrappedText`, `Circle`, `Plot`

## Rendering and Viewing an App

```sh
pixlet serve apps/<app>/<app>.star                    # Live-reloading browser preview
pixlet render apps/<app>/<app>.star                   # Writes <app>.webp next to the source
pixlet render apps/<app>/<app>.star --format gif -o /tmp/out.gif
pixlet render apps/<app>/<app>.star -m 4              # Magnify 4x — 64x32 is tiny to eyeball
pixlet render apps/<app>/<app>.star key=value         # Pass schema config values
pixlet check apps/<app>/<app>.star                    # Lint (wants a manifest.yaml; only
                                                      # needed for community submission)
```

`pixlet serve` is the fastest loop for iterating on layout. For animation bugs the
browser preview will lie to you about frame boundaries — render a GIF and inspect the
actual frames instead:

```sh
ffprobe -v error -count_frames -select_streams v:0 \
  -show_entries stream=nb_read_frames -of default=nw=1:nk=1 /tmp/out.gif   # frame count
ffmpeg -v error -i /tmp/out.gif -f rawvideo -pix_fmt gray /tmp/out.gray    # raw pixels
```

Then walk `/tmp/out.gray` in 64*32-byte chunks to see which rows are lit per frame.
That's how you tell a genuine loop seam from a truncated animation.

## Animation Gotchas

- **`pixlet render` silently truncates at `--max-duration` (default 15s).** No warning,
  exit code 0 — the animation just stops mid-motion and loops back to frame 0, which
  looks like a flicker/hard-reset on the device. Always check the frame count against
  `15000 / delay`.
- **`Marquee` scrolls exactly 1px per frame.** Its frame count is
  `content_size + offset_start + marquee_size - offset_end` (plus 1 when the two offsets
  differ). With `render.Root(delay = 100)` you only get 150 frames total — for a 30px-tall
  vertical Marquee that is about 120px of scrollable content. Halve the delay or cap the
  content to stay inside the budget.
- **`Marquee` renders only frame 0 of its child**, so nesting an animation inside one
  does nothing.
- Setting `offset_start == offset_end` removes the scroll-back phase and gives a
  blank-to-blank loop (the last frame still keeps 1px of content on screen — that's
  inherent to the widget, not a bug worth chasing).

