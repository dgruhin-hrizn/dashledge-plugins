# Dashledge plugins

The registry behind the Dashledge Marketplace. Every plugin listed here was checked by CI and reviewed by a maintainer before it reached anyone's dashboard.

- **Using Dashledge?** Open **Settings → Marketplace** to browse and install plugins. You don't need anything in this repository.
- **Building a plugin?** Read [Build widgets for Dashledge](https://github.com/dgruhin-hrizn/dashledge/blob/main/widgets/README.md), then [submit it here](CONTRIBUTING.md).

## How it works

```
author's release ──► listing PR ──► checks + review ──► merge ──► signed catalog on Pages ──► Dashledge
```

1. An author attaches the plugin's ZIP to a release in their own repository and opens a pull request adding `listings/<id>/<version>.json`. Dashledge's Widget Studio prepares both.
2. `Check submission` validates it with the same Rust code the app runs, then lists what the plugin may do. A maintainer reviews it.
3. On merge, `Publish catalog` downloads new versions, builds `v1/catalog.json` and signs it with a key only this repository's CI holds. It then publishes the catalog, packages, icons and screenshots to GitHub Pages.
4. Dashledge accepts the catalog only if its pinned public key verifies the signature. It refuses a catalog older than one it has seen, and checks every download's sha256 before installing.

The catalog expires after 30 days and is re-signed weekly. A pulled version (`revoked.json`) is turned off on every Mac at its next check.

## Layout

| Path | What it is |
| --- | --- |
| `listings/<id>/<version>.json` | One reviewed version. Published versions never change. |
| `listings/<id>/*.png` | Screenshots a listing names. |
| `revoked.json` | Pulled versions, with the reason people see. |
| `MAINTAINERS` | GitHub logins that review and may publish under `plugin.dashledge.`, Dashledge's first-party plugins from [dashledge-official-plugins](https://github.com/dgruhin-hrizn/dashledge-official-plugins). |
| `scripts/check-pr.sh`, `scripts/publish.sh` | What the two workflows run. |

The checker, `dashledge-package`, lives in the Dashledge repository at `src-tauri/package-core`. Both workflows build it from the branch or commit named in `DASHLEDGE_REF`. Every pull request check also runs the full catalog build that publishing runs, so a merged change can't break publishing.
