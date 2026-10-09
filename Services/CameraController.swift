import AVFoundation
import SwiftUI
import UIKit

/// The live in-app camera (context.md §4): front or back, one photo at a time. No photo library, on purpose.
@Observable
final class CameraController: NSObject {
    enum Status { case starting, running, denied, unavailable }

    private(set) var status = Status.starting
    @ObservationIgnored let session = AVCaptureSession()
    @ObservationIgnored private let output = AVCapturePhotoOutput()
    @ObservationIgnored private var input: AVCaptureDeviceInput?
    @ObservationIgnored private var position = AVCaptureDevice.Position.back
    @ObservationIgnored private var completion: ((UIImage) -> Void)?
    /// The camera is set up and started off the main thread, as Apple recommends.
    @ObservationIgnored private let queue = DispatchQueue(label: "camera")

    /// Asks for camera access the first time, then starts the camera.
    func start() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: break
        case .notDetermined:
            guard await AVCaptureDevice.requestAccess(for: .video) else { return setStatus(.denied) }
        default:
            return setStatus(.denied)
        }
        queue.async { [self] in
            guard configure(position: position) else { return setStatus(.unavailable) }
            session.startRunning()
            setStatus(.running)
        }
    }

    func stop() {
        queue.async { [session] in session.stopRunning() }
    }

    func switchCamera() {
        queue.async { [self] in
            let next: AVCaptureDevice.Position = position == .back ? .front : .back
            if configure(position: next) { position = next }
        }
    }

    /// Takes a photo and hands it back on the main thread.
    func capture(_ completion: @escaping (UIImage) -> Void) {
        guard status == .running else { return }
        self.completion = completion
        queue.async { [self] in
            output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        }
    }

    /// Points the session at the front or back camera. Runs on `queue`.
    private func configure(position: AVCaptureDevice.Position) -> Bool {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let newInput = try? AVCaptureDeviceInput(device: device) else { return false }
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.sessionPreset = .photo
        if let input { session.removeInput(input) }
        guard session.canAddInput(newInput) else {
            if let input { session.addInput(input) }
            return false
        }
        session.addInput(newInput)
        input = newInput
        if !session.outputs.contains(output), session.canAddOutput(output) { session.addOutput(output) }
        return true
    }

    private func setStatus(_ status: Status) {
        DispatchQueue.main.async { self.status = status }
    }
}

extension CameraController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else { return }
        DispatchQueue.main.async {
            self.completion?(image)
            self.completion = nil
        }
    }
}

/// What the camera sees, filling its frame.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ view: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
