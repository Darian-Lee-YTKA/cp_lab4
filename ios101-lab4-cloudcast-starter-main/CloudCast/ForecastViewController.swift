//
//  ViewController.swift
//  CloudCast
//
//  Created by Mari Batilando on 3/29/23.
//

import UIKit

class ForecastViewController: UIViewController {
    private var selectedLocationIndex = 0 // keeps track of the current selected location

        private func changeLocation(withLocationIndex locationIndex: Int) {
            guard locationIndex < locations.count else { return }
            let location = locations[locationIndex]
            locationLabel.text = location.name
            WeatherForecastService.fetchForecast(latitude: location.latitude, longitude: location.longitude) { forecast in
                self.configure(with: forecast)
            }
        }
        private func configure(with forecast: CurrentWeatherForecast) {
            forecastImageView.image = forecast.weatherCode.image
            descriptionLabel.text = forecast.weatherCode.description
            temperatureLabel.text = "\(forecast.temperature)"
            windspeedLabel.text = "\(forecast.windSpeed) mph"
            windDirectionLabel.text = "\(forecast.windDirection)°"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM d, yyyy"
            dateLabel.text = dateFormatter.string(from: Date())
        }
  
  @IBOutlet weak var locationLabel: UILabel!
  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var temperatureLabel: UILabel!
  @IBOutlet weak var windspeedLabel: UILabel!
  @IBOutlet weak var windDirectionLabel: UILabel!
  @IBOutlet weak var dateLabel: UILabel!
  @IBOutlet weak var forecastImageView: UIImageView!
    private var locations = [Location]() // stores the different locations
              override func viewDidLoad() {
                  changeLocation(withLocationIndex: 0)
                  super.viewDidLoad()
                  addGradient()
                  // Create a few locations to show the forecast for. Feel free to add your own custom location!
                  let sanJose = Location(name: "San Jose", latitude: 37.335480, longitude: -121.893028)
                  let manila = Location(name: "Manila", latitude: 12.8797, longitude: 121.7740)
                  let italy = Location(name: "Italy", latitude: 41.8719, longitude: 12.5674)
                  locations = [sanJose, manila, italy]
              }
      
      private func addGradient() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [UIColor(red: 0.54, green: 0.88, blue: 0.99, alpha: 1.00).cgColor,
                                UIColor(red: 0.51, green: 0.81, blue: 0.97, alpha: 1.00).cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
      }
      
        @IBAction func didTapBackButton(_ sender: UIButton) {
                selectedLocationIndex = max(0, selectedLocationIndex - 1) // make sure selectedLocationIndex is always >= 0
                changeLocation(withLocationIndex: selectedLocationIndex)
            }
            @IBAction func didTapForwardButton(_ sender: UIButton) {
                selectedLocationIndex = min(locations.count - 1, selectedLocationIndex + 1) // make sure selectedLocationIndex is always < locations.count
                changeLocation(withLocationIndex: selectedLocationIndex)
            }
        }

struct Location {
  let name: String
  let latitude: Double
  let longitude: Double
}


class WeatherForecastService {
  static func fetchForecast(latitude: Double,
                            longitude: Double,
                            completion: ((CurrentWeatherForecast) -> Void)? = nil) {
    let parameters = "latitude=\(latitude)&longitude=\(longitude)&current_weather=true&temperature_unit=fahrenheit&timezone=auto&windspeed_unit=mph"
    let url = URL(string: "https://api.open-meteo.com/v1/forecast?\(parameters)")!
    // create a data task and pass in the URL
      let task = URLSession.shared.dataTask(with: url) { data, response, error in
          // this closure is fired when the response is received
          guard error == nil else {
              assertionFailure("Error: \(error!.localizedDescription)")
              return
          }
          
          guard let httpResponse = response as? HTTPURLResponse else {
              assertionFailure("Invalid response")
              return
          }
          guard let data = data, httpResponse.statusCode == 200 else {
              assertionFailure("Invalid response status code: \(httpResponse.statusCode)")
              return
          }
          let decoder = JSONDecoder()
          let response = try! decoder.decode(WeatherAPIResponse.self, from: data)
          DispatchQueue.main.async {
              completion?(response.currentWeather)
          }
      }
    task.resume() // resume the task and fire the request
  }

private static func parse(data: Data) -> CurrentWeatherForecast {
    // transform the data we received into a dictionary [String: Any]
    let jsonDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
    let currentWeather = jsonDictionary["current_weather"] as! [String: Any]
    // wind speed
    let windSpeed = currentWeather["windspeed"] as! Double
    // wind direction
    let windDirection = currentWeather["winddirection"] as! Double
    // temperature
    let temperature = currentWeather["temperature"] as! Double
    // weather code
    let weatherCodeRaw = currentWeather["weathercode"] as! Int
    return CurrentWeatherForecast(windSpeed: windSpeed,
                                  windDirection: windDirection,
                                  temperature: temperature,
                                  weatherCodeRaw: weatherCodeRaw)
  }
}





struct WeatherAPIResponse: Decodable {
  let currentWeather: CurrentWeatherForecast

  private enum CodingKeys: String, CodingKey {
    case currentWeather = "current_weather"
  }
}


struct CurrentWeatherForecast: Decodable { // conform to the Decodable protocol
    let windSpeed: Double
      let windDirection: Double
      let temperature: Double
      let weatherCodeRaw: Int
    var weatherCode: WeatherCode {
        return WeatherCode(rawValue: weatherCodeRaw) ?? .clearSky
      }
    

  private enum CodingKeys: String, CodingKey {
    case windSpeed = "windspeed"
    case windDirection = "winddirection"
    case temperature = "temperature"
    case weatherCodeRaw = "weathercode"
  }
}
