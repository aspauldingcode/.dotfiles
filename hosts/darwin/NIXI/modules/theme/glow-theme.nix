{config, ...}: {
  system.defaults.CustomSystemPreferences."/Library/GlowThemes/${config.colorScheme.slug}-${config.colorScheme.variant}/settings.plist" = {
    gColors = {
      "AbsoluteLightBezelImage_Active_DeeplyPressed_Off_Base0" = "#${config.colorScheme.palette.base00}FF";
      "AbsoluteLightBezelImage_Active_DeeplyPressed_On_Base0" = "#${config.colorScheme.palette.base00}FF";
      "AbsoluteLightBezelImage_Active_Disabled_Off_Base0" = "#${config.colorScheme.palette.base00}FF";
      "AbsoluteLightBezelImage_Active_Disabled_On_Base0" = "#${config.colorScheme.palette.base00}FF";
      "AbsoluteLightBezelImage_Active_Normal_Off_Base0" = "#${config.colorScheme.palette.base00}FF";
      "AbsoluteLightBezelImage_Active_Normal_On_Base0" = "#${config.colorScheme.palette.base00}FF";
      "AbsoluteLightBezelImage_Active_Pressed_Off_Base0" = "#${config.colorScheme.palette.base00}FF";
      "AbsoluteLightBezelImage_Active_Pressed_On_Base0" = "#${config.colorScheme.palette.base00}FF";
      "AbsoluteLightBezelImage_Active_Rollover_Off_Base0" = "#${config.colorScheme.palette.base00}FF";
      "AbsoluteLightBezelImage_Active_Rollover_On_Base0" = "#${config.colorScheme.palette.base00}FF";
      "AbsoluteLightBezelImage_Inactive_DeeplyPressed_Off_Base0" = "#${config.colorScheme.palette.base00}FF";
      "AbsoluteLightBezelImage_Inactive_DeeplyPressed_On_Base0" = "#${config.colorScheme.palette.base00}FF";
      "AbsoluteLightBezelImage_Inactive_Disabled_Off_Base0" = "#${config.colorScheme.palette.base00}FF";
      "AbsoluteLightBezelImage_Inactive_Disabled_On_Base0" = "#${config.colorScheme.palette.base00}FF";
      "AbsoluteLightBezelImage_Inactive_Normal_Off_Base0" = "#${config.colorScheme.palette.base00}FF";
      "AbsoluteLightBezelImage_Inactive_Normal_On_Base0" = "#${config.colorScheme.palette.base00}FF";
      "AbsoluteLightBezelImage_Inactive_Pressed_Off_Base0" = "#${config.colorScheme.palette.base00}FF";
      "AbsoluteLightBezelImage_Inactive_Pressed_On_Base0" = "#${config.colorScheme.palette.base00}FF";
      "AbsoluteLightBezelImage_Inactive_Rollover_Off_Base0" = "#${config.colorScheme.palette.base00}FF";
      "AbsoluteLightBezelImage_Inactive_Rollover_On_Base0" = "#${config.colorScheme.palette.base00}FF";
      CUIWindowRimColor = "#${config.colorScheme.palette.base00}59";
      CUIWindowRimColor2x = "#${config.colorScheme.palette.base00}99";
    };
  };
}