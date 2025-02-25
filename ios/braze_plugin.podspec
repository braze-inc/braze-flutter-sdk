#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
require 'yaml'

# Read the version from your pubspec.yaml file
pubspec = YAML.load_file(File.join(__dir__, '../pubspec.yaml'))
flutter_version = pubspec['version']

braze_swift_version = '11.6.1'

Pod::Spec.new do |s|
  s.name             = 'braze_plugin'
  s.version          = flutter_version
  s.summary          = 'Braze plugin for Flutter.'
  s.homepage         = 'https://braze.com'
  s.license          = { :file => '../LICENSE' }
  s.authors          = 'Braze, Inc.'
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.static_framework = true

  s.dependency 'Flutter'
  s.dependency 'BrazeKit', "~> #{braze_swift_version}"
  s.dependency 'BrazeLocation', "~> #{braze_swift_version}"
  s.dependency 'BrazeUI', "~> #{braze_swift_version}"

  s.ios.deployment_target = '12.0'
end
