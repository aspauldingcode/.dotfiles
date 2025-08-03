{
  config,
  lib,
  pkgs,
  ...
}: let
  vesktopSettings = {
    minimizeToTray = "on";
    discordBranch = "stable";
    arRPC = "on";
    splashColor = "#${config.colorScheme.palette.base05}";
    splashBackground = "#${config.colorScheme.palette.base00}";
    splashTheming = true;
  };

  vesktopDetailedSettings = {
    autoUpdate = true; # so I don't gotta deal with it.
    autoUpdateNotification = false;
    useQuickCss = false;
    themeLinks = [
      # "https://kraxen72.github.io/rosebox/discord/dist/main.css"
    ];
    enabledThemes = [
      "gruvbox.theme.css"
    ];
    enableReactDevtools = false;
    frameless = false;
    transparent = false;
    winCtrlQ = false;
    disableMinSize = false;
    winNativeTitleBar = false;
    plugins = {
      ChatInputButtonAPI.enabled = false;
      CommandsAPI.enabled = true;
      MemberListDecoratorsAPI.enabled = false;
      MessageAccessoriesAPI.enabled = true;
      MessageDecorationsAPI.enabled = false;
      MessageEventsAPI.enabled = false;
      MessagePopoverAPI.enabled = false;
      MessageUpdaterAPI.enabled = false;
      ServerListAPI.enabled = false;
      UserSettingsAPI.enabled = true;
      AlwaysAnimate.enabled = false;
      AlwaysTrust.enabled = false;
      AnonymiseFileNames.enabled = false;
      AppleMusicRichPresence.enabled = false;
      "WebRichPresence (arRPC)".enabled = false;
      AutomodContext.enabled = false;
      BANger.enabled = false;
      BetterFolders.enabled = false;
      BetterGifAltText.enabled = false;
      BetterGifPicker.enabled = false;
      BetterNotesBox.enabled = false;
      BetterRoleContext.enabled = false;
      BetterRoleDot.enabled = false;
      BetterSessions.enabled = false;
      BetterSettings.enabled = false;
      BetterUploadButton.enabled = false;
      BiggerStreamPreview.enabled = false;
      BlurNSFW.enabled = false;
      CallTimer.enabled = false;
      ClearURLs.enabled = false;
      ClientTheme.enabled = false;
      ColorSighted.enabled = false;
      ConsoleJanitor.enabled = false;
      ConsoleShortcuts.enabled = false;
      CopyEmojiMarkdown.enabled = false;
      CopyUserURLs.enabled = false;
      CrashHandler.enabled = true;
      CtrlEnterSend.enabled = false;
      CustomRPC.enabled = false;
      CustomIdle.enabled = false;
      Dearrow.enabled = false;
      Decor.enabled = false;
      DisableCallIdle.enabled = false;
      DontRoundMyTimestamps.enabled = false;
      EmoteCloner.enabled = false;
      Experiments.enabled = false;
      F8Break.enabled = false;
      FakeNitro.enabled = false;
      FakeProfileThemes.enabled = false;
      FavoriteEmojiFirst.enabled = false;
      FavoriteGifSearch.enabled = false;
      FixCodeblockGap.enabled = false;
      FixSpotifyEmbeds.enabled = false;
      FixYoutubeEmbeds.enabled = false;
      ForceOwnerCrown.enabled = false;
      FriendInvites.enabled = false;
      FriendsSince.enabled = false;
      GameActivityToggle.enabled = false;
      GifPaste.enabled = false;
      GreetStickerPicker.enabled = false;
      HideAttachments.enabled = false;
      iLoveSpam.enabled = false;
      IgnoreActivities.enabled = false;
      ImageLink.enabled = false;
      ImageZoom.enabled = false;
      ImplicitRelationships.enabled = false;
      InvisibleChat.enabled = false;
      KeepCurrentChannel.enabled = false;
      LastFMRichPresence.enabled = false;
      LoadingQuotes.enabled = false;
      MaskedLinkPaste.enabled = false;
      MemberCount.enabled = false;
      MentionAvatars.enabled = false;
      MessageClickActions.enabled = false;
      MessageLatency.enabled = false;
      MessageLinkEmbeds.enabled = false;
      MessageLogger.enabled = false;
      MessageTags.enabled = false;
      MoreCommands.enabled = false;
      MoreKaomoji.enabled = false;
      MoreUserTags.enabled = false;
      Moyai.enabled = false;
      MutualGroupDMs.enabled = false;
      NewGuildSettings.enabled = false;
      NoBlockedMessages.enabled = false;
      NoDefaultHangStatus.enabled = false;
      NoDevtoolsWarning.enabled = false;
      NoF1.enabled = false;
      NoMosaic.enabled = false;
      NoOnboardingDelay.enabled = false;
      NoPendingCount.enabled = false;
      NoProfileThemes.enabled = false;
      NoReplyMention.enabled = false;
      NoScreensharePreview.enabled = false;
      NoServerEmojis.enabled = false;
      NoTypingAnimation.enabled = false;
      NoUnblockToJump.enabled = false;
      NormalizeMessageLinks.enabled = false;
      NotificationVolume.enabled = false;
      NSFWGateBypass.enabled = false;
      OnePingPerDM.enabled = false;
      oneko.enabled = false;
      OpenInApp.enabled = false;
      OverrideForumDefaults.enabled = false;
      PartyMode.enabled = false;
      PauseInvitesForever.enabled = false;
      PermissionFreeWill.enabled = false;
      PermissionsViewer.enabled = false;
      petpet.enabled = false;
      PictureInPicture.enabled = false;
      PinDMs.enabled = false;
      PlainFolderIcon.enabled = false;
      PlatformIndicators.enabled = false;
      PreviewMessage.enabled = false;
      PronounDB.enabled = false;
      QuickMention.enabled = false;
      QuickReply.enabled = false;
      ReactErrorDecoder.enabled = false;
      ReadAllNotificationsButton.enabled = false;
      RelationshipNotifier.enabled = false;
      ReplaceGoogleSearch.enabled = false;
      ReplyTimestamp.enabled = false;
      RevealAllSpoilers.enabled = false;
      ReverseImageSearch.enabled = false;
      ReviewDB.enabled = false;
      RoleColorEverywhere.enabled = false;
      SearchReply.enabled = false;
      SecretRingToneEnabler.enabled = false;
      Summaries.enabled = false;
      SendTimestamps.enabled = false;
      ServerInfo.enabled = false;
      ServerListIndicators.enabled = false;
      ShikiCodeblocks.enabled = false;
      ShowAllMessageButtons.enabled = false;
      ShowAllRoles.enabled = false;
      ShowConnections.enabled = false;
      ShowHiddenChannels.enabled = false;
      ShowHiddenThings.enabled = false;
      ShowMeYourName.enabled = false;
      ShowTimeoutDuration.enabled = false;
      SilentMessageToggle.enabled = false;
      SilentTyping.enabled = false;
      SortFriendRequests.enabled = false;
      SpotifyControls.enabled = false;
      SpotifyCrack.enabled = false;
      SpotifyShareCommands.enabled = false;
      StartupTimings.enabled = false;
      StreamerModeOnStream.enabled = false;
      SuperReactionTweaks.enabled = false;
      TextReplace.enabled = false;
      ThemeAttributes.enabled = false;
      TimeBarAllActivities.enabled = false;
      Translate.enabled = false;
      TypingIndicator.enabled = false;
      TypingTweaks.enabled = false;
      Unindent.enabled = false;
      UnlockedAvatarZoom.enabled = false;
      UnsuppressEmbeds.enabled = false;
      UserVoiceShow.enabled = false;
      USRBG.enabled = false;
      ValidReply.enabled = false;
      ValidUser.enabled = false;
      VoiceChatDoubleClick.enabled = false;
      VcNarrator.enabled = false;
      VencordToolbox.enabled = false;
      ViewIcons.enabled = false;
      ViewRaw.enabled = false;
      VoiceDownload.enabled = false;
      VoiceMessages.enabled = false;
      WebKeybinds.enabled = true;
      WebScreenShareFixes.enabled = true;
      WhoReacted.enabled = false;
      XSOverlay.enabled = false;
      YoutubeAdblock.enabled = false;
      NoTrack = {
        enabled = true;
        disableAnalytics = true;
      };
      WebContextMenus = {
        enabled = true;
        addBack = true;
      };
      Settings = {
        enabled = true;
        settingsLocation = "aboveNitro";
      };
    };
    notifications = {
      timeout = 5000;
      position = "bottom-right";
      useNative = "not-focused";
      logLimit = 50;
    };
    cloud = {
      authenticated = false;
      url = "https://api.vencord.dev/";
      settingsSync = false;
      settingsSyncVersion = 517574327;
    };
  };

  gruvboxTheme = let
    inherit (config.colorScheme) palette;
  in ''
    /**
    * @name Nix-Colors Base16
    * @author aspauldingcode
    * @version 0.1
    * @description A Base16 colorscheme for Discord using nix-colors
    * @website https://github.com/aspauldingcode
    **/

    button[class*=emojiButtonNormal] > div > div {
        filter: grayscale(0.8) hue-rotate(-50deg) brightness(0.8) opacity(100%) !important;
    }

    .container-1QtPKm, .input-125oad {
        border-radius: 14px;
        cursor: pointer;
        background-color: #${palette.base03} !important;
    }

    [data-popout-root],
    html {
      --brand-experiment: #${palette.base0A};
      --brand-experiment-330: #${palette.base07};
      --brand-experiment-360: #${palette.base07};
      --brand-experiment-400: #${palette.base03};
      --brand-experiment-430: #${palette.base07};
      --brand-experiment-460: #${palette.base07};
      --brand-experiment-500: #${palette.base02};
      --brand-experiment-530: #${palette.base06};
      --brand-experiment-560: #${palette.base03};
      --brand-experiment-600: #${palette.base04};
      --brand-experiment-630: #${palette.base04};
      --brand-experiment-660: #${palette.base0D};
      --brand-experiment-700: #${palette.base0D};
      --brand-experiment-730: #${palette.base0D};
      --brand-experiment-760: #${palette.base0D};
      --brand-experiment-800: #${palette.base0D};
      --brand-experiment-830: #${palette.base0D};
      --brand-experiment-860: #${palette.base0D};
      --brand-experiment-900: #${palette.base0D};
    }

    .theme-dark,
    .theme-light {
      --brand-260: #${palette.base0A};
      --brand-500: #${palette.base0A};
      --brand-560: #${palette.base00};
      --primary-300: #${palette.base07};
      --header-primary: #${palette.base07};
      --header-secondary: #${palette.base07};
      --text-normal: #${palette.base05};
      --text-muted: #${palette.base04};
      --text-link: #${palette.base0D};
      --text-link-low-saturation: #${palette.base0C};
      --text-positive: #${palette.base0A};
      --text-warning: #${palette.base08};
      --text-danger: #${palette.base0A};
      --text-brand: #${palette.base0A};
      --background-primary: #${palette.base00};
      --background-secondary: #${palette.base00};
      --background-secondary-alt: #${palette.base00};
      --background-tertiary: #${palette.base00};
      --background-accent: #${palette.base0A};
      --background-floating: #${palette.base00};
      --background-nested-floating: #${palette.base02};
      --background-mobile-primary: #${palette.base00};
      --background-modifier-hover: rgba(${palette.base04}, 0.15);
      --background-modifier-selected: rgba(${palette.base05}, 0.2);
      --background-modifier-accent: rgba(${palette.base04}, 0.26);
      --background-modifier-active: rgba(${palette.base07}, 0.17);
      --info-warning-background: rgba(${palette.base0A}, 0.15);
      --info-warning-foreground: #${palette.base0A};
      --info-warning-text: #${palette.base0A};
      --info-danger-background: rgba(${palette.base08}, 0.15);
      --info-danger-foreground: #${palette.base08};
      --info-danger-text: #${palette.base08};
      --info-help-background: rgba(${palette.base0A}, 0.10);
      --info-help-foreground: #${palette.base0A};
      --info-help-text: #${palette.base07};
      --status-positive-background: #${palette.base0A};
      --status-positive-text: #${palette.base00};
      --status-warning-background: #${palette.base0A};
      --status-warning-text: #${palette.base05};
      --status-danger-background: #${palette.base0A};
      --status-danger-text: #${palette.base00};
      --status-danger: #${palette.base08};
      --status-positive: #${palette.base0B};
      --status-warning: #${palette.base0A};
      --black-500: #${palette.base00};
      --green-360: #${palette.base0B};
      --primary-400: #${palette.base04};
      --white-500: #${palette.base07};
      --guild-boosting-pink: #${palette.base0E};
      --premium-perk-yellow: #${palette.base0A};
      --premium-perk-purple: #${palette.base0E};
      --premium-perk-dark-blue: #${palette.base0D};
      --premium-perk-light-blue: #${palette.base0D};
      --premium-perk-blue: #${palette.base0D};
      --premium-perk-green: #${palette.base0B};
      --premium-perk-pink: #${palette.base0E};
      --premium-perk-orange: #${palette.base09};
      --button-danger-background: #${palette.base0A};
      --button-danger-background-hover: #${palette.base0A};
      --button-danger-background-active: #${palette.base07};
      --button-danger-background-disabled: rgba(${palette.base0A}, 0.40);
      --button-positive-background: #${palette.base0A};
      --button-positive-background-hover: #${palette.base0A};
      --button-positive-background-active: #${palette.base07};
      --button-positive-background-disabled: rgba(${palette.base0A}, 0.40);
      --button-secondary-background: #${palette.base02};
      --button-secondary-background-hover: #${palette.base03};
      --button-secondary-background-active: #${palette.base04};
      --button-secondary-background-disabled: #${palette.base03};
      --button-outline-danger-text: #${palette.base08};
      --button-outline-danger-border: #${palette.base08};
      --button-outline-danger-background: transparent;
      --button-outline-danger-background-hover: #${palette.base08};
      --button-outline-danger-text-hover: #${palette.base00};
      --button-outline-danger-border-hover: #${palette.base08};
      --button-outline-danger-background-active: #${palette.base08};
      --button-outline-danger-text-active: #${palette.base08};
      --button-outline-danger-border-active: #${palette.base08};
      --button-outline-positive-text: #${palette.base05};
      --button-outline-positive-border: #${palette.base0A};
      --button-outline-positive-background: transparent;
      --button-outline-positive-background-hover: #${palette.base0A};
      --button-outline-positive-text-hover: #${palette.base00};
      --button-outline-positive-border-hover: #${palette.base0A};
      --button-outline-positive-background-active: #${palette.base0A};
      --button-outline-positive-text-active: #${palette.base00};
      --button-outline-positive-border-active: #${palette.base0A};
      --button-outline-brand-text: #${palette.base05};
      --button-outline-brand-border: #${palette.base0A};
      --button-outline-brand-background: transparent;
      --button-outline-brand-background-hover: #${palette.base0A};
      --button-outline-brand-text-hover: #${palette.base00};
      --button-outline-brand-border-hover: #${palette.base0A};
      --button-outline-brand-background-active: #${palette.base0A};
      --button-outline-brand-text-active: #${palette.base00};
      --button-outline-brand-border-active: #${palette.base0A};
      --button-outline-primary-text: #${palette.base05};
      --button-outline-primary-border: #${palette.base0A};
      --button-outline-primary-background: transparent;
      --button-outline-primary-background-hover: #${palette.base0A};
      --button-outline-primary-text-hover: #${palette.base00};
      --button-outline-primary-border-hover: #${palette.base0A};
      --button-outline-primary-background-active: #${palette.base0A};
      --button-outline-primary-text-active: #${palette.base00};
      --button-outline-primary-border-active: #${palette.base0A};
      --modal-background: #${palette.base00};
      --scrollbar-thin-thumb: #${palette.base02};
      --scrollbar-thin-track: transparent;
      --scrollbar-auto-thumb: #${palette.base02};
      --scrollbar-auto-track: transparent;
      --scrollbar-auto-scrollbar-color-thumb: #${palette.base02};
      --scrollbar-auto-scrollbar-color-track: #${palette.base02};
      --input-background: #${palette.base00};
      --input-placeholder-text: #${palette.base04};
      --control-brand-foreground: #${palette.base0A};
      --mention-foreground: #${palette.base06};
      --mention-background: rgba(${palette.base04}, 0.3);
      --background-mentioned: rgba(${palette.base0A}, 0.1);
      --background-mentioned-hover: rgba(${palette.base0A}, 0.2);
      --background-message-hover: rgba(${palette.base03}, 0.25);
      --background-message-highlight: rgba(${palette.base03}, 0.4);
      --channels-default: #${palette.base05};
      --channel-icon: #${palette.base06};
      --channel-text-area-placeholder: #${palette.base07};

      /* message input bar */
      --channeltextarea-background: #${palette.base00};

      --textbox-markdown-syntax: #${palette.base03};
      --deprecated-card-bg: #${palette.base00};
      --deprecated-card-editable-bg: #${palette.base00};
      --deprecated-text-input-bg: #${palette.base00};
      --deprecated-text-input-border: #${palette.base03};
      --focus-primary: #${palette.base0C};
      --interactive-normal: #${palette.base04};
      --interactive-muted: rgba(${palette.base04}, 0.3);
      --interactive-hover: #${palette.base05};
      --interactive-active: #${palette.base07};

      --primary-200: #${palette.base06};
    }
    .theme-dark [class*=disabledPointerEvents],
    .theme-light [class*=disabledPointerEvents] {
      --background-floating: #${palette.base00};
      --background-tertiary: #${palette.base00};
    }
    .theme-dark [class*=disabledPointerEvents] svg[class|=activityIcon],
    .theme-light [class*=disabledPointerEvents] svg[class|=activityIcon] {
      color: #${palette.base0A};
    }

    ::selection {
      background-color: #${palette.base03};
    }

    [class*=staffBadge-] {
      background-image: url("data:image/svg+xml,%3Csvg fill='none' height='24' viewBox='0 0 24 24' width='24' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='%23232634'%3E%3Cpath d='m5.92127 6.03526s.22115-.33086.31286-.47743c.09172-.14657-.23743-.49286-.36514-.60257-.12772-.10971-.32914-.05486-.32914-.05486-1.60715.71229-2.41115 2.17372-2.52086 2.466-.10972.29229.27943.61115.56657.76715.132.072.342-.08743.47143-.20572l.04371-.04457.06772-.06857.00085-.00086 4.37229 4.35517.59743-.5975 1.09801-1.098-4.32173-4.43224z'/%3E%3Cpath d='m16.2505 10.6294.2306-.2194 2.0717 2.052c.0146.0129.03.018.0437.018.0395 0 .072-.036.072-.036s2.2937-2.2757 2.3015-2.2834c.0677-.0669 0-.1037 0-.1037l-1.7692-1.78119-.0026.00258-.2425-.23743.1354-.13029.2897.03343-.0548-.384.0728-.07371-.1088-.55372c-.378-.53571-1.4135-1.39371-1.4135-1.39371l-.5417-.09772-.0548.07286-.408-.06086.0394.348.0257.02572-.1209.12171-.6685-.654s-3.8795-2.10686-4.086-2.20457c-.1166-.054-.2023-.09-.2846-.09-.0634 0-.1251.02143-.1963.072-.1646.11571-.0677.34886-.0677.34886l2.412 4.45714.4826.47829-.1509.15085-.0557.05572-.3857-.05315.0591.38229-.1114.11143-.0197-.01972c-.018-.018-.0429-.02742-.0669-.02742s-.048.00942-.0668.02742c-.0369.03686-.0369.09686 0 .13372l.0197.01971-.0532.054-.0137-.01457c-.0188-.018-.0428-.02743-.0668-.02743-.0249 0-.0489.00943-.0669.02743-.0368.03686-.0368.09686 0 .13372l.0146.01457-1.0149 1.02004-.0231-.0232c-.0189-.018-.0429-.0274-.0669-.0274s-.048.0094-.0668.0274c-.0369.0369-.0369.0969 0 .1337l.024.0232-.054.054-.018-.0172c-.018-.0188-.0429-.0283-.066-.0283-.0249 0-.0489.0095-.0677.0283-.036.0369-.036.096 0 .1329l.018.018-.132.1337-.018.1697.0694.0712-.0017.0008-.084.0857-5.47632 5.4755-.07114-.0592-.22714.0326-.12858.1303-.00857-.0086c-.01885-.0189-.04285-.0283-.06685-.0283s-.04886.0094-.06686.0283c-.03686.0369-.03686.096 0 .1329l.01028.0102-.05314.0549-.00514-.0051c-.018-.0189-.04286-.0283-.06686-.0283s-.048.0094-.06686.0283c-.036.0368-.036.096 0 .1328l.006.0069-1.002 1.0191-.02057-.0206c-.01885-.0188-.042-.0274-.06685-.0274-.024 0-.048.0086-.06686.0274-.03686.0369-.03686.0969 0 .1338l.02228.0214-.05314.054-.01628-.0163c-.01886-.018-.04286-.0274-.06772-.0274-.02314 0-.048.0094-.066.0274-.03686.0369-.03686.0969 0 .1337l.01714.018-.07457.0763-.38828-.0694.02914.4337-.12257.1251.10628.5846s.16286.5091.498.8469c.32486.3274.82029.4842.84172.5005l.55971.0977.138-.1354.38572.0626-.06343-.3814.11743-.1149.054.054c.018.018.042.0274.066.0274s.04885-.0094.06685-.0274c.03686-.0377.03686-.0969 0-.1337l-.05314-.0532.05486-.0531.04628.0463c.018.0188.04286.0283.06686.0283s.048-.0095.06686-.0283c.03686-.0369.03686-.096 0-.1329l-.04543-.0463 1.01743-1.0037.04457.0446c.018.0189.04286.0274.06686.0274s.048-.0085.06685-.0274c.036-.0369.036-.0969 0-.1337l-.04371-.0429.054-.054.03771.0377c.018.018.042.0275.066.0275.02486 0 .04886-.0095.06686-.0275.03686-.0368.03686-.0968 0-.1337l-.03686-.0368.114-.1115.04115-.2442-.06086-.0609.00086-.0009.11057-.1097 5.43946-5.4411-.0026-.0052.1063.1098.1706-.0189.1534-.1543.0248.0249c.0189.018.0429.0274.0669.0274s.0489-.0094.0669-.0274c.0368-.0369.0368-.0969 0-.1337l-.0249-.0249.054-.0531.0189.0188c.018.018.042.0274.0668.0274.024 0 .048-.0094.066-.0274.0369-.0368.0369-.0968 0-.1337l-.0188-.0197 1.0165-1.0183.0266.0266c.018.018.042.0274.066.0274.0249 0 .0489-.0094.0669-.0274.0368-.0369.0368-.0969 0-.1337l-.0266-.0266.054-.054.0206.0214c.0188.018.0428.0274.0668.0274s.048-.0094.0669-.0274c.0368-.0377.0368-.0968 0-.1337l-.0206-.0214.1131-.1132.378.0592z'/%3E%3Cpath d='m17.0057 16.7793-2.4111-1.8274-.4294-.4423-1.6637 1.6637.4183.3995 1.5711 2.3562 2.1188 2.3203 2.4421-2.2783z'/%3E%3C/g%3E%3C/svg%3E") !important;
    }

    [class*=permissionCheckmark-] {
      background-image: url("data:image/svg+xml,%3Csvg height='18' width='18' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cpath d='m0 0h18v18h-18z'/%3E%3Cpath d='m14.25 14.25h-10.5v-10.5h7.5v-1.5h-7.5c-.8325 0-1.5.6675-1.5 1.5v10.5c0 .8284271.67157288 1.5 1.5 1.5h10.5c.8284271 0 1.5-.6715729 1.5-1.5v-6h-1.5zm-7.5675-6.94-1.0575 1.065 3.375 3.375 7.5-7.5-1.0575-1.065-6.4425 6.4425z' fill='%23b8bb26'/%3E%3C/g%3E%3C/svg%3E") !important;
    }

    [class*=removeKeybind-] {
      background-image: url('data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="18" height="18"%3E%3Cg fill="none" fill-rule="evenodd"%3E%3Cpath d="M0 0h18v18H0"/%3E%3Cpath fill="%23232634" d="M14.25 4.8075L13.1925 3.75 9 7.9425 4.8075 3.75 3.75 4.8075 7.9425 9 3.75 13.1925 4.8075 14.25 9 10.0575l4.1925 4.1925 1.0575-1.0575L10.0575 9"/%3E%3C/g%3E%3C/svg%3E') !important;
    }

    [class*=removeGame-] {
      background-image: url("data:image/svg+xml,%3Csvg height='18' viewBox='0 0 18 18' width='18' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cpath d='m14.25 4.808-1.057-1.058-4.193 4.192-4.192-4.192-1.058 1.058 4.192 4.192-4.192 4.193 1.058 1.057 4.192-4.193 4.193 4.193 1.057-1.057-4.193-4.193z' fill-rule='nonzero' fill='%23cc241d'/%3E%3Cpath d='m0 0h18v18h-18z'/%3E%3C/g%3E%3C/svg%3E") !important;
    }

    [class*=emojiRemove-] {
      background-image: url("data:image/svg+xml,%3Csvg height='18' viewBox='0 0 18 18' width='18' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cpath d='m14.25 4.808-1.057-1.058-4.193 4.192-4.192-4.192-1.058 1.058 4.192 4.192-4.192 4.193 1.058 1.057 4.192-4.193 4.193 4.193 1.057-1.057-4.193-4.193z' fill-rule='nonzero' fill='%23cc241d'/%3E%3Cpath d='m0 0h18v18h-18z'/%3E%3C/g%3E%3C/svg%3E") !important;
    }

    [class*=lockIcon-] {
      content: url("data:image/svg+xml,%3Csvg height='14' viewBox='0 0 10 14' width='10' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='m553 515h-6v-1c0-1.654 1.346-3 3-3s3 1.346 3 3zm-4 6h2v-4h-2zm1-12c-2.762 0-5 2.238-5 5v1 4 2c0 1.104.896 2 2 2h6c1.104 0 2-.896 2-2v-2-4-1c0-2.762-2.238-5-5-5z' fill='%23b8bb26' fill-rule='evenodd' transform='translate(-545 -509)'/%3E%3C/svg%3E") !important;
    }

    .theme-dark svg[class*=noItemsIcon-],
    .theme-light svg[class*=noItemsIcon-] {
      background-color: #${palette.base03};
    }

    .theme-dark svg[class*=tier1ProfilePerk-],
    .theme-light svg[class*=tier1ProfilePerk-] {
      color: #${palette.base0D} !important;
    }

    .theme-dark svg[class*=tier1BoostPerk-],
    .theme-light svg[class*=tier1BoostPerk-] {
      color: #${palette.base0E} !important;
    }

    .theme-dark svg[class*=tier1CustomEmojiPerk-],
    .theme-light svg[class*=tier1CustomEmojiPerk-] {
      color: #${palette.base09} !important;
    }

    .theme-dark svg[class*=tier1UploadPerk-],
    .theme-light svg[class*=tier1UploadPerk-] {
      color: #${palette.base0D} !important;
    }

    .theme-dark svg[class*=tier1StreamPerk-],
    .theme-light svg[class*=tier1StreamPerk-] {
      color: #${palette.base0B} !important;
    }

    .theme-dark svg[class*=guildBoostingIcon-],
    .theme-light svg[class*=guildBoostingIcon-] {
      color: #${palette.base0E} !important;
    }

    .theme-dark svg[class*=guildSubscriptionSlotIcon-],
    .theme-light svg[class*=guildSubscriptionSlotIcon-] {
      color: #${palette.base0E} !important;
    }

    .theme-dark svg[class*=guildSubscriberCountIcon-],
    .theme-light svg[class*=guildSubscriberCountIcon-] {
      color: #${palette.base0E} !important;
    }

    .theme-dark svg[class*=gemWithLabel-],
    .theme-light svg[class*=gemWithLabel-] {
      color: #${palette.base0E} !important;
    }

    .theme-dark svg[class*=gemWithoutLabel-],
    .theme-light svg[class*=gemWithoutLabel-] {
      color: #${palette.base04} !important;
    }

    .theme-dark svg[class*=memberBadgeIcon-],
    .theme-light svg[class*=memberBadgeIcon-] {
      color: #${palette.base0E} !important;
    }

    .theme-dark svg[class*=stickerIcon-],
    .theme-light svg[class*=stickerIcon-] {
      color: #${palette.base0E} !important;
    }

    .theme-dark svg[class*=audioQualityIcon-],
    .theme-light svg[class*=audioQualityIcon-] {
      color: #${palette.base0D} !important;
    }

    .theme-dark svg[class*=uploadSizeIcon-],
    .theme-light svg[class*=uploadSizeIcon-] {
      color: #${palette.base0E} !important;
    }

    .theme-dark svg[class*=threadIcon-],
    .theme-light svg[class*=threadIcon-] {
      color: #${palette.base0C} !important;
    }

    .theme-dark svg[class*=premiumIcon-],
    .theme-light svg[class*=premiumIcon-] {
      color: #${palette.base0E} !important;
    }

    .theme-dark svg[class*=gameIcon-],
    .theme-light svg[class*=gameIcon-] {
      color: #${palette.base07} !important;
    }

    .theme-dark svg[class*=tierMarkerLabelPlusIcon-],
    .theme-light svg[class*=tierMarkerLabelPlusIcon-] {
      color: #${palette.base0E} !important;
    }

    .theme-dark svg[class*=currentTierIcon-],
    .theme-light svg[class*=currentTierIcon-] {
      color: #${palette.base0E} !important;
    }

    .theme-dark svg[class*=tier3Icon-],
    .theme-light svg[class*=tier3Icon-] {
      color: #${palette.base0E} !important;
    }

    .theme-dark svg[class*=searchIcon-],
    .theme-light svg[class*=searchIcon-] {
      color: #${palette.base05} !important;
    }

    .theme-dark svg[class*=upsellIcon-],
    .theme-light svg[class*=upsellIcon-] {
      color: #${palette.base0E} !important;
    }

    [class*=lookFilled-][class*=colorBrand-], [class*=lookFilled-][class*=colorBrandNew-], [class*=lookFilled-][class*=colorLink-], [class*=lookFilled-][class*=colorYellow-], [class*=lookFilled-][class*=colorRed-], [class*=lookFilled-][class*=colorGreen-] {
      color: #${palette.base00};
    }
    [class*=lookFilled-][class*=colorBrand-] svg[class|=premiumIcon], [class*=lookFilled-][class*=colorBrandNew-] svg[class|=premiumIcon], [class*=lookFilled-][class*=colorLink-] svg[class|=premiumIcon], [class*=lookFilled-][class*=colorYellow-] svg[class|=premiumIcon], [class*=lookFilled-][class*=colorRed-] svg[class|=premiumIcon], [class*=lookFilled-][class*=colorGreen-] svg[class|=premiumIcon] {
      color: #${palette.base0E};
    }
    [class*=lookFilled-][class*=colorBrand-] [class*=spinnerItem-], [class*=lookFilled-][class*=colorBrandNew-] [class*=spinnerItem-], [class*=lookFilled-][class*=colorLink-] [class*=spinnerItem-], [class*=lookFilled-][class*=colorYellow-] [class*=spinnerItem-], [class*=lookFilled-][class*=colorRed-] [class*=spinnerItem-], [class*=lookFilled-][class*=colorGreen-] [class*=spinnerItem-] {
      background-color: #${palette.base00};
    }
    [class*=lookFilled-][class*=colorBrand-] [class*=defaultColor-], [class*=lookFilled-][class*=colorBrandNew-] [class*=defaultColor-], [class*=lookFilled-][class*=colorLink-] [class*=defaultColor-], [class*=lookFilled-][class*=colorYellow-] [class*=defaultColor-], [class*=lookFilled-][class*=colorRed-] [class*=defaultColor-], [class*=lookFilled-][class*=colorGreen-] [class*=defaultColor-] {
      color: #${palette.base07};
    }
    [class*=lookFilled-][class*=colorPrimary-] {
      color: #${palette.base07};
    }

    div[class|=actionButtons] [class|=button][class*=buttonColor-],
    div[class|=actionButtons] [class|=button] [class*=buttonColor-] {
      background-color: #${palette.base02};
    }
    div[class|=actionButtons] [class|=button][class*=buttonColor-][class*=buttonActive-],
    div[class|=actionButtons] [class|=button] [class*=buttonColor-][class*=buttonActive-] {
      background-color: #${palette.base0A};
      color: #${palette.base00};
    }
    div[class|=actionButtons] [class|=button][class*=buttonColor-][class*=buttonActive-] [class*=buttonContents-],
    div[class|=actionButtons] [class|=button] [class*=buttonColor-][class*=buttonActive-] [class*=buttonContents-] {
      color: #${palette.base00};
    }
    div[class|=actionButtons] [class|=button][class*=buttonColor-][class*=buttonActive-] [class*=buttonContents-] svg,
    div[class|=actionButtons] [class|=button] [class*=buttonColor-][class*=buttonActive-] [class*=buttonContents-] svg {
      color: #${palette.base00};
    }

    [class*=lookInverted-][class*=colorBrand-] {
      color: #${palette.base0D};
    }
    [class*=lookInverted-][class*=colorBrand-] svg[class|=premiumIcon] {
      color: #${palette.base0E};
    }

    .theme-dark [class*=lookLink-][class*=colorPrimary-],
    .theme-light [class*=lookLink-][class*=colorPrimary-] {
      color: #${palette.base05};
    }
    .theme-dark [class*=lookFilled-][class*=colorTransparent-],
    .theme-light [class*=lookFilled-][class*=colorTransparent-] {
      color: #${palette.base05};
      background-color: #${palette.base02};
    }

    div[class*=button-][class*=dangerous-]:hover {
      color: #${palette.base08};
    }

    div[role=radio][class*=selected] {
      color: #${palette.base00};
    }
    div[role=radio][class*=selected][class*=allow] {
      background-color: #${palette.base0B};
    }

    [class*=container-][style*="background-color: var(--green-360)"] {
      --green-360: #${palette.base0B};
      background-color: #${palette.base0B} !important;
    }

    [class*=container-][style*="background-color: var(--primary-400)"],
    [class*=container-][style*="background-color: rgb(${palette.base03})"] {
      background-color: #${palette.base03} !important;
    }

    .vc-spotify-button-row .vc-spotify-button.vc-spotify-shuffle-on, .vc-spotify-button-row .vc-spotify-button.vc-spotify-repeat-context, .vc-spotify-button-row .vc-spotify-button.vc-spotify-repeat-track {
      color: var(--interactive-normal);
    }
    .vc-spotify-button-row .vc-spotify-button.vc-spotify-repeat-off, .vc-spotify-button-row .vc-spotify-button.vc-spotify-shuffle-off {
      color: var(--text-muted);
    }

    [class*=topGuildEmojiBadge-] {
      background: linear-gradient(268.26deg, #${palette.base09}, #${palette.base0E} 102.45%);
    }
    [class*=topGuildEmojiBadge-] * {
      color: #${palette.base00} !important;
    }

    [class*=newlyAddedBadge-] {
      background: linear-gradient(268.26deg, #${palette.base0C}, #${palette.base0B} 102.45%);
    }
    [class*=newlyAddedBadge-] * {
      color: #${palette.base00} !important;
    }

    [class*=lookFilled-] [class*=premiumSubscribeButton-] > [class*=premiumIcon-] {
      color: #${palette.base00} !important;
    }

    div[class|=sidebarRegion] div[class|=serverBoostTabItem] svg[class|=icon] {
      fill: #${palette.base0E} !important;
    }
    div[class|=sidebarRegion] div[class|=serverBoostTabItem][class*=selected-] {
      background-color: #${palette.base02} !important;
      color: #${palette.base07} !important;
    }
    div[class|=sidebarRegion] div[class|=serverBoostTabItem][class*=selected-] svg[class|=icon] {
      fill: #${palette.base07} !important;
    }
    div[class|=sidebarRegion] div[class|=premiumTab] > div > svg > path {
      fill: #${palette.base0E};
    }
    div[class|=sidebarRegion] div[class|=premiumTab] > div[class*=selected] {
      color: #${palette.base00};
    }
    div[class|=sidebarRegion] div[class|=premiumTab] > div[class*=selected] svg > path {
      fill: #${palette.base00};
    }
    div[class|=sidebarRegion] div[class*=tabBarItemContainer-] [class*=textBadge-] {
      color: #${palette.base00};
    }
    div[class|=sidebarRegion] div[class*=tabBarItemContainer-] [class*=textBadge-][style*="background-color: var(--brand-500);"] {
      background-color: #${palette.base0D} !important;
    }

    div[class|=contentRegion] div[class*=noticeRegion-] div[style="background-color: #${palette.base00};"] {
      background-color: #${palette.base00} !important;
    }
    div[class|=contentRegion] [class|=bar],
    div[class|=contentRegion] [class|=markDash] {
      background: #${palette.base02};
    }
    div[class|=contentRegion] [id="privacy-&-safety-tab"] div[class|=radioBar][style*="hsl(139,"] {
      border-color: #${palette.base0B};
    }
    div[class|=contentRegion] [id="privacy-&-safety-tab"] div[class|=radioBar][style*="hsl(37,"] {
      border-color: #${palette.base09};
    }
    div[class|=contentRegion] [id="privacy-&-safety-tab"] div[class|=radioBar][style*="hsl(359,"] {
      border-color: #${palette.base08};
    }
    div[class|=contentRegion] [id="privacy-&-safety-tab"] div[class*=betaTagIcon] {
      background-color: #${palette.base0A} !important;
      color: #${palette.base00};
    }
    div[class|=contentRegion] #accessibility-tab button[class*=colorBrandNew] {
      background-color: #${palette.base0D};
    }
    div[class|=contentRegion] #keybinds-tab span[class*=key] {
      color: #${palette.base00};
    }
    div[class|=contentRegion] #keybinds-tab span[class*=key] g {
      fill: #${palette.base00};
    }
    div[class|=contentRegion] #nitro-server-boost-tab circle[class|=circleProgress] {
      color: #${palette.base0E};
    }
    div[class|=contentRegion] #nitro-server-boost-tab div[class*=gemIndicatorContainer-] {
      background-color: #${palette.base01};
    }
    div[class|=contentRegion] #nitro-server-boost-tab div[class*=gemIndicatorContainer-] div[class|=tierLabel] {
      color: #${palette.base05};
    }
    div[class|=contentRegion] #nitro-server-boost-tab button[class*=lookInverted-] {
      color: #${palette.base00};
      background-color: #${palette.base05};
    }
    div[class|=contentRegion] #nitro-server-boost-tab button[class*=lookInverted-]:hover {
      background-color: #${palette.base05};
    }
    div[class|=contentRegion] #nitro-server-boost-tab div[class*=card-],
    div[class|=contentRegion] #nitro-server-boost-tab h3[class*=price-] {
      color: #${palette.base05} !important;
    }
    div[class|=contentRegion] #subscriptions-tab [class|=sectionAccountCredit],
    div[class|=contentRegion] #subscriptions-tab [class|=subscriptionDetails] {
      border-color: var(--background-modifier-accent);
    }
    div[class|=contentRegion] #library-inventory-tab div[class|=promotionIcon] {
      background-color: #${palette.base00};
    }
    div[class|=contentRegion] #discord-nitro-tab button[class*=buttonWhite] {
      color: #${palette.base07} !important;
      border-color: #${palette.base07} !important;
    }
    div[class|=contentRegion] #discord-nitro-tab h2 {
      color: #${palette.base07} !important;
    }
    div[class|=contentRegion] #discord-nitro-tab svg[class*=sparkleStar-] {
      color: #${palette.base07};
    }
    div[class|=contentRegion] #discord-nitro-tab div[class*=description-] {
      color: #${palette.base07} !important;
    }
    div[class|=contentRegion] #discord-nitro-tab div[class*=card-] {
      color: #${palette.base07};
    }
    div[class|=contentRegion] #discord-nitro-tab button[class*=lookInverted-] {
      color: #${palette.base00};
      background-color: #${palette.base07};
    }
    div[class|=contentRegion] #discord-nitro-tab button[class*=lookInverted-]:hover {
      background-color: #${palette.base07};
    }
    div[class|=contentRegion] #billing-tab div[class*=subtext] {
      color: #${palette.base05};
    }
    div[class|=contentRegion] #billing-tab [class*=Divider] {
      border-color: var(--background-modifier-accent);
    }
    div[class|=contentRegion] #billing-tab div[class|=defaultIndicator] {
      color: #${palette.base07};
      background-color: #${palette.base03};
    }
    div[class|=contentRegion] #billing-tab div[class*=summaryInfo],
    div[class|=contentRegion] #billing-tab [class|=paymentHeader] {
      color: #${palette.base07};
      border-color: var(--background-modifier-accent);
    }
    div[class|=contentRegion] #billing-tab div[class|=premiumIndicator] {
      color: #${palette.base00};
    }
    div[class|=contentRegion] #billing-tab div[class|=paymentPane],
    div[class|=contentRegion] #billing-tab div[class*=paginator-],
    div[class|=contentRegion] #billing-tab div[class*=payment-] {
      background-color: #${palette.base00};
      color: #${palette.base07};
    }
    div[class|=contentRegion] #billing-tab div[class|=expandedInfo] {
      background-color: #${palette.base00};
    }
    div[class|=contentRegion] #billing-tab [class*=paymentText-] {
      color: #${palette.base06};
    }
    div[class|=contentRegion] #billing-tab div[class|=codeRedemptionRedirect] {
      background-color: #${palette.base00};
      color: #${palette.base06};
      border-color: #${palette.base02};
    }
    div[class|=contentRegion] [id="voice-&-video-tab"] div[class|=backgroundOptionRing] {
      border-color: #${palette.base0D};
    }
    div[class|=contentRegion] #notifications-tab button[class*=marketingUnsubscribeButton-] {
      color: #${palette.base05};
    }
    div[class|=contentRegion] #game-activity-tab div[class*=nowPlayingAdd-],
    div[class|=contentRegion] #game-activity-tab div[class*=lastPlayed-],
    div[class|=contentRegion] #game-activity-tab div[class*=overlayStatusText-] {
      color: var(--text-muted);
    }
    div[class|=contentRegion] #game-activity-tab div[class*=activeGame-][class*=nowPlaying] * {
      color: #${palette.base00};
    }
    div[class|=contentRegion] #game-activity-tab div[class*=activeGame-][class*=nowPlaying] * svg > g > path {
      fill: #${palette.base00};
    }
    div[class|=contentRegion] #game-activity-tab input[class|=gameName] {
      color: #${palette.base07};
    }
    div[class|=contentRegion] #game-activity-tab input[class*=gameNameInput-]:hover, div[class|=contentRegion] #game-activity-tab input[class*=gameNameInput-]:focus {
      background-color: #${palette.base01};
      border-color: #${palette.base00};
      color: #${palette.base07};
    }
    div[class|=contentRegion] #game-activity-tab div[class*=game-] {
      -webkit-box-shadow: 0 1px 0 0 var(--background-modifier-accent);
      box-shadow: 0 1px 0 0 var(--background-modifier-accent);
    }
    div[class|=contentRegion] #game-activity-tab div[class*=removeGame-] {
      background-color: #${palette.base02};
    }
    div[class|=contentRegion] #emoji-tab div[class*=emojiRemove-] {
      background-color: #${palette.base02};
    }
    div[class|=contentRegion] section[class|=inputSensitivityToggle] div[class*=speaking-] {
      background: #${palette.base0B} !important;
    }
    div[class|=contentRegion] div[class*=reactionMe-] {
      background-color: #${palette.base02} !important;
    }
    div[class|=contentRegion] div[class|=control] > div[class*=checked-],
    div[class|=contentRegion] div[class|=sensitivity] div[class*=checked-],
    div[class|=contentRegion] div[style*="background-color: hsl(139, calc(var(--saturation-factor, 1) * 47.3%), 43.9%)"] {
      background-color: #${palette.base0B} !important;
    }
    div[class|=contentRegion] div[class|=control] > div[style*="background-color: hsl(218, calc(var(--saturation-factor, 1) * 4.6%), 46.9%)"] {
      background-color: #${palette.base03} !important;
    }
    div[class|=contentRegion] div[class|=control] svg[class|=slider] > svg > path {
      fill: #${palette.base0B} !important;
    }
    div[class|=contentRegion] #guild_premium-tab [class*=tierAccomplished-],
    div[class|=contentRegion] #guild_premium-tab [class*=tierCurrent-],
    div[class|=contentRegion] #guild_premium-tab [class*=tierFirst-] {
      background: #${palette.base0E};
    }
    div[class|=contentRegion] #guild_premium-tab [class*=tierInProgress-] {
      background-color: #${palette.base02};
    }
    div[class|=contentRegion] #guild_premium-tab div[class|=progressWithSubscriptions] > svg > g > rect:first-child {
      color: #${palette.base00};
    }
    div[class|=contentRegion] #guild_premium-tab div[class|=progressWithSubscriptions] > svg > g > rect:nth-child(2) {
      color: #${palette.base0E};
    }
    div[class|=contentRegion] #guild_premium-tab div[class|=tierHeaderUnlocked],
    div[class|=contentRegion] #guild_premium-tab div[class|=tierHeaderLocked] {
      background-color: #${palette.base00};
      color: #${palette.base05};
    }
    div[class|=contentRegion] #guild_premium-tab div[class|=tierHeaderUnlocked] div[class|=tierUnlocked],
    div[class|=contentRegion] #guild_premium-tab div[class|=tierHeaderLocked] div[class|=tierUnlocked] {
      background-image: linear-gradient(90deg, #${palette.base0D}, #${palette.base0E});
      color: #${palette.base00};
      font-weight: 600;
    }
    div[class|=contentRegion] #guild_premium-tab div[class|=tierHeaderUnlocked] svg[class|=tierIcon],
    div[class|=contentRegion] #guild_premium-tab div[class|=tierHeaderLocked] svg[class|=tierIcon] {
      color: #${palette.base0E};
    }
    div[class|=contentRegion] #guild_premium-tab div[class|=tierHeaderUnlocked] svg[class*=tierIconLocked-],
    div[class|=contentRegion] #guild_premium-tab div[class|=tierHeaderLocked] svg[class*=tierIconLocked-] {
      color: #${palette.base05};
    }
    div[class|=contentRegion] #guild_premium-tab div[class|=tierHeaderUnlocked] svg[class|=tierLock],
    div[class|=contentRegion] #guild_premium-tab div[class|=tierHeaderLocked] svg[class|=tierLock] {
      color: #${palette.base04};
    }
    div[class|=contentRegion] #guild_premium-tab div[class|=tierBody] {
      color: #${palette.base07};
      background-color: #${palette.base00};
    }
    div[class|=contentRegion] svg[class|=activeCircle] {
      color: #${palette.base00};
      background-color: #${palette.base0B};
    }
    div[class|=contentRegion] #discovery-tab div[class*=checklistIcon] svg[viewBox="0 0 14 14"] path {
      fill: #${palette.base08};
    }
    div[class|=contentRegion] #discovery-tab div[class*=checklistIcon] svg[viewBox="0 0 20 20"] path {
      fill: #${palette.base09};
    }
    div[class|=contentRegion] #guild_templates-tab svg[class*=descriptionIcon][viewBox="0 0 24 24"] path {
      fill: #${palette.base0B};
    }
    div[class|=contentRegion] #guild_templates-tab svg[class*=descriptionIcon][viewBox="0 0 14 14"] path {
      fill: #${palette.base08};
    }
    div[class|=contentRegion] #guild_templates-tab svg[class*=descriptionIcon] circle {
      fill: #${palette.base00};
    }
    div[class|=contentRegion] #stickers-tab div[class*=tierHeaderContent] {
      background-color: #${palette.base00};
    }
    div[class|=contentRegion] #stickers-tab div[class*=tierBody] {
      background-color: #${palette.base00};
    }
    div[class|=contentRegion] #roles-tab div[class*=previewContainer-] .theme-light img[class*=roleIcon-] {
      content: "data:image/svg+xml,%3Csvg width='20' height='20' viewBox='0 0 20 20' fill='none' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath fill-rule='evenodd' clip-rule='evenodd' d='M11.0749 1.66667H4.99996C3.15901 1.66667 1.66663 3.15906 1.66663 5.00001V15C1.66663 16.841 3.15901 18.3333 4.99996 18.3333H15C16.8409 18.3333 18.3333 16.841 18.3333 15V8.92511C17.8052 9.08227 17.2458 9.16667 16.6666 9.16667C13.445 9.16667 10.8333 6.555 10.8333 3.33334C10.8333 2.75419 10.9177 2.19476 11.0749 1.66667ZM6.66663 5.00001C7.58596 5.00001 8.33329 5.74601 8.33329 6.66667C8.33329 7.58801 7.58596 8.33334 6.66663 8.33334C5.74529 8.33334 4.99996 7.58801 4.99996 6.66667C4.99996 5.74601 5.74529 5.00001 6.66663 5.00001ZM4.99996 15L7.49996 11.6667L9.16663 13.3333L12.5 9.16667L15 15H4.99996Z' fill='%23${palette.base03}'/%3E%3Cpath d='M17.5 0V2.5H20V4.16667H17.5V6.66667H15.8334V4.16667H13.3334V2.5H15.8334V0H17.5Z' fill='%23${palette.base03}'/%3E%3C/svg%3E";
    }
    div[class|=contentRegion] #roles-tab div[class*=previewContainer-] .theme-dark img[class*=roleIcon-] {
      content: "data:image/svg+xml,%3Csvg fill='none' height='20' viewBox='0 0 20 20' width='20' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='%23c6d0f5'%3E%3Cpath clip-rule='evenodd' d='m11.0749 1.66667h-6.07488c-1.84095 0-3.33333 1.49239-3.33333 3.33334v9.99999c0 1.841 1.49238 3.3333 3.33333 3.3333h9.99998c1.841 0 3.3334-1.4923 3.3334-3.3333v-6.07489c-.5281.15716-1.0876.24156-1.6667.24156-3.2217 0-5.8333-2.61167-5.8333-5.83333 0-.57915.0844-1.13858.2415-1.66667zm-4.40821 3.33334c.91933 0 1.66666.746 1.66666 1.66666 0 .92134-.74733 1.66667-1.66666 1.66667-.92134 0-1.66667-.74533-1.66667-1.66667 0-.92066.74533-1.66666 1.66667-1.66666zm-1.66667 9.99999 2.5-3.3333 1.66667 1.6666 3.33331-4.16663 2.5 5.83333z' fill-rule='evenodd'/%3E%3Cpath d='m17.5 0v2.5h2.5v1.66667h-2.5v2.5h-1.6667v-2.5h-2.5v-1.66667h2.5v-2.5z'/%3E%3C/g%3E%3C/svg%3E";
    }

    .bd-settings-title {
      color: #${palette.base05};
    }

    .bd-switch-body {
      --switch-color: #${palette.base03};
    }
    .bd-switch input:checked + .bd-switch-body {
      --switch-color: #${palette.base0B};
    }
    .bd-switch input:checked + .bd-switch-body svg.bd-switch-symbol path {
      fill: #${palette.base0B};
    }

    .bd-button {
      background-color: #${palette.base0D};
      color: #${palette.base00};
    }
    .bd-button.bd-button-danger {
      background-color: #${palette.base08};
    }

    .bd-controls > .bd-addon-button svg {
      fill: #${palette.base00};
    }

    .bd-addon-views .bd-view-button.selected {
      background-color: #${palette.base0D};
    }
    .bd-addon-views .bd-view-button.selected svg {
      fill: #${palette.base00};
    }

    div[class|=perksModal] {
      background-color: #${palette.base01};
    }
    div[class|=perksModal] li[class|=perk] {
      background-color: #${palette.base02};
    }
    div[class|=perksModal] li[class|=perk] svg {
      color: #${palette.base0E};
    }
    div[class|=perksModal] svg[class|=giftIcon] {
      color: #${palette.base00};
    }
    div[class|=perksModal] div[class|=tierHeaderUnlocked] {
      background-image: linear-gradient(90deg, #${palette.base0D}, #${palette.base0E});
      color: #${palette.base01};
    }
    div[class|=perksModal] div[class|=tierUnlocked],
    div[class|=perksModal] div[class|=tierMarkerBackground] {
      background-color: #${palette.base01};
    }
    div[class|=perksModal] div[class|=barBackground],
    div[class|=perksModal] div[class|=tierMarkerInProgress],
    div[class|=perksModal] div[class|=tierBody] {
      background-color: #${palette.base00} !important;
    }
    div[class|=perksModal] div[class|=tierMarkerAccomplished] {
      background: #${palette.base0E} !important;
    }
    div[class|=perksModal] div[class|=tierMarkerInProgress] [class|=currentTierIcon] {
      color: #${palette.base0E};
    }
    div[class|=perksModal] div[class|=barForeground],
    div[class|=perksModal] div[class|=tierMarkerAccomplished] {
      background-color: #${palette.base0E};
    }
    div[class|=perksModal] svg[class|=currentTierIcon] {
      color: #${palette.base01};
    }
    div[class|=perksModal] div[class*=tierMarkerLabelText],
    div[class|=perksModal] svg[class|=tierLock] {
      color: var(--text-muted);
    }
    div[class|=perksModal] div[class*=selectedTier] div[class*=tierMarkerLabelText] {
      color: var(--text-normal);
    }
    div[class|=perksModal] div[class|=tierHeaderLocked] {
      background-color: #${palette.base00};
      color: var(--text-muted);
    }
    div[class|=perksModal] svg[class*=unlocked] {
      color: #${palette.base0B};
    }

    div[class|=sidebar] div[class|=container] div[class|=progressBar] {
      background: linear-gradient(90deg, #${palette.base0D}, #${palette.base0E});
    }
    div[class|=sidebar] div[class|=container]:hover div[class|=progressBar] {
      background: linear-gradient(90deg, #${palette.base0D}, #${palette.base0E} 34%, #${palette.base0D} 67%, #${palette.base0E});
    }
    div[class|=sidebar] div[class|=container] div[class|=divider] {
      border-color: var(--background-modifier-accent);
    }

    div[class|=pageWrapper] {
      background: #${palette.base00} !important;
    }
    div[class|=pageWrapper] div[class*=searchBox-] {
      background-color: #${palette.base02};
    }
    div[class|=pageWrapper] div[class*=searchBox-] svg[class*=clearIcon] path {
      fill: #${palette.base04};
    }
    div[class|=pageWrapper] div[class*=categoryPill-][class*=selected-] div {
      color: #${palette.base00} !important;
    }

    div[class|=homeContainer] {
      background: #${palette.base00} !important;
    }
    div[class|=homeContainer] > div[class|=homeContent] div[class*=card-] {
      background: #${palette.base02} !important;
    }

    section[class|=title] {
      background: var(--background-primary) !important;
    }

    div[class|=categoryItem][class*=selectedCategoryItem],
    button[class*=lookFilled] div[class*=addButton] {
      color: #${palette.base00} !important;
    }

    div[class|=itemInner] div[class|=new] > div[class*=newText-] {
      color: #${palette.base00} !important;
    }

    div[class*=directoryModal-] {
      background-color: #${palette.base01} !important;
    }
    div[class*=directoryModal-] [class*=searchBox] {
      background-color: #${palette.base02} !important;
    }
    div[class*=directoryModal-] [class*=searchBox] [name=search]::placeholder {
      color: #${palette.base05};
    }
    div[class*=directoryModal-] [role=button][class*=activeButton] {
      color: #${palette.base00};
    }

    section[class|=guildListSection] div[class|=guildList]:first-child div[class|=iconContainer] {
      background-color: #${palette.base0B};
    }
    section[class|=guildListSection] div[class|=guildList]:first-child div[class|=iconContainer] > div[class|=icon] {
      background-image: url("data:image/svg+xml,%3Csvg fill='none' height='24' viewBox='0 0 25 24' width='25' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='%23${palette.base00}'%3E%3Cpath clip-rule='evenodd' d='m13.25 18v-12h-1.5v12z' fill-rule='evenodd'/%3E%3Cpath clip-rule='evenodd' d='m7 12.75c-.69036 0-1.25.5596-1.25 1.25v4h-1.5v-4c0-1.5188 1.23122-2.75 2.75-2.75h11c1.5188 0 2.75 1.2312 2.75 2.75v4h-1.5v-4c0-.6904-.5596-1.25-1.25-1.25z' fill-rule='evenodd'/%3E%3Cpath d='m12.5 7c-1.3807 0-2.5-1.11929-2.5-2.5s1.1193-2.5 2.5-2.5 2.5 1.11929 2.5 2.5-1.1193 2.5-2.5 2.5z'/%3E%3Cpath d='m20 22c-1.3807 0-2.5-1.1193-2.5-2.5s1.1193-2.5 2.5-2.5 2.5 1.1193 2.5 2.5-1.1193 2.5-2.5 2.5z'/%3E%3Cpath d='m12.5 22c-1.3807 0-2.5-1.1193-2.5-2.5s1.1193-2.5 2.5-2.5 2.5 1.1193 2.5 2.5-1.1193 2.5-2.5 2.5z'/%3E%3Cpath d='m5 22c-1.38071 0-2.5-1.1193-2.5-2.5s1.11929-2.5 2.5-2.5 2.5 1.1193 2.5 2.5-1.11929 2.5-2.5 2.5z'/%3E%3C/g%3E%3C/svg%3E");
    }

    path[d="M22 12.4065C21.8956 14.9141 20.8533 17.2908 19.0798 19.0654C17.3062 20.8401 14.931 21.883 12.425 21.9875L13.7625 15.646L17.2375 17.9224C17.3214 17.9702 17.416 17.996 17.5125 17.9975C17.6481 17.9962 17.7781 17.9424 17.875 17.8474C17.9439 17.7577 17.9813 17.6478 17.9813 17.5347C17.9813 17.4216 17.9439 17.3117 17.875 17.222L15.6 13.7323L22 12.4065ZM13.7625 8.34148L17.2375 6.06504C17.3352 6.00866 17.4487 5.98608 17.5605 6.00084C17.6723 6.0156 17.7762 6.06686 17.8559 6.14665C17.9357 6.22645 17.9869 6.33037 18.0017 6.44225C18.0164 6.55413 17.9938 6.66772 17.9375 6.76548L15.6625 10.2551L22 11.581C21.8956 9.07342 20.8533 6.69669 19.0798 4.92206C17.3062 3.14742 14.931 2.10449 12.425 2L13.7625 8.34148ZM10.275 8.34148L11.6 2C9.09402 2.10449 6.71878 3.14742 4.94525 4.92206C3.17172 6.69669 2.12945 9.07342 2.02502 11.581L8.37497 10.2551L6.08752 6.76548C6.02873 6.66774 6.00413 6.55315 6.01772 6.43988C6.0313 6.32661 6.08228 6.22113 6.16252 6.14009C6.24233 6.05781 6.34797 6.00542 6.46175 5.99176C6.57552 5.97809 6.69052 6.00399 6.78752 6.06504L10.275 8.34148ZM6.16252 17.8474C6.08228 17.7663 6.0313 17.6609 6.01772 17.5476C6.00413 17.4343 6.02873 17.3197 6.08752 17.222L8.37497 13.7323L2 12.4065C2.10442 14.9141 3.1467 17.2908 4.92023 19.0654C6.69376 20.8401 9.06899 21.883 11.575 21.9875L10.25 15.646L6.7625 17.9224C6.67925 17.9718 6.58428 17.9977 6.48753 17.9975C6.35971 17.9937 6.23848 17.9398 6.15001 17.8474H6.16252Z"] {
      fill: #${palette.base0C};
    }

    path[d="M22 12.4065C21.8956 14.9141 20.8533 17.2908 19.0798 19.0654C17.3062 20.8401 14.931 21.883 12.425 21.9875L13.7625 15.646L17.2375 17.9224C17.3214 17.9702 17.416 17.996 17.5125 17.9975C17.6481 17.9962 17.7781 17.9424 17.875 17.8474C17.9439 17.7577 17.9813 17.6478 17.9813 17.5347C17.9813 17.4216 17.9439 17.3117 17.875 17.222L15.6 13.7323L22 12.4065ZM13.7625 8.34148L17.2375 6.06504C17.3352 6.00866 17.4487 5.98608 17.5605 6.00084C17.6723 6.0156 17.7762 6.06686 17.8559 6.14665C17.9357 6.22645 17.9869 6.33037 18.0017 6.44225C18.0164 6.55413 17.9938 6.66772 17.9375 6.76548L15.6625 10.2551L22 11.581C21.8956 9.07342 20.8533 6.69669 19.0798 4.92206C17.3062 3.14742 14.931 2.10449 12.425 2L13.7625 8.34148ZM10.275 8.34148L11.6 2C9.09402 2.10449 6.71878 3.14742 4.94525 4.92206C3.17172 6.69669 2.12945 9.07342 2.02502 11.581L8.37497 10.2551L6.08752 6.76548C6.02873 6.66774 6.00413 6.55315 6.01772 6.43988C6.0313 6.32661 6.08228 6.22113 6.16252 6.14009C6.24233 6.05781 6.34797 6.00542 6.46175 5.99176C6.57552 5.97809 6.69052 6.00399 6.78752 6.06504L10.275 8.34148ZM6.16252 17.8474C6.08228 17.7663 6.0313 17.6609 6.01772 17.5476C6.00413 17.4343 6.02873 17.3197 6.08752 17.222L8.37497 13.7323L2 12.4065C2.10442 14.9141 3.1467 17.2908 4.92023 19.0654C6.69376 20.8401 9.06899 21.883 11.575 21.9875L10.25 15.646L6.7625 17.9224C6.67925 17.9718 6.58428 17.9977 6.48753 17.9975C6.35971 17.9937 6.23848 17.9398 6.15001 17.8474H6.16252Z"] {
      fill: #${palette.base0C};
    }

    path[d="M17.225 6.06504C17.3227 6.00866 17.4362 5.98608 17.548 6.00084C17.6598 6.0156 17.7637 6.06686 17.8434 6.14665C17.9232 6.22645 17.9744 6.33037 17.9892 6.44225C18.0039 6.55413 17.9813 6.66772 17.925 6.76548L15.65 10.2551L21.9875 11.581C21.9875 11.7185 21.9875 11.8562 21.9875 11.9937C21.9875 12.1313 21.9875 12.2689 21.9875 12.4065L15.65 13.7323L17.925 17.222C17.9939 17.3117 18.0313 17.4216 18.0313 17.5347C18.0313 17.6478 17.9939 17.7577 17.925 17.8474C17.8281 17.9424 17.6982 17.9962 17.5625 17.9975C17.466 17.996 17.3714 17.9702 17.2875 17.9224L13.8125 15.646L12.4125 22H11.5875L10.2625 15.6585L6.77501 17.935C6.69176 17.9843 6.59672 18.0102 6.49997 18.01C6.43455 18.0098 6.3699 17.9963 6.30977 17.9705C6.24964 17.9447 6.1953 17.9072 6.15001 17.8599C6.06977 17.7789 6.01879 17.6734 6.0052 17.5601C5.99162 17.4468 6.01621 17.3323 6.07501 17.2345L8.36253 13.7449L2 12.4065C2 12.2689 2 12.1313 2 11.9937C2 11.8562 2 11.7185 2 11.581L8.35002 10.2551L6.0625 6.76548C6.0037 6.66774 5.97918 6.55315 5.99277 6.43988C6.00635 6.32661 6.05726 6.22113 6.1375 6.14009C6.21731 6.05781 6.32295 6.00542 6.43672 5.99176C6.5505 5.97809 6.6655 6.00399 6.7625 6.06504L10.25 8.34148L11.575 2H12.4L13.7375 8.34148L17.225 6.06504Z"] {
      fill: #${palette.base00};
    }

    div[class|=tierPreviews] button[class|=button] {
      background: linear-gradient(90deg, #${palette.base0C}, #${palette.base0D});
    }

    div[class|=notice] div[class*=noticeText-] {
      color: #${palette.base00};
    }
    div[class|=notice] div[class*=header-] {
      color: #${palette.base00};
    }
    div[class|=notice] div[class|=closeButton] > svg > path {
      fill: #${palette.base00};
    }
    div[class|=notice] button[class|=button] {
      border-color: #${palette.base07};
      color: #${palette.base00};
    }
    div[class|=notice] button[class|=button]:hover {
      background: #${palette.base0D};
    }

    nav[class*=guilds-] foreignObject > div[data-list-item-id|=guildsnav_] {
      background-color: #${palette.base02};
    }
    nav[class*=guilds-] foreignObject > div[data-list-item-id|=guildsnav_]:hover > div[class|=childWrapper], nav[class*=guilds-] foreignObject > div[data-list-item-id|=guildsnav_][class*=selected] > div[class|=childWrapper] {
      color: #${palette.base00};
      font-weight: 600;
    }
    nav[class*=guilds-] div[data-list-item-id=guildsnav___home] {
      --background-primary: #${palette.base02};
    }
    nav[class*=guilds-] span[class|=expandedFolderBackground] {
      background-color: #${palette.base01};
    }
    nav[class*=guilds-] div[class|=folder][class*=hover-] {
      background-color: #${palette.base03};
    }
    .closedFolderIconWrapper-3tRb2d {
      background-color: #${palette.base02};
    }
    .closedFolderIconWrapper-3tRb2d:hover {
      background-color: #${palette.base03};
    }
    nav[class*=guilds-] div[data-list-item-id=guildsnav___create-join-button] svg > path,
    nav[class*=guilds-] div[data-list-item-id=guildsnav___guild-discover-button] svg > path,
    nav[class*=guilds-] div[data-list-item-id=guildsnav___app-download-button] svg > path {
      fill: #${palette.base0B};
    }
    .circleIconButton-1VxDrg.selected-2r1Hvo {
      background-color: #${palette.base03};
    }

    div[class|=upperBadge] > div[class|=iconBadge] path {
      color: #${palette.base00};
    }
    div[class|=upperBadge] div[class*=participating-] {
      background: #${palette.base07};
    }

    div[class|=lowerBadge] div[class|=iconBadge] path {
      color: #${palette.base00};
    }

    svg[class|=spine] {
      color: #${palette.base04};
    }

    div[class|=spineBorder] {
      background: #${palette.base04};
    }

    ul[aria-label$=" threads"] > li:nth-child(1n) {
      --channels-default: #${palette.base05};
      --interactive-hover: #${palette.base08};
      --interactive-active: #${palette.base08};
    }

    ul[aria-label$=" threads"] > li:nth-child(2n) {
      --channels-default: #${palette.base05};
      --interactive-hover: #${palette.base09};
      --interactive-active: #${palette.base09};
    }

    ul[aria-label$=" threads"] > li:nth-child(3n) {
      --channels-default: #${palette.base05};
      --interactive-hover: #${palette.base09};
      --interactive-active: #${palette.base09};
    }

    ul[aria-label$=" threads"] > li:nth-child(4n) {
      --channels-default: #${palette.base05};
      --interactive-hover: #${palette.base0B};
      --interactive-active: #${palette.base0B};
    }

    ul[aria-label$=" threads"] > li:nth-child(5n) {
      --channels-default: #${palette.base05};
      --interactive-hover: #${palette.base0C};
      --interactive-active: #${palette.base0C};
    }

    ul[aria-label$=" threads"] > li:nth-child(6n) {
      --channels-default: #${palette.base05};
      --interactive-hover: #${palette.base0E};
      --interactive-active: #${palette.base0E};
    }

    [class|=botText] {
      color: #${palette.base00};
      font-weight: 600;
    }

    svg[class|=botTagVerified] {
      color: #${palette.base00};
    }

    div[class*=activePostCount-] {
      background-color: #${palette.base02};
      color: #${palette.base05} !important;
    }

    div[class*=newPostCount-] {
      background-color: #${palette.base05};
      color: #${palette.base00};
    }

    div[class*=liveSmall-] {
      background-color: #${palette.base0A}!important;
      color: #${palette.base00};
    }

    [class|=chatContent] div[class*=wrapperAudio-] div[class*=audioControls],
    [class|=chatContent] div[class*=wrapperAudio-] div[class*=videoControls-],
    [class|=chatContent] div[class*=imageWrapper-] div[class*=audioControls],
    [class|=chatContent] div[class*=imageWrapper-] div[class*=videoControls-] {
      background-color: rgba(${palette.base01}, 0.8);
    }
    [class|=chatContent] div[class*=wrapperAudio-] div[class*=audioControls] svg[class*=controlIcon-],
    [class|=chatContent] div[class*=wrapperAudio-] div[class*=videoControls-] svg[class*=controlIcon-],
    [class|=chatContent] div[class*=imageWrapper-] div[class*=audioControls] svg[class*=controlIcon-],
    [class|=chatContent] div[class*=imageWrapper-] div[class*=videoControls-] svg[class*=controlIcon-] {
      opacity: 1;
      color: #${palette.base07};
    }
    [class|=chatContent] #---new-messages-bar span[class|=unreadPill] {
      color: #${palette.base07};
    }
    [class|=chatContent] div[class|=newMessagesBar] button {
      color: #${palette.base00};
    }
    [class|=chatContent] div[class|=channelTextArea] div[class|=buttons] * {
      color: var(--interactive-normal) !important;
    }
    [class|=chatContent] [id|=message-reactions] div[class|=reaction] {
      background-color: #${palette.base02};
    }
    [class|=chatContent] [id|=message-reactions] div[class|=reaction]:hover {
      background-color: #${palette.base02};
      border-color: #${palette.base03};
    }
    [class|=chatContent] div[class*=isBurstReactionPicker-] {
      box-shadow: 0 0 0 2px #${palette.base0E}, 0 0 16px #${palette.base0D};
    }
    [class|=chatContent] div[class|=navButtonSuperReactActive],
    [class|=chatContent] div[class|=navButtonSuperReactActive]:hover {
      background: linear-gradient(270deg, #${palette.base0E}, #${palette.base0D} 33.63%, #${palette.base0E});
      color: #${palette.base00};
    }
    [class|=chatContent] div[class*=betaTag-] {
      background: var(--brand-experiment) !important;
      color: #${palette.base00};
    }
    [class|=chatContent] button[class*=navButtonActive-],
    [class|=chatContent] button[class*=navButtonActive-]:hover {
      color: #${palette.base00};
    }
    [class|=chatContent] div[class*=colorPremiumGradient-][class*=focused-] {
      background: linear-gradient(270deg, #${palette.base0E}, #${palette.base0D} 33.63%, #${palette.base0E});
      color: #${palette.base00} !important;
    }
    [class|=chatContent] div[class*=isBurstReactionPicker] {
      border: none;
      box-shadow: 0 0 0 2px #${palette.base0E}, 0 0 16px #${palette.base0D};
    }
    [class|=chatContent] div[class*=playButtonContainer-] {
      background: var(--brand-experiment) !important;
    }
    [class|=chatContent] svg[class*=playIcon-] path {
      fill: #${palette.base00};
    }
    [class|=chatContent] div[class|=container][class*=header-] div[class*=addReactButton-],
    [class|=chatContent] div[class|=container][class*=header-] div[class|=buttons]:not([class*=lookBlank-]) div[class|=contents] {
      background: #${palette.base02};
    }
    [class|=chatContent] div[class|=container][class*=header-] div[class*=addReactButton-]:hover,
    [class|=chatContent] div[class|=container][class*=header-] div[class|=buttons]:not([class*=lookBlank-]) div[class|=contents]:hover {
      background-color: var(--brand-experiment-20a);
      border-color: var(--brand-experiment-30a);
    }
    [class|=chatContent] div[class|=messagesErrorBar] div[class*=barButtonBase-] {
      color: #${palette.base00};
    }
    [class|=chatContent] [class*=inlineCode-] {
      background: #${palette.base02};
    }
    [class|=chatContent] code.inline {
      background: #${palette.base02};
    }
    [class|=chatContent] div[class|=container] div[class|=cardWrapper] div[class*=completed-] svg[class|=checkmark] {
      background-color: #${palette.base0B};
      color: #${palette.base00};
    }

    div[style*="d1382af8d9e755bc44811b1fd92990a8.svg"] {
      background-image: url("data:image/svg+xml,%3Csvg height='18' width='18' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cpath d='m18 0h-18v18h18z'/%3E%3Cpath d='m0 8h14.2l-3.6-3.6 1.4-1.4 6 6-6 6-1.4-1.4 3.6-3.6h-14.2' fill='%23${palette.base0B}'/%3E%3C/g%3E%3C/svg%3E") !important;
      filter: none !important;
    }

    main[class|=chatContent] div[id|=message-content] svg[class|=icon] > path[d="M4 0L0 4V8L4 12L8 8V4L4 0ZM7 7.59L4 10.59L1 7.59V4.41L4 1.41L7 4.41V7.59Z"],
    main[class|=chatContent] div[id|=message-content] svg[class|=icon] > path[d="M2 4.83V7.17L4 9.17L6 7.17V4.83L4 2.83L2 4.83Z"] {
      color: #${palette.base0E};
    }

    .theme-dark span[class|=spoilerContent],
    .theme-dark div[class|=spoilerContent],
    .theme-light span[class|=spoilerContent],
    .theme-light div[class|=spoilerContent] {
      background-color: #${palette.base04};
    }
    .theme-dark span[class|=spoilerContent][class*=hidden],
    .theme-dark div[class|=spoilerContent][class*=hidden],
    .theme-light span[class|=spoilerContent][class*=hidden],
    .theme-light div[class|=spoilerContent][class*=hidden] {
      background-color: #${palette.base03};
    }
    .theme-dark span[class|=spoilerContent][class*=hidden]:hover,
    .theme-dark div[class|=spoilerContent][class*=hidden]:hover,
    .theme-light span[class|=spoilerContent][class*=hidden]:hover,
    .theme-light div[class|=spoilerContent][class*=hidden]:hover {
      background-color: #${palette.base03};
    }
    .theme-dark div[class|=spoilerContainer] div[class|=spoilerWarning],
    .theme-light div[class|=spoilerContainer] div[class|=spoilerWarning] {
      color: #${palette.base07};
      background-color: rgba(${palette.base00}, 0.7);
    }
    .theme-dark div[class|=spoilerContainer]:hover div[class|=spoilerWarning],
    .theme-light div[class|=spoilerContainer]:hover div[class|=spoilerWarning] {
      color: #${palette.base07};
      background-color: rgba(${palette.base00}, 0.7);
    }
    .theme-dark div[class|=spoilerContainer] article[class*=embedFull-],
    .theme-light div[class|=spoilerContainer] article[class*=embedFull-] {
      border-color: #${palette.base03};
    }

    div[class|=cooldownWrapper] {
      color: var(--text-muted) !important;
    }

    div[class*=autocomplete-] {
      background-color: #${palette.base01} !important;
    }
    div[class*=autocomplete-] div[class*=categoryHeader] {
      background-color: #${palette.base01} !important;
    }
    div[class*=autocomplete-] div[class*=autocompleteRowSubheading] {
      background-color: transparent;
    }
    div[class*=autocomplete-] div[class*=autocompleteRowContentSecondary] {
      background-color: transparent;
    }
    div[class*=autocomplete-] div[class|=usageWrapper] > div[class*=title-] {
      color: #${palette.base0D} !important;
    }
    div[class*=autocomplete-] strong {
      color: #${palette.base0D} !important;
    }

    div[class|=channelTextArea] button[class*=emojiButton-] {
      background: transparent !important;
    }

    [class|=uploadDropModal][class*=error] {
      background-color: #${palette.base08};
    }
    [class|=uploadDropModal] div[class|=inner] {
      border-color: #${palette.base06};
    }
    [class|=uploadDropModal] div[class|=inner] * {
      color: #${palette.base07} !important;
    }

    div[class|=chat] > div[class|=content] > div[class|=container] {
      background-color: #${palette.base00};
    }
    div[class|=chat] > div[class|=content] > div[class|=container] div[class|=pinIcon] > svg > path,
    div[class|=chat] > div[class|=content] > div[class|=container] div[class|=stepStatus] > svg > path {
      fill: #${palette.base05};
    }
    div[class|=chat] > div[class|=content] > div[class|=container] div[class|=pinIcon][style*="background-color: var(--status-positive-background);"] > svg > path,
    div[class|=chat] > div[class|=content] > div[class|=container] div[class|=stepStatus][style*="background-color: var(--status-positive-background);"] > svg > path {
      fill: #${palette.base00};
    }
    div[class|=chat] > div[class|=content] > div[class|=container] div[class*=countText] {
      color: #${palette.base00};
    }
    div[class|=chat] > div[class|=content] > div[class|=container] svg[class|=discordIcon] {
      background-color: #${palette.base0D};
      color: #${palette.base00};
    }
    div[class|=chat] > div[class|=content] > div[class|=container] div[class|=newBadge] {
      background-color: #${palette.base0D} !important;
      color: #${palette.base00};
    }
    div[class|=chat] > div[class|=content] > div[class|=container] div[class*=mainCard-] {
      background-color: #${palette.base00};
    }

    div[class|=sidebar] > section[class|=panels] svg[class*=buttonIcon-],
    div[class|=sidebar] > section[class|=panels] div[class*=buttonContents] {
      fill: #${palette.base05};
      color: #${palette.base06};
    }

    [data-list-id|=forum-channel-list] div[class|=body] > div[class|=tags] div[class*=pill] {
      background-color: #${palette.base01};
    }
    [data-list-id|=forum-channel-list] button[class|=submitButton][class*=colorBrand] {
      background-color: #${palette.base0A};
      color: #${palette.base00} !important;
    }

    .text-md-bold-1mgErV, .text-md-semibold-2VMhBr {
      color: #${palette.base07};
    }

    .submitIcon-E3Vuaz {
      color: #${palette.base00};
    }

    .theme-dark svg[class*=searchIcon-], .theme-light svg[class*=searchIcon-] {
        color: #${palette.base04} !important;
    }

    .name-3Uvkvr {
      color: #${palette.base07};
    }

    div[class|=applicationCommand] span[class*=selectedPill-] {
      border-color: #${palette.base0D} !important;
    }
    div[class|=applicationCommand] span[class*=erroredPill-] {
      border-color: #${palette.base08} !important;
    }

    div[class|=chat] > div[class|=content] main[class|=chatContent] + div[class|=container] {
      background-color: var(--background-secondary);
    }

    [class*=channelTextAreaInnerError-] {
      border: 1px solid #${palette.base08} !important;
    }

    [class*=barButtonBase-] {
      color: #${palette.base00} !important;
    }

    div[class|=callContainer] [class*=controlIcon-] {
      color: #${palette.base05};
    }
    div[class|=callContainer] [class*=controlIcon-]:hover {
      color: #${palette.base06};
    }
    div[class|=callContainer] div[class*=tile-],
    div[class|=callContainer] div[class*=background-] {
      background-color: #${palette.base00} !important;
    }
    div[class|=callContainer] div[class*=overlayTitle],
    div[class|=callContainer] svg[class*=status-] {
      background-color: #${palette.base02};
      color: #${palette.base07};
    }
    div[class|=callContainer] div[class*=header],
    div[class|=callContainer] svg[class*=selectedIcon-] {
      color: #${palette.base07};
    }
    div[class|=callContainer] div[class*=button-][class*=contents-],
    div[class|=callContainer] button[class*=cta-],
    div[class|=callContainer] button[class*=participantsButton-] {
      background-color: #${palette.base00};
      color: #${palette.base07};
    }
    div[class|=callContainer] div[class|=indicators] div[class|=liveQualityIndicator] {
      background-color: transparent !important;
    }
    div[class|=callContainer] div[class|=indicators] div[class|=liveQualityIndicator] svg[class|=premiumStreamIcon] {
      color: #${palette.base00};
    }
    div[class|=callContainer] div[class|=videoControls] div[class|=children] div[class*=playingText-] {
      color: #${palette.base05};
    }
    div[class|=callContainer] div[class|=videoControls] div[class|=toolbar] svg[class|=controlIcon] {
      fill: #${palette.base04} !important;
    }
    div[class|=callContainer] div[class|=videoControls] div[class|=toolbar] div[class|=streamQualityIndicator] div[class|=liveQualityIndicator] {
      background-color: #${palette.base02} !important;
    }
    div[class|=callContainer] div[class|=videoControls] div[class|=toolbar] div[class|=streamQualityIndicator] div[class|=liveQualityIndicator] div[class|=qualityIndicator] {
      color: #${palette.base06};
    }
    div[class|=callContainer] div[class|=videoControls] div[class|=toolbar] div[class|=streamQualityIndicator] div[class|=liveQualityIndicator] svg[class|=premiumStreamIcon] {
      color: #${palette.base06};
    }
    div[class|=callContainer] div[class|=videoControls] div[class|=toolbar] div[class|=liveIndicator] div[class|=live] {
      background-color: #${palette.base08} !important;
      color: #${palette.base00} !important;
    }
    div[class|=callContainer] div[class|=videoControls] button[class*=leftTrayIcon-][class*=buttonColor-] {
      background-color: #${palette.base02};
      color: #${palette.base06};
    }
    div[class|=callContainer] div[class|=videoControls] div[class|=badge] {
      color: #${palette.base00};
    }
    div[class|=callContainer] div[class|=videoControls] [class*=colorable-][class*=red-] {
      background: #${palette.base08};
    }
    div[class|=callContainer] div[class|=videoControls] [class*=colorable-][class*=red-] [class*=centerIcon-] {
      color: #${palette.base00};
    }
    div[class|=callContainer] div[class|=videoControls] [class*=colorable-][class*=primaryDark-] {
      background: #${palette.base07};
      color: #${palette.base06};
    }
    div[class|=callContainer] div[class|=videoControls] [class*=colorable-][class*=primaryDark-] [class*=centerIcon-] {
      color: #${palette.base06};
    }
    div[class|=callContainer] div[class|=videoControls] [class*=colorable-][class*=green-] {
      background: #${palette.base0B};
    }
    div[class|=callContainer] div[class|=videoControls] [class*=colorable-][class*=green-] [class*=centerIcon-] {
      color: #${palette.base00};
    }
    div[class|=callContainer] div[class|=videoControls] [class*=colorable-][class*=white-] {
      color: #${palette.base00};
      background-color: #${palette.base05};
    }
    div[class|=callContainer] div[class|=videoControls] [class*=colorable-][class*=white-] [class*=centerIcon-] {
      color: #${palette.base00};
    }
    div[class|=callContainer] div[class|=videoControls] [class*=colorable-][class*=white-]:hover, div[class|=callContainer] div[class|=videoControls] [class*=colorable-][class*=white-][class*=active-] {
      background: #${palette.base06};
    }

    div[class*=giftCodeContainer] [class*=tile] {
      background-color: #${palette.base01};
    }
    div[class*=giftCodeContainer] [class*=tile] > [class*=description] {
      color: #${palette.base06};
    }

    div[class*=chat-] section[class*=header-] {
      background-color: #${palette.base00};
    }
    div[class*=chat-] div[class*=content-][class*=container-] {
      background-color: #${palette.base00};
    }
    div[class*=chat-] div[class*=content-][class*=container-] div[class*=container] {
      background-color: #${palette.base00};
    }
    div[class*=chat-] div[class*=content-][class*=container-] div[class*=search-] {
      background-color: #${palette.base01} !important;
    }
    div[class*=chat-] div[class*=content-][class*=container-] div[class*=search-] input::placeholder {
      color: #${palette.base04};
    }
    div[class*=chat-] div[class*=content-][class*=container-] div[class*=browser] div[class*=content] div[class|=container] {
      background-color: #${palette.base01};
    }
    div[class*=chat-] div[class*=content-][class*=container-] div[class*=scrollerContainer-] {
      background-color: #${palette.base00};
    }
    div[class*=chat-] div[class*=content-][class*=container-] div[class*=scrollerContainer-] div[class*=checkIcon-][style*="opacity: 1;"] > svg > path {
      fill: #${palette.base00};
    }
    div[class*=chat-] div[class*=content-][class*=container-] div[role=tablist] {
      background-color: #${palette.base00};
      border-bottom: 2px solid #${palette.base02};
    }
    div[class*=chat-] div[class*=content-][class*=container-] div[role=tablist] [class*=textBadge-] {
      color: #${palette.base00};
    }

    div[class*=chat-] section[class*=title] div[class*=searchBar] span[class*=search] {
      background-color: #${palette.base02};
      color: #${palette.base06};
    }
    div[class*=chat-] nav[class*=pageControl] div[class*=roundButton][class*=activeButton] span {
      color: #${palette.base00};
    }

    div[class*=chat-] li[class*=mainCard-][class*=container] {
      background-color: #${palette.base01};
    }
    div[class*=chat-] li[class*=mainCard-][class*=container]:hover {
      background-color: #${palette.base02};
    }
    div[class*=chat-] li[class*=mainCard-][class*=container] div[class*=contentPreview-] {
      background-color: #${palette.base03};
      border: none;
    }
    div[class*=chat-] li[class*=mainCard-][class*=container] div[class*=contentPreview-] div[class*=textContentFooter-] {
      background: none;
    }
    div[class*=chat-] li[class*=mainCard-][class*=container] div[class*=tags-] div[class*=tagPill-] {
      background-color: #${palette.base01};
    }
    div[class*=chat-] div[class*=emptyPage] {
      background-color: #${palette.base01};
    }
    div[class*=chat-] div[class*=innerHeader]:after {
      background: none;
    }

    [id*=message-accessories-] > [class*=invite-] {
      background-color: #${palette.base01};
    }
    [id*=message-accessories-] > [class*=invite-] [class*=inFront-][class*=header-] {
      color: #${palette.base05};
    }
    [id*=message-accessories-] > [class*=invite-] [class*=partyStatus-] {
      color: #${palette.base06};
    }

    [class|=avatar] [class|=dots] {
      color: #${palette.base01};
    }

    div[class|=chat][class*=page-] div[class|=content][class*=container-] {
      height: 100%;
    }

    .messagelogger-deleted div {
      color: #${palette.base08} !important;
    }

    .messagelogger-deleted div a {
      color: #${palette.base08} !important;
    }

    div[class|=layerContainer] [role=menu] {
      --brand-experiment-560: var(--brand-experiment-25a);
      --brand-experiment-600: var(--brand-experiment);
    }
    div[class|=layerContainer] [role=menu] [class*=colorDefault][class*=colorBrand] {
      color: #${palette.base0D};
    }
    div[class|=layerContainer] [role=menu] [class*=colorDefault][class*=focused]:not([class*=colorDanger]),
    div[class|=layerContainer] [role=menu] [class*=colorDefault][class*=focused] [class*=checkbox-] {
      color: #${palette.base00};
      background-color: #${palette.base0A};
    }
    div[class|=layerContainer] [role=menu] [class*=colorDefault][role=menuitem]:not([class*=colorDanger]):not([id*=user-context-user-volume]):hover {
      background: var(--background-accent);
      color: #${palette.base00};
    }
    div[class|=layerContainer] [role=menu] [class*=colorDefault][role=menuitem]:not([class*=colorDanger]):not([id*=user-context-user-volume]):hover [class*=subtext],
    div[class|=layerContainer] [role=menu] [class*=colorDefault][role=menuitem]:not([class*=colorDanger]):not([id*=user-context-user-volume]):hover [class*=caret-] {
      color: #${palette.base00};
    }
    div[class|=layerContainer] [role=menu] [class*=colorDefault] [class*=caret] {
      color: #${palette.base04};
    }
    div[class|=layerContainer] [role=menu] [class*=colorDefault]:active:not([class*=hideInteraction-]) {
      color: var(--background-floating);
    }
    div[class|=layerContainer] [role=menu] [class*=colorDefault]:active:not([class*=hideInteraction-]) [class*=check-] {
      color: var(--interactive-normal);
    }
    div[class|=layerContainer] [role=menu] [class*=colorDefault]:active:not([class*=hideInteraction-]) [class*=checkbox-] {
      color: var(--background-floating);
    }
    div[class|=layerContainer] [role=menu] [class*=focused] [class*=userMenuUsername] * {
      color: #${palette.base00};
    }
    div[class|=layerContainer] [role=menu] [class*=colorDanger][class*=focused],
    div[class|=layerContainer] [role=menu] [class*=colorDefault] [class*=check-] {
      color: var(--background-floating);
      background-color: #${palette.base08};
    }
    div[class|=layerContainer] [role=menu] #guild-header-popout-premium-subscribe div[class|=iconContainer] > svg {
      color: #${palette.base0E};
    }
    div[class|=layerContainer] [role=menu] #user-context-user-volume div[class*=slider-] div[class*=bar-] {
      background-color: #${palette.base02};
    }

    .theme-dark div[class|=layerContainer] div[id|=popout_] > div[class*=didRender-]:not([class|=animatorBottom]) > div div[class*=flowerStarContainer-] svg[class*=flowerStar-] *,
    .theme-light div[class|=layerContainer] div[id|=popout_] > div[class*=didRender-]:not([class|=animatorBottom]) > div div[class*=flowerStarContainer-] svg[class*=flowerStar-] * {
      fill: #${palette.base0D};
    }
    .theme-dark div[class|=layerContainer] div[id|=popout_] > div[class*=didRender-] div[class*=countText],
    .theme-light div[class|=layerContainer] div[id|=popout_] > div[class*=didRender-] div[class*=countText] {
      color: #${palette.base00};
    }
    .theme-dark div[class|=layerContainer] div[id|=popout_] > div[class*=didRender-] svg[class*=activeIcon] circle,
    .theme-light div[class|=layerContainer] div[id|=popout_] > div[class*=didRender-] svg[class*=activeIcon] circle {
      fill: #${palette.base0D};
    }
    .theme-dark div[class|=layerContainer] div[id|=popout_] > div[class*=didRender-] svg[class*=activeIcon] g path,
    .theme-light div[class|=layerContainer] div[id|=popout_] > div[class*=didRender-] svg[class*=activeIcon] g path {
      fill: #${palette.base0D};
    }
    .theme-dark div[class|=layerContainer] div[id|=popout_] > div[class*=didRender-] div[class*=container] div[class*=autocompleteArrow-],
    .theme-dark div[class|=layerContainer] div[id|=popout_] > div[class*=didRender-] div[class*=container] header,
    .theme-light div[class|=layerContainer] div[id|=popout_] > div[class*=didRender-] div[class*=container] div[class*=autocompleteArrow-],
    .theme-light div[class|=layerContainer] div[id|=popout_] > div[class*=didRender-] div[class*=container] header {
      background-color: #${palette.base01};
    }
    .theme-dark div[class|=layerContainer] div[id|=popout_] > div[class*=didRender-] div[class*=container] header > input::placeholder,
    .theme-light div[class|=layerContainer] div[id|=popout_] > div[class*=didRender-] div[class*=container] header > input::placeholder {
      color: #${palette.base04};
    }
    .theme-dark div[class|=layerContainer] div[id|=popout_] > div[class*=didRender-] div[class*=container] section,
    .theme-light div[class|=layerContainer] div[id|=popout_] > div[class*=didRender-] div[class*=container] section {
      background-color: #${palette.base01};
      color: #${palette.base06};
    }

    div[class*=recentMentionsPopout] div[class|=header] div[class|=tabBar] div[class|=badge],
    div[class*=recentMentionsPopout] div[class|=header] div[class|=tabBar] div[class|=tab][class*=active-] {
      color: #${palette.base01};
    }
    div[class*=recentMentionsPopout] div[class|=header] div[class|=controls-] {
      --background-secondary: #${palette.base02};
      --background-primary: rgba(${palette.base02}, 0.9);
    }
    div[class*=recentMentionsPopout] div[class|=scroller] [role=button] {
      --background-tertiary: rgba(${palette.base05}, 0.15);
      --background-floating: rgba(${palette.base01}, 0.12);
    }
    div[class*=recentMentionsPopout] div[class|=scroller] [role=button] div[class*=jumpButton-] {
      background-color: #${palette.base03};
    }

    div[class*=rolesList] div[class|=role],
    div[class*=rolesList] button[class|=addButton] {
      background-color: #${palette.base02};
    }
    div[class*=rolesList] div[class|=role] span[class|=roleCircle][style*="background-color: #${palette.base04}"] {
      background-color: #${palette.base04} !important;
    }
    div[class*=rolesList] div[class|=role] span[class|=roleCircle][style*="background-color: #${palette.base01}"], div[class*=rolesList] div[class|=role] span[class|=roleCircle][style*="background-color: rgb(53, 57, 64)"] {
      background-color: #${palette.base02} !important;
    }

    div[class*=layerContainer] > div[class*=layer] div[class|=reactors] {
      background-color: #${palette.base01};
    }
    div[class*=layerContainer] > div[class*=layer] div[class*=reactorDefault] {
      -webkit-box-shadow: inset 0 -1px 0 #${palette.base03};
      box-shadow: inset 0 -1px 0 #${palette.base03};
    }
    div[class*=layerContainer] > div[class*=layer] div[class*=reactionSelected] {
      background-color: #${palette.base02};
    }
    div[class*=layerContainer] > div[class*=layer] div[class*=friendSelected] {
      background: #${palette.base02} !important;
    }

    section[class|=positionContainer] button[class*=navButtonActive] {
      background-color: #${palette.base0A};
      color: #${palette.base00};
    }

    .theme-light section[class|=positionContainer] div[class|=categoryText] {
      color: #${palette.base00};
    }

    #emoji-picker-tab-panel [class*=stickerInspected-] [class*=inspectedIndicator],
    #emoji-picker-tab-panel [class|=emojiItem][class*=emojiItemSelected-] {
      background-color: #${palette.base03} !important;
    }
    #emoji-picker-tab-panel [class*=newlyAddedHighlight-] {
      border: 1px solid #${palette.base0B};
    }
    #emoji-picker-tab-panel [class*=newlyAddedHighlight-] ~ [class*=newlyAddedBadge-] {
      background: #${palette.base0B} !important;
      color: #${palette.base00};
    }

    [class*=stickerInspected-] [class|=inspectedIndicator] {
      background-color: var(--brand-experiment-25a);
    }

    .theme-light > div[class|=focusLock] > div[class|=root] > div[class|=container] div[class*=footer][class*=footerSeparator-] {
      box-shadow: inset 0 1px 0 #${palette.base03};
      -webkit-box-shadow: inset 0 1px 0 #${palette.base03};
    }
    .theme-light > div[class|=focusLock] > div[class|=root] {
      box-shadow: 0 0 0 1px #${palette.base03}, 0 2px 10px 0 hsla(0, calc(var(--saturation-factor, 1) * 0%), 0%, 0.1);
      -webkit-box-shadow: 0 0 0 1px #${palette.base03}, 0 2px 10px 0 hsla(0, calc(var(--saturation-factor, 1) * 0%), 0%, 0.1);
    }
    .theme-light div[class|=focusLock] div[class|=downloadApps] {
      background-color: #${palette.base00} !important;
    }
    .theme-light div[class|=focusLock] div[class|=downloadApps] button[class|=modalCloseButton],
    .theme-light div[class|=focusLock] div[class|=downloadApps] h2,
    .theme-light div[class|=focusLock] div[class|=downloadApps] h3 {
      color: #${palette.base05};
    }
    .theme-light div[class|=focusLock] div[class|=downloadApps] div[class*=footer-] {
      color: #${palette.base05} !important;
      background-color: unset !important;
    }
    .theme-light div[class|=focusLock] div[class|=downloadApps] div[class*=footer-] a {
      color: #${palette.base0D};
    }
    .theme-light div[class|=focusLock] div[class|=downloadApps] li[class*=active-] a[class*=downloadButton-] {
      transition: all 0.3s ease-in-out;
      color: #${palette.base00};
    }
    .theme-light[class*=profileColors-] [class*=userTagUsernameBase-],
    .theme-light[class*=profileColors-] [class*=discrimBase-],
    .theme-light[class*=profileColors-] [class*=title-],
    .theme-light[class*=profileColors-] [class*=roles-],
    .theme-light[class*=profileColors-] [class*=defaultColor-],
    .theme-light[class*=profileColors-] [class*=markup-],
    .theme-light[class*=profileColors-] [class*=activityUserPopoutV2-] *,
    .theme-light[class*=profileColors-] [class*=customStatus-],
    .theme-light[class*=profileColors-] [class*=section-],
    .theme-light[class*=profileColors-] [class*=additionalActionsIcon-],
    .theme-light[class*=profileColors-] [class*=overlayBackground-] * {
      --interactive-normal: #${palette.base00};
      --text-normal: #${palette.base00};
      --interactive-active: #${palette.base00};
      --interactive-hover: #${palette.base00};
    }
    .theme-light[class*=profileColors-] [class*=userTagUsernameBase-]:not(a),
    .theme-light[class*=profileColors-] [class*=discrimBase-]:not(a),
    .theme-light[class*=profileColors-] [class*=title-]:not(a),
    .theme-light[class*=profileColors-] [class*=roles-]:not(a),
    .theme-light[class*=profileColors-] [class*=defaultColor-]:not(a),
    .theme-light[class*=profileColors-] [class*=markup-]:not(a),
    .theme-light[class*=profileColors-] [class*=activityUserPopoutV2-] *:not(a),
    .theme-light[class*=profileColors-] [class*=customStatus-]:not(a),
    .theme-light[class*=profileColors-] [class*=section-]:not(a),
    .theme-light[class*=profileColors-] [class*=additionalActionsIcon-]:not(a),
    .theme-light[class*=profileColors-] [class*=overlayBackground-] *:not(a) {
      color: unset !important;
    }

    div[class|=layerContainer] #guild-header-popout,
    div[class|=layerContainer] #guild-context,
    div[class|=layerContainer] div[id|=channel-context],
    div[class|=layerContainer] div[id|=user-context] {
      background: #${palette.base00};
    }
    div[class|=layerContainer] > div[class*=layer] div[role=listbox] {
      background-color: #${palette.base00};
    }
    div[class|=layerContainer] > div[class*=layer] div[role=listbox] div[role=option][aria-selected=true] {
      background: #${palette.base02};
    }
    div[class|=layerContainer] > div[class*=layer] div[role=listbox] div[role=option] svg[class*=selectedIcon] circle {
      fill: #${palette.base00};
    }
    div[class|=layerContainer] > div[class*=layer] div[role=listbox] div[class*=queryText-] {
      color: #${palette.base04};
    }
    div[class|=layerContainer] > div[class*=layer] div[role=listbox] div[class*=queryText-] strong {
      color: #${palette.base05};
    }
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock] div[class|=modal],
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock] div[class|=modalSize],
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock] div[class|=uploadModal],
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock] div[class|=contentWrapper] {
      background-color: #${palette.base00};
    }
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock] div[class|=modal] li,
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock] div[class|=modal] p,
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock] div[class|=modal] span,
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock] div[class|=modalSize] li,
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock] div[class|=modalSize] p,
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock] div[class|=modalSize] span,
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock] div[class|=uploadModal] li,
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock] div[class|=uploadModal] p,
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock] div[class|=uploadModal] span,
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock] div[class|=contentWrapper] li,
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock] div[class|=contentWrapper] p,
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock] div[class|=contentWrapper] span {
      color: #${palette.base07};
    }
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock] div[class*=footer] {
      background-color: #${palette.base00};
    }
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock] div[class*=footer] button[type=submit] span {
      color: #${palette.base00};
    }
    div[class|=layerContainer] > div[class*=layer] div[class|=ffffffock] div[class*=footer] [class*=footerText-] {
      color: #${palette.base05};
    }
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock] h1[class|=fixed],
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock] h2[class|=fixed],
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock] h3[class|=fixed],
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock] h4[class|=fixed],
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock] h5[class|=fixed],
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock] h6[class|=fixed] {
      color: #${palette.base08};
    }
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock] h1[class|=fixed]:after,
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock] h2[class|=fixed]:after,
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock] h3[class|=fixed]:after,
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock] h4[class|=fixed]:after,
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock] h5[class|=fixed]:after,
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock] h6[class|=fixed]:after {
      background-color: #${palette.base08};
    }
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock] div[class*=message-] {
      background-color: transparent;
    }
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock][aria-label=Activities] div[class*=activityItem-] {
      background-color: #${palette.base00};
    }
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock][aria-label=Activities] div[class*=activityItem-] div[class*=previewBadge-] {
      color: #${palette.base00};
    }
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock][aria-label=Activities] div[class*=activityTag-] {
      background-color: rgba(${palette.base03}, 0.5);
    }
    div[class|=layerContainer] > div[class*=layer] div[class|=focusLock][aria-label="Manage Accounts"] div[class*=navRow-] {
      background-color: #${palette.base00};
    }
    div[class|=layerContainer] div[class|=addGamePopout] {
      background-color: #${palette.base01};
    }
    div[class|=layerContainer] div[class*=searchOption-]::after,
    div[class|=layerContainer] div[class*=option-]::after,
    div[class|=layerContainer] li[class*=option-]::after {
      display: none;
    }
    div[class|=layerContainer] div[class|=queryContainer] {
      background-color: #${palette.base00} !important;
    }
    div[class|=layerContainer] div[class|=queryContainer] span[class|=key] {
      color: #${palette.base05};
      background-color: #${palette.base01};
    }
    div[class|=layerContainer] [class*=tooltipBrand-],
    div[class|=layerContainer] [class*=tooltipRed-],
    div[class|=layerContainer] [class*=tooltipGreen-],
    div[class|=layerContainer] [class*=tooltipYellow] {
      color: #${palette.base00};
    }
    div[class|=layerContainer] div[class|=popout] div[class|=row][role=button]:hover {
      color: #${palette.base00};
    }
    div[class|=layerContainer] div[class|=popout] div[class|=row][role=button]:hover [class*=timestamp] {
      color: #${palette.base00};
    }

    form[class*=card-] {
      background-color: #${palette.base01};
    }

    div[class*=userInfoSection-] div[class|=connectedAccountContainer] {
      background-color: rgba(${palette.base03}, 0.45) !important;
    }

    div[class*=cardWarning-] div[class*=warning-] {
      color: #${palette.base00};
    }

    #emoji-picker-tab-panel,
    #sticker-picker-tab-panel {
      /* --background-floating: #${palette.base03};

        + div[class|="slotsContainer"] {
          background-color: $surface0;
        }
      */
    }
    #emoji-picker-tab-panel div[class|=tooltipContainer] label[class|=label][class*=labelChecked-],
    #sticker-picker-tab-panel div[class|=tooltipContainer] label[class|=label][class*=labelChecked-] {
      background: -webkit-gradient(linear, right top, left top, from(#${palette.base0E}), color-stop(33.33%, #${palette.base0E}), to(#${palette.base0D}));
      background: linear-gradient(270deg, #${palette.base0E}, #${palette.base0E} 33.33%, #${palette.base0D});
    }

    div[class*=keyboardShortcutsModal-] {
      background-color: #${palette.base01} !important;
    }
    div[class*=keyboardShortcutsModal-] div[class|=keybindShortcut] span[class|=key] {
      color: #${palette.base00};
    }
    div[class*=keyboardShortcutsModal-] div[class|=keybindShortcut] span[class|=key] svg g {
      fill: #${palette.base00} !important;
    }

    .react-datepicker,
    .react-datepicker__header {
      background-color: #${palette.base01} !important;
    }

    .react-datepicker__day {
      background-color: #${palette.base00} !important;
    }

    .react-datepicker__day:active {
      background: #${palette.base0D} !important;
    }

    .react-datepicker__day--selected:after {
      background-color: #${palette.base0D} !important;
    }

    [class|=datePickerHint] [class|=hintValue] {
      color: #${palette.base00} !important;
    }

    div[class*=layerContainer-] div[class|=control] div[class*=checked-] {
      background-color: #${palette.base0B} !important;
    }
    div[class*=layerContainer-] div[class|=control] div[style*="background-color: rgb(${palette.base04});"] {
      background-color: #${palette.base04} !important;
    }

    div[class*=layerContainer-] div[class*=guildPopout-][role=dialog] {
      background-color: #${palette.base02};
    }
    div[class*=layerContainer-] div[class*=guildPopout-][role=dialog] div[class*=guildName-] {
      color: #${palette.base05};
    }

    div[class*=layerContainer-] [role*=dialog] a[class*=downloadLink-] {
      color: #${palette.base04} !important;
      opacity: 1;
    }
    div[class*=layerContainer-] [role*=dialog] a[class*=downloadLink-]:hover {
      color: #${palette.base05} !important;
    }

    div[class*=userPopoutOuter-] div[aria-label="HypeSquad Bravery"] img,
    div[class*=userProfileOuter-] div[aria-label="HypeSquad Bravery"] img {
      content: url("data:image/svg+xml,%3Csvg height='24' viewBox='0 0 24 24' width='24' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath clip-rule='evenodd' d='m5.01502 4h13.97008c.1187 0 .215.09992.215.22305v9.97865c0 .0697-.0312.1343-.0837.1767l-6.985 5.5752c-.0389.0313-.0847.0464-.1314.0464-.0466 0-.0924-.0151-.1313-.0464l-6.985-5.5752c-.05252-.0424-.08365-.107-.08365-.1767v-9.97865c0-.12313.0963-.22305.21497-.22305zm7.82148 7.0972 4.1275-2.71296c.1039-.06863.2299.04542.1725.15644l-1.7114 3.36192c-.0403.0807.0182.1756.1079.1756h1.0246c.118 0 .1664.1504.0706.219l-4.6267 3.3175c-.0414.0303-.0978.0303-.1402 0l-4.6267-3.3175c-.0948-.0686-.04639-.219.07059-.219h1.02356c.09076 0 .14925-.0949.10791-.1756l-1.71132-3.36293c-.05648-.11001.06958-.22305.17345-.15543l4.12851 2.71296c.0716.0474.1291.112.1674.1887l.6293 1.2636c.0444.0888.1714.0888.2158 0l.6293-1.2636c.0383-.0767.0958-.1423.1674-.1887z' fill='%23${palette.base0E}' fill-rule='evenodd'/%3E%3C/svg%3E");
    }
    div[class*=userPopoutOuter-] div[aria-label="HypeSquad Balance"],
    div[class*=userProfileOuter-] div[aria-label="HypeSquad Balance"] {
      content: url("data:image/svg+xml,%3Csvg height='24' viewBox='0 0 24 24' width='24' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath clip-rule='evenodd' d='m11.8622 4.05696c.076-.07595.1996-.07595.2756 0l7.8048 7.80474c.0371.0362.0574.0865.0574.1377 0 .0513-.0212.1016-.0574.1378l-7.8048 7.8047c-.038.038-.0883.0574-.1378.0574s-.0998-.0194-.1378-.0574l-7.8048-7.8047c-.03709-.0362-.0574-.0857-.0574-.1378s.02031-.1015.0574-.1377zm.9299 8.29474 3.6146-2.37377c.0909-.05917.2013.03977.151.13597l-1.4986 2.9416c-.0354.0707.0158.1537.0944.1537h.8973c.1033 0 .1457.1316.0618.1916l-4.0517 2.9028c-.0362.0265-.0856.0265-.1227 0l-4.05168-2.9028c-.08301-.06-.04062-.1916.06182-.1916h.89634c.07948 0 .1307-.083.09449-.1537l-1.49862-2.9416c-.04945-.0962.06094-.19514.1519-.13597l3.61545 2.37377c.0627.0415.113.098.1465.1651l.5511 1.1057c.0389.0777.1501.0777.189 0l.551-1.1057c.0336-.0671.0839-.1245.1466-.1651z' fill='%23${palette.base0C}' fill-rule='evenodd'/%3E%3C/svg%3E");
    }
    div[class*=userPopoutOuter-] div[aria-label="HypeSquad Brilliance"],
    div[class*=userProfileOuter-] div[aria-label="HypeSquad Brilliance"] {
      content: url("data:image/svg+xml,%3Csvg height='24' viewBox='0 0 24 24' width='24' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath clip-rule='evenodd' d='m12 20c4.4183 0 8-3.5817 8-8 0-4.41828-3.5817-8-8-8-4.41828 0-8 3.58172-8 8 0 4.4183 3.58172 8 8 8zm.7921-8.275 3.6146-2.3738c.0909-.05916.2013.03974.151.136l-1.4986 2.9416c-.0354.0707.0158.1537.0944.1537h.8973c.1033 0 .1457.1315.0618.1916l-4.0517 2.9027c-.0362.0265-.0856.0265-.1227 0l-4.05168-2.9027c-.08301-.0601-.04062-.1916.06182-.1916h.89634c.07948 0 .1307-.083.09449-.1537l-1.49862-2.9416c-.04945-.09626.06094-.19516.1519-.136l3.61545 2.3738c.0627.0415.113.098.1465.1651l.5511 1.1057c.0389.0777.1501.0777.189 0l.551-1.1057c.0336-.0671.0839-.1245.1466-.1651z' fill='%23${palette.base08}' fill-rule='evenodd'/%3E%3C/svg%3E");
    }
    div[class*=userPopoutOuter-] div[aria-label="Active Developer"],
    div[class*=userProfileOuter-] div[aria-label="Active Developer"] {
      content: url("data:image/svg+xml,%3Csvg width='24' height='24' viewBox='0 0 24 24' fill='none' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M6.47213 4L4 6.47213V17.5279L6.47217 20H17.5278L20 17.5279V6.47213L17.5279 4H6.47213ZM10.8582 16.4255H8.64551C8.64551 14.5952 7.1567 13.1064 5.32642 13.1064V10.8936C7.1567 10.8936 8.64551 9.40483 8.64551 7.57454H10.8582C10.8582 9.39042 9.96684 10.9908 8.61129 12C9.96684 13.0093 10.8582 14.6096 10.8582 16.4255ZM18.6667 13.1064C16.8364 13.1064 15.3476 14.5952 15.3476 16.4255H13.1348C13.1348 14.6096 14.0263 13.0093 15.3818 12C14.0263 10.9908 13.1348 9.39042 13.1348 7.57454H15.3476C15.3476 9.40483 16.8364 10.8936 18.6667 10.8936V13.1064V13.1064Z' fill='%23${palette.base0B}'/%3E%3C/svg%3E");
    }
    div[class*=userPopoutOuter-] div[aria-label="Early Verified Bot Developer"],
    div[class*=userProfileOuter-] div[aria-label="Early Verified Bot Developer"] {
      content: url("data:image/svg+xml,%3Csvg height='24' viewBox='0 0 24 24' width='24' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='m21.58 11.4-4.28-7.39-.35-.6h-9.91l-.35.6-4.27 7.39-.35.6.35.6 4.27 7.39.35.6h9.92l.35-.6 4.28-7.39.35-.6zm-13.07-1.03-1.63 1.63 1.63 1.63v2.73l-4.36-4.36 4.37-4.37v2.74zm3.12 6.93-2.04-.63 3.1-9.98 2.04.64zm3.86-.93v-2.73l1.63-1.64-1.63-1.63v-2.74l4.36 4.37z' fill='%23${palette.base0D}'/%3E%3C/svg%3E");
    }
    div[class*=userPopoutOuter-] div[class|=userPopoutOverlayBackground] > div[class|=scroller] > div[class|=section]:first-child > div[class|=buttonsContainer] > button:nth-child(2),
    div[class*=userProfileOuter-] div[class|=userPopoutOverlayBackground] > div[class|=scroller] > div[class|=section]:first-child > div[class|=buttonsContainer] > button:nth-child(2) {
      background: #${palette.base0D};
    }

    [class*=layerContainer-] [id|=slate-toolbar] {
      background-color: #${palette.base00};
    }
    [class*=layerContainer-] [id|=slate-toolbar] [class*=buttons-] [class*=icon-] {
      color: #${palette.base05};
    }

    [class*=layerContainer-] div[id=sort-and-view] div[id=sort-and-view-reset-all] [style="color: var(--text-normal);"]:hover {
      color: #${palette.base00} !important;
    }

    [class|=layerContainer] [class|=quickswitcher] [class*=badge-] {
      color: #${palette.base00};
    }
    rect[fill="#${palette.base0B}"],
    foreignObject[mask="url(#svg-mask-status-online)"] > div,
    div[class|=dotOnline],
    i[class|=statusOnline] {
      fill: #${palette.base0B} !important;
      background-color: #${palette.base0B} !important;
    }

    rect[fill="rgba(${palette.base0B}, 1)"] {
      fill: #${palette.base0B} !important;
    }

    rect[fill="#${palette.base09}"],
    foreignObject[mask="url(#svg-mask-status-idle)"] > div {
      fill: #${palette.base09} !important;
      background-color: #${palette.base09} !important;
    }

    rect[fill="rgba(${palette.base09}, 1)"] {
      fill: #${palette.base09} !important;
    }

    rect[fill="#${palette.base08}"],
    foreignObject[mask="url(#svg-mask-status-dnd)"] > div {
      fill: #${palette.base08} !important;
      background-color: #${palette.base08} !important;
    }

    rect[fill="rgba(${palette.base08}, 1)"] {
      fill: #${palette.base08} !important;
    }

    rect[fill="#${palette.base04}"],
    foreignObject[mask="url(#svg-mask-status-offline)"] > div,
    foreignObject[mask="url(#svg-mask-status-offline)"] > rect,
    div[class|=dotOffline],
    i[class|=statusOffline] {
      fill: #${palette.base04} !important;
      background-color: #${palette.base04} !important;
    }

    rect[fill="rgba(${palette.base04}, 1)"] {
      fill: #${palette.base04} !important;
    }

    rect[fill="#${palette.base0E}"] {
      fill: #${palette.base0E} !important;
    }

    .vc-platform-indicator svg[fill*="--green-"] {
      fill: #${palette.base0B};
    }

    .vc-platform-indicator svg[fill*="--yellow-"] {
      fill: #${palette.base09};
    }

    .vc-platform-indicator svg[fill*="--red-"] {
      fill: #${palette.base08};
    }

    .vc-platform-indicator svg[fill*="--primary-400"] {
      fill: #${palette.base04};
    }

    [src="/assets/eaeac24163b35f7526704a3d9b3c7722.svg"] {
      width: 0 !important;
      padding: 12px;
      height: 0 !important;
      -webkit-mask-image: url("https://discord.com/assets/eaeac24163b35f7526704a3d9b3c7722.svg");
      -webkit-mask-repeat: no-repeat;
      -webkit-mask-size: contain;
      background: #${palette.base0B};
    }

    .vc-user-connection [src="/assets/eaeac24163b35f7526704a3d9b3c7722.svg"] {
      padding: 16px;
    }

    #vencordthemes-tab [class*=input-]:focus {
      border-color: #${palette.base0D} !important;
    }

    svg[class|=cursorDefault] svg[class|=dots] circle {
      fill: #${palette.base00} !important;
    }

    [style*="background-color: hsl(235, calc(var(--saturation-factor, 1) * 85.6%), 64.7%)"] {
      background-color: #${palette.base0D} !important;
      color: #${palette.base00};
    }

    span[class*=username-][style*="color: #${palette.base00}"],
    span[class*=username-][style*="color: #${palette.base01}"] {
      color: #${palette.base00} !important;
    }

    div[class*=flowerStarContainer-][class*=boostedGuildTierIconBackgroundWithVisibleBanner] svg[class*=flowerStar-] * {
      fill: #${palette.base05};
    }
    div[class*=flowerStarContainer-][class*=boostedGuildTierIconBackgroundWithVisibleBanner] div[class|=childContainer] svg * {
      fill: #${palette.base00};
    }
    div[class*=flowerStarContainer-][class*=iconBackgroundTierOne-] svg[class*=flowerStar-] *, div[class*=flowerStarContainer-][class*=iconBackgroundTierTwo-]:not([class*=boostedGuildTierIconBackgroundWithVisibleBanner]) svg[class*=flowerStar-] * {
      fill: #${palette.base03};
    }
    div[class*=flowerStarContainer-][class*=iconBackgroundTierOne-] div[class|=childContainer] svg *, div[class*=flowerStarContainer-][class*=iconBackgroundTierTwo-]:not([class*=boostedGuildTierIconBackgroundWithVisibleBanner]) div[class|=childContainer] svg * {
      fill: #${palette.base05};
    }
    div[class*=flowerStarContainer-][class*=iconBackgroundTierThree-] svg[class*=flowerStar-] * {
      fill: #${palette.base0E};
    }
    div[class*=flowerStarContainer-][class*=iconBackgroundTierThree-] div[class|=childContainer] svg * {
      fill: #${palette.base00};
    }
    div[class*=flowerStarContainer-][class*=verified-] svg[class*=flowerStar-] * {
      fill: #${palette.base0B};
    }
    div[class*=flowerStarContainer-][class*=verified-] div[class|=childContainer] svg * {
      fill: #${palette.base00};
    }
    div[class*=flowerStarContainer-][class*=partnered-] svg[class*=flowerStar-] * {
      fill: #${palette.base0D};
    }
    div[class*=flowerStarContainer-][class*=partnered-] div[class|=childContainer] svg * {
      fill: #${palette.base00};
    }

    div[class|=communityInfoPill] {
      --background-accent: rgba(${palette.base02}, 0.7);
      color: #${palette.base05};
    }
    div[class|=communityInfoPill] div[class|=text] {
      font-weight: 500;
    }

    a[class*=socialLink-][href*=discord] {
      color: #${palette.base04};
    }

    svg[class|=uploadIcon] {
      color: #${palette.base00};
    }

    .theme-dark h2[class|=emptyStateHeader],
    .theme-light h2[class|=emptyStateHeader] {
      color: #${palette.base05};
    }
    .theme-dark p[class|=emptyStateSubtext],
    .theme-light p[class|=emptyStateSubtext] {
      color: #${palette.base04};
    }

    div[class*=unreadMentionsBar-],
    div[class*=unreadBar-] {
      color: #${palette.base00};
    }

    div[class|=numberBadge] {
      font-weight: 700;
      color: #${palette.base00};
    }

    div[class|=newChannel] {
      color: #${palette.base00};
      background-color: #${palette.base0D} !important;
    }

    div[class|=botTag] {
      background-color: #${palette.base0D};
    }

    div[class|=addFriendInputWrapper]:focus-within {
      border-color: #${palette.base03};
    }

    button[class|=attachButton] svg path[class|=attachButtonPlay] {
      color: #${palette.base0B};
      fill: #${palette.base0B};
    }

    div[class|=tags] div[class|=pinIcon] path {
      fill: #${palette.base01} !important;
    }

    div[class*=avatarSpeaking-] {
      -webkit-box-shadow: inset 0 0 0 2px #${palette.base0B}, inset 0 0 0 3px var(--background-secondary);
      box-shadow: inset 0 0 0 2px #${palette.base0B}, inset 0 0 0 3px var(--background-secondary);
    }

    div[class*=videoLayer-] > div[class|=tileChild] > div[class|=border][class*=speaking-] {
      -webkit-box-shadow: inset 0 0 0 2px #${palette.base0B}, inset 0 0 0 3px #${palette.base0B};
      box-shadow: inset 0 0 0 2px #${palette.base0B}, inset 0 0 0 3px #${palette.base0B};
    }
    div[class*=videoLayer-] > div[class|=tileChild] > div[class|=border][class*=voiceChannelEffect-] {
      -webkit-box-shadow: inset 0 0 0 2px #${palette.base0D}, inset 0 0 0 3px #${palette.base0D};
      box-shadow: inset 0 0 0 2px #${palette.base0D}, inset 0 0 0 3px #${palette.base0D};
    }

    div[class*=featureIcon-] path {
      fill: #${palette.base0D};
    }

    div[class*=backgroundAccent-] {
      color: #${palette.base00};
    }

    div[class*=profileBadges-] div[aria-label="Supports Commands"] img {
      content: url("data:image/svg+xml,%3Csvg viewBox='0 0 24 24' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='%23${palette.base0B}'%3E%3Cpath d='m8.1176653 16.0847263 4.8330812-8.1694527h2.9315882l-4.8330812 8.1694527z'/%3E%3Cpath d='m20.4189453 9.4038086v-2.4311524c0-1.9775391-1.0825195-3.1118164-2.9697266-3.1118164h-1.5581055v1.7802734l.9594727-.0014648c.8540039 0 1.34375.5683594 1.34375 1.5585938v2.3969727c0 .8300781.1806641 1.8422852 1.5893555 2.3100586l.2856445.0947265-.2856445.0947266c-1.4086914.4677734-1.5893555 1.4799804-1.5893555 2.3100586v2.3964844c0 .9907227-.4897461 1.559082-1.34375 1.559082l-.9594727-.0014648v1.7802734h1.5581055c1.887207 0 2.9697266-1.1342773 2.9697266-3.1118164v-2.4316406c0-1.2583008.3432617-1.6264648 1.5810547-1.6445312v-1.9023438c-1.237793-.0180665-1.5810547-.3862305-1.5810547-1.6450196z'/%3E%3Cpath d='m5.8061523 7.1982422c0-.9760742.5024414-1.5585938 1.3432617-1.5585938l.9594727.0014648v-1.7802734h-1.5576172c-1.887207 0-2.9697266 1.1342773-2.9697266 3.1118164v2.4311523c0 1.2587891-.3432617 1.6269531-1.581543 1.6450195v1.9023438c1.2382812.0180664 1.581543.3862305 1.581543 1.6445312v2.4316406c0 1.9775391 1.0825195 3.1118164 2.9697266 3.1118164h1.5576172v-1.7802734l-.9594727.0014648c-.8408203 0-1.3432617-.5830078-1.3432617-1.559082v-2.3964844c0-.8300781-.1806641-1.8422852-1.5898438-2.3100586l-.2856444-.0947264.2856445-.0947266c1.4091797-.4677734 1.5898437-1.4799804 1.5898437-2.3100586z'/%3E%3C/g%3E%3C/svg%3E");
    }

    div[class*=newBadge-],
    div[class*=tryItOutBadge-] {
      color: #${palette.base00};
    }

    [class|=tabBar] [class|=badge] {
      color: #${palette.base00};
    }

    span[class*=channelMention]:hover,
    [class*=mention]:not([class*=mentionButton-],
    [class*=mentionIcon-]):hover {
      color: #${palette.base00};
    }

    .theme-dark code.hljs {
      color: #${palette.base07};
      background: #${palette.base01};
    }
    .theme-dark code .hljs-keyword {
      color: #${palette.base0E};
    }
    .theme-dark code .hljs-built_in {
      color: #${palette.base08};
    }
    .theme-dark code .hljs-type {
      color: #${palette.base09};
    }
    .theme-dark code .hljs-literal {
      color: #${palette.base09};
    }
    .theme-dark code .hljs-number {
      color: #${palette.base09};
    }
    .theme-dark code .hljs-operator {
      color: #${palette.base0C};
    }
    .theme-dark code .hljs-punctuation {
      color: #${palette.base05};
    }
    .theme-dark code .hljs-property {
      color: #${palette.base0C};
    }
    .theme-dark code .hljs-regexp {
      color: #${palette.base0E};
    }
    .theme-dark code .hljs-string {
      color: #${palette.base0B};
    }
    .theme-dark code .hljs-char.escape_ {
      color: #${palette.base0B};
    }
    .theme-dark code .hljs-subst {
      color: #${palette.base05};
    }
    .theme-dark code .hljs-symbol {
      color: #${palette.base08};
    }
    .theme-dark code .hljs-variable {
      color: #${palette.base0E};
    }
    .theme-dark code .hljs-variable.language_ {
      color: #${palette.base0E};
    }
    .theme-dark code .hljs-variable.constant_ {
      color: #${palette.base09};
    }
    .theme-dark code .hljs-title {
      color: #${palette.base0D};
    }
    .theme-dark code .hljs-title.class_ {
      color: #${palette.base09};
    }
    .theme-dark code .hljs-title.function_ {
      color: #${palette.base0D};
    }
    .theme-dark code .hljs-params {
      color: #${palette.base05};
    }
    .theme-dark code .hljs-comment {
      color: #${palette.base03};
    }
    .theme-dark code .hljs-doctag {
      color: #${palette.base08};
    }
    .theme-dark code .hljs-meta {
      color: #${palette.base09};
    }
    .theme-dark code .hljs-section {
      color: #${palette.base0D};
    }
    .theme-dark code .hljs-tag {
      color: #${palette.base05};
    }
    .theme-dark code .hljs-name {
      color: #${palette.base0E};
    }
    .theme-dark code .hljs-attr {
      color: #${palette.base0D};
    }
    .theme-dark code .hljs-attribute {
      color: #${palette.base0B};
    }
    .theme-dark code .hljs-bullet {
      color: #${palette.base0C};
    }
    .theme-dark code .hljs-code {
      color: #${palette.base0B};
    }
    .theme-dark code .hljs-emphasis {
      color: #${palette.base08};
      font-style: italic;
    }
    .theme-dark code .hljs-strong {
      color: #${palette.base08};
      font-weight: bold;
    }
    .theme-dark code .hljs-formula {
      color: #${palette.base0C};
    }
    .theme-dark code .hljs-link {
      color: #${palette.base0D};
      font-style: italic;
    }
    .theme-dark code .hljs-quote {
      color: #${palette.base0B};
      font-style: italic;
    }
    .theme-dark code .hljs-selector-tag {
      color: #${palette.base09};
    }
    .theme-dark code .hljs-selector-id {
      color: #${palette.base0D};
    }
    .theme-dark code .hljs-selector-class {
      color: #${palette.base0C};
    }
    .theme-dark code .hljs-selector-attr {
      color: #${palette.base0E};
    }
    .theme-dark code .hljs-selector-pseudo {
      color: #${palette.base0C};
    }
    .theme-dark code .hljs-template-tag {
      color: #${palette.base05};
    }
    .theme-dark code .hljs-template-variable {
      color: #${palette.base05};
    }
    .theme-dark code .hljs-diff-addition {
      color: #${palette.base0B};
      background: rgba(${palette.base0B}, 0.15);
    }
    .theme-dark code .hljs-diff-deletion {
      color: #${palette.base08};
      background: rgba(${palette.base08}, 0.15);
    }

    .pngImage-1vIgLy:hover, .lottieCanvas-c2HE82 {
        background-color: transparent !important;
    }

    .colorStreamerMode-8uoRWd {
        background-color: #${palette.base0E};
        color: #${palette.base07};
    }

    div[class|=notice] button[class|=button] {
        border-color: #${palette.base07};
        color: #${palette.base07};
    }

    div[class|=notice] button[class|=button]:hover {
        background: #${palette.base07};
      color: #${palette.base00};
    }

    div[class|=notice] div[class|=closeButton] > svg > path {
        fill: #${palette.base07};
    }

    [class|=chatContent] code.inline {
        background: #${palette.base00};
    }

    .contents-3NembX .button-ejjZWC {
        color: #${palette.base00};
    }

    .gradientBackground-MytxDL {
      background: #${palette.base0E};
    }

    .upsellText-29l7Q- {
        color: #${palette.base07};
        margin-left: 6px;
    }

    .contents-3NembX {
      color: #${palette.base07};
    }

    .icon-2O29O0 {
        background-color: transparent;
    }

    div[class|=newChannel] {
        color: #${palette.base00};
        background-color: #${palette.base0A} !important;
    }

    .fakeActivityIcon-KeXVoI.activityCharacterWumpus-31wmZ9 {
        background-color: #${palette.base02};
    }

    .theme-dark .customColorPicker-C_jddW {
        background: #${palette.base00};
        border-color: #${palette.base00};
    }

    .grabber-3R-Rx9 {
      background-color: #${palette.base07};
    }

    div[class|=contentRegion] [class|=bar], div[class|=contentRegion] [class|=markDash] {
        background: #${palette.base02};
    }

    .theme-dark .checkbox-1LuCGM {
        border-color: transparent;
    }

    .lookFilled-1H2Jvj.colorBrand-2M3O3N {
        color: #${palette.base07};
        background-color: #${palette.base0A};
    }

    .lookFilled-1H2Jvj.colorRed-2VFhM4 {
        color: #${palette.base07};
        background-color: #${palette.base0A};
    }

    .lookFilled-1H2Jvj.colorRed-2VFhM4:hover {
        background-color: #${palette.base09};
    }

    .lookFilled-1H2Jvj.colorBrand-2M3O3N:hover {
        background-color: #${palette.base09};
    }

    .lookInverted-2GrLaB.colorBrand-2M3O3N {
        color: #${palette.base0D};
        background-color: #${palette.base0E};
    }

    .lookInverted-2GrLaB.colorBrand-2M3O3N:hover {
        background-color: #${palette.base0D};
    }

    .theme-dark p[class|=emptyStateSubtext], .theme-light p[class|=emptyStateSubtext] {
        color: #${palette.base04};
    }


    div[class|=contentRegion] #discord-nitro-tab button[class*=lookInverted-] {
        color: #${palette.base07};
        background-color: #${palette.base0E};
    }

    div[class|=contentRegion] #discord-nitro-tab button[class*=lookInverted-]:hover {
        background-color: #${palette.base0D};
    }

    div[class|=contentRegion] #keybinds-tab span[class*=key] {
        color: #${palette.base07};
    }

    div[class|=layerContainer] div[class|=addGamePopout] {
        background-color: #${palette.base00};
    }

    div[class|=contentRegion] #accessibility-tab button[class*=colorBrandNew] {
        background-color: #${palette.base0A};
    }

    .reactionInner-YJjOtT {
      background-color: #${palette.base01};
    }

    div[class|=contentRegion] #guild_premium-tab div[class|=tierHeaderUnlocked] div[class|=tierUnlocked], div[class|=contentRegion] #guild_premium-tab div[class|=tierHeaderLocked] div[class|=tierUnlocked] {
        background-image: linear-gradient(90deg, #${palette.base0D}, #${palette.base0E});
        color: #${palette.base07};
        font-weight: 600;
    }

    .lookFilled-1H2Jvj.colorBrandNew-abZT3v:disabled, .lookFilled-1H2Jvj.colorBrandNew-abZT3v[aria-disabled=true] {
        background-color: #${palette.base09};
    }

    .text-sm-normal-AEQz4v {
      color: #${palette.base06};
    }

    div[class|=callContainer] div[class|=videoControls] [class*=colorable-][class*=white-] {
        color: #${palette.base06};
        background-color: #${palette.base03};
    }

    div[class|=callContainer] div[class|=videoControls] [class*=colorable-][class*=white-]:hover, div[class|=callContainer] div[class|=videoControls] [class*=colorable-][class*=white-][class*=active-] {
        color: #${palette.base06};
        background-color: #${palette.base03};
    }

    div[class|=callContainer] div[class|=videoControls] [class*=colorable-][class*=primaryDark-] {
        background: #${palette.base02};
    }
    div[class|=callContainer] div[class|=videoControls] [class*=colorable-][class*=primaryDark-] {
        background: #${palette.base02};
      color: #${palette.base05};
    }

    div[class|=callContainer] div[class|=videoControls] button[class*=leftTrayIcon-][class*=buttonColor-] {
        background-color: #${palette.base02};
        color: #${palette.base07};
    }

    [class|=chatContent] div[class*=wrapperAudio-] div[class*=audioControls], [class|=chatContent] div[class*=wrapperAudio-] div[class*=videoControls-], [class|=chatContent] div[class*=imageWrapper-] div[class*=audioControls], [class|=chatContent] div[class*=imageWrapper-] div[class*=videoControls-] {
        background-color: rgba(${palette.base00}, 0.8);
    }

    div[class|=chat] > div[class|=content] > div[class|=container] div[class|=newBadge] {
        background-color: #${palette.base0D} !important;
        color: #${palette.base00};
    }

    div[class|=callContainer] div[class|=videoControls] div[class|=toolbar] div[class|=streamQualityIndicator] div[class|=liveQualityIndicator] {
        background-color: #${palette.base00} !important;
    }

    .qualityResolution-RP9GCP {
        margin-right: 4px;
        color: #${palette.base07};
        background-color: #${palette.base00};
    }

    div[class|=callContainer] div[class|=videoControls] div[class|=children] div[class*=playingText-] {
        color: #${palette.base07};
    }

    .grid-21dB-S>div:first-child, .headerRow-1MKoR-, .list-3FIpnh>div:first-child {
        min-width: 480px;
        width: 100%;
        position: relative;
        background-color: #${palette.base00};
    }

    div[class|=callContainer] div[class|=videoControls] [class*=colorable-][class*=primaryDark-] [class*=centerIcon-] {
        color: #${palette.base07};
    }

    div[class|=callContainer] [class*=controlIcon-] {
        color: #${palette.base05};
    }

    div[class|=callContainer] [class*=controlIcon-]:hover {
        color: #${palette.base05};
    }

    div[class|=callContainer] div[class|=videoControls] div[class|=toolbar] div[class|=streamQualityIndicator] div[class|=liveQualityIndicator] div[class|=qualityIndicator] {
        background-color: #${palette.base01};
        color: #${palette.base07};
    }

    div[class|=callContainer] div[class|=videoControls] div[class|=toolbar] div[class|=streamQualityIndicator] div[class|=liveQualityIndicator] svg[class|=premiumStreamIcon] {
        color: #${palette.base07};
    }

    div[class|=layerContainer] [role=menu] [class*=colorDefault][class*=colorBrand] {
        color: #${palette.base0D};
    }

    .item-5ApiZt:hover {
        color: #${palette.base00};
        background-color: #${palette.base0A};
    }

    .colorDefault-2_rLdz .checkbox-397WsK, .colorDefault-2_rLdz .radioSelection-3PDNAQ {
        color: #${palette.base05};
    }

    .colorDefault-2_rLdz .checkbox-397WsK, .colorDefault-2_rLdz .radioSelection-3PDNAQ:hover {
        fill: #${palette.base05};
    }

    .emojiButton-3FRTuj {
        background-color: #${palette.base00} !important;
    }

    .unreadIcon-3dqgX9, .voiceChannelsIcon-2smmeE {
        display: none;
    }

    .button-3_1yil, .notice-12Koq- {
        background-color: #${palette.base0A};
    }

    div[class|=notice] button[class|=button] {
        border-color: #${palette.base00};
    }

    div[class|=notice] button[class|=button]:hover {
        background: #${palette.base0A};
        color: #${palette.base00};
    }

    .text-md-medium-2n7Vn5, .text-md-normal-2rFCH3 {
        color: #${palette.base07} !important;
    }

    .controlIcon-10O-4h {
        color: #${palette.base07} !important;
    }

    .theme-dark .categoryFadeBlurple-1l49_Q, .theme-light .categoryFadeBlurple-1l49_Q  {
        background-color: rgba(${palette.base03}, 0.8);
    }

    .theme-dark .categoryFadeBlurple-1l49_Q:hover, .theme-light .categoryFadeBlurple-1l49_Q:hover {
        background-color: rgba(${palette.base03}, 0.8);
    }

    .pngImage-1vIgLy:hover, .lottieCanvas-c2HE82 {
        background-color: #${palette.base03};
    }

    .theme-dark div[class|=spoilerContainer] div[class|=spoilerWarning], .theme-light div[class|=spoilerContainer] div[class|=spoilerWarning] {
        color: #${palette.base07};
        background-color: rgba(${palette.base00}, 0.7);
    }

    div[class*=userInfoSection-] div[class|=connectedAccountContainer] {
        background-color: #${palette.base00} !important;
    }

    .editIcon-3h_5Rm {
        color: #${palette.base07};
    }

    .iconBadge-3Mmg92 {
        background-color: #${palette.base08};
    }

    .theme-dark svg[class*=threadIcon-], .theme-light svg[class*=threadIcon-] {
        color: #${palette.base05} !important;
    }

    div[class|=notice] button[class|=button] {
        color: #${palette.base00};
    }

    div[class|=notice] button[class|=button]:hover {
        border-color: #${palette.base00};
    }

    .closeIcon-3eoP1e {
        filter: brightness(0) !important;
    }

    .assetWrapperMasked-1iw9lV {
        background-color: #${palette.base02};
    }

    .lookFilled-1H2Jvj.colorGreen-jIPCAS, .lookFilled-1H2Jvj.colorGreen-jIPCAS:hover{
        background-color: #${palette.base0B};
    }

    a[class*=socialLink-][href*=discord] {
        color: #${palette.base05};
    }

    .reaction-102jx9.reactionMe-2zhiyZ .reactionCount-SWXh9W {
        color: #${palette.base07};
    }

    .updateReactionButton-13dIN9>div {
        background: #${palette.base05};
    }

    svg[class|=spine] {
        color: #${palette.base02};
    }

    div[class|=spineBorder] {
        background: #${palette.base02};
    }

    ul[aria-label$=" threads"] > li:nth-child(2n) {
        --channels-default: #${palette.base04};
    }

    .clickable_d23a1a .icon__4cb88, .clickable_d23a1a .icon__4cb88:hover {
        color: #${palette.base07};
    }

    .button__66e8c .buttonColor_a6eb73.buttonActive__407a7, .button__66e8c.buttonColor_a6eb73.buttonActive__407a7 {
        background-color: #${palette.base0B};
        color: #${palette.base07};
    }

    .button__66e8c .buttonColor_a6eb73.buttonActive__407a7:hover, .button__66e8c.buttonColor_a6eb73.buttonActive__407a7:hover {
        background-color: #${palette.base0B};
    }

    .gradientBackground_aa82b3 {
        display: none;
    }

    .theme-dark .footerSeparator__57d95 {
        background-color: #${palette.base00};
    }
  '';
  themeFileLocation =
    if pkgs.stdenv.isDarwin
    then "Library/Application Support/vesktop/themes/gruvbox.theme.css"
    else ".config/vesktop/themes/gruvbox.theme.css";
  vesktopSettingsLocation =
    if pkgs.stdenv.isDarwin
    then "Library/Application Support/vesktop/settings.json"
    else ".config/vesktop/settings.json";
  vesktopDetailedSettingsLocation =
    if pkgs.stdenv.isDarwin
    then "Library/Application Support/vesktop/settings/settings.json"
    else ".config/vesktop/settings/settings.json";
in {
  # if is darwin, create a derivation for vesktop package..
  home.packages = with pkgs; [
    vesktop
  ];

  # To prevent discord from checking for new versions.
  home.file = {
    ".config/discord/settings.json" = {
      text = builtins.toJSON {
        SKIP_HOST_UPDATE = true;
        chromiumSwitches = {}; # wtf is this?
        IS_MAXIMIZED = false; # not respected?
        IS_MINIMIZED = false;
        # not respected?
        WINDOW_BOUNDS = {
          x = 727;
          y = 65;
          width = 1920;
          height = 1080;
        };
        THEME = "Dark"; # not respected?
        DANGEROUS_ENABLE_DEVTOOLS_ONLY_IF_YOU_KNOW_WHAT_YOU_ARE_DOING = true;
        BACKGROUND_COLOR = "#${config.colorScheme.palette.base00}"; # not respected?
        OPEN_ON_STARTUP = true; # not respected?
      };
    };
    ${vesktopSettingsLocation} = lib.mkForce {
      force = true;
      text = builtins.toJSON vesktopSettings;
    };
    ${vesktopDetailedSettingsLocation} = lib.mkForce {
      force = true;
      text = builtins.toJSON vesktopDetailedSettings;
    };
    ${themeFileLocation} = lib.mkForce {
      force = true;
      text = gruvboxTheme;
    };
  };
}
# bottom of page!

