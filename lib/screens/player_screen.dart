name: free_tv
description: A cross-platform free TV app built with Flutter.
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  http: ^1.1.0
  shared_preferences: ^2.2.2
  cached_network_image: ^3.3.0
  
  
  video_player: ^2.9.2
  chewie: ^1.8.5

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true

dependency_overrides:
  package_info_plus: 8.3.1
