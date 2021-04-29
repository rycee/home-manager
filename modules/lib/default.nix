{ lib }:

rec {
  dag = let d = import ./dag.nix { inherit lib; };
  in {
    empty = d.emptyDag;
    isDag = d.isDag;
    topoSort = d.dagTopoSort;
    map = d.dagMap;
    entryAnywhere = d.dagEntryAnywhere;
    entryBetween = d.dagEntryBetween;
    entryAfter = d.dagEntryAfter;
    entryBefore = d.dagEntryBefore;
  };

  gvariant = import ./gvariant.nix { inherit lib; };
  maintainers = import ./maintainers.nix;
  strings = import ./strings.nix { inherit lib; };
  types = import ./types.nix { inherit dag gvariant lib; };

  shell = import ./shell.nix { inherit lib; };
  zsh = import ./zsh.nix { inherit lib; };
}
