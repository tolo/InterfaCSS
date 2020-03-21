source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '11.0'
project 'InterfaCSS.xcodeproj'
use_frameworks!

target 'Core' do
  pod 'Parsicle', :path => '../Parsicle/'
end

target 'CoreTests' do
  inherit! :search_paths
end

target 'Layout' do
  pod 'YogaKit', '~> 1.18.0'
  pod 'Parsicle', :path => '../Parsicle/'
end

target 'LayoutTests' do
  inherit! :search_paths
end
