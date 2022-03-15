//
//  TSPlayerModuleInterface.swift
//  TransferModular
//
//  Created by Alex Linkov on 6/8/21.
//

import Foundation
import AVFAudio

public protocol TSPlayerModuleInterface {
    
    func load(file: AVAudioFile) throws
    func play()
    func play(from time: TimeInterval)
    func play(from inTime: TimeInterval, till outTime: TimeInterval)
    func playWithoutSegment(from inTime: TimeInterval, till outTime: TimeInterval)
    func pause()
    func seek(to time: TimeInterval)
    
    var duration: TimeInterval { get }
    var currentTime: TimeInterval { get }
    
    var isPlaying: Bool { get }
    var isLooping: Bool { get set }
    var isReady: Bool { get }
}

public protocol TSPlayerModuleDelegate: AnyObject {
    
    func playerPlaybackProgressDidUpdate(player: TSPlayer, progress: TimeInterval, isSegment: Bool)
    func playerDidFinish(player: TSPlayer)
    func playerDidFail(player: TSPlayer, error: TSPlayerModuleError)
}
