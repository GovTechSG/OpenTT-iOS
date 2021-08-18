//
//  TraceTogetherWidget.swift
//  TraceTogetherWidget
//  OpenTraceTogether

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {

    @AppStorage(WidgetUtils.widgetDataUserDefaultsKey, store: WidgetUtils.userDefaults) var widgetData = Data()

    func placeholder(in context: Context) -> SafeEntry {
        let model = WidgetUtils.getWidgetModel(from: widgetData)
        return SafeEntry(date: Date(), venueName: model.venueName, showCheckIn: model.showCheckIn)
    }

    func getSnapshot(in context: Context, completion: @escaping (SafeEntry) -> Void) {
        let model = WidgetUtils.getWidgetModel(from: widgetData)
        let entry = SafeEntry(date: Date(), venueName: model.venueName, showCheckIn: model.showCheckIn)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SafeEntry>) -> Void) {
        let model = WidgetUtils.getWidgetModel(from: widgetData)
        var entries = [SafeEntry(date: Date(), venueName: model.venueName, showCheckIn: model.showCheckIn)]

        /// Automatically remove current SE after some hours. This might happen when user forgot to checkout.
        if let removeDate = model.removeDate {
            entries.append(SafeEntry(date: removeDate, venueName: "", showCheckIn: model.showCheckIn))
        }
        let timeline = Timeline(entries: entries, policy: .never)
        completion(timeline)
    }
}

struct SafeEntry: TimelineEntry {
    let date: Date
    let venueName: String
    let showCheckIn: Bool
}

struct TraceTogetherWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            Color.set(colorScheme)

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.navBarStart, Color.navBarEnd]),
                        startPoint: UnitPoint(x: 0, y: 0),
                        endPoint: UnitPoint(x: 0, y: 1)
                    ))
                Image("Logo")
                    .padding(EdgeInsets(top: 11, leading: 16, bottom: 11, trailing: 16)).accessibilityHidden(true)
            }.fixedSize(horizontal: false, vertical: true)

            VStack {

                Spacer()

                HStack(alignment: .center, spacing: 8) {
                    Image("SafeEntryIcon").accessibilityHidden(true)
                    Text(String.widgetTitle)
                        .font(.system(size: 16))
                        .foregroundColor(Color.theme4F)
                    Spacer()

                    if (entry.showCheckIn) {
                        TTButton(String.newCheckIn, actionType: .checkIn)
                    }
                }

                Spacer()

                Rectangle()
                    .fill(Color.themeF2)
                    .frame(width: .none, height: 1, alignment: .center)

                Spacer()

                ZStack {
                    HStack(alignment: .center, spacing: nil) {
                        VStack(alignment: .leading, spacing: nil) {
                            Text(String.lastQRCheckIn)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .font(.system(size: 14))
                                .foregroundColor(Color.theme82)
                            Text(entry.venueName.isEmpty ? " " : entry.venueName)
                                .lineLimit(1)
                                .font(.system(size: 16, weight: .bold, design: .default))
                                .foregroundColor(Color.theme33)
                        }

                        Spacer()

                        TTButton(String.checkOut, actionType: .checkOut)

                    }.opacity(entry.venueName.isEmpty ? 0 : 1)
                    Text(String.noActiveCheckIn)
                        .font(.system(size: 16))
                        .foregroundColor(Color.theme82)
                        .opacity(entry.venueName.isEmpty ? 1 : 0)
                }

                Spacer()

            }.padding(.horizontal, 16)
        }
        .background(Color.themeFF)
        .widgetURL(WidgetUtils.url(from: .viewPass))
    }
}

@main
struct TraceTogetherWidget: Widget {
    let kind: String = "TraceTogetherWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TraceTogetherWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(String.widgetTitle)
        .description(String.widgetDescription)
        .supportedFamilies([.systemMedium])
    }
}

struct TraceTogetherWidget_Previews: PreviewProvider {
    static let entry = SafeEntry(date: Date(), venueName: "Lorem Ipsum", showCheckIn: true)
    static var previews: some View {
        Group {
            TraceTogetherWidgetEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .environment(\.colorScheme, .light)
            TraceTogetherWidgetEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .environment(\.colorScheme, .dark)
        }
    }
}
