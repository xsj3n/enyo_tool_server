{
  description = "Haskell dev shell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    };

  outputs = { self , nixpkgs, ... }:
  let
    name = "enyo-tool-server"; 
    system = "x86_64-linux";
    src = ./.;
    pkgs = import nixpkgs { inherit system; };
    hpkgs = pkgs.haskellPackages;
    haskell_tools = with hpkgs; [
      cabal-install
      haskell-language-server
      zlib
    ];
    python_tools = with pkgs; [
      python312Full
      python312Packages.pip
      python312Packages.python-lsp-server
      firefox
      geckodriver
    ];
    nativeBuildInputs = haskell_tools ++ python_tools;
  in
  {
    devShells."${system}".default = pkgs.mkShell
    {
      
      inherit  name nativeBuildInputs; 
      shellHook = ''
        if [ -d "venv/" ]; then
          source venv/bin/activate
        else
          python -m venv venv/ 
        fi
      '';

      LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath nativeBuildInputs; 
    };
    packages."${system}".default = hpkgs.callCabal2nix "${name}" src { };
  };
}
