//
//  GF256.swift
//  KeyPair
//
//  Created by James Pecoraro on 1/31/25.
//


import Foundation

enum GF256 {
    static let irreducible: UInt8 = 0x1B // Rijndael's polynomial (for GF(256))

    static func add(_ a: UInt8, _ b: UInt8) -> UInt8 {
        return a ^ b // XOR is addition in GF(256)
    }

    static func multiply(_ a: UInt8, _ b: UInt8) -> UInt8 {
        var result: UInt8 = 0
        var aVar = a
        var bVar = b

        while bVar > 0 {
            if (bVar & 1) != 0 {
                result ^= aVar
            }
            let highBitSet = (aVar & 0x80) != 0
            aVar <<= 1
            if highBitSet {
                aVar ^= irreducible // Modular reduction with 0x1B
            }
            bVar >>= 1
        }
        return result
    }

    static func modInverse(_ a: UInt8) -> UInt8 {
        for x in 1..<255 {
            if multiply(a, UInt8(x)) == 1 {
                return UInt8(x)
            }
        }
        return 1
    }
}

enum ShamirSecrets {
    // Generate shares for a byte array
    static func generateShares(secretString: String, totalShares: Int, threshold: Int) -> [String] {
        let secretData: [UInt8] = Array(secretString.utf8)
        print(secretData)

        let shares = secretData.map { byte in
            (1...totalShares).map { x in
                let y = evaluatePolynomial(coefficients: generatePolynomial(secret: byte, threshold: threshold), x: UInt8(x))
                return "\(String(format: "%02X", x))\(String(format: "%02X", y))" // Hex encoding
            }
        }

        // Format shares per secrets.js: concatenate bytes into strings
        return (0..<totalShares).map { i in
            shares.map { $0[i] }.joined()
        }
    }

    // Recover secret from hex-encoded shares
    static func recoverSecret(shares: [String], threshold: Int) -> String? {
        let splitShares = shares.map { str in
            stride(from: 0, to: str.count, by: 4).map {
                let index = str.index(str.startIndex, offsetBy: $0)
                let xStr = str[index..<str.index(index, offsetBy: 2)]
                let yStr = str[str.index(index, offsetBy: 2)..<str.index(index, offsetBy: 4)]
                return (UInt8(xStr, radix: 16)!, UInt8(yStr, radix: 16)!)
            }
        }
        
        print(splitShares)
        return nil
//        guard let first = splitShares.first, first.count == threshold else { return nil }
        guard let first = splitShares.first else { return nil }
        print("Count looks good")

        let recoveredBytes = (0..<first.count).map { i in
            lagrangeInterpolation(shares: splitShares.prefix(threshold).map { $0[i] })
        }
        print(recoveredBytes)

        return String(bytes: recoveredBytes, encoding: .utf8)
    }

    // Generate a polynomial for each byte
    static private func generatePolynomial(secret: UInt8, threshold: Int) -> [UInt8] {
        var coefficients = [secret]
        for _ in 1..<threshold {
            coefficients.append(UInt8.random(in: 1...255))
        }
        return coefficients
    }

    // Evaluate polynomial at a given x value
    static private func evaluatePolynomial(coefficients: [UInt8], x: UInt8) -> UInt8 {
        var result: UInt8 = 0
        var power: UInt8 = 1

        for coef in coefficients {
            result = GF256.add(result, GF256.multiply(coef, power))
            power = GF256.multiply(power, x)
        }
        return result
    }

    // Lagrange interpolation to recover a byte
    static private func lagrangeInterpolation(shares: [(UInt8, UInt8)]) -> UInt8 {
        var secret: UInt8 = 0

        for i in 0..<shares.count {
            let (xi, yi) = shares[i]
            var basis: UInt8 = 1

            for j in 0..<shares.count {
                if i != j {
                    let (xj, _) = shares[j]
                    let numerator = GF256.multiply(xj, GF256.modInverse(GF256.add(xj, xi)))
                    basis = GF256.multiply(basis, numerator)
                }
            }
            secret = GF256.add(secret, GF256.multiply(yi, basis))
        }
        return secret
    }
}
