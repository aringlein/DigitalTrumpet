//
//  ViewController.swift
//  ToneGenerator
//
//  Created by OOPer in cooperation with shlab.jp, on 2015/3/22.
//  See LICENSE.txt .
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var amplitudeSlider: UISlider!
    
    @IBOutlet weak var otherLabel: UILabel!
    var engine: AVAudioEngine!
    var tone: AVTonePlayerUnit!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        // Do any additional setup after loading the view, typically from a nib.
        tone = AVTonePlayerUnit()
        label.text = String(format: "%.1f", tone.frequency)
        slider.minimumValue = -5.0
        slider.maximumValue = 5.0
        slider.value = 0.0
        
        amplitudeSlider.minimumValue = 0
       amplitudeSlider.maximumValue = 3
        amplitudeSlider.value = 0.5
        let format = AVAudioFormat(standardFormatWithSampleRate: tone.sampleRate, channels: 1)
        print(format.sampleRate)
        engine = AVAudioEngine()
        engine.attach(tone)
        let mixer = engine.mainMixerNode
        engine.connect(tone, to: mixer, format: format)
        do {
            try engine.start()
        } catch let error as NSError {
            print(error)
        }
        
        
        
        //microphone initialization
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func sliderChanged(_ sender: UISlider) {
        
        if (sender.tag == 0) {
            let freq = 440.0 * pow(2.0, Double(slider.value))
            tone.frequency = freq
            label.text = String(format: "%.1f", freq)
                    } else {
            let amp = Double(sender.value);
            tone.pan = Float(amp);
            otherLabel.text = String(format: "%f.1f", amp);
        }
        
    }
    
    @IBAction func togglePlay(_ sender: UIButton) {
        if tone.isPlaying {
            engine.mainMixerNode.volume = 0.0
            tone.stop()
            sender.setTitle("Start", for: UIControlState())
        } else {
            tone.preparePlaying()
            tone.play()
            engine.mainMixerNode.volume = 1.0
            sender.setTitle("Stop", for: UIControlState())
        }
    }
}

