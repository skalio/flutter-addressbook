#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'addressbook'
  s.version          = '0.0.1'
  s.summary          = 'Addressbook access for Flutter apps.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'https://github.com/skalio/flutter-addressbook'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Skalio GmbH' => 'info@skalio.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx
  s.osx.deployment_target = '10.11'
end

