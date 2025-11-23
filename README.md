PDF-Maker

📌 App Overview

A lightweight PDF converter focused on fast creation and editing of PDF documents.
Key features:
	•	create PDFs from images and text pages;
	•	add, delete, and reorder pages;
	•	merge multiple PDF files into a single document;
	•	preview documents using PDFKit;
	•	save PDFs to local storage;
	•	export and share generated files;
	•	view and manage the list of saved PDFs.

⸻

🏗 Architecture
	•	Pattern: MVVM
	•	Navigation: NavigationStack
	•	PDF processing: PDFKit + custom wrappers/conversion logic for images → PDF pages
	•	File storage: FileManager, Core Data (document metadata, indexing, search)
	•	Concurrency: Task, async/await (no third-party dependencies)

⸻

🛠 Technologies & Stack
	•	Language: Swift
	•	UI: SwiftUI
	•	PDF: PDFKit
	•	Storage: FileManager, Core Data
	•	Architecture: MVVM
