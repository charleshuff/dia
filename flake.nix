{
  description = "Dia diagram editor (charleshuff fork; plug-in actions get accel paths)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Python matching whatever pkgs.dia links against, extended with the
        # PyGObject bindings so `import gi` works inside embedded plug-ins.
        pythonWithGi = pkgs.python3.withPackages (ps: [ ps.pygobject3 ]);

        # Typelibs that Dia plug-ins commonly need at runtime.
        # Use each package's `.out` output explicitly — wrapGAppsHook otherwise
        # picks up the `-bin` output for pango/glib, which does *not* ship the
        # typelibs, and `import gi.repository.Pango` then fails at plugin load.
        typelibs = with pkgs; [
          gtk3.out
          glib.out
          gdk-pixbuf.out
          pango.out
          harfbuzz.out
          atk.out
          gobject-introspection   # ships cairo-1.0.typelib
        ];
        typelibPath =
          pkgs.lib.makeSearchPath "lib/girepository-1.0" typelibs;

        dia-patched = pkgs.dia.overrideAttrs (old: {
          pname = "dia";
          version = "charleshuff-${self.shortRev or "dirty"}";

          # Build from the flake's own source tree instead of the pinned tarball.
          src = self;

          # wrapGAppsHook (already in `old.nativeBuildInputs`) picks these up
          # and threads them into the final wrapper, so plug-ins that do
          # `import gi` find PyGObject and the GTK typelibs at runtime.
          preFixup = (old.preFixup or "") + ''
            gappsWrapperArgs+=(
              --prefix PYTHONPATH : "${pythonWithGi}/${pythonWithGi.sitePackages}"
              --prefix GI_TYPELIB_PATH : "${typelibPath}"
            )
          '';
        });
      in
      {
        packages.default = dia-patched;
        packages.dia = dia-patched;

        apps.default = {
          type = "app";
          program = "${dia-patched}/bin/dia";
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = [ dia-patched ];
          packages = [ pythonWithGi ];
        };
      });
}
