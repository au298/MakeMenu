import UIKit
import Photos
import AVFoundation

protocol MachineLearningDelegate: AnyObject {
    func machineLearning(image: Data) -> [String]
}

final class CameraViewController: UIViewController {
    
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var shutterButton: UIButton!
    
    private let captureSession = AVCaptureSession()
    private var captureVideoLayer: AVCaptureVideoPreviewLayer!
    private let photoOutput = AVCapturePhotoOutput()
    
    private var currentDevice: AVCaptureDevice?
    private var videoDeviceInput: AVCaptureDeviceInput?
    
    private var settingsForMonitoring = AVCapturePhotoSettings()
    
    private let sessionQueue = DispatchQueue(label: "session_queue")
    
    private let machineLearning: MachineLearningDelegate = MachineLearningDummy()
    
    private var setupResult: SessionSetupResult = .success
    enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    private var compressedData: Data?
    
    // recognizedObjectを配列に変更
    private var recognizedObject: [String] = []
    
    // 新しいフラグを追加
    private var isTransitioning = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.checkPermission()
        
        self.sessionQueue.async {
            self.configureSession()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.sessionQueue.async {
            switch self.setupResult {
            case .success:
                self.captureSession.startRunning()
            case .notAuthorized:
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "AVFoundation-Camera-App",
                                                            message: "AVFoundation-Camera-App doesn't have permission to use the camera.",
                                                            preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: "OK",
                                                            style: .cancel,
                                                            handler: nil))
                    
                    alertController.addAction(UIAlertAction(title: "Settings",
                                                            style: .default,
                                                            handler: { _ in
                                                                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                                                          options: [:],
                                                                                          completionHandler: nil)
                    }))
                    self.present(alertController, animated: true, completion: nil)
                }
            case .configurationFailed:
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "AVFoundation-Camera-App",
                                                            message: "AVFoundation-Camera-App doesn't have permission to use the photo album",
                                                            preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: "OK",
                                                            style: .cancel,
                                                            handler: nil))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    
    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            self.sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })
        default:
            self.setupResult = .notAuthorized
            break
        }
        
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            break
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ photoAuthStatus in
                if photoAuthStatus == PHAuthorizationStatus.authorized {
                }
            })
        default:
            break
        }
    }
    
    private func configureSession() {
        guard setupResult == .success else {
            DispatchQueue.main.async {
                self.shutterButton.isEnabled = false
            }
            return
        }
        
        self.captureSession.beginConfiguration()
        do {
            var defaultVideoDevice: AVCaptureDevice?
            if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                defaultVideoDevice = backCameraDevice
            }
            
            guard let videoDevice = defaultVideoDevice else {
                self.setupResult = .configurationFailed
                self.captureSession.commitConfiguration()
                return
            }
            
            self.currentDevice = videoDevice
            
            let input = try AVCaptureDeviceInput(device: videoDevice)
            if self.captureSession.canAddInput(input) {
                self.captureSession.addInput(input)
                self.videoDeviceInput = input
                
                if self.captureSession.canAddOutput(self.photoOutput) {
                    self.captureSession.addOutput(self.photoOutput)
                    
                    self.captureVideoLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                    self.captureVideoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                    
                    DispatchQueue.main.async {
                        self.captureVideoLayer.frame = self.previewImageView.bounds
                        self.previewImageView.contentMode = .scaleAspectFill
                        self.previewImageView.layer.addSublayer(self.captureVideoLayer)
                    }
                }
                
                self.captureSession.sessionPreset = AVCaptureSession.Preset.photo
            }
        } catch {
            print("Error configure capture session: \(error)")
            self.setupResult = .configurationFailed
            self.captureSession.commitConfiguration()
            return
        }
        self.captureSession.commitConfiguration()
    }
    
    @IBAction func shutterButtonTUP(_ sender: Any) {
        self.settingsForMonitoring = AVCapturePhotoSettings()
        self.settingsForMonitoring.embeddedThumbnailPhotoFormat = [AVVideoCodecKey: AVVideoCodecType.jpeg]
        self.settingsForMonitoring.isHighResolutionPhotoEnabled = false
        self.photoOutput.capturePhoto(with: self.settingsForMonitoring, delegate: self)
    }
    
    private func showResultViewController() {
        // 画面遷移中でない場合のみ実行
        if !isTransitioning {
            isTransitioning = true
            performSegue(withIdentifier: "showResultViewController", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showResultViewController",
           let destinationVC = segue.destination as? ResultViewController {
            // recognizedObjectをそのまま渡す
            destinationVC.recognizedObject = self.recognizedObject
        }
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        guard error == nil else {
            print("Error broken photo data: \(error!)")
            return
        }
        
        guard let photoData = photo.fileDataRepresentation() else {
            print("No photo data to write.")
            return
        }
        
        self.compressedData = photoData
        
        // 画像認識を開始
        recognizeImage(imageData: photoData)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        
        guard error == nil else {
            self.shutterButton.isEnabled = true
            print("Error capture photo: \(error!)")
            return
        }
        
        guard let compressedData = self.compressedData else {
            self.shutterButton.isEnabled = true
            print("The expected photo data isn't available.")
            return
        }
        
    }
    
    func recognizeImage(imageData: Data) {
        let labels: [String] = machineLearning.machineLearning(image: imageData)
        
        // 認識されたラベルを配列に追加
        recognizedObject.append(contentsOf: labels)
    }
}
