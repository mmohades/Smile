//
//  PresentationViewController.swift
//  Smile
//
//  Created by Maksim Ekin Eren on 4/7/18.
//  Copyright © 2018 Smile. All rights reserved.
//

import UIKit
import AVKit
import Vision
import Speech

class PresentationViewController: UIViewController,AVCaptureVideoDataOutputSampleBufferDelegate, SFSpeechRecognizerDelegate {

    @IBOutlet weak var textView: UITextView!
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    
    func startRecording() {
        
        if recognitionTask != nil {  //1
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()  //2
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            //print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()  //3
        
        guard let inputNode = try? audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }  //4
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        } //5
        
        recognitionRequest.shouldReportPartialResults = true  //6
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in  //7
            
            var isFinal = false  //8
            
            if result != nil {
                //print("Testing the voice thingy")
                //print(result?.bestTranscription.formattedString)
                self.textView.text = result?.bestTranscription.formattedString  //9
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {  //10
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)  //11
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()  //12
        
        do {
            try audioEngine.start()
        } catch {
            //print("audioEngine couldn't start because of an error.")
        }
        
        textView.text = "Say something, I'm listening!"
        
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            //microphoneButton.isEnabled = true
        } else {
            //microphoneButton.isEnabled = false
        }
    }

    //End button
    @IBOutlet weak var endButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    //Display end info
    @IBOutlet weak var endLabel: UILabel!
    @IBOutlet weak var happyLabel: UILabel!
    @IBOutlet weak var neutralLabel: UILabel!
    @IBOutlet weak var sadLabel: UILabel!
    
    //Background
    @IBOutlet weak var bg: UIImageView!
    @IBOutlet weak var bgred: UIImageView!
    @IBOutlet weak var bbgreen: UIImageView!
    @IBOutlet weak var backB: UIButton!
    //Turning logo
    @IBOutlet weak var smileLogo: UIImageView!
    
    //Variables needed
    var information:[String?] = []      //Holds the information to be used  //Currently not used
    var startTheSession:Bool = false    //Flag to see if the session started
    
    //Mood variables for COUNT
    var angryCount = 0.0;
    var sadCount = 0.0;
    var happyCount = 0.0;
    var neutralCount = 0.0;
    
    //Variables for Avarage
    var angryAv = 0.0;
    var sadAv = 0.0;
    var happyAv = 0.0;
    var neutralAv = 0.0;
    //Count avrg
    var angryAv2 = 0.0;
    var sadAv2 = 0.0;
    var happyAv2 = 0.0;
    var neutralAv2 = 0.0;
    //Count flags
    var countF = false
    
    //Overall avarages
    var mainAngry2 = 0.0
    var mainSad2 = 0.0
    var mainHappy2 = 0.0
    var mainneutral2 = 0.0
    
    //Count the session
    var count = 0;
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    
        self.textView.backgroundColor = UIColor.clear
        self.textView.textColor = UIColor.black
        self.textView.font = UIFont.boldSystemFont(ofSize: 16)
        //microphoneButton.isEnabled = false
        speechRecognizer.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            var isButtonEnabled = false
            
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                //print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                //print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                //print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation() {
                //self.microphoneButton.isEnabled = isButtonEnabled
            }
        }
        
        
        
 
        //Start the camera here
        let captureSession = AVCaptureSession()
        
        captureSession.sessionPreset = .photo
        
        //Assign the device
        guard let captureDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: .video, position: .front) else {return}
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {return}
        captureSession.addInput(input)
        captureSession.startRunning()
    
        //Capture session
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer!)
        previewLayer?.frame = view.frame
        
        //ML
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
    }
    
    //Machine Learning module
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        var sadFlag = false
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        
        guard let model = try? VNCoreMLModel(for: CNNEmotions().model) else {return}
        let request = VNCoreMLRequest(model: model) { (finishedReq, err) in
            
            guard let results = finishedReq.results as? [VNClassificationObservation] else {return}
            
            guard let firstObservation = results.first else { return }
            
            //print(firstObservation.identifier, firstObservation.confidence)
            
            DispatchQueue.main.async {
                //self.infoLabel.text = "\(firstObservation.identifier) \(firstObservation.confidence * 100)"
                
                //If the session started
                if(self.startTheSession == true)
                {
                 
                    print(firstObservation.identifier)
                    
                    self.previewLayer?.isHidden = false
      
                    
                    //Increase the count by one
                    self.count = self.count + 1
                    
                    if(self.count%3 != 0){
                        if(firstObservation.identifier.contains("Angry")){
                            self.angryAv2 = (self.angryAv2 + Double((firstObservation.confidence * 100))) / 2
                        }
                        else if(firstObservation.identifier.contains("Sad")){
                            self.sadAv2 = (self.sadAv2 + Double((firstObservation.confidence * 100))) / 2
                        }
                        else if(firstObservation.identifier.contains("Happy")){
                            self.happyAv2 = (self.happyAv2 + Double((firstObservation.confidence * 100))) / 2
                        }
                        else if(firstObservation.identifier.contains("Neutral")){
                            self.neutralAv2 = (self.neutralAv2 + Double((firstObservation.confidence * 100))) / 2
                        }
                    }
                    else{
                        //Overall avarages
                        self.mainAngry2 = (self.angryAv2 / (self.angryAv2 + self.sadAv2 + self.happyAv2 + self.neutralAv2)) * 100
                        self.mainSad2 = (self.sadAv2 / (self.angryAv2 + self.sadAv2 + self.happyAv2 + self.neutralAv2)) * 100
                        self.mainHappy2 = (self.happyAv2 / (self.angryAv2 + self.sadAv2 + self.happyAv2 + self.neutralAv2)) * 100
                        self.mainneutral2 = (self.neutralAv2 / (self.angryAv2 + self.sadAv2 + self.happyAv2 + self.neutralAv2)) * 100
                        
                        if(((self.angryAv2 + self.sadAv2) > (self.neutralAv2 + self.happyAv2)) && (self.angryAv2 > 50.00 || self.sadAv2 > 50.00)){
                            self.countF = false
                        }
    
                        else{
                            self.countF = true
                        }
                        
                        self.angryAv2 = 0.0;
                        self.sadAv2 = 0.0;
                        self.happyAv2 = 0.0;
                        self.neutralAv2 = 0.0;
                    }

                    //Every 5 check
                    if(self.count%3 == 0){
                    
                    self.bg.isHidden = true
                    self.bbgreen.isHidden = false
                    self.bgred.isHidden = false
                    
                    //Hide the camera
                    self.previewLayer?.isHidden = false
                    //If ANGRY
                    if(self.countF == false && (self.mainAngry2 > self.mainSad2)){
                        self.angryCount = self.angryCount + 1;
                        self.angryAv = (self.angryAv + Double((firstObservation.confidence * 100))) / 2
                        //print("Anger: " , self.angryCount, " " , self.angryAv)
                        sadFlag = true
                    }
                    //If SAD
                    else if(self.countF == false && (self.mainSad2 > self.mainAngry2)){
                        self.sadCount = self.sadCount + 1;
                        self.sadAv = (self.sadAv + Double((firstObservation.confidence * 100))) / 2
                        //print("Sad: " , self.sadCount, " " , self.sadAv)
                        sadFlag = true
                    }
                    //If Neutral
                    else if(self.countF == true && (self.mainneutral2 > self.mainHappy2)){
                        self.neutralCount = self.neutralCount + 1;
                        self.neutralAv = (self.neutralAv + Double((firstObservation.confidence * 100))) / 2
                        //print("Neutral: " , self.neutralCount, " " , self.neutralAv)
                        sadFlag = false
                    }
                    //If Happy
                    else if(self.countF == true && (self.mainHappy2 > self.mainneutral2)){
                        self.happyCount = self.happyCount + 1;
                        self.happyAv = (self.happyAv + Double((firstObservation.confidence * 100))) / 2
                        //print("Happy: " , self.happyCount, " " , self.happyAv)
                        sadFlag = false
                    }
                    
                    //If sadness
                    if(sadFlag){
                        UIView.animate(withDuration: 0.3, animations: {
                            self.bgred.alpha = 1
                            self.bbgreen.alpha = 0
                            self.bg.alpha = 0
                            self.smileLogo.transform = self.smileLogo.transform.rotated(by: CGFloat.init(M_PI_2))
                        }) { (finished) in
                            
                        }
                    }
                    else if(sadFlag == false){
                        
                        UIView.animate(withDuration: 0.3, animations: {
                            self.bbgreen.alpha = 1
                            self.bgred.alpha = 0
                            self.bg.alpha = 0
                            self.smileLogo.transform = self.smileLogo.transform.rotated(by: CGFloat.init(-M_PI_2))
                        }) { (finished) in
                            
                        }
                    }
                }
                }
                else{
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               c2self.previewLayer?.isHidden = true
                }
            }
        }
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
    
    //This creates an allert
    func createAlert(titleText: String, messageText: String){
        let alert = UIAlertController(title: titleText, message: messageText, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    //Memmory function
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //Start Button Pressed
    @IBAction func buttonA(_ sender: UIButton) {
        if(endButton.isHidden){
            
             startRecording() //
            
            startButton.isHidden = true
           
            startTheSession = true
            endButton.alpha = 0;
             endButton.isHidden = false
            backB.isHidden = true
            endLabel.isHidden = true
            happyLabel.isHidden = true
            sadLabel.isHidden = true
            neutralLabel.isHidden = true
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            self.endButton.alpha = 1
            
        }) { (finished) in

        }
    }
    
    
    
    //End button pressed
    @IBAction func endButtonAction(_ sender: UIButton) {
        
        //
        audioEngine.stop()
        recognitionRequest?.endAudio()
        
        backB.alpha = 0
        startButton.alpha = 0
    
        UIView.animate(withDuration: 0.3, animations: {
            self.backB.alpha = 1
            self.startButton.alpha = 1
            
        }) { (finished) in
            
        }

        backB.isHidden = false
        startButton.isHidden = false
        endButton.isHidden = true
        startTheSession = false
        endLabel.isHidden = false
        happyLabel.isHidden = false
        sadLabel.isHidden = false
        neutralLabel.isHidden = false
        
        //Overall avarages
        let mainAngry = (angryAv / (angryAv + sadAv + happyAv + neutralAv)) * 100
        let mainSad = (sadAv / (angryAv + sadAv + happyAv + neutralAv)) * 100
        let mainHappy = (happyAv / (angryAv + sadAv + happyAv + neutralAv)) * 100
        let mainneutral = (neutralAv / (angryAv + sadAv + happyAv + neutralAv)) * 100

        //Information variable
        //var all = ("Angry Count: \(String(describing: angryCount))"/* , angryCount*/)
        //var angerL = ("Anger: \(String(describing: mainAngry))"/* , mainAngry*/)
        //Label
        endLabel.text = ("Anger: %\(String(format: "%.2f", mainAngry/*describing: mainAngry*/))"/* , mainAngry*/)
        happyLabel.text = ("Happiness: %\(String(format: "%.2f", mainHappy/*describing: mainHappy*/))"/* , mainHappy*/)
        sadLabel.text = ("Sadness: %\(String(format: "%.2f", mainSad/*describing: mainSad*/))"/* , mainSad*/)
        neutralLabel.text = ("Neutral: %\(String(format: "%.2f", mainneutral/*describing: mainneutral*/))"/* , mainNeutral*/)
        
        previewLayer?.isHidden = true
        
        if((mainSad + mainAngry) > (mainHappy + mainneutral)){
            UIView.animate(withDuration: 0.3, animations: {
                
               
                
                self.bgred.alpha = 1
                self.bbgreen.alpha = 0
                self.bg.alpha = 0
                
            }) { (finished) in
                self.bbgreen.isHidden = true
                self.bgred.isHidden = false
                self.bg.isHidden = true
            }
        }
        else{
            UIView.animate(withDuration: 0.3, animations: {
                self.bgred.alpha = 0
                self.bbgreen.alpha = 1
                self.bg.alpha = 0
            }) { (finished) in
                self.bbgreen.isHidden = false
                self.bgred.isHidden = true
                self.bg.isHidden = true
            }
        }
        
        //Reset the counts
        //Mood variables for COUNT
        angryCount = 0.0;
        sadCount = 0.0;
        happyCount = 0.0;
        neutralCount = 0.0;
        
        //Variables for Avarage
        angryAv = 0.0;
        sadAv = 0.0;
        happyAv = 0.0;
        neutralAv = 0.0;
    }
}
