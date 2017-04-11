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
    
    var friendData = [(Int, String)]()
    
    @IBOutlet weak var friendListTableView: UITableView!
    @IBOutlet weak var maximumAttendanceField: UITextField!
    @IBOutlet weak var acitivtyLocationField: UITextField!
    @IBOutlet weak var infoField: UITextField!

    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var createActivityButton: UIButton!
    
    
    var matchingItems: [MKMapItem] = [MKMapItem]()
    
    var friendsInvitedIds = [Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        friendListTableView.delegate = self
        friendListTableView.dataSource = self
        
        maximumAttendanceField.delegate = self
        acitivtyLocationField.delegate = self
        infoField.delegate = self
        
        self.friendListTableView.allowsMultipleSelection = true
        // Do any additional setup after loading the view.
        getFriendsFromServer()
    }
    
    func getFriendsFromServer() {
        let ud = UserDefaults.standard
        let userId = ud.integer(forKey: "currentUserId")
        
        Alamofire.request("http://@ec2-52-7-74-13.compute-1.amazonaws.com/friends/\(userId)", method: .get, encoding: JSONEncoding.default).validate().responseJSON { response in
            switch response.result {
            case .success:
                print("Validation Successful")
                if let json = response.result.value {
                    self.friendData.removeAll()
                    
                    print("JSON: \(json)")
                    let result = json as! NSDictionary
                    let array = result["Friends List"] as! [Dictionary<String, Any>]
                    for dict in array {
                        //print("dict ---> \(dict)")
                        let teamName = dict["username"] as! String
                        
                        let teamId = dict["userId"] as! Int
                        
                        self.friendData.append((teamId, teamName))
                        
                    }
                    
                    DispatchQueue.main.async(execute: {
                        self.friendListTableView.reloadData()
                    })
                }
            case .failure(let error):
                print(error)
                if let httpResponse = response.response {
                    if httpResponse.statusCode == 404 {
                        self.notifyFailure(info: "Currently no friends!")
                    } else if httpResponse.statusCode == 400 {
                        self.notifyFailure(info: "You don't have friends now!")
                    } else {
                        self.notifyFailure(info: "Cannot connect to server!")
                    }
                } else {
                    self.notifyFailure(info: "Cannot connect to server!")
                }
                
            }
        }
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
                    print("Name = \(String(describing: item.name))")
                    print("Phone = \(String(describing: item.phoneNumber))")
                    
                    self.matchingItems.append(item as MKMapItem)
                    print("Matching items = \(self.matchingItems.count)")
                    
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = item.placemark.coordinate
                    annotation.title = item.name
                    self.mapView.addAnnotation(annotation)
                    
                    //zoom in here
                    self.mapView.showAnnotations(self.mapView.annotations, animated: true)
                }
            }
        })
    }
    
    
    @IBAction func addNewActivity(_ sender: Any) {
        self.createActivityButton.isEnabled = false
        
        let ud = UserDefaults.standard
        let userId = ud.integer(forKey: "currentUserId")
        
        let parameters: Parameters = [
            "aName": activityName,
            "aInfo": infoField.text!,
            "location": acitivtyLocationField.text!,
            "aTime": dateString,
            "sportsType": sportType,
            "maxPeople": maximumAttendanceField.text!,
            "teamId": teamId,
            "friendList": friendsInvitedIds
        ]
        print("param ---> \(parameters)")
        Alamofire.request("http://@ec2-52-7-74-13.compute-1.amazonaws.com/activity/add/allInfo/\(userId)", method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseString { response in
            switch response.result {
            case .success:
                print("Response String: \(response.result.value!)")
                if response.result.value! == "success" {
                    self.performSegue(withIdentifier: "addActivitySuccess", sender: self)
                } else {
                    self.notifyFailure(info: "Failed to add activity!")
                }
                self.createActivityButton.isEnabled = true
            case .failure(let error):
                print(error)
                self.notifyFailure(info: "Cannot connect to server!")
                self.createActivityButton.isEnabled = true
            }
        }
    }
    
    
    @IBAction func cancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
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
        friendNameLabel.text = friendData[indexPath.row].1
        
        cell.accessoryType = cell.isSelected ? .checkmark : .none
        cell.selectionStyle = .none // to prevent cells from being "highlighted"
        
        return cell
        
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        let friend = friendData[indexPath.row]
        friendsInvitedIds.append(friend.0)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let friend = friendData[indexPath.row]
        friendsInvitedIds.remove(at: friendsInvitedIds.index(of: friend.0)!)
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        if textField == acitivtyLocationField {
            mapView.removeAnnotations(mapView.annotations)
            self.performSearch()
        }
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
