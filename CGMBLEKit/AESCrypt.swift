//
//  File.swift
//  
//
//  Created by Pete Schwamb on 11/25/20.
//

import Foundation
import CCommonCrypto


struct AESCrypt {
    static func encryptData(_ data: Data, usingKey key: Data) -> Data? {
        
        var outputBuffer = Data(count: data.count + kCCBlockSizeAES128)
        let outputBufferLength = outputBuffer.count
        var encryptedLength = Int(0)
        let status: CCCryptorStatus = outputBuffer.withUnsafeMutableBytes { (outputBufferBytes) -> CCCryptorStatus in
            let result: CCCryptorStatus
            result = data.withUnsafeBytes({ (dataBytes) -> CCCryptorStatus in
                let result: CCCryptorStatus
                result = key.withUnsafeBytes({ (keyBytes ) -> CCCryptorStatus in
                    return CCCrypt(CCOperation(kCCDecrypt),
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(kCCOptionECBMode),
                            keyBytes.baseAddress,
                            key.count,
                            nil,
                            dataBytes.baseAddress,
                            data.count,
                            outputBufferBytes.baseAddress,
                            outputBufferLength,
                            &encryptedLength)
                })
                return result
            })
            return result
        }
        if status == kCCSuccess {
            outputBuffer.count = encryptedLength
            return outputBuffer
        }
        return nil
    }
}
