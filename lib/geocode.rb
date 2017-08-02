require "httparty"
require "pp"

class Geocode
  def get_geocode(location)
    url = "https://maps.googleapis.com/maps/api/geocode/json"
    # ?address=#{location}&key=#{ENV["GOOGLE_API_KEY"]}"
    data = HTTParty.get(url, format: :plain,
      query: {
        address: location,
        key: ENV["GOOGLE_API_KEY"]
        })
    decoded_data = JSON.parse(data)
    pp decoded_data
    return decoded_data["results"][0]["geometry"]["bounds"]["northeast"]["lat"].round(1).to_s + ", " +
    decoded_data["results"][0]["geometry"]["bounds"]["northeast"]["lng"].round(1).to_s
  end
end
