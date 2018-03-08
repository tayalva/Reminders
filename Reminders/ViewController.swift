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

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var newReminderView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newReminderViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var nameTextField: UITextField!
    
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
        UNUserNotificationCenter.current().delegate = self
      
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        

    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotationOnLongPress(gesture:)))
        gestureRecognizer.minimumPressDuration = 0.5
        self.mapView.addGestureRecognizer(gestureRecognizer)
        fetchData()
        
    }
    
    func regionMonitoring() {
        
        let geofenceRegionCenter = CLLocationCoordinate2DMake(pinCoordinates.latitude, pinCoordinates.longitude)
        let geofenceRegion = CLCircularRegion(center: geofenceRegionCenter, radius: 50, identifier: "Geofence")
        
        geofenceRegion.notifyOnEntry = true
        geofenceRegion.notifyOnExit = true
        locationManager.startMonitoring(for: geofenceRegion)
        
    }
    
// Fetches data to populate the table view
    

    func fetchData() {
        
        do {
            reminders = try context.fetch(Reminder.fetchRequest())
            print(reminders)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
        } catch {
            print("could not load data")
        }
    }

    @IBAction func addReminderButton(_ sender: Any) {
        clearContents()
        navigationController?.isNavigationBarHidden = false
    newReminderViewConstraint.constant = 0
        UIView.animate(withDuration: 0.2, animations: {
            self.newReminderView.alpha = 0.95
            self.view.layoutIfNeeded()
            
        })
        
    }
    
    @IBAction func nameTextDidEndAction(_ sender: Any) {
        
        reminderName = nameTextField.text!
        
    }
    
    @IBAction func enterExitSegmentedControl(_ sender: Any) {
    
        if enterExit.selectedSegmentIndex == 0 {
            
            isEntering = true
        } else {
            isEntering = false
        }
        
    }
    
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
        newReminder.locationLat = mapView.annotations[1].coordinate.latitude
        newReminder.locationLong = mapView.annotations[1].coordinate.longitude
        newReminder.isArriving = isEntering
        appDelegate.saveContext()
        
        // UI effects/transitions
        
        fetchData()
        print(reminderName)
        newReminderViewConstraint.constant = 400
        navigationController?.isNavigationBarHidden = true
        UIView.animate(withDuration: 0.3, animations: {
            self.newReminderView.alpha = 0.0
            self.view.layoutIfNeeded()
            })
            
        }
    }
    
    
    @IBAction func cancelButton(_ sender: Any) {
        
        newReminderViewConstraint.constant = 400
        navigationController?.isNavigationBarHidden = true
        UIView.animate(withDuration: 0.3, animations: {
            self.newReminderView.alpha = 0.0
            self.view.layoutIfNeeded()
        })
        
    }
    
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
            let circle = MKCircle(center: center, radius: 50)
            
          
            self.mapView.add(circle)
            self.mapView.addAnnotation(annotation)
            self.pinCoordinates = coordinate
            regionMonitoring()

            print(pinCoordinates)
          
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
        return reminders.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.textLabel?.text = reminders.reversed()[indexPath.row].name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .default, title: "Delete") { (action, indexPath) in
            
            let item = self.reminders[indexPath.row]
            self.context.delete(item)
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            self.reminders.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        
        return [delete]
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
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region is CLCircularRegion {
            print("i've exited!")
            
        handleEvent()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLCircularRegion {
            
            print("i've entered!")
            print(region)
            /*
            let alert = UIAlertController(title: "Arrived", message: "You've entered", preferredStyle: .alert)
            
            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
            
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
            */
            handleEvent()

        }
    }
    
  
    
    func handleEvent() {
        
       let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = "\(reminderName)"
        content.sound = UNNotificationSound.default()
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let identifier = "Geofence"
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
       UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        print(request)
        
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
        let circle = MKCircle(center: center, radius: 50)
        
        
        self.mapView.add(circle)
        mapView.addAnnotation(annotation)
        mapView.selectAnnotation(mapView.annotations[1], animated: true)
        let span = MKCoordinateSpanMake(0.01, 0.01)
        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        mapView.setRegion(region, animated: true)
        pinCoordinates = center
        print(pinCoordinates)
    
        
    }
}

extension ViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
       return self.view.endEditing(true)
    }
    
}

extension ViewController: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        completionHandler([.alert, .sound])
    }
}



























