import SwiftUI

struct DatePickerView: View {
    @Binding var selectedDate: Date
    let onDateSelected: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            DatePicker("Tarih Seç",
                      selection: $selectedDate,
                      in: ...Date(),
                      displayedComponents: [.date])
                .datePickerStyle(.compact)
                .labelsHidden()
                .onChange(of: selectedDate) { _ in
                    onDateSelected()
                }
            
            Text(selectedDate.formatted(date: .long, time: .omitted))
                .font(.caption)
                .foregroundColor(Theme.text.opacity(0.7))
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
        .shadow(radius: Theme.shadowRadius)
    }
} 