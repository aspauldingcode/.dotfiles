{
  config,
  pkgs,
  ...
}:
let
  base16Settings = {
    "$schema" = "vscode://schemas/color-theme";
    name = "Base16 ${config.colorScheme.slug}";
    type = "${config.colorScheme.variant}";
    colors = {
      foreground = "#${config.colorScheme.palette.base05}";
      disabledForeground = "#${config.colorScheme.palette.base04}";
      "widget.shadow" = "#${config.colorScheme.palette.base00}";
      "selection.background" = "#${config.colorScheme.palette.base0D}";
      descriptionForeground = "#${config.colorScheme.palette.base03}";
      errorForeground = "#${config.colorScheme.palette.base08}";
      "icon.foreground" = "#${config.colorScheme.palette.base04}";
      "textBlockQuote.background" = "#${config.colorScheme.palette.base01}";
      "textBlockQuote.border" = "#${config.colorScheme.palette.base0D}";
      "textCodeBlock.background" = "#${config.colorScheme.palette.base00}";
      "textLink.activeForeground" = "#${config.colorScheme.palette.base0C}";
      "textLink.foreground" = "#${config.colorScheme.palette.base0D}";
      "textPreformat.foreground" = "#${config.colorScheme.palette.base0D}";
      "textSeparator.foreground" = "#${config.colorScheme.palette.base0F}";
      "toolbar.hoverBackground" = "#${config.colorScheme.palette.base02}";
      "toolbar.activeBackground" = "#${config.colorScheme.palette.base03}";
      "button.background" = "#${config.colorScheme.palette.base0D}";
      "button.foreground" = "#${config.colorScheme.palette.base07}";
      "button.hoverBackground" = "#${config.colorScheme.palette.base04}";
      "button.secondaryForeground" = "#${config.colorScheme.palette.base07}";
      "button.secondaryBackground" = "#${config.colorScheme.palette.base0E}";
      "button.secondaryHoverBackground" = "#${config.colorScheme.palette.base04}";
      "checkbox.background" = "#${config.colorScheme.palette.base00}";
      "checkbox.foreground" = "#${config.colorScheme.palette.base05}";
      "dropdown.background" = "#${config.colorScheme.palette.base00}";
      "dropdown.listBackground" = "#${config.colorScheme.palette.base00}";
      "dropdown.foreground" = "#${config.colorScheme.palette.base05}";
      "input.background" = "#${config.colorScheme.palette.base00}";
      "input.foreground" = "#${config.colorScheme.palette.base05}";
      "input.placeholderForeground" = "#${config.colorScheme.palette.base03}";
      "inputOption.activeBackground" = "#${config.colorScheme.palette.base02}";
      "inputOption.activeBorder" = "#${config.colorScheme.palette.base09}";
      "inputOption.activeForeground" = "#${config.colorScheme.palette.base05}";
      "inputValidation.errorBackground" = "#${config.colorScheme.palette.base08}";
      "inputValidation.errorForeground" = "#${config.colorScheme.palette.base05}";
      "inputValidation.errorBorder" = "#${config.colorScheme.palette.base08}";
      "inputValidation.infoBackground" = "#${config.colorScheme.palette.base0D}";
      "inputValidation.infoForeground" = "#${config.colorScheme.palette.base05}";
      "inputValidation.infoBorder" = "#${config.colorScheme.palette.base0D}";
      "inputValidation.warningBackground" = "#${config.colorScheme.palette.base0A}";
      "inputValidation.warningForeground" = "#${config.colorScheme.palette.base05}";
      "inputValidation.warningBorder" = "#${config.colorScheme.palette.base0A}";
      "scrollbar.shadow" = "#${config.colorScheme.palette.base01}";
      "scrollbarSlider.activeBackground" = "#${config.colorScheme.palette.base04}6f";
      "scrollbarSlider.background" = "#${config.colorScheme.palette.base02}6f";
      "scrollbarSlider.hoverBackground" = "#${config.colorScheme.palette.base03}6f";
      "badge.background" = "#${config.colorScheme.palette.base00}";
      "badge.foreground" = "#${config.colorScheme.palette.base05}";
      "progressBar.background" = "#${config.colorScheme.palette.base03}";
      "list.activeSelectionBackground" = "#${config.colorScheme.palette.base02}";
      "list.activeSelectionForeground" = "#${config.colorScheme.palette.base05}";
      "list.dropBackground" = "#${config.colorScheme.palette.base07}";
      "list.focusBackground" = "#${config.colorScheme.palette.base02}";
      "list.focusForeground" = "#${config.colorScheme.palette.base05}";
      "list.highlightForeground" = "#${config.colorScheme.palette.base07}";
      "list.hoverBackground" = "#${config.colorScheme.palette.base03}";
      "list.hoverForeground" = "#${config.colorScheme.palette.base05}";
      "list.inactiveSelectionBackground" = "#${config.colorScheme.palette.base02}";
      "list.inactiveSelectionForeground" = "#${config.colorScheme.palette.base05}";
      "list.inactiveFocusBackground" = "#${config.colorScheme.palette.base02}";
      "list.invalidItemForeground" = "#${config.colorScheme.palette.base08}";
      "list.errorForeground" = "#${config.colorScheme.palette.base08}";
      "list.warningForeground" = "#${config.colorScheme.palette.base0A}";
      "listFilterWidget.background" = "#${config.colorScheme.palette.base00}";
      "listFilterWidget.noMatchesOutline" = "#${config.colorScheme.palette.base08}";
      "list.filterMatchBackground" = "#${config.colorScheme.palette.base02}";
      "tree.indentGuidesStroke" = "#${config.colorScheme.palette.base05}";
      "activityBar.background" = "#${config.colorScheme.palette.base00}";
      "activityBar.dropBackground" = "#${config.colorScheme.palette.base07}";
      "activityBar.foreground" = "#${config.colorScheme.palette.base05}";
      "activityBar.inactiveForeground" = "#${config.colorScheme.palette.base03}";
      "activityBarBadge.background" = "#${config.colorScheme.palette.base0D}";
      "activityBarBadge.foreground" = "#${config.colorScheme.palette.base07}";
      "activityBar.activeBackground" = "#${config.colorScheme.palette.base02}";
      "sideBar.background" = "#${config.colorScheme.palette.base01}";
      "sideBar.foreground" = "#${config.colorScheme.palette.base05}";
      "sideBar.dropBackground" = "#${config.colorScheme.palette.base02}6f";
      "sideBarTitle.foreground" = "#${config.colorScheme.palette.base05}";
      "sideBarSectionHeader.background" = "#${config.colorScheme.palette.base03}";
      "sideBarSectionHeader.foreground" = "#${config.colorScheme.palette.base05}";
      "minimap.findMatchHighlight" = "#${config.colorScheme.palette.base0A}6f";
      "minimap.selectionHighlight" = "#${config.colorScheme.palette.base02}6f";
      "minimap.errorHighlight" = "#${config.colorScheme.palette.base08}";
      "minimap.warningHighlight" = "#${config.colorScheme.palette.base0A}";
      "minimap.background" = "#${config.colorScheme.palette.base00}";
      "minimap.selectionOccurrenceHighlight" = "#${config.colorScheme.palette.base03}";
      "minimapGutter.addedBackground" = "#${config.colorScheme.palette.base0B}";
      "minimapGutter.modifiedBackground" = "#${config.colorScheme.palette.base0E}";
      "minimapGutter.deletedBackground" = "#${config.colorScheme.palette.base08}";
      "editorGroup.background" = "#${config.colorScheme.palette.base00}";
      "editorGroup.dropBackground" = "#${config.colorScheme.palette.base02}6f";
      "editorGroupHeader.noTabsBackground" = "#${config.colorScheme.palette.base01}";
      "editorGroupHeader.tabsBackground" = "#${config.colorScheme.palette.base01}";
      "editorGroup.emptyBackground" = "#${config.colorScheme.palette.base00}";
      "editorGroup.dropIntoPromptForeground" = "#${config.colorScheme.palette.base06}";
      "editorGroup.dropIntoPromptBackground" = "#${config.colorScheme.palette.base00}";
      "tab.activeBackground" = "#${config.colorScheme.palette.base00}";
      "tab.unfocusedActiveBackground" = "#${config.colorScheme.palette.base00}";
      "tab.activeForeground" = "#${config.colorScheme.palette.base05}";
      "tab.inactiveBackground" = "#${config.colorScheme.palette.base01}";
      "tab.inactiveForeground" = "#${config.colorScheme.palette.base03}";
      "tab.unfocusedActiveForeground" = "#${config.colorScheme.palette.base04}";
      "tab.unfocusedInactiveForeground" = "#${config.colorScheme.palette.base03}";
      "tab.hoverBackground" = "#${config.colorScheme.palette.base02}";
      "tab.unfocusedHoverBackground" = "#${config.colorScheme.palette.base02}";
      "tab.activeModifiedBorder" = "#${config.colorScheme.palette.base0D}";
      "tab.inactiveModifiedBorder" = "#${config.colorScheme.palette.base0D}";
      "tab.unfocusedActiveModifiedBorder" = "#${config.colorScheme.palette.base0D}";
      "tab.unfocusedInactiveModifiedBorder" = "#${config.colorScheme.palette.base0D}";
      "editorPane.background" = "#${config.colorScheme.palette.base00}";
      "editor.background" = "#${config.colorScheme.palette.base00}";
      "editor.foreground" = "#${config.colorScheme.palette.base05}";
      "editorLineNumber.foreground" = "#${config.colorScheme.palette.base03}";
      "editorLineNumber.activeForeground" = "#${config.colorScheme.palette.base04}";
      "editorCursor.foreground" = "#${config.colorScheme.palette.base05}";
      "editor.selectionBackground" = "#${config.colorScheme.palette.base02}80";
      "editor.inactiveSelectionBackground" = "#${config.colorScheme.palette.base02}40";
      "editor.selectionHighlightBackground" = "#${config.colorScheme.palette.base01}80";
      "editor.wordHighlightBackground" = "#${config.colorScheme.palette.base02}6f";
      "editor.wordHighlightStrongBackground" = "#${config.colorScheme.palette.base03}6f";
      "editor.findMatchBackground" = "#${config.colorScheme.palette.base0A}6f";
      "editor.findMatchHighlightBackground" = "#${config.colorScheme.palette.base09}6f";
      "editor.findRangeHighlightBackground" = "#${config.colorScheme.palette.base01}6f";
      "searchEditor.findMatchBackground" = "#${config.colorScheme.palette.base0A}6f";
      "editor.hoverHighlightBackground" = "#${config.colorScheme.palette.base02}6f";
      "editor.lineHighlightBackground" = "#${config.colorScheme.palette.base01}";
      "editorLink.activeForeground" = "#${config.colorScheme.palette.base0D}";
      "editor.rangeHighlightBackground" = "#${config.colorScheme.palette.base01}6f";
      "editorWhitespace.foreground" = "#${config.colorScheme.palette.base03}";
      "editorIndentGuide.background1" = "#${config.colorScheme.palette.base03}";
      "editorIndentGuide.activeBackground1" = "#${config.colorScheme.palette.base04}";
      "editorInlayHint.background" = "#${config.colorScheme.palette.base01}";
      "editorInlayHint.foreground" = "#${config.colorScheme.palette.base05}";
      "editorInlayHint.typeBackground" = "#${config.colorScheme.palette.base01}";
      "editorInlayHint.typeForeground" = "#${config.colorScheme.palette.base05}";
      "editorInlayHint.parameterBackground" = "#${config.colorScheme.palette.base01}";
      "editorInlayHint.parameterForeground" = "#${config.colorScheme.palette.base05}";
      "editorRuler.foreground" = "#${config.colorScheme.palette.base03}";
      "editorCodeLens.foreground" = "#${config.colorScheme.palette.base02}";
      "editorLightBulb.foreground" = "#${config.colorScheme.palette.base0A}";
      "editorLightBulbAutoFix.foreground" = "#${config.colorScheme.palette.base0D}";
      "editorBracketMatch.background" = "#${config.colorScheme.palette.base02}";
      "editorBracketHighlight.foreground1" = "#${config.colorScheme.palette.base08}";
      "editorBracketHighlight.foreground2" = "#${config.colorScheme.palette.base09}";
      "editorBracketHighlight.foreground3" = "#${config.colorScheme.palette.base0A}";
      "editorBracketHighlight.foreground4" = "#${config.colorScheme.palette.base0B}";
      "editorBracketHighlight.foreground5" = "#${config.colorScheme.palette.base0D}";
      "editorBracketHighlight.foreground6" = "#${config.colorScheme.palette.base0E}";
      "editorBracketHighlight.unexpectedBracket.foreground" = "#${config.colorScheme.palette.base0F}";
      "editorOverviewRuler.findMatchForeground" = "#${config.colorScheme.palette.base0A}40";
      "editorOverviewRuler.rangeHighlightForeground" = "#${config.colorScheme.palette.base03}40";
      "editorOverviewRuler.selectionHighlightForeground" = "#${config.colorScheme.palette.base02}40";
      "editorOverviewRuler.wordHighlightForeground" = "#${config.colorScheme.palette.base07}40";
      "editorOverviewRuler.wordHighlightStrongForeground" = "#${config.colorScheme.palette.base0D}40";
      "editorOverviewRuler.modifiedForeground" = "#${config.colorScheme.palette.base0E}";
      "editorOverviewRuler.addedForeground" = "#${config.colorScheme.palette.base0B}";
      "editorOverviewRuler.deletedForeground" = "#${config.colorScheme.palette.base08}";
      "editorOverviewRuler.errorForeground" = "#${config.colorScheme.palette.base08}";
      "editorOverviewRuler.warningForeground" = "#${config.colorScheme.palette.base0A}";
      "editorOverviewRuler.infoForeground" = "#${config.colorScheme.palette.base0C}";
      "editorOverviewRuler.bracketMatchForeground" = "#${config.colorScheme.palette.base06}40";
      "editorError.foreground" = "#${config.colorScheme.palette.base08}";
      "editorWarning.foreground" = "#${config.colorScheme.palette.base0A}";
      "editorInfo.foreground" = "#${config.colorScheme.palette.base0C}";
      "editorHint.foreground" = "#${config.colorScheme.palette.base0D}";
      "problemsErrorIcon.foreground" = "#${config.colorScheme.palette.base08}";
      "problemsWarningIcon.foreground" = "#${config.colorScheme.palette.base0A}";
      "problemsInfoIcon.foreground" = "#${config.colorScheme.palette.base0C}";
      "editorGutter.background" = "#${config.colorScheme.palette.base00}";
      "editorGutter.modifiedBackground" = "#${config.colorScheme.palette.base0E}";
      "editorGutter.addedBackground" = "#${config.colorScheme.palette.base0B}";
      "editorGutter.deletedBackground" = "#${config.colorScheme.palette.base08}";
      "editorGutter.commentRangeForeground" = "#${config.colorScheme.palette.base04}";
      "editorGutter.foldingControlForeground" = "#${config.colorScheme.palette.base05}";
      "diffEditor.insertedTextBackground" = "#${config.colorScheme.palette.base0B}20";
      "diffEditor.removedTextBackground" = "#${config.colorScheme.palette.base08}20";
      "diffEditor.diagonalFill" = "#${config.colorScheme.palette.base02}";
      "editorWidget.foreground" = "#${config.colorScheme.palette.base05}";
      "editorWidget.background" = "#${config.colorScheme.palette.base00}";
      "editorSuggestWidget.background" = "#${config.colorScheme.palette.base01}";
      "editorSuggestWidget.foreground" = "#${config.colorScheme.palette.base05}";
      "editorSuggestWidget.focusHighlightForeground" = "#${config.colorScheme.palette.base07}";
      "editorSuggestWidget.highlightForeground" = "#${config.colorScheme.palette.base0D}";
      "editorSuggestWidget.selectedBackground" = "#${config.colorScheme.palette.base02}";
      "editorSuggestWidget.selectedForeground" = "#${config.colorScheme.palette.base06}";
      "editorHoverWidget.foreground" = "#${config.colorScheme.palette.base05}";
      "editorHoverWidget.background" = "#${config.colorScheme.palette.base00}";
      "debugExceptionWidget.background" = "#${config.colorScheme.palette.base01}";
      "editorMarkerNavigation.background" = "#${config.colorScheme.palette.base01}";
      "editorMarkerNavigationError.background" = "#${config.colorScheme.palette.base08}";
      "editorMarkerNavigationWarning.background" = "#${config.colorScheme.palette.base0A}";
      "editorMarkerNavigationInfo.background" = "#${config.colorScheme.palette.base0D}";
      "editorMarkerNavigationError.headerBackground" = "#${config.colorScheme.palette.base08}20";
      "editorMarkerNavigationWarning.headerBackground" = "#${config.colorScheme.palette.base0A}20";
      "editorMarkerNavigationInfo.headerBackground" = "#${config.colorScheme.palette.base0C}20";
      "peekViewEditor.background" = "#${config.colorScheme.palette.base01}";
      "peekViewEditorGutter.background" = "#${config.colorScheme.palette.base01}";
      "peekViewEditor.matchHighlightBackground" = "#${config.colorScheme.palette.base09}6f";
      "peekViewResult.background" = "#${config.colorScheme.palette.base00}";
      "peekViewResult.fileForeground" = "#${config.colorScheme.palette.base05}";
      "peekViewResult.lineForeground" = "#${config.colorScheme.palette.base03}";
      "peekViewResult.matchHighlightBackground" = "#${config.colorScheme.palette.base09}6f";
      "peekViewResult.selectionBackground" = "#${config.colorScheme.palette.base02}";
      "peekViewResult.selectionForeground" = "#${config.colorScheme.palette.base05}";
      "peekViewTitle.background" = "#${config.colorScheme.palette.base02}";
      "peekViewTitleDescription.foreground" = "#${config.colorScheme.palette.base03}";
      "peekViewTitleLabel.foreground" = "#${config.colorScheme.palette.base05}";
      "merge.currentContentBackground" = "#${config.colorScheme.palette.base0D}40";
      "merge.currentHeaderBackground" = "#${config.colorScheme.palette.base0D}40";
      "merge.incomingContentBackground" = "#${config.colorScheme.palette.base0B}60";
      "merge.incomingHeaderBackground" = "#${config.colorScheme.palette.base0B}60";
      "editorOverviewRuler.currentContentForeground" = "#${config.colorScheme.palette.base0D}";
      "editorOverviewRuler.incomingContentForeground" = "#${config.colorScheme.palette.base0B}";
      "editorOverviewRuler.commonContentForeground" = "#${config.colorScheme.palette.base0F}";
      "panel.background" = "#${config.colorScheme.palette.base00}";
      "panel.dropBackground" = "#${config.colorScheme.palette.base01}6f";
      "panel.dropBorder" = "#${config.colorScheme.palette.base01}6f";
      "panelTitle.activeForeground" = "#${config.colorScheme.palette.base05}";
      "panelTitle.inactiveForeground" = "#${config.colorScheme.palette.base03}";
      "statusBar.background" = "#${config.colorScheme.palette.base0D}";
      "statusBar.foreground" = "#${config.colorScheme.palette.base07}";
      "statusBar.debuggingBackground" = "#${config.colorScheme.palette.base09}";
      "statusBar.debuggingForeground" = "#${config.colorScheme.palette.base07}";
      "statusBar.noFolderBackground" = "#${config.colorScheme.palette.base0E}";
      "statusBar.noFolderForeground" = "#${config.colorScheme.palette.base07}";
      "statusBarItem.activeBackground" = "#${config.colorScheme.palette.base03}";
      "statusBarItem.hoverBackground" = "#${config.colorScheme.palette.base02}";
      "statusBarItem.prominentForeground" = "#${config.colorScheme.palette.base07}";
      "statusBarItem.prominentBackground" = "#${config.colorScheme.palette.base0E}";
      "statusBarItem.prominentHoverBackground" = "#${config.colorScheme.palette.base08}";
      "statusBarItem.remoteBackground" = "#${config.colorScheme.palette.base0B}";
      "statusBarItem.remoteForeground" = "#${config.colorScheme.palette.base07}";
      "statusBarItem.errorBackground" = "#${config.colorScheme.palette.base08}";
      "statusBarItem.errorForeground" = "#${config.colorScheme.palette.base07}";
      "statusBarItem.warningBackground" = "#${config.colorScheme.palette.base0A}";
      "statusBarItem.warningForeground" = "#${config.colorScheme.palette.base07}";
      "titleBar.activeBackground" = "#${config.colorScheme.palette.base00}";
      "titleBar.activeForeground" = "#${config.colorScheme.palette.base05}";
      "titleBar.inactiveBackground" = "#${config.colorScheme.palette.base01}";
      "titleBar.inactiveForeground" = "#${config.colorScheme.palette.base03}";
      "menubar.selectionForeground" = "#${config.colorScheme.palette.base05}";
      "menubar.selectionBackground" = "#${config.colorScheme.palette.base01}";
      "menu.foreground" = "#${config.colorScheme.palette.base05}";
      "menu.background" = "#${config.colorScheme.palette.base01}";
      "menu.selectionForeground" = "#${config.colorScheme.palette.base05}";
      "menu.selectionBackground" = "#${config.colorScheme.palette.base02}";
      "menu.separatorBackground" = "#${config.colorScheme.palette.base07}";
      "commandCenter.foreground" = "#${config.colorScheme.palette.base05}";
      "commandCenter.activeForeground" = "#${config.colorScheme.palette.base07}";
      "commandCenter.background" = "#${config.colorScheme.palette.base00}";
      "commandCenter.activeBackground" = "#${config.colorScheme.palette.base01}";
      "notificationCenterHeader.foreground" = "#${config.colorScheme.palette.base05}";
      "notificationCenterHeader.background" = "#${config.colorScheme.palette.base01}";
      "notifications.foreground" = "#${config.colorScheme.palette.base05}";
      "notifications.background" = "#${config.colorScheme.palette.base02}";
      "notificationLink.foreground" = "#${config.colorScheme.palette.base0D}";
      "notificationsErrorIcon.foreground" = "#${config.colorScheme.palette.base08}";
      "notificationsWarningIcon.foreground" = "#${config.colorScheme.palette.base0A}";
      "notificationsInfoIcon.foreground" = "#${config.colorScheme.palette.base0D}";
      "notification.background" = "#${config.colorScheme.palette.base02}";
      "notification.foreground" = "#${config.colorScheme.palette.base05}";
      "notification.buttonBackground" = "#${config.colorScheme.palette.base0D}";
      "notification.buttonHoverBackground" = "#${config.colorScheme.palette.base02}";
      "notification.buttonForeground" = "#${config.colorScheme.palette.base07}";
      "notification.infoBackground" = "#${config.colorScheme.palette.base0C}";
      "notification.infoForeground" = "#${config.colorScheme.palette.base07}";
      "notification.warningBackground" = "#${config.colorScheme.palette.base0A}";
      "notification.warningForeground" = "#${config.colorScheme.palette.base07}";
      "notification.errorBackground" = "#${config.colorScheme.palette.base08}";
      "notification.errorForeground" = "#${config.colorScheme.palette.base07}";
      "banner.background" = "#${config.colorScheme.palette.base02}";
      "banner.foreground" = "#${config.colorScheme.palette.base05}";
      "banner.iconForeground" = "#${config.colorScheme.palette.base0D}";
      "extensionButton.prominentBackground" = "#${config.colorScheme.palette.base0B}";
      "extensionButton.prominentForeground" = "#${config.colorScheme.palette.base07}";
      "extensionButton.prominentHoverBackground" = "#${config.colorScheme.palette.base02}";
      "extensionBadge.remoteBackground" = "#${config.colorScheme.palette.base09}";
      "extensionBadge.remoteForeground" = "#${config.colorScheme.palette.base07}";
      "extensionIcon.starForeground" = "#${config.colorScheme.palette.base0A}";
      "extensionIcon.verifiedForeground" = "#${config.colorScheme.palette.base0D}";
      "extensionIcon.preReleaseForeground" = "#${config.colorScheme.palette.base09}";
      "pickerGroup.foreground" = "#${config.colorScheme.palette.base03}";
      "quickInput.background" = "#${config.colorScheme.palette.base01}";
      "quickInput.foreground" = "#${config.colorScheme.palette.base05}";
      "quickInputList.focusBackground" = "#${config.colorScheme.palette.base03}";
      "quickInputList.focusForeground" = "#${config.colorScheme.palette.base07}";
      "quickInputList.focusIconForeground" = "#${config.colorScheme.palette.base07}";
      "keybindingLabel.background" = "#${config.colorScheme.palette.base02}";
      "keybindingLabel.foreground" = "#${config.colorScheme.palette.base05}";
      "keybindingTable.headerBackground" = "#${config.colorScheme.palette.base02}";
      "keybindingTable.rowsBackground" = "#${config.colorScheme.palette.base01}";
      "terminal.background" = "#${config.colorScheme.palette.base00}";
      "terminal.foreground" = "#${config.colorScheme.palette.base05}";
      "terminal.ansiBlack" = "#${config.colorScheme.palette.base00}";
      "terminal.ansiRed" = "#${config.colorScheme.palette.base08}";
      "terminal.ansiGreen" = "#${config.colorScheme.palette.base0B}";
      "terminal.ansiYellow" = "#${config.colorScheme.palette.base0A}";
      "terminal.ansiBlue" = "#${config.colorScheme.palette.base0D}";
      "terminal.ansiMagenta" = "#${config.colorScheme.palette.base0E}";
      "terminal.ansiCyan" = "#${config.colorScheme.palette.base0C}";
      "terminal.ansiWhite" = "#${config.colorScheme.palette.base05}";
      "terminal.ansiBrightBlack" = "#${config.colorScheme.palette.base03}";
      "terminal.ansiBrightRed" = "#${config.colorScheme.palette.base08}";
      "terminal.ansiBrightGreen" = "#${config.colorScheme.palette.base0B}";
      "terminal.ansiBrightYellow" = "#${config.colorScheme.palette.base0A}";
      "terminal.ansiBrightBlue" = "#${config.colorScheme.palette.base0D}";
      "terminal.ansiBrightMagenta" = "#${config.colorScheme.palette.base0E}";
      "terminal.ansiBrightCyan" = "#${config.colorScheme.palette.base0C}";
      "terminal.ansiBrightWhite" = "#${config.colorScheme.palette.base07}";
      "terminalCursor.foreground" = "#${config.colorScheme.palette.base05}";
      "terminalOverviewRuler.cursorForeground" = "#${config.colorScheme.palette.base05}";
      "terminalOverviewRuler.findMatchForeground" = "#${config.colorScheme.palette.base0A}6f";
      "debugToolBar.background" = "#${config.colorScheme.palette.base01}";
      "debugView.stateLabelForeground" = "#${config.colorScheme.palette.base07}";
      "debugView.stateLabelBackground" = "#${config.colorScheme.palette.base0D}";
      "debugView.valueChangedHighlight" = "#${config.colorScheme.palette.base0D}";
      "debugTokenExpression.name" = "#${config.colorScheme.palette.base0E}";
      "debugTokenExpression.value" = "#${config.colorScheme.palette.base05}";
      "debugTokenExpression.string" = "#${config.colorScheme.palette.base0B}";
      "debugTokenExpression.boolean" = "#${config.colorScheme.palette.base09}";
      "debugTokenExpression.number" = "#${config.colorScheme.palette.base09}";
      "debugTokenExpression.error" = "#${config.colorScheme.palette.base08}";
      "testing.iconFailed" = "#${config.colorScheme.palette.base08}";
      "testing.iconErrored" = "#${config.colorScheme.palette.base0F}";
      "testing.iconPassed" = "#${config.colorScheme.palette.base0B}";
      "testing.runAction" = "#${config.colorScheme.palette.base04}";
      "testing.iconQueued" = "#${config.colorScheme.palette.base0A}";
      "testing.iconUnset" = "#${config.colorScheme.palette.base04}";
      "testing.iconSkipped" = "#${config.colorScheme.palette.base0E}";
      "testing.peekHeaderBackground" = "#${config.colorScheme.palette.base01}";
      "testing.message.error.decorationForeground" = "#${config.colorScheme.palette.base05}";
      "testing.message.error.lineBackground" = "#${config.colorScheme.palette.base08}20";
      "testing.message.info.decorationForeground" = "#${config.colorScheme.palette.base05}";
      "testing.message.info.lineBackground" = "#${config.colorScheme.palette.base0D}20";
      "welcomePage.background" = "#${config.colorScheme.palette.base00}";
      "welcomePage.buttonBackground" = "#${config.colorScheme.palette.base01}";
      "welcomePage.buttonHoverBackground" = "#${config.colorScheme.palette.base02}";
      "welcomePage.progress.background" = "#${config.colorScheme.palette.base03}";
      "welcomePage.progress.foreground" = "#${config.colorScheme.palette.base0D}";
      "welcomePage.tileBackground" = "#${config.colorScheme.palette.base01}";
      "welcomePage.tileHoverBackground" = "#${config.colorScheme.palette.base02}";
      "walkThrough.embeddedEditorBackground" = "#${config.colorScheme.palette.base00}";
      "gitDecoration.addedResourceForeground" = "#${config.colorScheme.palette.base0B}";
      "gitDecoration.modifiedResourceForeground" = "#${config.colorScheme.palette.base0E}";
      "gitDecoration.deletedResourceForeground" = "#${config.colorScheme.palette.base08}";
      "gitDecoration.renamedResourceForeground" = "#${config.colorScheme.palette.base0C}";
      "gitDecoration.stageModifiedResourceForeground" = "#${config.colorScheme.palette.base0E}";
      "gitDecoration.stageDeletedResourceForeground" = "#${config.colorScheme.palette.base08}";
      "gitDecoration.untrackedResourceForeground" = "#${config.colorScheme.palette.base09}";
      "gitDecoration.ignoredResourceForeground" = "#${config.colorScheme.palette.base03}";
      "gitDecoration.conflictingResourceForeground" = "#${config.colorScheme.palette.base0A}";
      "gitDecoration.submoduleResourceForeground" = "#${config.colorScheme.palette.base0F}";
      "settings.headerForeground" = "#${config.colorScheme.palette.base05}";
      "settings.modifiedItemIndicator" = "#${config.colorScheme.palette.base0D}";
      "settings.modifiedItemForeground" = "#${config.colorScheme.palette.base0B}";
      "settings.dropdownBackground" = "#${config.colorScheme.palette.base01}";
      "settings.dropdownForeground" = "#${config.colorScheme.palette.base05}";
      "settings.checkboxBackground" = "#${config.colorScheme.palette.base01}";
      "settings.checkboxForeground" = "#${config.colorScheme.palette.base05}";
      "settings.rowHoverBackground" = "#${config.colorScheme.palette.base02}";
      "settings.textInputBackground" = "#${config.colorScheme.palette.base01}";
      "settings.textInputForeground" = "#${config.colorScheme.palette.base05}";
      "settings.numberInputBackground" = "#${config.colorScheme.palette.base01}";
      "settings.numberInputForeground" = "#${config.colorScheme.palette.base05}";
      "settings.focusedRowBackground" = "#${config.colorScheme.palette.base02}";
      "settings.headerBorder" = "#${config.colorScheme.palette.base05}";
      "settings.sashBorder" = "#${config.colorScheme.palette.base05}";
      "breadcrumb.foreground" = "#${config.colorScheme.palette.base05}";
      "breadcrumb.background" = "#${config.colorScheme.palette.base01}";
      "breadcrumb.focusForeground" = "#${config.colorScheme.palette.base06}";
      "breadcrumb.activeSelectionForeground" = "#${config.colorScheme.palette.base07}";
      "breadcrumbPicker.background" = "#${config.colorScheme.palette.base01}";
      "editor.snippetTabstopHighlightBackground" = "#${config.colorScheme.palette.base02}";
      "editor.snippetFinalTabstopHighlightBackground" = "#${config.colorScheme.palette.base03}";
      "symbolIcon.arrayForeground" = "#${config.colorScheme.palette.base05}";
      "symbolIcon.booleanForeground" = "#${config.colorScheme.palette.base09}";
      "symbolIcon.classForeground" = "#${config.colorScheme.palette.base0A}";
      "symbolIcon.colorForeground" = "#${config.colorScheme.palette.base0C}";
      "symbolIcon.constantForeground" = "#${config.colorScheme.palette.base09}";
      "symbolIcon.constructorForeground" = "#${config.colorScheme.palette.base0D}";
      "symbolIcon.enumeratorForeground" = "#${config.colorScheme.palette.base09}";
      "symbolIcon.enumeratorMemberForeground" = "#${config.colorScheme.palette.base0D}";
      "symbolIcon.eventForeground" = "#${config.colorScheme.palette.base0A}";
      "symbolIcon.fieldForeground" = "#${config.colorScheme.palette.base08}";
      "symbolIcon.fileForeground" = "#${config.colorScheme.palette.base05}";
      "symbolIcon.folderForeground" = "#${config.colorScheme.palette.base05}";
      "symbolIcon.functionForeground" = "#${config.colorScheme.palette.base0D}";
      "symbolIcon.interfaceForeground" = "#${config.colorScheme.palette.base0D}";
      "symbolIcon.keyForeground" = "#${config.colorScheme.palette.base0E}";
      "symbolIcon.keywordForeground" = "#${config.colorScheme.palette.base0E}";
      "symbolIcon.methodForeground" = "#${config.colorScheme.palette.base0D}";
      "symbolIcon.moduleForeground" = "#${config.colorScheme.palette.base05}";
      "symbolIcon.namespaceForeground" = "#${config.colorScheme.palette.base05}";
      "symbolIcon.nullForeground" = "#${config.colorScheme.palette.base0F}";
      "symbolIcon.numberForeground" = "#${config.colorScheme.palette.base09}";
      "symbolIcon.objectForeground" = "#${config.colorScheme.palette.base0A}";
      "symbolIcon.operatorForeground" = "#${config.colorScheme.palette.base0C}";
      "symbolIcon.packageForeground" = "#${config.colorScheme.palette.base0B}";
      "symbolIcon.propertyForeground" = "#${config.colorScheme.palette.base05}";
      "symbolIcon.referenceForeground" = "#${config.colorScheme.palette.base0D}";
      "symbolIcon.snippetForeground" = "#${config.colorScheme.palette.base05}";
      "symbolIcon.stringForeground" = "#${config.colorScheme.palette.base0B}";
      "symbolIcon.structForeground" = "#${config.colorScheme.palette.base0A}";
      "symbolIcon.textForeground" = "#${config.colorScheme.palette.base05}";
      "symbolIcon.typeParameterForeground" = "#${config.colorScheme.palette.base0C}";
      "symbolIcon.unitForeground" = "#${config.colorScheme.palette.base09}";
      "symbolIcon.variableForeground" = "#${config.colorScheme.palette.base08}";
      "debugIcon.breakpointForeground" = "#${config.colorScheme.palette.base08}";
      "debugIcon.breakpointDisabledForeground" = "#${config.colorScheme.palette.base04}";
      "debugIcon.breakpointUnverifiedForeground" = "#${config.colorScheme.palette.base02}";
      "debugIcon.breakpointCurrentStackframeForeground" = "#${config.colorScheme.palette.base0A}";
      "debugIcon.breakpointStackframeForeground" = "#${config.colorScheme.palette.base0F}";
      "debugIcon.startForeground" = "#${config.colorScheme.palette.base0B}";
      "debugIcon.pauseForeground" = "#${config.colorScheme.palette.base0D}";
      "debugIcon.stopForeground" = "#${config.colorScheme.palette.base08}";
      "debugIcon.disconnectForeground" = "#${config.colorScheme.palette.base08}";
      "debugIcon.restartForeground" = "#${config.colorScheme.palette.base0B}";
      "debugIcon.stepOverForeground" = "#${config.colorScheme.palette.base0D}";
      "debugIcon.stepIntoForeground" = "#${config.colorScheme.palette.base0C}";
      "debugIcon.stepOutForeground" = "#${config.colorScheme.palette.base0E}";
      "debugIcon.continueForeground" = "#${config.colorScheme.palette.base0B}";
      "debugIcon.stepBackForeground" = "#${config.colorScheme.palette.base0F}";
      "debugConsole.infoForeground" = "#${config.colorScheme.palette.base05}";
      "debugConsole.warningForeground" = "#${config.colorScheme.palette.base0A}";
      "debugConsole.errorForeground" = "#${config.colorScheme.palette.base08}";
      "debugConsole.sourceForeground" = "#${config.colorScheme.palette.base05}";
      "debugConsoleInputIcon.foreground" = "#${config.colorScheme.palette.base05}";
      "notebook.editorBackground" = "#${config.colorScheme.palette.base00}";
      "notebook.cellBorderColor" = "#${config.colorScheme.palette.base03}";
      "notebook.cellHoverBackground" = "#${config.colorScheme.palette.base01}";
      "notebook.cellToolbarSeparator" = "#${config.colorScheme.palette.base02}";
      "notebook.cellEditorBackground" = "#${config.colorScheme.palette.base00}";
      "notebook.focusedCellBackground" = "#${config.colorScheme.palette.base02}";
      "notebook.focusedCellBorder" = "#${config.colorScheme.palette.base0D}";
      "notebook.focusedEditorBorder" = "#${config.colorScheme.palette.base0D}";
      "notebook.inactiveFocusedCellBorder" = "#${config.colorScheme.palette.base03}";
      "notebook.selectedCellBackground" = "#${config.colorScheme.palette.base02}";
      "notebookStatusErrorIcon.foreground" = "#${config.colorScheme.palette.base08}";
      "notebookStatusRunningIcon.foreground" = "#${config.colorScheme.palette.base0C}";
      "notebookStatusSuccessIcon.foreground" = "#${config.colorScheme.palette.base0B}";
      "charts.foreground" = "#${config.colorScheme.palette.base05}";
      "charts.lines" = "#${config.colorScheme.palette.base05}";
      "charts.red" = "#${config.colorScheme.palette.base08}";
      "charts.blue" = "#${config.colorScheme.palette.base0D}";
      "charts.yellow" = "#${config.colorScheme.palette.base0A}";
      "charts.orange" = "#${config.colorScheme.palette.base09}";
      "charts.green" = "#${config.colorScheme.palette.base0B}";
      "charts.purple" = "#${config.colorScheme.palette.base0E}";
      "ports.iconRunningProcessForeground" = "#${config.colorScheme.palette.base09}";
    };
    tokenColors = [
      {
        name = "Comment";
        scope = [
          "comment"
          "punctuation.definition.comment"
        ];
        settings = {
          fontStyle = "italic";
          foreground = "#${config.colorScheme.palette.base03}";
        };
      }
      {
        name = "Variables, Parameters";
        scope = [
          "variable"
          "string constant.other.placeholder"
          "entity.name.variable.parameter"
          "entity.name.variable.local"
          "variable.parameter"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base08}";
        };
      }
      {
        name = "Properties";
        scope = [
          "variable.other.object.property"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0D}";
        };
      }
      {
        name = "Colors";
        scope = [
          "constant.other.color"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0B}";
        };
      }
      {
        name = "Invalid";
        scope = [
          "invalid"
          "invalid.illegal"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base08}";
        };
      }
      {
        name = "Invalid - Deprecated";
        scope = [
          "invalid.deprecated"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0F}";
        };
      }
      {
        name = "Keyword, Storage";
        scope = [
          "keyword"
          "storage.modifier"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0E}";
        };
      }
      {
        name = "Keyword Control";
        scope = [
          "keyword.control"
          "keyword.control.flow"
          "keyword.control.from"
          "keyword.control.import"
          "keyword.control.as"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0E}";
        };
      }
      {
        name = "Keyword";
        scope = [
          "keyword.other.using"
          "keyword.other.namespace"
          "keyword.other.class"
          "keyword.other.new"
          "keyword.other.event"
          "keyword.other.this"
          "keyword.other.await"
          "keyword.other.var"
          "keyword.other.package"
          "keyword.other.import"
          "variable.language.this"
          "storage.type.ts"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0E}";
        };
      }
      {
        name = "Types, Primitives";
        scope = [
          "keyword.type"
          "storage.type.primitive"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0C}";
        };
      }
      {
        name = "Function";
        scope = [
          "storage.type.function"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0D}";
        };
      }
      {
        name = "Operator, Misc";
        scope = [
          "constant.other.color"
          "punctuation"
          "punctuation.section.class.end"
          "meta.tag"
          "punctuation.definition.tag"
          "punctuation.separator.inheritance.php"
          "punctuation.definition.tag.html"
          "punctuation.definition.tag.begin.html"
          "punctuation.definition.tag.end.html"
          "keyword.other.template"
          "keyword.other.substitution"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base05}";
        };
      }
      {
        name = "Embedded";
        scope = [
          "punctuation.section.embedded"
          "variable.interpolation"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0F}";
        };
      }
      {
        name = "Tag";
        scope = [
          "entity.name.tag"
          "meta.tag.sgml"
          "markup.deleted.git_gutter"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base08}";
        };
      }
      {
        name = "Function, Special Method";
        scope = [
          "entity.name.function"
          "meta.function-call"
          "variable.function"
          "support.function"
          "keyword.other.special-method"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0D}";
        };
      }
      {
        name = "Block Level Variables";
        scope = [
          "meta.block variable.other"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base08}";
        };
      }
      {
        name = "Other Variable, String Link";
        scope = [
          "support.other.variable"
          "string.other.link"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base08}";
        };
      }
      {
        name = "Number, Constant, Function Argument, Tag Attribute, Embedded";
        scope = [
          "constant.numeric"
          "constant.language"
          "support.constant"
          "constant.character"
          "constant.escape"
          "keyword.other.unit"
          "keyword.other"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base09}";
        };
      }
      {
        name = "String, Symbols, Inherited Class, Markup Heading";
        scope = [
          "string"
          "constant.other.symbol"
          "constant.other.key"
          "entity.other.inherited-class"
          "markup.heading"
          "markup.inserted.git_gutter"
          "meta.group.braces.curly constant.other.object.key.js string.unquoted.label.js"
        ];
        settings = {
          fontStyle = "";
          foreground = "#${config.colorScheme.palette.base0B}";
        };
      }
      {
        name = "Class, Support";
        scope = [
          "entity.name"
          "support.type"
          "support.class"
          "support.other.namespace.use.php"
          "meta.use.php"
          "support.other.namespace.php"
          "markup.changed.git_gutter"
          "support.type.sys-types"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0A}";
        };
      }
      {
        name = "Storage Type, Import Class";
        scope = [
          "storage.type"
          "storage.modifier.package"
          "storage.modifier.import"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0A}";
        };
      }
      {
        name = "Fields";
        scope = [
          "entity.name.variable.field"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0D}";
        };
      }
      {
        name = "Entity Types";
        scope = [
          "support.type"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0C}";
        };
      }
      {
        name = "CSS Class and Support";
        scope = [
          "source.css support.type.property-name"
          "source.sass support.type.property-name"
          "source.scss support.type.property-name"
          "source.less support.type.property-name"
          "source.stylus support.type.property-name"
          "source.postcss support.type.property-name"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0C}";
        };
      }
      {
        name = "Sub-methods";
        scope = [
          "entity.name.module.js"
          "variable.import.parameter.js"
          "variable.other.class.js"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base08}";
        };
      }
      {
        name = "Language methods";
        scope = [
          "variable.language"
        ];
        settings = {
          fontStyle = "italic";
          foreground = "#${config.colorScheme.palette.base08}";
        };
      }
      {
        name = "entity.name.method.js";
        scope = [
          "entity.name.method.js"
        ];
        settings = {
          fontStyle = "italic";
          foreground = "#${config.colorScheme.palette.base0D}";
        };
      }
      {
        name = "meta.method.js";
        scope = [
          "meta.class-method.js entity.name.function.js"
          "variable.function.constructor"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0D}";
        };
      }
      {
        name = "Attributes";
        scope = [
          "entity.other.attribute-name"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0D}";
        };
      }
      {
        name = "HTML Attributes";
        scope = [
          "text.html.basic entity.other.attribute-name.html"
          "text.html.basic entity.other.attribute-name"
        ];
        settings = {
          fontStyle = "italic";
          foreground = "#${config.colorScheme.palette.base0A}";
        };
      }
      {
        name = "CSS Classes";
        scope = [
          "entity.other.attribute-name.class"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0A}";
        };
      }
      {
        name = "CSS ID's";
        scope = [
          "source.sass keyword.control"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0D}";
        };
      }
      {
        name = "Inserted";
        scope = [
          "markup.inserted"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0B}";
        };
      }
      {
        name = "Deleted";
        scope = [
          "markup.deleted"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base08}";
        };
      }
      {
        name = "Changed";
        scope = [
          "markup.changed"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0E}";
        };
      }
      {
        name = "Regular Expressions";
        scope = [
          "string.regexp"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0C}";
        };
      }
      {
        name = "Escape Characters";
        scope = [
          "constant.character.escape"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0C}";
        };
      }
      {
        name = "URL";
        scope = [
          "*url*"
          "*link*"
          "*uri*"
        ];
        settings = {
          fontStyle = "underline";
        };
      }
      {
        name = "Decorators";
        scope = [
          "tag.decorator.js entity.name.tag.js"
          "tag.decorator.js punctuation.definition.tag.js"
        ];
        settings = {
          fontStyle = "italic";
          foreground = "#${config.colorScheme.palette.base0D}";
        };
      }
      {
        name = "ES7 Bind Operator";
        scope = [
          "source.js constant.other.object.key.js string.unquoted.label.js"
        ];
        settings = {
          fontStyle = "italic";
          foreground = "#${config.colorScheme.palette.base0E}";
        };
      }
      {
        name = "JSON Key - Level 0";
        scope = [
          "source.json meta.structure.dictionary.json support.type.property-name.json"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0D}";
        };
      }
      {
        name = "JSON Key - Level 1";
        scope = [
          "source.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json support.type.property-name.json"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0D}";
        };
      }
      {
        name = "JSON Key - Level 2";
        scope = [
          "source.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json support.type.property-name.json"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0D}";
        };
      }
      {
        name = "JSON Key - Level 3";
        scope = [
          "source.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json support.type.property-name.json"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0D}";
        };
      }
      {
        name = "JSON Key - Level 4";
        scope = [
          "source.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json support.type.property-name.json"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0D}";
        };
      }
      {
        name = "JSON Key - Level 5";
        scope = [
          "source.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json support.type.property-name.json"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0D}";
        };
      }
      {
        name = "JSON Key - Level 6";
        scope = [
          "source.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json support.type.property-name.json"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0D}";
        };
      }
      {
        name = "JSON Key - Level 7";
        scope = [
          "source.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json support.type.property-name.json"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0D}";
        };
      }
      {
        name = "JSON Key - Level 8";
        scope = [
          "source.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json meta.structure.dictionary.value.json meta.structure.dictionary.json support.type.property-name.json"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0D}";
        };
      }
      {
        name = "Markdown - Plain";
        scope = [
          "text.html.markdown"
          "punctuation.definition.list_item.markdown"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base05}";
        };
      }
      {
        name = "Markdown - Markup Raw Inline";
        scope = [
          "text.html.markdown markup.inline.raw.markdown"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0E}";
        };
      }
      {
        name = "Markdown - Markup Raw Inline Punctuation";
        scope = [
          "text.html.markdown markup.inline.raw.markdown punctuation.definition.raw.markdown"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0C}";
        };
      }
      {
        name = "Markdown - Line Break";
        scope = [
          "text.html.markdown meta.dummy.line-break"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base03}";
        };
      }
      {
        name = "Markdown - Heading";
        scope = [
          "markdown.heading"
          "markup.heading | markup.heading entity.name"
          "markup.heading.markdown punctuation.definition.heading.markdown"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0D}";
        };
      }
      {
        name = "Markup - Italic";
        scope = [
          "markup.italic"
        ];
        settings = {
          fontStyle = "italic";
          foreground = "#${config.colorScheme.palette.base08}";
        };
      }
      {
        name = "Markup - Bold";
        scope = [
          "markup.bold"
          "markup.bold string"
        ];
        settings = {
          fontStyle = "bold";
          foreground = "#${config.colorScheme.palette.base08}";
        };
      }
      {
        name = "Markup - Bold-Italic";
        scope = [
          "markup.bold markup.italic"
          "markup.italic markup.bold"
          "markup.quote markup.bold"
          "markup.bold markup.italic string"
          "markup.italic markup.bold string"
          "markup.quote markup.bold string"
        ];
        settings = {
          fontStyle = "bold";
          foreground = "#${config.colorScheme.palette.base08}";
        };
      }
      {
        name = "Markup - Underline";
        scope = [
          "markup.underline"
        ];
        settings = {
          fontStyle = "underline";
          foreground = "#${config.colorScheme.palette.base09}";
        };
      }
      {
        name = "Markdown - Blockquote";
        scope = [
          "markup.quote punctuation.definition.blockquote.markdown"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0C}";
        };
      }
      {
        name = "Markup - Quote";
        scope = [
          "markup.quote"
        ];
        settings = {
          fontStyle = "italic";
        };
      }
      {
        name = "Markdown - Link";
        scope = [
          "string.other.link.title.markdown"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0D}";
        };
      }
      {
        name = "Markdown - Link Description";
        scope = [
          "string.other.link.description.title.markdown"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0E}";
        };
      }
      {
        name = "Markdown - Link Anchor";
        scope = [
          "constant.other.reference.link.markdown"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0A}";
        };
      }
      {
        name = "Markup - Raw Block";
        scope = [
          "markup.raw.block"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0E}";
        };
      }
      {
        name = "Markdown - Raw Block Fenced";
        scope = [
          "markup.raw.block.fenced.markdown"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base03}";
        };
      }
      {
        name = "Markdown - Fenced Bode Block";
        scope = [
          "punctuation.definition.fenced.markdown"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base03}";
        };
      }
      {
        name = "Markdown - Fenced Code Block Variable";
        scope = [
          "markup.raw.block.fenced.markdown"
          "variable.language.fenced.markdown"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0E}";
        };
      }
      {
        name = "Markdown - Fenced Language";
        scope = [
          "variable.language.fenced.markdown"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base08}";
        };
      }
      {
        name = "Markdown - Separator";
        scope = [
          "meta.separator"
        ];
        settings = {
          fontStyle = "bold";
          foreground = "#${config.colorScheme.palette.base0C}";
        };
      }
      {
        name = "Markup - Table";
        scope = [
          "markup.table"
        ];
        settings = {
          foreground = "#${config.colorScheme.palette.base0E}";
        };
      }
      {
        scope = "token.info-token";
        settings = {
          foreground = "#${config.colorScheme.palette.base0D}";
        };
      }
      {
        scope = "token.warn-token";
        settings = {
          foreground = "#${config.colorScheme.palette.base0A}";
        };
      }
      {
        scope = "token.error-token";
        settings = {
          foreground = "#${config.colorScheme.palette.base08}";
        };
      }
      {
        scope = "token.debug-token";
        settings = {
          foreground = "#${config.colorScheme.palette.base0E}";
        };
      }
    ];
  };
in
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;

    userSettings = {
      "workbench.colorTheme" = "Default ${
        if config.colorScheme.variant == "light" then "Light" else "Dark"
      } Modern";
      "workbench.colorCustomizations" = base16Settings.colors // {
        "minimap.selectionOccurrenceHighlight" = "#${config.colorScheme.palette.base03}40";
        "widget.shadow" = "#${config.colorScheme.palette.base00}40";
        "editor.lineHighlightBackground" = "#${config.colorScheme.palette.base01}40";
        "editor.lineHighlightBorder" = "#${config.colorScheme.palette.base01}40";
        "editor.selectionBackground" = "#${config.colorScheme.palette.base02}80";
      };
      "editor.tokenColorCustomizations" = {
        "textMateRules" = base16Settings.tokenColors;
      };
      # Common editor settings
      "editor.formatOnSave" = true;
      "editor.formatOnType" = true;
      "editor.formatOnPaste" = true;
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "editor.codeActionsOnSave" = {
        "source.addMissingImports" = "explicit";
        "source.fixAll" = "explicit";
        "source.organizeImports" = "explicit";
        "source.removeUnusedImports" = "explicit";
      };
      "editor.autoIndent" = "full";
      "editor.tabSize" = 2;
      "editor.insertSpaces" = true;
      "editor.detectIndentation" = true;
      "editor.wordWrap" = "wordWrapColumn";
      "editor.wordWrapColumn" = 120;
      "editor.rulers" = [
        80
        120
      ];
      "editor.minimap.enabled" = false;
      "editor.fontSize" = 14;
      "editor.fontFamily" = "'JetBrainsMono Nerd Font Mono'";
      "editor.fontLigatures" = true;
      "editor.cursorBlinking" = "expand";
      "editor.cursorSmoothCaretAnimation" = "on";
      "editor.renderWhitespace" = "boundary";
      "editor.showUnused" = true;
      "editor.bracketPairColorization.enabled" = false;
      "editor.guides.bracketPairs" = "active";
      "editor.inlayHints.enabled" = "on";
      "editor.snippetSuggestions" = "inline";

      # Files and workspace settings
      "files.autoSave" = "onFocusChange";
      "files.trimTrailingWhitespace" = true;
      "files.insertFinalNewline" = true;
      "files.trimFinalNewlines" = true;
      "files.exclude" = {
        "**/.DS_Store" = true;
        "**/.git" = true;
        "**/node_modules" = true;
        "**/target" = true;
        "**/.next" = true;
        "**/dist" = true;
        "**/build" = true;
      };
      "search.exclude" = {
        "**/node_modules" = true;
        "**/target" = true;
        "**/.next" = true;
        "**/dist" = true;
        "**/build" = true;
      };
      "explorer.compactFolders" = false;

      # Terminal settings
      "terminal.integrated.fontSize" = 13;
      "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font Mono'";
      "terminal.integrated.cursorBlinking" = true;
      "terminal.integrated.cursorStyle" = "line";
      "terminal.integrated.scrollback" = 10000;
      "terminal.integrated.shell.osx" = "/etc/profiles/per-user/alex/bin/zsh";
      "terminal.integrated.defaultProfile.osx" = "zsh";
      "terminal.integrated.automationProfile.osx" = null;

      # Git settings
      "git.autofetch" = true;
      "git.confirmSync" = false;
      "git.enableSmartCommit" = true;
      "git.autofetchPeriod" = 180;

      # Nix IDE settings
      "nix.enable" = true;
      "nix.serverPath" = "nixd";
      "nix.formatterPath" = "nixfmt";
      "nix.serverSettings" = {
        "nixd" = {
          "formatting" = {
            "command" = "nixfmt";
          };
        };
      };

      # Swift language settings
      "swift.path" = "/usr/bin/swift";
      "swift.sourcekit-lsp.serverPath" = "/usr/bin/sourcekit-lsp";
      "swift.sourcekit-lsp.toolchainPath" =
        "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain";

      # Rust analyzer settings
      "rust-analyzer.enable" = true;
      "rust-analyzer.server.path" = "rust-analyzer";
      "rust-analyzer.checkOnSave.command" = "clippy";
      "rust-analyzer.checkOnSave.extraArgs" = [ "--all-targets" ];
      "rust-analyzer.cargo.buildScripts.enable" = true;
      "rust-analyzer.cargo.features" = "all";
      "rust-analyzer.inlayHints.enable" = true;
      "rust-analyzer.inlayHints.parameterHints.enable" = true;
      "rust-analyzer.inlayHints.typeHints.enable" = true;
      "rust-analyzer.inlayHints.chainingHints.enable" = true;
      "rust-analyzer.lens.enable" = true;
      "rust-analyzer.lens.run.enable" = true;
      "rust-analyzer.lens.debug.enable" = true;
      "rust-analyzer.completion.addCallArgumentSnippets" = true;
      "rust-analyzer.completion.addCallParenthesis" = true;
      "rust-analyzer.assist.importGranularity" = "module";
      "rust-analyzer.assist.importPrefix" = "by_self";

      # Python settings
      "python.defaultInterpreterPath" = "python3";
      "python.formatting.provider" = "black";
      "python.formatting.blackArgs" = [ "--line-length=88" ];
      "python.linting.enabled" = true;
      "python.linting.pylintEnabled" = true;
      "python.linting.flake8Enabled" = false;
      "python.linting.mypyEnabled" = true;
      "python.linting.lintOnSave" = true;
      "python.sortImports.args" = [ "--profile=black" ];
      "python.analysis.autoImportCompletions" = true;
      "python.analysis.typeCheckingMode" = "basic";
      "python.analysis.autoSearchPaths" = true;
      "python.analysis.diagnosticMode" = "workspace";

      # TypeScript/JavaScript settings
      "typescript.updateImportsOnFileMove.enabled" = "always";
      "typescript.preferences.importModuleSpecifier" = "non-relative";
      "typescript.suggest.autoImports" = true;
      "typescript.suggest.completeFunctionCalls" = true;
      "typescript.preferences.quoteStyle" = "double";
      "typescript.format.enable" = true;
      "typescript.format.insertSpaceAfterCommaDelimiter" = true;
      "typescript.format.insertSpaceAfterSemicolonInForStatements" = true;
      "typescript.format.insertSpaceBeforeAndAfterBinaryOperators" = true;
      "typescript.inlayHints.parameterNames.enabled" = "literals";
      "typescript.inlayHints.parameterTypes.enabled" = true;
      "typescript.inlayHints.variableTypes.enabled" = true;
      "typescript.inlayHints.propertyDeclarationTypes.enabled" = true;
      "typescript.inlayHints.functionLikeReturnTypes.enabled" = true;
      "typescript.referencesCodeLens.enabled" = true;
      "typescript.implementationsCodeLens.enabled" = true;

      "javascript.updateImportsOnFileMove.enabled" = "always";
      "javascript.suggest.autoImports" = true;
      "javascript.suggest.completeFunctionCalls" = true;
      "javascript.preferences.quoteStyle" = "double";
      "javascript.format.enable" = true;
      "javascript.inlayHints.parameterNames.enabled" = "literals";
      "javascript.inlayHints.parameterTypes.enabled" = true;
      "javascript.inlayHints.variableTypes.enabled" = true;
      "javascript.inlayHints.propertyDeclarationTypes.enabled" = true;
      "javascript.inlayHints.functionLikeReturnTypes.enabled" = true;
      "javascript.referencesCodeLens.enabled" = true;
      "javascript.suggestionActions.enabled" = true;
      "javascript.updateImportsOnPaste.enabled" = true;

      # C/C++ settings
      "C_Cpp.default.cppStandard" = "c++20";
      "C_Cpp.default.cStandard" = "c17";
      "C_Cpp.default.intelliSenseMode" = "clang-x64";
      "C_Cpp.clang_format_style" = "{ BasedOnStyle: LLVM, IndentWidth: 2, ColumnLimit: 120 }";
      "C_Cpp.formatting" = "clangFormat";
      "C_Cpp.autocomplete" = "default";
      "C_Cpp.errorSquiggles" = "enabled";
      "C_Cpp.inlayHints.parameterNames.enabled" = true;
      "C_Cpp.inlayHints.referenceOperator.enabled" = true;
      "C_Cpp.enhancedColorization" = "enabled";

      # Makefile settings
      "makefile.configureOnOpen" = true;
      "makefile.extensionOutputFolder" = "./.vscode";
      "makefile.launchConfigurations" = [
        {
          "cwd" = "/path/to/make/directory";
          "binaryPath" = "/path/to/binary";
          "binaryArgs" = [ ];
        }
      ];

      # HTML settings
      "html.format.indentInnerHtml" = true;
      "html.format.wrapLineLength" = 120;
      "html.format.wrapAttributes" = "auto";
      "html.autoClosingTags" = true;
      "editor.linkedEditing" = true;

      # CSS settings
      "css.validate" = true;
      "css.lint.unknownAtRules" = "ignore";
      "scss.validate" = true;
      "less.validate" = true;

      # JSON settings
      "json.format.enable" = true;
      "json.maxItemsComputed" = 5000;

      # Markdown settings
      "markdown.preview.fontSize" = 14;
      "markdown.preview.lineHeight" = 1.6;
      "markdown.preview.fontFamily" =
        "system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif";
      "markdown.extension.toc.levels" = "1..6";
      "markdown.extension.preview.autoShowPreviewToSide" = true;
      "markdown.extension.math.enabled" = true;

      # Emmet settings
      "emmet.includeLanguages" = {
        "javascript" = "javascriptreact";
        "typescript" = "typescriptreact";
      };
      "emmet.triggerExpansionOnTab" = true;
      "emmet.showExpandedAbbreviation" = "always";

      # ESLint settings
      "eslint.enable" = true;
      "eslint.format.enable" = true;
      "eslint.lintTask.enable" = true;
      "eslint.codeAction.showDocumentation" = {
        "enable" = true;
      };
      "eslint.codeActionsOnSave.mode" = "all";
      "eslint.validate" = [
        "javascript"
        "javascriptreact"
        "typescript"
        "typescriptreact"
      ];

      # Prettier settings
      "prettier.enable" = true;
      "prettier.semi" = true;
      "prettier.singleQuote" = false;
      "prettier.tabWidth" = 2;
      "prettier.useTabs" = false;
      "prettier.printWidth" = 120;
      "prettier.trailingComma" = "es5";
      "prettier.bracketSpacing" = true;
      "prettier.arrowParens" = "avoid";

      # Language-specific formatter overrides
      "[javascript]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
        "editor.formatOnSave" = true;
      };
      "[typescript]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
        "editor.formatOnSave" = true;
      };
      "[javascriptreact]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
        "editor.formatOnSave" = true;
      };
      "[typescriptreact]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
        "editor.formatOnSave" = true;
      };
      "[json]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
        "editor.formatOnSave" = true;
      };
      "[jsonc]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
        "editor.formatOnSave" = true;
      };
      "[html]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
        "editor.formatOnSave" = true;
      };
      "[css]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
        "editor.formatOnSave" = true;
      };
      "[scss]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
        "editor.formatOnSave" = true;
      };
      "[less]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
        "editor.formatOnSave" = true;
      };
      "[markdown]" = {
        "editor.defaultFormatter" = "yzhang.markdown-all-in-one";
        "editor.formatOnSave" = true;
        "editor.wordWrap" = "on";
      };
      "[rust]" = {
        "editor.defaultFormatter" = "rust-lang.rust-analyzer";
        "editor.formatOnSave" = true;
      };
      "[python]" = {
        "editor.defaultFormatter" = "ms-python.black-formatter";
        "editor.formatOnSave" = true;
        "editor.codeActionsOnSave" = {
          "source.organizeImports" = "explicit";
        };
      };
      "[c]" = {
        "editor.defaultFormatter" =
          if pkgs.stdenv.isDarwin then
            "jnoortheen.nix-ide"
          else
            "ms-vscode.cpptools";
        "editor.formatOnSave" = true;
      };
      "[cpp]" = {
        "editor.defaultFormatter" =
          if pkgs.stdenv.isDarwin then
            "jnoortheen.nix-ide"
          else
            "ms-vscode.cpptools";
        "editor.formatOnSave" = true;
      };
      "[swift]" = {
        "editor.formatOnSave" = true;
      };
      "[nix]" = {
        "editor.defaultFormatter" = "jnoortheen.nix-ide";
        "editor.formatOnSave" = true;
      };
      "[makefile]" = {
        "editor.insertSpaces" = false;
        "editor.detectIndentation" = false;
      };

      # Workbench settings
      "workbench.startupEditor" = "newUntitledFile";
      "workbench.editor.enablePreview" = false;
      "workbench.editor.enablePreviewFromQuickOpen" = false;
      "workbench.editor.closeOnFileDelete" = true;
      "workbench.editor.highlightModifiedTabs" = true;
      "workbench.editor.limit.enabled" = true;
      "workbench.editor.limit.value" = 10;
      "workbench.iconTheme" = "material-icon-theme";
      "workbench.tree.indent" = 20;
      "workbench.tree.renderIndentGuides" = "always";

      # Debug settings
      "debug.allowBreakpointsEverywhere" = true;
      "debug.inlineValues" = "auto";
      "debug.showInStatusBar" = "always";
      "debug.terminal.clearBeforeReusing" = true;

      # Extension-specific settings
      "gitlens.codeLens.enabled" = true;
      "gitlens.currentLine.enabled" = false;
      "gitlens.blame.format" = "";
      "gitlens.blame.heatmap.enabled" = false;
      "gitlens.blame.highlight.enabled" = false;
      "gitlens.currentLine.format" = "";
      "gitlens.statusBar.format" = "";
      "gitlens.hovers.enabled" = true;
      "gitlens.statusBar.enabled" = false;

      "todo-tree.general.tags" = [
        "BUG"
        "HACK"
        "FIXME"
        "TODO"
        "XXX"
        "[ ]"
        "[x]"
      ];
      "todo-tree.highlights.enabled" = true;

      "errorLens.enabled" = true;
      "errorLens.enabledDiagnosticLevels" = [
        "error"
        "warning"
        "info"
      ];
      "errorLens.fontSize" = "12";

      "bracketPairColorizer.depreciation-notice" = false;

      # Performance settings
      "extensions.autoUpdate" = false;
      "extensions.autoCheckUpdates" = false;
      "telemetry.telemetryLevel" = "off";
      "update.mode" = "none";
      "workbench.settings.enableNaturalLanguageSearch" = false;

      # Explicitly disable rainbow/indent colorization
      "indentRainbow.colors" = [ ];
      "indentRainbow.enabled" = false;
      "editor.guides.indentGuides" = false;
      "editor.renderIndentGuides" = false;

      "editor.showFoldingControls" = "always";
    };
    extensions =
      with pkgs.vscode-extensions;
      [
        # Language Support - Swift & Native Development
        sswg.swift-lang # Swift language support (original extension, still works)
        vadimcn.vscode-lldb # LLDB debugger for Swift, Rust, C/C++

        # Language Support - Python
        ms-python.debugpy
        ms-python.black-formatter
        ms-python.pylint
        ms-python.isort

        # Language Support - Rust
        rust-lang.rust-analyzer
        tamasfe.even-better-toml

        # Language Support - Makefile
        ms-vscode.makefile-tools

        # Language Support - Nix
        jnoortheen.nix-ide

        # Language Support - C/C++
        # Note: ms-vscode.cpptools doesn't support Darwin platforms
      ]
      ++ (
        if pkgs.stdenv.isLinux && pkgs.stdenv.isAarch64 then
          [ ]
        else
          [
            ms-python.python # Python extension not available on aarch64-linux
          ]
      )
      ++ (
        if pkgs.stdenv.isDarwin then
          [ ]
        else
          [
            ms-vscode.cpptools # C/C++ extension for proper formatting
          ]
      )
      ++ [

        # Language Support - TypeScript/JavaScript/Web
        vue.vscode-typescript-vue-plugin # TypeScript support for Vue
        bradlc.vscode-tailwindcss
        esbenp.prettier-vscode
        dbaeumer.vscode-eslint

        # Language Support - JSON
        zainchen.json # JSON language support

        # Language Support - Markdown & Documentation
        yzhang.markdown-all-in-one
        davidanson.vscode-markdownlint
        bierner.markdown-mermaid
        asciidoctor.asciidoctor-vscode

        # Themes & UI
        pkief.material-icon-theme
        ms-vscode.hexeditor
        ms-vscode.live-server
        vscode-icons-team.vscode-icons

        # Git & Version Control
        eamodio.gitlens
        mhutchie.git-graph

        # Web Development & Frameworks
        ecmel.vscode-html-css # HTML/CSS support
        bradgashler.htmltagwrap # HTML tag wrapping
        formulahendry.auto-rename-tag
        formulahendry.auto-close-tag
        christian-kohler.path-intellisense
        christian-kohler.npm-intellisense

        # Testing & Debugging
        ms-vscode.test-adapter-converter
        hbenl.vscode-test-explorer

        # Productivity & Utilities
        ms-vscode.powershell
        streetsidesoftware.code-spell-checker
        gruntfuggly.todo-tree
        alefragnani.bookmarks

        # Docker & Containers
        ms-azuretools.vscode-docker

        # REST API & Testing
        humao.rest-client
      ];
  };
}
