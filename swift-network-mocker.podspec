Pod::Spec.new do |s|
  s.name             = 'NetworkMocker'
  s.version          = '0.1.0'
  s.summary          = 'Network mocking for iOS.'
  s.description      = 'Speed up development and testing by adding a autogenerated network mocking screen to your app.'
  s.homepage         = 'https://github.com/wvteijlingen/swift-network-mocker'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = 'Ward van Teijlingen'
  s.source           = { :git => 'https://github.com/wvteijlingen/swift-network-mocker.git', :tag => s.version.to_s }

  s.ios.deployment_target = '15.0'
  s.source_files = 'Sources/NetworkMocker/**/*'
  s.frameworks = 'SwiftUI'
  s.swift_version = '5'
end
