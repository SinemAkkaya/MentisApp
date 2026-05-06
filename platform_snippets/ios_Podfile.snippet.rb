# ios/Podfile dosyasının EN ÜST SATIRINI şöyle yap:
#
#   # Uncomment this line to define a global platform for your project
#   platform :ios, '15.5'
#
# Yani yorum satırını aç ve 15.5 yap. Bu satır zaten vardır ama
# genelde yorumlu gelir — aktifleştir.
#
# Neden 15.5?
# - google_mlkit_face_detection 0.13.x → GoogleMLKit 9+ kullanır
# - GoogleMLKit 9 iOS 15.5+ gerektirir
# - iPhone 16e iOS 18'de, sorun yok
#
# Podfile'ın EN ALTINDA (post_install bloğu içinde) zaten bir satır vardır:
#
#   post_install do |installer|
#     installer.pods_project.targets.each do |target|
#       flutter_additional_ios_build_settings(target)
#     end
#   end
#
# Bunu ŞÖYLE GÜNCELLE (Xcode build setting'i zorlamak için):
#
#   post_install do |installer|
#     installer.pods_project.targets.each do |target|
#       flutter_additional_ios_build_settings(target)
#       target.build_configurations.each do |config|
#         config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.5'
#         config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
#         config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
#           '$(inherited)',
#           'PERMISSION_CAMERA=1',
#           'PERMISSION_MICROPHONE=1',
#         ]
#       end
#     end
#   end
