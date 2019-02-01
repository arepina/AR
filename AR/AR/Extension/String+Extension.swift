//
//  String+Extension.swift
//  AR
//
//  Created by Анастасия on 16/12/2018.
//  Copyright © 2018 Anastasia. All rights reserved.
//

import UIKit

extension String {
    func image() -> UIImage? {
        let size = CGSize(width: 70, height: 70)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.clear.set()
        let rect = CGRect(origin: CGPoint(), size: size)
        UIRectFill(CGRect(origin: CGPoint(), size: size))
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key(rawValue: NSAttributedString.Key.paragraphStyle.rawValue): paragraph, NSAttributedString.Key(rawValue: NSAttributedString.Key.font.rawValue): UIFont.systemFont(ofSize: 6), NSAttributedString.Key(rawValue: NSAttributedString.Key.foregroundColor.rawValue) : UIColor.red]
        (self as NSString).draw(in: rect, withAttributes: attributes)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
