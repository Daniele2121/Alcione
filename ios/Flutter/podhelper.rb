def flutter_install_all_ios_pods(ios_application_path = nil)
  flutter_application_path = ios_application_path || File.join('..', '..')
  app_config = JSON.parse(File.read(File.join(flutter_application_path, '.metadata')))

  # Trova i plugin registrati nel file .flutter-plugins-dependencies
  plugins_file = File.join(flutter_application_path, '.flutter-plugins-dependencies')
  if File.exist?(plugins_file)
    plugins_config = JSON.parse(File.read(plugins_file))
    plugins_config['plugins']['ios'].each do |plugin|
      pod plugin['name'], :path => File.join(plugin['path'], 'ios')
    end
  end
end

def flutter_additional_ios_build_settings(target)
  return unless target.respond_to?(:build_configurations)
  target.build_configurations.each do |config|
    config.build_settings['ENABLE_BITCODE'] = 'NO'
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
  end
end