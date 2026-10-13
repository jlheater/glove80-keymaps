# Personal layer-diagram PDFs

This fork keeps `main` as a mirror of `sunaku/glove80-keymaps`. The `personal`
branch is the fork's default branch and contains custom assets and generated
personal PDFs. Keep the long-lived branches synchronized with ordinary merges:

```text
upstream  git@github.com:sunaku/glove80-keymaps.git
origin    git@github.com:jlheater/glove80-keymaps.git
```

```sh
git fetch upstream

git switch main
git merge --ff-only upstream/main
git push origin main

git switch personal
git merge main
git push origin personal
```

Do not rebase or force-push `main` or `personal`.

## Custom QWERTY diagram

The personal source and manually captured light screenshot are:

```text
README/personal/base-layer-diagram-QWERTY.json
README/personal/base-layer-diagram-QWERTY.png
```

The checked-in files start as copies of the upstream QWERTY diagram so the
workflow is runnable immediately. Replace them with your own KLE export and
capture after customizing the layout.

The QWERTY JSON, manually captured light PNG, and eight combined PDFs below
are tracked in Git. Generated dark PNGs (`*.dark.png`) and individual page
PDFs (`*.page.pdf`) are ignored build intermediates. Regenerate the combined
PDFs with Rake after diagram changes, then commit them with their sources.

To update the custom diagram:

1. Upload the JSON to [Keyboard Layout Editor](https://www.keyboard-layout-editor.com).
2. Use Firefox's Screenshot node feature on the `#keyboard-bg` element.
3. Save the light screenshot as `README/personal/base-layer-diagram-QWERTY.png`.

The JSON must be saved before the screenshot. Rake reports a missing or stale
PNG and repeats these recapture instructions.

## PDF variants

Every variant has a light and dark PDF. The dark images are generated from the
light screenshots, preserving hue and saturation while applying
`Ldark = 0.92 - 0.84 * Llight` to HSL lightness.

| Variant | Page count | Included layers |
| --- | ---: | --- |
| `all` | 19 | Template, Enthium, Dvorak, Colemak, custom QWERTY, and all 14 functional pages |
| `all_non_alpha` | 15 | Custom QWERTY and all 14 functional pages |
| `core` | 9 | Custom QWERTY, Cursor, Number, Function, Symbol, Mouse, System, Lower, Magic |
| `personalized` | 6 | Custom QWERTY, Cursor, Number, Function, Symbol, Mouse |

The dark `all_non_alpha` variant preserves the existing personal reference
order: QWERTY, Symbol, Number, Cursor, Function, Mouse, System, Repeat, Gaming,
Lower, Magic, Factory, World, Emoji, Typing. Its light variant follows the
upstream functional-layer order used by `all`. The other variants use the
same page order in both themes.

The committed outputs are:

```text
README/personal/all-layer-diagrams.pdf
README/personal/all-layer-diagrams-dark.pdf
README/personal/all-non-alpha-layer-diagrams.pdf
README/personal/all-non-alpha-layer-diagrams-dark.pdf
README/personal/core-layer-diagrams.pdf
README/personal/core-layer-diagrams-dark.pdf
README/personal/personalized-layer-diagrams.pdf
README/personal/personalized-layer-diagrams-dark.pdf
```

## Rake tasks

```sh
rake personal:pdf
rake personal:pdf:light
rake personal:pdf:dark

rake personal:pdf:all
rake personal:pdf:all_non_alpha
rake personal:pdf:core
rake personal:pdf:personalized
```

The first task builds all eight PDFs. Theme tasks build all four variants for
one theme. Variant tasks build both themes for one variant.

The workflow requires Ruby, Rake, GraphicsMagick (`gm`), and Poppler's
`pdfunite`. The repository's `Dockerfile` includes these dependencies, so
`./rake personal:pdf` can be used when Docker is available.

`rake clean` removes generated dark PNGs and individual page PDFs.
`rake clobber` also removes the eight combined personal PDFs. Neither command
removes the custom JSON or manually captured light PNG. Because the combined
PDFs are tracked, run `rake personal:pdf` after `rake clobber` to restore them
before committing.

## After upstream merges

After merging updated `main` into `personal`, run `rake personal:pdf` again.
Upstream functional diagrams are used directly from `README/`, while the
personal QWERTY JSON and light PNG remain isolated under `README/personal/`.
