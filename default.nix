{ nixpkgs ? import <nixpkgs> {} }:

let
  inherit (nixpkgs) callPackage pkgs stdenv;
  install-script = callPackage ./scripts {  };
  tar = builtins.fetchTarball {
               url = https://github.com/FaustXVI/nixos-yubikey-luks/archive/master.tar.gz;
               # Hash obtained using `nix-prefetch-url --unpack <url>`
               sha256 = "13lvwv8azbvak8ag256yf5rjamfq0rkh5f48mjcln7s99fsnlzja";
             };
  my = import tar { inherit nixpkgs; };
in
  stdenv.mkDerivation {
    name = "nixos-setup";
    buildInputs = with pkgs; [
      git
      install-script
    ] ++ my.buildInputs;
    
  }
