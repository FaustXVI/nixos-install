{ nixpkgs ? import <nixpkgs> {} }:

let
  inherit (nixpkgs) callPackage pkgs stdenv;
  install-script = callPackage ./scripts {  };
  tar = builtins.fetchTarball {
               url = https://github.com/FaustXVI/nixos-yubikey-luks/archive/master.tar.gz;
               # Hash obtained using `nix-prefetch-url --unpack <url>`
               sha256 = "1asmhgsh59pmxmi03ry8gjpm37yglrcq54mqwq5jqrda8v6klxln";
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
