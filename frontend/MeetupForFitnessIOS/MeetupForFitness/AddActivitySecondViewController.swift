//
//  AddActivitySecondViewController.swift
//  MeetupForFitness
//
//  Created by Mengyang Shi on 3/27/17.
//  Copyright © 2017 TFBOYZ. All rights reserved.
//

import UIKit
import MapKit
import Alamofire

class AddActivitySecondViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    var activityName:String!
    var teamId:Int!
    var teamName:String!
    var sportType:String!
    var dateString:String!
    
    
    @IBOutlet weak var friendListTableView: UITableView!
    @IBOutlet weak var maximumAttendanceField: UITextField!
    @IBOutlet weak var acitivtyLocationField: UITextField!

    @IBOutlet weak var mapView: MKMapView!
    
    var matchingItems: [MKMapItem] = [MKMapItem]()
    
    var friendsInvited = [String]()
    
    let friendData = ["friend1","friend2","friend3"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        friendListTableView.delegate = self
        friendListTableView.dataSource = self
        
        maximumAttendanceField.delegate = self
        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func searchOnMap(_ sender: AnyObject) {
        _ = sender.resignFirstResponder()
        mapView.removeAnnotations(mapView.annotations)
        self.performSearch()
    }
    
    func performSearch() {
        
        matchingItems.removeAll()
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = acitivtyLocationField.text
        request.region = mapView.region
        
        let search = MKLocalSearch(request: request)
        
        search.start(completionHandler: {(response, error) in
            
            if error != nil {
                print("Error occured in search: \(error!.localizedDescription)")
            } else if response!.mapItems.count == 0 {
                print("No matches found")
            } else {
                print("Matches found")
                
                for item in response!.mapItems {
                    print("Name = \(item.name)")
                    print("Phone = \(item.phoneNumber)")
                    
                    self.matchingItems.append(item as MKMapItem)
                    print("Matching items = \(self.matchingItems.count)")
                    
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = item.placemark.coordinate
                    annotation.title = item.name
                    self.mapView.addAnnotation(annotation)
                }
            }
        })
    }
    
    
    @IBAction func addNewActivity(_ sender: Any) {
        
        let ud = UserDefaults.standard
        let userId = ud.integer(forKey: "userId")
        
        let parameters: Parameters = [
            "aName": activityName,
            "aInfo": "   ",
            "location": acitivtyLocationField.text!,
            "aTime": dateString,
            "sportsType": sportType,
            "maxPeople": maximumAttendanceField.text!,
            "teamId": teamId
        ]
        Alamofire.request("http://@ec2-52-7-74-13.compute-1.amazonaws.com/activity/add/allInfo/\(userId)", method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseString { response in
            switch response.result {
            case .success:
                print("Response String: \(response.result.value)")
                if response.result.value! == "success" {
                    self.performSegue(withIdentifier: "addActivitySuccess", sender: self)
                } else {
                    self.notifyFailure(info: "Failed to add activity!")
                }
            case .failure(let error):
                print(error)
                self.notifyFailure(info: "Cannot connect to server!")
            }
        }
    }
    
    func sendAlart(info: String) {
        let alertController = UIAlertController(title: "Hey!", message: info, preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
            (result : UIAlertAction) -> Void in
            print("OK")
        }
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func notifyFailure(info: String) {
        self.sendAlart(info: info)
    }
    
    //Mark: Table view delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "friendListCell"
        let cell: UITableViewCell = friendListTableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        let friendNameLabel = cell.contentView.viewWithTag(1) as! UILabel
        friendNameLabel.text = friendData[indexPath.row]
        
        return cell
        
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        friendsInvited.append(friendData[indexPath.row])
        tableView.cellForRow(at: indexPath)?.isHighlighted = true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true;
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        
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
