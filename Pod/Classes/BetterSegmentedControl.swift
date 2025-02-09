//
//  BetterSegmentedControl.swift
//
//  Created by George Marmaridis on 01/04/16.
//  Copyright © 2016 George Marmaridis. All rights reserved.
//

import Foundation

@IBDesignable open class BetterSegmentedControl: UIControl {
    private class IndicatorView: UIView {
        // MARK: Properties
        fileprivate let segmentMaskView = UIView()
        fileprivate var cornerRadius: CGFloat = 0 {
            didSet {
                layer.cornerRadius = cornerRadius
                segmentMaskView.layer.cornerRadius = cornerRadius
            }
        }
        override open var frame: CGRect {
            didSet {
                segmentMaskView.frame = frame
            }
        }
        
        // MARK: Lifecycle
        init() {
            super.init(frame: CGRect.zero)
            finishInit()
        }
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            finishInit()
        }
        private func finishInit() {
            layer.masksToBounds = true
            segmentMaskView.backgroundColor = .black
        }
    }
    
    // MARK: Constants
    private struct Animation {
        static let withBounceDuration: TimeInterval = 0.3
        static let springDamping: CGFloat = 0.75
        static let withoutBounceDuration: TimeInterval = 0.2
    }
        
    // MARK: Properties
    /// The selected index
    public private(set) var index: UInt? = 0
    /// The segments available for selection
    public var segments: [BetterSegmentedControlSegment] {
        didSet {
            guard segments.count >= 1 else {
                return
            }
            
            separatorsView.subviews.forEach { $0.removeFromSuperview() }
            normalSegmentsView.subviews.forEach { $0.removeFromSuperview() }
            selectedSegmentsView.subviews.forEach { $0.removeFromSuperview() }
            
            for (index, segment) in segments.enumerated() {
                normalSegmentsView.addSubview(segment.normalView)
                selectedSegmentsView.addSubview(segment.selectedView)
                if showsSeparators && index > 0 {
                    separatorsView.addSubview(newSeparator())
                }
            }
            
            setNeedsLayout()
        }
    }
    /// A list of options to configure the control with
    public var options: [BetterSegmentedControlOption]? {
        get { return nil }
        set {
            guard let options = newValue else {
                return
            }
            
            for option in options {
                switch option {
                case let .indicatorViewBackgroundColor(value):
                    indicatorViewBackgroundColor = value
                case let .indicatorViewInset(value):
                    indicatorViewInset = value
                case let .indicatorViewBorderWidth(value):
                    indicatorViewBorderWidth = value
                case let .indicatorViewBorderColor(value):
                    indicatorViewBorderColor = value
                case let .alwaysAnnouncesValue(value):
                    alwaysAnnouncesValue = value
                case let .announcesValueImmediately(value):
                    announcesValueImmediately = value
                case let .panningDisabled(value):
                    panningDisabled = value
                case let .backgroundColor(value):
                    backgroundColor = value
                case let .cornerRadius(value):
                    cornerRadius = value
                case let .bouncesOnChange(value):
                    bouncesOnChange = value
                }
            }
        }
    }
    /// Whether the indicator should animate the change on user selection by tap. Defaults to true
    @IBInspectable public var animatesChangeOnTap: Bool = true
    /// Whether the selected item is unselected when tapping it. Defaults to false
    @IBInspectable public var deselectOnSelectedSegmentTap: Bool = false
    /// Whether the indicator should bounce when selecting a new index. Defaults to true
    @IBInspectable public var bouncesOnChange: Bool = true
    /// Whether the the control should always send the .ValueChanged event, regardless of the index remaining unchanged after interaction. Defaults to false
    @IBInspectable public var alwaysAnnouncesValue: Bool = false
    /// Whether to send the .ValueChanged event immediately or wait for animations to complete. Defaults to true
    @IBInspectable public var announcesValueImmediately: Bool = true
    /// Whether the the control should ignore pan gestures. Defaults to false
    @IBInspectable public var panningDisabled: Bool = false
    /// The control's and indicator's corner radii
    @IBInspectable public var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            indicatorView.cornerRadius = newValue - indicatorViewInset
            segmentViews.forEach { $0.layer.cornerRadius = indicatorView.cornerRadius }
        }
    }
    /// The indicator view's background color
    @IBInspectable public var indicatorViewBackgroundColor: UIColor? {
        get {
            return indicatorView.backgroundColor
        }
        set {
            indicatorView.backgroundColor = newValue
        }
    }
    /// The indicator view's inset. Defaults to 2.0
    @IBInspectable public var indicatorViewInset: CGFloat = 2.0 {
        didSet { setNeedsLayout() }
    }
    /// The indicator view's border width
    @IBInspectable public var indicatorViewBorderWidth: CGFloat {
        get {
            return indicatorView.layer.borderWidth
        }
        set {
            indicatorView.layer.borderWidth = newValue
        }
    }
    /// The indicator view's border color
    @IBInspectable public var indicatorViewBorderColor: UIColor? {
        get {
            guard let color = indicatorView.layer.borderColor else {
                return nil
            }
            return UIColor(cgColor: color)
        }
        set {
            indicatorView.layer.borderColor = newValue?.cgColor
        }
    }
    
    public var showsSeparators: Bool = false {
        didSet {
            guard showsSeparators != oldValue else { return }
            separatorsView.subviews.forEach { $0.removeFromSuperview() }
            if showsSeparators {
                for (index, _) in segments.enumerated() {
                    if index > 0 {
                        separatorsView.addSubview(newSeparator())
                    }
                }
                setNeedsLayout()
            }
        }
    }
    public var separatorColor: UIColor = .clear {
        didSet {
            separatorsView.subviews.forEach { $0.backgroundColor = separatorColor }
        }
    }
    public var separatorWidth: CGFloat = 1 {
        didSet { setNeedsLayout() }
    }
    public var separatorHeight: CGFloat = 10 {
        didSet { setNeedsLayout() }
    }
    
    // MARK: Private properties
    private let normalSegmentsView = UIView()
    private let selectedSegmentsView = UIView()
    private let separatorsView = UIView()
    private let indicatorView = IndicatorView()
    private var initialIndicatorViewFrame: CGRect?

    private var tapGestureRecognizer: UITapGestureRecognizer!
    private var panGestureRecognizer: UIPanGestureRecognizer!
    
    private var width: CGFloat { return bounds.width }
    private var height: CGFloat { return bounds.height }
    private var normalSegmentCount: Int { return normalSegmentsView.subviews.count }
    private var normalSegments: [UIView] { return normalSegmentsView.subviews }
    private var selectedSegments: [UIView] { return selectedSegmentsView.subviews }
    private var segmentViews: [UIView] { return normalSegments + selectedSegments}
    private var totalInsetSize: CGFloat { return indicatorViewInset * 2.0 }
    private lazy var defaultSegments: [BetterSegmentedControlSegment] = {
        return [LabelSegment(text: "First"), LabelSegment(text: "Second")]
    }()
    
    // MARK: Lifecycle
    public init(frame: CGRect,
                segments: [BetterSegmentedControlSegment],
                index: UInt? = 0,
                options: [BetterSegmentedControlOption]? = nil) {
        self.index = index
        self.segments = segments
        super.init(frame: frame)
        completeInit()
        self.options = options
    }
    required public init?(coder aDecoder: NSCoder) {
        self.index = 0
        self.segments = [LabelSegment(text: "First"), LabelSegment(text: "Second")]
        super.init(coder: aDecoder)
        completeInit()
    }
    @available(*, unavailable, message: "Use init(frame:segments:index:options:) instead.")
    convenience override public init(frame: CGRect) {
        self.init(frame: frame,
                  segments: [LabelSegment(text: "First"), LabelSegment(text: "Second")])
    }

    @available(*, unavailable, message: "Use init(frame:segments:index:options:) instead.")
    convenience init() {
        self.init(frame: .zero,
                  segments: [LabelSegment(text: "First"), LabelSegment(text: "Second")])
    }
    private func completeInit() {
        layer.masksToBounds = true
        
        normalSegmentsView.clipsToBounds = true
        addSubview(normalSegmentsView)
        addSubview(separatorsView)
        addSubview(indicatorView)
        selectedSegmentsView.clipsToBounds = true
        addSubview(selectedSegmentsView)
        selectedSegmentsView.layer.mask = indicatorView.segmentMaskView.layer
        
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(BetterSegmentedControl.tapped(_:)))
        addGestureRecognizer(tapGestureRecognizer)
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(BetterSegmentedControl.panned(_:)))
        panGestureRecognizer.delegate = self
        addGestureRecognizer(panGestureRecognizer)
        
        guard segments.count >= 1 else { return }
        
        for (index, segment) in segments.enumerated() {
            segment.normalView.clipsToBounds = true
            normalSegmentsView.addSubview(segment.normalView)
            segment.selectedView.clipsToBounds = true
            selectedSegmentsView.addSubview(segment.selectedView)
            if showsSeparators && index > 0 {
                separatorsView.addSubview(newSeparator())
            }
        }
        
        setNeedsLayout()
    }
    override open func layoutSubviews() {
        super.layoutSubviews()

        guard normalSegmentCount >= 1 else {
            return
        }
        
        normalSegmentsView.frame = bounds
        separatorsView.frame = bounds
        selectedSegmentsView.frame = bounds
        
        indicatorView.frame = index.map { elementFrame(forIndex: $0) } ?? .zero
        
        for index in 0...normalSegmentCount-1 {
            let frame = elementFrame(forIndex: UInt(index))
            normalSegmentsView.subviews[index].frame = frame
            selectedSegmentsView.subviews[index].frame = frame
            if showsSeparators && index > 0 {
                var sepFrame = CGRect.zero
                sepFrame.size.height = separatorHeight
                sepFrame.origin.x = frame.minX - separatorWidth / 2
                sepFrame.size.width = separatorWidth
                let sep = separatorsView.subviews[index - 1]
                sep.frame = sepFrame
                sep.center.y = separatorsView.center.y
            }
        }
    }
    open override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setDefaultLabelTextSegmentColorsFromInterfaceBuilder()
    }
    open override func awakeFromNib() {
        super.awakeFromNib()
        setDefaultLabelTextSegmentColorsFromInterfaceBuilder()
    }
    private func setDefaultLabelTextSegmentColorsFromInterfaceBuilder() {
        guard let normalLabelSegments = normalSegments as? [UILabel],
            let selectedLabelSegments = selectedSegments as? [UILabel] else {
                return
        }
        
        normalLabelSegments.forEach {
            $0.textColor = indicatorView.backgroundColor
        }
        selectedLabelSegments.forEach {
            $0.textColor = backgroundColor
        }
    }
    
    private func newSeparator() -> UIView {
        let view = UIView()
        view.backgroundColor = separatorColor
        return view
    }
    
    // MARK: Index Setting
    /// Sets the control's index.
    ///
    /// - Parameters:
    ///   - index: The new index
    ///   - canSendEvent: (Optional) Whether the `valueChanged` event should be considered to be fired or not. Overrides `alwaysAnnouncesValue`. Defaults to `true`.
    public func setIndex(_ index: UInt?, animated: Bool = true, canSendEvent: Bool = true) {
        // If nil index, go for it, otherwise check we can select the given index
        guard index.map({ normalSegments.indices.contains(Int($0)) }) ?? true else {
            return
        }
        let oldIndex = self.index
        self.index = index
        moveIndicatorViewToIndex(animated, shouldSendEvent: canSendEvent && (self.index != oldIndex || alwaysAnnouncesValue), oldIndex: oldIndex)
    }

    // MARK: Indicator View Customization
    /// Adds the passed view as a subview to the indicator view
    ///
    /// - Parameter view: The view to be added to the indicator view
    public func addSubviewToIndicator(_ view: UIView) {
        indicatorView.addSubview(view)
    }
    
    // MARK: Animations
    private func moveIndicatorViewToIndex(_ animated: Bool, shouldSendEvent: Bool, oldIndex: UInt? = nil) {
        // Only animate the move if we're moving between two selected sections
        let isMovingBetweenSelectedSegments = index != nil && oldIndex != nil
        if animated && isMovingBetweenSelectedSegments {
            if shouldSendEvent && announcesValueImmediately {
                sendActions(for: .valueChanged)
            }
            UIView.animate(withDuration: bouncesOnChange ? Animation.withBounceDuration : Animation.withoutBounceDuration,
                           delay: 0.0,
                           usingSpringWithDamping: bouncesOnChange ? Animation.springDamping : 1.0,
                           initialSpringVelocity: 0.0,
                           options: [UIView.AnimationOptions.beginFromCurrentState, UIView.AnimationOptions.curveEaseOut],
                           animations: {
                            () -> Void in
                            self.moveIndicatorView()
            }, completion: { (finished) -> Void in
                if finished && shouldSendEvent && !self.announcesValueImmediately {
                    self.sendActions(for: .valueChanged)
                }
            })
        } else {
            moveIndicatorView()

            if shouldSendEvent {
                sendActions(for: .valueChanged)
            }
        }
    }
    
    // MARK: Helpers
    private func elementFrame(forIndex index: UInt) -> CGRect {
        let elementWidth = (width - totalInsetSize) / CGFloat(normalSegmentCount)
        return CGRect(x: CGFloat(index) * elementWidth + indicatorViewInset,
                      y: indicatorViewInset,
                      width: elementWidth,
                      height: height - totalInsetSize)
    }
    private func nearestIndex(toPoint point: CGPoint) -> UInt {
        let distances = normalSegments.map { abs(point.x - $0.center.x) }
        return UInt(distances.index(of: distances.min()!)!)
    }
    private func moveIndicatorView() {
        // Hide if no index by setting zero frame
        let indicatorFrame = self.index.map { normalSegments[Int($0)].frame } ?? .zero
        indicatorView.frame = indicatorFrame
        layoutIfNeeded()
    }
    
    // MARK: Action handlers
    @objc private func tapped(_ gestureRecognizer: UITapGestureRecognizer!) {
        let location = gestureRecognizer.location(in: self)
        let locationIndex = nearestIndex(toPoint: location)
        let toSelect: UInt? = deselectOnSelectedSegmentTap && locationIndex == index ? nil : locationIndex
        setIndex(toSelect, animated: animatesChangeOnTap)
    }
    @objc private func panned(_ gestureRecognizer: UIPanGestureRecognizer!) {
        guard !panningDisabled else {
            return
        }
        
        switch gestureRecognizer.state {
        case .began:
            initialIndicatorViewFrame = indicatorView.frame
        case .changed:
            var frame = initialIndicatorViewFrame!
            frame.origin.x += gestureRecognizer.translation(in: self).x
            frame.origin.x = max(min(frame.origin.x, bounds.width - indicatorViewInset - frame.width), indicatorViewInset)
            indicatorView.frame = frame
        case .ended, .failed, .cancelled:
            setIndex(nearestIndex(toPoint: indicatorView.center))
        default: break
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension BetterSegmentedControl: UIGestureRecognizerDelegate {
    override open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panGestureRecognizer {
            return indicatorView.frame.contains(gestureRecognizer.location(in: self))
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
}
