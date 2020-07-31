{ callPackage, pkgs }:
{
  #### CORE EFL
  efl = callPackage ./efl { };

  #### WINDOW MANAGER
  enlightenment = callPackage ./enlightenment { };

  #### APPLICATIONS
  econnman = callPackage ./econnman { };
  terminology = callPackage ./terminology.nix { };
  rage = callPackage ./rage.nix { };
  ephoto = callPackage ./ephoto.nix { };
}
