{ ... }:

#Sudoer's file to symlink. removes the need for a password for the admin group
{
  environment.etc."sudoers.d/admin-no-passwd".text = ''
  %admin ALL = (ALL) NOPASSWD: ALL
  '';
}
