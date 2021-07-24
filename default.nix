{ nixpkgs ? import <nixpkgs> {} }:

let
  inherit (nixpkgs) callPackage pkgs stdenv;
  install-script = callPackage ./scripts {  };
  tar = builtins.fetchTarball {
               url = https://github.com/FaustXVI/nixos-yubikey-luks/archive/master.tar.gz;
               # Hash obtained using `nix-prefetch-url --unpack <url>`
               sha256 = "190xx0kzmv75kcxpn60n3xv6qhvzspmdm72v8qp83cs6rjj6qgl2";
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
