Pod::Spec.new do |s|
  s.name         = 'InterfaCSS'
  s.version      = '1.5.4'
  s.summary      = 'The CSS-inspired styling and layout framework for iOS'
  s.homepage     = 'https://github.com/tolo/InterfaCSS'
  s.license      = 'MIT'
  s.authors      = { 'Tobias Löfstrand' => 'tobias@leafnode.se' }
  s.source       = { :git => 'https://github.com/tolo/InterfaCSS.git', :tag => s.version.to_s }
  s.ios.deployment_target = '7.0'
if defined?(s.tvos)
  s.tvos.deployment_target = '9.0'
end
  s.source_files = 'InterfaCSS/**/*.{h,m}'
  s.requires_arc = true
  s.frameworks   = 'Foundation', 'UIKit', 'CoreGraphics', 'QuartzCore'

end
