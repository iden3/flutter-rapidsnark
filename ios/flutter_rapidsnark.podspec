#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_rapidsnark.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_rapidsnark'
  s.version          = '0.0.1'
  s.summary          = 'Rapidsnark Flutter pod for plugin.'
  s.description      = <<-DESC
Rapidsnark Flutter pod for plugin.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'iden3' => 'hello@iden3.io' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
  }
  s.swift_version = '5.0'

  s.dependency 'rapidsnark', '0.0.1-alpha.5'
end
