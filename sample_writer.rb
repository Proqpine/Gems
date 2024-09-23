# frozen_string_literal| true

require 'stringio'

# Define the RIFF chunk struct
Chunk = Struct.new(:chunk_id, :chunk_size, :format)

# Create a RIFF chunk
riff_chunk = Chunk.new("RIFF", 0, "WAVE")  # We'll update the size later
fmt_chunk = Chunk.new("fmt ",)

# Open a binary file for writing
File.open("sine_wave.wav", "wb") do |file|
  # Write RIFF chunk
  file.write(riff_chunk.chunk_id)
  chunk_size_pos = file.pos
  file.write([0].pack("V"))  # Placeholder for chunk size
  file.write(riff_chunk.format)

  # Write fmt chunk
  file.write("fmt ")
  file.write([16].pack("V"))  # fmt chunk size (16 for PCM)
  file.write([1].pack("v"))   # audio format (1 for PCM)
  file.write([1].pack("v"))   # num channels (1 for mono)
  file.write([44100].pack("V"))  # sample rate
  file.write([88200].pack("V"))  # byte rate (sample rate * num channels * bits per sample / 8)
  file.write([2].pack("v"))   # block align (num channels * bits per sample / 8)
  file.write([16].pack("v"))  # bits per sample

  # Write data chunk header
  file.write("data")
  data_size_pos = file.pos
  file.write([0].pack("V"))  # Placeholder for data size

  # Generate and write sine wave data
  frequency = 440  # A4 note
  duration = 3  # seconds
  amplitude = 20000

  (44100 * duration).times do |i|
    sample = (amplitude * Math.sin(2 * Math::PI * frequency * i / 44100)).round
    file.write([sample].pack("s"))
  end

  # Go back and write the correct sizes
  file_size = file.pos
  file.seek(data_size_pos)
  file.write([file_size - data_size_pos - 4].pack("V"))  # Data size
  file.seek(chunk_size_pos)
  file.write([file_size - 8].pack("V"))  # Chunk size
end

puts "File 'sine_wave.wav' has been created."

# Create a File
# Write the format chunk and read it back
# Write a short data chunk and play it back
# then read the entire file back using the sample_reader

# https://api.lu.ma/discover/get-paginated-events?discover_place_api_id=discplace-QCcNk3HXowOR97j&pagination_cursor=evt-Djt9E27aJgbxxXF&pagination_limit=25
# https://api.lu.ma/discover/get-paginated-events?discover_place_api_id=discplace-QCcNk3HXowOR97j&pagination_limit=25
# https://api.lu.ma/discover/get-paginated-events?discover_place_api_id=discplace-gCfX0s3E9Hgo3rG&pagination_limit=25
