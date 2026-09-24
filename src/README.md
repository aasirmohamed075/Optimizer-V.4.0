# Optimizer V.4.0 — Android Performance Suite

An Android-targeted optimizer dashboard: **live FPS HUD, hardware profiles, shield/zero-lag
engine controls, aim & sensitivity lab, touch-polling lab, memory + battery tools, ping/DNS
optimizer, WebGL2 shader tuner, benchmark studio and a game launcher**.

Read `SPEC.md` for the original user specification and exactly how each request is implemented.

```
main.pjs            $meta + editable app config (name, version, developer, WhatsApp, theme)
index.html          the whole UI shell: top bar, horizontal category tabs, 10 views, console dock
src/config.js       defaults, presets, labels, DNS list, region nodes, games, weapons, GFX presets
src/ui.js           state store + logger + toasts/modals + tab routing + control binding + grids
src/canvas.js       canvas fitting helpers (device-pixel-ratio aware, refit on resize/orientation)
src/engine.js       the render engine: frame limiter, pacing, shield scheduler, metrics
src/device.js       hardware detection (model, OS, cores, RAM class, panel Hz, GPU renderer)
src/monitors.js     FPS pill/HUD overlay, engine badge, live metrics, Chart.js telemetry graph
src/aim.js          drag-headshot simulator (recoil/spread/hit-registration/lag model)
src/touch.js        touch calibration canvas, real panel report-rate + velocity measurement
src/memory.js       RAM gauge, reclaimable buffer pool, real cache purge, battery + thermal
src/net.js          ping monitor, DoH resolver benchmark, regional latency table
src/gfx.js          WebGL2 scene + bloom + colour-grading pipeline (the shader tuner)
src/bench.js        CPU 1T/NT, GPU fill-rate, RAM bandwidth, storage I/O benchmark
src/launch.js       game launcher: direct `intent://` handoff to the top-level page, launch-tab retry, fallback handshake, 5s "not found" notice
src/main.js         boot: wires every module, About/developer/permissions/restore
src/caps.js         per-device capability layer: every setting resolved to NATIVE/REAL/LIMITED/MODEL
src/native.js       Android shell adapter: bridge calls, /proc metrics, exact game detection, purge
src/style.css       the entire visual design (dark + light themes, responsive down to 360px)
src/android/        the native Android shell - complete Kotlin + NDK project (see its README)
```

## Two shells, one codebase

The same web layer runs as a browser page **and** inside the Android shell in `src/android/`.
`src/caps.js` + `src/native.js` detect which shell they are in (`window.OptimizerNative`, plus a
`OptimizerV4` user-agent marker) and route every setting accordingly:

* **Browser** — real Web APIs where they exist (WebGL2, Screen Wake Lock, `getCoalescedEvents`,
  `navigator.getBattery`, `storage.estimate`, `deviceMemory`, `hardwareConcurrency`, fullscreen).
* **Android shell** — the same switches drive `Window.setFrameRate`, `GameManager` game mode,
  `PerformanceHintManager` hint sessions, `requestUnbufferedDispatch`, `getCurrentThermalStatus`,
  the battery-optimisation exemption, `PackageManager` game detection and the NDK `/proc` + `/sys`
  readers. CPU load, SoC temperature and RAM then come from the kernel, and the monitor labels
  change from `CPU engine` / `Thermal est.` to `CPU device` / `SoC temp`.

Nothing is claimed that the current device cannot do: open the **Hardware** tab → *Device
Compatibility & Every-Setting Audit* (or tap a badge on any card) and every switch is listed with
its real status for the phone in your hand — `NATIVE`, `REAL`, `LIMITED` or `MODEL` — and the API
behind it. See `SPEC.md` §12.

## How it is put together

* **One state store** (`src/ui.js`): every control is `data-key="module.thing"` in `index.html`;
  `bindControls()` wires switches/sliders/selects generically, `set()` notifies subscribers and
  writes an entry to the execution log. Modules subscribe with `on("module.thing", fn)`, so a tap
  on any switch takes effect *immediately* and is logged with its real consequence.
* **One frame engine** (`src/engine.js`): a single `requestAnimationFrame` loop owns the frame
  limiter, the pacing scheduler, the shield frame-budget and all metrics. Modules register
  renderers (`engine.addRenderer`) instead of starting their own loops.
* **Defaults are memory-only.** Nothing is persisted, so reloading or closing the app restores
  every parameter — plus the About tab has an explicit *Restore All Settings To Default*.
* **Measured, not faked.** FPS/frame time/jitter come from the real loop; panel refresh rate and
  touch report rate are measured; ping, resolver and storage numbers are real requests; the
  memory gauge reads the real JS heap and the purge releases a real buffer pool; the benchmark
  times real CPU/GPU/RAM/IndexedDB work.
* **One exception, and it is labelled in the UI**: no non-root app can touch another app's
  governor, GPU clocks, thermal limits or game memory. Those switches drive *this app's* engine
  and its ballistics lab. See `SPEC.md` → "Honest limits".

## Running it

It is a Perchance generator: the shipped page is `https://perchance.org/<generator-name>`.
The same files run natively in a WebView — see `src/android/README.md` for the APK build.
