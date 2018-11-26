require 'rails_helper'

describe StripEmoji do
  describe '.replace' do
    it 'replaces the emoji with ?' do
      expect(StripEmoji.replace('😀alallaこのやろ')).to eq '?alallaこのやろ'
    end
  end
end
