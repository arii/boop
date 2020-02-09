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

// two finger scrub to toggle vibrate enable on or off

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate{
    
    @IBOutlet weak var vibrate_label: UILabel!
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var do_vibrate: UISwitch!
    @IBOutlet weak var luminance: UILabel!
    
    var mySound: AVAudioPlayer?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var updater: Timer?
    
    var lastBuzz: Double?

    let tap = UITapGestureRecognizer()
    var lock : Bool?
    
    let AD = UIApplication.shared.delegate as! AppDelegate


  /*  - (void)viewDidLoad
    {
        [super viewDidLoad];
        NSLog(@"view did load");

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    }

    - (void)appDidBecomeActive:(NSNotification *)notification {
        NSLog(@"did become active notification");
    }

    - (void)appWillEnterForeground:(NSNotification *)notification {
        NSLog(@"will enter foreground notification");
    }

    - (void)viewWillAppear:(BOOL)animated {
        [super viewWillAppear:animated];
        NSLog(@"view will appear");
    }

    - (void)viewDidAppear:(BOOL)animated {
        [super viewDidAppear:animated];
        NSLog(@"view did appear");
    }*/
    

    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NSLog("View will appear")
        startLightDetection()
        
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        
         NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
         NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
               
    }
    
    @objc func willResignActive(){
        NSLog("View: will resign active")
    }
    @objc func willEnterForeground(){
        NSLog("View: will enter foreground")
    }
    
    @objc func didBecomeActive(){
        NSLog("View: did become active")
    }
    
    @objc func applicationWillTerminate(){
           NSLog("View: app will terminate")
       }
    @objc func didEnterBackground(){
           NSLog("View: did enter background")
       }
        
    func startLightDetection(){
        AD.setupServices()
        setupCameraPreviewLayer()
        
        self.lastBuzz =   NSDate().timeIntervalSince1970
        self.lock = false
        if (AD.loaded!){
            self.updater = Timer.scheduledTimer( timeInterval: 0.07, target: self, selector: #selector(UIMenuController.update), userInfo: nil, repeats: true)
        }
        
    }
    

   
    func setupCameraPreviewLayer(){
        if (!AD.loaded!){
            self.vibrate_label.text="camera error"
        }
        
        if (AD.loaded!){
        previewLayer = AVCaptureVideoPreviewLayer(session: AD.captureSession!)
        previewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        previewView.layer.addSublayer(previewLayer!)
        }else{
            NSLog("did not load preview layer due to loading error")
        }
        if (AD.loaded! && previewLayer != nil){
            previewLayer!.frame = previewView.bounds
        }
        NSLog("View did appear")
    }
    
    
    /* Light detection secret sauce */
    
    @objc func update() {
        if (!AD.loaded!){
            NSLog("Light detection services not enabled") //XXX should comment
            return
        }
        
        if (self.lock!){
            NSLog("locked")
        } else{
            
            self.lock = true
            
            var amount = (AD.prev_lum! + AD.prev_lum1!)/2
            let iso = Double((AD.backCamera?.iso)!)
            let exp = Double((AD.backCamera?.exposureDuration.seconds)!)
            
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
            let  note = UInt8(20.0*amount + lo)
            
            let vol = UInt8(amount*100 + 20)
            let sleep_time = 1000000.0*(0.4-0.3*amount)
            let vibe_sleep_time = (1.7-1.3*amount)
            
            
            if (amount > 0.01){
                self.play(note: note,velocity:vol )
                let currentDateTime = NSDate().timeIntervalSince1970
                if (self.do_vibrate.isOn && ((currentDateTime - self.lastBuzz!) > vibe_sleep_time)){
                    
                    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                    self.lastBuzz = currentDateTime
                }
                if (amount > 0.9){
                    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                }
                
            }
            
            usleep (UInt32(sleep_time))
            if (amount > 0.01){
                AD.sampler!.stopNote(note, onChannel: 1)
            }
            self.lock = false
        }
    }
    
    
    
    func play(note:UInt8, velocity:UInt8){
        AD.sampler!.startNote(note, withVelocity: velocity, onChannel: 1)
    }
    
    
    
    /*
     Accessiblity functions below
     */
    override func accessibilityPerformMagicTap() -> Bool {
        
        exit(0)
        
    }
    override func accessibilityPerformEscape() -> Bool {
        if (AD.loaded!){
            
            if (self.do_vibrate.isOn){
                self.vibrate_label.text = "Vibrate mode is off"
                self.do_vibrate.setOn(false, animated: true)
            }else{
                self.do_vibrate.setOn(true, animated: true)
                
                self.vibrate_label.text = "Vibrate mode is on"
                
            }
        }
        return true
    }
    @IBAction func vibrate_toggle(_ sender: Any) {
        if (AD.loaded!){
            if (self.do_vibrate.isOn){
                self.vibrate_label.text = "Vibrate mode is on"
                // self.vibrate_enable.setTitle("Vibrate On",forState: UIControlState.Normal)
            }else{
                self.vibrate_label.text = "Vibrate mode is off"
            }
        }
    }
    
    
}

