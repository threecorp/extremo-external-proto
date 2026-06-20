{
  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*.tar.gz";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      flake-utils,
      nixpkgs,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        go = pkgs.go_1_25;

        formatter = pkgs.nixfmt-tree;
      in
      {
        devShells = {
          ci = pkgs.mkShellNoCC {
            packages = [
              go
              pkgs.buf
              pkgs.protobuf
              pkgs.tree
              formatter
            ];

            shellHook = ''
              export GOPATH=''${GOPATH:-$HOME/go}
              export PATH=$GOPATH/bin:$PATH
            '';
          };
          default = pkgs.mkShellNoCC {
            inputsFrom = [ (pkgs.mkShellNoCC { }) ];
            packages = [
              go
              pkgs.buf
              pkgs.protobuf
              pkgs.tree
              pkgs.nil
              formatter
            ];

            shellHook = ''
              export GOPATH=''${GOPATH:-$HOME/go}
              export PATH=$GOPATH/bin:$PATH
            '';
          };
        };

        inherit formatter;
      }
    );
}
