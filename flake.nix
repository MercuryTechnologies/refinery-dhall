{
  description = "Honeycomb Refinery rules configuration in Dhall";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    dhall = {
      url = "github:lf-/dhall-haskell/toml-integers";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, dhall }:
    let
      ghcVer = "ghc902";
      makeHaskellOverlay = overlay: final: prev: {
        haskell = prev.haskell // {
          packages = prev.haskell.packages // {
            ${ghcVer} = prev.haskell.packages."${ghcVer}".override (oldArgs: {
              overrides =
                prev.lib.composeExtensions (oldArgs.overrides or (_: _: { }))
                  (overlay prev final);
            });
          };
        };
      };
      out = system:
        let
          pkgsDefault = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.dhall-fixes self.overlays.default ];
          };
        in
        {
          packages = rec {
            refinery-dhall = pkgsDefault.refinery-dhall;
            default = refinery-dhall;
          };
          inherit pkgs;

          devShells.default = pkgs.mkShell {
            buildInputs =
              let
                hlib = pkgs.haskell.lib;
                haskellPackages = pkgs.haskell.packages.${ghcVer};
              in
              [
                pkgs.dhall-lsp-server
                (hlib.justStaticExecutables haskellPackages.dhall)
                (hlib.justStaticExecutables haskellPackages.dhall-yaml)
                (hlib.justStaticExecutables haskellPackages.dhall-toml)
              ];
          };

        };
    in
    flake-utils.lib.eachDefaultSystem out // {
      overlays.default = prev: final: {
        refinery-dhall = final.dhallPackages.buildDhallDirectoryPackage {
          name = "refinery-dhall";
          src = ./.;
          dependencies = [
            final.dhallPackages.Prelude
          ];
          source = true;
          document = true;
        };
      };
      overlays.dhall-fixes = makeHaskellOverlay (prev: final: hfinal: hprev:
        let
          hlib = prev.haskell.lib;
        in
        {
          dhall = hlib.overrideSrc hprev.dhall { src = (dhall + "/dhall"); };
          dhall-toml = hlib.overrideSrc hprev.dhall-toml { src = (dhall + "/dhall-toml"); };
          dhall-yaml = hlib.overrideSrc hprev.dhall-yaml { src = (dhall + "/dhall-yaml"); };
          dhall-json = hlib.overrideSrc hprev.dhall-json { src = (dhall + "/dhall-json"); };
        });
    };

}
