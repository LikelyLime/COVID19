//
//  ViewController.swift
//  COVID19
//
//  Created by 백시훈 on 2022/09/28.
//

import UIKit
import Alamofire
import Charts

class ViewController: UIViewController {

    @IBOutlet weak var totalCaseLabel: UILabel!
    @IBOutlet weak var newCaseLabel: UILabel!
    
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    @IBOutlet weak var labelStackView: UIStackView!
    @IBOutlet weak var pieChartView: PieChartView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.indicatorView.startAnimating()
        self.fetchCovidOverview(completionHandler: {[weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(result):
                self.indicatorView.stopAnimating()
                self.indicatorView.isHidden = true
                self.labelStackView.isHidden = false
                self.pieChartView.isHidden = false
                self.configureStackView(koreaCovidOverview: result.korea)
                let covidOverviewList = self.makeCovidOverviewList(cityCovidOverview: result)
                self.configureChartView(covidOverviewList: covidOverviewList)
            case let .failure(error):
                debugPrint("fail\(error)")
            }
        })
    }
    /**
     pieCart에 값을 추가하기 위해 API return값을 리스트에 담아 리턴하는 메서드
     */
    func makeCovidOverviewList(
        cityCovidOverview: CityCovidOverview
    ) -> [CovidOverview]{
        return [
            cityCovidOverview.seoul,
            cityCovidOverview.busan,
            cityCovidOverview.daejeon,
            cityCovidOverview.incheon,
            cityCovidOverview.daegu,
            cityCovidOverview.gwangju,
            cityCovidOverview.ulsan,
            cityCovidOverview.sejong,
            cityCovidOverview.gyeonggi,
            cityCovidOverview.jeonbuk,
            cityCovidOverview.jeonnam,
            cityCovidOverview.gyeongbuk,
            cityCovidOverview.gyeongnam,
            cityCovidOverview.jeju
        ]
    }
    
    /**
     pieChart에 값을 추가하는 메서드
     */
    func configureChartView(covidOverviewList: [CovidOverview]){
        //상세보기 --
        self.pieChartView.delegate = self
        //-----
        
        let entries = covidOverviewList.compactMap{[weak self] overview -> PieChartDataEntry? in
            guard let self = self else { return nil }
            return PieChartDataEntry(
                value: self.removeFormatString(str: overview.newCase),
                label: overview.countryName,
                data: overview
             )
            
        }
        let dataSet = PieChartDataSet(entries: entries, label: "코로나 발생 현황")
        //차트의 구간을 생성
        dataSet.sliceSpace = 1
        dataSet.entryLabelColor = .black
        dataSet.valueTextColor = .black
        dataSet.xValuePosition = .outsideSlice
        dataSet.valueLinePart1OffsetPercentage = 0.8
        dataSet.valueLinePart1Length = 0.2
        dataSet.valueLinePart2Length = 0.3
        
        //컬러 작성
        dataSet.colors = ChartColorTemplates.vordiplom() +
        ChartColorTemplates.joyful() +
        ChartColorTemplates.pastel() +
        ChartColorTemplates.liberty() +
        ChartColorTemplates.material()
        
        self.pieChartView.data = PieChartData(dataSet: dataSet)
        self.pieChartView.spin(duration: 0.3, fromAngle: self.pieChartView.rotationAngle, toAngle: self.pieChartView.rotationAngle + 80)
    }
    
    /**
     문자열을 double타입으로 변경하는 메서드
     */
    func removeFormatString(str: String) -> Double{
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.number(from: str)?.doubleValue ?? 0
    }
    /**
     main페이지에 나오는 값 세팅하는 메서드
     */
    func configureStackView(koreaCovidOverview: CovidOverview){
        self.totalCaseLabel.text = "\(koreaCovidOverview.totalCase) 명"
        self.newCaseLabel.text = "\(koreaCovidOverview.newCase) 명"
    }
    
    /**
    COVID19 API호출하는 메서드
     */
    func fetchCovidOverview(
        completionHandler: @escaping  (Result<CityCovidOverview, Error>) -> Void
    ){
        let url = "https://api.corona-19.kr/korea/country/new/"
        let param = [
            "serviceKey": "5VW61nSNEicgByjaJUvzuXYxp9T8sZFoO"
        ]
        AF.request(url, method: .get, parameters: param)
            .responseData(completionHandler: { response in
                switch response.result{
                case let .success(data):
                    do{
                        let decoder = JSONDecoder()
                        let result = try decoder.decode(CityCovidOverview.self, from: data)
                        completionHandler(.success(result))
                    }catch{
                        completionHandler(.failure(error))
                    }
                
                case let .failure(error):
                    completionHandler(.failure(error))
                }
            })
    }
}

extension ViewController: ChartViewDelegate{
    //차트가 선택되었을 때 진행되는 함수
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        guard let covidDetailViewController = self.storyboard?.instantiateViewController(identifier: "CovidDetailViewController") as? CovidDetailViewController else { return }
        guard let covidOverview = entry.data as? CovidOverview else { return }
        covidDetailViewController.covidOverview = covidOverview
        self.navigationController?.pushViewController(covidDetailViewController, animated: true)
    }
}
