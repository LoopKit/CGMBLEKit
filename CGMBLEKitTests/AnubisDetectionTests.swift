//
//  AnubisDetectionTests.swift
//  CGMBLEKit
//
//  Covers transmitter-expiry parsing + Anubis-mod detection across the two
//  layers it spans: the version-rx frame decoder and the persisted manager
//  state.
//

import XCTest
@testable import CGMBLEKit

class AnubisDetectionTests: XCTestCase {

    // MARK: - TransmitterVersionRxMessage parsing

    /// Stock G6 reports a 90-day lifetime in the version-rx frame.
    func testStockG6ExpiryParsedAndNotAnubis() {
        // Same layout as TransmitterVersionRxMessageTests' fixture; expiry
        // bytes (13..14, little-endian) overwritten to 0x5A 0x00 = 90.
        let data = makeVersionRxPayload(expiryDays: 90)
        let message = TransmitterVersionRxMessage(data: data)!

        XCTAssertEqual(90, message.transmitterExpiryInDays)
        XCTAssertFalse(message.isAnubis)
    }

    /// Anubis-modded G6 reports 180 days. Mirrors xDrip4iOS's heuristic.
    func testAnubisG6ExpiryParsedAndIsAnubis() {
        let data = makeVersionRxPayload(expiryDays: 180)
        let message = TransmitterVersionRxMessage(data: data)!

        XCTAssertEqual(180, message.transmitterExpiryInDays)
        XCTAssertTrue(message.isAnubis)
    }

    /// Some early transmitters report neither 90 nor 180. They're stock G6
    /// firmware that just doesn't expose the lifetime field reliably; the
    /// only known classification we care about is "is this a 180-day Anubis."
    func testOddExpiryNotClassifiedAsAnubis() {
        let data = makeVersionRxPayload(expiryDays: 112)
        let message = TransmitterVersionRxMessage(data: data)!

        XCTAssertEqual(112, message.transmitterExpiryInDays)
        XCTAssertFalse(message.isAnubis)
    }

    func testWrongOpcodeReturnsNil() {
        var data = makeVersionRxPayload(expiryDays: 90)
        data[0] = 0x4c                                  // not .transmitterVersionRx
        // Re-CRC so the opcode rejection is exercised, not a CRC failure.
        let resealed = data.dropLast(2).appendingCRC()
        XCTAssertNil(TransmitterVersionRxMessage(data: resealed))
    }

    func testInvalidCRCReturnsNil() {
        var data = makeVersionRxPayload(expiryDays: 90)
        // Flip the last byte of the CRC trailer.
        data[data.count - 1] ^= 0xFF
        XCTAssertNil(TransmitterVersionRxMessage(data: data))
    }

    func testWrongLengthReturnsNil() {
        let data = makeVersionRxPayload(expiryDays: 90).dropLast()
        XCTAssertNil(TransmitterVersionRxMessage(data: Data(data)))
    }

    // MARK: - TransmitterManagerState round-trip

    func testManagerStateStoresAndRestoresExpiry() {
        let state = TransmitterManagerState(transmitterID: "ABCDEF", transmitterExpiryInDays: 180)
        let restored = TransmitterManagerState(rawValue: state.rawValue)!

        XCTAssertEqual(180, restored.transmitterExpiryInDays)
        XCTAssertTrue(restored.isAnubis)
    }

    /// Older installs persisted the expiry as a plain `Int` (UserDefaults
    /// rounds UInt16 → Int on archive). The decoder accepts both shapes so an
    /// upgrade doesn't drop the Anubis flag.
    func testManagerStateRestoresLegacyIntExpiry() {
        let raw: [String: Any] = [
            "transmitterID": "ABCDEF",
            "transmitterExpiryInDays": Int(180)
        ]
        let restored = TransmitterManagerState(rawValue: raw)!

        XCTAssertEqual(180, restored.transmitterExpiryInDays)
        XCTAssertTrue(restored.isAnubis)
    }

    func testManagerStateMissingExpiryIsNotAnubis() {
        let state = TransmitterManagerState(transmitterID: "ABCDEF")

        XCTAssertNil(state.transmitterExpiryInDays)
        XCTAssertFalse(state.isAnubis)
    }

    // MARK: - Fixture helper

    /// Builds a 19-byte version-rx payload with the given expiry, opcode +
    /// CRC trailer correctly applied. Patterned on the canonical fixture in
    /// `TransmitterVersionRxMessageTests`.
    private func makeVersionRxPayload(expiryDays: UInt16) -> Data {
        // Bytes 0..12: opcode + status + firmware + filler from the canonical
        // existing fixture. Bytes 13..14: expiry (little-endian). Bytes
        // 15..16: trailing filler. CRC re-computed at the end.
        let body = Data([
            0x4b, 0x00,                                 // opcode + status
            0x01, 0x00, 0x00, 0x11,                     // firmwareVersion
            0xdf, 0x29, 0x00, 0x00, 0x51, 0x00, 0x03,   // filler (bytes 6..12)
            UInt8(expiryDays & 0xff),                   // byte 13: low byte
            UInt8((expiryDays >> 8) & 0xff),            // byte 14: high byte
            0xf0, 0x00                                  // filler (bytes 15..16)
        ])
        return body.appendingCRC()
    }
}
