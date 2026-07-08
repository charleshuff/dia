# Dia (charleshuff fork)

This repository is a personal fork of [Dia](https://gitlab.gnome.org/GNOME/dia),
the GNOME diagram editor. It was created to add keyboard-shortcut support for
plug-in-registered actions so I can drive UML / flowchart shape insertion
entirely from the keyboard.

Upstream: https://gitlab.gnome.org/GNOME/dia

## What this fork changes

Two commits on top of upstream `master`:

1. **`menus: give plug-in actions an accel path`** — `app/menus.c`

   Built-in Dia actions get an accelerator path automatically (via
   `gtk_action_group_add_actions`), which is what makes `~/.dia/menurc`
   entries able to bind keys to them. Plug-in-registered actions were added
   via the plain `gtk_action_group_add_action`, which does *not* set an accel
   path — so `menurc` entries pointing at plug-in actions had nothing to
   bind to and were silently ignored.

   This patch assigns each plug-in action a stable accel path of the form
   `<Actions>/<group-name>/<action-name>`, so keyboard shortcuts written
   in `menurc` (e.g. `(gtk_accel_path "<Actions>/plugin-actions-0/MyAction" "<Primary>j")`)
   actually resolve.

2. **`nix: flake for reproducible builds with PyGObject in embedded Python`**
   — new `flake.nix` / `flake.lock`

   Adds a Nix flake that builds Dia from the current tree and wraps the
   resulting binary so its embedded Python 3 can `import gi`. Nixpkgs' stock
   `dia` derivation doesn't include PyGObject, which makes any plug-in that
   uses GTK dialogs (including several stock ones like `gtkcons.py`,
   `dia_rotate.py`, `scascale.py`, `select_by.py`) fail at load with
   `No module named 'gi'`. The flake fixes this by prefixing `PYTHONPATH`
   with a Python environment containing `pygobject3` and `GI_TYPELIB_PATH`
   with the `.out` outputs of GTK, GLib, Pango, GdkPixbuf, HarfBuzz, ATK,
   and `gobject-introspection` (which ships `cairo-1.0.typelib`).

   Usage: `nix run github:charleshuff/dia` or add this repo as an input in
   your own flake and consume `packages.${system}.dia`.

## Use of generative AI

Every change in this fork was produced with
[Claude Code](https://claude.com/claude-code) (Claude Opus 4.7 model) in an
interactive session. The upstream project's README asks contributors not to
submit LLM-generated work, so nothing here is intended to be sent back
upstream — this fork exists purely to run a patched Dia on my own machines.

## Everything else

For anything not covered above, defer to the upstream README, HACKING.md,
BUILDING.md, and documentation in the `doc/` directory.
