import Foundation
protocol ServiceBuilderProtocol {

}

final class ServiceBuilder: ServiceBuilderProtocol, ObservableObject {
    let pdfGeneratorService = PDFGeneratorService()
}
