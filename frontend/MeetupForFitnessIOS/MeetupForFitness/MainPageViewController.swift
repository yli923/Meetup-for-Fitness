//
//  MainPageViewController.swift
//  MeetupForFitness
//
//  Created by Mengyang Shi on 3/27/17.
//  Copyright © 2017 TFBOYZ. All rights reserved.
//

import UIKit
import Alamofire

class MainPageViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var allActivities = [Activity]()
    var shownActivities = [Activity]()
    var userId:Int!
    
    @IBOutlet weak var popularOrNearbySegmentControl: UISegmentedControl!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        // Do any additional setup after loading the view.
        userId = UserDefaults.standard.integer(forKey: "currentUserId")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.downloadActivities()
    }
    
    
    @IBAction func switchToPopularOrNearby(_ sender: Any) {
        switch popularOrNearbySegmentControl.selectedSegmentIndex {
        case 0:
            self.shownActivities = self.allActivities
            self.tableView.reloadData()
        case 1:
            presentPopularActivities()
        default:
            break
        }
    }
    
    func presentPopularActivities() {
        self.shownActivities.removeAll()
        for activity in allActivities {
            if activity.getAttendedAmount() >= activity.maxAttendance / 2 {
                self.shownActivities.append(activity)
            }
        }
        self.tableView.reloadData()
    }

    func downloadActivities() {
        Alamofire.request("http://@ec2-52-7-74-13.compute-1.amazonaws.com/activity", method: .get, encoding: JSONEncoding.default).validate().responseJSON { response in
            switch response.result {
            case .success:
                print("Validation Successful")
                if let json = response.result.value {
                    self.allActivities.removeAll()
                    self.shownActivities.removeAll()
                    
                    print("JSON: \(json)")
                    let result = json as! NSDictionary
                    let array = result["activities"] as! [Dictionary<String, Any>]
                    for dict in array {
                        //print("dict ---> \(dict)")
                        let activityName = dict["aName"] as! String
                        let sportsType = (dict["sportsType"] as! [String]).first
                        let teamNameArr = dict["teamName"] as? [String]
                        let info = dict["aInfo"] as! String
                        let aid = dict["aid"] as! Int
                        let postTime = dict["postTime"] as! String
                        let activityTime = dict["aTime"] as! String
                        let userId = dict["userId"] as! Int
                        var teamId = dict["teamId"] as? Int
                        let maxAttendance = dict["maxPeople"] as! Int
                        let attendedIds = dict["attended"] as! [Int]
                        let location = dict["location"] as! String
                        let username = (dict["username"] as! [String]).first
                        var teamName:String!
                        if teamId == nil {
                            teamId = -1
                            teamName = ""
                        } else {
                            if teamNameArr != nil && (teamNameArr?.count)! > 0 {
                                teamName = teamNameArr!.first
                            } else {
                                teamName = "Unknown"
                            }
                        }
                        let newActivity = Activity(name: activityName, sportsType: sportsType!, teamName: teamName!, username: username!, info: info, aid: aid, postTime: postTime, activityTime: activityTime, userId: userId, teamId: teamId!, maxAttendance: maxAttendance, attendedIds: attendedIds, location: location)
                        self.allActivities.append(newActivity)
                        
                    }
                    
                    DispatchQueue.main.async(execute: {
                        self.sortByDate()
                        self.storeActivitiesToLocal()
                        self.shownActivities = self.allActivities
                        self.tableView.reloadData()
                    })
                 }
            case .failure(let error):
                print(error)
                if let httpResponse = response.response {
                    if httpResponse.statusCode == 404 {
                        self.notifyFailure(info: "Currently no activities!")
                    } else {
                        self.notifyFailure(info: "Cannot connect to server!")
                    }
                } else {
                    self.notifyFailure(info: "Cannot connect to server!")
                }
                
            }
        }
    }
    
    func sortByDate() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd LLL yyyy HH:mm:ss z"
        self.allActivities.sort(by: {dateFormatter.date(from: $0.postTime)! > dateFormatter.date(from: $1.postTime)!})
    }
    
    func storeActivitiesToLocal() {
        let activitiesToSave = allActivities.sorted(by: {$0.aid! < $1.aid!})
        let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: activitiesToSave)
        UserDefaults.standard.set(encodedData, forKey: "activities")
        UserDefaults.standard.synchronize()
    }
    
    func attendActivity(_ sender : AttendButton) {
        if sender.aid == nil {
            print("some errors here")
            return
        }
        
        sender.isEnabled = false
        
        let parameters: Parameters = [
            "userId": userId,
            "aid": sender.aid!
        ]
        print("param ---> \(parameters)")
        Alamofire.request("http://@ec2-52-7-74-13.compute-1.amazonaws.com/activity/attend", method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseString { response in
            switch response.result {
            case .success:
                print("Response String: \(response.result.value!)")
                if response.result.value! == "success" {
                    DispatchQueue.main.async(execute: {
                        self.allActivities[sender.indexPath!].newUserAttended(uid: self.userId)
                        self.storeActivitiesToLocal()
                        self.shownActivities = self.allActivities
                        self.tableView.reloadData()
                    })
                } else {
                    self.notifyFailure(info: "The activity is already full! Reload this  page to update!")
                    sender.isEnabled = true
                }
            case .failure(let error):
                print(error)
                self.notifyFailure(info: "Cannot connect to server!")
                sender.isEnabled = true
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
        return shownActivities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "mainActivityCell"
        let cell: UITableViewCell = self.tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        
        let currentActivity = self.shownActivities[indexPath.row]
        
        let activityNameLabel = cell.contentView.viewWithTag(1) as! UILabel
        let sportTypeLabel = cell.contentView.viewWithTag(2) as! UILabel
        let ownerLabel = cell.contentView.viewWithTag(3) as! UILabel
        let activityTimeLabel = cell.contentView.viewWithTag(4) as! UILabel
        let locationLabel = cell.contentView.viewWithTag(5) as! UILabel
        let attendanceLabel = cell.contentView.viewWithTag(6) as! UILabel
        let attendButton = cell.contentView.viewWithTag(7) as! AttendButton
        let postTimeLabel = cell.contentView.viewWithTag(8) as! UILabel
        
        activityNameLabel.text = currentActivity.name
        sportTypeLabel.text = currentActivity.sportsType
        ownerLabel.text = "By: \(currentActivity.getOwnerName())"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd LLL yyyy HH:mm:ss z"
        
        let activityTime = dateFormatter.date(from: currentActivity.activityTime)
        let postTime = dateFormatter.date(from: currentActivity.postTime)
        
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        activityTimeLabel.text = dateFormatter.string(from: activityTime!)
        postTimeLabel.text = "Post at: \(dateFormatter.string(from: postTime!))"
        
        locationLabel.text = currentActivity.location
        attendanceLabel.text = "\(currentActivity.getAttendedAmount())/\(currentActivity.maxAttendance!)"
        
        if currentActivity.hasAttended(uid: self.userId) {
            attendButton.setTitle("Attended", for: .normal)
            attendButton.backgroundColor = .green
            attendButton.isEnabled = false
        } else {
            if currentActivity.isFull() {
                attendButton.setTitle("Full", for: .normal)
                attendButton.backgroundColor = .red
                attendButton.isEnabled = false
            } else {
                attendButton.setTitle("Attend", for: .normal)
                attendButton.backgroundColor = .blue
                attendButton.isEnabled = true
                attendButton.addTarget(self, action: #selector(self.attendActivity(_:)), for: .touchUpInside)
                attendButton.aid = currentActivity.aid!
                attendButton.indexPath = indexPath.row
            }
        }
        
        cell.selectionStyle = .none // to prevent cells from being "highlighted"
        
        return cell
        
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
