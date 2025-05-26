//
//  QueueJobState.swift
//  Alethia
//
//  Created by Angelo Carasig on 26/5/2025.
//

import Foundation

enum QueueJobState {
    case success(Data?)
    case pending(QueueProgress)
    case failure(Error)
}
