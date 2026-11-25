import SwiftUI

struct NewChatSheet: View {
    let contacts: [User]
    let onSelect: (User) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var filteredContacts: [User] {
        guard !query.isEmpty else { return contacts }
        return contacts.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            List(filteredContacts) { contact in
                Button {
                    onSelect(contact)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        AvatarView(user: contact, size: 42)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(contact.name)
                                .font(.body.weight(.medium))
                                .foregroundStyle(.primary)
                            Text(contact.statusText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .listStyle(.plain)
            .overlay {
                if filteredContacts.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
            }
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search contacts"
            )
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NewChatSheet(contacts: MockData.contacts) { _ in }
}
