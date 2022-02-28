//
//  WriteDiaryViewController.swift
//  Diary
//
//  Created by 정선아 on 2022/02/20.
//

import UIKit

//일기 수정
enum DiaryEditorMode {
case new
    case edit(IndexPath, Diary)
}

//일기가 작성된 다이어리 객체 전달
protocol WriteDiaryViewDelegate: AnyObject {
    func didSelectRegister(diary: Diary)
}

class WriteDiaryViewController: UIViewController {

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var contentsTextView: UITextView!
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var confirmButton: UIBarButtonItem!
    
    private let datePicker = UIDatePicker()
    private var diaryDate: Date?
    weak var delegate: WriteDiaryViewDelegate?
    var diaryEditorMode: DiaryEditorMode = .new
   
    //화면에 호출하기
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureContentsTextView()
        self.configureDatePicker()
        self.confirmButton.isEnabled = false
        self.configureEditorMode()
        self.configureInputField()
    }
    
    //일기 수정 화면 구성하기
    private func configureEditorMode() {
        switch self.diaryEditorMode {
          case let .edit(_, diary):
            self.titleTextField.text = diary.title
            self.contentsTextView.text = diary.contents
            self.dateTextField.text = self.dateToString(date: diary.date)
            self.diaryDate = diary.date
            self.confirmButton.title = "수정"
            
        default:
            break
        }
    }
    
    //Date 타입의 데이터를 문자열로 변환
    private func dateToString(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy년 MM월 dd일(EEEEE)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
    
    //내용 텍스트필드의 테두리 잡아주기
    private func configureContentsTextView() {
        let borderColor = UIColor(red: 220/225, green: 220/225, blue: 220/225, alpha: 1.0)
        self.contentsTextView.layer.borderColor = borderColor.cgColor
        self.contentsTextView.layer.borderWidth = 0.5
        self.contentsTextView.layer.cornerRadius = 5.0
    }
    
    //날짜 설정 자판에서 날짜피커로 변경하기
    private func configureDatePicker() {
        self.datePicker.datePickerMode = .date
        self.datePicker.preferredDatePickerStyle = .wheels
        self.datePicker.addTarget(self, action: #selector(datePickerValueDidChange), for: .valueChanged)
        self.datePicker.locale = Locale(identifier: "ko_KR")
        self.dateTextField.inputView = self.datePicker
    }
    
    //등록 버튼 활성화하기
    private func configureInputField() {
        self.contentsTextView.delegate = self
        self.titleTextField.addTarget(self, action: #selector(titleTextFieldDidChange(_:)), for: .editingChanged)
        self.dateTextField.addTarget(self, action: #selector(dateTextFieldDidChange(_:)), for: .editingChanged)
    }
    
    //일기를 다 작성했을 때 다이어리 객체 생성
    //delegate 메서드에 정의한 didSelectRegister를 호출하여 메서드 파라미터에 생성된 다이어리 객체를 전달
    @IBAction func tapConfirmButton(_ sender: UIBarButtonItem) {
        guard let title = self.titleTextField.text else { return }
        guard let contents = self.contentsTextView.text else { return }
        guard let date = self.diaryDate else { return }
        
        
        //수정된 다이어리 객체
        switch self.diaryEditorMode {
        case .new:
            let diary = Diary(
                uuidString: UUID().uuidString,
                title: title,
                contents: contents,
                date: date,
                isStar: false
            )
            self.delegate?.didSelectRegister(diary: diary)
            
        case let .edit(indexPath, diary):
            let diary = Diary(
                uuidString: diary.uuidString,
                title: title,
                contents: contents,
                date: date,
                isStar: diary.isStar
            )
            NotificationCenter.default.post(
                name: NSNotification.Name("editDiary"),
                object: diary,
                userInfo: nil
            )
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    //날짜 피커에서 해당 날짜 설정 후 텍스트 필드에 표시
    @objc private func datePickerValueDidChange(_ datePicker: UIDatePicker) {
        let formmater = DateFormatter()
        formmater.dateFormat = "yyyy년 MM월 dd일(EEEE)"
        formmater.locale = Locale(identifier: "ko_KR")
        self.diaryDate = datePicker.date
        self.dateTextField.text = formmater.string(from: datePicker.date)
        //키보드로 입력되는 형태가 아니라 에디팅체인지 액션을 발생시켜 dateTextFieldDidChange 메서드 호출
        self.dateTextField.sendActions(for: .editingChanged)
    }
    
    //제목이 변경되었을 때 등록 버튼 활성화 여부 판단
    @objc private func titleTextFieldDidChange(_ textField: UITextField) {
        self.validateInputField()
    }
    
    //날짜가 변경될 때마다 등록 버튼 활성화 여부 판단
    @objc private func dateTextFieldDidChange(_ textField: UITextField) {
        self.validateInputField()
    }
    
    //빈 곳 눌렀을 때 자판과 날짜 피커 사라지게 하기
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    //제목, 내용, 날짜 모두 입력되었을 때 등록되게 조건 걸기
    private func validateInputField() {
        self.confirmButton.isEnabled = !(self.titleTextField.text?.isEmpty ?? true) && !(self.dateTextField.text?.isEmpty ?? true) && !self.contentsTextView.text.isEmpty
    }
}

//등록 버튼 활성화 여부 판단 - 텍스트 뷰에 내용이 입력될 때마다 델리게이트 메소드가 호출
extension WriteDiaryViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView){
        self.validateInputField()
    }
}
