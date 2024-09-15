# frozen_string_literal: true

require 'rss'
require 'open-uri'
require 'openai'
require 'net/http'
require 'fileutils'

# PodcastTranscriber
class PodcastTranscriber
  RSS_URL = 'https://feeds.simplecast.com/XA_851k3' # Replace with podcast of choice
  CHUNK_DURATION = 300 # Set at 5 minutes, allows for processing long audi with OpenAI's Whisper
  MAX_EPISODES = 2 # Increase as needed

  def initialise
    configure_openai
  end

  def process_feed
    feed = fetch_rss_feed
    puts "Title: #{feed.channel.title}"
    feed.items.take(MAX_EPISODES).each do |item|
      process_episode(item)
    end
  end

  private

  def configure_openai
    OpenAI.configure do |config|
      config.access_token = ENV.fetch('OPENAI_ACCESS_TOKEN')
      config.log_errors = true
    end
  end

  def fetch_rss_feed
    URI.open(RSS_URL) { |rss| RSS::Parser.parse(rss) }
  end

  def process_episode(item)
    file_path = download_episode(item)
    transcribe_episode(file_path, item.title)
  end

  def download_episode(item)
    file_name = sanitize_filename(item.title)
    url = item.enclosure.url
    directory = 'episodes'
    path = File.join(directory, "#{file_name}.mp3")

    FileUtils.mkdir_p(directory)

    URI.open(url) do |io|
      File.open(path, 'wb') do |file|
        file.write(io.read)
      end
    end

    path
  end

  def sanitize_filename(file_name)
    file_name.gsub(/\s+/, '_')
  end

  def transcribe_episode(file_path, title)
    split_audio(file_path)
    transcribe_chunks(file_path, title)
  end

  def split_audio(file_path)
    output_pattern = "#{File.basename(file_path, '.*')}_%03d#{File.extname(file_path)}"
    command = "ffmpeg -i #{file_path} -f segment -segment_time #{CHUNK_DURATION} -c copy #{output_pattern}"
    system(command) or puts "FFmpeg command failed: #{command}"
  end

  def transcribe_chunks(file_path, title)
    client = OpenAI::Client.new
    transcript_dir = 'transcripts'
    FileUtils.mkdir_p(transcript_dir)

    Dir.glob("#{File.basename(file_path, '.*')}_*#{File.extname(file_path)}").each do |chunk_file|
      transcribe_chunk(client, chunk_file, title, transcript_dir)
    end
  end

  def transcribe_chunk(client, chunk_file, title, transcript_dir)
    File.open(chunk_file, 'rb') do |file|
      response = client.audio.transcribe(
        parameters: {
          model: 'whisper-1',
          file: file,
          language: 'en'
        }
      )
      File.write(File.join(transcript_dir, "#{title}.md"), response['text'], mode: 'a')
      puts "Transcription for #{chunk_file}: #{response['text']}" # Comment this line to only write to file
    end
  rescue StandardError => e
    puts "Error transcribing #{chunk_file}: #{e.message} \n #{e}"
  end
end

transcriber = PodcastTranscriber.new
transcriber.process_feed
