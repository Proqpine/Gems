# frozen_string_literal: true

require 'csv'
require 'stringio'

File.open('out.wav', 'rb') do |file|
  # Read the first chunk (should be 'RIFF')
  riff_id = file.read(4) # "RIFF"
  riff_size = file.read(4).unpack1('L') # RIFF chunk size
  wave_id = file.read(4) # Should be 'WAVE'

  puts "RIFF ID: #{riff_id.inspect}, RIFF Size: #{riff_size}, Format: #{wave_id.inspect}"

  until file.eof?
    # Read next chunk ID and size
    chunk_id = file.read(4)
    chunk_size = file.read(4).unpack1('L') # Read 4 bytes for chunk size

    # Debug: Print the chunk ID and size to understand what's being processed
    puts "Chunk ID: #{chunk_id.inspect}, Chunk Size: #{chunk_size}"

    # Check if we found the 'fmt ' chunk
    if chunk_id == 'fmt '
      puts "Found 'fmt ' chunk"

      # Read and parse the fmt chunk
      fmt_chunk_data = file.read(chunk_size)
      audio_format, num_channels, sample_rate, byte_rate, block_align, bits_per_sample = fmt_chunk_data.unpack('S<S<L<L<S<S<')

      # Output the parsed fmt chunk data
      puts "Audio Format: #{audio_format}"
      puts "Number of Channels: #{num_channels}"
      puts "Sample Rate: #{sample_rate}"
      puts "Byte Rate: #{byte_rate}"
      puts "Block Align: #{block_align}"
      puts "Bits per Sample: #{bits_per_sample}"
      break
    else
      # If it's not 'fmt ', skip this chunk and move on to the next one
      file.read(chunk_size)
    end
  end
end

# File.open('wavdata.csv', 'w') do |file|
#   CSV(file) do |csv|
#     csv << %w[ch1 ch2 combined] # Write the headers

#     File.open('out.wav', 'rb') do |wav_file|
#       until wav_file.eof?
#         if wav_file.read(4) == 'data'
#           length = wav_file.read(4).unpack1('l') # Unpack only the first element
#           wavedata = StringIO.new(wav_file.read(length))

#           until wavedata.eof?
#             ch1, ch2 = wavedata.read(4).unpack('ss')
#             csv << [ch1, ch2, ch1 + ch2]
#           end
#         end
#       end
#     end
#   end
# end
