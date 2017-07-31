require_relative "../lib/geocode"

describe Geocode do
  it "it should return coordinates" do
    geocode = Geocode.new
    result = geocode.get_geocode
    expect(result("london")).to eq("51.5" ", " "0.1")
  end
end
