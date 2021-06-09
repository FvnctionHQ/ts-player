//
//  TSPlayerModuleError.swift
//  TransferModular
//
//  Created by Alex Linkov on 6/8/21.
//

import Foundation


public enum TSPlayerModuleError: Error {
    case tillTimeNotValid
    case fromTimeNotValid
    case playerNotReady
    case audiokitError(String?)
    case failedToClearTempSegment(String?)
    case failedToCreatePlaySegment(String?)
    case audioPlayerDidFinishPlayingNoSuccess
    case audioPlayerDecodeErrorDidOccur(String?)
    case audioPlayerBeginInterruption
    case audioPlayerEndInterruption
  
}

extension TSPlayerModuleError: LocalizedError {
    public var errorDescription: String? {
        switch self {
       
        case .tillTimeNotValid:
  
            return "TSPlayerModule Error: End time position is invalid"
            
        case .fromTimeNotValid:
  
            return "TSPlayerModule Error: Start time position is invalid"
            
        case .playerNotReady:
  
            return "TSPlayerModule Error: Player was not setup properly"
            
        case .failedToClearTempSegment(let reason):
  
            return "TSPlayerModule Error: Failed to remove temp file for audio segment: \(reason ?? "")"
            
            
        case .audioPlayerDidFinishPlayingNoSuccess:
  
            return "TSPlayerModule Error: Player finished playing abnormally"
            
        case .audioPlayerDecodeErrorDidOccur(let reason):
  
            return "TSPlayerModule Error: Player decode error occured: \(reason ?? "")"
            
        case .audiokitError(let reason):
  
            return "TSPlayerModule Error: AudioKit Extension Error: \(reason ?? "")"
            
            
        case .failedToCreatePlaySegment(let reason):
  
            return "TSPlayerModule Error: Failed to create playback segment: \(reason ?? "")"
      
        case .audioPlayerBeginInterruption:
  
            return "TSPlayerModule Error: Abnormal interruption occured"
     
        case .audioPlayerEndInterruption:
  
            return "TSPlayerModule Error: Abnormal interruption ended"
        }
    }
}
