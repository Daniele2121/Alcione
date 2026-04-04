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

    # --- AGGIUNTA PER FIX ERRORE 409 ---
    # Impedisce ai bundle dei plugin di includere eseguibili non necessari
    if target.respond_to?(:product_type) && target.product_type == 'com.apple.product-type.bundle'
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
    end
    # -----------------------------------
  end
end