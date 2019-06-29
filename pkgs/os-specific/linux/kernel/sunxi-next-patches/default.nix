let
  ents = builtins.readDir ./.;
in builtins.filter (x: x != null) (map (name: let
  match = builtins.match "(.*)\\.patch" name;
in if match == null then null else {
  name = "sunxi-next-${name}";
  patch = ./. + "/${name}";
}) (builtins.attrNames ents))
