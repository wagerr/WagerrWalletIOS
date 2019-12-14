//
//  EventsPickerView.swift
//  breadwallet
//
//  Created by MIP on 08/12/2019.
//  Copyright © 2019 Wagerr Ltd. All rights reserved.
//

import Foundation
import UIKit
 
extension UITextField {
    func loadDropdownData(data: [ (Int,String) ], didChangePicker: @escaping ( Int ) -> Void) {
        self.inputView = EventPickerView(pickerData: data, dropdownField: self, didChangePicker: didChangePicker)
    }
    func getSelectedIndex() -> Int  {
        let evPicker : EventPickerView? = self.inputView as? EventPickerView
        return evPicker?.selectedIndex ?? -1
    }
}

class EventPickerView : UIPickerView, UIPickerViewDataSource, UIPickerViewDelegate {

    var pickerData : [ (Int,String) ]!
    var pickerTextField : UITextField!
    var selectedIndex : Int
    
    let didChangePicker: ( Int ) -> Void
 
    init(pickerData: [ (Int, String) ], dropdownField: UITextField, didChangePicker: @escaping ( Int ) -> Void ) {
        self.pickerData = pickerData
        self.pickerTextField = dropdownField
        self.selectedIndex = 0
        self.didChangePicker = didChangePicker
        super.init(frame: CGRect.zero)

        self.backgroundColor = .whiteBackground
        self.autoresizingMask = .flexibleWidth
        self.contentMode = .center
        self.frame = CGRect.init(x: 0.0, y: UIScreen.main.bounds.size.height - 300, width: UIScreen.main.bounds.size.width, height: 300)
        self.delegate = self
        self.dataSource = self
 
        DispatchQueue.main.async {
            if pickerData.count > 0 {
                self.pickerTextField.text = self.pickerData[0].1
                self.selectedIndex = self.pickerData[0].0
                self.pickerTextField.isEnabled = true
            } else {
                self.pickerTextField.text = nil
                self.pickerTextField.isEnabled = false
            }
        }
        createToolbar()
    }
 
    func createToolbar()
    {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.closePickerView))
        toolbar.setItems([doneButton], animated: false)
        toolbar.isUserInteractionEnabled = true
        pickerTextField.inputAccessoryView = toolbar
    }
    
    @objc func closePickerView()
    {
        self.endEditing(true)
        pickerTextField.resignFirstResponder()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
 
 
    // This function sets the text of the picker view to the content of the "data" array
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row].1
    }
 
    // When user selects an option, this function will set the text of the text field to reflect
    // the selected option.
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickerTextField.text = pickerData[row].1
        selectedIndex = pickerData[row].0
        didChangePicker( selectedIndex )
        self.endEditing(true)
    }

    // Sets number of columns in picker view
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
     return 1
    }
 
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
     return pickerData.count
    }
    
}
