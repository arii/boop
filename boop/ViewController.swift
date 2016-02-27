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


class ViewController: UIViewController {

    @IBOutlet weak var hi: UIButton!
    var mySound: AVAudioPlayer?
    @IBOutlet weak var capturedImage: UIImageView!
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var capturePhoto: UIButton!
    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?


    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // initialize the sound
        if let sound = self.setupAudioPlayerWithFile("yourAudioFileName", type: "mp3") {
            self.mySound = sound
        }
        NSLog("Hello world! Loaded Program!")
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        captureSession = AVCaptureSession()
        captureSession!.sessionPreset = AVCaptureSessionPresetPhoto
        
        let backCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        var error: NSError?
        var input: AVCaptureDeviceInput!
        do {
            input = try AVCaptureDeviceInput(device: backCamera)
        } catch let error1 as NSError {
            error = error1
            input = nil
        }
        
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
                
                captureSession!.startRunning()
            }
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

    @IBAction func hi(sender: AnyObject) {
        
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        mySound?.play() // ignored if nil
    }

    @IBAction func didPressTakePhoto(sender: UIButton) {
        
        if let videoConnection = stillImageOutput!.connectionWithMediaType(AVMediaTypeVideo) {
            videoConnection.videoOrientation = AVCaptureVideoOrientation.Portrait
            stillImageOutput?.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {(sampleBuffer, error) in
                if (sampleBuffer != nil) {
                    
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    let dataProvider = CGDataProviderCreateWithCFData(imageData)
                    let cgImageRef = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true, CGColorRenderingIntent.RenderingIntentDefault)
                    
                    let image = UIImage(CGImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.Right)
                    self.capturedImage.image = image
                    
                    NSLog("width:%d", CGImageGetWidth(cgImageRef))
                    NSLog("height:%d", CGImageGetWidth(cgImageRef))
                    
                    self.getPixels(cgImageRef!)

                    
                    
                }
            })
        }
    }
    
    @IBAction func didPressTakeAnother(sender: AnyObject) {
        captureSession!.startRunning()
    }

    func getPixels(image: CGImageRef ){
        let width = CGImageGetWidth(image)
        let height = CGImageGetHeight(image)
       // let length = width * 4
        //let pixels = UnsafeMutablePointer<UInt8>.alloc(width*height*4)
        //let colorspace = CGColorSpaceCreateDeviceRGB()
        //let bytesPerRow = (4 * width);
        //let bitsPerComponent: UInt8?
        //let bitsPerComponent = 8

        let pixelData = CGDataProviderCopyData(CGImageGetDataProvider(image))
        let pixels: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        
      
       // let context = CGBitmapContextCreate(pixels, width, height, bitsPerComponent, bytesPerRow, colorspace, CGImageGetBitmapInfo(image).rawValue)
        //CGContextDrawImage(context, CGRectMake(0, 0, CGFloat(width), CGFloat(height)), image);
        
        for x in 0...10 {
            for y in 0...10 {
                //Here is your raw pixels
                let offset = 4*((Int(width) * Int(y)) + Int(x))
                let alpha = pixels[offset]
                let red = pixels[offset+1]
                let green = pixels[offset+2]
                let blue = pixels[offset+3]
                
                NSLog("%d, %d, %d, %d" , alpha, red, green, blue)
  
            }
        }    }
    
   

    
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
}