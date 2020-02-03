//
//  DividendHistoryViewController.swift
//  Dividends
//
//  Created by Todd Johnson on 4/28/19.
//  Copyright © 2019 Todd Johnson. All rights reserved.
//

import UIKit

struct HistoryInfo {
    let date: String
    let dividend: String
}
struct DividendHistory: Decodable {
    let data: [DividendData]
    
    private enum CodingKeys : String, CodingKey {
        case data = "Data"
    }
}

struct DividendData: Decodable {
    let TotDiv: Float
//    let Income: Float
//    let CapitalReturn: Float
//    let CapitalLT: Float?
//    let Special: Float?
    let PayDateDisplay: String
//    let ExDivDateDisplay: String
//    let DeclaredDateDisplay: String
}

class DividendHistoryViewController: UITableViewController {

    var symbol = "MSFT"
    private var dividends = [HistoryInfo]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let localFormatter = NumberFormatter()
        localFormatter.numberStyle = .decimal
        localFormatter.maximumFractionDigits = 4

        self.navigationItem.title = "\(symbol) Dividends"

        let today = Date()
        var dateComponents = DateComponents()
        dateComponents.year = -1
        let yearAgo = Calendar.current.date(byAdding: dateComponents, to: today)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"
        let todayString = dateFormatter.string(from: today)
        let yearAgoString = dateFormatter.string(from: yearAgo!)
        
        let symbolRequest = RestClient.client.clientURLRequest("https://www.cefconnect.com/api/v3/distributionhistory/fund/\(symbol)/\(yearAgoString)/\(todayString)")
        RestClient.client.get(symbolRequest, success: { response in
        }, failure: { error in
            print("Error: \(error)")
        }, successWithData: { [weak self] data in
            let decoder = JSONDecoder()
            do {
                let history = try decoder.decode(DividendHistory.self, from: data)
                for item in history.data {
                    let amountString = localFormatter.string(from: NSNumber(value: item.TotDiv)) ?? "0.0"
                    let info = HistoryInfo(date: item.PayDateDisplay, dividend: amountString)
                    self?.dividends.append(info)
                }
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            } catch {
                print(error.localizedDescription)
                if let jsonString = String(data: data, encoding: .utf8) {
                    print(jsonString)
                }
            }
        })
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dividends.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DividendHistoryCell", for: indexPath)

        if let dividendCell = cell as? DividendHistoryTableViewCell {
            dividendCell.dateLabel?.text = dividends[indexPath.row].date
            dividendCell.dividendLabel?.text = dividends[indexPath.row].dividend
        }
        
        return cell
    }
}
