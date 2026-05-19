import UIKit

protocol NoteEditorDelegate: AnyObject {
    func didSaveNote()
}

class NotesListViewController: UIViewController {
    // UI элементы
    var tableView: UITableView!
    var searchBar: UISearchBar!
    var sortSegmentedControl: UISegmentedControl!
    
    private var filteredNotes: [Note] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createUIElements()  // ← СОЗДАЕМ элементы ДО их использования
        setupUI()
        loadNotes()
        
        // Принудительно обновляем таблицу
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.tableView.reloadData()
            
        }
    }
    
    private func createUIElements() {
        // 1. SearchBar
        searchBar = UISearchBar()
        searchBar.placeholder = "Поиск заметок..."
        searchBar.searchBarStyle = .minimal  // убирает фон
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        
        // 2. SegmentedControl
        sortSegmentedControl = UISegmentedControl(items: ["По дате создания", "По дате изменения"])
        sortSegmentedControl.selectedSegmentIndex = 0
        sortSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        // 3. TableView
        tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // 4. Добавляем на экран
        view.addSubview(searchBar)
        view.addSubview(sortSegmentedControl)
        view.addSubview(tableView)
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // Внутри setupUI(), заменим блок navigationItem:
        title = "Блокнот"
        
        // Левая кнопка – сканирование
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .camera,   // можно любой символ
            target: self,
            action: #selector(scanTapped)
        )
        
        // Правая кнопка – добавление
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addNote)
        )
        
        // Настраиваем tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "NoteCell")
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(loadNotes), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        // Настраиваем searchBar
        searchBar.delegate = self
        
        // Настраиваем segmentedControl
        sortSegmentedControl.addTarget(self, action: #selector(sortChanged), for: .valueChanged)
        
        // Констрейнты (расположение элементов)
        NSLayoutConstraint.activate([
            // SearchBar
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchBar.heightAnchor.constraint(equalToConstant: 56),
            
            // SegmentedControl
            sortSegmentedControl.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            sortSegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            sortSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            sortSegmentedControl.heightAnchor.constraint(equalToConstant: 32),
            
            // TableView
            tableView.topAnchor.constraint(equalTo: sortSegmentedControl.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
    }
    
    @objc private func scanTapped() {
        let alert = UIAlertController(title: "Сканировать текст",
                                      message: "Выберите источник",
                                      preferredStyle: .actionSheet)
        
        // Если камера доступна
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Камера", style: .default) { _ in
                self.presentImagePicker(source: .camera)
            })
        }
        
        // Галерея доступна всегда (даже в симуляторе)
        alert.addAction(UIAlertAction(title: "Галерея", style: .default) { _ in
            self.presentImagePicker(source: .photoLibrary)
        })
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        
        // Для iPad action sheet нужен sourceView
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.leftBarButtonItem
        }
        present(alert, animated: true)
    }
    
    private func presentImagePicker(source: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = source
        picker.mediaTypes = ["public.image"] // только фото
        present(picker, animated: true)
    }
    
    @objc private func loadNotes() {
        let allNotes = NoteStore.shared.allNotes()
        filteredNotes = allNotes
        sortNotes()
        tableView.reloadData()
        tableView.refreshControl?.endRefreshing()
        
        updateEmptyState()
    }
    
    @objc private func addNote() {
        let editorVC = NoteEditorViewController()
        editorVC.delegate = self
        let navController = UINavigationController(rootViewController: editorVC)
        present(navController, animated: true)
    }
    
    @objc private func sortChanged() {
     loadNotes()
    }
    
    private func sortNotes() {
        switch sortSegmentedControl.selectedSegmentIndex {
        case 0:
            filteredNotes.sort { $0.createdAt > $1.createdAt }
        case 1:
            filteredNotes.sort { $0.updatedAt > $1.updatedAt }
        default:
            break
        }
    }
    
    private func updateEmptyState() {
        if filteredNotes.isEmpty {
            let emptyLabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 100))
            
            if searchBar.text?.isEmpty ?? true {
                emptyLabel.text = "Нет заметок\nНажми + чтобы создать первую"
            } else {
                emptyLabel.text = "Ничего не найдено"
            }
            
            emptyLabel.textAlignment = .center
            emptyLabel.numberOfLines = 2
            emptyLabel.textColor = .gray
            tableView.backgroundView = emptyLabel
        } else {
            tableView.backgroundView = nil
        }
    }
    
    private func startRecognition(with image: UIImage) {
        // Показываем индикатор загрузки
        let spinner = UIActivityIndicatorView(style: .gray)
        spinner.center = view.center
        spinner.startAnimating()
        view.addSubview(spinner)
        
        let service = YandexVisionService()
        service.recognizeHandwrittenText(from: image) { [weak self] result in
            DispatchQueue.main.async {
                spinner.removeFromSuperview()
                
                switch result {
                case .success(let recognizedText):
                    self?.openEditorWithRecognizedText(recognizedText)
                case .failure(let error):
                    self?.showAlert(title: "Ошибка распознавания",
                                    message: error.localizedDescription)
                }
            }
        }
    }
    
    private func openEditorWithRecognizedText(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(title: "Пустой результат", message: "API не обнаружил текст на изображении")
            return
        }
        
        // Создаём новую заметку с распознанным текстом
        let note = Note(
            title: "Распознано", // или пустую, пусть пользователь сам назовёт
            text: text,
            tags: []
        )
        
        let editorVC = NoteEditorViewController()
        editorVC.note = note
        editorVC.delegate = self
        let navController = UINavigationController(rootViewController: editorVC)
        present(navController, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
}

// MARK: - UITableViewDataSource
extension NotesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredNotes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "NoteCell")
        //tableView.dequeueReusableCell(withIdentifier: "NoteCell", for: indexPath) ??
        
        let note = filteredNotes[indexPath.row]
        
        //заголовок
        cell.textLabel?.text = note.title.isEmpty ? "Без заголовка" : note.title
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        cell.textLabel?.textColor = .black
        cell.textLabel?.numberOfLines = 1

        //
        let preview = String(note.text.prefix(60))
        let dots = note.text.count > 60 ? "..." : ""
        
        
        let tagsString = note.tags.isEmpty ? "" : "[\(note.tags.joined(separator: ", "))] "
        
        let dateString = formatDate(note.updatedAt)
        
        cell.detailTextLabel?.text = "\(preview)\(dots)\n\(tagsString)\(dateString)"
        cell.detailTextLabel?.numberOfLines = 3
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 13)
        cell.detailTextLabel?.textColor = .darkGray
        //cell.frame.size.height = 100
        
        return cell
    }
    
    private func formatDate(_ date:Date) -> String{
        let formatter=DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let alert = UIAlertController(title: "Удалить заметку?", message: nil, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            
            alert.addAction(UIAlertAction(title: "Удалить", style: .destructive) { _ in
                let noteToDelete = self.filteredNotes[indexPath.row]
                NoteStore.shared.delete(noteWithId: noteToDelete.id)
                self.loadNotes()
            })
            
            present(alert, animated: true)
        }
    }
}

// MARK: - UITableViewDelegate
extension NotesListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70 // Или 90, 110
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedNote = filteredNotes[indexPath.row]
        print("=== ОТКРЫВАЕМ РЕДАКТИРОВАНИЕ ===")
        print("Выбрана заметка: \(selectedNote.title)")
        print("ID заметки: \(selectedNote.id)")
        print("Текст: \(selectedNote.text.prefix(20))...")
        print("Теги: \(selectedNote.tags)")
        
        let editorVC = NoteEditorViewController()
        editorVC.note = filteredNotes[indexPath.row]
        editorVC.delegate = self
    
        let editorWithNav = UINavigationController(rootViewController: editorVC)
        present(editorWithNav, animated: true)
        //navigationController?.pushViewController(editorVC, animated: true)
    }
}

// MARK: - UISearchBarDelegate
extension NotesListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            loadNotes()
        } else {
            filteredNotes = NoteStore.shared.allNotes().filter { note in
                note.title.localizedCaseInsensitiveContains(searchText) ||
                    note.text.localizedCaseInsensitiveContains(searchText) ||
                    note.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
            tableView.reloadData()
            updateEmptyState()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - UIImagePickerControllerDelegate
extension NotesListViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true) {
            guard let image = info[.originalImage] as? UIImage else {
                self.showAlert(title: "Ошибка", message: "Не удалось получить изображение")
                return
            }
            self.startRecognition(with: image)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - NoteEditorDelegate
extension NotesListViewController: NoteEditorDelegate {
    func didSaveNote() {
        loadNotes()
    }
}
