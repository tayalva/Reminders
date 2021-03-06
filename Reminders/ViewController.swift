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
import UserNotifications

protocol HandleMapSearch {
    
    func dropPinZoomIn(placemark: MKPlacemark)
    
}

class ViewController: UIViewController {
    
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var reminders: [Reminder] = []
    var reversedReminders: [Reminder] = []

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var newReminderView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var reminderMapView: MKMapView!
    @IBOutlet weak var reminderLabel: UILabel!
    @IBOutlet weak var reminderView: UIView!

    @IBOutlet weak var newReminderViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var addReminderButtonOutlet: UIButton!
    @IBOutlet weak var saveButtonOutlet: UIButton!
    @IBOutlet weak var cancelButtonOutlet: UIButton!
    @IBOutlet weak var enterExit: UISegmentedControl!
    
    
    var annotationIsPlaced: Bool = false
    let locationManager = CLLocationManager()
    var selectedPin: MKPlacemark? = nil
    var reminderName: String = ""
    var resultsSearchController: UISearchController? = nil
    var isEntering: Bool = true
    let center = UNUserNotificationCenter.current()
    let options: UNAuthorizationOptions = [.alert, .sound]
    let content = UNMutableNotificationContent()
    var pinCoordinates = CLLocationCoordinate2D()
    
    
// sets up search bar, delegates, notification center, etc.
    
    override func viewDidLoad() {
        super.viewDidLoad()

        nameTextField.delegate = self
        locationManager.delegate = self
        mapView.delegate = self
        reminderMapView.delegate = self
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
        UNUserNotificationCenter.current().delegate = self
      
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
     
        

    }
    
    override func viewWillAppear(_ animated: Bool) {
 
// sets up long press gesture recognizer to place pins
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotationOnLongPress(gesture:)))
        gestureRecognizer.minimumPressDuration = 0.5
        self.mapView.addGestureRecognizer(gestureRecognizer)
        fetchData()
        
    }

// Function that enables monitoring of geofences
    
    func regionMonitoring(geofence: Reminder) {
    
        let geofenceRegionCenter = CLLocationCoordinate2DMake(geofence.locationLat, geofence.locationLong)
        let geofenceRegion: CLCircularRegion = CLCircularRegion(center: geofenceRegionCenter, radius: 50, identifier: geofence.identifier!)
        
        if geofence.isArriving == true {
        geofenceRegion.notifyOnEntry = true
        geofenceRegion.notifyOnExit = false
        } else if geofence.isArriving == false {
        geofenceRegion.notifyOnExit = true
        geofenceRegion.notifyOnEntry = false
        }
        locationManager.startMonitoring(for: geofenceRegion)
        
    }

// removes geofences from monitored regions array
    
    func stopMonitoring(geofence: Reminder) {
        
        for region in locationManager.monitoredRegions {
           
            if geofence.identifier == region.identifier {
            locationManager.stopMonitoring(for: region)
              
        }
          

        }
    }
    
// Fetches data to populate the table view
    

    func fetchData() {
        
        do {
            reminders = try context.fetch(Reminder.fetchRequest())
            reversedReminders = reminders.reversed()
            DispatchQueue.main.async {
                
            
                self.tableView.reloadData()
            }
            
        } catch {
            print("could not load data")
        }
    }

//Add reminder button that swoops in newReminderView
    
    @IBAction func addReminderButton(_ sender: Any) {
        clearContents()
        
   newReminderViewConstraint.constant = 0
        UIView.animate(withDuration: 0.2, animations: {
            self.newReminderView.alpha = 0.95
            self.navigationController?.isNavigationBarHidden = false
            self.view.layoutIfNeeded()
               // self.newReminderView.frame.origin.x -= 600
            
        })
        
    }
    
// IBAction that asigns the name textfield to a variable at the end of typing
    
    @IBAction func nameTextDidEndAction(_ sender: Any) {
        
        reminderName = nameTextField.text!
        
    }

// segmeneted control button that enables entering/exiting for a new reminder
    
    @IBAction func enterExitSegmentedControl(_ sender: Any) {
    
        if enterExit.selectedSegmentIndex == 0 {
            
            isEntering = true
        } else {
            isEntering = false
        }
        
    }
  
// All context saves happen in here
    @IBAction func saveButton(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
       
        
        if nameTextField.text == "" || mapView.annotations.count != 2 {
            
            let alert = UIAlertController(title: "Uh Oh!", message: "Make sure you have placed a pin and set a name!", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .default) { action in
                
            })
            
            self.present(alert, animated: true, completion: nil)
        } else {
        
     
        
        let newReminder = Reminder(context: context)
        newReminder.name = nameTextField?.text
        newReminder.locationLat = pinCoordinates.latitude
        newReminder.locationLong = pinCoordinates.longitude
        newReminder.identifier = UUID().description
        newReminder.isArriving = isEntering
        appDelegate.saveContext()
        
        // UI effects/transitions
        
        fetchData()
        regionMonitoring(geofence: newReminder)
            print(reversedReminders)
        newReminderViewConstraint.constant = 600
        navigationController?.isNavigationBarHidden = true
        UIView.animate(withDuration: 0.3, animations: {
            self.newReminderView.alpha = 0.0
            self.view.layoutIfNeeded()
            })
            
        }
    }
    
// Cancel button that also dismisses newReminderView
    
    @IBAction func cancelButton(_ sender: Any) {
        
       newReminderViewConstraint.constant = 600
        navigationController?.isNavigationBarHidden = true
        UIView.animate(withDuration: 0.3, animations: {
            self.newReminderView.alpha = 0.0
            self.view.layoutIfNeeded()
            //self.newReminderView.frame.origin.x += 600

        })
        
    }

// Clears contents of newReminderView
    func clearContents() {
        
        enterExit.selectedSegmentIndex = 0
        isEntering = true
        
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        
        nameTextField.text = nil
        addLocation()
        
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
// Adds the users location
    
    func addLocation() {
        
        checkAuthorizationStatus()
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        locationManager.startUpdatingLocation()
      
        
    }
    
// dismisses mapview of selected reminder
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
      //  let touch: UITouch? = touches.first
        tableView.isUserInteractionEnabled = true
        addReminderButtonOutlet.isEnabled = true

            UIView.animate(withDuration: 0.5, animations: {
                 self.reminderView.alpha = 0
                })
            
        
    }
 

// Adds an annotation on the mapView via a long press
    
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
            let circle = MKCircle(center: center, radius: 50)
            
          
            self.mapView.add(circle)
            self.mapView.addAnnotation(annotation)
            self.pinCoordinates = coordinate
          
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
                reminderName = nameTextField.text!

            
        }
    }


}


// MARK: TableView Methods


extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reversedReminders.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let item = reversedReminders[indexPath.row]
        
        cell.textLabel?.text = item.name
        
        return cell
    }
   
// Deletes a row by swiping (also deletes from core data)
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .default, title: "Delete") { (action, indexPath) in
            
        let item = self.reversedReminders[indexPath.row]
             self.stopMonitoring(geofence: item)
            

            self.context.delete(item)
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            self.reversedReminders.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
           self.reminders = self.reversedReminders.reversed()
         
        }
        
        return [delete]
    }
 
    
// shows a user disabled mapview to have a quick glance at existing reminders
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        UIView.animate(withDuration: 0.3, animations: {
            self.reminderView.alpha = 0.9
        })
        tableView.isUserInteractionEnabled = false
        addReminderButtonOutlet.isEnabled = false
        let item = reversedReminders[indexPath.row]
        reminderMapView.removeAnnotations(reminderMapView.annotations)
        reminderMapView.removeOverlays(reminderMapView.overlays)
        reminderLabel.text = item.name
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2DMake(item.locationLat, item.locationLong)
        
        let circle = MKCircle(center: annotation.coordinate, radius: 50)
        
       
        
        reminderMapView.addAnnotation(annotation)
         self.reminderMapView.add(circle)
        let span = MKCoordinateSpanMake(0.005, 0.005)
        let region = MKCoordinateRegionMake(annotation.coordinate, span)
        reminderMapView.setRegion(region, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
        
        
    
    }
}

// MARK: MapView/Location Methods

extension ViewController: CLLocationManagerDelegate, MKMapViewDelegate {
 
    
    
// Delegate method that sets attributes for the geofence radius circle to be drawn on the map
    
    
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
    
// Delegate method that changes the pin style from the default red bubble
    
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
    

 // Enter/Exit geofence delegate methods
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region is CLCircularRegion {
                    
                    handleEvent(forRegion: region)
        
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLCircularRegion {
    
           handleEvent(forRegion: region)
            
        }
    }
    
  
// This method triggers the local notification when the user enters/exits a given reminder
    
    func handleEvent(forRegion region: CLRegion) {
        
       let content = UNMutableNotificationContent()
        
        for item in reversedReminders {
            
            if item.identifier == region.identifier {
                
                content.title = item.name!
       
   
        content.sound = UNNotificationSound.default()
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let identifier = region.identifier
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
       UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
       
                
            }
        }
        
    }
    
}


//This method drops a pin if the user elects to search for a location instead of placing a pin manually

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
        let circle = MKCircle(center: center, radius: 50)
        
        
        self.mapView.add(circle)
        mapView.addAnnotation(annotation)
        mapView.selectAnnotation(mapView.annotations[1], animated: true)
        let span = MKCoordinateSpanMake(0.01, 0.01)
        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        mapView.setRegion(region, animated: true)
        pinCoordinates = center
      
    
        
    }
}

extension ViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
       return self.view.endEditing(true)
    }
    
}


//allows for the local notifcaiton to be displayed while in the app itself

extension ViewController: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        completionHandler([.alert, .sound])
    }
}



























