//
//  Transaction.swift
//  KeyPair
//
//  Created by James Pecoraro on 1/3/25.
//

//import Foundation
//import SwiftUI
//import CoreLocation

struct Transaction: Hashable, Codable {
    var GSP: String
    var vaultId: Int
    var amount: Float64
    var asset: String
    var destination: String
}
