namespace :custom do
  task :show_checklist do
    puts

    GIST_URL = 'https://gist.githubusercontent.com/binary-koan/e865e3b3865360a3ea0c2369141f688d/raw/46dfad8bba922d7fa04119d8a3f2efb2cbd34730/DEPLOYMENT_CHECKLIST.txt'

    Net::HTTP.get(URI.parse(GIST_URL)).each_line do |line|
      puts line.
        gsub(/#.+/) { |s| "\e[31m#{s}\e[0m" }.
        gsub(/`([^`]+)`/) { "\e[33m#{$1}\e[0m" }
    end
  end
end
