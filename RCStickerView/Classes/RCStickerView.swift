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
    case flipX
    case flipY
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
    @objc optional func stickerViewDidChangeRotating(_ stickerView: RCStickerView, angle: CGFloat)
    @objc optional func stickerViewDidEndRotating(_ stickerView: RCStickerView)
    @objc optional func stickerViewDidClose(_ stickerView: RCStickerView)
    @objc optional func stickerViewDidTap(_ stickerView: RCStickerView)
    @objc optional func stickerViewDidBeginZooming(_ stickerView: RCStickerView)
    @objc optional func stickerViewDidChangeZooming(_ stickerView: RCStickerView, scale: CGFloat)
    @objc optional func stickerViewDidEndZooming(_ stickerView: RCStickerView)
}

@IBDesignable
open class RCStickerView: UIView {
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
    private var deltaAngle: CGFloat = 0
    private var _minimumSize: CGFloat = 0
    private var _handleSize: CGFloat = 0
    
    private var contentView: UIView!
    
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
    
    private lazy var flipXGesture: UITapGestureRecognizer = {
        let _flipGesture = UITapGestureRecognizer(target: self, action: #selector(handleFlipXGesture(_:)))
        _flipGesture.delegate = self
        return _flipGesture
    }()
    
    private lazy var flipYGesture: UITapGestureRecognizer = {
        let _flipGesture = UITapGestureRecognizer(target: self, action: #selector(handleFlipYGesture(_:)))
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
    
    private lazy var flipXImageView: UIImageView = {
        let _flipImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: defaultInset * 2, height: defaultInset * 2))
        _flipImageView.contentMode = .scaleAspectFit
        _flipImageView.backgroundColor = .clear
        _flipImageView.isUserInteractionEnabled = true
        _flipImageView.addGestureRecognizer(self.flipXGesture)
        return _flipImageView
    }()
    
    private lazy var flipYImageView: UIImageView = {
        let _flipImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: defaultInset * 2, height: defaultInset * 2))
        _flipImageView.contentMode = .scaleAspectFit
        _flipImageView.backgroundColor = .clear
        _flipImageView.isUserInteractionEnabled = true
        _flipImageView.addGestureRecognizer(self.flipYGesture)
        return _flipImageView
    }()
    
    private lazy var dashedLineBorder: CAShapeLayer = {
        let  borderLayer = CAShapeLayer()
        borderLayer.name  = "borderLayer"
        
        borderLayer.bounds = contentView?.bounds ?? .zero
        borderLayer.position = CGPoint(x: frame.width / 2, y: frame.height / 2)
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = outlineBorderColor.cgColor
        borderLayer.lineWidth = 1
        borderLayer.lineJoin = kCALineJoinRound
        borderLayer.lineDashPattern = [NSNumber(value: 8), NSNumber(value: 4)]
        borderLayer.allowsEdgeAntialiasing = true
        
        let path = UIBezierPath.init(roundedRect: contentView?.frame ?? .zero, cornerRadius: 0)
        borderLayer.path = path.cgPath
        
        return borderLayer
    }()
    
    // MARK: - Public
    
    @IBOutlet public weak var delegate: RCStickerViewDelegate?
    
    public func set(image: UIImage?, for handler: RCStickerViewHandler) {
        switch handler {
        case .close:
            self.closeImageView.image = image
        case .rotate:
            self.rotateImageView.image = image
        case .flipX:
            self.flipXImageView.image = image
        case .flipY:
            self.flipYImageView.image = image
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
        case .flipX:
            handlerView = self.flipXImageView
        case .flipY:
            handlerView = self.flipYImageView
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
            self.flipXImageView.frame = handlerFrame
            self.set(position: .bottomLeft, for: .flipX)
            self.flipYImageView.frame = handlerFrame
            self.set(position: .bottomRight, for: .flipY)
            
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
                self.flipXImageView.isHidden = !(isEnableFlipX && isEnableFlip)
                self.flipXImageView.isUserInteractionEnabled = isEnableFlipX && isEnableFlip
                self.flipYImageView.isHidden = !(isEnableFlipY && isEnableFlip)
                self.flipYImageView.isUserInteractionEnabled = isEnableFlipY && isEnableFlip
            }
        }
    }
    
    public var isEnableFlipX: Bool = true {
        didSet {
            if self.shouldShowEditingHandlers {
                self.flipXImageView.isHidden = !(isEnableFlipX && isEnableFlip)
                self.flipXImageView.isUserInteractionEnabled = isEnableFlipX && isEnableFlip
            }
        }
    }
    
    public var isEnableFlipY: Bool = true {
        didSet {
            if self.shouldShowEditingHandlers {
                self.flipYImageView.isHidden = !(isEnableFlipY && isEnableFlip)
                self.flipYImageView.isUserInteractionEnabled = isEnableFlipY && isEnableFlip
            }
        }
    }
    
    public var isEnableZooming: Bool = true {
        didSet {
            if isEnableZooming {
                if !(self.gestureRecognizers?.contains(zoomGesture) ?? false) {
                    self.addGestureRecognizer(zoomGesture)
                }
            }
            else {
                self.removeGestureRecognizer(zoomGesture)
            }
        }
    }
    
    public var shouldShowEditingHandlers: Bool = true {
        didSet {
            if shouldShowEditingHandlers {
                if self.isDashedLine {
                    self.contentView?.layer.borderWidth = 0
                    self.contentView?.layer.addSublayer(dashedLineBorder)
                }
                else {
                    dashedLineBorder.removeFromSuperlayer()
                    self.contentView?.layer.borderWidth = 1
                    self.contentView?.layer.borderColor = outlineBorderColor.cgColor
                }
            } else {
                dashedLineBorder.removeFromSuperlayer()
                self.contentView?.layer.borderWidth = 0
            }
            
            self.closeImageView.isHidden = !isEnableClose
            self.closeImageView.isUserInteractionEnabled = isEnableClose
            
            self.rotateImageView.isHidden = !isEnableRotate
            self.rotateImageView.isUserInteractionEnabled = isEnableRotate
            
            self.flipXImageView.isHidden = !(isEnableFlipX && isEnableFlip)
            self.flipXImageView.isUserInteractionEnabled = isEnableFlipX && isEnableFlip
            
            self.flipYImageView.isHidden = !(isEnableFlipY && isEnableFlip)
            self.flipYImageView.isUserInteractionEnabled = isEnableFlipY && isEnableFlip
        }
    }
    
    public var isDashedLine: Bool = false {
        didSet {
            if isDashedLine {
                self.contentView?.layer.addSublayer(dashedLineBorder)
            }
            else {
                dashedLineBorder.removeFromSuperlayer()
            }
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
            if isDashedLine {
                self.contentView?.layer.borderColor = outlineBorderColor.cgColor
            }
            else {
                dashedLineBorder.borderColor = outlineBorderColor.cgColor
            }
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
        self.contentView.isUserInteractionEnabled = true
        self.contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.contentView.layer.allowsEdgeAntialiasing = true
        self.addSubview(contentView)
        
        if self.isDashedLine {
            dashedLineBorder.removeFromSuperlayer()
            self.contentView.layer.addSublayer(dashedLineBorder)
        }
        else {
            self.contentView.layer.borderWidth = 1
            self.contentView.layer.borderColor = outlineBorderColor.cgColor
        }
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
        self.set(position: .bottomLeft, for: .flipX)
        self.addSubview(self.flipXImageView)
        self.set(position: .bottomRight, for: .flipY)
        self.addSubview(self.flipYImageView)
        
        self.shouldShowEditingHandlers = true
        self.isEnableClose = true
        self.isEnableRotate = true
        self.isEnableFlipX = true
        self.isEnableFlipY = true
        
        self._minimumSize = defaultMinimumSize
    }
    
    // MARK: - Gesture Handlers
    
    @objc func handleMoveGesture(_ recognizer: UIPanGestureRecognizer) {
        let touchLocation = recognizer.location(in: self.superview)
        
        switch recognizer.state {
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
            self.delegate?.stickerViewDidBeginRotating?(self)
        case .changed:
            let angle = atan2f(Float(touchLocation.y - center.y), Float(touchLocation.x - center.x))
            let angleDiff = deltaAngle - CGFloat(angle)
            self.transform = CGAffineTransform(rotationAngle: -angleDiff)
            
            self.delegate?.stickerViewDidChangeRotating?(self, angle: CGFloat(angle))
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
    
    @objc func handleFlipXGesture(_ recognizer: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.35) {
            self.contentView?.transform = CGAffineTransform(scaleX: -1, y: 1)
        }
    }
    
    @objc func handleFlipYGesture(_ recognizer: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.35) {
            self.contentView?.transform = CGAffineTransform(scaleX: 1, y: -1)
        }
    }
    
    @objc func handleTapGesture(_ recognizer: UITapGestureRecognizer) {
        self.delegate?.stickerViewDidTap?(self)
    }
    
    @objc func handleZoomGesture(_ recognizer: UIPinchGestureRecognizer) {
        switch recognizer.state {
        case .began:
            initialBounds = self.bounds
            recognizer.scale = 1
            self.delegate?.stickerViewDidBeginZooming?(self)
        case .changed:
            var scale = recognizer.scale
            let minimumScale = self._minimumSize / min(initialBounds.width, initialBounds.height)
            scale = max(scale, minimumScale)
            self.bounds = initialBounds.scale(w: scale, h: scale)
            self.contentView.bounds = CGRect(x: defaultInset, y: defaultInset, width: frame.width - defaultInset * 2, height: frame.height - defaultInset * 2)
            self.setNeedsDisplay()
            
            self.delegate?.stickerViewDidChangeZooming?(self, scale: scale)
        case .ended:
            self.transform = .identity
            self.delegate?.stickerViewDidEndZooming?(self)
        default:
            return
        }
    }
}

extension RCStickerView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
