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

The October 27 balance/performance update adds overcrits, Redline and Slow Roast, strengthens the horde and guardians, and preserves the existing Ascensions. Both release exports completed successfully. The packaged Windows executable passed a headless startup check; the final web release passed main-menu, character setup, movement and pause-inspector checks without browser runtime errors. Both platforms use Compatibility rendering and interpolated 30 Hz physics. Build recipes and benchmark methodology are in `docs/design/ENDGAME_AND_PERFORMANCE.md` in the source repository.

Automated checks cover save migration, shop purchase conditions, level-ten caps, compass targeting, run setup, all weapons, evolution/Ascension, inspection and the new damage interactions. The accelerated full-run stability check defeated all three guardians at 611.27 seconds. It uses boosted player health, so it does not certify difficulty or human win rates.

The deliberately extreme rendered benchmark uses 180 unkillable enemies and a maxed four-weapon Ascension build. Native median frame time improved from 121.92 ms to 20.51 ms on the local Intel Iris Xe; p95 remained 55.74 ms. The equivalent WebGL trial improved from 230.40/455.90 ms to 29.70/66.70 ms median/p95, with no browser runtime errors. The optimization is substantial, but extreme builds can still cause frame spikes. Unlimited spawning and smooth performance on every device are not guaranteed. Tests do not certify mobile, Safari or Firefox, or replace a full manual playthrough.

The ZIPs include the ChickenPack, Ninja Adventure and Travel Book Lite licenses. Travel Book Lite is by Crusenho Agus Hennihuno: https://crusenho.itch.io/complete-ui-book-styles-pack. UI textures are resized/tinted in-engine; source sprites are unchanged.

Generated builds are excluded from Git; export presets and source changes are versioned.

## Developer tools

Debug builds (running from the Godot editor, or `--export-debug`) include a hidden developer page: press F12 on the main menu to complete quests, add gold, unlock everything, max training, unlock levels or reset progress. During a run, F1 gains a level, F2 drops a free chest, F3 adds 100 coins, F4 skips to just before the next guardian and F5 maxes everything owned. Release exports (`--export-release`, as above) leave all of these out.
