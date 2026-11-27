# Submitting a plugin

Anyone can publish a Dashledge plugin here. A maintainer reviews every version before it reaches the Marketplace.

## Before you submit

- Build and test your plugin with the guide in the Dashledge repository: [Build widgets for Dashledge](https://github.com/dgruhin-hrizn/dashledge/blob/main/widgets/README.md).
- Give it an ID in your namespace, `plugin.<your GitHub login>.<name>`, in lowercase. For example, `plugin.alice.radarr-queue`.
- Give it a `version` such as `1.0.0`. Every version you publish gets a new number. A published version never changes.
- Keep its source in a public GitHub repository.

## Submit from Dashledge

1. In **Settings → Widget Studio**, load your package folder with **Load unpacked package** and open it.
2. Choose **Submit to Marketplace…**. Dashledge checks the package with the same rules this registry uses, saves a ZIP, and shows the listing file it will propose.
3. Publish a release in your repository tagged `v<version>`, with that ZIP attached.
4. Choose **Open GitHub**. GitHub opens a new file, `listings/<id>/<version>.json`, with the listing filled in. Commit it to a new branch and open the pull request.

## Submit by hand

Add one file per version, `listings/<id>/<version>.json`:

```json
{
  "id": "plugin.alice.radarr-queue",
  "version": "1.0.0",
  "publisher": "alice",
  "source": {"repo": "alice/radarr-queue", "tag": "v1.0.0", "asset": "radarr-queue-1.0.0.zip"},
  "sha256": "<sha256 of the ZIP, lowercase hex>",
  "summary": "Movies downloading now, with posters.",
  "screenshots": ["queue.png"],
  "notes": "First release."
}
```

- `publisher` is your GitHub login, and it must match the account that opens the pull request.
- `source` names a release asset. The registry downloads it, checks `sha256`, and keeps its own copy, so changing the asset later changes nothing.
- `summary` (up to 140 characters) and `notes` (up to 1,000) are optional. Without a summary, the Marketplace shows your manifest's `description`.
- `screenshots` (optional, up to 4) are PNG or JPEG files up to 1 MiB each, committed next to the listing in `listings/<id>/`. Show the widget at the Edge's full size, 2560 × 720, and in a compact tile.

You can run the same check locally with `dashledge-package`, built from the Dashledge repository:

```sh
cargo run --manifest-path src-tauri/package-core/Cargo.toml --bin dashledge-package -- check-listing listings/<id>/<version>.json path/to/package.zip
```

## What happens next

1. **Checks.** The pull request runs `Check submission`. It downloads your ZIP, verifies its sha256, validates the package and lists everything it may do: connections, sign-in form, hosts, image routes, streams, commands and capabilities.
2. **Review.** A maintainer reads the checks' summary and your code, then approves or asks for changes.
3. **Publish.** Merging runs `Publish catalog`. Within a few minutes, the new version appears in every Dashledge Marketplace.
   - People who already use your plugin get the update on their own, unless it asks for something new. Then they approve it first, with each new grant marked.

## Dashledge's own plugins

IDs under `plugin.dashledge.` are first-party. The Marketplace shows them **by Dashledge** with a Dashledge badge. Only maintainers in `MAINTAINERS` can list them, and CI refuses anyone else.
- **Source:** a first-party listing's `source.repo` is [dgruhin-hrizn/dashledge-official-plugins](https://github.com/dgruhin-hrizn/dashledge-official-plugins), and its asset comes from a release that repository's workflow made. The one exception is `plugin.dashledge.weather-example` 1.0.0, released here before that repository existed.
- **The spec:** that repository's CI enforces the first-party spec in its `AGENTS.md`. Review a first-party listing against the checklist below as well.
- **Listing a release:** the release notes hold the listing JSON. Add it as `listings/<id>/<version>.json`.

## Review checklist

Maintainers check each version against this list.

- [ ] The ID is in the author's namespace and the listing's publisher is the PR's author.
- [ ] The checks passed, and the sha256 matches the release asset.
- [ ] Every connector host is needed for what the plugin says it does. **A plugin that reads the user's server and also declares an outside host can send that data away; read its connector closely.**
- [ ] The sign-in form, image routes and streams stay on the user's own connection.
- [ ] The connector code is readable: not minified or obfuscated, and it doesn't fetch code at run time.
- [ ] The view follows Dashledge's widget design principles: touch targets of at least 44 × 44 CSS pixels, legible type, and loading, empty and failed states.
- [ ] It works at the Edge's full size, 2560 × 720, and in a compact tile, with long real-world labels.
- [ ] For an update, the new grants match what the release notes say.
- [ ] For a `plugin.dashledge.` ID: the publisher is a maintainer and `source.repo` is `dgruhin-hrizn/dashledge-official-plugins`.

## Pulling a version

When a published version is harmful or broken, a maintainer adds it to `revoked.json` with a reason:

```json
[{"id": "plugin.alice.radarr-queue", "version": "1.0.0", "reason": "Sends the API key to an outside host."}]
```

Dashledge turns that version off on the next daily check and shows the reason on the widget. A newer version that fixes the problem turns it back on.
