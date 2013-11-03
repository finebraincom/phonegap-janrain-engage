== Porting of Janrain Engage plugin for iOS for Phonegap 3.1

Configuration of XCode project after plugin installation:

1. Add plugin m-files to the list of Compile Sources in Target/Build Phases/Compile Sources with flag -fno-objc-arc for source
1. Remove image files of the plugin from the same list