# Tidbyt Apps

This repository is an archive of Tidbyt apps written in Starlark using the Pixlet SDK. It is read and updated by the user's Tronbyt device.

## App Structure

Each app lives in its own directory under the repo root:

```
app-name/
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
- Use `pixlet render app-name.star` to render locally
- Use `pixlet serve app-name.star` to preview in a browser

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

## Testing

```sh
pixlet render <app-dir>/<app-name>.star   # Renders to .webp
pixlet serve <app-dir>/<app-name>.star    # Local preview server
pixlet check <app-dir>/<app-name>.star    # Lint/validate
```

