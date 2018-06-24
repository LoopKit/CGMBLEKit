//
//  GlucoseBackfillMessageTests.swift
//  xDripG5Tests
//
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import XCTest
@testable import CGMBLEKit

class GlucoseBackfillMessageTests: XCTestCase {

    func testTxMessage() {
        let message = GlucoseBackfillTxMessage(byte1: 5, byte2: 2, identifier: 0, startTime: 5439415, endTime: 5440614) // 20 minutes

        XCTAssertEqual(Data(hexadecimalString: "50050200b7ff5200660453000000000000007138")!, message.data)
    }

    func testRxMessage() {
        let message = GlucoseBackfillRxMessage(data: Data(hexadecimalString: "51000100b7ff52006604530032000000e6cb9805")!)!

        XCTAssertEqual(.ok, TransmitterStatus(rawValue: message.status))
        XCTAssertEqual(1, message.backfillStatus)
        XCTAssertEqual(0, message.identifier)
        XCTAssertEqual(5439415, message.startTime)
        XCTAssertEqual(5440614, message.endTime)
        XCTAssertEqual(50, message.bufferLength)
        XCTAssertEqual(0xcbe6, message.bufferCRC)

        // 0xbc46
        // 0b10111100 01000110
        var buffer = GlucoseBackfillFrameBuffer(identifier: message.identifier)
        buffer.append(Data(hexadecimalString: "0100bc460000b7ff52008b0006eee30053008500")!)
        buffer.append(Data(hexadecimalString: "020006eb0f025300800006ee3a0353007e0006f5")!)
        buffer.append(Data(hexadecimalString: "030066045300790006f8")!)

        XCTAssertEqual(Int(message.bufferLength), buffer.count)
        XCTAssertEqual(message.bufferCRC, buffer.crc16)

        let messages = buffer.glucose
        
        XCTAssertEqual(139, messages[0].glucose)
        XCTAssertEqual(5439415, messages[0].timestamp)
        XCTAssertEqual(.known(.ok), CalibrationState(rawValue: messages[0].state))
        XCTAssertEqual(-18, messages[0].trend)

        XCTAssertEqual(133, messages[1].glucose)
        XCTAssertEqual(5439715, messages[1].timestamp)
        XCTAssertEqual(.known(.ok), CalibrationState(rawValue: messages[1].state))
        XCTAssertEqual(-21, messages[1].trend)

        XCTAssertEqual(128, messages[2].glucose)
        XCTAssertEqual(5440015, messages[2].timestamp)
        XCTAssertEqual(.known(.ok), CalibrationState(rawValue: messages[2].state))
        XCTAssertEqual(-18, messages[2].trend)

        XCTAssertEqual(126, messages[3].glucose)
        XCTAssertEqual(5440314, messages[3].timestamp)
        XCTAssertEqual(.known(.ok), CalibrationState(rawValue: messages[3].state))
        XCTAssertEqual(-11, messages[3].trend)

        XCTAssertEqual(121, messages[4].glucose)
        XCTAssertEqual(5440614, messages[4].timestamp)
        XCTAssertEqual(.known(.ok), CalibrationState(rawValue: messages[4].state))
        XCTAssertEqual(-08, messages[4].trend)
    }

    func testGlucoseBackfill2() {
        let message = GlucoseBackfillTxMessage(byte1: 5, byte2: 2, identifier: 0, startTime: 4648682, endTime: 4650182) // 25 minutes

        XCTAssertEqual(Data(hexadecimalString: "50050200eaee4600c6f446000000000000009f6d")!, message.data, message.data.hexadecimalString)

        let response = GlucoseBackfillRxMessage(data: Data(hexadecimalString: "51000103eaee4600c6f446003a0000004f3ac9e6")!)!

        XCTAssertEqual(.ok, TransmitterStatus(rawValue: response.status))
        XCTAssertEqual(1, response.backfillStatus)
        XCTAssertEqual(3, response.identifier)
        XCTAssertEqual(4648682, response.startTime)
        XCTAssertEqual(4650182, response.endTime)
        XCTAssertEqual(58, response.bufferLength)
        XCTAssertEqual(0x3a4f, response.bufferCRC)

        // 0x6e3c
        // 0b01101110 00111100
        var buffer = GlucoseBackfillFrameBuffer(identifier: 0xc0)
        buffer.append(Data(hexadecimalString: "01c06e3c0000eaee4600920007fd16f046009500")!)
        buffer.append(Data(hexadecimalString: "02c0070042f14600960007026ef2460099000704")!)
        buffer.append(Data(hexadecimalString: "03c09af3460093000700c6f44600900007fc")!)

        XCTAssertEqual(Int(response.bufferLength), buffer.count)
        XCTAssertEqual(response.bufferCRC, buffer.crc16)

        let messages = buffer.glucose

        XCTAssertEqual(6, messages.count)
    }

    func testMalformedBackfill() {
        var buffer = GlucoseBackfillFrameBuffer(identifier: 0)
        buffer.append(Data(hexadecimalString: "0100bc460000b7ff52008b0006eee30053008500")!)
        buffer.append(Data(hexadecimalString: "020006eb0f025300800006ee3a0353007e0006")!)

        XCTAssertEqual(3, buffer.glucose.count)
    }

    func testGlucoseBackfill3() {
        let response = GlucoseBackfillRxMessage(data: Data(hexadecimalString: "510001023d6a0e00c16d0e00280000005b1a9154")!)!

        XCTAssertEqual(.ok, TransmitterStatus(rawValue: response.status))
        XCTAssertEqual(1, response.backfillStatus)
        XCTAssertEqual(2, response.identifier)
        XCTAssertEqual(944701, response.startTime)
        XCTAssertEqual(945601, response.endTime)
        XCTAssertEqual(40, response.bufferLength)
        XCTAssertEqual(0x1A5B, response.bufferCRC)

        // 0x440c
        // 0b01000100 00001100
        var buffer = GlucoseBackfillFrameBuffer(identifier: 0x80)
        buffer.append(Data(hexadecimalString: "0180440c00003d6a0e005c0007fe696b0e005d00")!)
        buffer.append(Data(hexadecimalString: "028007ff956c0e005e000700c16d0e005d000700")!)

        XCTAssertEqual(Int(response.bufferLength), buffer.count)
        XCTAssertEqual(response.bufferCRC, buffer.crc16)

        let messages = buffer.glucose

        XCTAssertEqual(response.startTime, messages.first!.timestamp)
        XCTAssertEqual(response.endTime, messages.last!.timestamp)

        XCTAssertEqual(4, messages.count)
    }

    func testGlucoseBackfill4() {
        let response = GlucoseBackfillRxMessage(data: Data(hexadecimalString: "51000103c9740e004d780e0028000000235bd94c")!)!

        XCTAssertEqual(.ok, TransmitterStatus(rawValue: response.status))
        XCTAssertEqual(1, response.backfillStatus)
        XCTAssertEqual(3, response.identifier)
        XCTAssertEqual(947401, response.startTime)
        XCTAssertEqual(948301, response.endTime)
        XCTAssertEqual(40, response.bufferLength)
        XCTAssertEqual(0x5B23, response.bufferCRC)

        // 0x04d0
        // 0b00000100 11010000
        var buffer = GlucoseBackfillFrameBuffer(identifier: 0xc0)
        buffer.append(Data(hexadecimalString: "01c04d0c0000c9740e005a000700f5750e005800")!)
        buffer.append(Data(hexadecimalString: "02c007ff21770e00590007ff4d780e0059000700")!)

        XCTAssertEqual(Int(response.bufferLength), buffer.count)
        XCTAssertEqual(response.bufferCRC, buffer.crc16)

        let messages = buffer.glucose

        XCTAssertEqual(response.startTime, messages.first!.timestamp)
        XCTAssertEqual(response.endTime, messages.last!.timestamp)

        XCTAssertEqual(4, messages.count)
    }

    func testNotGlucoseBackfill1() {
        let response = GlucoseBackfillRxMessage(data: Data(hexadecimalString: "5100010339410e0085a90e00ac06000070ca9143")!)!

        XCTAssertEqual(.ok, TransmitterStatus(rawValue: response.status))
        XCTAssertEqual(1, response.backfillStatus)
        XCTAssertEqual(3, response.identifier)
        XCTAssertEqual(934201, response.startTime)
        XCTAssertEqual(960901, response.endTime)
        XCTAssertEqual(1708, response.bufferLength)
        XCTAssertEqual(0xCA70, response.bufferCRC)

        // 0x4a4f
        // 0b01001010 01001111
        var buffer = GlucoseBackfillFrameBuffer(identifier: 0xc0)
        buffer.append(Data(hexadecimalString: "01c04a4f4a5558ef554453b7392a0df008571a7f")!)
        buffer.append(Data(hexadecimalString: "02c0451e0d74bdec596b633cf2b03d511ef3d048")!)
        buffer.append(Data(hexadecimalString: "03c009145e959ca51f7a1663ca31676b175d7bc7")!)
        buffer.append(Data(hexadecimalString: "04c0de00c954fcd3281d5163ed873cdc136fca3e")!)
        buffer.append(Data(hexadecimalString: "05c0c7da188dd5fbb8997206da1cc8d0c22f8434")!)
        buffer.append(Data(hexadecimalString: "06c04d50b29df06b12e7162f2d73fd553e44e469")!)
        buffer.append(Data(hexadecimalString: "07c02b4bb61d66cf6e949ee0f07dbe0cc12127ae")!)
        buffer.append(Data(hexadecimalString: "08c03bf887be09ece7595adfee494b25368103b4")!)
        buffer.append(Data(hexadecimalString: "09c07eefb9b5398468a53f00355341d19b50c8b1")!)
        buffer.append(Data(hexadecimalString: "0ac028f0ddb4dc09a2c74deedf7fdff13fcd6b0e")!)
        buffer.append(Data(hexadecimalString: "0bc0ad2d7311ac9ec1908fb7ee5557c463ea4fea")!)
        buffer.append(Data(hexadecimalString: "0cc0bf3c62d9aa62d7c3d447c959b51d31fd016d")!)
        buffer.append(Data(hexadecimalString: "0dc0278116abd1252ad66c894a39ed7c6d72086e")!)
        buffer.append(Data(hexadecimalString: "0ec0aaee3bf9b05ccb7b23e1c27d777173c4d9fd")!)
        buffer.append(Data(hexadecimalString: "0fc044048720d76a696249737f999f944995e44e")!)
        buffer.append(Data(hexadecimalString: "10c0495e4cb7f22327a920a843de1b4522a68108")!)
        buffer.append(Data(hexadecimalString: "11c058c482389192ed920e322b71900d747a9492")!)
        buffer.append(Data(hexadecimalString: "12c0eac06906ff4863f0e8da07d1ead29fc15bd3")!)
        buffer.append(Data(hexadecimalString: "13c0c0be38548fe9e229c64c9c0f3e9b4c4c1d83")!)
        buffer.append(Data(hexadecimalString: "14c018a936bdde548e4244093e77c87adda0a1cf")!)
        buffer.append(Data(hexadecimalString: "15c0fb97d1d147dd0bc6552faa4d62ab553e1682")!)
        buffer.append(Data(hexadecimalString: "16c0f15f8cb77decb934bfe0c711a026dd4bf36b")!)
        buffer.append(Data(hexadecimalString: "17c0bd268b0eee07ed20a0f3856ea449b1503708")!)
        buffer.append(Data(hexadecimalString: "18c00872ed5a996a13480b81fc82b6ca1e7dd379")!)
        buffer.append(Data(hexadecimalString: "19c06fb4c5bc84e63688b0a77edbab85bfb61b45")!)
        buffer.append(Data(hexadecimalString: "1ac071d29d30edb43db6b8e114bbbcd67f9dd3a9")!)
        buffer.append(Data(hexadecimalString: "1bc0569e17a8a80c015def11ddce1b8f194ff6e2")!)
        buffer.append(Data(hexadecimalString: "1cc0df79ffbc1e077fe249b47550feb5dcd53044")!)
        buffer.append(Data(hexadecimalString: "1dc0b557e2ba03caed61de30221b0330e1cc49b1")!)
        buffer.append(Data(hexadecimalString: "1ec006f05e739d737939baf8b14a8b7a6faae96e")!)
        buffer.append(Data(hexadecimalString: "1fc00b82d430e9e75fb8e7e2affbdd292a41fad2")!)
        buffer.append(Data(hexadecimalString: "20c0fbf8e8f2686aaaf19d2809eecd3bd4f63516")!)
        buffer.append(Data(hexadecimalString: "21c0a7df809e73538e459c1a9cd27a566f636e22")!)
        buffer.append(Data(hexadecimalString: "22c0dbb3c23d7d7847dee77311287e6c6b192eb4")!)
        buffer.append(Data(hexadecimalString: "23c0d30038d70241a80b9e390778a897dd1632cc")!)
        buffer.append(Data(hexadecimalString: "24c0177b23127b464c07a499abeff05f13e40998")!)
        buffer.append(Data(hexadecimalString: "25c0855350c7c4a335e95d2e569996639e8341b4")!)
        buffer.append(Data(hexadecimalString: "26c0d42874475710a50764d4a4166c0e420aff7f")!)
        buffer.append(Data(hexadecimalString: "27c0facb1d61cb8057de64546fc9f24f93603093")!)
        buffer.append(Data(hexadecimalString: "28c080befb84f22c60d398f017dde114d0557b27")!)
        buffer.append(Data(hexadecimalString: "29c07555e92425342c0674b62fa517b13ba0e3b0")!)
        buffer.append(Data(hexadecimalString: "2ac0923624bce36c89fade1f66bd7ae1e8e7d598")!)
        buffer.append(Data(hexadecimalString: "2bc0d345ceea668373d31f95b03a6ee7fff1a3b5")!)
        buffer.append(Data(hexadecimalString: "2cc045e409b8d31dd53ae9d353f35738819fbb79")!)
        buffer.append(Data(hexadecimalString: "2dc0a5d31fd3c3b7b217d3f79b245d3714b0523d")!)
        buffer.append(Data(hexadecimalString: "2ec0eb576e0193584bff8ecada0dc54e4ebde86c")!)
        buffer.append(Data(hexadecimalString: "2fc092b8ef52003f8b76e90d920ca738c998bb70")!)
        buffer.append(Data(hexadecimalString: "30c07cfa0f7a69d14b79f605d254a164fd67c658")!)
        buffer.append(Data(hexadecimalString: "31c049a329162e03f41c12db845b73301f5bbb81")!)
        buffer.append(Data(hexadecimalString: "32c08a21ca0995b5aa413897ea9e2b7c563ced07")!)
        buffer.append(Data(hexadecimalString: "33c05d51a18e19209f1c55054bd2f74677c71070")!)
        buffer.append(Data(hexadecimalString: "34c0299e29ae5576a220b0b767fc4e898aaf2df1")!)
        buffer.append(Data(hexadecimalString: "35c0bbb554546b69c53b4b3a63bd524bfbe728e6")!)
        buffer.append(Data(hexadecimalString: "36c0cd4e8c6e10e72950e66bfa0d23b954a7aede")!)
        buffer.append(Data(hexadecimalString: "37c0ea5df836af737298d44b4b156ced47727920")!)
        buffer.append(Data(hexadecimalString: "38c02303edefc4916cfdba55829426c153d0d30c")!)
        buffer.append(Data(hexadecimalString: "39c0dfee091fea60c2da239c9aabef8eddbe49b5")!)
        buffer.append(Data(hexadecimalString: "3ac02788f23fb030e7606329ed24cbee10bc20eb")!)
        buffer.append(Data(hexadecimalString: "3bc00a601d46c10bab8cdf04513a47550b0e4fe5")!)
        buffer.append(Data(hexadecimalString: "3cc072ea5e514432c81e325464e1ac2d659378d2")!)
        buffer.append(Data(hexadecimalString: "3dc0f050e994caa508fdea7202ed70a4acc6e8ab")!)
        buffer.append(Data(hexadecimalString: "3ec069ab0d13863943415b492569db29b9594dbe")!)
        buffer.append(Data(hexadecimalString: "3fc02c37277a98b88956f0def9ad866f44ca6d9f")!)
        buffer.append(Data(hexadecimalString: "40c0e5bd6aa2dbd835fab2ec238de4a635a3f6cb")!)
        buffer.append(Data(hexadecimalString: "41c0aafa8812d94d5fe722b3ecfb74eb4c12c622")!)
        buffer.append(Data(hexadecimalString: "42c08c5b4bb2f28069fc6f9dcb26bc84c0cc01c7")!)
        buffer.append(Data(hexadecimalString: "43c04ad95cefa1f62a18fa2c5a05bac208685cdb")!)
        buffer.append(Data(hexadecimalString: "44c0ffe910ddc010b30f457578ab24a866b8a94d")!)
        buffer.append(Data(hexadecimalString: "45c01b0bb36e58f401eb15da2e6710721e39c573")!)
        buffer.append(Data(hexadecimalString: "46c06165075618fc9626c53acdd9cb8bcfb0719f")!)
        buffer.append(Data(hexadecimalString: "47c081599f76725e30d4de39cdcc7f7c0c918d68")!)
        buffer.append(Data(hexadecimalString: "48c0563b99dce4913105b793f4d539fe668feef6")!)
        buffer.append(Data(hexadecimalString: "49c04ebaaf9f4dfda6cac4d617cd07098fec39f0")!)
        buffer.append(Data(hexadecimalString: "4ac04c1ae961bc4f3e2cd395396dc8098bbf4bd5")!)
        buffer.append(Data(hexadecimalString: "4bc0d95ed88f296e8d68c35085af86e5ef8d8bf0")!)
        buffer.append(Data(hexadecimalString: "4cc0658ccce111259ce8ac5cbedfc46deda77433")!)
        buffer.append(Data(hexadecimalString: "4dc05fda2f8d2885082db4b1356c5e2a0e830471")!)
        buffer.append(Data(hexadecimalString: "4ec066c7813ff84a9da11fe343e5a95bbfa3082c")!)
        buffer.append(Data(hexadecimalString: "4fc03bcfd6fe6d9657d04f06ed7bc461ebe18d47")!)
        buffer.append(Data(hexadecimalString: "50c035bbe880ba24d7c84f73ae061b33d62a1845")!)
        buffer.append(Data(hexadecimalString: "51c0650f0a6bbc91b2771549cf49a5a4faf8b278")!)
        buffer.append(Data(hexadecimalString: "52c07ac551477e6cd10fe6a3b43d62b02569d110")!)
        buffer.append(Data(hexadecimalString: "53c005f79d6de0ec017e7a0c98961ce6770f885d")!)
        buffer.append(Data(hexadecimalString: "54c0d05fee0b5f5bf9de8c61b58f8634ecbf3347")!)
        buffer.append(Data(hexadecimalString: "55c0e0c7d345fbc40f35aed12e82f8ccb0ed9335")!)
        buffer.append(Data(hexadecimalString: "56c0b1c8b263179e")!)

        XCTAssertEqual(Int(response.bufferLength), buffer.count)
        XCTAssertEqual(response.bufferCRC, buffer.crc16)

        let messages = buffer.glucose

        XCTAssertFalse(messages.first!.timestamp >= response.startTime &&
                        messages.last!.timestamp <= response.endTime)

        XCTAssertEqual(191, messages.count)
    }

    func testNotGlucoseBackfill2() {
        let response = GlucoseBackfillRxMessage(data: Data(hexadecimalString: "51000102b1aa0e00e5b20e00a000000020a39b7e")!)!

        XCTAssertEqual(.ok, TransmitterStatus(rawValue: response.status))
        XCTAssertEqual(1, response.backfillStatus)
        XCTAssertEqual(2, response.identifier)
        XCTAssertEqual(961201, response.startTime)
        XCTAssertEqual(963301, response.endTime)
        XCTAssertEqual(160, response.bufferLength)
        XCTAssertEqual(0xA320, response.bufferCRC)

        // 0xcde3
        // 0b11001101 11100011
        var buffer = GlucoseBackfillFrameBuffer(identifier: 0x80)
        buffer.append(Data(hexadecimalString: "0180cde3fd48248e37a7bf6c2d9d78d4bfef6d5b")!)
        buffer.append(Data(hexadecimalString: "02809f074c9039b6d3b841f422cf36398338f98c")!)
        buffer.append(Data(hexadecimalString: "038004160a5a1ad37c382f3ca23ea215c644f7b6")!)
        buffer.append(Data(hexadecimalString: "04802ed7376fa7c83c3ecf0b645233f9b3c80238")!)
        buffer.append(Data(hexadecimalString: "05805692724e630a703f01b0a942250f725553d2")!)
        buffer.append(Data(hexadecimalString: "06804ca2727a4051033a550da80905caf77c735d")!)
        buffer.append(Data(hexadecimalString: "07808f937b4b9602c5dd6fa13ae983e00783b28e")!)
        buffer.append(Data(hexadecimalString: "088069846e672c106b339159ead9ee1c08e1a159")!)

        XCTAssertEqual(Int(response.bufferLength), buffer.count)
        XCTAssertEqual(response.bufferCRC, buffer.crc16)

        let messages = buffer.glucose

        XCTAssertFalse(messages.first!.timestamp >= response.startTime &&
                        messages.last!.timestamp <= response.endTime)

        XCTAssertEqual(17, messages.count)
    }
}
