//
//  PlantScannerView.swift
//  Botanical
//
//  Created by Rishi Suryavanshi on 4/4/25.
//
import SwiftUI
import UIKit
import AVFoundation
import Vision
import CoreML

struct PlantScannerView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var classificationResult: String = "Take a photo to identify your plant"
    @State private var confidence: Float = 0.0
    @State private var capturedImage: UIImage?
    @State private var showingResult = false
    @State private var takePhoto = false // State variable for capture button
    @State private var showPlantProfile = false // State variable for showing plant profile
    
    var body: some View {
        ZStack {
            // Camera view takes up full screen
            CameraRepresentable(
                classificationResult: $classificationResult,
                confidence: $confidence,
                capturedImage: $capturedImage,
                showingResult: $showingResult,
                takePhoto: $takePhoto
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Header with back button
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                    }
                    
                    Spacer()
                }
                
                Spacer()
                
                // Bottom controls and results
                VStack(spacing: 20) {
                    if showingResult {
                        // Results view
                        VStack(spacing: 10) {
                            Text("Plant Identified")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(classificationResult)
                                .font(.largeTitle)
                                .bold()
                                .foregroundColor(.white)
                            
                            if confidence > 0 {
                                Text("Confidence: \(Int(confidence * 100))%")
                                    .foregroundColor(.white)
                            }
                            
                            HStack(spacing: 20) {
                                Button(action: {
                                    // Reset to take a new photo
                                    showingResult = false
                                }) {
                                    Text("Try Again")
                                        .font(.system(size: 16))
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 20)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(25)
                                        .foregroundColor(.white)
                                }
                                
                                Button(action: {
                                    // Show plant profile view
                                    showPlantProfile = true
                                }) {
                                    Text("View Profile")
                                        .font(.system(size: 16))
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 30)
                                        .background(Color.white)
                                        .cornerRadius(25)
                                        .foregroundColor(.black)
                                }
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(16)
                        .padding(.bottom, 30)
                    } else {
                        // Capture button
                        Button(action: {
                            takePhoto = true // Set this to true when button is tapped
                        }) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Circle()
                                        .stroke(Color.black, lineWidth: 3)
                                        .padding(3)
                                )
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showPlantProfile) {
            PlantProfileView(
                plantName: classificationResult,
                confidence: confidence,
                plantImage: capturedImage
            )
        }
    }
}

// UIViewControllerRepresentable to handle camera and ML classification
struct CameraRepresentable: UIViewControllerRepresentable {
    @Binding var classificationResult: String
    @Binding var confidence: Float
    @Binding var capturedImage: UIImage?
    @Binding var showingResult: Bool
    @Binding var takePhoto: Bool
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // Check if takePhoto flag is set and capture photo accordingly
        if takePhoto {
            uiViewController.capturePhotoFromSwiftUI()
            DispatchQueue.main.async {
                self.takePhoto = false // Reset the flag
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CameraViewControllerDelegate {
        var parent: CameraRepresentable
        
        init(_ parent: CameraRepresentable) {
            self.parent = parent
        }
        
        func didCapture(image: UIImage?, classificationResult: String, confidence: Float) {
            DispatchQueue.main.async {
                self.parent.capturedImage = image
                self.parent.classificationResult = classificationResult
                self.parent.confidence = confidence
                self.parent.showingResult = true
            }
        }
    }
}

// Protocol for camera controller
protocol CameraViewControllerDelegate: AnyObject {
    func didCapture(image: UIImage?, classificationResult: String, confidence: Float)
}

// UIViewController for camera handling and plant classification
class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    weak var delegate: CameraViewControllerDelegate?
    
    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let photoOutput = AVCapturePhotoOutput()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }
    
    private func setupCamera() {
        captureSession.sessionPreset = .photo
        
        guard let backCamera = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) else {
            print("Unable to access back camera")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.videoGravity = .resizeAspectFill
            
            guard let previewLayer = previewLayer else { return }
            view.layer.addSublayer(previewLayer)
            previewLayer.frame = view.bounds
        } catch {
            print("Error setting up camera: \(error.localizedDescription)")
        }
    }
    
    private func startSession() {
        DispatchQueue.global(qos: .background).async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }
    
    private func stopSession() {
        DispatchQueue.global(qos: .background).async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
    
    // This function will be called from SwiftUI
    func capturePhotoFromSwiftUI() {
        capturePhoto()
    }
    
    @objc func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("Error capturing photo")
            return
        }
        
        // Process image with CoreML
        classifyImage(image) { classificationResult, confidence in
            DispatchQueue.main.async {
                self.delegate?.didCapture(
                    image: image,
                    classificationResult: classificationResult,
                    confidence: confidence
                )
            }
        }
    }
    
    private func classifyImage(_ image: UIImage, completion: @escaping (String, Float) -> Void) {
        guard let ciImage = CIImage(image: image) else {
            completion("Could not process image", 0)
            return
        }
        
        // Try to load the ML model
        do {
            // Create a Vision-compatible version of your model
            guard let modelURL = Bundle.main.url(forResource: "FlowerClassifier", withExtension: "mlmodelc") else {
                print("Failed to find the compiled model")
                completion("Model not found", 0)
                return
            }
            
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            
            let handler = VNImageRequestHandler(ciImage: ciImage)
            let request = try VNCoreMLRequest(model: visionModel) { request, error in
                guard let results = request.results as? [VNClassificationObservation],
                      let topResult = results.first else {
                    completion("Could not classify", 0)
                    return
                }
                
                completion(topResult.identifier, topResult.confidence)
            }
            
            try handler.perform([request])
        } catch {
            print("Failed to classify image: \(error.localizedDescription)")
            completion("Classification error", 0)
        }
    }
}

#Preview {
    PlantScannerView()
}
