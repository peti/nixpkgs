{ pkgs, haskellLib }:

let
  inherit (pkgs) lib;
in

with haskellLib;

# cabal2nix doesn't properly add dependencies conditional on arch(javascript)

(self: super: {
  ghcjs-base = addBuildDepends (with self; [
    aeson
    attoparsec
    dlist
    hashable
    primitive
    scientific
    unordered-containers
    vector
  ]) super.ghcjs-base;

  ghcjs-dom = addBuildDepend self.ghcjs-dom-javascript super.ghcjs-dom;
  ghcjs-dom-javascript = addBuildDepend self.ghcjs-base super.ghcjs-dom-javascript;
  jsaddle = addBuildDepend self.ghcjs-base super.jsaddle;
  jsaddle-dom = addBuildDepend self.ghcjs-base super.jsaddle-dom;

  entropy = addBuildDepend self.ghcjs-dom super.entropy;

  # https://gitlab.haskell.org/ghc/ghc/-/issues/25083#note_578275
  patch = haskellLib.disableParallelBuilding super.patch;
  reflex-dom-core = haskellLib.disableParallelBuilding super.reflex-dom-core;

  reflex-dom =
    lib.warn "reflex-dom builds with JS backend but it is missing fixes for working at runtime"
      super.reflex-dom.override
      (drv: {
        jsaddle-webkit2gtk = null;
      });
})
