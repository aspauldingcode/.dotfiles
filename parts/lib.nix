# Library Functions Module - Expose helper functions through flake-parts
{ inputs, ... }:
{
  flake.lib = import ../lib { inherit inputs; };
}
