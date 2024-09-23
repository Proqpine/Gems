# frozen_string_literal: true

# out = [-2587, -2049, -1512, -1153, -616, -257, 279, 817, 1354, 1713].pack('C*').inspect
out = '\x01\xB1\x02\x00'.unpack('C*').inspect
puts out

into = [92, 120, 48, 49, 92, 120, 66, 49, 92, 120, 48, 50, 92, 120, 48, 48].pack('C*').inspect
puts into
