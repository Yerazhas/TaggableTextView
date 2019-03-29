import UIKit

class TaggableTextView: UITextView {
    weak var customDelegate: TaggableTextViewDelegate?
    var mentioningStartAction: (() -> ())?
    private var callBack: ((String, WordType) -> ())?
    private var attrString = NSMutableAttributedString()
    private var textString = NSString()
    
    init() {
        super.init(frame: .zero, textContainer: nil)
        delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setText(text: String, withHashtagColor hashtagColor: UIColor, andMentionColor mentionColor: UIColor, andCallBack callBack: @escaping (String, WordType) -> ()) {
        self.callBack = callBack
        let attrString = NSMutableAttributedString(string: text)
        self.attrString = attrString
        let textString = NSString(string: text)
        self.textString = textString
        
        attrString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 14), range: NSRange(location: 0, length: textString.length))
        
        setAttrWithName("Hashtag", wordPrefix: "#", color: hashtagColor, text: text)
        setAttrWithName("Mention", wordPrefix: "@", color: mentionColor, text: text)
        
        let tapper = UITapGestureRecognizer(target: self, action: #selector(tapRecognized(tapGesture:)))
        addGestureRecognizer(tapper)
    }
    
    func defaultAction() {
        print("default action!!!!!!!")
    }
    
    private func setAttrWithName(_ attrName: String, wordPrefix: String, color: UIColor, text: String) {
        let words = text.components(separatedBy: " ")
        
        for word in words.filter({$0.hasPrefix(wordPrefix)}) {
            if word.first == word.last, word.first! == "@" {
                customDelegate?.didBeginMentioning()
            }
            let range = textString.range(of: word)
            attrString.addAttribute(.foregroundColor, value: color, range: range)
            attrString.addAttribute(NSAttributedString.Key(rawValue: attrName), value: 1, range: range)
            attrString.addAttribute(NSAttributedString.Key(rawValue: "Clickable"), value: 1, range: range)
        }
        self.attributedText = attrString
    }
    
    @objc private func tapRecognized(tapGesture: UITapGestureRecognizer) {
        // Gets the range of word at current position
        let point = tapGesture.location(in: self)
        let position = closestPosition(to: point)
        let range = tokenizer.rangeEnclosingPosition(position!, with: .word, inDirection: UITextDirection(rawValue: 1))
        
        if range != nil {
            let location = offset(from: beginningOfDocument, to: range!.start)
            let length = offset(from: range!.start, to: range!.end)
            let attrRange = NSMakeRange(location, length)
            let word = attributedText.attributedSubstring(from: attrRange)
            
            // Checks the word's attribute, if any
            let isHashtag: AnyObject? = word.attribute(NSAttributedString.Key(rawValue: "Hashtag"), at: 0, longestEffectiveRange: nil, in: NSMakeRange(0, word.length)) as AnyObject
            let isAtMention: AnyObject? = word.attribute(NSAttributedString.Key(rawValue: "Mention"), at: 0, longestEffectiveRange: nil, in: NSMakeRange(0, word.length)) as AnyObject
            
            // Runs callback function if word is a Hashtag or Mention
            if isHashtag != nil && callBack != nil {
                callBack!(word.string, .hashTag)
            } else if isAtMention != nil && callBack != nil {
                callBack!(word.string, .mention)
            }
        }
    }
}

extension TaggableTextView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        guard let textView = textView as? TaggableTextView else { return }
        guard let text = textView.text else { return }
        textView.setText(text: text, withHashtagColor: .red, andMentionColor: .blue) { (string, type) in
            self.customDelegate?.didTapMention(withText: string)
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == nil {
            textView.text = "Оставить комментарии"
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.text = nil
    }
}
