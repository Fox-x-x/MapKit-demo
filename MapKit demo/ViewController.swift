//
//  ViewController.swift
//  MapKit demo
//
//  Created by Никита Павлов on 25.05.2021.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    var locationManager = CLLocationManager()
    var currentLocations: [CLLocation] = []
    var currentPin: MKPointAnnotation?

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var deletePinButton: UIButton!
    @IBOutlet var makeRouteButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        
        deletePinButton.isEnabled = false
        makeRouteButton.isEnabled = false
        
        self.mapView.showsCompass = true
        self.mapView.showsUserLocation = true
        
        // задаем точность определения геолокации
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        // запрашиваем разрешение пользователя на определение геолокации
        locationManager.requestWhenInUseAuthorization()
        // получаем местоположение пользователя
        locationManager.startUpdatingLocation()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(pinLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 1.2 // тут указаны секунды, если поставить 1, то будет слишком быстро, если ставить дольше, то не юзерфрендли
        mapView.addGestureRecognizer(gestureRecognizer)
        
    }
    
    @objc func pinLocation(gestureRecognizer: UILongPressGestureRecognizer) {
//        1
        if gestureRecognizer.state == .began {
//        2
            let touchPoint = gestureRecognizer.location(in: self.mapView)
            let touchCoordinates = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
//        3
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchCoordinates
            annotation.title = "Сюда"
            annotation.subtitle = "Новая точка на карте"
            
            currentPin = annotation
//        4
            self.mapView.addAnnotation(annotation)
            deletePinButton.isEnabled = true
            makeRouteButton.isEnabled = true
            
        }
    }
    
    @IBAction func deletePin(_ sender: Any) {
        
        let annotations = self.mapView.annotations
        self.mapView.removeAnnotations(annotations)
        
        let overlays = self.mapView.overlays
        self.mapView.removeOverlays(overlays)
        
        deletePinButton.isEnabled = false
        makeRouteButton.isEnabled = false
    }
    
    @IBAction func makeRouteButtonPressed(_ sender: Any) {
        makeRoute()
        makeRouteButton.isEnabled = false
    }
    
    // создаем функцию, которая будет получать местоположение и наводить карту на него
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: location, span: span)
        currentLocations = locations
        mapView.setRegion(region, animated: true)
    }
    
    func makeRoute() {
        // making the route
        if !currentLocations.isEmpty, let currentPin = currentPin {
            let request = MKDirections.Request()
            
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(
                latitude: currentLocations[0].coordinate.latitude,
                longitude: currentLocations[0].coordinate.longitude))
            )
            
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(
                latitude: currentPin.coordinate.latitude,
                longitude: currentPin.coordinate.longitude))
            )
            
            request.transportType = .automobile
            
            let directions = MKDirections(request: request)
            
            directions.calculate { response, error in
                
                guard let response = response else {
                    print("ошибка в попытке построить маршрут: \(error.debugDescription)")
                    return
                }
                
                if let route = response.routes.first {
                    self.mapView.addOverlay(route.polyline, level: .aboveRoads)
                    let rect = route.polyline.boundingMapRect
                    self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
                }
                
            }
            
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.lineWidth = 3.5
        renderer.strokeColor = .systemRed
        
        return renderer
    }


}

