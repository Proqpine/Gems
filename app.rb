# frozen_string_literal: true

if ARGV.length != 2
  puts 'Need only one file'
  exit
end

filename = ARGV[1]
fh = File.open(filename)

def read_bytes(data)
  data.readbyte
end

def read_line(data)
  data.readline('\n')
end

option = ARGV[0]
out = option.split('')

out.each do |i|
  case i
  when 'c'
    puts read_bytes(fh)
  when 'l'
    puts read_line(fh).length
  when 'w'
    puts 'I count words'
  end
end

puts filename

fh.close
