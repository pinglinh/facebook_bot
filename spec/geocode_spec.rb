require_relative "../lib/geocode"

describe Geocode do
  it "it should return coordinates" do
    expect(Geocode.coords("london")).to eq("51.5, 0.1")
  end
end
