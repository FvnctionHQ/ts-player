# TSPlayer

A wrapper on AVAudioPlayer with progress callback and ability to play a segment from audio file. Uses several relevant AudioKit classes so you don't have to import AudioKit if you don't need it.

## Installation
To add TSPlayer to your Xcode project, select File -> Swift Packages -> Add Package Depedancy. Enter `https://github.com/FvnctionHQ/ts-player`


## Api

After init load file or use convenience init <br />
`func load(file: AVAudioFile) throws`

Play entire file  <br />
`func play()`

Play entire file from time <br />
`func play(from time: TimeInterval)`

Play segment from the file <br />
`func play(from inTime: TimeInterval, till outTime: TimeInterval)`

Pause playback <br />
`func pause()`

Toggle loopining <br />
`func toggleLooping()`

Check if player is playing <br />
`var isPlaying: Bool { get }`

Check if player is in loop mode <br />
`var isLooping: Bool { get }`

## Delegate


`func playerPlaybackProgressDidUpdate(player: TSPlayer, progress: TimeInterval, isSegment: Bool)` <br />
Called as player plays the file, `isSegment` is true if currently played file is a segment of entire file defined by `inTime` and `outTime` 

`func playerDidFinish(player: TSPlayer)`   <br />
Called when player finished playback in non-looping mode

`func playerDidFail(player: TSPlayer, error: TSPlayerModuleError)`  <br />
Called when player experienced an error

