//
//  CharViewController.swift
//  ToTheMoon
//
//  Created by 황석범 on 1/21/25.
//

import UIKit
import DGCharts

class ChartViewController: UIViewController {

    // ChartView 인스턴스 생성
    private let chartView = ChartView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        configureChartData()
    }

    private func setupViews() {
        view.backgroundColor = .white
        view.addSubview(chartView)

        // ChartView 레이아웃 설정
        chartView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func configureChartData() {
        // 예제 데이터
        let dates = ["1994", "1998", "2002", "2006", "2010", "2014", "2018", "2022", "2026", "2030", "2034", "2038", "2042"]
        let dataEntries = [
            CandleChartDataEntry(x: 0, shadowH: 100, shadowL: 80, open: 90, close: 85),
            CandleChartDataEntry(x: 1, shadowH: 105, shadowL: 70, open: 75, close: 95),
            CandleChartDataEntry(x: 2, shadowH: 110, shadowL: 90, open: 100, close: 95),
            CandleChartDataEntry(x: 3, shadowH: 95, shadowL: 65, open: 85, close: 75),
            CandleChartDataEntry(x: 4, shadowH: 120, shadowL: 100, open: 110, close: 115),
            CandleChartDataEntry(x: 5, shadowH: 115, shadowL: 95, open: 105, close: 100),
            CandleChartDataEntry(x: 6, shadowH: 130, shadowL: 110, open: 125, close: 115),
            CandleChartDataEntry(x: 7, shadowH: 90, shadowL: 70, open: 80, close: 85),
            CandleChartDataEntry(x: 8, shadowH: 110, shadowL: 85, open: 100, close: 90),
            CandleChartDataEntry(x: 9, shadowH: 95, shadowL: 75, open: 85, close: 90),
            CandleChartDataEntry(x: 10, shadowH: 105, shadowL: 85, open: 95, close: 100),
            CandleChartDataEntry(x: 11, shadowH: 120, shadowL: 100, open: 110, close: 115),
            CandleChartDataEntry(x: 12, shadowH: 125, shadowL: 105, open: 120, close: 110)
        ]

        // ChartView에 데이터 설정
        chartView.configureChart(dates: dates, dataEntries: dataEntries)
    }
}
