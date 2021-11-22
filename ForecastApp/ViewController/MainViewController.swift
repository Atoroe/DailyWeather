import UIKit
import CoreLocation
import NVActivityIndicatorView

class MainViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var conditionImageView: UIImageView!
    @IBOutlet weak var conditionLabel: UILabel!
    @IBOutlet weak var tempretareLabel: UILabel!
    @IBOutlet weak var forecastTableView: UITableView!
    @IBOutlet weak var searchTextField: UITextField!
    
    private let titles = Titles()
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let step = 8
    private let dailyCellHeight: CGFloat = 70
    private let weeklyCellHeight: CGFloat = 100
    
    private var activityIndicator: NVActivityIndicatorView!
    private var dataIsReady = false
    private var aditionalDailyData = Array(repeating: Array(repeating: String(), count: 2), count: 3)
    private var days = Array(repeating: String(), count: 4)
    private var icons = Array(repeating: String(), count: 4)
    private var temp = Array(repeating: String(), count: 4)
    private var backgroundImageView = UIImageView()
    private var regionIdentifier = String()
    private var forecastData: ForecastModel? {
        didSet {
            DispatchQueue.main.async {
                guard self.forecastData != nil else { return }
                self.updateData()
                self.forecastTableView.reloadData()
                self.updateMainScreen()
                self.dayUpdate()
                self.activityIndicator.stopAnimating()
                self.backgroundImageView.removeFromSuperview()
                
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchTextField.delegate = self
        addWallpaper(imageView: self.backgroundImageView)
        setupNVActivityIndicatorView()
        hideKeyboardWhenTappedAround()
        forecastTableView.separatorStyle = .none
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
    }
    
    //MARK: - search city
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        guard let locality = sender.text else { return }
        if  locality != ""{
            activityIndicator.startAnimating()
            locationManager.stopUpdatingLocation()
            NetworkManager.shared.getWeather(city: locality) { (model) in
                guard let model = model else { return }
                self.forecastData = model
            }
        } else {
            locationManager.startUpdatingLocation()
        }
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        locationManager.startUpdatingLocation()
        searchTextField.text = ""
    }
    
    //MARK: - create an add wallpaper
    private func addWallpaper(imageView: UIImageView) {
        imageView.frame = CGRect(x: 0,
                                 y: 0,
                                 width: view.frame.size.width,
                                 height: view.frame.size.height)
        imageView.image = UIImage(named: "background")
        view.addSubview(imageView)
    }
    
    //MARK: - updateManeScreen
    private func updateMainScreen() {
        guard let location = forecastData?.city?.name else { return }
        guard let image = forecastData?.list?[0].weather?[0].icon else { return}
        guard let description = forecastData?.list?[0].weather?[0].weatherDescription else { return }
        guard let temp = forecastData?.list?[0].main?.temp else { return }
        locationLabel.text = location
        dayUpdate()
        conditionImageView.image = UIImage(named: image)
        conditionLabel.text = description
        tempretareLabel.text = "\(Int(temp.rounded(.toNearestOrEven)))"
    }
    
    //MARK: - day update
    private func dayUpdate() {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        dayLabel.text = dateFormatter.string(from: date)
    }
    
    
    
    //MARK: - update all forecast data arrays
    private func updateData() {
        updateAdditionalDailyData()
        updateWeeklyData()
    }
    
    private func updateAdditionalDailyData() {
        guard let feelsLike = forecastData?.list?[0].main?.feelsLike else { return }
        guard let pressure = forecastData?.list?[0].main?.pressure else { return }
        guard let humidity = forecastData?.list?[0].main?.humidity else { return }
        guard let windSpeed = forecastData?.list?[0].wind?.speed else { return }
        guard let sunrice = forecastData?.city?.sunrise else { return }
        guard let sunset = forecastData?.city?.sunset else { return }
        let data = ["\(Int(feelsLike.rounded(.toNearestOrEven)))°C",
                    "\(pressure) hPa", "\(humidity)%",
                    "\(convertSpeed(speed: windSpeed)) km/h",
                    convertUTC(timeResult: sunrice),
                    convertUTC(timeResult: sunset)]
        var count = 0
        for row in 0..<aditionalDailyData.count{
            for index in 0..<aditionalDailyData[row].count {
                self.aditionalDailyData[row][index] = data[count]
                count += 1
            }
        }
    }
    
    private func updateWeeklyData() {
        var count = 0
        for index in 0..<days.count {
            count += step
            guard let day = forecastData?.list?[count].dt else { return }
            guard let image = forecastData?.list?[count].weather?[0].icon else { return}
            guard let temp = forecastData?.list?[count].main?.temp else { return }
            days[index] = convertUTC(dayResult: day)
            icons[index] = image
            self.temp[index] = "\(Int(temp.rounded(.toNearestOrEven)))"
        }
    }
    
    //MARK: - convert UTC
    private func convertUTC(timeResult: Int) -> String {
        let date = Date(timeIntervalSince1970: Double(timeResult))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let time = dateFormatter.string(from: date)
        return time
    }
    
    private func convertUTC(dayResult: Int) -> String {
        let date = Date(timeIntervalSince1970: Double(dayResult))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        let day = dateFormatter.string(from: date)
        return day
    }
    
    //MARK: - convert m/c in km/h
    private func convertSpeed(speed: Double) -> Int {
        let convertedSpeed = Int(speed * 3600/1000)
        return convertedSpeed
    }
    
    // MARK: - setup NVActivityIndicatorView
    private func setupNVActivityIndicatorView(){
        let indicatorSize: CGFloat = 70
        let indicatorFrame = CGRect(x: (view.frame.width-indicatorSize)/2,
                                    y: (view.frame.height-indicatorSize)/2,
                                    width: indicatorSize,
                                    height: indicatorSize)
        self.activityIndicator = NVActivityIndicatorView(frame: indicatorFrame,
                                                         type: .ballRotateChase,
                                                         color: UIColor.white,
                                                         padding: 20.0)
        self.activityIndicator.backgroundColor = UIColor.clear
        self.view.addSubview(self.activityIndicator)
        self.activityIndicator.startAnimating()
    }
    
    //MARK: - hide keyboard after return button pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
    
}

// MARK: - UITableView
extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if dataIsReady {
            switch section {
            case 0:
                return titles.dailyTitles.count
            case 1:
                return days.count
            default:
                return aditionalDailyData.count
            }
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        UITableViewCell.appearance().backgroundColor = UIColor.clear
        if indexPath.section == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "DailyCustomTableViewCell", for: indexPath) as? DailyCustomTableViewCell else { return UITableViewCell()
            }
            cell.parameterLabel.text = titles.dailyTitles[indexPath.row][0]
            cell.valueLabel.text = aditionalDailyData[indexPath.row][0]
            cell.secondParameterLabel.text = titles.dailyTitles[indexPath.row][1]
            cell.secondValueLabel.text = aditionalDailyData[indexPath.row][1]
            cell.parameterLabel.textColor = UIColor.white
            cell.valueLabel.textColor = UIColor.white
            cell.secondParameterLabel.textColor = UIColor.white
            cell.secondValueLabel.textColor = UIColor.white
            cell.selectionStyle = .none
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "WeeklyCustomTableViewCell", for: indexPath) as! WeeklyCustomTableViewCell
            cell.dayLabel.text = days[indexPath.row]
            cell.tempLabel.text = " \(temp[indexPath.row])°C"
            cell.conditionImageView.image = UIImage(named: icons[indexPath.row])
            cell.dayLabel.textColor = UIColor.white
            cell.tempLabel.textColor = UIColor.white
            cell.selectionStyle = .none
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 {
            return weeklyCellHeight
        }
        return dailyCellHeight
    }
}

//MARK: - location
extension MainViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0]
        locationManager.stopUpdatingLocation()
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if (error != nil) {
                print("Error in reverseGeocode")
            }
            let placemark = placemarks! as [CLPlacemark]
            if placemark.count > 0 {
                guard let placemark = placemarks?[0] else {return}
                guard let locality = placemark.locality else {return}
                NetworkManager.shared.getWeather(city: locality) { (model) in
                    guard let model = model else { return }
                    self.dataIsReady = true
                    self.forecastData = model
                }
            }
        }
    }
}

// MARK: - hide keyboard
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
