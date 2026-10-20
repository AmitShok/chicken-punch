# Windows and web exports

Requires Godot 4.7.2 and its matching export templates. In the Godot Export dialog, use Windows Desktop or Web. Create the output folders before exporting.

Command-line equivalents, from the project directory:

```text
godot --headless --path . --export-release "Windows Desktop"
godot --headless --path . --export-release Web
```

## Windows

Run `builds/windows/Chickenpunch.exe`. This 64-bit Windows release embeds its resource pack and uses the chicken icon. Godot does not need to be installed. The build is unsigned.

## Web

Upload all files in `builds/web/` together to a static web host. The entry page is `index.html`. For itch.io, upload a ZIP with index.html at its root and select HTML game.

For a local preview, run `python -m http.server 8000 --directory builds/web` from the project root, then open http://localhost:8000. Opening index.html directly with file:// is unsupported. Use HTTPS for public hosting.

The web preset uses single-threaded WebAssembly and WebGL 2 Compatibility rendering. No SharedArrayBuffer isolation headers are required. Progress saves in browser storage per site, separately from the Windows save. Browser storage must be allowed. Sound begins after user interaction. Quit is hidden on web because browsers cannot close their own tab on demand.

Reference: https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_web.html

## Validation

Both release exports completed without export errors. Windows was checked in the actual executable window: menu, rendered combat, kills, compact HUD, pause inspector, and run completion. Web was served over localhost and tested in desktop Chrome: options, movement, combat, pause, results, and saving across reload.

These are desktop smoke tests, not a full ten-minute run or mobile/Safari/Firefox certification.

Generated builds are excluded from Git; export presets and source changes are versioned.
