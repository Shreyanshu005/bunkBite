# Uncomment the next line to define a global platform for your project
platform :ios, '18.0'

target 'BunkBite' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for BunkBite

  target 'BunkBiteTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'BunkBiteUITests' do
    # Pods for testing
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '18.0'
    end
  end

  # Fix for framework embedding sandbox issues
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
      end
    end
  end
end
