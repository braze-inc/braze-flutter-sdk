#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'braze_plugin'
  s.version          = '2.0.0'
  s.summary          = 'Braze plugin for Flutter.'
  s.description      = <<-DESC
Braze plugin for Flutter.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'Appboy-iOS-SDK', '~> 4.0.2'

  s.ios.deployment_target = '9.0'
end
