require_relative "../bot"

describe Bot do
  it "it should return coordinates" do
    expect(bot.coords("london")).to eq("51.5, 0.1")
  end
end
