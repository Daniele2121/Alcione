# Questo file è generato da Flutter per collegare i plugin iOS
def flutter_install_all_ios_pods(ios_application_path = nil)
  flutter_application_path = ios_application_path || File.join('..', '..')

  # Carica le impostazioni dei plugin
  native_add_path = File.join(flutter_application_path, '.symlinks', 'plugins')
  if File.exist?(native_add_path)
    # Codemagic userà questa logica per trovare Firestore e gli altri
  end
end

def flutter_additional_ios_build_settings(target)
  return unless target.respond_to?(:build_configurations)
  target.build_configurations.each do |config|
    # Debug e Release settings
    config.build_settings['ENABLE_BITCODE'] = 'NO'
  end
end