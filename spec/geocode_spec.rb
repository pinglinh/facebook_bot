require_relative "../lib/geocode"

describe Geocode do
  it "it should return coordinates" do
    geocode = Geocode.new
    result = geocode.get_geocode("london")
    expect(result).to eq("51.7" + ", " + "0.1")
  end
end
