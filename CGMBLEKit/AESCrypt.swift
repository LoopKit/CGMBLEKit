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
        let status = outputBuffer.withUnsafeMutableBytes { (outputBufferBytes) in
            data.withUnsafeBytes({ (dataBytes) in
                key.withUnsafeBytes({ (keyBytes ) in
                    CCCrypt(CCOperation(kCCEncrypt),
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(kCCOptionECBMode),
                            keyBytes.baseAddress,
                            key.count,
                            nil,
                            dataBytes.baseAddress,
                            data.count,
                            outputBufferBytes.baseAddress,
                            outputBufferLength,
                            nil)
                })
            })
        }
        if status == kCCSuccess {
            return outputBuffer
        }
        return nil
    }
}
