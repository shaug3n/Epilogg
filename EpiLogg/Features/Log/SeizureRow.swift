import SwiftUI

struct SeizureRow: View {
    let record: SeizureRecord
    var compact = false

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 5) {
                Text(record.occurredAt.formatted(.dateTime.day()))
                    .font(.title2.bold())
                    .foregroundStyle(AppStyle.accent)
                Text(record.occurredAt.formatted(.dateTime.month(.abbreviated)))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppStyle.muted)
            }
            .frame(width: 44)
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(record.type.rawValue).font(.subheadline.weight(.semibold)).foregroundStyle(AppStyle.ink)
                    Spacer()
                    Text(record.occurredAt.formatted(.dateTime.hour().minute()))
                        .font(.caption)
                        .foregroundStyle(AppStyle.muted)
                }
                Text(DiaryFormat.duration(record.durationSeconds))
                    .font(.caption)
                    .foregroundStyle(AppStyle.muted)
                if !record.triggers.isEmpty {
                    Text(record.triggers.joined(separator: " · "))
                        .font(.caption2)
                        .foregroundStyle(AppStyle.accent)
                        .lineLimit(1)
                }
                if !compact, !record.notes.isEmpty {
                    Text(record.notes).font(.caption).foregroundStyle(AppStyle.muted).lineLimit(2)
                }
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppStyle.muted.opacity(0.55))
                .padding(.top, 6)
        }
        .padding(.vertical, compact ? 4 : 12)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
