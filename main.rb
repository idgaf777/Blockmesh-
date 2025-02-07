##########################################
# Code  : Blockmesh Bot v.0.1 ruby 3.1.3 #
# Autor : Kazuha #
# Github: https://github.com/Kazuha787/      #
# Tg    : https://t.me/Offical_Im_kazuha      #
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
UL = "\e[4m"
AM = "\e[91m"
RESET = "\e[0m"

# Display coder sign
def coder_mark
  puts <<~HEREDOC
    ▗▖ ▗▖ ▗▄▖ ▗▄▄▄▄▖▗▖ ▗▖▗▖ ▗▖ ▗▄▖
    ▐▌▗▞▘▐▌ ▐▌   ▗▞▘▐▌ ▐▌▐▌ ▐▌▐▌ ▐▌
    ▐▛▚▖ ▐▛▀▜▌ ▗▞▘  ▐▌ ▐▌▐▛▀▜▌▐▛▀▜▌
    ▐▌ ▐▌▐▌ ▐▌▐▙▄▄▄▖▝▚▄▞▘▐▌ ▐▌▐▌ ▐▌
    #{GREEN}--------------------------------------
    #{YELLOW}[+]#{AM} BlockMesh Network Bot #{RESET}#{UL}v0.1.1#{RESET}
    #{GREEN}--------------------------------------
    #{YELLOW}[+]#{BLUE} https://github.com/cmalf/
    #{GREEN}--------------------------------------#{RESET}
  HEREDOC
end

$proxy_tokens = {}
$email_input = nil
$api_token = nil
$password_input = nil

# adding handle_proxy_error
def handle_proxy_error(proxy, error_message)
  if error_message.include?('end of file reached')
    proxy_file = 'proxy.txt'
    error_file = 'proxy_error.txt'
    
    # Read current proxies
    proxies = File.exist?(proxy_file) ? File.readlines(proxy_file).map(&:chomp) : []
    
    # Remove the failed proxy from the list
    proxies.delete(proxy)
    
    # Write remaining proxies back to proxy.txt
    File.write(proxy_file, proxies.join("\n"))
    
    # Append failed proxy to proxy_error.txt
    File.open(error_file, 'a') do |f|
      f.puts "#{proxy} | Error: #{error_message} | #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    end
    
    puts "[#{Time.now.strftime('%H:%M:%S')}] Proxy removed due to EOF error: #{proxy}".red
    return true
  end
  false
end

# Speed and metrics generation methods
def generate_download_speed
  rand(0.0..10.0).round(16)
end

def generate_upload_speed
  rand(0.0..5.0).round(16)
end

def generate_latency
  rand(20.0..300.0).round(16)
end

def generate_response_time
  rand(200.0..600.0).round(1)
end

def get_ip_info(ip_address)
  begin
    uri = URI("https://ipwhois.app/json/#{ip_address}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(uri)
    response = http.request(request)
    raise "HTTP Error" unless response.is_a?(Net::HTTPSuccess)
    JSON.parse(response.body)
  rescue => e
    puts "Failed to get IP info: #{e}".red
    nil
  end
end

def connect_websocket(email, api_token)
  begin
    ws = WebSocket::Client::Simple.connect("wss://ws.blockmesh.xyz/ws?email=#{email}&api_token=#{api_token}")
    puts "[#{Time.now.strftime('%H:%M:%S')}]" + " Connected to WebSocket".yellow
    ws.close
  rescue => e
    puts "[#{Time.now.strftime('%H:%M:%S')}]" + " WebSocket connection OK".yellow
  end
end

def submit_bandwidth(email, api_token, ip_info, proxy_config = nil)
  return unless ip_info

  payload = {
    email: email,
    api_token: api_token,
    download_speed: generate_download_speed,
    upload_speed: generate_upload_speed,
    latency: generate_latency,
    city: ip_info['city'] || 'Unknown',
    country: ip_info['country_code'] || 'XX',
    ip: ip_info['ip'] || '',
    asn: ip_info['asn']&.gsub('AS', '') || '0',
    colo: 'Unknown'
  }.to_json

  begin
    uri = URI("https://app.blockmesh.xyz/api/submit_bandwidth")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    if proxy_config
      proxy_uri = URI(proxy_config[:http])
      http.proxy_from_env = false
      http.proxy_address = proxy_uri.host
      http.proxy_port = proxy_uri.port
      http.proxy_user = proxy_uri.user if proxy_uri.user
      http.proxy_pass = proxy_uri.password if proxy_uri.password
    end

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = payload
    
    response = http.request(request)
    raise "HTTP Error" unless response.is_a?(Net::HTTPSuccess)
  rescue => e
  end
end

def get_and_submit_task(email, api_token, ip_info, proxy_config)
  return unless ip_info

  begin
    uri = URI("https://app.blockmesh.xyz/api/get_task")
    response = Net::HTTP.post(uri, { email: email, api_token: api_token }.to_json, { 'Content-Type' => 'application/json' })
    raise "HTTP Error" unless response.is_a?(Net::HTTPSuccess)
    task_data = JSON.parse(response.body)

    if task_data.nil? || !task_data.key?('id')
      puts "[#{Time.now.strftime('%H:%M:%S')}]" + " No Task Available".yellow
      return
    end

    task_id = task_data['id']
    puts "[#{Time.now.strftime('%H:%M:%S')}]" + " Got task: #{task_id}".green
    sleep(rand(60..120))

    submit_url = "https://app.blockmesh.xyz/api/submit_task"
    params = {
      email: email,
      api_token: api_token,
      task_id: task_id,
      response_code: 200,
      country: ip_info['country_code'] || 'XX',
      ip: ip_info['ip'] || '',
      asn: ip_info['asn']&.gsub('AS', '') || '0',
      colo: 'Unknown',
      response_time: generate_response_time
    }

    response = Net::HTTP.post(URI(submit_url), params.to_json, { 'Content-Type' => 'application/json' })
    raise "HTTP Error" unless response.is_a?(Net::HTTPSuccess)
  rescue => e
  end
end

def save_credentials(email, api_token, password)
  File.write('data.json', { email: email, api_token: api_token, password: password }.to_json)
end

def load_credentials
  return unless File.exist?('data.json')
  JSON.parse(File.read('data.json'))
end

def format_proxy(proxy_string)
  proxy_type, address = proxy_string.split("://")

  if address.include?("@")
    credentials, host_port = address.split("@")
    username, password = credentials.split(":")
    host, port = host_port.split(":")
    {
      http: "#{proxy_type}://#{username}:#{password}@#{host}:#{port}",
      https: "#{proxy_type}://#{username}:#{password}@#{host}:#{port}"
    }
  else
    host, port = address.split(":")
    {
      http: "#{proxy_type}://#{host}:#{port}",
      https: "#{proxy_type}://#{host}:#{port}"
    }
  end
end

# Modified authenticate method to include error handling
def authenticate(proxy)
  if $proxy_tokens.key?(proxy)
    return $proxy_tokens[proxy]
  end

  proxy_config = format_proxy(proxy)
  proxy_uri = URI(proxy_config[:http])
  ip_info = get_ip_info(proxy_uri.host)

  login_endpoint = "https://api.blockmesh.xyz/api/get_token"
  login_headers = {
    "accept" => "*/*",
    "content-type" => "application/json",
    "origin" => "https://app.blockmesh.xyz",
    "user-agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
  }

  login_data = { email: $email_input, password: $password_input }

  begin
    uri = URI(login_endpoint)
    http = Net::HTTP.new(uri.host, uri.port, proxy_uri.host, proxy_uri.port, proxy_uri.user, proxy_uri.password)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    request = Net
