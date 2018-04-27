Pod::Spec.new do |s|
  s.name         = 'InterfaCSS'
  s.version      = '2.0-Beta1'
  s.summary      = 'The CSS-inspired styling and layout framework for iOS'
  s.homepage     = 'https://github.com/tolo/InterfaCSS'
  s.license      = 'MIT'
  s.authors      = { 'Tobias Löfstrand' => 'tobias@leafnode.se' }
  s.source       = { :git => 'https://github.com/tolo/InterfaCSS.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
if defined?(s.tvos)
  s.tvos.deployment_target = '9.0'
end
  s.source_files = 'Core/Source/*.{h,m}'
  s.requires_arc = true
  s.frameworks   = 'Foundation', 'UIKit', 'CoreGraphics', 'QuartzCore'

end
