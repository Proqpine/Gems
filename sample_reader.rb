# frozen_string_literal: true

require 'csv'
require 'stringio'

def process_fmt(audio, chunk_size)
  fmt_chunk_data = audio.read(chunk_size)
  audio_format, num_channels, sample_rate, byte_rate, block_align, bits_per_sample = fmt_chunk_data.unpack('S<S<L<L<S<S<')

  puts "\n|= fmt"
  puts "Audio Format: #{audio_format}"
  puts "Number of Channels: #{num_channels}"
  puts "Sample Rate: #{sample_rate}"
  puts "Byte Rate: #{byte_rate}"
  puts "Block Align: #{block_align}"
  puts "Bits per Sample: #{bits_per_sample}"

  @num_channels = num_channels
  @bits_per_sample = bits_per_sample
end

def proess_data(_audio, chunk_size)
  number_of_samples = chunk_size / (@num_channels * (@bits_per_sample / 8))
  puts "\n|= data"
  puts "Number of Samples: #{number_of_samples}"
end

File.open('c8hannel.wav', 'rb') do |audio|
  riff_id = audio.read(4)
  riff_size = audio.read(4).unpack1('L')
  wave_id = audio.read(4)

  puts "RIFF ID: #{riff_id.inspect}, RIFF Size: #{riff_size}, Format: #{wave_id.inspect}"

  until audio.eof?
    chunk_id = audio.read(4)
    chunk_size = audio.read(4).unpack1('L')

    case chunk_id
    when 'fmt '
      process_fmt(audio, chunk_size)
      break
    else
      puts 'Dunno'
    end

    next unless chunk_id == 'data'

    length = audio.read(4).unpack1('l')
    wavedata = audio.read(length)
    ch1, ch2 = wavedata.read(4).unpack1('ss')
    puts "CH1: #{ch1}, CH2: #{ch2}"
    break
    # path = 'out.txt'
    # File.open(path, 'a+') do |file|
    #   file << "Chunk ID: #{chunk_id.inspect}, Chunk Size: #{chunk_size}\n"
    # end
  end
end
