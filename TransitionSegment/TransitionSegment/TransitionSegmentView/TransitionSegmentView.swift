//
//  TransitionSegmentView.swift
//  TransitionSegment
//
//  Created by wuliupai on 16/9/21.
//  Copyright © 2016年 wuliu. All rights reserved.
//

import UIKit

let widthAddition:CGFloat = 20.0
let heightAddtion:CGFloat = 16.0
let cornerRadius:CGFloat = 6.0

let maxScrollSize: Int = 10_000_000
let initialOffset: Int = 5_000_000

let tagAddition = 100

struct SegmentConfigure {
    
    var textSelColor:UIColor
    
    var highlightColor:UIColor
    
    var titles:[String]
}


class TransitionSegmentView: UIView,UIScrollViewDelegate {


    var configure: SegmentConfigure!{
        
        didSet{
            self.configUI()
        }
    }
    
    typealias SegmentClosureType = (Int)->Void
    
    //闭包回调方法
    public var scrollClosure:SegmentClosureType?
    
    //字体非选中状态颜色
    private var textNorColor:UIColor = UIColor.black
    
    //字体大小
    private var textFont:CGFloat = 14.0
    
    //底部scrollview容器
    private var bottomContainer:UIScrollView?
    
    //高亮区域
    private var highlightView:UIView?
    
    //顶部scrollView容器
    private var topContainer:UIScrollView?
    
    private var lastContentOffset: CGPoint = CGPoint.zero
    private var leftBoundary: Int = 0
    private var rightBoundary: Int = 0
    private var totalWidthForAllTabs: Int = 0
    private var leftmostLabel: UILabel?
    private var rightmostLabel: UILabel?
    private var tabLabels: [UILabel]?
    
    public var currentTabIndex: Int
    
    
    
    
    init(frame: CGRect,configure:SegmentConfigure) {
        
        currentTabIndex = 0
        tabLabels = []
        
        super.init(frame:frame)
        
        
        self.configure = configure
        
        self.configUI()
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    
    //初始化UI
    func configUI() {
        
        let rect = CGRect(x:0,y:0,width:frame.width,height:frame.height)
        
        bottomContainer = UIScrollView.init(frame:rect)
        topContainer = UIScrollView.init(frame: rect)
        highlightView = UIView.init()
        highlightView?.layer.masksToBounds = false
        
        self.configScrollView()
        
        self.addSubview(bottomContainer!)
        bottomContainer?.addSubview(highlightView!)
        highlightView?.addSubview(topContainer!)
        
    }
    
    //初始化scrollview容器
    func configScrollView()  {
        
        
        for view in (bottomContainer?.subviews)! {
            
            if view .isEqual(highlightView) {
                return
            }else{
                view .removeFromSuperview()
            }
        }
        
        for view in (topContainer?.subviews)! {
            view .removeFromSuperview()
        }
        
        highlightView?.backgroundColor = configure.highlightColor
        self.createBottomLabels(scrollView: bottomContainer!, titleArray: configure.titles,isHighlight:false)
        self.createBottomLabels(scrollView: topContainer!, titleArray: configure.titles,isHighlight:true)
        
        
        // Allow infinite scrolling
        bottomContainer!.delegate = self
        bottomContainer?.decelerationRate = UIScrollViewDecelerationRateFast
        
        let contentSize = CGSize(width: CGFloat(maxScrollSize), height: frame.height)
        bottomContainer!.contentSize = contentSize
        
        let contentOffset = CGPoint(x:initialOffset, y:0)
        bottomContainer!.setContentOffset(contentOffset, animated: false)
        
        topContainer?.isScrollEnabled = false
        
        totalWidthForAllTabs = rightBoundary-leftBoundary
    }

    //对scrollview容器进行设置
    func createBottomLabels(scrollView:UIScrollView,titleArray:[String],isHighlight:Bool) {
        
        var firstX:Int = 0
        if (scrollView.isEqual(bottomContainer)) {
            firstX = initialOffset
            leftBoundary = firstX
        }
        
        scrollView.showsHorizontalScrollIndicator = false
        
        for index in 0..<titleArray.count{
            
            let title:NSString = titleArray[index] as NSString
            
            let dict = [NSFontAttributeName:UIFont.systemFont(ofSize: textFont)]
            //富文本自己算label宽度和高度
            let itemWidth = Int(title.size(attributes: dict).width + widthAddition)
            
            let label = UILabel.init()
            label.frame = CGRect(x:CGFloat(firstX),y:0,width:CGFloat(itemWidth),height:self.frame.height)
            label.text = title as String
            label.textAlignment = NSTextAlignment.center
            
            if isHighlight {
                
                label.font = UIFont.systemFont(ofSize:textFont+1)
                label.textColor = configure.textSelColor
                
            }else{
                
                label.font = UIFont.systemFont(ofSize:textFont)
                label.textColor = textNorColor
                label.isUserInteractionEnabled = true
                label.tag = index + tagAddition;
                
                let gesture = UITapGestureRecognizer.init(target: self, action: #selector(tap))
                label.addGestureRecognizer(gesture)
                
                
                if index == 0 {
                    highlightView?.frame = label.frame
                    self.clipView(view: highlightView!)
                }
                
            }
            
            firstX += itemWidth
            scrollView.contentSize = CGSize(width:firstX,height:0)
            
            if (scrollView.isEqual(bottomContainer)) {
                
                tabLabels?.append(label)
                
                if (0 == index) {
                    leftmostLabel = label
                }
                else if (titleArray.count-1 == index) {
                    rightmostLabel = label
                }
                
                rightBoundary = Int(label.frame.maxX)
            }
            
            scrollView.addSubview(label)
        }
    }
    
    //设置闭包
    func setScrollClosure(tempClosure:@escaping SegmentClosureType) {
        
        self.scrollClosure = tempClosure
        
    }
    
    //点击手势方法
    func tap(sender:UITapGestureRecognizer) {
        
        let item:UILabel = sender.view as! UILabel
        currentTabIndex = item.tag-tagAddition
        
        self.scrollClosure!(currentTabIndex)
        
    }
    
    //scrollViewDidScroll调用
    func segmentWillMove(point:CGPoint) {
        
        let index = Int(point.x/screenWidth)
        let remainder = point.x/screenWidth - CGFloat(index)
        
        for view in (bottomContainer?.subviews)! {
            
            if index == (view.tag - tagAddition) {
                
                
                // 判断bottomContainer 是否需要移动
                var offsetx = Int(view.center.x - screenWidth/2)
                
                let offsetMax = maxScrollSize
                
                if offsetx < 0 {
                    offsetx = 0
                }else if offsetx > offsetMax{
                    
                    offsetx = offsetMax
                }
                let bottomPoint = CGPoint(x:offsetx,y:0)
                
                bottomContainer?.setContentOffset(bottomPoint, animated: false)
                
                //调整高亮区域的frame
                highlightView?.frame = view.frame
                highlightView?.x = CGFloat(Int(view.x + view.frame.width*remainder))
                
                //获取下一个label的宽度
                let nextView = bottomContainer?.subviews[index+1]
                highlightView?.width = CGFloat(Int((nextView?.width)!*remainder + view.width * (1-remainder)))
                
                
                //裁剪高亮区域
                self.clipView(view: highlightView!)
                
                self.adjustTopContainerOffsetAccordingToHighlightView()
            }
        }
    }
    
    
    //scrollViewDidEndScrollingAnimation方法调用
    func segmentDidEndMove(point:CGPoint)  {
        //四舍五入
        let index = lroundf(Float(point.x/screenWidth))
        
        for view in (bottomContainer?.subviews)! {
            
            if index == (view.tag - tagAddition) {
                
                //调整高亮区域的frame
                highlightView?.frame = view.frame
                self.adjustTopContainerOffsetAccordingToHighlightView()
                
                
                // 判断bottomContainer 是否需要移动
                var offsetx = Int(view.centerX - screenWidth/2)
                
                let offsetMax = maxScrollSize
                
                if offsetx < 0 {
                    offsetx = 0
                }else if offsetx > offsetMax{
                    
                    offsetx = offsetMax
                }
                let bottomPoint = CGPoint(x:offsetx,y:0)
                
                bottomContainer?.setContentOffset(bottomPoint, animated: true)
                
            }
        }
        
    }
    
    //切割高亮区域
    func clipView(view:UIView)  {
        
        let rect = CGRect(x:widthAddition/4,y:heightAddtion/4,width:view.width-widthAddition/2,height:view.height-heightAddtion/2)
        
        let bezierPath = UIBezierPath.init(roundedRect: rect, cornerRadius: cornerRadius)
        let maskLayer = CAShapeLayer()
        maskLayer.path = bezierPath.cgPath
        view.layer.mask = maskLayer
        
        
    }

    
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let contentOffset = scrollView.contentOffset
        
        if (contentOffset.x < 0) {
            return
        }
        
        var isMovingRightToLeft = false
        if (contentOffset.x > lastContentOffset.x) {
            isMovingRightToLeft = true
        }
        lastContentOffset = contentOffset
        
        
        self.relocateUIComponentsOf(bottomContainer!, isMovingRightToLeft: isMovingRightToLeft)
    }
    
    
    private func relocateUIComponentsOf(_ container:UIScrollView, isMovingRightToLeft:Bool) {
        
        guard totalWidthForAllTabs > 0 else {
            return
        }
        
        let contentOffset = container.contentOffset
        
        // using some extra padding for early decision making
        let safetyPadding: CGFloat = 10
        let leadingEdgeOfRightmostLabel = rightmostLabel!.frame.minX-safetyPadding
        let trailingEdgeOfLeftmostLabel = leftmostLabel!.frame.maxX+safetyPadding
        
        
        if (isMovingRightToLeft) {
            
            if (contentOffset.x > trailingEdgeOfLeftmostLabel) {
                print ("Relocate \(leftmostLabel!.text) to right")
                
                leftBoundary = Int(leftmostLabel!.frame.maxX)
                
                var frame = leftmostLabel!.frame
                frame.origin.x = CGFloat(rightBoundary)
                leftmostLabel!.frame = frame
                
                rightBoundary = Int(frame.maxX)
                
                let firstLabel = tabLabels?.first
                tabLabels = Array(tabLabels!.dropFirst())
                tabLabels?.append(firstLabel!)
                
                print("leftBoundary = \(leftBoundary), rightBoundary = \(rightBoundary), view = \(leftmostLabel)")
            }
            
        } else {
            
            if (contentOffset.x+screenWidth < leadingEdgeOfRightmostLabel) {
                print ("Relocate \(rightmostLabel!.text) to left")
                
                rightBoundary = Int(rightmostLabel!.frame.minX)
                
                var frame = rightmostLabel!.frame
                frame.origin.x = CGFloat(leftBoundary - Int(rightmostLabel!.frame.size.width))
                rightmostLabel!.frame = frame
                
                leftBoundary = Int(frame.minX)
                
                let lastLabel = tabLabels?.last
                tabLabels = Array(tabLabels!.dropLast())
                tabLabels?.insert(lastLabel!, at: 0)
                
                print("leftBoundary = \(leftBoundary), rightBoundary = \(rightBoundary), view = \(rightmostLabel)")
            }
        }
        
        leftmostLabel = tabLabels?.first
        rightmostLabel = tabLabels?.last
        
        assert(totalWidthForAllTabs == rightBoundary-leftBoundary)
        
        guard let selectedView = bottomContainer?.viewWithTag(tagAddition+currentTabIndex) else {
            return
        }
        
        highlightView?.frame = selectedView.frame
        self.clipView(view: highlightView!)
        
        self.adjustTopContainerOffsetAccordingToHighlightView()
    }
    
    
    private func adjustTopContainerOffsetAccordingToHighlightView() {
        
        var hightlightViewOffset: CGFloat = (highlightView?.frame.minX)!
        
        if (hightlightViewOffset >= CGFloat(initialOffset)) {
            hightlightViewOffset -= CGFloat(initialOffset)
            hightlightViewOffset = hightlightViewOffset.truncatingRemainder(dividingBy: CGFloat(totalWidthForAllTabs))
        }
        else {
            hightlightViewOffset = CGFloat(initialOffset)-hightlightViewOffset
            hightlightViewOffset = hightlightViewOffset.truncatingRemainder(dividingBy: CGFloat(totalWidthForAllTabs))
            
            if (hightlightViewOffset > 0) {
                hightlightViewOffset = CGFloat(totalWidthForAllTabs)-hightlightViewOffset
            }
        }
        
        let topPoint = CGPoint(x:hightlightViewOffset, y:0)
        topContainer?.setContentOffset(topPoint, animated: false)
    }
}
