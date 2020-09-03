Pod::Spec.new do |s|
    s.name             = "mParticle-UrbanAirship"
    s.version          = "8.0.0"
    s.summary          = "Urban Airship integration for mParticle"

    s.description      = <<-DESC
                       This is the Urban Airship integration for mParticle.
                       DESC

    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle-integrations/mparticle-apple-integration-urbanairship.git", :tag => s.version.to_s }
    s.social_media_url = "https://twitter.com/mparticle"

    s.ios.deployment_target = "11.0"
    s.ios.source_files      = 'mParticle-UrbanAirship/*.{h,m,mm}'
    s.ios.dependency 'mParticle-Apple-SDK/mParticle', '~> 8.0-beta'
    s.ios.dependency 'Airship', '~> 14.0.0-beta1'
end

