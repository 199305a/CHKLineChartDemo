//
//  CHKLineChart.swift
//  CHKLineChart
//
//  Created by Chance on 16/9/6.
//  Copyright © 2016年 Chance. All rights reserved.
//

import UIKit



/**
 图表滚动到那个位置
 
 - top: 头部
 - end: 尾部
 - None:  不处理
 */
public enum CHChartViewScrollPosition {
    case top, end, none
}


/// 图表选中的十字y轴显示位置
///
/// - free: 自由就在显示的点上
/// - onClosePrice: 在收盘价上
public enum CHChartSelectedPosition {
    case free
    case onClosePrice
}

/**
 *  K线数据源代理
 */
@objc public protocol CHKLineChartDelegate: class {
    
    /**
     数据源总数
     
     - parameter chart:
     
     - returns:
     */
    func numberOfPointsInKLineChart(chart: CHKLineChartView) -> Int
    
    /**
     数据源索引为对应的对象
     
     - parameter chart:
     - parameter index: 索引位
     
     - returns: K线数据对象
     */
    func kLineChart(chart: CHKLineChartView, valueForPointAtIndex index: Int) -> CHChartItem
    
    /**
     获取图表Y轴的显示的内容
     
     - parameter chart:
     - parameter value:     计算得出的y值
     
     - returns:
     */
    func kLineChart(chart: CHKLineChartView, labelOnYAxisForValue value: CGFloat, atIndex index: Int, section: CHSection) -> String
    
    /**
     获取图表X轴的显示的内容
     
     - parameter chart:
     - parameter index:     索引位
     
     - returns:
     */
    @objc optional func kLineChart(chart: CHKLineChartView, labelOnXAxisForIndex index: Int) -> String
    
    /**
     完成绘画图表
     
     */
    @objc optional func didFinishKLineChartRefresh(chart: CHKLineChartView)
    
    
    /// 配置各个分区小数位保留数
    ///
    /// - parameter chart:
    /// - parameter decimalForSection: 分区
    ///
    /// - returns:
    @objc optional func kLineChart(chart: CHKLineChartView, decimalFormatAt section: Int) -> String

    
    /// 点击图表列响应方法
    ///
    /// - Parameters:
    ///   - chart: 图表
    ///   - index: 点击的位置
    ///   - item: 数据对象
    @objc optional func kLineChart(chart: CHKLineChartView, didSelectAt index: Int, item: CHChartItem)
    
    
    /// 初始化时的显示范围长度
    ///
    /// - Parameter chart: 图表
    @objc optional func initRangeInKLineChart(in chart: CHKLineChartView) -> Int
    
    
    /// 自定义选择点时出现的标签样式
    ///
    /// - Parameters:
    ///   - chart: 图表
    ///   - yAxis: 可给用户自定义的y轴显示标签
    ///   - viewOfXAxis: 可给用户自定义的x轴显示标签
    @objc optional func kLineChart(chart: CHKLineChartView, viewOfYAxis yAxis: UILabel, viewOfXAxis: UILabel)
    
    
    /// 自定义section的头部View显示内容
    ///
    /// - Parameters:
    ///   - chart: 图表
    ///   - section: 分区的索引位
    /// - Returns: 自定义的View
    @objc optional func kLineChart(chart: CHKLineChartView, viewForHeaderInSection section: Int) -> UIView?
    
    /// 自定义section的头部View显示内容
    ///
    /// - Parameters:
    ///   - chart: 图表
    ///   - section: 分区的索引位
    /// - Returns: 自定义的View
    @objc optional func kLineChart(chart: CHKLineChartView, titleForHeaderInSection section: CHSection, index: Int, item: CHChartItem) -> NSAttributedString?
    
    
    /// 切换分区用分页方式展示的线组
    ///
    @objc optional func kLineChart(chart: CHKLineChartView, didFlipPageSeries section: CHSection, series: CHSeries, seriesIndex: Int)
}

open class CHKLineChartView: UIView {
    
    /// MARK: - 常量
    let kMinRange = 13       //最小缩放范围
    let kMaxRange = 133     //最大缩放范围
    let kPerInterval = 4    //缩放的每段间隔
    
    /// MARK: - 成员变量
    @IBInspectable open var upColor: UIColor = UIColor.green     //升的颜色
    @IBInspectable open var downColor: UIColor = UIColor.red     //跌的颜色
    @IBInspectable open var labelFont = UIFont.systemFont(ofSize: 10) 
    @IBInspectable open var lineColor: UIColor = UIColor(white: 0.2, alpha: 1) //线条颜色
    @IBInspectable open var textColor: UIColor = UIColor(white: 0.8, alpha: 1) //文字颜色
    
    open var handlerOfAlgorithms: [CHChartAlgorithmProtocol] = [CHChartAlgorithmProtocol]()
    open var padding: UIEdgeInsets = UIEdgeInsets.zero    //内边距
    open var yAxisShowPosition = CHYAxisShowPosition.right      //显示y的位置，默认右边
    open var isInnerYAxis: Bool = false                     // 是否把y坐标内嵌到图表中
    open var selectedPosition: CHChartSelectedPosition = .onClosePrice         //选中显示y值的位置

    @IBOutlet open weak var delegate: CHKLineChartDelegate?             //代理
    
    open var sections = [CHSection]()
    open var selectedIndex: Int = -1                      //选择索引位
    open var scrollToPosition: CHChartViewScrollPosition = .none  //图表刷新后开始显示位置
    var selectedPoint: CGPoint = CGPoint.zero
    
    //是否可缩放
    open var enablePinch: Bool = true
    //是否可滑动
    open var enablePan: Bool = true
    //是否可点选
    open var enableTap: Bool = true {
        didSet {
            self.showSelection = self.enableTap
        }
    }
    
    /// 是否显示选中的内容
    open var showSelection: Bool = true {
        didSet {
            self.selectedXAxisLabel?.isHidden = !self.showSelection
            self.selectedYAxisLabel?.isHidden = !self.showSelection
            self.selectedYAxisLineView?.isHidden = !self.showSelection
            self.selectedXAxisLineView?.isHidden = !self.showSelection
            self.sightView?.isHidden = !self.showSelection
        }
    }
    
    /// 把X坐标内容显示到哪个索引分区上，默认为-1，表示最后一个，如果用户设置溢出的数值，也以最后一个
    open var showXAxisOnSection: Int = -1
    
    /// 是否显示X轴标签
    open var showXAxisLabel: Bool = true
    
    /// 是否显示所有内容
    open var isShowAll: Bool = false
    
    /// 显示边线上左下有
    open var borderWidthTuple: (top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) = (0.25, 0.25, 0.25, 0.25)
    
    var lineWidth: CGFloat = 0.5
    var plotCount: Int = 0
    var rangeFrom: Int = 0                          //可见区域的开始索引位
    var rangeTo: Int = 0                            //可见区域的结束索引位
    let defaultRange = 77
    open var range: Int = 77                             //显示在可见区域的个数
    
    var datas: [CHChartItem] = [CHChartItem]()      //数据源
    
    open var currentPrinceLineColor = UIColor.orange
    open var currentPriceTextColor = UIColor.orange
    open var selectedLineColor: UIColor = UIColor.white
    open var selectedSightColor: UIColor = UIColor.white
    open var selectedBGColor: UIColor = UIColor(white: 0.4, alpha: 1)    //选中点的显示的框背景颜色
    open var selectedTextColor: UIColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1) //选中点的显示的文字颜色
    var currentPriceLineView: UIView?
    var currentPriceLabel: UILabel?
    var selectedYAxisLineView: UIView?
    var selectedXAxisLineView: UIView?
    var selectedXAxisLabel: UILabel?
    var selectedYAxisLabel: UILabel?
    var sightView: UIView?       //点击出现的准星
    var yAxisLabelHeight: CGFloat = 16
    
    //动力学引擎
    lazy var animator: UIDynamicAnimator = UIDynamicAnimator(referenceView: self)
    
    //动力的作用点
    lazy var dynamicItem = CHDynamicItem()
    
    //滚动图表时用于处理线性减速
    weak var decelerationBehavior: UIDynamicItemBehavior?
    
    //滚动释放后用于反弹回来
    weak var springBehavior: UIAttachmentBehavior?
    
    //减速开始x
    var decelerationStartX: CGFloat = 0
    
    /// 用于图表的图层
    var drawLayer: CHShapeLayer = CHShapeLayer()
    
    /// 点线图层
    var chartModelLayer: CHShapeLayer = CHShapeLayer()
    
    /// 图表数据信息显示层，显示每个分区的数值内容
    var chartInfoLayer: CHShapeLayer = CHShapeLayer()
    
    private var style: CHKLineChartStyle
    
    init(frame: CGRect, style: CHKLineChartStyle) {
        self.style = style
        super.init(frame: frame)
        configureChartStyle()
        configureSublayer()
        initUI()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureChartStyle() {
        backgroundColor = style.backgroundColor
        sections = style.sections
        padding = style.padding
        handlerOfAlgorithms = style.algorithms
        lineColor = style.lineColor
        textColor = style.textColor
        labelFont = style.labelFont
        yAxisShowPosition = style.showYAxisLabel
        selectedLineColor = style.selectedLineColor
        selectedSightColor = style.selectedSightColor
        selectedBGColor = style.selectedBGColor
        selectedTextColor = style.selectedTextColor
        isInnerYAxis = style.isInnerYAxis
        enableTap = style.enableTap
        enablePinch = style.enablePinch
        enablePan = style.enablePan
        showSelection = style.showSelection
        showXAxisOnSection = style.showXAxisOnSection
        isShowAll = style.isShowAll
        showXAxisLabel = style.showXAxisLabel
        borderWidthTuple = style.borderWidth
    }
    
    private func configureSublayer() {
        configureDrawLayer()
        configureSections()
    }
    
    private func configureDrawLayer() {
        let layer = CHShapeLayer()
        layer.lineWidth = lineWidth
        layer.strokeColor = lineColor.cgColor
        layer.fillColor = backgroundColor?.cgColor
        let layerPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: bounds.size.width,height: bounds.size.height), cornerRadius: 0)
        
        // 画左边线
        if borderWidthTuple.left > 0 {
            layerPath.move(to: CGPoint.zero)
            layerPath.addLine(to: CGPoint(x: 0, y: bounds.height - style.xAxisLabelLayerHeight))
            layerPath.close()
        }
        // 画右边线
        if borderWidthTuple.right > 0 {
            layerPath.move(to: CGPoint(x: bounds.width, y: 0))
            layerPath.addLine(to: CGPoint(x: bounds.width, y: bounds.height - style.xAxisLabelLayerHeight))
        }
        
        layer.path = layerPath.cgPath
        drawLayer.addSublayer(layer)
    }
    
    private func configureSections() {
        // 计算实际的显示高度和宽度
        var restHeight = frame.size.height - (padding.top + padding.bottom) - style.xAxisLabelLayerHeight
        let restWidth  = frame.size.width - (padding.left + padding.right)
        
        var total = 0
        for (index, section) in sections.enumerated() {
            section.index = index
            if !section.hidden {
                //如果使用fixHeight，ratios要设置为0
                if section.ratios > 0 {
                    total = total + section.ratios
                }
            }
        }
        
        var offsetY = padding.top
        //计算每个区域的高度，并绘制
        for (index, section) in sections.enumerated() {
            section.index = index
            var heightOfSection: CGFloat = 0
            let widthOfSection = restWidth
            //计算每个区域的高度
            //如果fixHeight大于0，有限使用fixHeight设置高度，
            if section.fixHeight > 0 {
                heightOfSection = section.fixHeight
                restHeight = restHeight - heightOfSection
            } else {
                heightOfSection = restHeight * CGFloat(section.ratios) / CGFloat(total)
            }
            //y轴的标签显示方位
            switch yAxisShowPosition {
            case .left:         //左边显示
                section.padding.left = isInnerYAxis ? section.padding.left : style.yAxisLabelLayerWidth
                section.padding.right = 0
            case .right:        //右边显示
                section.padding.left = 0
                section.padding.right = isInnerYAxis ? section.padding.right : style.yAxisLabelLayerWidth
            case .none:         //都不显示
                section.padding.left = 0
                section.padding.right = 0
            }
            //计算每个section的坐标
            let rect = CGRect(x: 0 + padding.left, y: offsetY, width: widthOfSection, height: heightOfSection)
            section.frame = rect
            section.sectionLayer.frame = rect
            offsetY = offsetY + section.frame.height
            //如果这个分区设置为显示X轴，下一个分区的Y起始位要加上X轴高度
            if showXAxisOnSection == index {
                offsetY = offsetY + style.xAxisLabelLayerHeight
            }
            
            // 注意layer层级
            configureSectionLayer(in: section)
            let xAxisTextRects = configureXAxisReferenceLayer(in: section)
            let yAxisTextRects = configureYAxisReferenceLayer(in: section)
            section.configureSeriesLayer()
            configureXAxisTextLayers(in: section, rects: xAxisTextRects)
            configureYAxisTextLayers(in: section, rects: yAxisTextRects)
            section.configureTitleLayer()
        }
    }
    
    private func configureSectionLayer(in section: CHSection) {
        let borderLayer = CHShapeLayer()
        borderLayer.lineWidth = lineWidth
        borderLayer.strokeColor = lineColor.cgColor
        
        let borderPath = UIBezierPath()
        // 画顶部边线
        if borderWidthTuple.top > 0 {
            borderPath.move(to: CGPoint(x: 0, y: section.frame.minY))
            borderPath.addLine(to: CGPoint(x: bounds.width, y: section.frame.minY))
        }
        // 画底部边线
        if borderWidthTuple.bottom > 0 {
            borderPath.move(to: CGPoint(x: 0, y: section.frame.maxY))
            borderPath.addLine(to: CGPoint(x: bounds.width, y: section.frame.maxY))
        }

        borderLayer.path = borderPath.cgPath
        drawLayer.addSublayer(borderLayer)
        drawLayer.addSublayer(section.sectionLayer)
        drawLayer.addSublayer(section.titleLayer)
    }
    
    private func configureXAxisReferenceLayer(in section: CHSection) -> [CGRect] {
        // 每个纵向辅助线的间隔
        let tickSpace: CGFloat = (section.frame.size.width - section.padding.left - section.padding.right) / CGFloat(section.xAxis.tickInterval)
        let textSize = CGSize(width: tickSpace, height: style.xAxisLabelLayerHeight)
        var showXAxisReference = false
        var textRects = [CGRect]()
        
        for i in 0...section.xAxis.tickInterval {
            let verticalLineX = section.frame.origin.x + section.padding.left + tickSpace * CGFloat(i)
            let textRect = CGRect(x: verticalLineX - textSize.width / 2, y: section.frame.maxY, width: textSize.width, height: textSize.height)
            textRects.append(textRect)
            
            guard i != 0 || i != section.xAxis.tickInterval else { continue }
            // 绘制辅助线
            let referencePath = UIBezierPath()
            let referenceLayer = CHShapeLayer()
            referenceLayer.lineWidth = self.lineWidth
            // 处理辅助线样式
            switch section.xAxis.referenceStyle {
            case let .dash(color: dashColor, pattern: pattern):
                referenceLayer.strokeColor = dashColor.cgColor
                referenceLayer.lineDashPattern = pattern
                showXAxisReference = true
            case let .solid(color: solidColor):
                referenceLayer.strokeColor = solidColor.cgColor
                showXAxisReference = true
            default:
                showXAxisReference = false
            }
            //需要画x轴上的辅助线
            if showXAxisReference {
                referencePath.move(to: CGPoint(x: verticalLineX, y: 0))
                referencePath.addLine(to: CGPoint(x: verticalLineX, y: section.frame.height))
                referenceLayer.path = referencePath.cgPath
                section.sectionLayer.addSublayer(referenceLayer)
            }
        }
        
        return textRects
    }
    
    private func configureXAxisTextLayers(in section: CHSection, rects: [CGRect]) {
        for rect in rects {
            let textLayer = CHTextLayer()
            textLayer.frame = rect
            textLayer.fontSize = labelFont.pointSize
            textLayer.foregroundColor =  textColor.cgColor
            textLayer.backgroundColor = UIColor.clear.cgColor
            textLayer.contentsScale = UIScreen.main.scale
            textLayer.alignmentMode = .center
            section.xAxisTextLayers.append(textLayer)
            drawLayer.addSublayer(textLayer)
        }
    }
    
    private func updateXAxisTexts(in section: CHSection) {
        guard isXAxisTextsShow(in: section), section.xAxis.tickInterval + 1 == section.xAxisTextLayers.count else { return }
        
        // 每个点的宽度（包括左右空白）
        let plotWidth = (section.frame.size.width - section.padding.left - section.padding.right) / CGFloat(rangeTo - rangeFrom)
        // 每个纵向辅助线的间隔
        let tickSpace: CGFloat = (section.frame.size.width - section.padding.left - section.padding.right) / CGFloat(section.xAxis.tickInterval)
        for index in 0...section.xAxis.tickInterval {
            let verticalLineX = section.frame.origin.x + section.padding.left + tickSpace * CGFloat(index)
            let textIndex = Int(verticalLineX / plotWidth) + rangeFrom
            let text = delegate?.kLineChart?(chart: self, labelOnXAxisForIndex: textIndex) ?? ""
            let textLayer = section.xAxisTextLayers[index]
            textLayer.string = text
        }
    }
    
    private func isXAxisTextsShow(in section: CHSection) -> Bool {
        if showXAxisOnSection == -1 {
            return  sections.last == section
        } else {
            return sections.firstIndex(of: section) == showXAxisOnSection
        }
    }
    
    private func configureYAxisReferenceLayer(in section: CHSection) -> [CGRect] {
        var originX: CGFloat = 0
        var originY: CGFloat = 0
        var showYAxisReference = true
        
        // 控制y轴的label在左还是右显示
        switch yAxisShowPosition {
        case .left:
            originX = section.frame.origin.x - 3 * (isInnerYAxis ? -1 : 1)
        case .right:
            originX = section.frame.maxX - style.yAxisLabelLayerWidth + 3 * (isInnerYAxis ? -1 : 1)
        case .none: break
        }
        
        let showXAxisTexts = isXAxisTextsShow(in: section)
        let xAxisTextsHeight = showXAxisTexts ? style.xAxisLabelLayerHeight : 0
        let restHeight = section.frame.size.height - (section.padding.top + section.padding.bottom) - xAxisTextsHeight
        let step = restHeight / CGFloat(section.yAxis.tickInterval)
        var textRects = [CGRect]()
        
        for index in 0...section.yAxis.tickInterval {
            if index == section.yAxis.tickInterval && !section.yAxis.showLast {
                break
            }
            
            let referenceY = step * CGFloat(index) + section.padding.top
            if isInnerYAxis {
                // y轴标签向内显示，为了不挡住辅助线，所以把y轴的数值位置向上移一些
                originY = referenceY - 14
            } else {
                originY = referenceY - 7
            }
            let textRect = CGRect(x: originX, y: originY, width: style.yAxisLabelLayerWidth, height: 12)
            textRects.append(textRect)
            
            let referencePath = UIBezierPath()
            let referenceLayer = CHShapeLayer()
            referenceLayer.lineWidth = lineWidth
            // 处理辅助线样式
            switch section.yAxis.referenceStyle {
            case let .dash(color: dashColor, pattern: pattern):
                referenceLayer.strokeColor = dashColor.cgColor
                referenceLayer.lineDashPattern = pattern
                showYAxisReference = true
            case let .solid(color: solidColor):
                referenceLayer.strokeColor = solidColor.cgColor
                showYAxisReference = true
            default:
                showYAxisReference = false
            }
            // 绘制辅助线
            if showYAxisReference {
                referencePath.move(to: CGPoint(x: section.frame.origin.x + section.padding.left, y: referenceY))
                referencePath.addLine(to: CGPoint(x: section.frame.origin.x + section.frame.size.width - section.padding.right, y: referenceY))
                referenceLayer.path = referencePath.cgPath
                section.sectionLayer.addSublayer(referenceLayer)
            }
        }
        return textRects
    }
    
    private func configureYAxisTextLayers(in section: CHSection, rects: [CGRect]) {
        var alignmentMode: CATextLayerAlignmentMode
        switch yAxisShowPosition {
        case .left:
            alignmentMode = isInnerYAxis ? .left : .right
        case .right:
            alignmentMode = isInnerYAxis ? .right : .left
        case .none:
            alignmentMode = .left
        }
        
        for rect in rects {
            let textLayer = CHTextLayer()
            textLayer.frame = rect
            textLayer.fontSize = labelFont.pointSize
            textLayer.foregroundColor =  textColor.cgColor
            textLayer.backgroundColor = UIColor.clear.cgColor
            textLayer.alignmentMode = alignmentMode
            textLayer.contentsScale = UIScreen.main.scale
            section.yAxisTextLayers.append(textLayer)
            section.sectionLayer.addSublayer(textLayer)
        }
    }
    
    private func updateYAxisTexts(in section: CHSection) {
        let referenceValues = getReferenceValues(in: section)
        guard referenceValues.count == section.yAxisTextLayers.count else { return }
        
        for (index, referenceValue) in referenceValues.enumerated() {
            let textLayer = section.yAxisTextLayers[index]
            let text = delegate?.kLineChart(chart: self, labelOnYAxisForValue: referenceValue, atIndex: index, section: section) ?? ""
            textLayer.string = text
        }
    }
    
    private func getReferenceValues(in section: CHSection) -> [CGFloat] {
        var referenceValues = Set<CGFloat>()
        let yaxis = section.yAxis
        // 计算y轴的标签及辅助线分几段
        let step = (yaxis.max - yaxis.min) / CGFloat(yaxis.tickInterval)
        // 从base值绘制Y轴标签到最大值
        var i = 0
        var referenceValue = yaxis.baseValue + CGFloat(i) * step
        while referenceValue <= yaxis.max && i <= yaxis.tickInterval {
            referenceValues.insert(referenceValue)
            i =  i + 1
            referenceValue = yaxis.baseValue + CGFloat(i) * step
        }
        i = 0
        referenceValue = yaxis.baseValue - CGFloat(i) * step
        while referenceValue >= yaxis.min && i <= yaxis.tickInterval {
            referenceValues.insert(referenceValue)
            i =  i + 1
            referenceValue = yaxis.baseValue - CGFloat(i) * step
        }
        var sortedValue = referenceValues.sorted(by: >)
        // 是否不显示最后一个标签及辅助线
        if !section.yAxis.showLast {
            sortedValue.removeLast()
        }
        return sortedValue
    }
    
    /**
     初始化UI
     
     - returns:
     */
    fileprivate func initUI() {
        
        //绘画图层
        self.layer.addSublayer(self.drawLayer)
        
        self.isMultipleTouchEnabled = true
        
        currentPriceLineView = UIView()
        currentPriceLineView?.isHidden = true
        addSubview(currentPriceLineView!)
        
        currentPriceLabel = UILabel()
        currentPriceLabel?.backgroundColor = UIColor.white
        currentPriceLabel?.isHidden = true
        currentPriceLabel?.font = labelFont
        currentPriceLabel?.minimumScaleFactor = 0.5
        currentPriceLabel?.lineBreakMode = .byClipping
        currentPriceLabel?.adjustsFontSizeToFitWidth = true
        currentPriceLabel?.textColor = currentPriceTextColor
        currentPriceLabel?.textAlignment = .center
        addSubview(currentPriceLabel!)
        
        //初始化点击选择的辅助线显示
        self.selectedYAxisLineView = UIView(frame: CGRect(x: 0, y: 0, width: lineWidth, height: 0))
        self.selectedYAxisLineView?.backgroundColor = selectedLineColor
        self.selectedYAxisLineView?.isHidden = true
        self.addSubview(self.selectedYAxisLineView!)
        
        self.selectedXAxisLineView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: lineWidth))
        self.selectedXAxisLineView?.backgroundColor = selectedLineColor
        self.selectedXAxisLineView?.isHidden = true
        self.addSubview(self.selectedXAxisLineView!)
        
        //用户点击图表显示当前y轴的实际值
        self.selectedYAxisLabel = UILabel(frame: CGRect.zero)
        self.selectedYAxisLabel?.backgroundColor = self.selectedBGColor
        self.selectedYAxisLabel?.isHidden = true
        self.selectedYAxisLabel?.font = self.labelFont
        self.selectedYAxisLabel?.minimumScaleFactor = 0.5
        self.selectedYAxisLabel?.lineBreakMode = .byClipping
        self.selectedYAxisLabel?.adjustsFontSizeToFitWidth = true
        self.selectedYAxisLabel?.textColor = self.selectedTextColor
        self.selectedYAxisLabel?.textAlignment = NSTextAlignment.center
        self.addSubview(self.selectedYAxisLabel!)
        
        //用户点击图表显示当前x轴的实际值
        self.selectedXAxisLabel = UILabel(frame: CGRect.zero)
        self.selectedXAxisLabel?.backgroundColor = self.selectedBGColor
        self.selectedXAxisLabel?.isHidden = true
        self.selectedXAxisLabel?.font = self.labelFont
        self.selectedXAxisLabel?.textColor = self.selectedTextColor
        self.selectedXAxisLabel?.textAlignment = NSTextAlignment.center
        self.addSubview(self.selectedXAxisLabel!)
        
        self.sightView = UIView(frame: CGRect(x: 0, y: 0, width: 6, height: 6))
        self.sightView?.backgroundColor = selectedSightColor
        self.sightView?.isHidden = true
        self.sightView?.layer.cornerRadius = 3
        self.addSubview(self.sightView!)
        
        //添加手势操作
        let pan = UIPanGestureRecognizer(
            target: self,
            action: #selector(doPanAction(_:)))
        pan.delegate = self
        
        self.addGestureRecognizer(pan)
        
        //点击手势操作
        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(doTapAction(_:)))
        tap.delegate = self
        self.addGestureRecognizer(tap)
        
        
        //双指缩放操作
        let pinch = UIPinchGestureRecognizer(
            target: self,
            action: #selector(doPinchAction(_:)))
        pinch.delegate = self
        self.addGestureRecognizer(pinch)
        
        //长按手势操作
        let longPress = UILongPressGestureRecognizer(target: self,
                                                     action: #selector(doLongPressAction(_:)))
        //长按时间为1秒
        longPress.minimumPressDuration = 0.5
        self.addGestureRecognizer(longPress)
        
        
        //加载一个初始化的Range值
        if let userRange = self.delegate?.initRangeInKLineChart?(in: self) {
            self.range = userRange
        }
        
        //初始数据
        self.resetData()
        
    }
    
    /**
     初始化数据
     */
    fileprivate func resetData() {
        self.datas.removeAll()
        self.plotCount = self.delegate?.numberOfPointsInKLineChart(chart: self) ?? 0
        
        if plotCount > 0 {
            
            //获取代理上的数据源
            for i in 0...self.plotCount - 1 {
                let item = self.delegate?.kLineChart(chart: self, valueForPointAtIndex: i)
                self.datas.append(item!)
            }
            
            //执行算法方程式计算值，添加到对象中
            for algorithm in self.handlerOfAlgorithms {
                //执行该算法，计算指标数据
                self.datas = algorithm.handleAlgorithm(self.datas)
            }
        }
    }
    
    
    /**
     获取点击区域所在分区位
     
     - parameter point: 点击坐标
     
     - returns: 返回section和索引位
     */
    func getSectionByTouchPoint(_ point: CGPoint) -> (Int, CHSection?) {
        for (i, section) in self.sections.enumerated() {
            if section.frame.contains(point) {
                return (i, section)
            }
        }
        return (-1, nil)
    }
    
    
    /// 取显示X轴坐标的分区
    ///
    /// - Returns:
    func getSecionWhichShowXAxis() -> CHSection? {
        let visiableSection = self.sections.filter { !$0.hidden }
        var showSection: CHSection?
        for (i, section) in visiableSection.enumerated() {
            //用户自定义显示X轴的分区
            if section.index == self.showXAxisOnSection {
                showSection = section
            }
            //如果最后都没有找到，取最后一个做显示
            if i == visiableSection.count - 1 && showSection == nil{
                showSection = section
            }
        }
        
        return showSection
    }
    
    /**
     设置选中的数据点
     
     - parameter point:
     */
    func setSelectedIndexByPoint(_ point: CGPoint) {
        
        
        guard self.enableTap else {
            return
        }
        
//        self.selectedXAxisLabel?.isHidden = !self.showSelection
//        self.selectedYAxisLabel?.isHidden = !self.showSelection
//        self.verticalLineView?.isHidden = !self.showSelection
//        self.horizontalLineView?.isHidden = !self.showSelection
//        self.sightView?.isHidden = !self.showSelection
        
        if point.equalTo(CGPoint.zero) {
            return
        }
        
        let (_, section) = self.getSectionByTouchPoint(point)
        if section == nil {
            return
        }
        
        let visiableSections = self.sections.filter { !$0.hidden }
        guard let lastSection = visiableSections.last else {
            return
        }
        
        guard let showXAxisSection = self.getSecionWhichShowXAxis() else {
            return
        }
        
        //重置文字颜色和字体
        self.selectedYAxisLabel?.font = self.labelFont
        self.selectedYAxisLabel?.backgroundColor = self.selectedBGColor
        self.selectedYAxisLabel?.textColor = self.selectedTextColor
        self.selectedXAxisLabel?.font = self.labelFont
        self.selectedXAxisLabel?.backgroundColor = self.selectedBGColor
        self.selectedXAxisLabel?.textColor = self.selectedTextColor
        
        let yaxis = section!.yAxis
        let format = yaxis.decimalFormat
        
        self.selectedPoint = point
        
        //每个点的间隔宽度
        let plotWidth = (section!.frame.size.width - section!.padding.left - section!.padding.right) / CGFloat(self.rangeTo - self.rangeFrom)
        
        var yVal: CGFloat = 0        //获取y轴坐标的实际值
        
        for i in self.rangeFrom...self.rangeTo - 1 {
            let ixs = plotWidth * CGFloat(i - self.rangeFrom) + section!.padding.left + self.padding.left
            let ixe = plotWidth * CGFloat(i - self.rangeFrom + 1) + section!.padding.left + self.padding.left
            //            NSLog("ixs = \(ixs)")
            //            NSLog("ixe = \(ixe)")
            //            NSLog("point.x = \(point.x)")
            if ixs <= point.x && point.x < ixe {
                self.selectedIndex = i
                let item = self.datas[i]
                var hx = section!.frame.origin.x + section!.padding.left
                hx = hx + plotWidth * CGFloat(i - self.rangeFrom) + plotWidth / 2
                let hy = self.padding.top
                let hheight = lastSection.frame.maxY
                //显示辅助线
                self.selectedXAxisLineView?.frame = CGRect(x: hx, y: hy, width: self.lineWidth, height: hheight)
                //                self.horizontalLineView?.isHidden = false
                
                let vx = section!.frame.origin.x + section!.padding.left
                var vy: CGFloat = 0
                
                
                
                //处理水平线y的值
                switch self.selectedPosition {
                case .free:
                    vy = point.y
                    yVal = section!.getRawValue(point.y)        //获取y轴坐标的实际值
                case .onClosePrice:
                    if let series = section?.getSeries(key: CHSeriesKey.candle), !series.hidden {
                        yVal = item.closePrice          //获取收盘价作为实际值
                    } else if let series = section?.getSeries(key: CHSeriesKey.timeline), !series.hidden {
                        yVal = item.closePrice          //获取收盘价作为实际值
                    } else if let series = section?.getSeries(key: CHSeriesKey.volume), !series.hidden {
                        yVal = item.vol                 //获取交易量作为实际值
                    }
                    
                    vy = section!.getLocalY(yVal)
                    
                }
                let hwidth = section!.frame.size.width - section!.padding.left - section!.padding.right
                //显示辅助线
                self.selectedYAxisLineView?.frame = CGRect(x: vx, y: vy - self.lineWidth / 2, width: hwidth, height: self.lineWidth)
                //                self.verticalLineView?.isHidden = false
                
                //显示y轴辅助内容
                //控制y轴的label在左还是右显示
                var yAxisStartX: CGFloat = 0
                //                self.selectedYAxisLabel?.isHidden = false
                //                self.selectedXAxisLabel?.isHidden = false
                switch self.yAxisShowPosition {
                case .left:
                    yAxisStartX = section!.frame.origin.x
                case .right:
                    yAxisStartX = section!.frame.maxX - style.yAxisLabelLayerWidth
                case .none:
                    self.selectedYAxisLabel?.isHidden = true
                }
                self.selectedYAxisLabel?.text = yVal.ch_toString(withFormat: format)    //显示实际值
                self.selectedYAxisLabel?.frame = CGRect(x: yAxisStartX, y: vy - yAxisLabelHeight / 2, width: style.yAxisLabelLayerWidth, height: yAxisLabelHeight)
                let time = Date.ch_getTimeByStamp(item.time, format: "yyyy-MM-dd HH:mm") //显示实际值
                let size = time.ch_sizeWithConstrained(self.labelFont)
                self.selectedXAxisLabel?.text = time
                
                //判断x是否超过左右边界
                let labelWidth = size.width  + 6
                var x = hx - (labelWidth) / 2
                
                if x < section!.frame.origin.x {
                    x = section!.frame.origin.x
                } else if x + labelWidth > section!.frame.origin.x + section!.frame.size.width {
                    x = section!.frame.origin.x + section!.frame.size.width - labelWidth
                }
                
                self.selectedXAxisLabel?.frame = CGRect(x: x, y: showXAxisSection.frame.maxY, width: size.width  + 6, height: style.xAxisLabelLayerHeight)
                
                self.sightView?.center = CGPoint(x: hx, y: vy)
                
                //给用户进行最后的自定义
                self.delegate?.kLineChart?(chart: self, viewOfYAxis: self.selectedXAxisLabel!, viewOfXAxis: self.selectedYAxisLabel!)
                
                self.showSelection = true
                
                self.bringSubviewToFront(self.selectedYAxisLineView!)
                self.bringSubviewToFront(self.selectedXAxisLineView!)
                self.bringSubviewToFront(self.selectedXAxisLabel!)
                self.bringSubviewToFront(self.selectedYAxisLabel!)
                self.bringSubviewToFront(self.sightView!)
                
                //设置选中点
                self.setSelectedIndexByIndex(i)
                
                break
            }
            
        }
    }
    
    /**
     设置选中的数据点
     
     - parameter index: 选中位置
     */
    func setSelectedIndexByIndex(_ index: Int) {
        
        guard index >= self.rangeFrom && index < self.rangeTo else {
            return
        }
        
        self.selectedIndex = index
        let item = self.datas[index]
        
        //显示分区的header标题
        for (_, section) in self.sections.enumerated() {
            if section.hidden {
                continue
            }
            
            if let titleString = self.delegate?.kLineChart?(chart: self,
                                                            titleForHeaderInSection: section,
                                                            index: index,
                                                            item: self.datas[index]) {
                //显示用户自定义的title
                section.drawTitleForHeader(title: titleString)
            } else {
                //显示默认
                section.drawTitle(index)
            }
        }
        
        
        
        //回调给代理委托方法
        self.delegate?.kLineChart?(chart: self, didSelectAt: index, item: item)
        
    }
    
}

// MARK: - 绘图相关方法
extension CHKLineChartView {
    
    
    /// 清空图表的子图层
    func removeLayerView() {
        for section in self.sections {
            for series in section.series {
                series.removeLayerView()
            }
        }
    }
    
    /// 通过CALayer方式画图表
    func drawLayerView() {
        // 先清空图层
        self.removeLayerView()
        // 初始化数据
        if self.initChart() {
            for (index, section) in sections.enumerated() {
                // 获取各section的小数保留位数
                let decimal = delegate?.kLineChart?(chart: self, decimalFormatAt: index) ?? "0.2"
                section.decimal = decimal
                // 初始Y轴的数据
                initYAxis(section)
                // 更新x、y轴坐标标签
                updateXAxisTexts(in: section)
                updateYAxisTexts(in: section)
                // 绘制图表的点线
                drawChart(section)

                if let titleString = delegate?.kLineChart?(chart: self, titleForHeaderInSection: section, index: selectedIndex, item: datas[selectedIndex]) {
                    // 显示用户自定义的section title
                    section.drawTitleForHeader(title: titleString)
                } else {
                    // 显示范围最后一个点的内容
                    section.drawTitle(selectedIndex)
                }
            }

            self.delegate?.didFinishKLineChartRefresh?(chart: self)
        }
        
    }
    
    /**
     绘制图表
     
     - parameter rect:
 
    override open func draw(_ rect: CGRect) {
        
    }
    */
    
    /**
     初始化图表结构
     
     - returns: 是否初始化数据
     */
    fileprivate func initChart() -> Bool {
        
        self.plotCount = self.delegate?.numberOfPointsInKLineChart(chart: self) ?? 0
        
        //数据条数不一致，需要重新计算
        if self.plotCount != self.datas.count {
            self.resetData()
        }
        
        if plotCount > 0 {
            
            //如果显示全部，显示范围为全部数据量
            if self.isShowAll {
                self.range = self.plotCount
                self.rangeFrom = 0
                self.rangeTo = self.plotCount
            }
            
            //图表刷新滚动为默认时，如果第一次初始化，就默认滚动到最后显示
            if self.scrollToPosition == .none {
                //如果图表尽头的索引为0，则进行初始化
                if self.rangeTo == 0 || self.plotCount < self.rangeTo {
                    self.scrollToPosition = .end
                }
            }
            
            
            if self.scrollToPosition == .top {
                self.rangeFrom = 0
                if self.rangeFrom + self.range < self.plotCount {
                    self.rangeTo = self.rangeFrom + self.range   //计算结束的显示的位置
                } else {
                    self.rangeTo = self.plotCount
                }
                self.selectedIndex = -1
            } else if self.scrollToPosition == .end {
                self.rangeTo = self.plotCount               //默认是数据最后一条为尽头
                if self.rangeTo - self.range > 0 {          //如果尽头 - 默认显示数大于0
                    self.rangeFrom = self.rangeTo - range   //计算开始的显示的位置
                } else {
                    self.rangeFrom = 0
                }
                self.selectedIndex = -1
            }
            
        }
        
        //重置图表刷新滚动默认不处理
        self.scrollToPosition = .none
        
        //超出范围，选择最后一个元素选中
        if self.selectedIndex < 0 || self.selectedIndex >= self.rangeTo {
            self.selectedIndex = datas.count - 1
        }

        return self.datas.count > 0 ? true : false
    }
    
    
    /**
     初始化分区上各个线的Y轴
     */
    fileprivate func initYAxis(_ section: CHSection) {
        
        if section.series.count > 0 {
            //建立分区每条线的坐标系
            section.buildYAxis(startIndex: self.rangeFrom, endIndex: self.rangeTo, datas: self.datas)
        }
        
    }
    
    
    /**
     绘制图表上的点线
     
     - parameter section:
     */
    func drawChart(_ section: CHSection) {
        for serie in section.series {
            drawSerie(serie)
            updatePriceIndicator(in: serie)
        }
    }
    
    /**
     绘制图表分区上的系列点先
     */
    func drawSerie(_ serie: CHSeries) {
        guard !serie.hidden else { return }
        //循环画出每个模型的线
        for model in serie.chartModels {
            let serieLayer = model.drawSerie(self.rangeFrom, endIndex: self.rangeTo)
            serie.seriesLayer.addSublayer(serieLayer)
        }
    }
    
    func updatePriceIndicator(in serie: CHSeries) {
        guard let model = serie.chartModels.first, let data = model.datas.last, serie.key == CHSeriesKey.candle else { return }
        let section = model.section!
        
        let currentPriceY = section.getLocalY(data.closePrice)
        let indicatorY = min(section.frame.height - 10, max(20, currentPriceY))
        let indicatorLineX = section.padding.left
        let indicatorLineWidth = section.frame.size.width - section.padding.left - section.padding.right
        currentPriceLineView?.frame = CGRect(x: indicatorLineX, y: indicatorY, width: indicatorLineWidth, height: lineWidth)
        currentPriceLineView?.isHidden = false
        let indicatorLabelX = style.showYAxisLabel == .left ? 0 : section.frame.maxX - style.yAxisLabelLayerWidth
        currentPriceLabel?.frame = CGRect(x: indicatorLabelX, y: indicatorY - yAxisLabelHeight / 2, width: style.yAxisLabelLayerWidth, height: yAxisLabelHeight)
        currentPriceLabel?.isHidden = false
        currentPriceLabel?.text = data.closePrice.ch_toString()
        if currentPriceLineView?.layer.sublayers == nil {
            let lineLayer = CAShapeLayer()
            lineLayer.strokeColor = UIColor.orange.cgColor
            lineLayer.lineDashPattern = [5]
            lineLayer.lineWidth = currentPriceLineView!.frame.height
            let linePath = UIBezierPath()
            linePath.move(to: .zero)
            linePath.addLine(to: CGPoint(x: indicatorLineWidth, y: 0))
            lineLayer.path = linePath.cgPath
            currentPriceLineView?.layer.addSublayer(lineLayer)
        }
    }
}

// MARK: - 公开方法
extension CHKLineChartView {
    
    /**
     刷新视图
     */
    public func reloadData(toPosition: CHChartViewScrollPosition = .none, resetData: Bool = true) {
        self.scrollToPosition = toPosition
        if resetData {
            self.resetData()
        }
        self.drawLayerView()
    }
    
    
    /// 刷新风格
    ///
    /// - Parameter style: 新风格
    public func resetStyle(style: CHKLineChartStyle) {
        self.style = style
        self.showSelection = false
        self.reloadData()
    }
    
    /// 通过key隐藏或显示线系列
    /// inSection = -1时，全section都隐藏，否则只隐藏对应的索引的section
    /// key = "" 时，设置全部线显示或隐藏
    public func setSerie(hidden: Bool, by key: String = "", inSection: Int = -1) {
        
        var hideSections = [CHSection]()
        if inSection < 0 {
            hideSections = self.sections
        } else {
            if inSection >= self.sections.count {
                return //超过界限
            }
            hideSections.append(self.sections[inSection])
        }
        for section in hideSections {
            for serie in section.series {
                if key == "" {
                    serie.hidden = hidden
                } else if serie.key == key {
                    serie.hidden = hidden
                    break
                }
            }
        
        }
  
//        self.drawLayerView()
    }
    
    /**
     通过key隐藏或显示分区
     */
    public func setSection(hidden: Bool, byKey key: String) {
        for section in self.sections {
            //副图才能隐藏
            if section.key == key && section.valueType == .assistant {
                section.hidden = hidden
                break
            }
        }

        
//        self.drawLayerView()
    }
    
    /**
     通过索引位隐藏或显示分区
     */
    public func setSection(hidden: Bool, byIndex index: Int) {
        //副图才能隐藏
        guard let section = self.sections[safe: index], section.valueType == .assistant else {
            return
        }
        
        section.hidden = hidden
        
        
//        self.drawLayerView()
    }
    
    
    /// 缩放图表
    ///
    /// - Parameters:
    ///   - interval: 偏移量
    ///   - enlarge: 是否放大操作
    public func zoomChart(by interval: Int, enlarge: Bool) {
        
        var newRangeTo = 0
        var newRangeFrom = 0
        var newRange = 0
        
        if enlarge {
            //双指张开
            newRangeTo = self.rangeTo - interval
            newRangeFrom = self.rangeFrom + interval
            newRange = self.rangeTo - self.rangeFrom
            if newRange >= kMinRange {
                
                if self.plotCount > self.rangeTo - self.rangeFrom {
                    if newRangeFrom < self.rangeTo {
                        self.rangeFrom = newRangeFrom
                    }
                    if newRangeTo > self.rangeFrom {
                        self.rangeTo = newRangeTo
                    }
                }else{
                    if newRangeTo > self.rangeFrom {
                        self.rangeTo = newRangeTo
                    }
                }
                self.range = self.rangeTo - self.rangeFrom
                self.drawLayerView()
            }
            
        } else {
            //双指合拢
            newRangeTo = self.rangeTo + interval
            newRangeFrom = self.rangeFrom - interval
            newRange = self.rangeTo - self.rangeFrom
            if newRange <= kMaxRange {
                
                if newRangeFrom >= 0 {
                    self.rangeFrom = newRangeFrom
                } else {
                    self.rangeFrom = 0
                    newRangeTo = newRangeTo - newRangeFrom //补充负数位到头部
                }
                if newRangeTo <= self.plotCount {
                    self.rangeTo = newRangeTo
                    
                } else {
                    self.rangeTo = self.plotCount
                    newRangeFrom = newRangeFrom - (newRangeTo - self.plotCount)
                    if newRangeFrom < 0 {
                        self.rangeFrom = 0
                    } else {
                        self.rangeFrom = newRangeFrom
                    }
                }
                self.range = self.rangeTo - self.rangeFrom
                self.drawLayerView()
            }
        }
        
    }
    
    func resetDrawRange() {
        range = defaultRange
    }
    
    
    /// 左右平移图表
    ///
    /// - Parameters:
    ///   - interval: 移动列数
    ///   - direction: 方向，true：右滑操作，fasle：左滑操作
    public func moveChart(by interval: Int, direction: Bool) {
        if (interval > 0) {                     //有移动间隔才移动
            if direction {
                // 单指向右拖，往后查看数据
                if plotCount > rangeTo - rangeFrom, rangeFrom - interval >= 0  {
                    rangeFrom -= interval
                    rangeTo -= interval
                    drawLayerView()
                }
            } else {
                //单指向左拖，往前查看数据
                if plotCount > rangeTo - rangeFrom, rangeTo + interval <= plotCount {
                    rangeFrom += interval
                    rangeTo += interval
                    drawLayerView()
                }
            }
        }
        range = rangeTo - rangeFrom
    }
    
    /// 生成截图
    open var image: UIImage {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        let capturedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return capturedImage!
    }
    
    
    /// 手动设置分区头部文本显示内容
    ///
    /// - Parameters:
    ///   - titles: 文本内容及颜色元组
    ///   - section: 分区位置
    open func setHeader(titles: [(title: String, color: UIColor)], inSection section: Int)  {
        guard let section = self.sections[safe: section] else {
            return
        }
        
        //设置标题
        section.setHeader(titles: titles)
    }
    
    
    /// 向分区添加新线段
    ///
    /// - Parameters:
    ///   - series: 线段
    ///   - section: 分区位置
    open func addSeries(_ series: CHSeries, inSection section: Int) {
        guard let section = self.sections[safe: section] else {
            return
        }
        section.series.append(series)
        
        self.drawLayerView()
    }
    
    
    /// 通过主键名向分区删除线段
    ///
    /// - Parameters:
    ///   - key: 主键
    ///   - section: 分区位置
    open func removeSeries(key: String, inSection section: Int) {
        guard let section = self.sections[safe: section] else {
            return
        }
        
        section.removeSeries(key: key)
        
        self.drawLayerView()
    }
}


// MARK: - 手势操作
extension CHKLineChartView: UIGestureRecognizerDelegate {
    
    
    /// 控制手势开关
    ///
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        switch gestureRecognizer {
        case is UITapGestureRecognizer:
            return self.enableTap
        case is UIPanGestureRecognizer:
            return self.enablePan
        case is UIPinchGestureRecognizer:
            return self.enablePinch
        default:
            return false
        }
    }
   
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if otherGestureRecognizer.view is UITableView{
            
            return true
        }
        
        return false
    }
    
    
    /// 平移拖动操作
    ///
    /// - Parameter sender: 手势
    @objc func doPanAction(_ sender: UIPanGestureRecognizer) {
        
        guard self.enablePan else {
            return
        }
        
        selectedIndex = -1
        self.showSelection = false
        
        //手指滑动总平移量
        let translation = sender.translation(in: self)
        //滑动力度，用于释放手指时完成惯性滚动的效果
        let velocity =  sender.velocity(in: self)
        
        //获取可见的其中一个分区
        let visiableSection = self.sections.filter { !$0.hidden }
        guard let section = visiableSection.first else {
            return
        }
        
        //该分区每个点的间隔宽度
        let plotWidth = (section.frame.size.width - section.padding.left - section.padding.right) / CGFloat(self.rangeTo - self.rangeFrom)
        
        switch sender.state {
        case .began:
            self.animator.removeAllBehaviors()
        case .changed:
            
            //计算移动距离的绝对值，距离满足超过线条宽度就进行图表平移刷新
            let distance = abs(translation.x)
//            print("translation.x = \(translation.x)")
//            print("distance = \(distance)")
            if distance > plotWidth {
                let isRight = translation.x > 0 ? true : false
                let interval = lroundf(abs(Float(distance / plotWidth)))
                self.moveChart(by: interval, direction: isRight)
                //重新计算起始位
                sender.setTranslation(CGPoint(x: 0, y: 0), in: self)
            }
            
        case .ended, .cancelled:
            
            //重置减速开始
            self.decelerationStartX = 0
            //添加减速行为
            self.dynamicItem.center = self.bounds.origin
            let decelerationBehavior = UIDynamicItemBehavior(items: [self.dynamicItem])
            decelerationBehavior.addLinearVelocity(velocity, for: self.dynamicItem)
            decelerationBehavior.resistance = 2.0
            decelerationBehavior.action = {
                [weak self]() -> Void in
                //print("self.dynamicItem.x = \(self?.dynamicItem.center.x ?? 0)")
                
                //到边界不执行移动
                if self?.rangeFrom == 0 || self?.rangeTo == self?.plotCount{
                    return
                }
                
                let itemX = self?.dynamicItem.center.x ?? 0
                let startX = self?.decelerationStartX ?? 0
                //计算移动距离的绝对值，距离满足超过线条宽度就进行图表平移刷新
                let distance = abs(itemX - startX)
                //            print("distance = \(distance)")
                if distance > plotWidth {
                    let isRight = itemX > 0 ? true : false
                    let interval = lroundf(abs(Float(distance / plotWidth)))
                    self?.moveChart(by: interval, direction: isRight)
                    //重新计算起始位
                    self?.decelerationStartX = itemX
                }
            }
            
            //添加动力行为
            self.animator.addBehavior(decelerationBehavior)
            self.decelerationBehavior = decelerationBehavior

            
        default:
            break
        }
    }
    
    /**
     *  点击事件处理
     *
     *  @param sender
     */
    @objc func doTapAction(_ sender: UITapGestureRecognizer) {
        
        guard self.enableTap else {
            return
        }
        
        animator.removeAllBehaviors()
        let point = sender.location(in: self)
        let (_, section) = self.getSectionByTouchPoint(point)
        if section != nil {
            self.setSelectedIndexByPoint(point)
        }
    }
    
    
    
    /// 双指手势缩放图表
    ///
    /// - Parameter sender: 手势
    @objc func doPinchAction(_ sender: UIPinchGestureRecognizer) {
        
        guard self.enablePinch else {
            return
        }
        
        self.showSelection = false
        
        //获取可见的其中一个分区
        let visiableSection = self.sections.filter { !$0.hidden }
        guard let section = visiableSection.first else {
            return
        }
        
        //该分区每个点的间隔宽度
        let plotWidth = (section.frame.size.width - section.padding.left - section.padding.right) / CGFloat(self.rangeTo - self.rangeFrom)
        
        
        //双指合拢或张开
        let scale = sender.scale
        var newRange = 0
        
        
        
        //根据放大比例计算一个新的列宽
        let newPlotWidth = plotWidth * scale
        
        let newRangeF = (section.frame.size.width - section.padding.left - section.padding.right) / newPlotWidth
        newRange = scale > 1 ? Int(newRangeF + 1) : Int(newRangeF)
        let distance = abs(self.range - newRange)
        //放大缩小的距离为偶数
        if distance % 2 == 0 && distance > 0 {
//            print("scale = \(scale)")
            let enlarge = scale > 1 ? true : false
            self.zoomChart(by: distance / 2, enlarge: enlarge)
            sender.scale = 1    //恢复比例
        }
        
    }
    
    
    /// 处理长按操作
    ///
    /// - Parameter sender:
    @objc func doLongPressAction(_ sender: UILongPressGestureRecognizer) {
        let point = sender.location(in: self)
        let (_, section) = self.getSectionByTouchPoint(point)
        if section != nil {
            //显示点击选中的内容
            self.setSelectedIndexByPoint(point)
        }
    }
}
