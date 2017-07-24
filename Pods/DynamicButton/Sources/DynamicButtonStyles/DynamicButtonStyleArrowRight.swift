/*
 * DynamicButton
 *
 * Copyright 2015-present Yannick Loriot.
 * http://yannickloriot.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

import UIKit

/// Rightwards arrow style: →
struct DynamicButtonStyleArrowRight: DynamicButtonBuildableStyle {
  let pathVector: DynamicButtonPathVector

  init(center: CGPoint, size: CGFloat, offset: CGPoint, lineWidth: CGFloat) {
    let leftPoint   = CGPoint(x: offset.x, y: center.y)
    let headPoint   = CGPoint(x: offset.x + size - lineWidth, y: center.y)
    let topPoint    = CGPoint(x: offset.x + size - size / 3.2, y: center.y + size / 3.2)
    let bottomPoint = CGPoint(x: offset.x + size - size / 3.2, y: center.y - size / 3.2)

    let p1 = PathHelper.line(from: leftPoint, to: headPoint)
    let p2 = PathHelper.line(from: headPoint, to: topPoint)
    let p3 = PathHelper.line(from: headPoint, to: bottomPoint)

    pathVector = DynamicButtonPathVector(p1: p1, p2: p2, p3: p3, p4: p1)
  }

  /// "Arrow Right" style.
  static var styleName: String {
    return "Arrow Right"
  }
}
