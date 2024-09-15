# frozen_string_literal: true

require 'rss'
require 'open-uri'
require 'openai'
require 'net/http'
require 'fileutils'

url = 'https://feeds.simplecast.com/XA_851k3'

OpenAI.configure do |config|
  config.access_token = ENV.fetch('OPENAI_ACCESS_TOKEN')
  config.log_errors = true
end

def sanitize_filename(file_name)
  file_name.gsub(/\s+/, '_')
end

def download(url, file_name, directory)
  sanitized_file_name = sanitize_filename(file_name)
  path = File.join(directory, "#{sanitized_file_name}.mp3")
  FileUtils.mkdir_p(directory) unless File.directory?(directory)

  case io = URI.open(url)
  when StringIO
    File.open(path, 'wb') { |f| f.write(io.read) }
  when Tempfile
    io.close
    FileUtils.mv(io.path, path)
  end
  path
end

def split_audio(file_path, chunk_duration = 300)
  output_pattern = "#{File.basename(file_path, '.*')}_%03d#{File.extname(file_path)}"
  command = "ffmpeg -i #{file_path} -f segment -segment_time #{chunk_duration} -c copy #{output_pattern}"

  unless system(command)
    puts "FFmpeg command failed: #{command}"
  end
end

def transcribe(file_path, title)
  client = OpenAI::Client.new
  split_audio(file_path, 300)
  FileUtils.mkdir_p('transcripts') unless File.directory?('transcripts')

  Dir.glob("#{File.basename(file_path, '.*')}_*#{File.extname(file_path)}").each do |chunk_file|
    File.open(chunk_file, 'rb') do |file|
      begin
        response = client.audio.transcribe(
          parameters: {
            model: 'whisper-1',
            file: file,
            language: 'en'
          }
        )
        File.write("transcripts/#{title}", response['text'], mode: 'a')
        puts "Transcription for #{chunk_file}: #{response['text']}"
      rescue => e
        puts "Error transcribing #{chunk_file}: #{e.message}"
      end
    end
  end
end

def get_script(item)
  @limit_episode ||= 0
  if @limit_episode < 2
    file_path = download(item.enclosure.url, item.title, 'episodes')
    transcribe(file_path, item.title)
    @limit_episode += 1
  else
    exit
  end
end

URI.open(url) do |rss|
  feed = RSS::Parser.parse(rss)
  puts "Title: #{feed.channel.title}"
  feed.items.each do |item|
    get_script(item)
  end
end
