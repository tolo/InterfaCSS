Pod::Spec.new do |s|
  s.name         = 'InterfaCSS'
  s.version      = '0.8.0'
  s.summary      = 'CSS based layout, styling and theming for iOS user interface components'
  s.homepage     = 'https://github.com/tolo/InterfaCSS'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Tobias Löfstrand' => 'tobias@leafnode.se' }
  s.source       = { :git => 'https://github.com/tolo/InterfaCSS.git', :tag => "v#{s.version}" }
  s.platform     = :ios, '6.0'
  s.source_files = 'InterfaCSS', 'InterfaCSS/**/*.{h,m}'
  s.requires_arc = true
  s.frameworks   = ['UIKit', 'CoreGraphics', 'QuartzCore']
  s.dependency 'Parcoa'
end
