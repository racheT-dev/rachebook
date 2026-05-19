import Foundation

class NoteStore {
    static let shared = NoteStore()
    
    private var notes: [Note] = []
    private let fileName = "notes.archive"
    
    private init() {
        loadNotes()
    }
    
    private var filePath: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent(fileName)
    }
    
    // MARK: - Public Methods
    func getNoteIndex(by id: UUID) -> Int? {
        return notes.firstIndex { $0.id == id }
    }
    
    func update(noteWithId id: UUID, with updatedNote: Note) {
        print("=== ОБНОВЛЕНИЕ ЗАМЕТКИ ===")
        print("Ищем ID: \(id)")
        print("Все ID в хранилище: \(notes.map { $0.id })")
        print("Обновляемая заметка ID: \(updatedNote.id)")
        
        if let index = notes.firstIndex(where: { $0.id == id }) {
            print("Нашел на позиции: \(index)")
            print("Старая: \(notes[index].title)")
            print("Новая: \(updatedNote.title)")
            
            notes[index] = updatedNote
            saveNotes()
            print("✅ Обновлено успешно")
        } else {
            print("❌ Заметка с ID \(id) не найдена!")
            print("Вместо этого добавляем новую заметку...")
            notes.append(updatedNote)
            saveNotes()
        }
        print("=== КОНЕЦ ОБНОВЛЕНИЯ ===")
        
    }
    
    func allNotes() -> [Note] {
        return notes
    }
    
    func add(_ note: Note) {
        // Проверяем нет ли уже заметки с таким ID
        if !notes.contains(where: { $0.id == note.id }) {
            notes.append(note)
            saveNotes()
            print("✅ Добавлена новая заметка с ID: \(note.id)")
        } else {
            print("⚠️ Заметка с ID \(note.id) уже существует, не добавляем дубликат")
        }
    }
    
    func delete(noteWithId id: UUID) {
        if let index = notes.firstIndex(where: { $0.id == id }) {
            notes.remove(at: index)
            saveNotes()
        }
    }
    
    // MARK: - Private Methods
    
    private func saveNotes() {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: notes as NSArray, requiringSecureCoding: false)
            try data.write(to: filePath)
        } catch {
            print("Ошибка сохранения заметок: \(error)")
        }
    }
    
    private func loadNotes() {
        guard FileManager.default.fileExists(atPath: filePath.path),
            let data = try? Data(contentsOf: filePath) else {
                self.notes = []
                print("📭 Файл не найден, создаем пустой список")
                return
        }
        
        do {
            let loadedNotes = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [Note]
            
            // УДАЛЯЕМ ДУБЛИКАТЫ по ID
            var uniqueNotes: [Note] = []
            var seenIDs: Set<UUID> = []
            
            if let loadedNotes = loadedNotes {
                for note in loadedNotes {
                    if !seenIDs.contains(note.id) {
                        seenIDs.insert(note.id)
                        uniqueNotes.append(note)
                    } else {
                        print("⚠️ Найден дубликат заметки с ID: \(note.id), пропускаем")
                    }
                }
            }
            
            self.notes = uniqueNotes
            print("✅ Загружено \(self.notes.count) уникальных заметок")
            
        } catch {
            print("❌ Ошибка загрузки заметок: \(error)")
            self.notes = []
        }
    }
}
