# @generated
def flutter_install_all_ios_pods(ios_application_path = nil)
  flutter_install_ios_plugin_pods(ios_application_path)
end

def flutter_install_ios_plugin_pods(ios_application_path = nil)
  ios_application_path ||= File.join('..', '..')
  symlinks_dir = File.expand_path('.symlinks', ios_application_path)
  FileUtils.mkdir_p(symlinks_dir)

  plugins_file = File.join(ios_application_path, '.flutter-plugins-dependencies')
  return unless File.exist?(plugins_file)

  plugins_config = JSON.parse(File.read(plugins_file))
  plugins_config['plugins']['ios'].each do |plugin|
    pod plugin['name'], :path => File.join(plugin['path'], 'ios')
  end
end

def flutter_additional_ios_build_settings(target)
  return unless target.respond_to?(:build_configurations)
  target.build_configurations.each do |config|
    config.build_settings['ENABLE_BITCODE'] = 'NO'
  end
end