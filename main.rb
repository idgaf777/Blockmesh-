##########################################
# Code  : Blockmesh Bot v.0.1 ruby 3.1.3 #
# Author: Kazuha787 (dune)               #
# Github: https://github.com/kazuha787/  #
# Tg    : https://t.me/Offical_im_kazuha #
##########################################

require 'net/http'
require 'json'
require 'uri'
require 'colorize'
require 'securerandom'
require 'websocket-client-simple'

# Color codes
RED = "\e[31m"
BLUE = "\e[34m"
GREEN = "\e[32m"
YELLOW = "\e[33m"
RESET = "\e[0m"

$proxy_tokens = {}
$email_input = nil
$api_token = nil
$password_input = nil

# Display coder sign
def coder_mark
  puts <<~HEREDOC
    #{GREEN}--------------------------------------
    #{YELLOW}[+]#{RED} BlockMesh Network Bot v0.1.1 #{RESET}
    #{GREEN}--------------------------------------
    #{YELLOW}[+]#{BLUE} https://github.com/Kazuha787/
    #{GREEN}--------------------------------------#{RESET}
  HEREDOC
end

# Get email & password from user
def get_login_credentials
  print "Enter your BlockMesh email: "
  $email_input = gets.chomp
  print "Enter your BlockMesh password: "
  $password_input = gets.chomp
end

def authenticate_direct
  return $api_token if $api_token

  uri = URI("https://api.blockmesh.xyz/api/get_token")
  data = { email: $email_input, password: $password_input }.to_json
  headers = { "Content-Type" => "application/json" }

  begin
    response = Net::HTTP.post(uri, data, headers)
    raise "HTTP Error" unless response.is_a?(Net::HTTPSuccess)
    $api_token = JSON.parse(response.body)['api_token']
    puts "[#{Time.now.strftime('%H:%M:%S')}] Login successful!".green
    $api_token
  rescue => e
    puts "[#{Time.now.strftime('%H:%M:%S')}] Login failed: #{e}".red
    nil
  end
end

def process_direct_connection
  system('clear')
  coder_mark
  get_login_credentials  # Ask for login credentials
  puts "\nRunning Direct Connection...\n\n"

  loop do
    api_token = authenticate_direct
    next unless api_token

    puts "[#{Time.now.strftime('%H:%M:%S')}] Authentication successful!".green
    sleep(2)
  end
end

def main
  system('clear')
  coder_mark
  puts "\n1. Direct Connection\n2. Proxy Connection"
  print "Choose (1/2): "
  choice = gets.chomp.to_i

  if choice == 1
    process_direct_connection
  else
    puts "Proxy mode not yet implemented."
  end
end

main if __FILE__ == $0
