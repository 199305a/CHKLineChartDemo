//
//  ChartCustomViewController.swift
//  Example
//
//  Created by Chance on 2018/2/27.
//  Copyright © 2018年 Chance. All rights reserved.
//

import UIKit
import SnapKit

let screenWidth = UIScreen.main.bounds.width
let screenHeight = UIScreen.main.bounds.height

class ChartCustomViewController: UIViewController {
    
    /// 选择时间
    private let times = ["5min", "15min", "1hour", "6hour","1day"]
    /// 主图线段
    private let masterLine = [CHSeriesKey.candle, CHSeriesKey.timeline]
    /// 主图指标
    private let masterIndex = [CHSeriesKey.ma]
    /// 副图指标
    private let assistIndex = [CHSeriesKey.volume]
    //选择交易对
    private let exPairs = ["BTC-USD", "ETH-USD", "LTC-USD", "LTC-BTC", "ETH-BTC", "BCH-BTC"]
    /// 已选主图线段
    private var selectedMasterLine: Int = 0
    /// 已选主图指标
    private var selectedMasterIndex: Int = 0
    /// 已选副图指标1
    private var selectedAssistIndex: Int = 0
    private var selectedSymbol: Int = 0
    /// 数据源
    private var klineDatas = [KlineChartData]()
    /// 图表X轴的前一天，用于对比是否夸日
    private var chartXAxisPrevDay: String = ""
    /// 已选周期
    private var selectedTime: Int = 0 {
        didSet {
            let time = self.times[self.selectedTime]
            self.buttonTime.setTitle(time, for: .normal)
        }
    }
    /// 图表
    private lazy var chartView: CHKLineChartView = {
        let rect = CGRect(x: 0, y: topView.frame.maxY, width: screenWidth, height: screenHeight - topView.frame.maxY - toolbar.frame.height - 64)
        let chartView = CHKLineChartView(frame: rect, style: loadUserStyle())
        chartView.delegate = self
        return chartView
    }()
    /// 顶部数据
    private lazy var topView: TickerTopView = {
        let rect = CGRect(x: 0, y: 0, width: screenWidth, height: 60)
        let view = TickerTopView(frame: rect)
        return view
    }()
    /// 选择时间周期
    private lazy var buttonTime: UIButton = {
        let btn = UIButton()
        btn.setTitleColor(UIColor.ch_hex(0xfe9d25), for: .normal)
        btn.addTarget(self, action: #selector(self.handleShowTimeSelection), for: .touchUpInside)
        return btn
    }()
    /// 股票指标
    private lazy var buttonIndex: UIButton = {
        let btn = UIButton()
        btn.setTitle("Index", for: .normal)
        btn.setTitleColor(UIColor.ch_hex(0xfe9d25), for: .normal)
        btn.addTarget(self, action: #selector(self.handleShowIndex), for: .touchUpInside)
        return btn
    }()
    /// 市场设置
    private lazy var buttonMarket: UIButton = {
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 70, height: 40))
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        btn.setTitleColor(UIColor.ch_hex(0xfe9d25), for: .normal)
        btn.addTarget(self, action: #selector(self.handleTitlePress(_:)), for: .touchUpInside)
        return btn
    }()
    /// 工具栏
    private lazy var toolbar: UIView = {
        let rect = CGRect(x: 0, y: screenHeight - 44 - 64, width: screenWidth, height: 44)
        let view = UIView(frame: rect)
        view.backgroundColor = UIColor.ch_hex(0x242731)
        return view
    }()
    ///周期弹出窗
    private lazy var selectionViewForTime: SelectionPopView = {
        let view = SelectionPopView() {
            (vc, indexPath) in
            self.selectedTime = indexPath.row
            self.requestData()
        }
        return view
    }()
    ///市场弹出窗
    private lazy var selectionViewForMarket: SelectionPopView = {
        let view = SelectionPopView() {
            (vc, indexPath) in
            let symbol = self.exPairs[indexPath.row]
            self.selectedSymbol = indexPath.row
            self.buttonMarket.setTitle(symbol + "📈", for: .normal)
            self.requestData()
        }
        return view
    }()
    ///指标弹出窗
    private lazy var selectionViewForIndex: SelectionPopView = {
        let view = SelectionPopView() {
            (vc, indexPath) in
            self.didSelectChartIndex(indexPath: indexPath)
        }
        return view
    }()
    private lazy var loadingView: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .whiteLarge)
        return v
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureSubviews()
        
        self.selectedTime = 0
        self.selectedMasterLine = 0
        self.selectedMasterIndex = 0
        self.selectedAssistIndex = 0
        self.selectedSymbol = 0
        let symbol = self.exPairs[self.selectedSymbol]
        self.buttonMarket.setTitle(symbol + "📈", for: .normal)
        self.handleChartIndexChanged()
        self.requestData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    func requestData() {
        self.loadingView.startAnimating()
        self.loadingView.isHidden = false
        let symbol = self.exPairs[self.selectedSymbol]
        ChartDatasFetcher.shared.getRemoteChartData(
            symbol: symbol,
            timeType: self.times[self.selectedTime],
            size: 1000) {
                [weak self](flag, chartsData) in
                if flag && chartsData.count > 0 {
                    self?.klineDatas = chartsData
                    self?.chartView.reloadData()
                    
                    //显示最后一条数据
                    self?.topView.update(data: chartsData.last!)
                    
                    self?.loadingView.stopAnimating()
                    self?.loadingView.isHidden = true
                }
        }
    }
}

// MARK: - Configure
extension ChartCustomViewController {
    
    private func configureSubviews() {
        self.view.backgroundColor = UIColor.ch_hex(0x232732)
        self.navigationItem.titleView = self.buttonMarket
        self.view.addSubview(self.topView)
        self.view.addSubview(self.chartView)
        self.view.addSubview(self.toolbar)
        self.view.addSubview(self.loadingView)
        self.toolbar.addSubview(self.buttonIndex)
        self.toolbar.addSubview(self.buttonTime)
        
        self.loadingView.snp.makeConstraints { (make) in
            make.center.equalTo(self.chartView)
        }
        
        self.buttonTime.snp.makeConstraints { (make) in
            make.left.equalToSuperview().inset(8)
            make.width.equalTo(80)
            make.height.equalTo(30)
            make.centerY.equalToSuperview()
        }
        
        self.buttonIndex.snp.makeConstraints { (make) in
            make.left.equalTo(self.buttonTime.snp.right)
            make.width.equalTo(80)
            make.height.equalTo(30)
            make.centerY.equalToSuperview()
        }
    }
}

// MARK: - Action
extension ChartCustomViewController {
    
    /// 选择周期
    @objc func handleShowTimeSelection() {
        let view = self.selectionViewForTime
        view.clear()
        view.addItems(section: "Time", items: self.times, selectedIndex: self.selectedTime)
        view.show(from: self)
    }
    
    /// 选择指标
    @objc func handleShowIndex() {
        let view = self.selectionViewForIndex
        view.clear()
        view.addItems(section: "Chart Line", items: self.masterLine, selectedIndex: self.selectedMasterLine)
        view.addItems(section: "Master Index", items: self.masterIndex, selectedIndex: self.selectedMasterIndex)
        view.addItems(section: "Assist Index 1", items: self.assistIndex, selectedIndex: self.selectedAssistIndex)
        view.show(from: self)
    }
    
    func didSelectChartIndex(indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            self.selectedMasterLine = indexPath.row
        case 1:
            self.selectedMasterIndex = indexPath.row
        case 2:
            self.selectedAssistIndex = indexPath.row
        default: break
        }
        
        // 重新渲染
        self.handleChartIndexChanged()
    }
    
    /// 处理指标的变更
    func handleChartIndexChanged() {
        let lineKey = self.masterLine[self.selectedMasterLine]
        let masterKey = self.masterIndex[self.selectedMasterIndex]
        let assistKey = self.assistIndex[self.selectedAssistIndex]
        
        //先隐藏所有线段
        self.chartView.setSerie(hidden: true, inSection: 0)
        self.chartView.setSerie(hidden: true, inSection: 1)
        
        //显示当前选中的线段
        self.chartView.setSerie(hidden: false, by: lineKey, inSection: 0)
        self.chartView.setSerie(hidden: false, by: masterKey, inSection: 0)
        self.chartView.setSerie(hidden: false, by: assistKey, inSection: 1)
        
        //重新渲染
        self.chartView.reloadData(resetData: false)
    }
    
    @objc func handleTitlePress(_ sender: Any) {
        let view = self.selectionViewForMarket
        view.clear()
        view.addItems(section: "Markets", items: self.exPairs, selectedIndex: self.selectedSymbol)
        view.show(from: self)
    }
}

// MARK: - CHKLineChartDelegate
extension ChartCustomViewController: CHKLineChartDelegate {
    
    func numberOfPointsInKLineChart(chart: CHKLineChartView) -> Int {
        return self.klineDatas.count
    }
    
    func kLineChart(chart: CHKLineChartView, valueForPointAtIndex index: Int) -> CHChartItem {
        let data = self.klineDatas[index]
        let item = CHChartItem()
        item.time = data.time
        item.openPrice = CGFloat(data.openPrice)
        item.highPrice = CGFloat(data.highPrice)
        item.lowPrice = CGFloat(data.lowPrice)
        item.closePrice = CGFloat(data.closePrice)
        item.vol = CGFloat(data.vol)
        return item
    }
    
    func kLineChart(chart: CHKLineChartView, labelOnYAxisForValue value: CGFloat, atIndex index: Int, section: CHSection) -> String {
        var strValue = ""
        if section.key == "volume" {
            if value / 1000 > 1 {
                strValue = (value / 1000).ch_toString(withFormat: section.decimal) + "K"
            } else {
                strValue = value.ch_toString(withFormat: section.decimal)
            }
            
        } else {
            strValue = value.ch_toString(withFormat: section.decimal)
        }
        
        return strValue
    }
    
    func kLineChart(chart: CHKLineChartView, labelOnXAxisForIndex index: Int) -> String {
        var data: KlineChartData
        if index >= klineDatas.count {
            data = klineDatas[klineDatas.count - 1]
        } else {
            data = klineDatas[index]
        }
        let timestamp = data.time
        let dayText = Date.ch_getTimeByStamp(timestamp, format: "yyyy-MM-dd")
        let timeText = Date.ch_getTimeByStamp(timestamp, format: "MM-dd HH:mm")
        var text = ""
        //跨日，显示日期
        if dayText != self.chartXAxisPrevDay && index > 0 {
            text = dayText
        } else {
            text = timeText
        }
        self.chartXAxisPrevDay = dayText
        return text
    }
    
    /// 自定义分区图标题
    ///
    func kLineChart(chart: CHKLineChartView, titleForHeaderInSection section: CHSection, index: Int, item: CHChartItem) -> NSAttributedString? {
        var start = 0
        let titleString = NSMutableAttributedString()
        var key = ""
        switch section.index {
        case 0:
            key = self.masterIndex[self.selectedMasterIndex]
        default:
            key = section.series[section.selectedIndex].key
        }
        
        // 获取该线段的标题值及颜色，可以继续自定义
        guard let attributes = section.getTitleAttributesByIndex(index, seriesKey: key) else {
            return nil
        }
        
        // 合并为完整字符串
        for (title, color) in attributes {
            titleString.append(NSAttributedString(string: title))
            let range = NSMakeRange(start, title.ch_length)
            let colorAttribute = [NSAttributedString.Key.foregroundColor: color]
            titleString.addAttributes(colorAttribute, range: range)
            start += title.ch_length
        }
        
        return titleString
    }
    
    /// 点击图标返回点击的位置和数据对象
    ///
    /// - Parameters:
    ///   - chart:
    ///   - index:
    ///   - item:
    func kLineChart(chart: CHKLineChartView, didSelectAt index: Int, item: CHChartItem) {
        let data = self.klineDatas[index]
        self.topView.update(data: data)
    }
    
    /// 切换可分页分区的线组
    ///
    func kLineChart(chart: CHKLineChartView, didFlipPageSeries section: CHSection, series: CHSeries, seriesIndex: Int) {
        switch section.index {
        case 1:
            self.selectedAssistIndex = self.assistIndex.firstIndex(of: series.key) ?? self.selectedAssistIndex
        default:break
        }
    }
}

// MARK: - Rotate
extension ChartCustomViewController {
    
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        if toInterfaceOrientation.isPortrait {
            // 竖屏时，交易量的y轴只以4间断显示
            self.chartView.sections[1].yAxis.tickInterval = 3
        } else {
            // 竖屏时，交易量的y轴只以2间断显示
            self.chartView.sections[1].yAxis.tickInterval = 1
        }
        self.chartView.reloadData()
    }
    
}

// MARK: - Custom Style
extension ChartCustomViewController {
    
    /// 读取用户自定义样式
    ///
    /// - Returns:
    func loadUserStyle() -> CHKLineChartStyle {
        let backgroundColor = UIColor.ch_hex(0x232732)

        let style = CHKLineChartStyle()
//        style.borderWidth = (0.5, 0, 0.5, 0.5)
        style.labelFont = UIFont.systemFont(ofSize: 10)
        style.lineColor = UIColor.white
        style.textColor = UIColor.white
        style.selectedLineColor = UIColor.white
        style.selectedSightColor = UIColor.white
        style.selectedBGColor = UIColor(white: 0.4, alpha: 1)
        style.selectedTextColor = UIColor.white
        style.backgroundColor = backgroundColor
        style.isInnerYAxis = false
        style.showYAxisLabel = .right
        style.padding = UIEdgeInsets.zero
        style.yAxisLabelLayerWidth = 60
        style.xAxisLabelLayerHeight = 16
        
        let maNums = [5, 10]
        let maArray = maNums.map { CHChartAlgorithm.ma($0) }
        style.algorithms.append(contentsOf: maArray)
        style.algorithms.append(CHChartAlgorithm.timeline)
        
        /************** 配置分区样式 **************/
        
        /// 主图
        let upcolor = (UIColor.ch_hex(0x00bd9a), true)
        let downcolor = (UIColor.ch_hex(0xff6960), true)
        let mainSection = CHSection()
        mainSection.backgroundColor = style.backgroundColor
        mainSection.valueType = .master
        mainSection.key = "master"
        mainSection.ratios = 3
        mainSection.padding = UIEdgeInsets(top: 40, left: 0, bottom: 20, right: 0)
        mainSection.xAxis.tickInterval = 4
        mainSection.xAxis.referenceStyle = .solid(color: UIColor(white: 0.4, alpha: 1))
        mainSection.yAxis.referenceStyle = .solid(color: UIColor(white: 0.4, alpha: 1))
        /// 副图1
        let volumeSection = CHSection()
        volumeSection.backgroundColor = style.backgroundColor
        volumeSection.valueType = .assistant
        volumeSection.key = "volume"
        volumeSection.ratios = 1
        volumeSection.padding = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        volumeSection.xAxis.tickInterval = 4
        volumeSection.xAxis.referenceStyle = .solid(color: UIColor(white: 0.4, alpha: 1))
        volumeSection.yAxis.tickInterval = 1
        volumeSection.yAxis.referenceStyle = .none
        volumeSection.yAxis.showLast = false
        
        /************** 添加主图固定的线段 **************/
        
        // 分时图
        let timelineSeries = CHSeries.getTimelinePrice(
            color: UIColor.ch_hex(0xAE475C),
            section: mainSection,
            showGuide: true,
            ultimateValueStyle: .circle(UIColor.ch_hex(0xAE475C), true),
            lineWidth: 2)
        timelineSeries.hidden = true
        // 蜡烛图
        let candleSeries = CHSeries.getCandlePrice(
            upStyle: upcolor,
            downStyle: downcolor,
            titleColor: UIColor(white: 0.8, alpha: 1),
            section: mainSection,
            showGuide: true,
            ultimateValueStyle: .arrow(UIColor(white: 0.8, alpha: 1)))
        candleSeries.showTitle = true
        candleSeries.chartModels.first?.ultimateValueStyle = .arrow(UIColor(white: 0.8, alpha: 1))
        // 分区点线样式
        let lineColors = [UIColor.ch_hex(0xDDDDDD), UIColor.ch_hex(0xF9EE30)]
        let mainMASeries = CHSeries.getPriceMA(
            isEMA: false,
            num: maNums,
            colors: lineColors,
            section: mainSection)
        mainSection.series.append(candleSeries)
        mainSection.series.append(timelineSeries)
        mainSection.series.append(mainMASeries)
        
        let volumeMASeries = CHSeries.getVolumeWithMA(
            upStyle: upcolor,
            downStyle: downcolor,
            isEMA: false,
            num: maNums,
            colors: lineColors,
            section: volumeSection
        )
        volumeMASeries.baseValueSticky = true
        volumeSection.series.append(volumeMASeries)
        style.sections.append(mainSection)
        style.sections.append(volumeSection)
        
        /************** 同时设置图表外的样式背景 **************/
        
        self.view.backgroundColor = backgroundColor
        self.topView.backgroundColor = backgroundColor
        self.toolbar.backgroundColor = backgroundColor
        
        return style
    }
}
