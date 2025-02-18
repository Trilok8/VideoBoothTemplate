//
//  VideoEditor.swift
//  VideoBoothTemplate
//
//  Created by Altaf Razzaque on 18/02/2025.
//

import AVFoundation
import UIKit

class VideoEditor {
    
    /// ✅ Applies slow motion effect to a specific part of the video
    func applySlowMotionEffect(to videoURL: URL, slowMotionStart: CMTime, slowMotionDuration: CMTime, outputURL: URL, completion: @escaping (Bool, URL?) -> Void) {
        
        Task {
            do {
                let asset = AVURLAsset(url: videoURL)
                let composition = AVMutableComposition()
                
                // ✅ Load video tracks asynchronously
                guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
                    print("⚠️ Video track not found")
                    completion(false, nil)
                    return
                }
                
                let compositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
                
                guard let audioTrack = try await asset.loadTracks(withMediaType: .audio).first else {
                    print("⚠️ Audio track not found")
                    completion(false, nil)
                    return
                }
                
                // ✅ Audio composition track
                let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                
                
                let fullDuration = try await asset.load(.duration)
                
                // ✅ Insert the original video
                try compositionTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: fullDuration), of: videoTrack, at: .zero)
                try audioCompositionTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: fullDuration), of: audioTrack, at: .zero)
                         
                
                // ✅ Apply slow-motion effect (2x slower)
                let slowEnd = CMTimeAdd(slowMotionStart, slowMotionDuration)
                let slowRange = CMTimeRange(start: slowMotionStart, duration: slowMotionDuration)
                
                let newDuration = CMTimeMultiplyByFloat64(slowMotionDuration, multiplier: 3.0) // Slow down 2x
                compositionTrack?.scaleTimeRange(slowRange, toDuration: newDuration)
                
                // ✅ Apply slow-motion effect to audio (same time range)
                audioCompositionTrack?.scaleTimeRange(slowRange, toDuration: newDuration)
                
                // ✅ Export the slow-motion video
                await exportEditedVideo(composition: composition, outputURL: outputURL, completion: completion)
                
            } catch {
                print("⚠️ Error processing video: \(error.localizedDescription)")
                completion(false, nil)
            }
        }
    }
    
    /// ✅ Exports the edited video asynchronously
    private func exportEditedVideo(composition: AVMutableComposition, outputURL: URL, completion: @escaping (Bool, URL?) -> Void) async {
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            print("⚠️ Failed to create export session")
            completion(false, nil)
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        
        await withCheckedContinuation { continuation in
            exportSession.exportAsynchronously {
                DispatchQueue.main.async {
                    if exportSession.status == .completed {
                        print("✅ Slow-motion video saved at: \(outputURL)")
                        completion(true, outputURL)
                    } else {
                        print("⚠️ Export failed: \(exportSession.error?.localizedDescription ?? "Unknown error")")
                        completion(false, nil)
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    func getVideoFilePath(prefix: String) -> URL{
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let appVideosDirectory = documentDirectory.appendingPathComponent("EditedVideos")
        
        if !fileManager.fileExists(atPath: appVideosDirectory.path){
            do{
                try fileManager.createDirectory(at: appVideosDirectory, withIntermediateDirectories: true,attributes: nil)
            } catch {
                print("Error creating RecordedVideos Directory: \(error.localizedDescription)")
            }
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmssSSS"
        let timeStamp = formatter.string(from: Date())
        
        let videoFileName = "\(prefix)_\(timeStamp).mov"
        return appVideosDirectory.appendingPathComponent(videoFileName)
    }
}
