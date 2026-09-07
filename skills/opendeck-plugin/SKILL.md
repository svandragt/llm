---
name: opendeck-plugin
description: Scaffold and maintain OpenDeck / Stream Deck plugins in Node. Use when the user is building, debugging, or extending an OpenDeck plugin (manifest.json + WebSocket loop + key rendering). Reference for known gotchas around devbox PATH, deb-vs-Flatpak install paths, icon handling, and dependency-shape drift.
---

OpenDeck implements the Elgato Stream Deck WebSocket SDK, so the same plugin layout works for both hosts. Target the **deb-installed OpenDeck** path by default unless the user says otherwise.

## Minimal file layout

```
my.plugin.sdPlugin/
├── manifest.json          # declares Actions; CodePath: run.sh
├── run.sh                 # entrypoint the host spawns
├── plugin.js              # WebSocket loop; one setInterval tick
├── render.js              # pure fn → data:image/svg+xml;base64,...
├── icon.png, icon@2x.png  # generated; extensionless paths in manifest
├── actions/<id>.png, @2x.png
├── package.json
├── devbox.json            # pins node version
└── Makefile               # deps / install / reinstall / restart / logs
```

## Gotchas (learned the hard way)

1. **devbox PATH** — OpenDeck spawns plugins with a minimal PATH that doesn't include the user's devbox-managed `node`. Always indirect through `run.sh`:
   ```sh
   #!/usr/bin/env bash
   cd "$(dirname "$0")"
   if command -v devbox >/dev/null 2>&1; then
     exec devbox run -- node plugin.js "$@"
   else
     exec node plugin.js "$@"
   fi
   ```
   Set `CodePath: "run.sh"` in manifest (and `CodePathWin: "plugin.js"` for the Windows path that doesn't need the wrapper).

2. **Install path is `~/.config/opendeck/plugins/`** for deb installs. Do NOT use `flatpak override` logic unless the user explicitly runs the Flatpak build.

3. **Icon paths in manifest.json are extensionless** — the host appends `.png` / `@2x.png`. Generate PNGs from an SVG via ImageMagick `convert` in a `make icons` target; never hand-edit PNGs.

4. **Logs land in two places after install:** `plugin.log` next to the *installed* copy, and OpenDeck's own logs at `~/.config/opendeck/logs/`. The dev-tree `plugin.log` only appears when running in place.

5. **WS contract:** the host passes four CLI args: `-port -pluginUUID -registerEvent -info`. After connecting to `ws://127.0.0.1:<port>`, send `{event: registerEvent, uuid: pluginUUID}` to identify. Track contexts in a `Set<string>` updated on `willAppear` / `willDisappear`; broadcast `setImage` with `target: 0` and a `data:` URI.

6. **Pin third-party CLIs you shell out to** (e.g. ccusage) as devDependencies, and run them via `npx -y <name>@<version>` so there's no per-run network fetch. Dependabot bumps them in one place.

7. **JSON-shape drift is the real risk on dependency bumps.** A grep-for-CLI-flag test will pass while both metrics return 0. Add an **integration test** that builds a synthetic input fixture in a tmp HOME and asserts the parsed numbers are non-zero. CI must run it.

8. **No tunable magic constants** if the user has rejected them before — derive thresholds from history / observed data. (Project-specific: check the project's CLAUDE.md.)

9. **No undocumented APIs.** If the user's project says use ccusage / a sanctioned source, don't reach for OAuth tokens or rate-limit headers as a shortcut. See the user's global memory.

## Plugin skeleton (plugin.js)

```js
const WebSocket = require('ws');
const fs = require('fs');
const path = require('path');
const { renderGauge } = require('./render');
const { getUsage } = require('./usage'); // or whatever data source

const log = (...a) => fs.appendFileSync(
  path.join(__dirname, 'plugin.log'),
  `[${new Date().toISOString()}] ${a.join(' ')}\n`
);

const args = require('minimist')(process.argv.slice(2));
const ws = new WebSocket(`ws://127.0.0.1:${args.port}`);
const contexts = new Set();

ws.on('open', () => {
  ws.send(JSON.stringify({ event: args.registerEvent, uuid: args.pluginUUID }));
  setInterval(tick, 60_000);
  tick();
});

ws.on('message', (raw) => {
  const msg = JSON.parse(raw);
  if (msg.event === 'willAppear') contexts.add(msg.context);
  if (msg.event === 'willDisappear') contexts.delete(msg.context);
  if (msg.event === 'keyDown') tick();
});

async function tick() {
  const data = await getUsage();
  const image = renderGauge(data);
  for (const context of contexts) {
    ws.send(JSON.stringify({ event: 'setImage', context, payload: { image, target: 0 } }));
  }
}
```

## When asked to add another Action to an existing plugin

Prefer adding an `Action` entry in `manifest.json` and a second render/data module, **sharing** the WS loop in `plugin.js`. Only extract a shared lib once there are 2+ unrelated plugins.

## Makefile targets to provide

`deps`, `test`, `icons`, `install`, `uninstall`, `reinstall`, `restart`, `logs`. `make test` should run the unit + integration tests; `make logs` is `tail -f` on the installed plugin.log.
