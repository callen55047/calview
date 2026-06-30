import SwiftUI

struct LegendEditorView: View {
    @Environment(CalendarStore.self) private var store
    @State private var showingAdd = false
    @State private var editingEntry: LegendEntry?

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.legend) { entry in
                    HStack(spacing: 12) {
                        Circle().fill(entry.color).frame(width: 24, height: 24)
                        Text(entry.label)
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(.tertiary).font(.caption)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { editingEntry = entry }
                }
                .onDelete { indexSet in
                    var updated = store.legend
                    updated.remove(atOffsets: indexSet)
                    Task { await store.saveLegend(updated) }
                }
            }
            .navigationTitle("Legend")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingAdd) { LegendEntryEditView(entry: nil) }
            .sheet(item: $editingEntry) { entry in LegendEntryEditView(entry: entry) }
        }
        .task { if store.legend.isEmpty { await store.loadMonth() } }
    }
}

struct LegendEntryEditView: View {
    @Environment(CalendarStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let entry: LegendEntry?

    @State private var label = ""
    @State private var color: Color = .red

    var body: some View {
        NavigationStack {
            Form {
                TextField("Label (e.g. Doctor, Gym)", text: $label)
                ColorPicker("Color", selection: $color, supportsOpacity: false)
            }
            .navigationTitle(entry == nil ? "New Category" : "Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var updated = store.legend
                        let new = LegendEntry(id: entry?.id ?? UUID().uuidString,
                                              label: label, hex: color.hexString)
                        if let idx = updated.firstIndex(where: { $0.id == new.id }) {
                            updated[idx] = new
                        } else {
                            updated.append(new)
                        }
                        Task { await store.saveLegend(updated); dismiss() }
                    }
                    .disabled(label.isEmpty)
                }
            }
            .onAppear {
                if let entry { label = entry.label; color = entry.color }
            }
        }
    }
}
