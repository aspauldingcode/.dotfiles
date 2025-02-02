#!/bin/sh

sudo dscl . delete /Users/alex jpegphoto
sudo dscl . delete /Users/alex Picture
sudo dscl . create /Users/alex Picture "/Users/alex/.dotfiles/users/alex/face.heic"

exit 0
