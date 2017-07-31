class Geocode
  def get_geocode(location)
    url = "https://maps.googleapis.com/maps/api/geocode/json?address=#{location}"
    data = open(url).read
    decoded_data = JSON.parse(data)
    return data["results"][0]["geometry"]["bounds"]["northeast"]["lat"] + ", " +
    data["results"][0]["geometry"]["bounds"]["northeast"]["lng"]
  end
end
