Pod::Spec.new do |s|
  s.name         = 'InterfaCSS'
  s.version      = '2.0-Beta3'
  s.summary      = 'The CSS-inspired styling and layout framework for iOS'
  s.homepage     = 'https://github.com/tolo/InterfaCSS'
  s.license      = 'MIT'
  s.authors      = { 'Tobias Löfstrand' => 'tobias@leafnode.se' }
  s.source       = { :git => 'https://github.com/tolo/InterfaCSS.git', :tag => s.version.to_s }
  s.default_subspec = 'Layout'
  s.swift_version = '5.0'
  s.ios.deployment_target = '11.0'
  if defined?(s.tvos)
    s.tvos.deployment_target = '11.0'
  end

  s.subspec 'Core' do |ss|
    ss.frameworks = 'Foundation', 'UIKit'
    ss.source_files = 'Core/Source/*.{swift},*.{h,m}'
  end

  s.subspec 'CoreUIKit' do |ss|
    ss.frameworks = 'Foundation', 'UIKit'
    ss.dependency 'InterfaCSS/Core'
    ss.source_files = 'UIKit/Source/*.{swift},*.{h,m}'
  end

  s.subspec 'Layout' do |ss|
    #ss.ios.deployment_target = '11.0'
    ss.frameworks = 'Foundation', 'UIKit'
    ss.source_files = 'Layout/Source/*.{swift}'
    ss.dependency 'InterfaCSS/Core'
    ss.dependency 'YogaKit', '~> 1.18.0'
  end
  
  s.subspec 'Full' do |ss| // TODO:
    #ss.dependency 'InterfaCSS/CoreUIKit'
    ss.dependency 'InterfaCSS/Layout'
    ss.source_files = 'UIKit/Source/*.{swift},*.{h,m}'
  end
  
end
