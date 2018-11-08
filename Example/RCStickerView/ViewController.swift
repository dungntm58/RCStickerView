//
//  ViewController.swift
//  RCStickerView
//
//  Created by Robert Nguyen on 11/02/2018.
//  Copyright (c) 2018 Robert Nguyen. All rights reserved.
//

import UIKit
import RCStickerView

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        self.view.addSubview(container)
        container.backgroundColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
        container.center = self.view.center
        
        let testView = UIView(frame: CGRect(x: 0, y: 0, width: 150, height: 100))
        testView.backgroundColor = .black
        
        let stickerView = RCStickerView(contentView: testView)
        stickerView.delegate = self
        stickerView.outlineBorderColor = .blue
        stickerView.set(image: UIImage(named: "Close"), for: .close)
        stickerView.set(image: UIImage(named: "Rotate"), for: .rotate)
        stickerView.set(image: UIImage(named: "Flip"), for: .flipX)
        stickerView.isEnableFlipY = false
        stickerView.handlerSize = 40
        stickerView.isDashedLine = true
        stickerView.movingMode = .insideSuperview(ignoreHandler: true)
        stickerView.zoomMode = .insideSuperview
        
        container.addSubview(stickerView)
        
        let testLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 50))
        testLabel.text = "Test Label"
        testLabel.textAlignment = .center
        
        let stickerView2 = RCStickerView(contentView: testLabel)
        stickerView2.center = CGPoint(x: 100, y: 100)
        stickerView2.delegate = self
        stickerView2.set(image: UIImage(named: "Close"), for: .close)
        stickerView2.set(image: UIImage(named: "Rotate"), for: .rotate)
        stickerView2.isEnableFlip = false
        stickerView2.shouldShowEditingHandlers = true
        self.view.addSubview(stickerView2)
        
        self.selectedView = stickerView
    }

    var selectedView: RCStickerView! {
        didSet {
            if oldValue != selectedView {
                oldValue?.shouldShowEditingHandlers = false
            }
            selectedView?.shouldShowEditingHandlers =  true
        }
    }
}

extension ViewController: RCStickerViewDelegate {
    func stickerViewDidBeginMoving(_ stickerView: RCStickerView) {
        self.selectedView = stickerView
    }
    
    func stickerViewDidTap(_ stickerView: RCStickerView) {
        self.selectedView = stickerView
    }
}

