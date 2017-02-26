//
//  AVTonePlayerUnit.swift
//  ToneGenerator
//
//  Created by OOPer in cooperation with shlab.jp, on 2015/3/22.
//  See LICENSE.txt .
//

import Foundation
import AVFoundation

class AVTonePlayerUnit: AVAudioPlayerNode {
    let bufferCapacity: AVAudioFrameCount = 512
//    let sampleRate: Double = 44_100.0
    let sampleRate: Double = 60_100.0
    
    var frequency: Double = 440.0
    var amplitude: Double = 0.5
    var mod: Float = 0
    var val: Float = 0.0
    
    private var theta: Double = 0.0
    private var audioFormat: AVAudioFormat!
    
    override init() {
        super.init()
        audioFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
    }
    
    func prepareBuffer() -> AVAudioPCMBuffer {
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: bufferCapacity)
        fillBuffer(buffer)
        return buffer
    }
    
    func flat(val: Float) -> Float {
        if theta < M_PI {
            return 1.0
        } else {
            return -1.0
        }
    }
    
    func pointy(val: Float) -> Float {
        if theta >= 0 && theta < M_PI/2 {
            return Float(theta)/Float((M_PI/2))
        } else if theta >= M_PI/2 && theta < M_PI {
            return Float((1.0 - (theta - M_PI/2) / (M_PI/2)))
        } else if theta > M_PI && theta <= M_PI * 3.0 / 2.0{
            return Float((theta - M_PI) / (M_PI/2) * (-1.0))
        } else {
            return Float((1.0 - (theta - 3 * M_PI/2) / (M_PI/2)) * (-1.0))
        }
    }
    
    func fillBuffer(_ buffer: AVAudioPCMBuffer) {
        let data = buffer.floatChannelData?[0]
        let numberFrames = buffer.frameCapacity
        var theta = self.theta
        let theta_increment = 2.0 * M_PI * self.frequency / self.sampleRate;
        
        for frame in 0..<Int(numberFrames) {
            var value: Float
            if mod < 0 {
                 value = Float(sin(theta)) * Float(amplitude) * (1 - (mod*(-1))) + Float(pointy(val: Float(theta))) * Float(amplitude) * (mod * (-1))
            } else {
                 value = Float(sin(theta)) * Float(amplitude) * (1 - mod) + Float(flat(val: Float(theta))) * Float(amplitude) * mod
            }
            val = value
            data?[frame] = Float32(val)
            
            theta += theta_increment
            if theta > 2.0 * M_PI {
                theta -= 2.0 * M_PI
            }
        }
        buffer.frameLength = numberFrames
        self.theta = theta
    }
    
    func scheduleBuffer() {
        let buffer = prepareBuffer()
        self.scheduleBuffer(buffer) {
            if self.isPlaying {
                self.scheduleBuffer()
            }
        }
    }
    
    func preparePlaying() {
        scheduleBuffer()
        scheduleBuffer()
        scheduleBuffer()
        scheduleBuffer()
    }
}
