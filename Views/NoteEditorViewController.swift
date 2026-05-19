import UIKit

class NoteEditorViewController: UIViewController {
    
    // UI элементы
    let titleTextField = UITextField()
    let textView = UITextView()
    let tagsTextField = UITextField()
    
    weak var delegate: NoteEditorDelegate?
    var note: Note?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        populateFieldsIfNeeded()
        
        // Автофокус при создании новой заметки
        if note == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.titleTextField.becomeFirstResponder()
            }
        }
        
        // ДЕБАГ - проверим layout
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.debugLayout()
        }
    }
    
    private func debugLayout() {
        print("=== ДЕБАГ LAYOUT ===")
        print("View bounds: \(view.bounds)")
        print("Safe area frame: \(view.safeAreaLayoutGuide.layoutFrame)")
        print("TitleTextField frame: \(titleTextField.frame)")
        print("TagsTextField frame: \(tagsTextField.frame)")
        print("TextView frame: \(textView.frame)")
        print("TextView superview: \(textView.superview?.description ?? "nil")")
        print("Subview count: \(view.subviews.count)")
        
        
        // Проверим констрейнты
        print("\nКонстрейнты textView:")
        for constraint in textView.constraints {
            print("- \(constraint)")
        }
        print("\nКонстрейнты view:")
        for constraint in view.constraints {
            if constraint.firstItem as? UIView == textView || constraint.secondItem as? UIView == textView {
                print("- \(constraint)")
            }
        }
        print("=== КОНЕЦ ДЕБАГ ===")
    }
    
    private func setupNavigationBar() {
        // Заголовок
        title = note != nil ? "Редактировать" : "Новая заметка"
        
        // Кнопка Отмена слева
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Отмена",
            style: .plain,
            target: self,
            action: #selector(cancel)
        )
        
        // Кнопка Сохранить справа
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Сохранить",
            style: .done,
            target: self,
            action: #selector(save)
        )
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // Настройка полей ввода
        titleTextField.placeholder = "Заголовок"
        titleTextField.borderStyle = .roundedRect
        
        tagsTextField.placeholder = "Теги (через запятую)"
        tagsTextField.borderStyle = .roundedRect
        
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.borderWidth = 0.45
        textView.layer.cornerRadius = 5
        textView.delegate = self
        
        // Добавляем на view
        view.addSubview(titleTextField)
        view.addSubview(tagsTextField)
        view.addSubview(textView)
        
        // Отключаем авто-констрейнты
        titleTextField.translatesAutoresizingMaskIntoConstraints = false
        tagsTextField.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        let safeArea = view.safeAreaLayoutGuide
        
        // Констрейнты
        NSLayoutConstraint.activate([
            // Заголовок
            titleTextField.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 20),
            titleTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            titleTextField.heightAnchor.constraint(equalToConstant: 40),
            
            // Теги
            tagsTextField.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 20),
            tagsTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tagsTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            tagsTextField.heightAnchor.constraint(equalToConstant: 40),
            
            // Текст заметки
            textView.topAnchor.constraint(equalTo: tagsTextField.bottomAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -20)
            ])
    }
    
    private func populateFieldsIfNeeded() {
        if let note = note {
            titleTextField.text = note.title
            textView.text = note.text
            textView.textColor = .black
            tagsTextField.text = note.tags.joined(separator: ", ")
        } else {
            // Подсказка для новой заметки
            textView.text = "Введите текст заметки..."
            textView.textColor = .lightGray
        }
    }
    
    @objc private func cancel() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func save() {
        let title = titleTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let text = textView.text == "Введите текст заметки..." ? "" : textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let tagString = tagsTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let tags = tagString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        
        if title.isEmpty && text.isEmpty {
            let alert = UIAlertController(title: "Ошибка", message: "Заметка пуста.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        if let existingNote = note {
            // Обновляем существующую заметку
            let updatedNote = Note(
                id: existingNote.id,
                title: title.isEmpty ? "Без заголовка" : title,
                text: text,
                tags: tags,
                createdAt: existingNote.createdAt,
                updatedAt: Date()
            )
            NoteStore.shared.update(noteWithId: existingNote.id, with: updatedNote)
        } else {
            // Создаем новую заметку
            let newNote = Note(
                title: title.isEmpty ? "Без заголовка" : title,
                text: text,
                tags: tags
            )
            NoteStore.shared.add(newNote)
        }
        
        delegate?.didSaveNote()
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UITextViewDelegate
extension NoteEditorViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .lightGray && textView.text == "Введите текст заметки..." {
            textView.text = ""
            textView.textColor = .black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Введите текст заметки..."
            textView.textColor = .lightGray
        }
    }
}
