//
//  CalendarView.swift
//  calendartest1
//
//  Created by KK on 2024/01/21.
//

import SwiftUI

// Date extension
extension Date {
    func allDatesInMonth() -> [Date] {
        var dates: [Date] = []
        let calendar = Calendar.current
        
        let range = calendar.range(of: .day, in: .month, for: self)!
        let monthFirstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: self))!
        
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthFirstDay) {
                dates.append(date)
            }
        }
        
        return dates
    }
    
    func monthAsString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        return dateFormatter.string(from: self)
    }
    
    func isSameDay(as otherDate: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, inSameDayAs: otherDate)
    }
    
    func firstDayOfMonthWeekday() -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        let firstDayOfMonth = calendar.date(from: components)!
        return calendar.component(.weekday, from: firstDayOfMonth)
    }
    
    func isToday() -> Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(self)
    }
}

struct CalendarView: View {
    @StateObject private var eventManager = EventManager()
    @State private var currentDate = Date()
    @State private var selectedDate: Date? // 追加したState変数
    
    @State private var showingAddEventView = false
    @State private var newEventTitle = ""
    
    @State private var showingMonthPicker = false
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    
    var body: some View {
        VStack {
            
            Button("Change Month") {
                showingMonthPicker = true
            }
            .sheet(isPresented: $showingMonthPicker) {
                MonthYearPickerView(selectedMonth: $selectedMonth, selectedYear: $selectedYear)
            }
            
            CalendarMonthView(currentDate: $currentDate, selectedDate: $selectedDate)
            
            List {
                // オプショナルバインディングを使用してselectedDateをアンラップ
                if let selectedDate = selectedDate {
                    ForEach(eventManager.events.filter { $0.date.isSameDay(as: selectedDate) }) { event in
                        Text(event.title)
                    }
                }
            }
            
            Button("Add Event") {
                self.showingAddEventView = true
            }
            .sheet(isPresented: $showingAddEventView) {
                VStack {
                    TextField("Event Title", text: $newEventTitle)
                    HStack{
                        Button("Cancel") {
                            showingAddEventView = false
                            newEventTitle = ""
                        }
                        
                        Spacer()
                            .frame(width: 50)
                        
                        Button("Save") {
                            if let selectedDate = self.selectedDate {
                                let newEvent = Event(title: newEventTitle, date: selectedDate)
                                eventManager.events.append(newEvent)
                            }
                            showingAddEventView = false
                            newEventTitle = ""
                        }
                    }
                }
                .padding()
            }
            .onChange(of: selectedMonth) { newMonth in
                updateCurrentDate()
            }
            .onChange(of: selectedYear) { newYear in
                updateCurrentDate()
            }
        }
    }
    
    private func updateCurrentDate() {
        let components = DateComponents(year: selectedYear, month: selectedMonth)
        if let newDate = Calendar.current.date(from: components) {
            currentDate = newDate
        }
    }
}

struct MonthYearPickerView: View {
    @Binding var selectedMonth: Int
    @Binding var selectedYear: Int
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Picker("Month", selection: $selectedMonth) {
                    ForEach(1...12, id: \.self) { month in
                        Text("\(month)").tag(month)
                    }
                }
                
                Picker("Year", selection: $selectedYear) {
                    ForEach(2020...2030, id: \.self) { year in
                        Text("\(year)").tag(year)
                    }
                }
                HStack {
                    Spacer()
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    Spacer()
                }
            }
            .navigationTitle("Select Month and Year")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}


struct CalendarMonthView: View {
    @Binding var currentDate: Date
    @Binding private var selectedDate: Date?
    
    private var daysInWeek: [String] = ["日", "月", "火", "水", "木", "金", "土"]
    
    // Public initializer
    public init(currentDate: Binding<Date>, selectedDate: Binding<Date?>) {
        self._currentDate = currentDate
        self._selectedDate = selectedDate // selectedDateを初期化
    }
    
    var body: some View {
        VStack {
            Text(currentDate.monthAsString())
                .font(.title)
                .padding()
            HStack {
                ForEach(daysInWeek, id: \.self) { day in
                    Text(day)
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(), count: 7), spacing: 15) {
                // 月の最初の日の曜日に応じた空白セルを追加
                ForEach(0..<currentDate.firstDayOfMonthWeekday() - 1, id: \.self) { _ in
                    Text("")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // 日付セル
                ForEach(currentDate.allDatesInMonth(), id: \.self) { date in
                    Text("\(date, formatter: dateFormatter)")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(backgroundColor(for: date))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(date == selectedDate ? Color.black : Color.clear, lineWidth: 2)
                        )
                        .onTapGesture {
                            self.selectedDate = date
                        }
                }
            }
            .gesture(DragGesture()
                .onEnded { value in
                    if value.translation.width > 0 {
                        self.changeMonth(by: -1)
                    } else if value.translation.width < 0 {
                        self.changeMonth(by: 1)
                    }
                }
            )
        }
    }
    
    private func changeMonth(by amount: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: amount, to: currentDate) {
            currentDate = newDate
        }
    }
    
    private func backgroundColor(for date: Date) -> Color {
        if date.isToday() {
            return Color.cyan
        } else {
            return Color.gray.opacity(0.2) // 他の日付の背景色
        }
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}

// DateFormatter instance for formatting the date
let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "d"
    return formatter
}()

