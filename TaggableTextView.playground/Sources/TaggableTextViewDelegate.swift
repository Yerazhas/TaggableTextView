import Foundation

protocol TaggableTextViewDelegate: class {
    func didBeginMentioning()
    func didEndMentioning(withText text: String)
    func didTapMention(withText text: String)
}
