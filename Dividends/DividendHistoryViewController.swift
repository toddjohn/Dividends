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

class DividendHistoryViewController: UITableViewController {

    var symbol = "MSFT"
    private var dividends = [HistoryInfo]()
    let currencyFormatter = NumberFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        currencyFormatter.numberStyle = .decimal
        currencyFormatter.maximumFractionDigits = 4
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        self.navigationItem.title = "\(symbol) Dividends"
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        let symbolRequest = RestClient.client.clientURLRequest("https://api.iextrading.com/1.0/stock/\(symbol)/dividends/2y")
        let localFormatter = currencyFormatter
        RestClient.client.get(symbolRequest, success: { [weak self] response in
//            print("Success: \(String(describing: response))")
            if let responseArray = response as? [Dictionary<String, Any>] {
//                print("\(responseArray)")
                for historyItem in responseArray {
                    var dividendAmount = "0"
                    if let amount = historyItem["amount"] as? NSNumber, let amountString = localFormatter.string(from: amount) {
                        dividendAmount = amountString
                    }
                    var dividendDate = "1/1/1970"
                    if let date = historyItem["paymentDate"] as? String {
                        dividendDate = date
                    }
                    let info = HistoryInfo(date: dividendDate, dividend: dividendAmount)
                    self?.dividends.append(info)
                }
            }
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }, failure: { error in
            print("Error: \(error)")
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

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
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
