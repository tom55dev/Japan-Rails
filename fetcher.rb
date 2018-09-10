streaks = RewardTemplate.where(name: 'A').flat_map(&:streaks)
Box.activated.where(streak: streaks).group(:streak_id).count

# D - 184 streaks, highest box activated: 2
# E - 137 streaks, highest box activated: 2
# F - 43 streaks, highest box activated: 2
# A - 149 streaks, highest box activated: 2