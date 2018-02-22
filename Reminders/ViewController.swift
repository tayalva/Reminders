//
//  ViewController.swift
//  Reminders
//
//  Created by Taylor Smith on 2/19/18.
//  Copyright © 2018 Taylor Smith. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import CoreLocation


class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var newReminderView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var newReminderViewConstraint: NSLayoutConstraint!
    
    var testArray = ["Get Milk", "Drop off package"]
    
    let locationManager = CLLocationManager()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        mapView.delegate = self
        
        
       addLocation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }

    @IBAction func addReminderButton(_ sender: Any) {
    newReminderViewConstraint.constant = 0
        UIView.animate(withDuration: 0.2, animations: {
            self.newReminderView.alpha = 0.95
            self.view.layoutIfNeeded()
            
        })
        
    }
    
   
    @IBAction func saveButton(_ sender: Any) {
        
        newReminderViewConstraint.constant = 400
        
        UIView.animate(withDuration: 0.3, animations: {
            self.newReminderView.alpha = 0.0
            self.view.layoutIfNeeded()
            
            
            })
    }
    
    func checkAuthorizationStatus() {
        
        switch (CLLocationManager.authorizationStatus()) {
                
            case .notDetermined:
                locationManager.requestAlwaysAuthorization()
                print("not determined")
            
            case .denied:
                print("no location!")
                
            case .authorizedAlways:
                locationManager.startUpdatingLocation()
                
            case .authorizedWhenInUse:
                locationManager.requestAlwaysAuthorization()
                
            default:
                print("nothing")
      
        }
    /*
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestAlwaysAuthorization()
            print("not determined")
        } else if CLLocationManager.authorizationStatus() == .denied {
            print("no location!")
        } else if CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager.startUpdatingLocation()
            print("authorized")
        }
 
 */
        
    }
    
    func addLocation() {
        
        checkAuthorizationStatus()
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        locationManager.startUpdatingLocation()

        
    }
    

}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return testArray.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.textLabel?.text = testArray[indexPath.row]
        
        return cell
        
        
    }
}

extension ViewController: CLLocationManagerDelegate, MKMapViewDelegate {
    
   
}

