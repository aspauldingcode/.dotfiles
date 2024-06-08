#!/bin/bash

# Source the yabai_labeler.sh script from ~/.dotfiles
source ~/.dotfiles/CUSTOM_yabai_scripts/yabai_labeler.sh

# echo -e "\nSpaces Information:"
# read_all_spaces

# echo -e "\nDisplay Information with Spaces Information:"
# read_spaces_on_display_n_for_all_displays 

# echo -e "\nMissing Spaces:"
# missing_label_spaces

echo -e "\nGenerating Unique Labels:"
generate_unique_labels

# echo -e "\nSpaces Information:"
# read_all_spaces

# echo -e "\nDisplay Information with Spaces Information:"
# read_spaces_on_display_n_for_all_displays 

# echo -e "\nPrint Space Labels Active on a Display and/or Containing a Window:"
# print_space_labels

echo -e "\nRemoving Unnecessary Spaces:"
remove_unimportant_spaces

echo -e "\nReorder Display Labels Accordingly:"
reorder_displays "--auto" # save the pain and agony of display ordering

echo -e "\nDisplay Information with Spaces Information:"
read_spaces_on_display_n_for_all_displays 
