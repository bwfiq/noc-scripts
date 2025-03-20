{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

{
  languages.python = {
    enable = true;
    venv.enable = true;
    venv.requirements = ''
      jira[cli]
    '';
  };
}
