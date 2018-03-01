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

protocol HandleMapSearch {
    
    func dropPinZoomIn(placemark: MKPlacemark)
    
}

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var newReminderView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newReminderViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var saveButtonOutlet: UIButton!
    @IBOutlet weak var cancelButtonOutlet: UIButton!
    
    
    var testArray = ["Get Milk", "Drop off package"]
    var annotationIsPlaced: Bool = false
    let locationManager = CLLocationManager()
    var selectedPin: MKPlacemark? = nil
    var reminderName: String = ""


    
    var resultsSearchController: UISearchController? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameTextField.delegate = self
        locationManager.delegate = self
        mapView.delegate = self
        addLocation()
        
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchTable
        
        resultsSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultsSearchController?.searchResultsUpdater = locationSearchTable
        let searchBar = resultsSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search here or place a pin!"
        navigationItem.titleView = resultsSearchController?.searchBar
        resultsSearchController?.hidesNavigationBarDuringPresentation = false
        resultsSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        

        locationSearchTable.mapView = mapView
        locationSearchTable.handleMapSearchDelegate = self
      
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotationOnLongPress(gesture:)))
        gestureRecognizer.minimumPressDuration = 0.5
        self.mapView.addGestureRecognizer(gestureRecognizer)
        
    }

    @IBAction func addReminderButton(_ sender: Any) {
        navigationController?.isNavigationBarHidden = false
    newReminderViewConstraint.constant = 0
        UIView.animate(withDuration: 0.2, animations: {
            self.newReminderView.alpha = 0.95
            self.view.layoutIfNeeded()
            
        })
        
    }
    
    @IBAction func nameTextDidEndAction(_ sender: Any) {
        
        
    }
    
    
    @IBAction func saveButton(_ sender: Any) {
        
        newReminderViewConstraint.constant = 400
        navigationController?.isNavigationBarHidden = true
    
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
    }
    
    func addLocation() {
        
        checkAuthorizationStatus()
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        locationManager.startUpdatingLocation()
      
        
    }
    
    @objc func addAnnotationOnLongPress(gesture: UILongPressGestureRecognizer){
        
        if gesture.state == .ended {
            
            mapView.removeAnnotations(mapView.annotations)
            mapView.removeOverlays(mapView.overlays)
            let point = gesture.location(in: self.mapView)
            let coordinate = self.mapView.convert(point, toCoordinateFrom: self.mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "Remind Me"
            
            let center = coordinate
            let circle = MKCircle(center: center, radius: 150)
            
        
            self.mapView.add(circle)
            self.mapView.addAnnotation(annotation)
          
        }
    }
 // helper methods to raise/lower the view above the keyboard when naming the reminder
 
    @objc func keyboardWillShow(notification: NSNotification) {
        
        if nameTextField.isEditing {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0{
                self.view.frame.origin.y -= keyboardSize.height
                saveButtonOutlet.isEnabled = false
                saveButtonOutlet.alpha = 0.5
                cancelButtonOutlet.isEnabled = false
                cancelButtonOutlet.alpha = 0.5
                print(self.view.frame.origin.y)
            }
        }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
       
   
            if self.view.frame.origin.y != 0{
                self.view.frame.origin.y = 0.0
                saveButtonOutlet.isEnabled = true
                saveButtonOutlet.alpha = 1.0
                cancelButtonOutlet.isEnabled = true
                cancelButtonOutlet.alpha = 1.0
                print(self.view.frame.origin.y)
            
        }
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
 
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if overlay.isKind(of: MKCircle.self) {
            
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.fillColor = UIColor.green.withAlphaComponent(0.1)
            circleRenderer.strokeColor = UIColor.green
            circleRenderer.lineWidth = 1
            return circleRenderer
        }
        
        return MKOverlayRenderer(overlay: overlay)
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        

        let annotationView = MKPinAnnotationView()
        if annotation.title! != "My Location" {
        annotationView.animatesDrop = true
        annotationView.pinTintColor = UIColor.darkGray
        annotationView.canShowCallout = true
        return annotationView
        }
        
        return nil
    }
    
  
    
}

extension ViewController: HandleMapSearch {
    
    func dropPinZoomIn(placemark: MKPlacemark) {
        selectedPin = placemark
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        if let city = placemark.locality, let state = placemark.administrativeArea {
            annotation.subtitle = "\(city) \(state)"
        }
        
        let center = placemark.coordinate
        let circle = MKCircle(center: center, radius: 150)
        
        
        self.mapView.add(circle)
        mapView.addAnnotation(annotation)
        mapView.selectAnnotation(mapView.annotations[1], animated: true)
        let span = MKCoordinateSpanMake(0.01, 0.01)
        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        mapView.setRegion(region, animated: true)
        print(mapView.annotations.count)
    
        
    }
}

extension ViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
       return self.view.endEditing(true)
    }
    
}


