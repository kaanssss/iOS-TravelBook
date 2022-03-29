//
//  ViewController.swift
//  UdemyTravelBook
//
//  Created by Kaan Yalçınkaya on 30.11.2021.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    @IBOutlet weak var nameText: UITextField!
    
    @IBOutlet weak var commentText: UITextField!
    
    @IBOutlet weak var mapView: MKMapView!
    var locationManager = CLLocationManager()
    var chosenLatitude = Double()
    var chosenLongitude = Double()
    
    //Seçilen yer
    
    var selectedTitle = ""
    var selectedTitleID : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Map
        
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gesturerecognizer:)))
        //kullanıcı kaç saniye bastıgında işlem alsın.
        gestureRecognizer.minimumPressDuration = 2
        mapView.addGestureRecognizer(gestureRecognizer)
        
        if selectedTitle != "" {
            //CoreData çekme işlemi(ListView üzerinden)
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchrequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedTitleID!.uuidString
            fetchrequest.predicate = NSPredicate(format: "id = %@", idString)//sadece id stringine eşit olan kişileri çağırmak için.
            fetchrequest.returnsObjectsAsFaults = false
            do{
                let results = try context.fetch(fetchrequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        
                        if let title = result.value(forKey: "title") as? String {
                            annotationTitle = title
                            if let subtitle = result.value(forKey: "subtitle") as? String{
                                annotationSubtitle = subtitle
                                if let longitude = result.value(forKey: "longitude") as? Double {
                                    annotationLongitude = longitude
                                    if let latitude = result.value(forKey: "latitude") as? Double {
                                        annotationLatitude = latitude
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationSubtitle
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = coordinate
                                        
                                        mapView.addAnnotation(annotation)
                                        nameText.text = annotationTitle
                                        commentText.text = annotationSubtitle
                                        
                                        locationManager.stopUpdatingLocation()
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                        
                            }
                        }
                        
                    }
                        
                 }
             }
        }

    }
            catch{
                print("error")
            }
        }
        else {
            
        }
        
    }
    
    @objc func chooseLocation(gesturerecognizer:UILongPressGestureRecognizer) {
        
        //gesturerecognizer başlayıp başlamadığını kontrol etmek için
        
        if gesturerecognizer.state == .began{
            
            let touchedPoint = gesturerecognizer.location(in: self.mapView)
            let touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
            
            //kullanıcı her dokunduğunda longitude latitude değişecektirmek için.
            chosenLatitude = touchedCoordinates.latitude
            chosenLongitude = touchedCoordinates.longitude
            
            //pin oluşturma
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates
            annotation.title = nameText.text
            annotation.subtitle = commentText.text
            self.mapView.addAnnotation(annotation)
            
        }
        
    }
    
    //Güncellenen lokasyonları dizi içerisinde vermeyi sağlıyor.
    //CLLocation objesi enlem ve boylam barındıran obje.
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedTitle == ""{
        let locations = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        //zoom için yapılıyor. 0.1 vermek en zoom ayarı için
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: locations, span: span)
        mapView.setRegion(region, animated: true)
        }
        else{
    }
        
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
            
        let reuseId = "myAnnonation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: "reuseId") as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            //bir baloncukla birlikte ekstra bilgi gösterdiğimiz yer
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.black
            //detay göstermek için
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        }
        else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    
    //(i) bilgi butonuna tıklamak için
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
       if selectedTitle != "" {
           let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
           
           //Navigasyonu çalıştırmak için (closure)
           CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemark, Error) in
               if let placemark = placemark {
                   if placemark.count > 0 {
                       
                       let newPlacemark = MKPlacemark(placemark: placemark[0])
                       let item = MKMapItem(placemark: newPlacemark)
                       item.name = self.annotationTitle
                       let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                       item.openInMaps(launchOptions: launchOptions)
                   }
               }
               
              
           }
        }
    }
    
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        newPlace.setValue(nameText.text, forKey: "title")
        newPlace.setValue(commentText.text, forKey: "subtitle")
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(chosenLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        do{
            try context.save()
        }
        catch{
            print("error")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
        //bi önceki view controllera gönderiyor.
        navigationController?.popViewController(animated: true)
        
    }
    
}

