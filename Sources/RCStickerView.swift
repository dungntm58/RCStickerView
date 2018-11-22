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

public enum MovingMode {
    case free
    case insideSuperview(ignoreHandler: Bool)
    case inside(view: UIView, ignoreHandler: Bool)
}

@objc public protocol RCStickerViewDelegate: AnyObject {
    @objc optional func stickerViewDidBeginMoving(_ stickerView: RCStickerView)
    @objc optional func stickerViewDidChangeMoving(_ stickerView: RCStickerView)
    @objc optional func stickerViewDidEndMoving(_ stickerView: RCStickerView)
    @objc optional func stickerViewDidBeginRotating(_ stickerView: RCStickerView)
    @objc optional func stickerViewDidChangeRotating(_ stickerView: RCStickerView, angle: CGFloat, scale: CGFloat)
    @objc optional func stickerViewDidEndRotating(_ stickerView: RCStickerView)
    @objc optional func stickerViewDidClose(_ stickerView: RCStickerView)
    @objc optional func stickerViewDidTap(_ stickerView: RCStickerView)
}

@IBDesignable
open class RCStickerView: UIView {
    private var defaultInset: CGFloat = 0
    private var defaultMinimumSize: CGFloat = 0
    private var defaultMaximumSize: CGFloat = 0
    
    /**
     *  Variables for moving view
     */
    private var beginningPoint: CGPoint = .zero
    private var beginningCenter: CGPoint = .zero
    
    /**
     *  Variables for rotating and resizing view
     */
    private var initialDistance: CGFloat = 0
    private var initialBounds: CGRect = .zero
    private var deltaAngle: CGFloat = 0
    private var _minimumSize: CGFloat = 0
    private var _maximumSize: CGFloat = 0
    private var _handleSize: CGFloat = 0
    
    private var contentView: UIView!
    
    private var positionHandlerMap: [RCStickerViewPosition: RCStickerViewHandler] = [:]
    private var positionVisibilityMap: [RCStickerViewPosition: Bool] = [:]
    
    private lazy var moveGesture = UIPanGestureRecognizer(target: self, action: #selector(handleMoveGesture(_:)))
    
    private lazy var rotateGesture = UIPanGestureRecognizer(target: self, action: #selector(handleRotateGesture(_:)))
    
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
    
    private lazy var tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
    
    private lazy var closeImageView: UIImageView = {
        let _closeImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: _handleSize, height: _handleSize))
        _closeImageView.contentMode = .scaleAspectFit
        _closeImageView.backgroundColor = .clear
        _closeImageView.isUserInteractionEnabled = true
        _closeImageView.addGestureRecognizer(closeGesture)
        return _closeImageView
    }()
    
    private lazy var rotateImageView: UIImageView = {
        let _rotateImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: _handleSize, height: _handleSize))
        _rotateImageView.contentMode = .scaleAspectFit
        _rotateImageView.backgroundColor = .clear
        _rotateImageView.isUserInteractionEnabled = true
        _rotateImageView.addGestureRecognizer(rotateGesture)
        return _rotateImageView
    }()
    
    private lazy var flipXImageView: UIImageView = {
        let _flipImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: _handleSize, height: _handleSize))
        _flipImageView.contentMode = .scaleAspectFit
        _flipImageView.backgroundColor = .clear
        _flipImageView.isUserInteractionEnabled = true
        _flipImageView.addGestureRecognizer(flipXGesture)
        return _flipImageView
    }()
    
    private lazy var flipYImageView: UIImageView = {
        let _flipImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: _handleSize, height: _handleSize))
        _flipImageView.contentMode = .scaleAspectFit
        _flipImageView.backgroundColor = .clear
        _flipImageView.isUserInteractionEnabled = true
        _flipImageView.addGestureRecognizer(flipYGesture)
        return _flipImageView
    }()
    
    private lazy var dashedLineBorder: CAShapeLayer = {
        let  borderLayer = CAShapeLayer()
        borderLayer.name  = "borderLayer"
        
        borderLayer.bounds = contentView?.bounds ?? .zero
        borderLayer.position = CGPoint(x: (contentView?.frame.width ?? 0) / 2, y: (contentView?.frame.height ?? 0) / 2)
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = outlineBorderColor.cgColor
        borderLayer.lineWidth = 1
        borderLayer.lineJoin = .round
        borderLayer.lineDashPattern = [NSNumber(value: 8), NSNumber(value: 4)]
        borderLayer.allowsEdgeAntialiasing = true
        
        let path = UIBezierPath.init(roundedRect: contentView?.bounds ?? .zero, cornerRadius: 0)
        borderLayer.path = path.cgPath
        
        return borderLayer
    }()
    
    // MARK: - Public
    
    @IBOutlet public weak var delegate: RCStickerViewDelegate?
    
    public var movingMode: MovingMode = .free
    public var shouldScaleContent = false
    
    public func set(image: UIImage?, for handler: RCStickerViewHandler) {
        switch handler {
        case .close:
            closeImageView.image = image
        case .rotate:
            rotateImageView.image = image
        case .flipX:
            flipXImageView.image = image
        case .flipY:
            flipYImageView.image = image
        }
        
        for (key, value) in positionHandlerMap where value == handler {
            positionVisibilityMap[key] = image != nil
            break
        }
    }
    
    public func set(position: RCStickerViewPosition, for handler: RCStickerViewHandler) {
        let origin = contentView.frame.origin
        let size = contentView.frame.size
        let handlerView: UIView
        
        switch handler {
        case .close:
            handlerView = closeImageView
        case .rotate:
            handlerView = rotateImageView
        case .flipX:
            handlerView = flipXImageView
        case .flipY:
            handlerView = flipYImageView
        }
        
        var oldPosition: RCStickerViewPosition = .topLeft
        for (key, value) in positionHandlerMap where value == handler {
            oldPosition = key
        }
        
        let oldHandler = positionHandlerMap[position]
        positionHandlerMap[position] = handler
        positionHandlerMap[oldPosition] = oldHandler
        
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
            guard size > 0 else { return }
            
            defaultInset = round(size / 2)
            defaultMinimumSize = 4 * defaultInset
            _handleSize = size

            let originalCenter = self.center
            let originalTransform = self.transform
            let frame = CGRect(x: 0, y: 0, width: contentView.frame.width + size, height: contentView.frame.height + size)
            
            contentView.removeFromSuperview()
            self.transform = .identity
            self.frame = frame
            
            contentView.center = center
            addSubview(contentView)
            sendSubviewToBack(contentView)
            
            let handlerFrame = CGRect(x: 0, y: 0, width: size, height: size)
            closeImageView.frame = handlerFrame
            rotateImageView.frame = handlerFrame
            flipXImageView.frame = handlerFrame
            flipYImageView.frame = handlerFrame
            
            set(position: .topLeft, for: positionHandlerMap[.topLeft]!)
            set(position: .topRight, for: positionHandlerMap[.topRight]!)
            set(position: .bottomLeft, for: positionHandlerMap[.bottomLeft]!)
            set(position: .bottomRight, for: positionHandlerMap[.bottomRight]!)
            
            self.center = originalCenter
            self.transform = originalTransform
        }
        get { _handleSize }
    }
    
    public var isEnableClose: Bool = true {
        didSet {
            guard shouldShowEditingHandlers else { return }
            closeImageView.isHidden = !isEnableClose
            closeImageView.isUserInteractionEnabled = isEnableClose
        }
    }
    
    public var isEnableRotate: Bool = true {
        didSet {
            guard shouldShowEditingHandlers else { return }
            rotateImageView.isHidden = !isEnableRotate
            rotateImageView.isUserInteractionEnabled = isEnableRotate
        }
    }
    
    public var isEnableFlip: Bool = true {
        didSet {
            guard shouldShowEditingHandlers else { return }
            flipXImageView.isHidden = !(isEnableFlipX && isEnableFlip)
            flipXImageView.isUserInteractionEnabled = isEnableFlipX && isEnableFlip
            flipYImageView.isHidden = !(isEnableFlipY && isEnableFlip)
            flipYImageView.isUserInteractionEnabled = isEnableFlipY && isEnableFlip
        }
    }
    
    public var isEnableFlipX: Bool = true {
        didSet {
            guard shouldShowEditingHandlers else { return }
            flipXImageView.isHidden = !(isEnableFlipX && isEnableFlip)
            flipXImageView.isUserInteractionEnabled = isEnableFlipX && isEnableFlip
        }
    }
    
    public var isEnableFlipY: Bool = true {
        didSet {
            guard shouldShowEditingHandlers else { return }
            flipYImageView.isHidden = !(isEnableFlipY && isEnableFlip)
            flipYImageView.isUserInteractionEnabled = isEnableFlipY && isEnableFlip
        }
    }
    
    public var shouldShowEditingHandlers: Bool = true {
        didSet {
            if shouldShowEditingHandlers {
                if isDashedLine {
                    contentView?.layer.borderWidth = 0
                    contentView?.layer.addSublayer(dashedLineBorder)
                }
                else {
                    dashedLineBorder.removeFromSuperlayer()
                    contentView?.layer.borderWidth = 1
                    contentView?.layer.borderColor = outlineBorderColor.cgColor
                }
            } else {
                dashedLineBorder.removeFromSuperlayer()
                contentView?.layer.borderWidth = 0
            }
            
            closeImageView.isHidden = !(isEnableClose && shouldShowEditingHandlers)
            closeImageView.isUserInteractionEnabled = isEnableClose
            
            rotateImageView.isHidden = !(isEnableRotate && shouldShowEditingHandlers)
            rotateImageView.isUserInteractionEnabled = isEnableRotate
            
            flipXImageView.isHidden = !(isEnableFlipX && isEnableFlip && shouldShowEditingHandlers)
            flipXImageView.isUserInteractionEnabled = isEnableFlipX && isEnableFlip
            
            flipYImageView.isHidden = !(isEnableFlipY && isEnableFlip && shouldShowEditingHandlers)
            flipYImageView.isUserInteractionEnabled = isEnableFlipY && isEnableFlip
        }
    }
    
    public var isDashedLine: Bool = false {
        didSet {
            if isDashedLine {
                if dashedLineBorder.superlayer == nil {
                    contentView?.layer.addSublayer(dashedLineBorder)
                }
                dashedLineBorder.borderColor = outlineBorderColor.cgColor
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
        get { _minimumSize }
    }
    
    public var maximumSize: CGFloat {
        set(size) {
            _maximumSize = min(size, defaultMaximumSize)
        }
        get {
            return _maximumSize
        }
    }
    
    public var outlineBorderColor: UIColor = .brown {
        didSet {
            if isDashedLine {
                dashedLineBorder.borderColor = outlineBorderColor.cgColor
            }
            else {
                contentView?.layer.borderColor = outlineBorderColor.cgColor
            }
        }
    }
    
    // MARK: - UIView
    
    public init(contentView: UIView) {
        defaultInset = 11
        defaultMinimumSize = 4 * defaultInset
        defaultMaximumSize = UIScreen.main.bounds.width
        _handleSize = 2 * defaultInset
        
        let frame = CGRect(x: 0, y: 0, width: contentView.frame.width + _handleSize, height: contentView.frame.height + _handleSize)
        super.init(frame: frame)
        set(contentView: contentView)
        initView()
        initMap()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
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
        addSubview(contentView)
        
        if isDashedLine {
            dashedLineBorder.removeFromSuperlayer()
            self.contentView.layer.addSublayer(dashedLineBorder)
        }
        else {
            self.contentView.layer.borderWidth = 1
            self.contentView.layer.borderColor = outlineBorderColor.cgColor
        }
    }
    
    public func layoutInsideBounds(in view: UIView) {
        let frameInSuperview = view.convert(view.bounds, to: self.superview)
        
        var x = self.center.x
        var y = self.center.y
        
        var topPadding: CGFloat = 0
        var leftPadding: CGFloat = 0
        var rightPadding: CGFloat = 0
        var bottomPadding: CGFloat = 0
        
        if positionVisibilityMap[.topLeft]! || positionVisibilityMap[.topRight]! {
            topPadding = _handleSize - frameInSuperview.origin.y
        }
        if positionVisibilityMap[.topLeft]! || positionVisibilityMap[.bottomLeft]! {
            leftPadding = _handleSize - frameInSuperview.origin.x
        }
        if positionVisibilityMap[.bottomRight]! || positionVisibilityMap[.topRight]! {
            rightPadding = _handleSize + frameInSuperview.origin.x
        }
        if positionVisibilityMap[.bottomRight]! || positionVisibilityMap[.bottomLeft]! {
            bottomPadding = _handleSize + frameInSuperview.origin.y
        }
        
        if x < frame.width / 2 - leftPadding {
            x = frame.width / 2 - leftPadding
        }
        
        if y < frame.height / 2 - topPadding {
            y = frame.height / 2 - topPadding
        }
        
        if x > frameInSuperview.width - frame.width / 2 + rightPadding {
            x = frameInSuperview.width - frame.width / 2 + rightPadding
        }
        
        if y > frameInSuperview.height - frame.height / 2 + bottomPadding {
            y = frameInSuperview.height - frame.height / 2 + bottomPadding
        }
        
        self.center = CGPoint(x: x, y: y)
    }
}

private extension RCStickerView {
    func addGestures() {
        addGestureRecognizer(moveGesture)
        addGestureRecognizer(tapGesture)
    }
    
    func initView() {
        self.backgroundColor = .clear
        addGestures()
        
        // Setup editing handlers
        addSubview(closeImageView)
        addSubview(rotateImageView)
        addSubview(flipXImageView)
        addSubview(flipYImageView)
        
        set(position: .topLeft, for: .close)
        set(position: .topRight, for: .rotate)
        set(position: .bottomLeft, for: .flipX)
        set(position: .bottomRight, for: .flipY)
        
        self.shouldShowEditingHandlers = true
        self.isEnableClose = true
        self.isEnableRotate = true
        self.isEnableFlipX = true
        self.isEnableFlipY = true
        
        self._minimumSize = defaultMinimumSize
    }
    
    func commonInit() {
        defaultInset = 11
        defaultMinimumSize = 4 * defaultInset
        defaultMaximumSize = UIScreen.main.bounds.width
        _handleSize = 2 * defaultInset
        initView()
        initMap()
    }
    
    func initMap() {
        positionHandlerMap[.topLeft] = .close
        positionHandlerMap[.topRight] = .rotate
        positionHandlerMap[.bottomLeft] = .flipX
        positionHandlerMap[.bottomRight] = .flipY
        
        positionVisibilityMap[.topLeft] = false
        positionVisibilityMap[.topRight] = false
        positionVisibilityMap[.bottomLeft] = false
        positionVisibilityMap[.bottomRight] = false
    }
    
    // MARK: - Gesture Handlers
    
    @objc func handleMoveGesture(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            onBeginMoving(recognizer)
            delegate?.stickerViewDidBeginMoving?(self)
        case .changed:
            onMoving(recognizer)
            delegate?.stickerViewDidChangeMoving?(self)
        case .ended:
            onMoving(recognizer)
            delegate?.stickerViewDidEndMoving?(self)
        default:
            break
        }
    }
    
    private func onBeginMoving(_ recognizer: UIPanGestureRecognizer) {
        beginningPoint = recognizer.location(in: self.superview)
        beginningCenter = self.center
    }
    
    private func onMoving(_ recognizer: UIPanGestureRecognizer) {
        var touchLocation: CGPoint
        var x: CGFloat
        var y: CGFloat
        
        switch movingMode {
        case .free:
            touchLocation = recognizer.location(in: superview)
            x = beginningCenter.x + (touchLocation.x - beginningPoint.x)
            y = beginningCenter.y + (touchLocation.y - beginningPoint.y)
        case .insideSuperview(let ignoreHandler):
            touchLocation = recognizer.location(in: superview)
            x = beginningCenter.x + (touchLocation.x - beginningPoint.x)
            y = beginningCenter.y + (touchLocation.y - beginningPoint.y)
            
            var topPadding: CGFloat = 0
            var leftPadding: CGFloat = 0
            var rightPadding: CGFloat = 0
            var bottomPadding: CGFloat = 0
            if ignoreHandler {
                if positionVisibilityMap[.topLeft]! || positionVisibilityMap[.topRight]! {
                    topPadding = _handleSize / 2
                }
                if positionVisibilityMap[.topLeft]! || positionVisibilityMap[.bottomLeft]! {
                    leftPadding = _handleSize / 2
                }
                if positionVisibilityMap[.bottomRight]! || positionVisibilityMap[.topRight]! {
                    rightPadding = _handleSize / 2
                }
                if positionVisibilityMap[.bottomRight]! || positionVisibilityMap[.bottomLeft]! {
                    bottomPadding = _handleSize / 2
                }
            }
            
            if x < frame.width / 2 - leftPadding {
                x = frame.width / 2 - leftPadding
            }
            
            if y < frame.height / 2 - topPadding {
                y = frame.height / 2 - topPadding
            }
            
            let superview = self.superview ?? self.window
            if let superview = superview {
                if x > superview.frame.width - frame.width / 2 + rightPadding {
                    x = superview.frame.width - frame.width / 2 + rightPadding
                }
                
                if y > superview.frame.height - frame.height / 2 + bottomPadding {
                    y = superview.frame.height - frame.height / 2 + bottomPadding
                }
            }
        case .inside(let view, let ignoreHandler):
            touchLocation = recognizer.location(in: self.superview)
            let frameInSuperview = view.convert(view.bounds, to: self.superview)
            
            x = beginningCenter.x + touchLocation.x - beginningPoint.x
            y = beginningCenter.y + touchLocation.y - beginningPoint.y
            
            var topPadding: CGFloat = 0
            var leftPadding: CGFloat = 0
            var rightPadding: CGFloat = 0
            var bottomPadding: CGFloat = 0
            if ignoreHandler {
                if positionVisibilityMap[.topLeft]! || positionVisibilityMap[.topRight]! {
                    topPadding = _handleSize / 2
                }
                if positionVisibilityMap[.topLeft]! || positionVisibilityMap[.bottomLeft]! {
                    leftPadding = _handleSize / 2
                }
                if positionVisibilityMap[.bottomRight]! || positionVisibilityMap[.topRight]! {
                    rightPadding = _handleSize / 2
                }
                if positionVisibilityMap[.bottomRight]! || positionVisibilityMap[.bottomLeft]! {
                    bottomPadding = _handleSize / 2
                }
            }
            
            if x < frame.width / 2 - leftPadding + frameInSuperview.origin.x {
                x = frame.width / 2 - leftPadding + frameInSuperview.origin.x
            }
            
            if y < frame.height / 2 - topPadding + frameInSuperview.origin.y {
                y = frame.height / 2 - topPadding + frameInSuperview.origin.y
            }
            
            if x > frameInSuperview.width - frame.width / 2 + rightPadding + frameInSuperview.origin.x {
                x = frameInSuperview.width - frame.width / 2 + rightPadding + frameInSuperview.origin.x
            }
            
            if y > frameInSuperview.height - frame.height / 2 + bottomPadding + frameInSuperview.origin.y {
                y = frameInSuperview.height - frame.height / 2 + bottomPadding + frameInSuperview.origin.y
            }
        }
        
        self.center = CGPoint(x: x, y: y)
    }
    
    @objc func handleRotateGesture(_ recognizer: UIPanGestureRecognizer) {
        let touchLocation = recognizer.location(in: superview)
        let center = self.center
        
        switch recognizer.state {
        case .began:
            deltaAngle = CGFloat(atan2f(Float(touchLocation.y - center.y), Float(touchLocation.x - center.x - self.transform.angle)))
            initialBounds = self.bounds
            initialDistance = distance(from: center, to: touchLocation)
            self.delegate?.stickerViewDidBeginRotating?(self)
        case .changed:
            let angle = atan2f(Float(touchLocation.y - center.y), Float(touchLocation.x - center.x))
            let angleDiff = deltaAngle - CGFloat(angle)
            self.transform = CGAffineTransform(rotationAngle: -angleDiff)
            
            var scale = distance(from: center, to: touchLocation) / initialDistance
            let minimumScale = self._minimumSize / min(initialBounds.width, initialBounds.height)
            let maximumScale = self._maximumSize / max(initialBounds.width, initialBounds.height)
            scale = min(max(scale, minimumScale), maximumScale)
            if shouldScaleContent {
                self.contentView.transform = CGAffineTransform(scaleX: scale, y: scale)
                
                self.set(position: .topLeft, for: positionHandlerMap[.topLeft]!)
                self.set(position: .topRight, for: positionHandlerMap[.topRight]!)
                self.set(position: .bottomLeft, for: positionHandlerMap[.bottomLeft]!)
                self.set(position: .bottomRight, for: positionHandlerMap[.bottomRight]!)
            }
            else {
                self.bounds = initialBounds.scale(w: scale, h: scale)
            }
            self.setNeedsDisplay()
            
            self.delegate?.stickerViewDidChangeRotating?(self, angle: CGFloat(angle), scale: scale)
        case .ended:
            delegate?.stickerViewDidEndRotating?(self)
        default:
            break
        }
    }
    
    @objc func handleCloseGesture(_ recognizer: UITapGestureRecognizer) {
        removeFromSuperview()
        delegate?.stickerViewDidClose?(self)
    }
    
    @objc func handleFlipXGesture(_ recognizer: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.35) {
            self.contentView?.flipX()
        }
    }
    
    @objc func handleFlipYGesture(_ recognizer: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.35) {
            self.contentView?.flipY()
        }
    }
    
    @objc func handleTapGesture(_ recognizer: UITapGestureRecognizer) {
        delegate?.stickerViewDidTap?(self)
    }
    
    func layoutDashedLineBorder() {
        dashedLineBorder.bounds = contentView.bounds
        dashedLineBorder.position = CGPoint(x: contentView.frame.width / 2, y: contentView.frame.height / 2)
        let path = UIBezierPath.init(roundedRect: contentView.bounds, cornerRadius: 0)
        dashedLineBorder.path = path.cgPath
        setNeedsDisplay()
    }
    
    private func calculateFrameWhileZooming(in view: UIView, scale: CGFloat, estimatedFrame: CGRect) -> CGRect {
        var expectedBounds = estimatedFrame
        let oldHeight = expectedBounds.height
        let oldWidth = expectedBounds.width
        let maxResize = max(oldHeight / view.frame.height, oldWidth / view.frame.width)
        if oldHeight > view.frame.height && maxResize == oldHeight / view.frame.height {
            expectedBounds.size.height = view.frame.height
            expectedBounds.size.width = oldWidth / oldHeight * view.frame.height
        }
        
        if oldWidth > view.frame.width && maxResize == oldWidth / view.frame.width {
            expectedBounds.size.width = view.frame.width
            expectedBounds.size.height = oldHeight / oldWidth * view.frame.width
        }
        
        return expectedBounds
    }
}

extension RCStickerView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
