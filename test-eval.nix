let
  inputs = builtins.getFlake (toString ./.);
  eval = inputs.systemConfigs.linux-generic;
in
  eval.config.environment.systemPackages
