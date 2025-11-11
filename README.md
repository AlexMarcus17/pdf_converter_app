# 📄 PDF Converter App

A fully offline, Flutter-based PDF utility app using **Cupertino (iOS-style) widgets only**, with a clean and scalable UI/UX.  
No platform channels or native code — **100% Flutter packages only**.

---

## 🚀 Features Overview (11 Tools)

The app provides **11 tools** grouped into 3 main categories, accessible from the **Home tab**. The **Scanner** tool is accessible from the bottom navigation bar as a separate tab.

---

### 🏠 Home (10 Tools)

Organized in a **3-column `GridView` layout**, each row contains 3 tool cards.
Each tool card has an icon an a title with the feature

#### 📂 From PDF
1. **JPEG from PDF** – Extract images as JPEG
2. **PNG from PDF** – Extract images as PNG
3. **Text from PDF** – Extract readable text or OCR

#### 📥 To PDF
4. **Images to PDF** – Convert gallery/camera images
5. **Text to PDF** – Convert typed/pasted text
6. **URL to PDF** – Generate PDF from webpage

#### 🛠 Other Tools
7. **Sign PDF** – Add handwritten signatures
8. **Encrypt PDF** – Add password protection
9. **Merge PDFs** – Combine multiple files
10. **Split PDF** – Extract selected pages

---

### 📷 Scanner Tab

- A **dedicated page** for camera-based scanning
- Auto-crop and enhance documents using edge detection
- Converts scan result to PDF directly

---

## 🧭 Bottom Navigation Bar

Uses Cupertino-style `CupertinoTabScaffold` with **4 tabs**:

| Icon | Label     | Screen           | Description                               |
|------|-----------|------------------|-------------------------------------------|
| 🏠    | Home       | `HomeScreen()`    | 10 categorized tools                      |
| 📷    | Scan       | `ScannerPage()`   | Live scan, crop, and convert to PDF       |
| 🕘    | History    | `HistoryScreen()` | Saved projects in grid format             |
| ⚙️    | Settings   | `SettingsScreen()`| App preferences and info                  |

---

## 🕘 History Screen

- Displays completed projects in a **2-column `GridView`**
- Each tile shows thumbnail, file name, and type
- Data stored locally using hive