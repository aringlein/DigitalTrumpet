//
//  ViewController.swift
//  ToneGenerator
//
//  Created by OOPer in cooperation with shlab.jp, on 2015/3/22.
//  See LICENSE.txt .
//

import UIKit
import AVFoundation

import AVFoundation
import CoreAudio

var recorder: AVAudioRecorder!
var levelTimer = Timer()
var lowPassResults: Double = 0.0

class ViewController: UIViewController {
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var amplitudeSlider: UISlider!
    
    @IBOutlet weak var otherLabel: UILabel!
    
    //music playing
    var engine: AVAudioEngine!
    var tone: AVTonePlayerUnit!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       //tone player setup
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
        do {
            //make an AudioSession
            let audioSession:AVAudioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try audioSession.setActive(true)
            
            //set up the URL
            let documents: NSString = NSSearchPathForDirectoriesInDomains( FileManager.SearchPathDirectory.documentDirectory,  FileManager.SearchPathDomainMask.userDomainMask, true)[0] as NSString
            let str =  documents.appendingPathComponent("recordTest.caf")
            let url = NSURL.fileURL(withPath: str as String)
            
            // make a dictionary (disgusting)
                let recordSettings:[String: Any] = [(AVFormatIDKey as NSObject) as! String:kAudioFormatAppleIMA4 as AnyObject,
                                                          (AVSampleRateKey as NSObject) as! String:44100.0 as AnyObject,
                                                          (AVNumberOfChannelsKey as NSObject) as! String:2 as AnyObject,(AVEncoderBitRateKey as NSObject) as! String:12800 as AnyObject,
                                                          (AVLinearPCMBitDepthKey as NSObject) as! String:16 as AnyObject,
                                                          (AVEncoderAudioQualityKey as NSObject) as! String:AVAudioQuality.max.rawValue as AnyObject
                
            ]
            
            var error: NSError?
            
            //Instantiate an AVAudioRecorder
            try recorder = AVAudioRecorder(url: url, settings: recordSettings)
            if let e = error {
                NSLog(e.localizedDescription)
            } else {
                recorder.prepareToRecord()
                recorder.isMeteringEnabled = true
                recorder.record()
                
                levelTimer = Timer.scheduledTimer(timeInterval: 0.02, target: self, selector: #selector(ViewController.levelTimerCallback), userInfo: nil, repeats: true)
                
            }
        } catch {
            //whoops
        }
    }
    
    //This called every time timer fires
    func levelTimerCallback() {
        recorder.updateMeters()
        
        //if we're blowing
        let vol = recorder.averagePower(forChannel: 0)
        if (vol > -10) {
            //do something because we're blowing
            //make the request
            let urlPath: String = "https://api.particle.io/v1/devices/3e0033000a47353138383138/status?access_token=2a62610028c4a017bcea1bddec41439585c23a9b"
            let url: NSURL = NSURL(string: urlPath)!
            //let request = NSURLRequest(url: url as URL)
            //request.httpMethod = "GET"
            
            let session = URLSession.shared
            //session.dataTaskWithUrl(with: request as URLRequest) { (data)
            let task = session.dataTask(with: url as URL) { (data, response, error) -> Void in
                
                if (error != nil) {
                    NSLog((error as! NSString) as String)
                } else {
                    // Handle incoming data like you would in synchronous request
                    let reply = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                    if let data = reply?.data(using: String.Encoding.utf8.rawValue) {
                        
                        do {
                            let dictonary = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject]
                            
                            if let myDictionary = dictonary
                            {
                                let state = myDictionary["result"]
//                                switch state {
//                                    //case "open"
//                                }
                                NSLog(state as! String)
                                
                            }
                        } catch let error as NSError {
                            print(error)
                        }
                    }
                }
                
            }
            task.resume()

        }
        
        
    }
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
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

