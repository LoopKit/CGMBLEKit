Pod::Spec.new do |s|
  s.name             = "xDripG5"
  s.version          = "0.3.1"
  s.summary          = "An interface for communicating with the G5 glucose transmitter over Bluetooth."

  s.description      = <<-DESC
A iOS framework providing an interface for communicating with the G5 glucose transmitter over Bluetooth.

By using this framework in your own app, you can get access to your glucose readings, without the need for internet access or a multi-hour delay.

Please note this project is neither created nor backed by Dexcom, Inc. Use of this software is not intended for therapy.
                       DESC

  s.homepage         = "https://github.com/loudnate/xDripG5"
  s.license          = 'MIT'
  s.author           = { "Nathan Racklyeft" => "loudnate@gmail.com" }
  s.source           = { :git => "https://github.com/loudnate/xDripG5.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/loudnate'

  s.platform     = :ios, '9.2'
  s.requires_arc = true

  s.source_files = ['xDripG5/**/*.swift', 'Pod/*.h']
  s.public_header_files = 'Pod/*.h'

  s.frameworks = 'CoreBluetooth'
  s.dependency 'RNCryptor', '~> 4.0'
end
