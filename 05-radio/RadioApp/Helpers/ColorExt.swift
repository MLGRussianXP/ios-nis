//
//  ColorExt.swift
//  RadioApp
//  Created by B.RF Group on 03.11.2025.
//
import SwiftUI

// MARK: - Расширение для цветов приложения
/// Кастомное расширение для определения цветовой палитры приложения
/// Поддерживает светлую и темную тему через assets catalogs
extension Color {
    
    // MARK: - Основные цвета приложения
    
    /// Основной цвет фона (адаптивный: светлый/темный)
    /// В assets: "EFF0F9" для светлой темы, "282C31" для темной
    static let primary_color = Color("EFF0F9_282C31")
    
    /// Основной акцентный цвет приложения
    static let main_color = Color(hex: "657592")
    
    /// Основной белый цвет (адаптивный)
    /// В assets: "657592" для светлой темы, "F4F4F4" для темной
    static let main_white = Color("657592_F4F4F4")
    
    // MARK: - Текстовые цвета
    
    /// Цвет для заголовков (адаптивный)
    static let text_header = Color("333333_F4F4F4")
    
    /// Основной цвет текста (адаптивный)
    static let text_primary = Color("657592_C6CBDA")
    
    /// Основной цвет текста с прозрачностью 80%
    static let text_primary_f1 = Color.text_primary.opacity(0.8)
    
    // MARK: - Второстепенные цвета
    
    /// Цвет линий разделителей (адаптивный)
    static let disc_line = Color("666666_F4F4F4")
    
    // MARK: - Специальные градиентные цвета для неоморфизма
    
    /// Светлый цвет для неоморфного дизайна
    static let offWhite = Color(red: 225 / 255, green: 225 / 255, blue: 235 / 255)
    
    /// Начальный цвет темного градиента
    static let darkStart = Color(red: 50 / 255, green: 60 / 255, blue: 65 / 255)
    
    /// Конечный цвет темного градиента
    static let darkEnd = Color(red: 25 / 255, green: 25 / 255, blue: 30 / 255)
    
    // MARK: - Инициализатор из HEX строки
    
    /// Создает цвет из HEX-строки с поддержкой альфа-канала
    /// - Parameters:
    ///   - hex: HEX-строка (с # или без)
    ///   - alpha: Прозрачность (от 0.0 до 1.0)
    ///
    /// Примеры использования:
    /// ```
    /// Color(hex: "FF0000") // Красный
    /// Color(hex: "#00FF00") // Зеленый
    /// Color(hex: "0000FF", alpha: 0.5) // Синий с прозрачностью 50%
    /// ```
    init(hex: String, alpha: Double = 1) {
        // Очищаем строку от пробелов и символов новой строки, приводим к верхнему регистру
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // Удаляем символ # если он есть в начале строки
        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }
        
        // Используем Scanner для преобразования HEX в числовое значение
        let scanner = Scanner(string: cString)
        scanner.currentIndex = scanner.string.startIndex
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        // Извлекаем компоненты RGB из HEX значения
        let r = (rgbValue & 0xff0000) >> 16  // Красный компонент (биты 16-23)
        let g = (rgbValue & 0xff00) >> 8     // Зеленый компонент (биты 8-15)
        let b = rgbValue & 0xff              // Синий компонент (биты 0-7)
        
        // Создаем цвет с извлеченными компонентами
        // Делим на 0xff (255) для нормализации значений в диапазон 0.0 - 1.0
        self.init(
            .sRGB,
            red: Double(r) / 0xff,
            green: Double(g) / 0xff,
            blue: Double(b) / 0xff,
            opacity: alpha
        )
    }
}

// MARK: - Расширение для градиентов
extension LinearGradient {
    
    /// Упрощенный инициализатор для создания градиента из переменного числа цветов
    /// - Parameter colors: Цвета для градиента (от 2 и более)
    ///
    /// Пример использования:
    /// ```
    /// LinearGradient(.red, .blue, .green)
    /// LinearGradient(.darkStart, .darkEnd)
    /// ```
    init(_ colors: Color...) {
        self.init(
            gradient: Gradient(colors: colors),
            startPoint: .topLeading,    // Начало градиента - верхний левый угол
            endPoint: .bottomTrailing   // Конец градиента - нижний правый угол
        )
    }
}
