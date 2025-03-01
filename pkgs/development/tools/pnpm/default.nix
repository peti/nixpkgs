{
  lib,
  callPackage,
}:

let
  inherit (lib) mapAttrs' nameValuePair;

  variants = {
    "8" = {
      version = "8.15.9";
      hash = "sha256-2qJ6C1QbxjUyP/lsLe2ZVGf/n+bWn/ZwIVWKqa2dzDY=";
    };
    "9" = {
      version = "9.15.5";
      hash = "sha256-hHIWjD4f0L/yh+aUsFP8y78gV5o/+VJrYzO+q432Wo0=";
    };
    "10" = {
      version = "10.4.0";
      hash = "sha256-5X6KVE96hCR8+nfdbZI+rlGZo3NHTlPqsfVAx5Yok4Y=";
    };
  };

  callPnpm = variant: callPackage ./generic.nix { inherit (variant) version hash; };

  mkPnpm = versionSuffix: variant: nameValuePair "pnpm_${versionSuffix}" (callPnpm variant);
in
mapAttrs' mkPnpm variants
