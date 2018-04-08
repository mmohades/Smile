//
//  ViewController.swift
//  Smile
//
//  Created by Maksim Ekin Eren on 4/6/18.
//  Copyright © 2018 Smile. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var label: UIImageView!
    @IBOutlet weak var smileLogo: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func faceA(_ sender: UIButton) {
        UIView.animate(withDuration: 0.3, animations: {
            self.smileLogo.transform = self.smileLogo.transform.rotated(by: CGFloat.init(M_PI_2))
        }) { (finished) in
            
        }
    }
    
    @IBAction func smileA(_ sender: UIButton) {
        UIView.animate(withDuration: 0.3, animations: {
            self.smileLogo.transform = self.smileLogo.transform.rotated(by: CGFloat.init(M_PI_2))
        }) { (finished) in
            
        }
    }
    
    @IBAction func labelBA(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1, animations: {
            self.label.transform = self.label.transform.scaledBy(x: 1.02, y: 1.02)
        }) { (finished) in
            UIView.animate(withDuration: 0.1, animations: {
                self.label.transform = self.label.transform.scaledBy(x: 0.98, y: 0.98)
            }) { (finished) in
                
            }
        }
    }
    
}

