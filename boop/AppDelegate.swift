//
//  AppDelegate.swift
//  boop
//
//  Created by ariel anders on 2/26/16.
//  Copyright © 2016 ArielAnders. All rights reserved.
//

import UIKit
import AudioToolbox
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate,AVCaptureVideoDataOutputSampleBufferDelegate {

    var window: UIWindow?
    let special_test = "Hello World!"
    
    var loaded: Bool?
    
    
    //audio variables
    var audioEngine : AVAudioEngine?
    var sampler:AVAudioUnitSampler?
    var mixer:AVAudioMixerNode?
    
    // camera variables
    var captureSession: AVCaptureSession?
    var input_av_capture: AVCaptureDeviceInput?
    var videoOutput : AVCaptureVideoDataOutput?
    var backCamera: AVCaptureDevice?
    
    //pixel callbacks
    var pixelBuffer: CVPixelBuffer?
    var context: CIContext?
    var cameraImage: CIImage?
    var cgImg: CGImage?
    var pixelData:CFData?
    var pixels: UnsafePointer<UInt8>?
    
    //lightdetection computation
    var prev_lum: Double?
    var prev_lum1: Double?
    var processImgLock : Bool?
    var lock : Bool?
    
    
  
    
    

    private func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        NSLog("launched")
        
        return true
    }
    
    
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        
        NSLog("will resign active -- temporary interup")
        
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        NSLog("did enter background")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        NSLog("will enter forground")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        NSLog("did become active")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        NSLog("wil terminate")
    }
    
    

    
    func setupAudio() -> Bool {
        var setup : Bool?
        setup = true
        self.audioEngine = AVAudioEngine()
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        
        self.mixer = self.audioEngine?.mainMixerNode
        self.sampler = AVAudioUnitSampler()
        self.audioEngine?.attach(self.sampler!)
        self.audioEngine?.connect(self.sampler!, to: self.mixer!, format: self.sampler!.outputFormat(forBus: 0))
        do{
            try   self.audioEngine?.start()
        }catch let error as NSError{
            setup = false
            NSLog(error.description)
        }
        return setup!
    }
    
    func setupCamera() -> Bool {
           
           var setup : Bool?
           setup = false
           
           self.captureSession = AVCaptureSession()
           self.backCamera = getDevice(position: .back)
           
           if self.backCamera == nil {
               NSLog("Cant even discover a camera!")
               return setup!
           }
           
           // set up back camera as input device
           do {
               self.input_av_capture = try AVCaptureDeviceInput(device: self.backCamera!)
           } catch let error as NSError {
               self.input_av_capture = nil
               NSLog("Camera error -- permissions")
               NSLog(error.description)
               return setup!
           }
           
           self.videoOutput = AVCaptureVideoDataOutput()
           self.videoOutput!.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer delegate"))
           
           if self.captureSession!.canAddInput(self.input_av_capture!) {
               self.captureSession!.addInput(self.input_av_capture!)
           
               if self.captureSession!.canAddOutput(self.videoOutput!) {
                   self.captureSession!.addOutput(self.videoOutput!)
                   self.captureSession!.startRunning()
                   setup = true
               }else{
                   NSLog("cannot capture video output")
               }
           }else{
               NSLog("cannot capture video input")
               }
           return setup!
       }
    
    //Get the device (Front or Back)
       func getDevice(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
           // as default back device is first option
           // possibly want to be more specific here
           let devices: NSArray = AVCaptureDevice.devices() as NSArray;
           for de in devices {
               let deviceConverted = de as! AVCaptureDevice
               if(deviceConverted.position == position){
                   return deviceConverted
               }
           }
           return nil
       }
    
    // camera image callback and pixel computation
    func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)
    {
        // not sure how this attaches tbh
        pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        context = CIContext(options:nil)
        cameraImage = CIImage(cvPixelBuffer: pixelBuffer!)
        cgImg = context!.createCGImage(cameraImage!, from: cameraImage!.extent)
        DispatchQueue.main.async {
            self.getPixels()
        }
    }
    
    func getPixels(){
        
        if (!self.loaded!){
            // ideally we would not get here, since the camera calls it
            // but in case there's a race condition
            NSLog("GetPixels: Light detection services not enabled") //XXX should comment
            return
        }
        
        if (!processImgLock!){
            processImgLock = true
            
            let width = self.cgImg!.width
            let height = self.cgImg!.height
            
            pixelData = self.cgImg!.dataProvider?.data
            pixels = CFDataGetBytePtr(pixelData)
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
                    let red = pixels![offset]
                    let green = pixels![offset+1]
                    let blue = pixels![offset+2]
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

