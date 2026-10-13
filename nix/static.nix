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
      (hself: hsuper: {
        # Cabal-3.16 pulls in semaphore-compat-1.0.0, which needs
        # unix >= 2.8.1 (semWaitInterruptible); the static GHC 9.4
        # toolchain ships unix-2.7.3, and boot libs can't be overridden
        # from the package set. semThreadWait is the same call minus the
        # interruptible FFI marker - irrelevant for a one-shot CLI.
        os-string = hself.callHackageDirect {
          pkg = "os-string";
          ver = "2.0.7";
          sha256 = "sha256-u7ImqUt/HZlo61gwMXlB+CS3K19D+QCvzHQpqjsPCrY=";
        } {};
        filepath = hself.callHackageDirect {
          pkg = "filepath";
          ver = "1.4.100.1";
          sha256 = "sha256-bYPdD8f7vgcrgpXLF6b/P+o135KXqZW792XUeflmc2E=";
        } {};
        semaphore-compat =
          hlib.overrideCabal (old: {
            preConfigure =
              (old.preConfigure or "")
              + ''
                sed -i 's/semWaitInterruptible/semThreadWait/g' src/System/Semaphore.hs
                # unix-2.7's semThreadWait :: IO (); only the IO Bool site gets wrapped.
                # file has CRLF endings; no $ anchors, indent distinguishes the sites.
                sed -i 's/^\(          Posix\.semThreadWait sem\)/\1 >> pure True/' src/System/Semaphore.hs
                sed -i 's/>= 2.8.1.0 && < 2.9/>= 2.7.1.0/' *.cabal
              '';
          })
          hsuper.semaphore-compat;
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
