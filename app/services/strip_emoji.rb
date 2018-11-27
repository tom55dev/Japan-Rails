module StripEmoji
  EMOJI_REGEX = /[^\u0000-\uFFFF]/


  def self.replace(str)
    str.gsub(EMOJI_REGEX, '?')
  end
end
