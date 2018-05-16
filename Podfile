use_frameworks!

target 'AlarmAwake' do
	pod 'ReactiveSwift', '~> 3.0'
	pod 'SwiftTryCatch', :git => 'https://github.com/ravero/SwiftTryCatch.git'
	pod 'Pulsator'
	pod 'RKDropdownAlert'
	pod 'PopupDialog', '~> 0.7'
	pod 'AffdexSDK-iOS'
	pod 'ChameleonFramework/Swift', :git => 'https://github.com/ViccAlexander/Chameleon.git'
	pod 'RZViewActions'
end 

post_install do |installer|
    installer.pods_project.targets.each do |target|
        if (target.name == "AWSCore") || (target.name == 'AWSKinesis')
            target.build_configurations.each do |config|
                config.build_settings['BITCODE_GENERATION_MODE'] = 'bitcode'
            end
        end
    end
end

