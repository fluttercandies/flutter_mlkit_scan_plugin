Pod::Spec.new do |s|
  s.name             = 'mlkit_scan_plugin'
  s.version          = '1.0.0'
  s.summary          = 'The MLKit scan plugin for Flutter'
  s.description      = <<-DESC
  The MLKit scan plugin for Flutter
  DESC
  s.homepage         = 'https://github.com/AlexV525/flutter_mlkit_scan_plugin'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'AlexV525' => 'github@alexv525.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'
  
  s.dependency 'GoogleMLKit/BarcodeScanning', '~> 3.2.0'
  s.dependency 'GoogleMLKit/TextRecognition', '~> 3.2.0'
  s.static_framework = true
  
  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
  }
  s.swift_version = '5.0'
end
