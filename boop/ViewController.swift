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
    /*@IBOutlet weak var red: UILabel!

    @IBOutlet weak var green: UILabel!

    @IBOutlet weak var blue: UILabel!*/
    
    var prev_lum: Double?
    
    
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

        if let sound3 = self.setupAudioPlayerWithFile("blip_2_3", type: "mp3") {
            self.mySound3 = sound3
        }

        if let sound4 = self.setupAudioPlayerWithFile("blip_2_4", type: "mp3") {
            self.mySound4 = sound4
        }

        if let sound5 = self.setupAudioPlayerWithFile("blip_2_5", type: "mp3") {
            self.mySound5 = sound5
        }

        
        
        self.prev_lum = 0.0
        self.tone = AVAudioEngine()
        NSLog("Hello world! Loaded Program!")
        self.audioEngine = AVAudioEngine()
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        self.updater = NSTimer.scheduledTimerWithTimeInterval( 0.01, target: self, selector: "update", userInfo: nil, repeats: true)

    }

    override func accessibilityPerformMagicTap() -> Bool {
        exit(0)
    }
    
    
    func update() {
       // AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))

        let amount = self.prev_lum!
        if (amount >= 0.95){
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
        
        if (mySound!.playing || mySound1!.playing ){
            return
        }
        
        
        var vol = 0.0
        
        var sound = self.mySound
        
        if (amount > 0.05 && amount < 0.75){
            vol = (amount - 0.05)*0.05
            //AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            
        }else if (amount >= 0.75){
            vol = amount
            //sound = self.mySound1
            if (amount >= 0.8){
                sound = self.mySound1

            }
            
            if (amount >= 0.95){
                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                sound = self.mySound2

            }
            
        }
        

        sound?.volume = Float(vol)
        sound?.rate = Float(2*vol)
        sound?.play()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        captureSession = AVCaptureSession()
        captureSession!.sessionPreset = AVCaptureSessionPreset352x288 //AVCaptureSessionPresetPhoto
        var error: NSError?

        let backCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        do {
            try backCamera.lockForConfiguration()
            backCamera.focusMode = AVCaptureFocusMode.Locked
            //backCamera.setExposureModeCustomWithDuration(CMTimeMakeWithSeconds(10, 1000*1000*1000), ISO: Float(1), completionHandler: nil)
            backCamera.unlockForConfiguration()
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
        
        let mid_size = 10
        let mid_sqr = (mid_size + 1 ) * (mid_size + 1)
        
        for x in width/2...width/2 + mid_size{
            for y in height/2...height/2 + mid_size {
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
        self.luminance.text = String( Int(100.0*lum) )
        self.prev_lum = lum
        
        //self.notify_sound(lum)
        
        //NSLog("%d %d %d " , avg_red, avg_green, avg_blue)
    
    
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