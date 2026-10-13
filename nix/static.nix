{
  haskell,
  haskellPackages,
  lib,
  upx,
  ...
}: let
  hlib = haskell.lib.compose;
  hspkgs = haskellPackages.override {
    overrides =
      lib.composeExtensions
      (import ./haskell-overlay.nix {inherit hlib;})
      (hself: _: {
        cabal-install-solver = hself.callHackageDirect {
          pkg = "cabal-install-solver";
          ver = "3.16.1.0";
          sha256 = "sha256-BjRXWha4kiedo/Fi3qr2LXixvuQvXD62XJ4pLZ6yq3c=";
        } {};
        cabal-install =
          hself.callHackageDirect {
            pkg = "cabal-install";
            ver = "3.16.1.0";
            sha256 = "sha256-6ssSeM1oeXVCLR5/HPxYEUkcEWU8XxlqZiBl1JHbMbw=";
          } {
            Cabal-QuickCheck = null;
            Cabal-described = null;
            Cabal-tree-diff = null;
            Cabal-tests = null;
          };
      });
  };
in
  (hlib.justStaticExecutables hspkgs.cabal-audit).overrideAttrs (old: {
    postPhases = ["compressionPhase"];
    nativeBuildInputs = old.nativeBuildInputs ++ [upx];
    compressionPhase = ''
      echo "this might take a while.."
      upx --best $out/bin/cabal-audit
    '';
  })
