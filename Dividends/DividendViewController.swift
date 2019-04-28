//
//  DividendViewController.swift
//  Dividends
//
//  Created by Todd Johnson on 12/19/18.
//  Copyright © 2018 Todd Johnson. All rights reserved.
//

import UIKit

struct StockInfo {
    let symbol: String
    let name: String
    let dividend: String
}

class DividendViewController: UITableViewController {

    var symbols = [String]()
    private var downloadedInfo = [StockInfo]()
    let currencyFormatter = NumberFormatter()
    private var selectedSymbol = "MSFT"

    override func viewDidLoad() {
        super.viewDidLoad()

        currencyFormatter.numberStyle = .decimal
        currencyFormatter.maximumFractionDigits = 4

        for symbol in symbols {
            let index = downloadedInfo.count
            let info = StockInfo(symbol: symbol, name: "", dividend: "")
            downloadedInfo.append(info)
            print("\(symbol)")
            let symbolRequest = RestClient.client.clientURLRequest("https://api.iextrading.com/1.0/stock/\(symbol)/stats")
            let localFormatter = currencyFormatter
            RestClient.client.get(symbolRequest, success: { [weak self] response in
                if let dividendData = response as? Dictionary<String, AnyObject> {
//                    print("\(dividendData)")
                    print("dividend amount \(String(describing: dividendData["dividendRate"]))")
                    if let amount = dividendData["dividendRate"] as? NSNumber, let name = dividendData["companyName"] as? String {
                        print("dividend = \(String(describing: localFormatter.string(from: amount)))")
                        if let dividend = localFormatter.string(from: amount) {
                            let updatedInfo = StockInfo(symbol: symbol, name: name, dividend: dividend)
                            self?.downloadedInfo[index] = updatedInfo
                            DispatchQueue.main.async {
                                self?.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                            }
                        }
                    }
                } else if let responseArray = response as? [Any] {
//                    print("\(responseArray)")
                    if let responseDict = responseArray.first as? Dictionary<String, Any> {
                        print("Dividend amount \(String(describing: responseDict["amount"]))")
                        if let amount = responseDict["amount"] as? NSNumber {
                            print("dividend = \(String(describing: localFormatter.string(from: amount)))")
                        }
                    }
                }
            }, failure: { error in
                print("Error: \(error)")
            })
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return downloadedInfo.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DividendCell", for: indexPath)

        if let dividendCell = cell as? DividendTableViewCell {
            dividendCell.symbolLabel?.text = downloadedInfo[indexPath.row].symbol
            dividendCell.nameLabel?.text = downloadedInfo[indexPath.row].name
            dividendCell.dividendLabel?.text = downloadedInfo[indexPath.row].dividend
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("selected \(indexPath.row)")
        selectedSymbol = downloadedInfo[indexPath.row].symbol
        self.performSegue(withIdentifier: "DividendHistorySegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dividendHistoryViewController = segue.destination as? DividendHistoryViewController {
            dividendHistoryViewController.symbol = selectedSymbol
        }
    }
}
