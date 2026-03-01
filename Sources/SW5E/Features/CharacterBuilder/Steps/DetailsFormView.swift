import SwiftUI

// MARK: - Step 7: Character Details Form

struct DetailsFormView: View {
    @ObservedObject var vm: CharacterBuilderViewModel
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case name, age, appearance, backstory
    }

    private var nameIsEmpty: Bool {
        vm.draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Character Details")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.lightText)
                    Text("Give your character a name and identity.")
                        .font(.subheadline)
                        .foregroundStyle(Color.mutedText)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                VStack(spacing: 16) {
                    // MARK: Name (required)
                    DetailsField(
                        label: "Character Name",
                        systemImage: "person.fill",
                        isRequired: true,
                        accentColor: .veilGold
                    ) {
                        TextField("Enter character name…", text: $vm.draft.name)
                            .focused($focusedField, equals: .name)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .age }
                            .foregroundStyle(nameIsEmpty ? Color.mutedText : Color.lightText)
                    }

                    // Name validation
                    if !vm.draft.name.isEmpty && nameIsEmpty {
                        Label("Name cannot be blank", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(Color.voidRed)
                            .padding(.horizontal, 20)
                            .padding(.top, -10)
                    }

                    // MARK: Age (optional)
                    DetailsField(
                        label: "Age",
                        systemImage: "calendar",
                        isRequired: false,
                        accentColor: .mutedText
                    ) {
                        TextField("Optional", text: $vm.draft.age)
                            .focused($focusedField, equals: .age)
                            .keyboardType(.numberPad)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .appearance }
                            .foregroundStyle(Color.lightText)
                    }

                    // MARK: Physical Appearance (optional)
                    DetailsField(
                        label: "Physical Appearance",
                        systemImage: "eye.fill",
                        isRequired: false,
                        accentColor: .mutedText
                    ) {
                        TextField("Height, build, distinguishing features…", text: $vm.draft.appearance, axis: .vertical)
                            .focused($focusedField, equals: .appearance)
                            .lineLimit(3...5)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .backstory }
                            .foregroundStyle(Color.lightText)
                    }

                    // MARK: Backstory (optional + AI generate)
                    VStack(alignment: .leading, spacing: 8) {
                        // Label row
                        HStack {
                            Label {
                                Text("Backstory")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.mutedText)
                            } icon: {
                                Image(systemName: "text.book.closed.fill")
                                    .foregroundStyle(Color.mutedText)
                            }

                            Spacer()

                            // AI Generate button
                            Button {
                                focusedField = nil
                                Task { await vm.generateBackstory() }
                            } label: {
                                HStack(spacing: 4) {
                                    if vm.isGeneratingBackstory {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                            .tint(Color.veilGold)
                                    } else {
                                        Image(systemName: "sparkles")
                                            .font(.caption.weight(.semibold))
                                    }
                                    Text(vm.isGeneratingBackstory ? "Generating…" : "Generate")
                                        .font(.caption.weight(.semibold))
                                }
                                .foregroundStyle(Color.veilGold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.veilGold.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(Color.veilGold.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .disabled(vm.isGeneratingBackstory || nameIsEmpty)
                        }

                        // Backstory text editor
                        ZStack(alignment: .topLeading) {
                            if vm.draft.backstory.isEmpty {
                                Text("Your character's history, motivations, and goals…")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.mutedText.opacity(0.6))
                                    .padding(.horizontal, 4)
                                    .padding(.top, 8)
                                    .allowsHitTesting(false)
                            }

                            TextEditor(text: $vm.draft.backstory)
                                .focused($focusedField, equals: .backstory)
                                .font(.subheadline)
                                .foregroundStyle(Color.lightText)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 120, maxHeight: 200)
                        }
                        .padding(10)
                        .background(Color.spaceCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    focusedField == .backstory ? Color.veilGold.opacity(0.5) : Color.borderSubtle,
                                    lineWidth: 1
                                )
                        )
                    }
                    .padding(.horizontal, 16)
                }

                // Generate AI hint
                if nameIsEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundStyle(Color.mutedText)
                        Text("Enter a name to enable AI backstory generation.")
                            .font(.caption)
                            .foregroundStyle(Color.mutedText)
                    }
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 20)
            }
        }
        .background(Color.spacePrimary)
        .onTapGesture { focusedField = nil }
    }
}

// MARK: - Details Field Helper

private struct DetailsField<Content: View>: View {
    let label: String
    let systemImage: String
    let isRequired: Bool
    let accentColor: Color
    @ViewBuilder var content: Content
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.caption)
                    .foregroundStyle(accentColor)
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(accentColor)
                if isRequired {
                    Text("*")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.voidRed)
                }
            }

            content
                .padding(12)
                .background(Color.spaceCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.borderSubtle, lineWidth: 1)
                )
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Preview

#Preview("Details Form") {
    let vm = CharacterBuilderViewModel()
    vm.draft.name = "Kira Voss"
    vm.draft.species = CBSpecies.samples.first
    vm.draft.charClass = CBClass.samples.first
    return DetailsFormView(vm: vm)
        .preferredColorScheme(.dark)
        .background(Color.spacePrimary)
}
