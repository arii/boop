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

    @IBOutlet weak var vibrate_enable: UIButton!
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
    var setup: Bool?
    
    
    var backCamera: AVCaptureDevice?
    
    var mute_mode : Bool?
    
    var lastBuzz: Double?

    
    var prev_lum: Double?
    var prev_lum1: Double?
    
    var sampler:AVAudioUnitSampler?
    var mixer:AVAudioMixerNode?
    
    let tap = UITapGestureRecognizer()

    var lock : Bool?
    var processImgLock : Bool?
    
    @IBOutlet weak var luminance: UILabel!
    override func viewDidLoad() {
       // UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,"Started Boop Ari")
       // UIAccessibilityPostNotification(<#T##notification: UIAccessibilityNotifications##UIAccessibilityNotifications#>, <#T##argument: AnyObject?##AnyObject?#>)
        super.viewDidLoad()

        let swipe: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "GotoProfile")
        swipe.direction = UISwipeGestureRecognizerDirection.Down
        self.view.addGestureRecognizer(swipe)
        

        
        self.prev_lum1 = 0.0
        self.prev_lum = 0.0
        self.mute_mode = false
        

        self.tone = AVAudioEngine()
        NSLog("Hello world! Loaded Program!")
        self.audioEngine = AVAudioEngine()
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        self.updater = NSTimer.scheduledTimerWithTimeInterval( 0.01, target: self, selector: "update", userInfo: nil, repeats: true)
        
       
        self.lastBuzz =   NSDate().timeIntervalSince1970
        self.lock = false
        self.processImgLock = false
        
        mixer = self.audioEngine?.mainMixerNode
        
        sampler = AVAudioUnitSampler()
        
        self.audioEngine?.attachNode(sampler!)
        self.audioEngine?.connect(sampler!, to: mixer!, format: sampler!.outputFormatForBus(0))
        var error: NSError?

        do{
            try   self.audioEngine?.start()
        }catch let error2 as NSError{
            error = error2
            NSLog(error!.description)
        }
    }


    func play(note:UInt8, velocity:UInt8){
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
            


        var amount = (self.prev_lum! + self.prev_lum1!)/2
        let iso = Double((self.backCamera?.ISO)!)
        let exp = Double((self.backCamera?.exposureDuration.seconds)!)
        
        var scalelum =  (log10( amount / (iso*exp)) + 2.4)/2.8
            if (scalelum <= 0.0){
                scalelum = 0.0
            }
            if (scalelum >= 1.0 ){
                scalelum = 1.0
            }
            amount = scalelum
            
       //XXX NSLog("iso:%f, exp:%f, scalelum:%f", (self.backCamera?.ISO)!, (self.backCamera?.exposureDuration.seconds)!, scalelum)
            self.luminance.text = String( Int(100.0*amount) )

                 let lo = 73.0
            _ = 80
            
          let  note = UInt8(20.0*amount + lo)
            
        //let note = UInt8(100*amount)
        let vol = UInt8(amount*100 + 20)
            let sleep_time = 1000000.0*(0.4-0.3*amount)
            let vibe_sleep_time = (1.7-1.3*amount)


            if (amount > 0.01){
                self.play(note,velocity:vol )
                let currentDateTime = NSDate().timeIntervalSince1970
               if (self.mute_mode! && ((currentDateTime - self.lastBuzz!) > vibe_sleep_time)){

                    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                    self.lastBuzz = currentDateTime
                }
                if (amount > 0.9){
                    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                }
                
            }
        usleep (UInt32(sleep_time))
        sampler!.stopNote(note, onChannel: 0)
        self.lock = false
        }
    }
    
  override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setup = false
        
        captureSession = AVCaptureSession()
        captureSession!.sessionPreset = AVCaptureSessionPreset352x288
        var error: NSError?

        backCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    
        var input: AVCaptureDeviceInput!
        do {
            input = try AVCaptureDeviceInput(device: backCamera)
        } catch let error1 as NSError {
            error = error1
            input = nil
        }
        let videoOutput = AVCaptureVideoDataOutput()
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
                setup = true
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
        if (setup!){
            previewLayer!.frame = previewView.bounds
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    func GotoProfile(){
       // self.performSegueWithIdentifier("Profilesegue", sender: nil)
        self.toggle()
    }
    
    override func accessibilityPerformEscape() -> Bool {
        self.toggle()
        return true
        
    }

    
    @IBAction func toggle_mute(sender: AnyObject) {
        if (self.mute_mode!){
            self.vibrate_enable.setTitle("Enable Vibrate",forState: UIControlState.Normal)
        }else{
            self.vibrate_enable.setTitle("Disable Vibrate", forState:UIControlState.Normal)
        }
        self.mute_mode = !(self.mute_mode!)
    }
    
    func toggle(){
        if (self.mute_mode!){
            self.vibrate_enable.setTitle("Enable Vibrate",forState: UIControlState.Normal)
        }else{
            self.vibrate_enable.setTitle("Disable Vibrate", forState:UIControlState.Normal)
        }
        self.mute_mode = !(self.mute_mode!)
    }
    
    
    func getPixels(image: CGImageRef ){
        if (!processImgLock! && !lock!){
            processImgLock = true
            
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
                sum_red = sum_red + Int(red)
                sum_green = sum_green + Int(green)
                sum_blue = sum_blue + Int(blue)
            }
        }
        
        
        let avg_red = Double( sum_red/mid_sqr)
        let avg_green = Double( sum_green/mid_sqr)
        let avg_blue = Double(sum_blue/mid_sqr)
        
        let lum =  (0.21 * avg_red + 0.72*avg_green + 0.07*avg_blue ) / 255.0
        self.prev_lum = self.prev_lum1
        self.prev_lum1 = lum
        processImgLock = false
            
        }
    }

}
 