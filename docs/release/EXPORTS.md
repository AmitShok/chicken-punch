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

The Travel Book update exports completed successfully. The Windows executable passed a headless startup check; the source build's menus, rewards, pause inspection, and HUD were rendered and inspected with the native renderer. Desktop Chrome checks cover the exported menu, options, movement, combat, pause, results, and saving across reload.

An accelerated source-game soak reached victory after all three guardians. These checks do not certify mobile, Safari or Firefox, or a full manual Windows playthrough of this update.

The ZIPs include the ChickenPack, Ninja Adventure and Travel Book Lite licenses. Travel Book Lite is by Crusenho Agus Hennihuno: https://crusenho.itch.io/complete-ui-book-styles-pack. UI textures are resized/tinted in-engine; source sprites are unchanged.

Generated builds are excluded from Git; export presets and source changes are versioned.
