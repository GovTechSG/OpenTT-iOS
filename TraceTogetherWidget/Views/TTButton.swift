//
//  TTButton.swift
//  TraceTogetherWidget
//  OpenTraceTogether

import SwiftUI

struct TTButton: View {
    var title: String
    var actionType: WidgetUtils.ActionType

    init(_ title: String, actionType: WidgetUtils.ActionType) {
        self.title = title
        self.actionType = actionType
    }

    var body: some View {
        Color.buttonBlue.frame(width: 116, height: 28, alignment: .center).cornerRadius(4).overlay(
            Link(title, destination: WidgetUtils.url(from: actionType))
                .minimumScaleFactor(0.5)
                .font(.system(size: 14, weight: .bold, design: .default))
                .foregroundColor(.white)
        )
    }
}
