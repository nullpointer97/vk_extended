//
//  String.swift
//  VKExt
//
//  Created by programmist_NA on 20.05.2020.
//

import Foundation
import UIKit

enum NameCases: String {
    case nom
    case gen
    case dat
    case acc
    case ins
    case abl
}

extension NSRegularExpression {
    func matches(_ string: String) -> Bool {
        let range = NSRange(location: 0, length: string.utf16.count)
        return firstMatch(in: string, options: [], range: range) != nil
    }
}

extension Character {
    /// A simple emoji is one scalar and presented to the user as an Emoji
    var isSimpleEmoji: Bool {
        guard let firstScalar = unicodeScalars.first else { return false }
        return firstScalar.properties.isEmoji && firstScalar.value > 0x238C
    }

    var isCombinedIntoEmoji: Bool { unicodeScalars.count > 1 && unicodeScalars.first?.properties.isEmoji ?? false }

    var isEmoji: Bool { isSimpleEmoji || isCombinedIntoEmoji }
}
extension Character {
    static var space: Character {
        return " "
    }
}
extension String {
    var isSingleEmoji: Bool { count == 1 && containsEmoji }

    var containsEmoji: Bool { contains { $0.isEmoji } }

    var containsOnlyEmoji: Bool { !isEmpty && !contains { !$0.isEmoji } }

    var emojiString: String { emojis.map { String($0) }.reduce("", +) }

    var emojis: [Character] { filter { $0.isEmoji } }

    var emojiScalars: [UnicodeScalar] { filter { $0.isEmoji }.flatMap { $0.unicodeScalars } }
}
extension NSAttributedString {
    func height(with width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, context: nil)

        return ceil(boundingBox.height)
    }
}
extension String {
    static func random(_ length: Int) -> String {
        let letters: NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let lettersLen = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(lettersLen)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }

    func matches(for regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
            return results.map {
                String(self[Range($0.range, in: self)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }

    // Преобразовать [id000|Name] в Name и выделить цветом
    var findNameFromBrackets: (NSAttributedString, [NSRange], [String]) {
        if let regex = try? NSRegularExpression(pattern: "[a-z0-9\\[]*[|]|[\\]]"), let regexName = try? NSRegularExpression(pattern: "[a-zA-ZА-Я0-9а-я\\s]*[\\]]"), let regexId = try? NSRegularExpression(pattern: "[0-9]*[|]"), regex.matches(self), regexName.matches(self), regexId.matches(self) {
            let editedString = self.replacingOccurrences(of: "[a-z0-9\\[]*[|]|[\\]]", with: "$1", options: .regularExpression)
            var names = [String]()
            for name in matches(for: regexName.pattern) {
                let newName = name.dropLast()
                names.append(String(newName))
            }
            let attribute = NSMutableAttributedString.init(string: editedString, attributes: [.font: GoogleSansFont.regular(with: 15), .foregroundColor: UIColor.adaptableTextPrimaryColor])
            var range = NSRange()
            var ranges = [NSRange]()
            for name in names {
                range = (editedString as NSString).range(of: name)
                ranges.append(range)
                attribute.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.systemBlue , range: range)
                attribute.addAttribute(NSAttributedString.Key.font, value: GoogleSansFont.medium(with: 15) , range: range)
            }
            var ids = [String]()
            for id in matches(for: regexId.pattern) {
                let newId = id.dropLast()
                ids.append(String(newId))
            }
            return (attribute, ranges, ids)
        } else {
            let attribute = NSMutableAttributedString.init(string: self, attributes: [.font: GoogleSansFont.regular(with: 15), .foregroundColor: UIColor.adaptableTextPrimaryColor])
            return (attribute, [NSRange](), [])
        }
    }
    
    func width(with height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: CGFloat.greatestFiniteMagnitude, height: height)

        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        return ceil(boundingBox.width)
    }

    func height(with width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        return ceil(boundingBox.height)
    }
    
    /*func height(with width: CGFloat, font: UIFont) -> CGFloat {
        let label =  UILabel(frame: CGRect(x: 0, y: 0, width: width, height: .greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.text = self
        label.font = font
        label.sizeToFit()
        
        return label.frame.height
    }*/
    
    func with(nameCase: NameCases) -> String {
        return self
    }

    init?(htmlEncodedString: String) {

        guard let data = htmlEncodedString.data(using: .utf8) else {
            return nil
        }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        guard let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            return nil
        }

        self.init(attributedString.string)
    }
    
    public var initials: String {
        
        let words = components(separatedBy: .whitespacesAndNewlines)
        
        //to identify letters
        let letters = CharacterSet.alphanumerics
        var firstChar : String = ""
        var secondChar : String = ""
        var firstCharFoundIndex : Int = -1
        var firstCharFound : Bool = false
        var secondCharFound : Bool = false
        
        for (index, item) in words.enumerated() {
            
            if item.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                continue
            }
            
            //browse through the rest of the word
            for (_, char) in item.unicodeScalars.enumerated() {
                
                //check if its a aplha
                if letters.contains(char) {
                    
                    if !firstCharFound {
                        firstChar = String(char)
                        firstCharFound = true
                        firstCharFoundIndex = index
                        
                    } else if !secondCharFound {
                        
                        secondChar = String(char)
                        if firstCharFoundIndex != index {
                            secondCharFound = true
                        }
                        
                        break
                    } else {
                        break
                    }
                }
            }
        }
        
        if firstChar.isEmpty && secondChar.isEmpty {
            firstChar = ""
            secondChar = ""
        }
        
        return words.count == 1 ? firstChar : firstChar + secondChar
    }
    
    var boolValue: Bool {
        switch self {
        case "true", "TRUE", "True", "1", "Yes", "YES", "yes", "private":
            return true
        case "false", "FALSE", "False", "0", "No", "NO", "no", "normal":
            return false
        default: return false
        }
    }
    
    var intValue: Int {
        return Int(self) ?? 0
    }
    
    var attributedValue: NSAttributedString {
        return NSAttributedString(string: self)
    }
    
    var image: UIImage? {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 0);
        UIColor.clear.set()
        
        let stringBounds = (self as NSString).size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 75)])
        let originX = (size.width - stringBounds.width)/2
        let originY = (size.height - stringBounds.height)/2
        print(stringBounds)
        let rect = CGRect(origin: CGPoint(x: originX, y: originY), size: size)
        UIRectFill(rect)
        
        (self as NSString).draw(in: rect, withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 75)])
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
var attributedSpace: NSAttributedString {
    return NSAttributedString(string: " ")
}
extension StringProtocol where Index == String.Index { // for Swift 4 you need to add the constrain `where Index == String.Index`
    var byWords: [SubSequence] {
        var byWords: [SubSequence] = []
        enumerateSubstrings(in: startIndex..., options: .byWords) { _, range, _, _ in
            byWords.append(self[range])
        }
        return byWords
    }
}
