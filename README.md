# TSPlayer

A wrapper on AVAudioPlayer with progress callback and ability to play a segment from audio file. Uses several relevant AudioKit classes so you don't have to import AudioKit if you don't need it.

## Installation
To add TSPlayer to your Xcode project, select File -> Swift Packages -> Add Package Depedancy. Enter `https://github.com/FvnctionHQ/ts-player`


## Api

After init load file or use convenience init
`func load(file: AVAudioFile) throws`

Play entire file
`func play()`

Play entire file from time
`func play(from time: TimeInterval)`

Play segment from the file
`func play(from inTime: TimeInterval, till outTime: TimeInterval)`

Pause playback
`func pause()`

Toggle loopining
`func toggleLooping()`

Check if player is playing
`var isPlaying: Bool { get }`

Check if player is in loop mode
`var isLooping: Bool { get }`

## Delegate

Called as player plays the file, `isSegment` is true if currently played file is a segment of entire file defined by `inTime` and `outTime`
`func playerPlaybackProgressDidUpdate(player: TSPlayer, progress: TimeInterval, isSegment: Bool)`

Called when player finished playback in non-looping mode
`func playerDidFinish(player: TSPlayer)`

Called when player experienced an error
`func playerDidFail(player: TSPlayer, error: TSPlayerModuleError)`
