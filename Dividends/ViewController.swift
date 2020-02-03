//
//  ViewController.swift
//  Dividends
//
//  Created by Todd Johnson on 12/19/18.
//  Copyright © 2018 Todd Johnson. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {

    var portfolioSymbols = [[String]]()
    var selectedSymbols = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.title = "Portfolios"
        let Fidelity401k  = ["CHI", "ETJ", "JPS", "JRO"]
        portfolioSymbols.append(Fidelity401k)
//        let IRA = ["AAPL", "AXS", "BDX", "CVX", "EMD", "GPC", "HSY", "IBM", "KMB", "KWEB", "MAIN", "MCD", "MSFT", "NMFC", "O", "OAK", "PSEC", "STAG", "SYY", "T", "TGT", "WRB"]
        let IRA = ["EMD"]
        portfolioSymbols.append(IRA)
//        let trading = ["ABT", "BSM", "BX", "BXMT", "CTL", "EXG", "FAX", "IGD", "IIM", "LADR", "MO", "OHI", "VNOM"]
        let trading = ["EXG", "FAX", "IGD", "IIM"]
        portfolioSymbols.append(trading)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("selected \(indexPath.row)")
        selectedSymbols = portfolioSymbols[indexPath.row]
        self.performSegue(withIdentifier: "DividendSegue", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dividendViewController = segue.destination as? DividendViewController {
            dividendViewController.symbols = selectedSymbols
        }
    }
}
