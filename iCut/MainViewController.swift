//
//  MainViewController.swift
//  iCut
//
//  Created by Nail Sharipov on 24.03.2022.
//

import UIKit
import AVFoundation

final class MainViewController: UIViewController {

    private let photoView = UIView()
    private let resultView = UIImageView()
    private let shotButton: UIButton = {
        let button = UIButton()
        button.setTitle("Shot", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = UIColor.darkGray
        return button
    }()
    private var cameraLayer: CALayer?

    private var captureProcessor: CaptureProcessor?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .orange
        self.view.addSubview(photoView)
        self.view.addSubview(resultView)
        self.view.addSubview(shotButton)
        
        AVCaptureDevice.requestAccess(for: .video) { success in
            if success {
                DispatchQueue.main.async { [weak self] in
                    self?.setupCaptureProcessor()
                }
            }
        }
        
        shotButton.addTarget(self, action: #selector(takePhoto), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        captureProcessor?.start()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        captureProcessor?.stop()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        photoView.frame = CGRect(
            x: 0,
            y: 0,
            width: view.bounds.width,
            height: 0.5 * view.bounds.height
        )
        
        resultView.frame = CGRect(
            x: 0,
            y: photoView.frame.maxY,
            width: view.bounds.width,
            height: view.bounds.height - photoView.frame.height
        )

        shotButton.frame = CGRect(
            x: 0.5 * (view.bounds.width - 100),
            y: view.bounds.height - 100,
            width: 100,
            height: 50
        )
        
        shotButton.layer.cornerRadius = 0.5 * 50

        guard let layer = cameraLayer else { return }
        layer.frame = photoView.bounds
    }
    
    @objc private func takePhoto() {
        captureProcessor?.takeShot()
    }
    
    private func setupCaptureProcessor() {
        self.captureProcessor = CaptureProcessor()
        guard let processor = self.captureProcessor else { return }
        
        processor.onDidCapturePhoto = { [weak self] image in
            guard let self = self, let image = image else {
                return
            }
            self.navigationController?.pushViewController(ShotViewController(image: image), animated: true)
        }
        
        processor.onDidUpdateDepthePhoto = { [weak self] image in
            self?.resultView.image = image
            self?.resultView.contentMode = .scaleAspectFit
        }
        
        let layer = AVCaptureVideoPreviewLayer(session: processor.session)
        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        photoView.layer.addSublayer(layer)
        layer.frame = photoView.bounds
        cameraLayer = layer
        
        processor.start()
    }
}

