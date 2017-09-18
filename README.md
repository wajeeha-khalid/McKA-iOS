PiQUE for iOS
=============

This app was originally based on the [Open edX iOS App](https://github.com/edx/edx-app-ios).
It was forked from the edX source Code version 2.6 on 2016-12-20.

License
=======
This software is licensed under version 2 of the Apache License unless
otherwise noted. Please see ``LICENSE.txt`` for details.

Building
========
1. Install Carthage, if you don't have it. (`brew install carthage`)
1. Install CocoaPods, if you don't have it. (`brew install cocoapods`)
1. Check out the source code. Please do a recursive clone since we are using XBlock library as a submodule:
    
    ```
    git clone --recursive git@github.com:mckinseyacademy/PiQUE-iOS.git
    or if you already have cloned the repo non recursively
    cd PiQUE-iOS
    git submodule update --init --recursive
    ```

1. Install the required frameworks using Carthage. (Install Carthage dependencies seperately for both the main app and
   XBlock submodule):

    ```
    cd PiQUE-iOS
    carthage update --platform iOS
    pod install
    cd xblock-component-library-ios
    carthage update --platform iOS
    ```

1. Launch the workspace: `open edX.xcworkspace` (Important: always open the .xcworkspace
   file, not the `edX.xcodeproj` file, or you'll get build errors.)

1. Ensure that the `edX` scheme is selected.

1. Click the **Run** button.

*Note: The build system requires Java 7 or later.  If you see an error
mentioning "Unsupported major.minor version 51.0 " then you should install a newer Java SDK.*

Configuration
=============

By default, the app is pre-configured to connect to the
McKinsey Academy QA Server. You can edit the settings in the
`default_config` directory if you want to use another server
such as a local Open edX devstack.
