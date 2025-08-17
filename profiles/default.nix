# Profiles Index - Reusable configuration profiles
{ inputs, ... }:
{
  flake.profiles = {
    # Desktop profile - GUI applications, window managers, etc.
    desktop = ./desktop;

    # Server profile - headless, minimal, server-focused
    server = ./server;

    # Mobile profile - power management, mobile-specific optimizations
    mobile = ./mobile;

    # Development profile - development tools, IDEs, etc.
    development = ./development;
  };
}
