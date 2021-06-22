//
//  TSPlayerModuleCoordinator.swift
//  TransferModular
//
//  Created by Alex Linkov on 6/8/21.
//

import Foundation
import AVFAudio

public typealias TSPlayer = TSPlayerModuleCoordinator

extension TSPlayerModuleCoordinator: TSPlayerModuleInterface {
    
    public var isReady: Bool {
        get {
            loadedFile  != nil
        }
    }
    
   
    public var duration: TimeInterval {
        
        guard let p = player else {
            delegate.playerDidFail(player: self, error: TSPlayerModuleError.playerNotReady)
            return 0
        }
        
        return p.duration
    }
    
  
    public var currentTime: TimeInterval {
        guard let p = player else {
            delegate.playerDidFail(player: self, error: TSPlayerModuleError.playerNotReady)
            return 0
        }
        
        return p.currentTime
    }
    
    
    public func seek(to time: TimeInterval) {
        
        guard let p = player else {
            delegate.playerDidFail(player: self, error: TSPlayerModuleError.playerNotReady)
            return
        }
        
        
        
        self._seekTo(player: p, time: time)
    }
    
   
    public func load(file: AVAudioFile) throws {
        
        if (file.duration.isZero) {
            throw TSPlayerModuleError.fileDurationIsZero
        }
        outTime = file.duration
        isInSegmentMode = false
        
        loadedFile = file
        _filePlayer = try AVAudioPlayer(contentsOf: loadedFile.url)
    }
    
    public func play() {
        
        isInSegmentMode = false
        
        guard let p = player else {
            delegate.playerDidFail(player: self, error: TSPlayerModuleError.playerNotReady)
            return
        }
        
        
        
        self._play(player: p)
    }
    
    public func play(from time: TimeInterval) {

        isInSegmentMode = false
        
        guard let p = player else {
            delegate.playerDidFail(player: self, error: TSPlayerModuleError.playerNotReady)
            return
        }
    
        if (time > p.duration || time.sign == .minus) {
            
            delegate.playerDidFail(player: self, error: TSPlayerModuleError.fromTimeNotValid)
            return
        }
        
        self._play(player: p, from: time)
        
    }
    
    public func playWithoutSegment(from inTime: TimeInterval, till outTime: TimeInterval) {
        
        guard let p = player else {
            delegate.playerDidFail(player: self, error: TSPlayerModuleError.playerNotReady)
            return
        }
        
        if (inTime > p.duration || inTime.sign == .minus) {
            
            delegate.playerDidFail(player: self, error: TSPlayerModuleError.fromTimeNotValid)
            return
        }
        
        if (outTime > loadedFile.duration || outTime.sign == .minus || outTime <= inTime) {
            
            delegate.playerDidFail(player: self, error: TSPlayerModuleError.tillTimeNotValid)
            return
        }
        
        
        self.outTime = outTime
        
        self._play(player: p, from: inTime)
    }
    
    public func play(from inTime: TimeInterval, till outTime: TimeInterval) {
     
        
        guard let segment = segmentFromFile(file: loadedFile, inTime: inTime, outTime: outTime) else {
            return
        }
        
        do {
            
            _segmentPlayer = try AVAudioPlayer(contentsOf: segment.url)
            
            isInSegmentMode = true
            
            guard let p = player else {
                delegate.playerDidFail(player: self, error: TSPlayerModuleError.playerNotReady)
                return
            }
            

            
            self.segmentInTime = inTime
            
            _play(player: p)
            
            
        } catch let error {
            
            delegate.playerDidFail(player: self, error: .failedToCreatePlaySegment(error.localizedDescription))
        }
        
       
        
    }
    
    public func pause() {
        
        guard let p = player else {
            delegate.playerDidFail(player: self, error: TSPlayerModuleError.playerNotReady)
            return
        }
        
        self._pause(player: p)
    }
    
    public func toggleLooping() {
        
        if (self.numberOfLoops == 0) {
            self.numberOfLoops = -1
        } else {
            self.numberOfLoops = 0
        }
       
    }
    
    public var isPlaying: Bool {
        get {
            guard let p = player else {
                return false
            }
            return p.isPlaying
        }
    }
    
    public var isLooping: Bool {
        get {
            return numberOfLoops == -1
        }
    }
    
    
}

extension TSPlayerModuleCoordinator: AVAudioPlayerDelegate {

    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        
        stopTimer()
        
        if (!flag) {
            delegate.playerDidFail(player: self, error: .audioPlayerDidFinishPlayingNoSuccess)
        } else {
            delegate.playerDidFinish(player: self)
        }
        
    }

    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        
        delegate.playerDidFail(player: self, error: .audioPlayerDecodeErrorDidOccur(error?.localizedDescription))
    }

    public func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
        
        delegate.playerDidFail(player: self, error: .audioPlayerBeginInterruption)
    }

    public func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
        
        delegate.playerDidFail(player: self, error: .audioPlayerEndInterruption)
    }
    
}

public class TSPlayerModuleCoordinator: NSObject {
    unowned let delegate: TSPlayerModuleDelegate
    var outTime: TimeInterval!
    var segmentInTime: TimeInterval = 0
    var playbackTimer: Timer?
    var numberOfLoops = 0
    var isInSegmentMode = false {
        
        didSet {
            if (isInSegmentMode == false && _segmentPlayer != nil) {
                _segmentPlayer?.delegate = nil
                deleteTempFile()
                _segmentPlayer = nil
            }
        }
    }
    var loadedFile: AVAudioFile!
    
    var player: AVAudioPlayer? {
        get {
            if (isInSegmentMode) {
                return self._segmentPlayer
            } else {
                return self._filePlayer
            }
        }
    }
    
    var _filePlayer: AVAudioPlayer?
    var _segmentPlayer: AVAudioPlayer?
    
   public required init(delegate: TSPlayerModuleDelegate) {
        self.delegate = delegate
    }
    
   public convenience init(delegate: TSPlayerModuleDelegate, file: AVAudioFile) throws {
        self.init(delegate: delegate)
        try self.load(file: file)
        
    }
 
    func _play(player: AVAudioPlayer) {
        player.delegate = self
        player.numberOfLoops = numberOfLoops
        player.play()
        startTimer()
    }
    
    func _seekTo(player: AVAudioPlayer, time: TimeInterval) {
        
        player.currentTime = time
        updatePlaybackProgress()
    }
    
    func _play(player: AVAudioPlayer, from time: TimeInterval) {
        player.delegate = self
        player.currentTime = time
        player.play(atTime: player.deviceCurrentTime + 0.01)
        startTimer()
    }
    
    func _pause(player: AVAudioPlayer) {
        
        player.pause()
        stopTimer()
       
    }
    

    
    @objc func updatePlaybackProgress() {
        
        let progress = playbackProgress()
        if (progress >= outTime) {
            pause()
            delegate.playerDidFinish(player: self)
            return
        }
        
        delegate.playerPlaybackProgressDidUpdate(player: self, progress: playbackProgress(), isSegment: isInSegmentMode)
    }
    
    
    func startTimer() {
        
        self.playbackTimer = Timer.scheduledTimer(timeInterval: 0.001, target: self, selector: #selector(updatePlaybackProgress), userInfo: nil, repeats: true)
    }
    
    func stopTimer() {
        self.playbackTimer?.invalidate()
    }
    
    func segmentFromFile(file: AVAudioFile, inTime: TimeInterval, outTime: TimeInterval) -> AVAudioFile? {
        
        let url = tempDirectoryURLForLoadedFileSegment()
        
        if (inTime > loadedFile.duration || inTime.sign == .minus) {
            
            delegate.playerDidFail(player: self, error: TSPlayerModuleError.fromTimeNotValid)
            return nil
        }
        
        if (outTime > loadedFile.duration || outTime.sign == .minus || outTime <= inTime) {
            
            delegate.playerDidFail(player: self, error: TSPlayerModuleError.tillTimeNotValid)
            return nil
        }
        
        guard let segmement = loadedFile.extract(to: url, from: inTime, to: outTime) else {
            
            delegate.playerDidFail(player: self, error: .failedToCreatePlaySegment(nil))
            return nil
        }
        
        return segmement
    }
    
    func playbackProgress() -> TimeInterval {
        
        var p: TimeInterval
        if (isInSegmentMode) {
            p = self.segmentInTime + player!.currentTime
        } else {
            p = player!.currentTime
        }
        
        return p
    }
    
    func tempDirectoryURLForLoadedFileSegment() -> URL {
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempURL = tempDirectory.appendingPathComponent("\(loadedFile.url.lastPathComponent)")
        return tempURL
    }
    
    func deleteTempFile() {
        
        let fileManager = FileManager.default
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempURL = tempDirectory.appendingPathComponent("\(loadedFile.url.lastPathComponent)")
        
        do {
            if (fileManager.fileExists(atPath: tempURL.path)) {
                try fileManager.removeItem(atPath: tempURL.path)
            }
           

        } catch let error  {
        
            delegate.playerDidFail(player: self, error: .failedToClearTempSegment(error.localizedDescription))
        }
    }
    

}
