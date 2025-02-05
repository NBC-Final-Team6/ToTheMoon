//
//  SimpleChartView.swift
//  ToTheMoon
//
//  Created by Jimin on 2/3/25.
//

import UIKit
import SnapKit
import DGCharts

class SimpleChartView: UIView {
    private lazy var lineChartView: LineChartView = {
        let chartView = LineChartView()
        chartView.rightAxis.enabled = false
        chartView.leftAxis.enabled = false
        chartView.xAxis.enabled = false
        chartView.legend.enabled = false
        chartView.drawGridBackgroundEnabled = false
        chartView.drawBordersEnabled = false
        chartView.isUserInteractionEnabled = false
        chartView.animate(xAxisDuration: 0)
        chartView.backgroundColor = .clear
        
        // 차트 여백 최소화
        chartView.minOffset = 0
        chartView.extraTopOffset = 0
        chartView.extraBottomOffset = 0
        chartView.extraLeftOffset = 0
        chartView.extraRightOffset = 0
        chartView.layoutMargins = .zero
        return chartView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .clear
        addSubview(lineChartView)
        
        lineChartView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
    }
    
    func updateChart(with candles: [Candle], changeRate: Double) {
        
        let entries = candles.enumerated().map { index, candle in
            ChartDataEntry(x: Double(index), y: candle.close)
        }
        
        if entries.isEmpty {
            clearChart()
            return
        }
        
        let dataSet = LineChartDataSet(entries: entries)
        dataSet.mode = .linear
        dataSet.drawCirclesEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.lineWidth = 1.0
        
        if let color = UIColor(named: "NumbersGreenColor") {
            dataSet.setColor(color)
            dataSet.fillColor = color
            dataSet.drawFilledEnabled = true
            dataSet.fillAlpha = 0.1
        }
        
        let data = LineChartData(dataSet: dataSet)
        lineChartView.data = data
        lineChartView.notifyDataSetChanged()
    }
    
    func clearChart() {
        let emptyData = LineChartData()
        lineChartView.data = emptyData
        lineChartView.notifyDataSetChanged()
    }
}

class CandleChartDataManager {
    static func processCandles(_ candles: [Candle]) -> [Candle] {
        let sortedCandles = candles
            .sorted { $0.timestamp < $1.timestamp }
            .suffix(24 * 60) // 24시간 * 60분
        return Array(sortedCandles)
    }
}
