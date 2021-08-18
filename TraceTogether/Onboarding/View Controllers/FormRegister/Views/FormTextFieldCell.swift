//
//  FormTextFieldCell.swift
//  OpenTraceTogether

import UIKit

class FormTextFieldCell: UITableViewCell, UITextFieldDelegate {

    enum ServerErrorType {
        case dontAllow
        case lineOnly
        case allow
    }

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var iconView: UIImageView!
    @IBOutlet var textField: UITextField!
    @IBOutlet var arrowView: UIView!
    @IBOutlet var errorLabel: UILabel!
    @IBOutlet var findButton: UIButton!
    @IBOutlet var borderView: UIView!
    @IBOutlet var borderHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var formAccessoryView: UIView!

    var error: String? { didSet { reloadView() }}
    var serverError: String? { didSet { reloadView() }}
    var serverErrorType: ServerErrorType = .dontAllow
    var valueChanged: (() -> Void)?
    var onFind: (() -> Void)? { didSet { findButton.isHidden = onFind == nil }}
    var maxLength = 200
    var listPicker: ListPickerDataSource?

    //Make set text centralized to make sure all value is uppercased
    func setTextFieldText(_ text: String?) {
        textField.text = text?.uppercased()
    }

    func setAsDatePicker() {
        let datePicker = UIDatePicker()
        datePicker.calendar = Calendar.appCalendar
        datePicker.datePickerMode = .date
        datePicker.locale = .init(identifier: "en_SG")
        datePicker.minimumDate = Date(timeIntervalSince1970: TimeInterval(-2208988800))
        datePicker.maximumDate = Date()
        datePicker.date = Date(timeIntervalSince1970: TimeInterval(946684800))
        datePicker.addTarget(self, action: #selector(datePickerValueChange(_:)), for: .valueChanged)
        if #available(iOS 13.4, *) { datePicker.preferredDatePickerStyle = .wheels }
        setInputView(datePicker)
    }

    func setAsListPicker(_ listPicker: ListPickerDataSource) {
        let pickerView = UIPickerView()
        pickerView.dataSource = self
        pickerView.delegate = self
        self.listPicker = listPicker
        setInputView(pickerView)
    }

    func setInputView(_ inputView: UIView) {
        textField.inputView = inputView
        textField.tintColor = .clear
        textField.clearButtonMode = .never
        arrowView.isHidden = false
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        textField.inputAccessoryView = formAccessoryView
        findButton.isHidden = true
        arrowView.isHidden = true
        errorLabel.isHidden = true
        reloadView()
    }

    func getDisplayError() -> String? {
        if (error != nil) {
            return error
        } else if (serverError != nil) {
            if (serverErrorType == .dontAllow) {
                return nil
            } else if (serverErrorType == .lineOnly) {
                return ""
            }
        }
        return serverError
    }

    func reloadView() {
        let editing = textField.isEditing
        let error = getDisplayError()
        iconView.image = iconView.image?.withRenderingMode(.alwaysTemplate)
        iconView.tintColor = UIColor(hexString: editing ? "#FF6666" : "#828282")
        titleLabel.textColor = UIColor(hexString: editing ? "#4F4F4F" : "#828282")
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: editing ? .bold : .regular)
        borderView.backgroundColor = UIColor(hexString: editing ? "#4F4F4F" : error == nil ? "#DADCE0" : "#FF6565")
        borderHeightConstraint.constant = editing || error != nil ? 2 : 1
        errorLabel.text = error

        let errorHidden = editing ? true : error == nil || error!.isEmpty
        if (errorHidden != errorLabel.isHidden) {
            errorLabel.isHidden = errorHidden
            errorLabel.superview?.updateConstraintsIfNeeded()
            reloadHeight()
        }
    }

    // Toggling error label require tableview to recalculate the height
    // Simply tell tableview to reload empty row and it will do the job
    // Put this as an extension if more cell require this logic
    func reloadHeight() {
        var sv = superview
        while (sv != nil && !(sv is UITableView)) {
            sv = sv?.superview
        }
        (sv as? UITableView)?.reloadRows(at: [], with: .none)
    }

    @IBAction func findButtonPressed() {
        onFind?()
    }

    @objc func datePickerValueChange(_ datePicker: UIDatePicker) {
        setTextFieldText(DateFormatter.appDateFormatter(format: "dd-MMM-yyyy").string(from: datePicker.date))
    }

    @IBAction func textFieldDidChangeText(_ textField: UITextField) {
        setTextFieldText(textField.text)
        valueChanged?()
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return textField.inputView == nil ? textField.text!.count - range.length + string.count <= maxLength : false
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        reloadView()

        /// Setup the `inputView` initial value
        if let datePicker = textField.inputView as? UIDatePicker {
            if textField.text!.count > 0, let date = DateFormatter.appDateFormatter(format: "dd-MMM-yyyy").date(from: textField.text!) {
                datePicker.date = date
            }
            datePickerValueChange(datePicker)
        } else if let pickerView = textField.inputView as? UIPickerView {
            let data = textField.text!.isEmpty ? listPicker!.initialData : listPicker!.data(from: textField.text!)
            data.enumerated().forEach { d in
                let row = listPicker!.allData[d.offset].firstIndex { $0.uppercased() == d.element.uppercased() }
                pickerView.selectRow(row ?? 0, inComponent: d.offset, animated: false)
            }
            setTextFieldText(listPicker!.value(from: data))
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        reloadView()
        valueChanged?()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }
}

extension FormTextFieldCell: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return listPicker!.allData.count
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return listPicker!.allData[component].count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return listPicker!.allData[component][row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let data = listPicker!.allData.enumerated().map { $0.element[pickerView.selectedRow(inComponent: $0.offset)] }
        setTextFieldText(listPicker!.value(from: data))
    }
}

protocol ListPickerDataSource {
    /// All available options
    var allData: [[String]] { get }
    /// Initial selected options when textField value empty
    var initialData: [String] { get }
    /// Convert the selected options to displayed string
    func value(from data: [String]) -> String
    /// Convert displayed string to inputView selected options
    func data(from value: String) -> [String]
}
