//
//  ViewController.swift
//  boop
//
//  Created by ariel anders on 2/26/16.
//  Copyright © 2016 ArielAnders. All rights reserved.
//

import UIKit
import AudioToolbox
import AVFoundation
import Darwin



class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate{

    @IBOutlet weak var hi: UIButton!
    var mySound: AVAudioPlayer?
    var tone : AVAudioEngine?
    @IBOutlet weak var capturedImage: UIImageView!
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var capturePhoto: UIButton!
    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var SwiftTimer : NSTimer?
    var sample_buff: CMSampleBufferRef?
    var confused: AVCaptureVideoDataOutputSampleBufferDelegate?
    var audioEngine : AVAudioEngine?
    var updater: NSTimer?
    
    var mySound1: AVAudioPlayer?
    var mySound2: AVAudioPlayer?
    var mySound3: AVAudioPlayer?
    var mySound4: AVAudioPlayer?
    var mySound5: AVAudioPlayer?
    
    var backCamera: AVCaptureDevice?
    
    var lastBuzz: Double?

    
    var prev_lum: Double?
    var prev_lum1: Double?
    
    //var ae:AVAudioEngine?
    var sampler:AVAudioUnitSampler?
    var mixer:AVAudioMixerNode?
    
    var midiNoteNumberFor:Dictionary<String,UInt8>? /*= [
        "BD":48,
        "Snr":50,
        "Hat":52,
        "Hit":53,
        "VI":68,
        "V":67,
        "i":60,
        "III": 63
    ]*/
    


    var lock : Bool?
    
    @IBOutlet weak var luminance: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()

        
        // Do any additional setup after loading the view, typically from a nib.
        
        // initialize the sound
       if let sound = self.setupAudioPlayerWithFile("yourAudioFileName", type: "mp3") {
            self.mySound = sound
        }
        if let sound1 = self.setupAudioPlayerWithFile("blip_2_1", type: "mp3") {
            self.mySound1 = sound1
        }
        if let sound2 = self.setupAudioPlayerWithFile("blip_2_2", type: "mp3") {
            self.mySound2 = sound2
        }

        if let sound3 = self.setupAudioPlayerWithFile("blip_2_115_f2", type: "mp3") {
            self.mySound3 = sound3
        }

        if let sound4 = self.setupAudioPlayerWithFile("blip_2_2_f3", type: "mp3") {
            self.mySound4 = sound4
        }

        if let sound5 = self.setupAudioPlayerWithFile("blip_2_5", type: "mp3") {
            self.mySound5 = sound5
        }

        
        
        self.prev_lum1 = 0.0
        self.prev_lum = 0.0

        self.tone = AVAudioEngine()
        NSLog("Hello world! Loaded Program!")
        self.audioEngine = AVAudioEngine()
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        self.updater = NSTimer.scheduledTimerWithTimeInterval( 0.01, target: self, selector: "update", userInfo: nil, repeats: true)
        
        let urls = NSBundle.mainBundle().URLsForResourcesWithExtension("wav", subdirectory: "wavs")
        midiNoteNumberFor = [
            "BD":48,
            "Snr":50,
            "Hat":52,
            "Hit":53,
            "VI":68,
            "V":67,
            "i":60,
            "III": 63
        ]
        self.lastBuzz =   NSDate().timeIntervalSince1970
        self.lock = false
        

        //ae = AVAudioEngine()
        mixer = self.audioEngine?.mainMixerNode
        
        sampler = AVAudioUnitSampler()
        
        self.audioEngine?.attachNode(sampler!)
        //self.audioEngine?.start()
        self.audioEngine?.connect(sampler!, to: mixer!, format: sampler!.outputFormatForBus(0))
        var error: NSError?

        do{
            try   self.audioEngine?.start()

            //try sampler!.loadAudioFilesAtURLs(urls!)
        }catch let error2 as NSError{
            error = error2
            //NSLog(error?.description)
        }
        //self.update()

        
    
    }


    func play(note:UInt8, velocity:UInt8){
        // shouldn't I care if snd exists in the
        // midiNoteNumberFor Dictionary?????????
        //NSLog(String(midiNoteNumberFor![snd]!))
        //sampler!.startNote(midiNoteNumberFor![snd]!, withVelocity: 80,onChannel: 0)
        sampler!.startNote(note, withVelocity: velocity, onChannel: 0)
        
    }
    

    override func accessibilityPerformMagicTap() -> Bool {
        exit(0)
    }
    
    
    func update() {
        if (self.lock!){
            NSLog("locked")
        } else{
            
            self.lock = true
            
       // AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
       // sampler!.stopNote(45, onChannel: 0)
       // sampler!.stopNote(70, onChannel: 0)
       // sampler!.stopNote(80, onChannel: 0)


       // var freq = UInt8(80)
        var amount = (self.prev_lum! + self.prev_lum1!)/2
        let iso = Double((self.backCamera?.ISO)!)
        let exp = Double((self.backCamera?.exposureDuration.seconds)!)
        
        var scalelum =  (log10( amount / (iso*exp)) + 2.4)/3.0
            if (scalelum <= 0.0){
                scalelum = 0.0
            }
            if (scalelum >= 1.0 ){
                scalelum = 1.0
            }
            amount = scalelum
            
        NSLog("iso:%f, exp:%f, scalelum:%f", (self.backCamera?.ISO)!, (self.backCamera?.exposureDuration.seconds)!, scalelum)
            self.luminance.text = String( Int(100.0*amount) )

     
        /*
        if (amount >= 0.95){
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
        
        if (mySound!.playing || mySound1!.playing ){
            return
        }
        
        
        var vol = 0.0
        
        var sound = self.mySound
        
        var note = UInt8(45)
    
        
        if (amount > 0.10 && amount < 0.75){
            vol = (amount - 0.10)*0.5
            //AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            
        }else if (amount >= 0.70){
            
            vol = amount
            sound = self.mySound1
            
            if (amount >= 0.85){
                sound = self.mySound2
            }
            
            if (amount >= 0.90){
                sound = self.mySound3
            }
   
            if (amount >= 0.97){
                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                sound = self.mySound4

            }
            freq = UInt8(amount*100)
            
            note = UInt8(100*amount)
            self.lastNote = 0
        }
        */
            let lo = 73.0
            let hi = 80
            
          let  note = UInt8(20.0*amount + lo)
            
        //let note = UInt8(100*amount)
        let vol = UInt8(amount*100 + 20)
            let sleep_time = 1000000.0*(0.4-0.3*amount)

            if (amount > 0.01){
                self.play(note,velocity:vol )
                let currentDateTime = NSDate().timeIntervalSince1970
               /* if ( (currentDateTime - self.lastBuzz!) > (3*(0.4 + sleep_time/1E6))){

                    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                    self.lastBuzz = currentDateTime
                }*/
                if (amount > 0.95){
                    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                }
                
            }

        //self.play(note,velocity:vol )
        //sleep(1)
        //    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))

        //NSLog(String(sleep_time))
        usleep (UInt32(sleep_time))
        sampler!.stopNote(note, onChannel: 0)
         //   usleep (UInt32(sleep_time))

        self.lock = false
        
        //self.update()
        
        //sound?.volume = Float(vol)
        //sound?.rate = Float(2*vol)
        //sound?.play()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        captureSession = AVCaptureSession()
        captureSession!.sessionPreset = AVCaptureSessionPreset352x288 //AVCaptureSessionPresetPhoto
        var error: NSError?

        backCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        do {
            try backCamera?.lockForConfiguration()
            backCamera?.focusMode = AVCaptureFocusMode.Locked
            //backCamera.setExposureModeCustomWithDuration(duration: CMTime, ISO: <#T##Float#>, completionHandler: <#T##((CMTime) -> Void)!##((CMTime) -> Void)!##(CMTime) -> Void#>)
           /* let dur = CMTime(value: 1, timescale: 1000, flags: [], epoch: 0)
            let iso = Float(200)
           backCamera?.setExposureModeCustomWithDuration(dur, ISO: iso, completionHandler: {
                (CMTime) -> Void in
             //   backCamera.finish()
                
            })*/
            //backCamera.setExposureModeCustomWithDuration(dur, ISO: Float(200), completionHandler: nil)
            backCamera?.unlockForConfiguration()
        }catch let error2 as NSError{
            error = error2
        }
    
        var input: AVCaptureDeviceInput!
        do {
            input = try AVCaptureDeviceInput(device: backCamera)
        } catch let error1 as NSError {
            error = error1
            input = nil
        }
        let videoOutput = AVCaptureVideoDataOutput()
        //videoOutput.setSampleBufferDelegate(AVCaptureVideoDataOutputSampleBufferDelegate!, queue: <#T##dispatch_queue_t!#>)
       videoOutput.setSampleBufferDelegate(self, queue: dispatch_queue_create("sample buffer delegate", DISPATCH_QUEUE_SERIAL))
        
        if error == nil && captureSession!.canAddInput(input) {
            captureSession!.addInput(input)
            
            stillImageOutput = AVCaptureStillImageOutput()
            stillImageOutput!.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            if captureSession!.canAddOutput(stillImageOutput) {
                captureSession!.addOutput(stillImageOutput)
                
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer!.videoGravity = AVLayerVideoGravityResizeAspect
                previewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.Portrait
                previewView.layer.addSublayer(previewLayer!)
                
                captureSession!.addOutput(videoOutput)

                
                
                captureSession!.startRunning()
            }
        }
    }
    
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!)
    {
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let context = CIContext(options:nil)
        let cameraImage = CIImage(CVPixelBuffer: pixelBuffer!)
        let cgImg = context.createCGImage(cameraImage, fromRect: cameraImage.extent)
        dispatch_async(dispatch_get_main_queue())
            {
                self.getPixels(cgImg)
        }
        
   
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer!.frame = previewView.bounds
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    func getPixels(image: CGImageRef ){
        let width = CGImageGetWidth(image)
        let height = CGImageGetHeight(image)
        let pixelData = CGDataProviderCopyData(CGImageGetDataProvider(image))
        let pixels: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        var sum_red = 0
        var sum_green = 0
        var sum_blue = 0
        
        let mid_size = 20
        let mid_sqr = (mid_size + 1 ) * (mid_size + 1)
        
        let x_min = width/2 - mid_size / 2
        let x_max = width/2 + mid_size / 2
        
        let y_min = height/2 - mid_size / 2
        let y_max = height/2 + mid_size / 2

        for x in x_min ... x_max  {
            for y in y_min ... y_max {
                //Here is your raw pixels
                let offset = 4*((Int(width) * Int(y)) + Int(x))
                let red = pixels[offset]
                let green = pixels[offset+1]
                let blue = pixels[offset+2]
                //let alpha = pixels[offset+3]
                
                sum_red = sum_red + Int(red)
                sum_green = sum_green + Int(green)
                sum_blue = sum_blue + Int(blue)
                
  
            }
        }
        
        
        let avg_red = Double( sum_red/mid_sqr)
        let avg_green = Double( sum_green/mid_sqr)
        let avg_blue = Double(sum_blue/mid_sqr)
        
        let lum =  (0.21 * avg_red + 0.72*avg_green + 0.07*avg_blue ) / 255.0

        
        /*self.red.text = String( avg_red )
        self.green.text = String( avg_green )
        self.blue.text = String( avg_blue )*/
        //self.luminance.text = String( Int(100.0*lum) )
        self.prev_lum = self.prev_lum1
        self.prev_lum1 = lum
        //self.notify_sound(lum)
        
        //NSLog("%d %d %d " , avg_red, avg_green, avg_blue)
       // if (!self.lock!){
       //     self.update()
       // }
    
    
    }
    
    
    func notify_sound( amount: Double){
        var vol = 0.0
        
        if (amount > 0.05 && amount < 0.75){
            vol = (amount - 0.05)*0.15
            //AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))

            
        }else if (amount >= 0.75){
            
            vol = amount
            if (amount >= 0.95){
                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            }

        }
        
        mySound?.volume = Float(vol)
        self.playAudioWithVariablePith(2*Float(vol))


        
    }


    
    func playAudioWithVariablePith(pitch: Float){
        mySound?.rate = pitch
        mySound?.play()
    }

    
    func setupAudioPlayerWithFile(file: NSString, type: NSString) -> AVAudioPlayer? {
        
        let path = NSBundle.mainBundle().pathForResource(file as String, ofType: type as String)
        let url = NSURL.fileURLWithPath(path!)
        var audioPlayer: AVAudioPlayer?
        do {
            try audioPlayer = AVAudioPlayer(contentsOfURL: url)
        } catch {
            print("Player not available")
        }
        
        return audioPlayer
    }
    
    
     func updateStream() {

        if let videoConnection = stillImageOutput!.connectionWithMediaType(AVMediaTypeVideo) {
            videoConnection.videoOrientation = AVCaptureVideoOrientation.Portrait
            stillImageOutput?.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {(sampleBuffer, error) in
                if (sampleBuffer != nil) {
                    
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    let dataProvider = CGDataProviderCreateWithCFData(imageData)
                    let cgImageRef = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true, CGColorRenderingIntent.RenderingIntentDefault)
                    
                    let image = UIImage(CGImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.Right)
                    self.capturedImage.image = image
                    
                   // NSLog("width:%d", CGImageGetWidth(cgImageRef))
                    //NSLog("height:%d", CGImageGetWidth(cgImageRef))
                    
                    self.getPixels(cgImageRef!)
                    
                    
                    
                }
            })
        }
    }

    
    
    
}