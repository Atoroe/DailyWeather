import Foundation

class NetworkManager {
    private init() {}
    static let shared = NetworkManager()
    
    private let key = "e45c3399ca3a074064e3b0998a041892"
    private let units = "metric"
    
    func getWeather(city: String, complition: @escaping ((ForecastModel?) -> ())) {
        guard let url = URL(string: "http://api.openweathermap.org/data/2.5/forecast?id=524901&APPID=\(key)&q=\(city)&units=\(units)") else { return }
        let task = URLSession.shared.dataTask(with: url) { (data, _, error) in
            guard let data = data else { return }
            var decoderForecastModel : ForecastModel?
            do {
                decoderForecastModel = try JSONDecoder().decode(ForecastModel.self, from: data)
                complition(decoderForecastModel)
            } catch let error{
                print(error.localizedDescription)
            }
        }
        task.resume()
        
    }
    
}
