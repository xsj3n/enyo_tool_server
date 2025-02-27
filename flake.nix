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
      ghc
      haskell-language-server
      zlib
    ];
    python_tools = with pkgs; [
      python312Full
      python312Packages.pip
      python312Packages.python-lsp-server
      google-chrome
      glib
      nss
      nspr
      xorg.libxcb
    ];
    
    shellHook = ''
      if [ -d "venv/" ]; then
        source venv/bin/activate
      else
        python -m venv venv/
      fi
      export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${pkgs.lib.makeLibraryPath nativeBuildInputs }
    '';
    nativeBuildInputs = haskell_tools ++ python_tools;
    nonFhsSHell = pkgs.mkShell
    {
      inherit  name nativeBuildInputs shellHook;
      LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath nativeBuildInputs;
    };
    fhsShell = pkgs.buildFHSEnv
    {
      inherit name;
      targetPkgs = pkgs: nativeBuildInputs;
      profile = shellHook;
      runScript = "bash";
    };
  in
  {
    devShells."${system}".default = fhsShell.env;
     packages."${system}".default = hpkgs.callCabal2nix "${name}" src { };
  };
}
