//
//  RCStickerView.swift
//  Pods-RCStickerView_Example
//
//  Created by Robert Nguyen on 11/2/18.
//

import UIKit

public enum RCStickerViewHandler {
    case close
    case rotate
    case flip
}

public enum RCStickerViewPosition: Int {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

@objc public protocol RCStickerViewDelegate: class {
    @objc optional func stickerViewDidBeginMoving(_ stickerView: RCStickerView)
    @objc optional func stickerViewDidChangeMoving(_ stickerView: RCStickerView)
    @objc optional func stickerViewDidEndMoving(_ stickerView: RCStickerView)
    @objc optional func stickerViewDidBeginRotating(_ stickerView: RCStickerView)
    @objc optional func stickerViewDidChangeRotating(_ stickerView: RCStickerView)
    @objc optional func stickerViewDidEndRotating(_ stickerView: RCStickerView)
    @objc optional func stickerViewDidClose(_ stickerView: RCStickerView)
    @objc optional func stickerViewDidTap(_ stickerView: RCStickerView)
    @objc optional func stickerViewDidBeginZooming(_ stickerView: RCStickerView)
    @objc optional func stickerViewDidChangeZooming(_ stickerView: RCStickerView)
    @objc optional func stickerViewDidEndZooming(_ stickerView: RCStickerView)
}

public class RCStickerView: UIView {
    private var defaultInset: CGFloat = 0
    private var defaultMinimumSize: CGFloat = 0
    
    /**
     *  Variables for moving view
     */
    private var beginningPoint: CGPoint = .zero
    private var beginningCenter: CGPoint = .zero
    
    /**
     *  Variables for rotating and resizing view
     */
    private var initialBounds: CGRect = .zero
    private var initialDistance: CGFloat = 0
    private var deltaAngle: CGFloat = 0
    private var _minimumSize: CGFloat = 0
    private var _handleSize: CGFloat = 0
    
    private var contentView: UIView!
    
    @IBOutlet public weak var delegate: RCStickerViewDelegate?
    
    private lazy var moveGesture: UIPanGestureRecognizer = {
        return UIPanGestureRecognizer(target: self, action: #selector(handleMoveGesture(_:)))
    }()
    
    private lazy var rotateGesture: UIPanGestureRecognizer = {
        return UIPanGestureRecognizer(target: self, action: #selector(handleRotateGesture(_:)))
    }()
    
    private lazy var closeGesture: UITapGestureRecognizer = {
        let _closeGesture = UITapGestureRecognizer(target: self, action: #selector(handleCloseGesture(_:)))
        _closeGesture.delegate = self
        return _closeGesture
    }()
    
    private lazy var flipGesture: UITapGestureRecognizer = {
        let _flipGesture = UITapGestureRecognizer(target: self, action: #selector(handleFlipGesture(_:)))
        _flipGesture.delegate = self
        return _flipGesture
    }()
    
    private lazy var tapGesture: UITapGestureRecognizer = {
        return UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
    }()
    
    private lazy var zoomGesture: UIPinchGestureRecognizer = {
        return UIPinchGestureRecognizer(target: self, action: #selector(handleZoomGesture(_:)))
    }()
    
    private lazy var closeImageView: UIImageView = {
        let _closeImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: defaultInset * 2, height: defaultInset * 2))
        _closeImageView.contentMode = .scaleAspectFit
        _closeImageView.backgroundColor = .clear
        _closeImageView.isUserInteractionEnabled = true
        _closeImageView.addGestureRecognizer(self.closeGesture)
        return _closeImageView
    }()
    
    private lazy var rotateImageView: UIImageView = {
        let _rotateImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: defaultInset * 2, height: defaultInset * 2))
        _rotateImageView.contentMode = .scaleAspectFit
        _rotateImageView.backgroundColor = .clear
        _rotateImageView.isUserInteractionEnabled = true
        _rotateImageView.addGestureRecognizer(self.rotateGesture)
        return _rotateImageView
    }()
    
    private lazy var flipImageView: UIImageView = {
        let _flipImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: defaultInset * 2, height: defaultInset * 2))
        _flipImageView.contentMode = .scaleAspectFit
        _flipImageView.backgroundColor = .clear
        _flipImageView.isUserInteractionEnabled = true
        _flipImageView.addGestureRecognizer(self.flipGesture)
        return _flipImageView
    }()
    
    public func set(image: UIImage?, for handler: RCStickerViewHandler) {
        switch handler {
        case .close:
            self.closeImageView.image = image
        case .rotate:
            self.rotateImageView.image = image
        case .flip:
            self.flipImageView.image = image
        }
    }
    
    public func set(position: RCStickerViewPosition, for handler: RCStickerViewHandler) {
        let origin = self.contentView.frame.origin
        let size = self.contentView.frame.size
        let handlerView: UIView
        
        switch handler {
        case .close:
            handlerView = self.closeImageView
        case .rotate:
            handlerView = self.rotateImageView
        case .flip:
            handlerView = self.flipImageView
        }
        
        switch position {
        case .topLeft:
            handlerView.center = origin
            handlerView.autoresizingMask = [.flexibleRightMargin, .flexibleBottomMargin]
        case .topRight:
            handlerView.center = CGPoint(x: origin.x + size.width, y: origin.y)
            handlerView.autoresizingMask = [.flexibleLeftMargin, .flexibleBottomMargin]
        case .bottomLeft:
            handlerView.center = CGPoint(x: origin.x, y: origin.y + size.height)
            handlerView.autoresizingMask = [.flexibleRightMargin, .flexibleTopMargin]
        case .bottomRight:
            handlerView.center = CGPoint(x: origin.x + size.width, y: origin.y + size.height)
            handlerView.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
        }
        
        handlerView.tag = position.rawValue
    }
    
    public var handlerSize: CGFloat {
        set(size) {
            guard size > 0 else {
                return
            }
            
            defaultInset = round(size / 2)
            defaultMinimumSize = 4 * defaultInset
//            self._minimumSize = MAX(self.minimumSize, defaultMinimumSize)
            
            let originalCenter = self.center
            let originalTransform = self.transform
            let frame = CGRect(x: 0, y: 0, width: self.contentView.frame.width + defaultInset * 2, height: self.contentView.frame.height + defaultInset * 2)
            
            self.contentView.removeFromSuperview()
            self.transform = .identity
            self.frame = frame
            
            self.contentView.center = center
            self.addSubview(self.contentView)
            self.sendSubview(toBack: self.contentView)
            
            let handlerFrame = CGRect(x: 0, y: 0, width: defaultInset * 2, height: defaultInset * 2)
            self.closeImageView.frame = handlerFrame
            self.set(position: .topRight, for: .close)
            self.rotateImageView.frame = handlerFrame
            self.set(position: .topLeft, for: .rotate)
            self.flipImageView.frame = handlerFrame
            self.set(position: .bottomRight, for: .flip)
            
            self.center = originalCenter
            self.transform = originalTransform
        }
        get {
            return _handleSize
        }
    }
    
    public var isEnableClose: Bool = true {
        didSet {
            if self.shouldShowEditingHandlers {
                self.closeImageView.isHidden = !isEnableClose
                self.closeImageView.isUserInteractionEnabled = isEnableClose
            }
        }
    }
    
    public var isEnableRotate: Bool = true {
        didSet {
            if self.shouldShowEditingHandlers {
                self.rotateImageView.isHidden = !isEnableRotate
                self.rotateImageView.isUserInteractionEnabled = isEnableRotate
            }
        }
    }
    
    public var isEnableFlip: Bool = true {
        didSet {
            if self.shouldShowEditingHandlers {
                self.flipImageView.isHidden = !isEnableFlip
                self.flipImageView.isUserInteractionEnabled = isEnableFlip
            }
        }
    }
    
    public var shouldShowEditingHandlers: Bool = true {
        didSet {
            if shouldShowEditingHandlers {
                self.contentView.layer.borderWidth = 2
            } else {
                self.contentView.layer.borderWidth = 0
            }
            
            self.closeImageView.isHidden = !isEnableClose
            self.closeImageView.isUserInteractionEnabled = isEnableClose
            self.rotateImageView.isHidden = !isEnableRotate
            self.rotateImageView.isUserInteractionEnabled = isEnableRotate
            self.flipImageView.isHidden = !isEnableFlip
            self.flipImageView.isUserInteractionEnabled = isEnableFlip
        }
    }
    
    public var minimumSize: CGFloat {
        set(size) {
            _minimumSize = max(size, defaultMinimumSize)
        }
        get {
            return _minimumSize
        }
    }
    
    public var outlineBorderColor: UIColor = .brown {
        didSet {
            self.contentView.layer.borderColor = outlineBorderColor.cgColor
        }
    }
    
    // MARK: - UIView
    
    public init(contentView: UIView) {
        defaultInset = 11
        defaultMinimumSize = 4 * defaultInset
        
        let frame = CGRect(x: 0, y: 0, width: contentView.frame.width + defaultInset * 2, height: contentView.frame.height + defaultInset * 2)
        super.init(frame: frame)
        set(contentView: contentView)
        initView()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        defaultInset = 11
        defaultMinimumSize = 4 * defaultInset
        initView()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func set(contentView: UIView) {
        self.contentView?.removeFromSuperview()
        
        self.contentView = contentView
        self.contentView.center = center
        self.contentView.isUserInteractionEnabled = false
        self.contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.contentView.layer.allowsEdgeAntialiasing = true
        self.addSubview(contentView)
        
        self.contentView.layer.borderColor = outlineBorderColor.cgColor
    }
}

private extension RCStickerView {
    func addGestures() {
        addGestureRecognizer(self.moveGesture)
        addGestureRecognizer(self.tapGesture)
        addGestureRecognizer(self.zoomGesture)
    }
    
    func initView() {
        self.backgroundColor = .clear
        addGestures()
        
        // Setup editing handlers
        self.set(position: .topLeft, for: .close)
        self.addSubview(self.closeImageView)
        self.set(position: .topRight, for: .rotate)
        self.addSubview(self.rotateImageView)
        self.set(position: .bottomLeft, for: .flip)
        self.addSubview(self.flipImageView)
        
        self.shouldShowEditingHandlers = true
        self.isEnableClose = true
        self.isEnableRotate = true
        self.isEnableFlip = true
        
        self._minimumSize = defaultMinimumSize
    }
}

// MARK: - Gesture Handlers

private extension RCStickerView {
    
    @objc func handleMoveGesture(_ recognizer: UIPanGestureRecognizer) {
        let touchLocation = recognizer.location(in: self.superview)
        
        switch (recognizer.state) {
        case .began:
            beginningPoint = touchLocation
            beginningCenter = self.center
            self.delegate?.stickerViewDidBeginMoving?(self)
        case .changed:
            self.center = CGPoint(x: beginningCenter.x + (touchLocation.x - beginningPoint.x),
                                  y: beginningCenter.y + (touchLocation.y - beginningPoint.y))
            self.delegate?.stickerViewDidChangeMoving?(self)
        case .ended:
            self.center = CGPoint(x: beginningCenter.x + (touchLocation.x - beginningPoint.x),
                                  y: beginningCenter.y + (touchLocation.y - beginningPoint.y))
            self.delegate?.stickerViewDidEndMoving?(self)
        default:
            break
        }
    }
    
    @objc func handleRotateGesture(_ recognizer: UIPanGestureRecognizer) {
        let touchLocation = recognizer.location(in: self.superview)
        let center = self.center
        
        switch recognizer.state {
        case .began:
            deltaAngle = CGFloat(atan2f(Float(touchLocation.y - center.y), Float(touchLocation.x - center.x - self.transform.angle)))
//            initialBounds = self.bounds
//            initialDistance = distance(from: center, to: touchLocation)
            self.delegate?.stickerViewDidBeginRotating?(self)
        case .changed:
            let angle = atan2f(Float(touchLocation.y - center.y), Float(touchLocation.x - center.x))
            let angleDiff = deltaAngle - CGFloat(angle)
            self.transform = CGAffineTransform(rotationAngle: -angleDiff)
            
//            var scale = distance(from: center, to: touchLocation) / initialDistance
//            let minimumScale = self._minimumSize / min(initialBounds.width, initialBounds.height)
//            scale = max(scale, minimumScale)
//            self.bounds = initialBounds.scale(w: scale, h: scale)
//            self.setNeedsDisplay()
            
            self.delegate?.stickerViewDidChangeRotating?(self)
        case .ended:
            self.delegate?.stickerViewDidEndRotating?(self)
        default:
            break
        }
    }
    
    @objc func handleCloseGesture(_ recognizer: UITapGestureRecognizer) {
        self.removeFromSuperview()
        self.delegate?.stickerViewDidClose?(self)
    }
    
    @objc func handleFlipGesture(_ recognizer: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.35) {
            self.contentView.transform = CGAffineTransform(scaleX: -1, y: 1)
        }
    }
    
    @objc func handleTapGesture(_ recognizer: UITapGestureRecognizer) {
        self.delegate?.stickerViewDidTap?(self)
    }
    
    @objc func handleZoomGesture(_ recognizer: UIPinchGestureRecognizer) {
        switch recognizer.state {
        case .began:
            initialBounds = self.bounds
            self.delegate?.stickerViewDidBeginZooming?(self)
        case .changed:
//            let pinchCenter = CGPoint(x: recognize.location(in: contentView).x - contentView.bounds.midX,
//                                      y: recognize.location(in: contentView).y - contentView.bounds.midY)
//            let transform = contentView.transform.translatedBy(x: pinchCenter.x, y: pinchCenter.y)
//                .scaledBy(x: recognize.scale, y: recognize.scale)
//                .translatedBy(x: -pinchCenter.x, y: -pinchCenter.y)
//            contentView.transform = transform
//            recognize.scale = 1
            
            var scale = recognizer.scale
            let minimumScale = self._minimumSize / min(initialBounds.width, initialBounds.height)
            scale = max(scale, minimumScale)
            self.bounds = initialBounds.scale(w: scale, h: scale)
            self.setNeedsDisplay()
            
            self.delegate?.stickerViewDidChangeZooming?(self)
        case .ended:
            // Nice animation to scale down when releasing the pinch.
            // OPTIONAL
            self.contentView.transform = .identity
            self.delegate?.stickerViewDidEndZooming?(self)
        default:
            return
        }
    }
}

extension RCStickerView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
