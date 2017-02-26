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

import CoreBluetooth

var recorder: AVAudioRecorder!
var levelTimer = Timer()
var lowPassResults: Double = 0.0

let BEAN_NAME = "Robu"
let BEAN_SCRATCH_UUID =
    CBUUID(string: "a495ff21-c5b1-4b44-b512-1370f02d74de")
let BEAN_SERVICE_UUID =
    CBUUID(string: "a495ff20-c5b1-4b44-b512-1370f02d74de")

let screenSize: CGRect = UIScreen.main.bounds

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
//    @IBOutlet weak var slider: UISlider!
//    @IBOutlet weak var label: UILabel!
//    @IBOutlet weak var amplitudeSlider: UISlider!
//    
//    @IBOutlet weak var otherLabel: UILabel!
    
    //music playing
    var engine: AVAudioEngine!
    var tone: AVTonePlayerUnit!
    
    var frequency: Float!
    var partial: Int!
    var frequencyMod: Float!
    var mod: Float!
    
    var x: Float!
    var y: Float!
    
    var imageView: UIImageView!
    var imageSize: CGSize!
    
    var loudness: [Float]!
    
    
    //bluetooth
    var manager:CBCentralManager!
    var peripheral:CBPeripheral!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        manager = CBCentralManager(delegate: self, queue: nil)

        
        self.frequency = 410
        self.partial = 0
        self.frequencyMod = 0.0
        self.mod = 0
        self.x = 0.0
        self.y = 0.0
        self.loudness = []
       //tone player setup
        tone = AVTonePlayerUnit()
        tone.volume = 1;
//        label.text = String(format: "%.1f", tone.frequency)
//        slider.minimumValue = -5.0
//        slider.maximumValue = 5.0
//        slider.value = 0.0
//        
//        slider.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI_2));
//        
//        amplitudeSlider.minimumValue = 0
//       amplitudeSlider.maximumValue = 1
//        amplitudeSlider.value = 0.25
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
            
            print("1")
            // make a dictionary (disgusting)
                let recordSettings:[String: Any] = [(AVFormatIDKey as NSObject) as! String:kAudioFormatAppleIMA4 as AnyObject,
                                                          (AVSampleRateKey as NSObject) as! String:44100.0 as AnyObject,
                                                          (AVNumberOfChannelsKey as NSObject) as! String:2 as AnyObject,(AVEncoderBitRateKey as NSObject) as! String:12800 as AnyObject,
                                                          (AVLinearPCMBitDepthKey as NSObject) as! String:16 as AnyObject,
                                                          (AVEncoderAudioQualityKey as NSObject) as! String:AVAudioQuality.max.rawValue as AnyObject
                
            ]
            print("2")
            var error: NSError?
            
            //Instantiate an AVAudioRecorder
            try recorder = AVAudioRecorder(url: url, settings: recordSettings)
            if let e = error {
                //NSLog(e.localizedDescription)
            } else {
                recorder.prepareToRecord()
                recorder.isMeteringEnabled = true
                recorder.record()
                
                levelTimer = Timer.scheduledTimer(timeInterval: 0.005, target: self, selector: #selector(ViewController.levelTimerCallback), userInfo: nil, repeats: true)
                
            }
        } catch {
            //whoops
        }
        
        imageSize = CGSize(width: screenSize.width, height: screenSize.height)
        imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: imageSize))
        self.view.addSubview(imageView)
        
    
}

func drawCustomImage(size: CGSize) -> UIImage {
    print("drawing")
    // Setup our context
    let bounds = CGRect(origin: CGPoint.zero, size: size)
    let opaque = false
    let scale: CGFloat = 0
    UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
    let context = UIGraphicsGetCurrentContext()
    
    // Setup complete, do drawing here
    let color = UIColor.red
    context!.setStrokeColor(color.cgColor)
    context!.setLineWidth(1.0)
    
    context!.stroke(bounds)
    
    context!.beginPath()
    if loudness.count <= Int(screenSize.width) {
        for i in 0..<loudness.count {
            context?.move(to: CGPoint(x: i, y: (Int(loudness[i]) + 40) * -4 + Int(screenSize.height)/2))
            context?.addLine(to: CGPoint(x:i, y:(Int(loudness[i]) + 40) * 4 + Int(screenSize.height)/2))
        }
        context!.strokePath()
    
    } else {
        let diff = loudness.count - Int(screenSize.width)
        for i in (loudness.count - Int(screenSize.width))..<loudness.count {
            context?.move(to: CGPoint(x: i - diff , y: (Int(loudness[i]) + 40) * -4 + Int(screenSize.height)/2))
            context?.addLine(to: CGPoint(x:i - diff , y:(Int(loudness[i]) + 40) * 4 + Int(screenSize.height)/2))
        }
        context!.strokePath()
    }
    context!.strokePath()
    
    // Drawing complete, retrieve the finished image and cleanup
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image!
}

    
//    func draw(_ rect: CGRect) {
//        let aPath = UIBezierPath()
//        
//        aPath.move(to: CGPoint(x:20, y:50))
//        
//        aPath.addLine(to: CGPoint(x:300, y:50))
//        
//        //Keep using the method addLineToPoint until you get to the one where about to close the path
//        
//        aPath.close()
//        
//        //If you want to stroke it with a red color
//        UIColor.red.set()
//        aPath.stroke()
//        //If you want to fill it as well
//        aPath.fill()
//    }
    
    //potentially touch screen
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.location(in: self.view)
            print(position.x)
            print(position.y)
            self.x = Float(position.x)
            self.y = Float(position.y)
        }
        
}
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
       
        if let touch = touches.first {
            let position = touch.location(in: self.view)
            print(position.x)
            print(position.y)
            updateMods(x: position.x, y: position.y)
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.frequencyMod = 0.0
        self.mod = 0
    }
    
    func updateMods(x: CGFloat, y: CGFloat) {
        let xfrac = (x - CGFloat(self.x)) / screenSize.width
        let yfrac = (y - CGFloat(self.y)) / screenSize.height
        
        self.frequencyMod = (Float(yfrac)) + self.frequencyMod
        self.mod = Float(xfrac) + self.mod
        if self.mod > 1 {
            self.mod = 1.0
        } else if self.mod < -1.0 {
            self.mod = -1.0
        }
        
        self.x = Float(x)
        self.y = Float(y)
        
    }
    
    //bluetooth
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if #available(iOS 10.0, *) {
            if central.state == CBManagerState.poweredOn {
                print("scanning for peripherals")
                central.scanForPeripherals(withServices: nil, options: nil)
            } else {
                print("Bluetooth not available.")
            }
        } else {
            // Fallback on earlier versions
        }
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("found device")
        
        let device = (advertisementData as NSDictionary)
            .object(forKey: CBAdvertisementDataLocalNameKey)
            as? NSString
        
        print(device)
        
        if device?.contains(BEAN_NAME) == true {
            self.manager.stopScan()
            
            self.peripheral = peripheral
            self.peripheral.delegate = self
            
            manager.connect(peripheral, options: nil)
        }

    }
    
    
    func centralManager(
        central: CBCentralManager,
        didConnectPeripheral peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            let thisService = service as CBService
            
            if service.uuid == BEAN_SERVICE_UUID {
                peripheral.discoverCharacteristics(
                    nil,
                    for: thisService
                )
            }
        }
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?) {
        for characteristic in service.characteristics! {
            let thisCharacteristic = characteristic as CBCharacteristic
            
            if thisCharacteristic.uuid == BEAN_SCRATCH_UUID {
                self.peripheral.setNotifyValue(
                    true,
                    for: thisCharacteristic
                )
            }
        }
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?) {
        var count:UInt32 = 0;
        
        if characteristic.uuid == BEAN_SCRATCH_UUID {
            //characteristic.value!.copyBytes(to: &count, count: UInt32(MemoryLayout<UInt32>.size))
            //labelCount.text =
            //count = characteristic.value as Int
             //   NSString(format: "%llu", count) as String
            print("got a matching id")
        }
    }
    
    
    //This called every time timer fires
    func levelTimerCallback() {
        let image = drawCustomImage(size: imageSize)
        imageView.image = image
        recorder.updateMeters()
        
        //if we're blowing
        let vol = recorder.averagePower(forChannel: 0)
        self.loudness.append(vol)
        if (vol > -23) {
            if (vol > -10) {
                //print("high")
                self.partial = 1
            } else {
                //print("blowing");
                self.partial = 0
            }
            
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
                    //NSLog((error as! NSString) as String)
                } else {
                    // Handle incoming data like you would in synchronous request
                    let reply = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                    if let data = reply?.data(using: String.Encoding.utf8.rawValue) {
                        
                        do {
                            let dictonary = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject]
                            
                            if let myDictionary = dictonary
                            {
                                let state = myDictionary["result"] as! String
                                
                                if self.partial == 0 || self.partial == 1 {
                                    switch state {
                                    case "open" : self.frequency = 440
                                    case "valveOne" : self.frequency = 493.88
                                    case "valveTwo" : self.frequency = 554.37 // C#
                                    case "valveThree": self.frequency = 587.33 // D
                                    case "valveTwoThree": self.frequency = 659.25
                                    case "valveOneThree": self.frequency = 739.99
                                    case "valveOneTwo" : self.frequency = 830.61
                                    case "valveOneTwoThree": self.frequency = 880 
                                    default : self.frequency = 1
                                    }
                                }
                                //first partial
//                                if self.partial == 0 || self.partial == 1 {
//                                    switch state {
//                                    case "open" : self.frequency = 523.5 //C
//                                    case "valveOne" : self.frequency = 466.16 //Bb
//                                    case "valveTwo" : self.frequency = 493.88 // B
//                                    case "valveThree": self.frequency = 415.3 // Ab
//                                    case "valveTwoThree": self.frequency = 622.25 // Eb
//                                    case "valveOneThree": self.frequency = 587.33 // D
//                                    case "valveOneTwo" : self.frequency = 440 // A
//                                    case "valveOneTwoThree": self.frequency = 554.37 // C#
//                                    default : self.frequency = 1
//                                    }
//                                }
                                //second partial
//                                if self.partial == 1 {
//                                    switch state {
//                                    case "open" : self.frequency = 783.99 // G
//                                    case "valveOne" : self.frequency = 698.46 //F                              
//                                    case "valveTwo" : self.frequency = 739.99 // F#
//                                    case "valveThree": self.frequency = 880 // A
//                                    case "valveTwoThree": self.frequency = 830.61// G#
//                                    case "valveOneThree": self.frequency = 932.33 // A#
//                                    case "valveOneTwo" : self.frequency = 659.25 // E
//                                    case "valveOneTwoThree": self.frequency = 987.77 // B
//                                    default : self.frequency = 1
//                                    }
//                                }
                                
                            }
                            
//
                        } catch let error as NSError {
                            print(error)
                        }
                    }
                }
                
            }
            task.resume()
            tone.frequency = Double(frequency) + Double(frequencyMod) * 40.0
            tone.mod = self.mod
            
            if !tone.isPlaying {
                tone.preparePlaying()
                tone.play()
                engine.mainMixerNode.volume = 1.0
            }

        } else {
            self.partial = 0
            //print("not blowing")
            if tone.isPlaying {
                engine.mainMixerNode.volume = 0.0
                tone.stop()
            }
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
    
//    @IBAction func sliderChanged(_ sender: UISlider) {
//        
//        if (sender.tag == 0) {
//            let freq = 440.0 * pow(2.0, Double(slider.value))
//            tone.frequency = freq
//            label.text = String(format: "%.1f", freq)
//                    } else {
//            let amp = Double(sender.value);
//            tone.amplitude = Double(amp);
//            otherLabel.text = String(format: "%f.1f", amp);
//        }
//        
//    }
    
//    @IBAction func togglePlay(_ sender: UIButton) {
//        if tone.isPlaying {
//            engine.mainMixerNode.volume = 0.0
//            tone.stop()
//            sender.setTitle("Start", for: UIControlState())
//        } else {
//            tone.preparePlaying()
//            tone.play()
//            engine.mainMixerNode.volume = 1.0
//            sender.setTitle("Stop", for: UIControlState())
//        }
//    }
}

