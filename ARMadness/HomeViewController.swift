//
//  HomeViewController.swift
//  ARMadness
//
//  Created by Vikash Kumar on 16/07/18.
//  Copyright © 2018 Vikash Kumar. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBOutlet weak var scoreLabel: UILabel!
    
    @IBAction func onPlayButton(_ sender: Any) {
        performSegue(withIdentifier: "homeToGameSegue", sender: self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let defaults = UserDefaults.standard
        if let gameScore = defaults.value(forKey: "score"){
            let score = gameScore as! Int
            scoreLabel.text = "Score: \(String(score))"
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
