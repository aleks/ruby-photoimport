require 'optparse'
require 'fileutils'
require 'progressbar'

class Photoimport

  def initialize
    @source_path = ""
    @target_path = ""
    @file_extension = ""
    @files  = []
    @copy_log = []
  end

  def run
    parse_options
    raise "Missing SOURCE argument" if @source_path == ""
    raise "Missing TARGET argument" if @target_path == ""
    raise "Missing FILEEXTENSION argument" if @file_extension == ""

    find_source_files
    find_target_directory
    copy_files_to_target
    show_copy_log
    open_target_directory
  end

  private

    def parse_options
      OptionParser.new do |parser|
        parser.banner = "Usage: photoimport [arguments]"
        parser.on("-s SOURCE", "--source=SOURCE", "Source directory") { |source| @source_path = source }
        parser.on("-t TARGET", "--target=TARGET", "Target directory") { |target| @target_path = target }
        parser.on("-e FILEEXTENSION", "--file-extension=FILEEXTENSION", "File extension") { |file_extension| @file_extension = file_extension }
      end.parse!
    end

    def find_source_files
      if Dir.exists?(@source_path)
        source = Dir.new(@source_path)
        source.each do |item|
          next if item == '.' or item == '..'

          child_path = [@source_path, item].join('/')

          if Dir.exists?(child_path)
            Dir.new(child_path).each do |child|
              next if child == '.' or child == '..'

              if child =~ /#{@file_extension}/i
                @files << [child_path, child].join('/')
              end
            end
          end
        end
      else
        puts "Can't find SOURCE directory"
      end
    end

    def find_target_directory
      puts "Can't find TARGET directory" unless Dir.exists?(@target_path)
    end

    def copy_files_to_target
      if @files.empty?
        puts "No Files matching files found in #{@source_path}"
        exit
      end

      puts "Copying Pictures:"
      puts "From: #{@source_path}"
      puts "To: #{@target_path}"

      progressbar = ProgressBar.create(
        title: 'Copying pictures',
        total: @files.size,
        format: "%a %b>%i %p%%"
      )

      @files.each do |file_path|
        file_name = file_path.scan(/\/(\w+\.\w{3})/)[0][0]
        file_mtime = File.stat(file_path).mtime.to_s.scan(/\d{4}\-\d{2}\-\d{2}/)[0].split('-')
        file_target_directory = [@target_path, file_mtime].flatten.join('/')

        FileUtils.mkdir_p(file_target_directory)

        if FileUtils.cp(file_path, file_target_directory, preserve: true)
          progressbar.increment
          @copy_log << "#{file_path} -> #{file_target_directory}/#{file_name}"
        end
      end
    end

    def show_copy_log
      @copy_log.each do |line|
        puts line
      end
    end

    def open_target_directory
      system("open #{@target_path}")
    end
end

Photoimport.new.run
