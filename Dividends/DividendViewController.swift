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

    override func viewDidLoad() {
        super.viewDidLoad()

        currencyFormatter.numberStyle = .decimal
        currencyFormatter.maximumFractionDigits = 4
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        for symbol in symbols {
            let index = downloadedInfo.count
            let info = StockInfo(symbol: symbol, name: "", dividend: "")
            downloadedInfo.append(info)
            print("\(symbol)")
            let symbolRequest = RestClient.client.clientURLRequest("https://api.iextrading.com/1.0/stock/\(symbol)/stats")
//            let symbolRequest = RestClient.client.clientURLRequest("https://api.iextrading.com/1.0/stock/\(symbol)/dividends")
            let localFormatter = currencyFormatter
            RestClient.client.get(symbolRequest, success: { [weak self] response in
                if let dividendData = response as? Dictionary<String, AnyObject> {
                    print("\(dividendData)")
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
                    print("\(responseArray)")
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

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
