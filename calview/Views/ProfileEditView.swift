import SwiftUI

/// Edits the local Member's profile. Each Member edits only their own; the saved
/// record is shared via the synced document so others can identify them later.
struct ProfileEditView: View {
    @Environment(CalendarStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var timeZoneIdentifier = TimeZone.current.identifier
    @State private var avatarURL = ""

    /// A live preview profile so the avatar updates as fields change.
    private var preview: MemberProfile {
        MemberProfile(id: store.localUserId, firstName: firstName, lastName: lastName,
                      avatarURL: avatarURL)
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    AvatarView(profile: preview, size: 96)
                    Spacer()
                }
                TextField("Photo URL", text: $avatarURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
            } footer: {
                Text("Paste a CDN image link. Photo upload is coming later.")
            }

            Section("Name") {
                TextField("First name", text: $firstName)
                TextField("Last name", text: $lastName)
            }

            Section("Contact") {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section("Time Zone") {
                Picker("Time Zone", selection: $timeZoneIdentifier) {
                    ForEach(TimeZone.knownTimeZoneIdentifiers, id: \.self) { id in
                        Text(id).tag(id)
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    var p = store.myProfile
                    p.id = store.localUserId
                    p.firstName = firstName
                    p.lastName = lastName
                    p.email = email
                    p.timeZoneIdentifier = timeZoneIdentifier
                    p.avatarURL = avatarURL
                    Task { await store.saveProfile(p); dismiss() }
                }
            }
        }
        .onAppear {
            let p = store.myProfile
            firstName = p.firstName
            lastName = p.lastName
            email = p.email
            timeZoneIdentifier = p.timeZoneIdentifier
            avatarURL = p.avatarURL
        }
    }
}
