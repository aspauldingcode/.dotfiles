{ ... }:

#Sudoer's file to symlink
{
  environment.etc."sudoers.d/admin-no-passwd".text = ''
  %admin ALL = (ALL) NOPASSWD: ALL
  '';
}
