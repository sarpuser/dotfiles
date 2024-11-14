#!/bin/bash

# Tested on Sonoma

# TODO: Menu Bar items (hide certain things and reorder)
# TODO: Default Mail app -> Spark
# TODO: Default Browser -> Arc (already done in mac-setup.sh using brew app)
# TODO: Screensaver start time & Settings
# TODO: Change Function key to emojis
# TODO: Disable setting "Rearrange spaces automatically"

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Settings" to quit'

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until `mac-settings` has finished
while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
done 2>/dev/null &

###############################################################################
# Functions                                                                   #
###############################################################################

setComputerName() {
    read -r -p "Enter computer name ($(scutil --get ComputerName))" response
    if [[ -n $response ]]; then
        sudo scutil --set ComputerName "$response"
        sudo scutil --set HostName "$response"
        sudo scutil --set LocalHostName "$response"
        sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$response"
    fi
}

__dock_item() {
    local tiletype="${1-file}"
    local path="$2"
    printf "%s%s%s%s%s%s%s%s%s%s%s%s"\
        '<dict>'\
            '<key>tile-data</key> <dict>'\
                '<key>file-data</key> <dict>'\
                    '<key>_CFURLString</key> <string>' "$path" '</string>'\
                    '<key>_CFURLStringType</key> <integer>0</integer>'\
                '</dict>'\
                \
                '<key>file-type</key> <integer>3</integer>'\
            '</dict>'\
            \
            '<key>tile-type</key> <string>'"$tiletype"'-tile</string>'\
        '</dict>'
}

# FIXME: set finder sidebar items without accesibility permissions
setFinderSidebarItems() {
   local currentApp="$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true')"
    osascript -e '
    tell application "System Preferences"
      activate
      delay 0.1
      reveal anchor "Privacy_Accessibility" of pane id "com.apple.settings.PrivacySecurity.extension"
    end tell
    '
    echo "⚠️ $currentApp needs permission to control this computer to set Finder's sidebar items."
    confirm "Have you added $currentApp to the Accessibility list?" && {
        osascript -e "
        quit application \"System Preferences\"
        activate application \"Finder\"

        tell application \"System Events\"
            tell process \"Finder\"

                select menu bar 1
                click menu bar item \"Finder\" of menu bar 1
                click menu 1 of menu bar item \"Finder\" of menu bar 1
                click menu item \"Settings…\" of menu 1 of menu bar item \"Finder\" of menu bar 1

                repeat until exists window \"Finder Settings\"
                end repeat

                click button \"Sidebar\" of toolbar 1 of window \"Finder Settings\"

                -- Uncheck recents
                if (value of checkbox 1 of scroll area 1 of window \"Finder Settings\" as boolean) then
                    click checkbox 1 of scroll area 1 of window \"Finder Settings\"
                end if

                -- Check home folder
                if not (value of checkbox 10 of scroll area 1 of window \"Finder Settings\" as boolean) then
                    click checkbox 10 of scroll area 1 of window \"Finder Settings\"
                end if

                -- Check iCloud Drive
                if not (value of checkbox 11 of scroll area 1 of window \"Finder Settings\" as boolean) then
                    click checkbox 11 of scroll area 1 of window \"Finder Settings\"
                end if

                -- Uncheck Shared
                if (value of checkbox 12 of scroll area 1 of window \"Finder Settings\" as boolean) then
                    click checkbox 12 of scroll area 1 of window \"Finder Settings\"
                end if

                -- Uncheck Computer
                if (value of checkbox 13 of scroll area 1 of window \"Finder Settings\" as boolean) then
                    click checkbox 13 of scroll area 1 of window \"Finder Settings\"
                end if

                -- Check Hard Drives
                if not (value of checkbox 14 of scroll area 1 of window \"Finder Settings\" as boolean) then
                    click checkbox 14 of scroll area 1 of window \"Finder Settings\"
                end if

                -- Check External Drives
                if not (value of checkbox 15 of scroll area 1 of window \"Finder Settings\" as boolean) then
                    click checkbox 15 of scroll area 1 of window \"Finder Settings\"
                end if

                -- Check Removable Media
                if not (value of checkbox 16 of scroll area 1 of window \"Finder Settings\" as boolean) then
                    click checkbox 16 of scroll area 1 of window \"Finder Settings\"
                end if

                -- Uncheck Cloud Storage
                if (value of checkbox 17 of scroll area 1 of window \"Finder Settings\" as boolean) then
                    click checkbox 17 of scroll area 1 of window \"Finder Settings\"
                end if

                -- Uncheck Tags
                if (value of checkbox 20 of scroll area 1 of window \"Finder Settings\" as boolean) then
                    click checkbox 20 of scroll area 1 of window \"Finder Settings\"
                end if

            end tell
        end tell
        tell application \"Finder\" to close its windows
        activate application \"$currentApp\"
        "
    }
}

setLoginWindowText() {
    confirm "Do you want to set a login message?" && {
        read -r -p "Enter login message: " message
        defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText -string "$message"
    }
}

###############################################################################
# General UI/UX                                                               #
###############################################################################

# Set computer name (as done via System Preferences → Sharing)
setComputerName

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Automatically quit printer app once the print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Change first day of the week to Monday
defaults write NSGlobalDomain AppleFirstWeekday -dict gregorian 2

# Use Celcius
defaults write NSGlobalDomain AppleTemperatureUnit -string "Celcius"

# Add Turkish to preferred languages
defaults write NSGlobalDomain AppleLanguages -array-add "tr-US"

# 24 Hour Time
defaults write NSGlobalDomain AppleICUForce24HourTime -int 1

# Always show scrollbars
defaults write NSGlobalDomain AppleShowScrollBars -string "Automatic"
# Possible values: `WhenScrolling`, `Automatic` and `Always`

# Jump's to the spot that's clicked on the scroll bar
defaults write NSGlobalDomain AppleScrollerPagingBehavior -int 1

# Set light/dark mode to auto
defaults write NSGlobalDomain AppleInterfaceStyleSwitchesAutomatically -int 1

# Set accent & highlight color to orange
defaults write NSGlobalDomain AppleAccentColor -int 1
defaults write NSGlobalDomain AppleHighlightColor -string "1.000000 0.874510 0.701961 Orange";

# Set title bar menu click action
defaults write NSGlobalDomain AppleActionOnDoubleClick -string "Minimize"

# Always prefer tabs to windows
defaults write NSGlobaldomain AppleWindowTabbingMode -string "always"

# Increase Bluetooth Audio bitrate & resolution
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

# Control (^) + scroll to zoom
defaults write com.apple.universalaccess closeViewScrollWheelToggle -int 1

# Disable Game Center
defaults write com.apple.gamed Disabled -bool true

###############################################################################
# Siri                                                                    #
###############################################################################

# Disable Siri in the lock screen
defaults write com.apple.Siri LockscreenEnabled -int 0

###############################################################################
# Dock, Dashboard, and hot corners                                            #
###############################################################################

# Set up hot corners
# Possible values:
#  0: no-op
#  2: Mission Control
#  3: Show application windows
#  4: Desktop
#  5: Start screen saver
#  6: Disable screen saver
#  7: Dashboard
# 10: Put display to sleep
# 11: Launchpad
# 12: Notification Center
# 13: Lock Screen
defaults write com.apple.dock wvous-tr-corner -int 0   # Top left screen corner → none
defaults write com.apple.dock wvous-tr-modifier -int 0 # Top left screen corner modifier → none
defaults write com.apple.dock wvous-tl-corner -int 0   # Top right screen corner → none
defaults write com.apple.dock wvous-tl-modifier -int 0 # Top right screen corner modifier → none
defaults write com.apple.dock wvous-br-corner -int 0   # Bottom left screen corner → none
defaults write com.apple.dock wvous-br-modifier -int 0 # Bottom left screen corner modifier → none
defaults write com.apple.dock wvous-bl-corner -int 0   # Bottom right screen corner → none
defaults write com.apple.dock wvous-bl-modifier -int 0 # Bottom right screen corner modifier → none

# Automatically hide and show the Dock
defaults write com.apple.dock autohide -bool true

# Auto-hide delay = 0
defaults write com.apple.Dock "autohide-delay" -int 0

# Don’t show recent applications in Dock
defaults write com.apple.dock show-recents -bool false

# Increase the dock magnification size
defaults write com.apple.dock largesize -float 96

# Group apps in mission control
defaults write com.apple.Dock "expose-group-apps" -int 1

# Magnification
defaults write com.apple.Dock magnification -int 1

# Minimize to application
defaults write com.apple.Dock "minimize-to-application" -int 1

# Enable App Expose gesture
defaults write com.apple.Dock showAppExposeGestureEnabled -int 1

# Enable Mission Control Gesture
defaults write com.apple.Dock showMissionControlGestureEnabled -int 1

# App Expose on icon
defaults write com.apple.dock "scroll-to-open" -bool "true"

# Clear Dock
defaults write com.apple.Dock persistent-apps -array
defaults write com.apple.Dock persistent-others -array

# Add apps to Dock
defaults write com.apple.Dock persistent-apps -array-add "$(__dock_item /Applications/Arc.app)"
defaults write com.apple.Dock persistent-apps -array-add "$(__dock_item /Applications/Spotify.app)"
defaults write com.apple.Dock persistent-apps -array-add "$(__dock_item /System/Applications/Photos.app)"
defaults write com.apple.Dock persistent-apps -array-add "$(__dock_item /System/Applications/Facetime.app)"
defaults write com.apple.Dock persistent-apps -array-add "$(__dock_item /System/Applications/Messages.app)"
defaults write com.apple.Dock persistent-apps -array-add "$(__dock_item /System/Applications/Calendar.app)"
defaults write com.apple.Dock persistent-apps -array-add "$(__dock_item /System/Applications/Notes.app)"
defaults write com.apple.Dock persistent-apps -array-add "$(__dock_item /Applications/Spark.app)"
defaults write com.apple.Dock persistent-apps -array-add "$(__dock_item /Applications/Visual\ Studio\ Code.app)"
defaults write com.apple.Dock persistent-apps -array-add "$(__dock_item /Applications/Alacritty.app)"
defaults write com.apple.Dock persistent-apps -array-add "$(__dock_item /Applications/Things3.app)"

# Add folders to Dock
defaults write com.apple.Dock persistent-others -array-add "$(__dock_item directory "/Users/$USER/Downloads")"
defaults write com.apple.Dock persistent-others -array-add "$(__dock_item directory /Applications)"

# Stack items by kind in the Desktop
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:GroupBy Kind" ~/Library/Preferences/com.apple.finder.plist

###############################################################################
# Finder                                                                      #
###############################################################################

# When performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Use list view in all Finder windows by default
# Four-letter codes for all the views: Icons (icnv), List (nlsv), Columns (clmv), and Gallery (glyv) - https://krypted.com/mac-os-x/change-default-finder-views-using-defaults/
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Show the ~/Library folder
chflags nohidden ~/Library && xattr -d com.apple.FinderInfo ~/Library

# Finder: show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Finder: show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Set Documents as the default location for new Finder windows
# For other paths, use `PfLo` and `file:///full/path/here/`
# defaults write com.apple.finder NewWindowTarget -string "PfDe"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"

# Disable remove from iCloud warning
defaults write com.apple.Finder FXEnableRemoveFromICloudDriveWarning -int 0

# Enable cloud Desktop & Documents
defaults write com.apple.Finder FXICloudDriveDesktop -int 1
defaults write com.apple.Finder FXICloudDriveDocuments -int 1

# Show removable media on desktop
defaults write com.apple.Finder ShowExternalHardDrivesOnDesktop -int 1
defaults write com.apple.Finder ShowRemovableMediaOnDesktop -int 1

# Do not show internal hard drives on desktop
defaults write com.apple.Finder ShowHardDrivesOnDesktop -int 0

# Keep folders on top when sorting by name
defaults write com.apple.finder "_FXSortFoldersFirst" -bool "true"

# Title bar hover shows icon
defaults write NSGlobalDomain "NSToolbarTitleViewRolloverDelay" -float "0"

# Side bar icon size
defaults write NSGlobalDomain "NSTableViewDefaultSizeMode" -int "2"

# Disable warning when changing extensions
defaults write com.apple.finder "FXEnableExtensionChangeWarning" -bool "false"

# Allow text selection in Quick Look
defaults write com.apple.finder QLEnableTextSelection -bool true

# Expand all sections in info panel
/usr/libexec/PlistBuddy -c "Set :FXInfoPanesExpanded:Privileges true" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :FXInfoPanesExpanded:MetaData true" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :FXInfoPanesExpanded:OpenWith true" ~/Library/Preferences/com.apple.finder.plist

# Set Finder Toolbar
/usr/libexec/PlistBuddy -c 'Delete :"NSToolbar Configuration Browser":"TB Item Identifiers"' ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c 'Add :"NSToolbar Configuration Browser":"TB Item Identifiers" array' ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c 'Add :"NSToolbar Configuration Browser":"TB Item Identifiers": string "com.apple.finder.BACK"' ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c 'Add :"NSToolbar Configuration Browser":"TB Item Identifiers": string "com.apple.finder.SWCH"' ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c 'Add :"NSToolbar Configuration Browser":"TB Item Identifiers": string "com.apple.finder.SHAR"' ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c 'Add :"NSToolbar Configuration Browser":"TB Item Identifiers": string "com.apple.finder.NFLD"' ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c 'Add :"NSToolbar Configuration Browser":"TB Item Identifiers": string "com.apple.finder.INFO"' ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c 'Add :"NSToolbar Configuration Browser":"TB Item Identifiers": string "com.apple.finder.TRSH"' ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c 'Add :"NSToolbar Configuration Browser":"TB Item Identifiers": string "NSToolbarSpaceItem"' ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c 'Add :"NSToolbar Configuration Browser":"TB Item Identifiers": string "com.apple.finder.SRCH"' ~/Library/Preferences/com.apple.finder.plist

# Set Finder sidebar defaults (AppleScript) - Needs Accessibility permission
setFinderSidebarItems

###############################################################################
# Energy saving                                                               #
###############################################################################

# Sleep machine after 5
sudo pmset -a sleep 10

# Set display sleep to 10 minutes
sudo pmset -a displaysleep 10

# Set low power mode to never
sudo pmset -a lowpowermode 0

###############################################################################
# Screen                                                                      #
###############################################################################

# Require password immediately after sleep or screen saver begins
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 1

# Set login message
setLoginWindowText

###############################################################################
# TextEdit                                                                    #
###############################################################################

# Make TextEdit launch with a blank file by default
defaults write com.apple.TextEdit NSShowAppCentricOpenPanelInsteadOfUntitledFile -bool false

###############################################################################
# Trackpad                                                                    #
###############################################################################

# Set the trakpad speed
defaults write -globalDomain com.apple.trackpad.scaling -float 2

# Set scroll direction to natural
defaults write -g com.apple.swipescrolldirection -int 1

# Enable tap to click
defaults write com.apple.AppleMultitouchTrackpad Clicking -int 1

# Enable three finger drag
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -int 1

# Set horizontal space swipe to four fingers
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerHorizSwipeGesture -int 0

# Set mission control swipe to four fingers
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerVertSwipeGesture -int 0

###############################################################################
# Keyboard                                                                    #
###############################################################################

# Enable key repeat instead of accent menu
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Command + Option + l to lock screen
defaults write -globalDomain NSUserKeyEquivalents  -dict-add "Lock Screen" "@~l"

# Disable Spotlight keyboard shortcut
/usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:64:enabled: false" ~/Library/Preferences/com.apple.symbolichotkeys.plist

# Enable Dictation
defaults write com.apple.HIToolbox AppleDictationAutoEnable -int 1

###############################################################################
# Bartender                                                                   #
###############################################################################

defaults write com.surteesstudios.Bartender HideItemsWhenShowingOthers -int 0
defaults write com.surteesstudios.Bartender HideShownItemsLeaveItemsToRightOfBartender -int 1
defaults write com.surteesstudios.Bartender HideShownItemsWhen -int 0
defaults write com.surteesstudios.Bartender MouseOverMenuBarTogglesBartender -int 0
defaults write com.surteesstudios.Bartender ShowDivider -int 1
defaults write com.surteesstudios.Bartender statusBarImageNamed -string "Bartender"
defaults write com.surteesstudios.Bartender UseBartenderBar -int 0

/usr/libexec/plistbuddy ~/Library/Preferences/com.surteesstudios.bartender.plist \
-c 'Delete :ProfileSettings:activeProfile:Show'\
-c 'Add :ProfileSettings:activeProfile:Show'\
-c 'Add :ProfileSettings:activeProfile:Show: string "com.apple.controlcenter-Battery"'\
-c 'Add :ProfileSettings:activeProfile:Show: string "com.apple.controlcenter-WiFi"'\
-c 'Add :ProfileSettings:activeProfile:Show: string "com.apple.controlcenter-Bluetooth"'\
-c 'Add :ProfileSettings:activeProfile:Show: string "com.apple.controlcenter-Sound"'\
-c 'Add :ProfileSettings:activeProfile:Show: string "com.surteesstudios.Bartender-statusItem"'\
-c 'Add :ProfileSettings:activeProfile:Show: string "com.apple.controlcenter-ScreenMirroring"'\
-c 'Add :ProfileSettings:activeProfile:Show: string "com.aptonic.Dropzone4-Item-0"'\
-c 'Add :ProfileSettings:activeProfile:Show: string "net.rafaelconde.Hand-Mirror-Item-0"'\
-c 'Add :ProfileSettings:activeProfile:Show: string "net.rafaelconde.Hand-Mirror-Item-1"'\
-c 'Add :ProfileSettings:activeProfile:Show: string "info.marcel-dierkes.KeepingYouAwake-Item-0"'

/usr/libexec/plistbuddy ~/Library/Preferences/com.surteesstudios.bartender.plist \
-c 'Delete :ProfileSettings:activeProfile:Hide'\
-c 'Add :ProfileSettings:activeProfile:Hide'\
-c 'Add :ProfileSettings:activeProfile:Hide: string "com.crowdcafe.windowmagnet-Item-0"'\
-c 'Add :ProfileSettings:activeProfile:Hide: string "com.apphousekitchen.aldente-pro-Item-0"'\
-c 'Add :ProfileSettings:activeProfile:Hide: string "pro.betterdisplay.BetterDisplay-Item-0"'\
-c 'Add :ProfileSettings:activeProfile:Hide: string "special.AllOtherItems"'\
-c 'Add :ProfileSettings:activeProfile:Hide: string "com.apple.systemuiserver-AppleTimeMachineExtra"'

/usr/libexec/plistbuddy ~/Library/Preferences/com.surteesstudios.bartender.plist \
-c 'Delete :ProfileSettings:activeProfile:AlwaysHide'\
-c 'Add :ProfileSettings:activeProfile:AlwaysHide'\
-c 'Add :ProfileSettings:activeProfile:AlwaysHide: string "io.fadel.MissionControlPlus-Item-0"'\
-c 'Add :ProfileSettings:activeProfile:AlwaysHide: string "com.apple.controlcenter-NowPlaying"'\
-c 'Add :ProfileSettings:activeProfile:AlwaysHide: string "com.apple.controlcenter-Display"'

###############################################################################
# Kill affected applications                                                  #
###############################################################################

for app in "Activity Monitor" \
    "Address Book" \
    "Calendar" \
    "cfprefsd" \
    "Contacts" \
    "Dock" \
    "Finder" \
    "Mail" \
    "Messages" \
    "Photos" \
    "Safari" \
    "SystemUIServer" \
    "Terminal" \
    "iCal"; do
    killall "${app}" &>/dev/null
done
echo "Done. Note that some of these of macos file changes require a logout/restart to take effect."

confirm "Do you want to reboot now?" && reboot now