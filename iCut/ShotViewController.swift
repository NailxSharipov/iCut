//
//  ShotViewController.swift
//  iCut
//
//  Created by Nail Sharipov on 24.03.2022.
//

import UIKit

final class ShotViewController: UIViewController {
    
    private let imageView = UIImageView()
    
    override func loadView() {
        self.view = imageView
        imageView.contentMode = .center
    }
    
    init(image: UIImage) {
        super.init(nibName: nil, bundle: nil)
        imageView.image = image
    }
    
    required init?(coder: NSCoder) {
        return nil
    }
}
