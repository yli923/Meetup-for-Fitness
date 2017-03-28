//
//  AddActivityViewController.swift
//  MeetupForFitness
//
//  Created by Mengyang Shi on 3/27/17.
//  Copyright © 2017 TFBOYZ. All rights reserved.
//

import UIKit

class AddActivityViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    @IBOutlet weak var activityNameField: UITextField!
    @IBOutlet weak var personalOrTeamSegmentControl: UISegmentedControl!
    @IBOutlet weak var teamSelections: UIPickerView!
    @IBOutlet weak var sportSelections: UIPickerView!
    @IBOutlet weak var timeSelection: UIDatePicker!
    
    var teamId = -1
    
    
    
    let teamPickerData = ["team1","team2","team3"]
    let sportPickerData = ["badminton","basketball","soccer","table tennis"]
    
    var selectedTeam = String()
    var selectedSport = String()
    var dateString = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        timeSelection.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        
        teamSelections.isHidden = true
        
        teamSelections.delegate = self
        teamSelections.dataSource = self
        sportSelections.delegate = self
        sportSelections.dataSource = self
        
        activityNameField.delegate = self
        
        selectedTeam = teamPickerData[0]
        selectedSport = sportPickerData[0]
        // Do any additional setup after loading the view.
    }

    func dateChanged(_ sender: UIDatePicker) {
        dateString = sender.date.toString(format: "EEE, dd LLL yyyy HH:mm:ss z")
    }
    
    @IBAction func changeAcitivityType(_ sender: Any) {
        switch personalOrTeamSegmentControl.selectedSegmentIndex
        {
        case 0:
            teamSelections.isHidden = true
            teamId = -1
        case 1:
            teamSelections.isHidden = false
            
        default:
            break
        }
    }
    
    // MARK: - pickerview delegate
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        var count:Int?
        if pickerView == teamSelections {
            count = teamPickerData.count
        } else if pickerView == sportSelections {
            count = sportPickerData.count
        }
        return count!
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        var title:String?
        if pickerView == teamSelections {
            title = teamPickerData[row]
        } else if pickerView == sportSelections {
            title = sportPickerData[row]
        }
        return title!
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == teamSelections {
            selectedTeam = teamPickerData[row]
        } else if pickerView == sportSelections {
            selectedSport = sportPickerData[row]
        }
    }
    
    @IBAction func nextStep(_ sender: Any) {
        self.performSegue(withIdentifier: "addNextNew", sender: self)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true;
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addNextNew" {
            let destination = segue.destination as!AddActivitySecondViewController
            destination.teamId = teamId
            destination.teamName = selectedTeam
            destination.sportType = selectedSport
            destination.dateString = dateString
            destination.activityName = activityNameField.text!
        }
    }
    

}

extension Date {
    func toString(format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}
