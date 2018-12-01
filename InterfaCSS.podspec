Pod::Spec.new do |s|
  s.name         = 'InterfaCSS'
  s.version      = '2.0-Beta2'
  s.summary      = 'The CSS-inspired styling and layout framework for iOS'
  s.homepage     = 'https://github.com/tolo/InterfaCSS'
  s.license      = 'MIT'
  s.authors      = { 'Tobias Löfstrand' => 'tobias@leafnode.se' }
  s.source       = { :git => 'https://github.com/tolo/InterfaCSS.git', :tag => s.version.to_s }
  s.frameworks   = 'Foundation', 'UIKit', 'CoreGraphics', 'QuartzCore'
  s.default_subspec = 'Core'

  s.subspec 'Core' do |core|
      core.ios.deployment_target = '9.0'
      if defined?(s.tvos)
          core.tvos.deployment_target = '9.0'
      end
      core.source_files = 'Core/Source/*.{h,m}'
  end

  s.subspec 'Layout' do |layout|
      layout.ios.deployment_target = '11.0'
      if defined?(s.tvos)
          layout.tvos.deployment_target = '11.0'
      end
      layout.source_files = 'Layout/Source/*.{h,swift}'
      layout.dependency 'YogaKit', '~> 1.0'
  end
end
