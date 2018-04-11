# xDripG5

[![CI Status](http://img.shields.io/travis/LoopKit/xDripG5.svg?style=flat)](https://travis-ci.org/LoopKit/xDripG5)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Version](https://img.shields.io/cocoapods/v/xDripG5.svg?style=flat)](http://cocoapods.org/pods/xDripG5)
[![License](https://img.shields.io/cocoapods/l/xDripG5.svg?style=flat)](http://cocoapods.org/pods/xDripG5)
[![Platform](https://img.shields.io/cocoapods/p/xDripG5.svg?style=flat)](http://cocoapods.org/pods/xDripG5)

A iOS framework providing an interface for communicating with the G5 glucose transmitter over Bluetooth. The name and inspiration comes from [xDrip](http://stephenblackwasalreadytaken.github.io/xDrip/), a breakthrough application for connecting to the G4 system.

*Please note this project is neither created nor backed by Dexcom, Inc. This software is not intended for use in therapy.*

## Requirements

This framework connects to a G5 Mobile Transmitter via Bluetooth LE. It does not connect to the G4 Share Receiver or any earlier CGM products.

## Frameworks Installation

### Carthage

xDripG5 is available through [Carthage](https://github.com/Carthage/Carthage). To install it, add the following line to your Cartfile:

```ruby
github "LoopKit/xDripG5"
```

Note that you'll need to confgure your target to link against `CommonCrypto.framework` in addition to `xDripG5.framework`

## Usage

If you plan to run your app alongside the G5 Mobile application, make sure to set `passiveModeEnabled` to true.

### Examples

[glucose-badge](https://github.com/dennisgove/glucose-badge) – Display the latest glucose values as an app icon badge

## ResetTransmitter App Installation

Download the XdripG5 code by clicking on the green `Clone or Download` button (scroll up on this page and you'll find it), then select `Download Zip`

![ResetTransmitter help](https://github.com/Kdisimone/images/blob/master/resetTransmitter-first.png)

Then navigate to the `XdripG5-dev` folder that just downloaded to your computer.  Double-click on the `xDripG5.xcodeproj` file to open the project in Xcode.

![ResetTransmitter help](https://github.com/Kdisimone/images/blob/master/resetTransmitter-download.png)

To install the ResetTransmitter App on your iPhone, simply make sure to sign the ResetTransmitter target and then select just the `ResetTransmitter` scheme in the build area.  Make sure your iPhone is plugged into the computer, select your iPhone from the top of the `Devices` in the 4th circled area, screenshot below.  Note: You do not have to change bundle IDs or anything beyond the steps listed.

![ResetTransmitter help](https://github.com/Kdisimone/images/blob/master/resetTransmitter.png)


## Code of Conduct

Please note that this project is released with a [Contributor Code of Conduct](https://github.com/LoopKit/LoopKit/blob/master/CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

## License

xDripG5 is available under the MIT license. See the LICENSE file for more info.
