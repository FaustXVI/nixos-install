{ nixpkgs ? import <nixpkgs> {} }:

let
  inherit (nixpkgs) callPackage pkgs stdenv;
  install-script = callPackage ./scripts {  };
 tar = builtins.fetchTarball {
               url = https://github.com/FaustXVI/nixos-yubikey-luks/archive/master.tar.gz;
               # Hash obtained using `nix-prefetch-url --unpack <url>`
               sha256 = "0d8gpvljfica6nb4i2ksr57c8swvkk5s38lrliglrhz20as4xfsq";
             };
 my = import tar { };
in
  stdenv.mkDerivation {
    name = "nixos-setup";
    buildInputs = with pkgs; [
      git
      install-script
    ] ++ my.buildInputs;
    
  }
