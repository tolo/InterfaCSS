Pod::Spec.new do |s|
  s.name         = 'InterfaCSS'
  s.version      = '1.1.1'
  s.summary      = 'A fabulous CSS based styling and layout framework for iOS applications.'
  s.homepage     = 'https://github.com/tolo/InterfaCSS'
  s.license      = 'MIT'
  s.authors      = { 'Tobias Löfstrand' => 'tobias@leafnode.se' }
  s.source       = { :git => 'https://github.com/tolo/InterfaCSS.git', :tag => s.version.to_s }
  s.platform     = :ios
  s.ios.deployment_target = '6.0'
  s.source_files = 'InterfaCSS/**/*.{h,m}'
  s.requires_arc = true
  s.frameworks   = 'Foundation', 'UIKit', 'CoreGraphics', 'QuartzCore'
  s.dependency 'Parcoa', '~> 0.0.1'
end
