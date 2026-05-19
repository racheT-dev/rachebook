import Foundation

// MARK: - Note Model (Class for NSCoding compatibility)
class Note: NSObject, Codable, NSCoding {
    @objc dynamic var id: UUID
    @objc dynamic var title: String
    @objc dynamic var text: String
    @objc dynamic var tags: [String]
    @objc dynamic var createdAt: Date
    @objc dynamic var updatedAt: Date
    
    init(title: String = "", text: String = "", tags: [String] = []) {
        self.id = UUID()
        self.title = title
        self.text = text
        self.tags = tags
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    init(id: UUID, title: String, text: String, tags: [String], createdAt: Date, updatedAt: Date) {
        self.id = id
        self.title = title
        self.text = text
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - NSCoding
    private enum Keys {
        static let id = "id"
        static let title = "title"
        static let text = "text"
        static let tags = "tags"
        static let createdAt = "createdAt"
        static let updatedAt = "updatedAt"
    }
    
    required convenience init?(coder: NSCoder) {
        guard let id = coder.decodeObject(forKey: Keys.id) as? UUID,
            let title = coder.decodeObject(forKey: Keys.title) as? String,
            let text = coder.decodeObject(forKey: Keys.text) as? String,
            let tags = coder.decodeObject(forKey: Keys.tags) as? [String],
            let createdAt = coder.decodeObject(forKey: Keys.createdAt) as? Date,
            let updatedAt = coder.decodeObject(forKey: Keys.updatedAt) as? Date
            else {
                print("❌ Ошибка декодирования заметки")
                return nil
        }
        
         print("✅ Декодировал заметку с ID: \(id)")
        
        self.init(
            id: id,
            title: title,
            text: text,
            tags: tags,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    func encode(with coder: NSCoder) {
        print("💾 Кодирую заметку с ID: \(id)")
        coder.encode(id, forKey: Keys.id)
        coder.encode(title, forKey: Keys.title)
        coder.encode(text, forKey: Keys.text)
        coder.encode(tags, forKey: Keys.tags)
        coder.encode(createdAt, forKey: Keys.createdAt)
        coder.encode(updatedAt, forKey: Keys.updatedAt)
    }
    
    func update(text newText: String, title newTitle: String, tags newTags: [String]) {
        self.text = newText
        self.title = newTitle
        self.tags = newTags
        self.updatedAt = Date()
    }
}
