import config, json, streams, plists, configutil, os

# The default plist
const defaultInfoPlist =
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
        <dict>
            <key>CFBundleShortVersionString</key>
                <string>TK</string>
            <key>CFBundleName</key>
                <string>TK</string>
            <key>CFBundleExecutable</key>
                <string>TK</string>
            <key>UIStatusBarHidden</key>
                <true/>
            <key>UISupportedInterfaceOrientations</key>
                <array>
                    <string>UIInterfaceOrientationLandscapeLeft</string>
                    <string>UIInterfaceOrientationLandscapeRight</string>
                </array>
            <key>UIDeviceFamily</key>
                <array>
                    <integer>1</integer>
                    <integer>2</integer>
                </array>
            <key>CFBundleIdentifier</key>
                <string>TK</string>
            <key>CFBundleVersion</key>
                <string>1</string>
            <key>CFBundleInfoDictionaryVersion</key>
                <string>6.0</string>
            <key>UISupportedInterfaceOrientations~ipad</key>
                <array>
                    <string>UIInterfaceOrientationLandscapeLeft</string>
                    <string>UIInterfaceOrientationLandscapeRight</string>
                </array>
        </dict>
    </plist>
    """

proc createPlist*(self: Config) =
    ## Returns the JsonNode representint the Info.plist file
    let plist = parsePlist(newStringStream(defaultInfoPlist))
    plist["CFBundleName"] = %self.appName
    plist["CFBundleIdentifier"] = %self.bundleId
    plist["CFBundleExecutable"] = %self.appName
    plist["CFBundleShortVersionString"] = %self.version
    plist["CFBundleVersion"] = %self.buildTime

    plist.writePlist(self.macAppDir / "Info.plist")

