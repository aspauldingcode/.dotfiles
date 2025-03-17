defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
defaults write -g QLPanelAnimationDuration -float 0
defaults write com.apple.dock autohide-time-modifier -float 0
defaults write com.apple.dock launchanim -bool false
sudo sysctl debug.lowpri_throttle_enabled=0

# There are in general many services used by Apple
# So if you find any other useless service that can be removed please leave a comment
# use the following to see all services in play: `launchctl list`
# Some general services that I don't use 
sudo launchctl remove com.apple.CallHistoryPluginHelper
sudo launchctl remove com.apple.AddressBook.abd
sudo launchctl remove com.apple.ap.adprivacyd
sudo launchctl remove com.apple.ReportPanic
sudo launchctl remove com.apple.ReportCrash
sudo launchctl remove com.apple.ReportCrash.Self
sudo launchctl remove com.apple.DiagnosticReportCleanup.plist
sudo launchctl remove com.apple.siriknowledged
sudo launchctl remove com.apple.helpd
sudo launchctl remove com.apple.mobiledeviceupdater
sudo launchctl remove com.apple.screensharing.MessagesAgent
sudo launchctl remove com.apple.TrustEvaluationAgent
sudo launchctl remove com.apple.iTunesHelper.launcher
sudo launchctl remove com.apple.softwareupdate_notify_agent
sudo launchctl remove com.apple.appstoreagent
sudo launchctl remove com.apple.familycircled

# I don't use Safari so...
sudo launchctl remove com.apple.SafariCloudHistoryPushAgent
sudo launchctl remove com.apple.Safari.SafeBrowsing.Service
sudo launchctl remove com.apple.SafariNotificationAgent
sudo launchctl remove com.apple.SafariPlugInUpdateNotifier
sudo launchctl remove com.apple.SafariHistoryServiceAgent
sudo launchctl remove com.apple.SafariLaunchAgent
sudo launchctl remove com.apple.SafariPlugInUpdateNotifier
sudo launchctl remove com.apple.safaridavclient

_service' \
'com.apple.assistantd' \
'com.apple.assistant_cdmd' \
'com.apple.avconferenced' \
'com.apple.BiomeAgent' \
'com.apple.biomesyncd' \
'com.apple.calaccessd' \
'com.apple.CallHistoryPluginHelper' \
'com.apple.cloudd' \
'com.apple.cloudpaird' \
'com.apple.cloudphotod' \
'com.apple.CloudSettingsSyncAgent' \
'com.apple.CommCenter-osx' \
'com.apple.ContextStoreAgent' \
'com.apple.CoreLocationAgent' \
'com.apple.corespeechd' \
'com.apple.dataaccess.dataaccessd' \
'com.apple.duetexpertd' \
'com.apple.familycircled' \
'com.apple.familycontrols.useragent' \
'com.apple.familynotificationd' \
'com.apple.financed' \
'com.apple.findmy.findmylocateagent' \
'com.apple.followupd' \
'com.apple.gamed' \
'com.apple.generativeexperiencesd' \
'com.apple.geoanalyticsd' \
'com.apple.geodMachServiceBridge' \
'com.apple.homed' \
'com.apple.icloud.fmfd' \
'com.apple.iCloudNotificationAgent' \
'com.apple.icloudmailagent' \
'com.apple.iCloudUserNotifications' \
'com.apple.icloud.searchpartyuseragent' \
'com.apple.imagent' \
'com.apple.imautomatichistorydeletionagent' \
'com.apple.imtransferagent' \
'com.apple.inputanalyticsd' \
'com.apple.intelligenceflowd' \
'com.apple.intelligencecontextd' \
'com.apple.intelligenceplatformd' \
'com.apple.itunescloudd' \
'com.apple.knowledge-agent' \
'com.apple.knowledgeconstructiond' \
'com.apple.ManagedClientAgent.enrollagent' \
'com.apple.Maps.pushdaemon' \
'com.apple.Maps.mapssyncd' \
'com.apple.maps.destinationd' \
'com.apple.mediaanalysisd' \
'com.apple.mediastream.mstreamd' \
'com.apple.naturallanguaged' \
'com.apple.newsd' \
'com.apple.parsec-fbf' \
'com.apple.parsecd' \
'com.apple.passd' \
'com.apple.photoanalysisd' \
'com.apple.photolibraryd' \
'com.apple.progressd' \
'com.apple.protectedcloudstorage.protectedcloudkeysyncing' \
'com.apple.quicklook' \
'com.apple.quicklook.ui.helper' \
'com.apple.quicklook.ThumbnailsAgent' \
'com.apple.rapportd-user' \
'com.apple.remindd' \
'com.apple.routined' \
'com.apple.screensharing.agent' \
'com.apple.screensharing.menuextra' \
'com.apple.screensharing.MessagesAgent' \
'com.apple.ScreenTimeAgent' \
'com.apple.SSInvitationAgent' \
'com.apple.security.cloudkeychainproxy3' \
'com.apple.sharingd' \
'com.apple.sidecar-hid-relay' \
'com.apple.sidecar-relay' \
'com.apple.siriactionsd' \
'com.apple.Siri.agent' \
'com.apple.siriinferenced' \
'com.apple.sirittsd' \
'com.apple.SiriTTSTrainingAgent' \
'com.apple.macos.studentd' \
'com.apple.siriknowledged' \
'com.apple.suggestd' \
'com.apple.tipsd' \
'com.apple.telephonyutilities.callservicesd' \
'com.apple.TMHelperAgent' \
'com.apple.triald' \
'com.apple.universalaccessd' \
'com.apple.UsageTrackingAgent' \
'com.apple.videosubscriptionsd' \
'com.apple.voicebankingd' \
'com.apple.weatherd')

for agent in "${TODISABLE[@]}"
do
	launchctl bootout gui/501/${agent}
	launchctl disable gui/501/${agent}
done


# system
TODISABLE=()

TODISABLE+=('com.apple.analyticsd' \
'com.apple.audioanalyticsd' \
'com.apple.backupd' \
'com.apple.backupd-helper' \
'com.apple.biomed' \
'com.apple.biometrickitd' \
'com.apple.cloudd' \
'com.apple.coreduetd' \
'com.apple.dhcp6d' \
'com.apple.ecosystemanalyticsd' \
'com.apple.familycontrols' \
'com.apple.findmymac' \
'com.apple.findmymacmessenger' \
'com.apple.ftp-proxy' \
'com.apple.GameController.gamecontrollerd' \
'com.apple.icloud.findmydeviced' \
'com.apple.icloud.searchpartyd' \
'com.apple.locationd' \
'com.apple.ManagedClient.cloudconfigurationd' \
'com.apple.modelcatalogd' \
'com.apple.modelmanagerd' \
'com.apple.netbiosd' \
'com.apple.rapportd' \
'com.apple.screensharing' \
'com.apple.triald.system' \
'com.apple.wifianalyticsd')

for daemon in "${TODISABLE[@]}"
do
	sudo launchctl bootout system/${daemon}
	sudo launchctl disable system/${daemon}
done#!/bin/zsh
# WARNING! The script is meant to show how and what can be disabled. Don’t use it as it is, adapt it to your needs.
# Credit: Original idea and script disable.sh by pwnsdx https://gist.github.com/pwnsdx/d87b034c4c0210b988040ad2f85a68d3
# Disabling unwanted services on macOS Big Sur (11), macOS Monterey (12), macOS Ventura (13), macOS Sonoma (14) and macOS Sequoia (15)
# Disabling SIP is required  ("csrutil disable" from Terminal in Recovery)
# Modifications are written in /private/var/db/com.apple.xpc.launchd/ disabled.plist, disabled.501.plist
# To revert, delete /private/var/db/com.apple.xpc.launchd/ disabled.plist and disabled.501.plist and reboot; sudo rm -r /private/var/db/com.apple.xpc.launchd/*


# user
TODISABLE=()

TODISABLE+=('com.apple.accessibility.MotionTrackingAgent' \
'com.apple.accessibility.axassetsd' \
'com.apple.AMPArtworkAgent' \
'com.apple.AMPLibraryAgent' \
'com.apple.amsengagementd' \
'com.apple.ap.adprivacyd' \
'com.apple.ap.promotedcontentd' \
'com.apple.assistant
