import Testing
@testable import NotesModule

@Suite("NotesBridge Tests")
struct NotesBridgeTests {
    @Test("初始化成功")
    func initialization() {
        let bridge = NotesBridge()
        _ = bridge // 确认可以创建实例
    }
}
