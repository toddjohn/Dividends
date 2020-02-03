//
//  DividendViewController.swift
//  Dividends
//
//  Created by Todd Johnson on 12/19/18.
//  Copyright © 2018 Todd Johnson. All rights reserved.
//

import UIKit

class DividendViewController: UITableViewController {

    var symbols = [String]()
    private var selectedSymbol = "MSFT"

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return symbols.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DividendCell", for: indexPath)

        if let dividendCell = cell as? DividendTableViewCell {
            dividendCell.symbolLabel?.text = symbols[indexPath.row]
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedSymbol = symbols[indexPath.row]
        print("selected \(indexPath.row) - \(selectedSymbol)")
        self.performSegue(withIdentifier: "DividendHistorySegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dividendHistoryViewController = segue.destination as? DividendHistoryViewController {
            dividendHistoryViewController.symbol = selectedSymbol
        }
    }
}
