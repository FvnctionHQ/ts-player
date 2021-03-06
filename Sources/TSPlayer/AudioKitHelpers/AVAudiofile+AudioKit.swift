//
//  File.swift
//  
//
//  Created by Alex Linkov on 6/8/21.
//

// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

import Accelerate
import AVFoundation

public typealias FloatChannelData = [[Float]]

extension AVAudioFile {
    /// Duration in seconds
    public var duration: TimeInterval {
        Double(length) / fileFormat.sampleRate
    }

    /// returns the max level in the file as a Peak struct
    public var peak: AVAudioPCMBuffer.Peak? {
        toAVAudioPCMBuffer()?.peak()
    }

    /// Convenience init to instantiate a file from an AVAudioPCMBuffer.
    public convenience init(url: URL, fromBuffer buffer: AVAudioPCMBuffer) throws {
        try self.init(forWriting: url, settings: buffer.format.settings)

        // Write the buffer in file
        do {
            framePosition = 0
            try write(from: buffer)
        } catch let error as NSError {
            let err = TSPlayerModuleError.audiokitError(error.localizedDescription)
            print(err)
            throw error
        }
    }

    /// converts to a 32 bit PCM buffer
    public func toAVAudioPCMBuffer() -> AVAudioPCMBuffer? {
        guard let buffer = AVAudioPCMBuffer(pcmFormat: processingFormat,
                                            frameCapacity: AVAudioFrameCount(length)) else { return nil }

        do {
            framePosition = 0
            try read(into: buffer)

        } catch let error as NSError {
            
            let err = TSPlayerModuleError.audiokitError(error.localizedDescription)
            print(err)
         
        }

        return buffer
    }

    /// converts to Swift friendly Float array
    public func toFloatChannelData() -> FloatChannelData? {
        guard let pcmBuffer = toAVAudioPCMBuffer(),
              let data = pcmBuffer.toFloatChannelData() else { return nil }
        return data
    }

    /// Will return a 32bit CAF file with the format of this buffer
    @discardableResult public func extract(to outputURL: URL,
                                           from startTime: TimeInterval,
                                           to endTime: TimeInterval) -> AVAudioFile? {
        guard let inputBuffer = toAVAudioPCMBuffer() else {
            let err = TSPlayerModuleError.audiokitError("Error reading into input buffer")
            print(err)
            return nil
        }

        guard let editedBuffer = inputBuffer.extract(from: startTime, to: endTime) else {
            let err = TSPlayerModuleError.audiokitError("Failed to create edited buffer")
            print(err)
            return nil
        }

        var outputURL = outputURL
        if outputURL.pathExtension.lowercased() != "caf" {
            outputURL = outputURL.deletingPathExtension().appendingPathExtension("caf")
        }

        guard let outputFile = try? AVAudioFile(url: outputURL, fromBuffer: editedBuffer) else {
            let err = TSPlayerModuleError.audiokitError("Failed to write new file at \(outputURL)")
            print(err)
            return nil
        }
        return outputFile
    }

    /// - Returns: An extracted section of this file of the passed in conversion options
    public func extract(to url: URL,
                        from startTime: TimeInterval,
                        to endTime: TimeInterval,
                        fadeInTime: TimeInterval = 0,
                        fadeOutTime: TimeInterval = 0,
                        options: FormatConverter.Options? = nil,
                        completionHandler: FormatConverter.FormatConverterCallback? = nil) {
        func createError(message: String, code: Int = 1) -> NSError {
            let userInfo: [String: Any] = [NSLocalizedDescriptionKey: message]
            return NSError(domain: "io.audiokit.FormatConverter.error", code: code, userInfo: userInfo)
        }

        // if options are nil, create them to match the input file
        let options = options ?? FormatConverter.Options(audioFile: self)

        let format = options?.format ?? url.pathExtension
        let directory = url.deletingLastPathComponent()
        let filename = url.deletingPathExtension().lastPathComponent
        let tempFile = directory.appendingPathComponent(filename + "_temp").appendingPathExtension("caf")
        let outputURL = directory.appendingPathComponent(filename).appendingPathExtension(format)

        // first print CAF file
        guard extract(to: tempFile,
                      from: startTime,
                      to: endTime,
                      fadeInTime: fadeInTime,
                      fadeOutTime: fadeOutTime) != nil else {
            completionHandler?(createError(message: "Failed to create new file"))
            return
        }

        // then convert to desired format here:
        guard FileManager.default.isReadableFile(atPath: tempFile.path) else {
            completionHandler?(createError(message: "File wasn't created correctly"))
            return
        }

        let converter = FormatConverter(inputURL: tempFile, outputURL: outputURL, options: options)
        converter.start { error in

            if let error = error {
                let err = TSPlayerModuleError.audiokitError("Done, error: \(error.localizedDescription)")
                print(err)
            }

            completionHandler?(error)

            do {
                // clean up temp file
                try FileManager.default.removeItem(at: tempFile)
            } catch {
                let err = TSPlayerModuleError.audiokitError("Unable to remove temp file at \(tempFile)")
                print(err)
           
            }
        }
    }
}

extension AVURLAsset {
    /// Audio format for  the file in the URL asset
    public var audioFormat: AVAudioFormat? {
        // pull the input format out of the audio file...
        if let source = try? AVAudioFile(forReading: url) {
            return source.fileFormat

            // if that fails it might be a video, so check the tracks for audio
        } else {
            let audioTracks = tracks.filter { $0.mediaType == .audio }

            guard !audioTracks.isEmpty else { return nil }

            let formatDescriptions = audioTracks.compactMap({
                $0.formatDescriptions as? [CMFormatDescription]
            }).reduce([], +)

            let audioFormats: [AVAudioFormat] = formatDescriptions.compactMap {
                AVAudioFormat(cmAudioFormatDescription: $0)
            }
            return audioFormats.first
        }
    }
}
