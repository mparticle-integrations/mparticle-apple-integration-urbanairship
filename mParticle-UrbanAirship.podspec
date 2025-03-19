Pod::Spec.new do |s|
    s.name             = "mParticle-UrbanAirship"
    s.version          = "8.3.0"
    s.summary          = "Airship integration for mParticle"

    s.description      = <<-DESC
                       This is the Airship integration for mParticle.
                       DESC

    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle-integrations/mparticle-apple-integration-urbanairship.git", :tag => "v" + s.version.to_s }
    s.social_media_url = "https://twitter.com/mparticle"

    s.ios.deployment_target = "15.0"
    s.ios.source_files      = 'mParticle-UrbanAirship/*.{h,m,mm,swift}'
    s.ios.resource_bundles = { 'mParticle-UrbanAirship-Privacy' => ['mParticle-UrbanAirship/PrivacyInfo.xcprivacy'] }
    s.ios.dependency 'mParticle-Apple-SDK/mParticle', '~> 8.22'
    s.ios.dependency 'Airship/ObjectiveC', '~> 19.1'
end

