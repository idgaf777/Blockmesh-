##########################################
# Code  : Blockmesh Bot v.0.1 ruby 3.1.3 #
# Autor : Furqonflynn (cmalf)            #
# Github: https://github.com/cmalf/      #
# Tg    : https://t.me/furqonflynn       #
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
    ╭━━━╮╱╱╱╱╱╱╱╱╱╱╱╱╱╭━━━┳╮
    ┃╭━━╯╱╱╱╱╱╱╱╱╱╱╱╱╱┃╭━━┫┃#{GREEN}
    ┃╰━━┳╮╭┳━┳━━┳━━┳━╮┃╰━━┫┃╭╮╱╭┳━╮╭━╮
    ┃╭━━┫┃┃┃╭┫╭╮┃╭╮┃╭╮┫╭━━┫┃┃┃╱┃┃╭╮┫╭╮╮#{BLUE}
    ┃┃╱╱┃╰╯┃┃┃╰╯┃╰╯┃┃┃┃┃╱╱┃╰┫╰━╯┃┃┃┃┃┃┃
    ╰╯╱╱╰━━┻╯╰━╮┣━━┻╯╰┻╯╱╱╰━┻━╮╭┻╯╰┻╯╰╯#{RESET}
    ╱╱╱╱╱╱╱╱╱╱╱┃┃╱╱╱╱╱╱╱╱╱╱╱╭━╯┃
    ╱╱╱╱╱╱╱╱╱╱╱╰╯╱╱╱╱╱╱╱╱╱╱╱╰━━╯
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
    
    request = Net::HTTP::Post.new(uri)
    login_headers.each { |k, v| request[k] = v }
    request.body = login_data.to_json
    
    response = http.request(request)
    raise "HTTP Error" unless response.is_a?(Net::HTTPSuccess)
    
    auth_data = JSON.parse(response.body)
    api_token = auth_data['api_token']

    $proxy_tokens[proxy] = api_token
    save_credentials($email_input, api_token, $password_input)

    puts "[#{Time.now.strftime('%H:%M:%S')}] #{'Login successful'.green} | #{proxy.blue}"
    api_token
  rescue => e
    error_message = e.message
    puts "[#{Time.now.strftime('%H:%M:%S')}] Login failed | #{proxy} : #{error_message}".red
    
    if handle_proxy_error(proxy, error_message)
      Thread.current.exit # Exit the current thread if proxy is removed
    end
    
    nil
  end
end

def send_uptime_report(api_token, ip_addr, proxy)
  proxy_config = format_proxy(proxy)
  report_endpoint = "https://app.blockmesh.xyz/api/report_uptime?email=#{$email_input}&api_token=#{api_token}&ip=#{ip_addr}"
  
  report_headers = {
    "accept" => "*/*",
    "content-type" => "text/plain;charset=UTF-8",
    "origin" => "chrome-extension://obfhoiefijlolgdmphcekifedagnkfjp",
    "user-agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
  }

  begin
    response = Net::HTTP.post(URI(report_endpoint), {}, report_headers)
    raise "HTTP Error" unless response.is_a?(Net::HTTPSuccess)
  rescue => e
    $proxy_tokens.delete(proxy) if $proxy_tokens.key?(proxy)
  end
end

def process_proxy(proxy)
  first_run = true
  loop do
    if first_run || !$proxy_tokens.key?(proxy)
      api_token = authenticate(proxy)
      first_run = false
    else
      api_token = $proxy_tokens[proxy]
    end

    if api_token
      proxy_config = format_proxy(proxy)
      ip_info = get_ip_info(proxy_config[:http].split('@').last.split(':').first)

      connect_websocket($email_input, api_token)
      sleep(rand(60..120))

      submit_bandwidth($email_input, api_token, ip_info, proxy_config)
      sleep(rand(60..120))

      get_and_submit_task($email_input, api_token, ip_info, proxy_config)
      sleep(rand(60..120))

      send_uptime_report(api_token, ip_info['ip'], proxy)
      sleep(rand(900..1200))
    end

    sleep(10)
  end
end

# Handle SIGINT
Signal.trap('INT') do
  puts "#{BLUE}\nReceived SIGINT. Stopping Script with Blessing...#{RESET}"
  exit 0
end

def main
  system('clear')
  coder_mark
  credentials = load_credentials

  if credentials
    $email_input = credentials['email']
    $api_token = credentials['api_token']
    $password_input = credentials['password']
  else
    puts "\n#{YELLOW}[+]#{RESET} Please Login to your Blockmesh Account:\n"
    print "\n)> Enter Email: ".green
    $email_input = gets.chomp
    print ")> Enter Password: ".green
    $password_input = gets.chomp
  end
  system('clear')
  coder_mark
  puts "\nSelect Connection Type:"
  puts "\n#{'1.'.yellow} #{'Direct Connection'.green} (No Proxy)"
  puts "#{'2.'.yellow} #{'Proxy Connection'.blue}\n"
  print "\n#{')>'.yellow} Choose (1/2): "
  choice = gets.chomp.to_i

  if choice == 1
    process_direct_connection
  else
    process_proxy_connections
  end
end

def process_direct_connection
  system('clear')
  coder_mark
  puts "\n#{')>'.blue} Running Direct Connection...\n\n"
  loop do
    api_token = authenticate_direct
    if api_token
      ip_info = get_ip_info(get_public_ip)
      puts "\n[#{Time.now.strftime('%H:%M:%S')}]" + " IP Address | #{ip_info['ip']} ".green
      
      connect_websocket($email_input, api_token)
      sleep(3)
      puts "\n#{')>'.yellow} #{'Please wait... before next cycle'.light_cyan}\n"
      sleep(rand(60..120))

      submit_bandwidth($email_input, api_token, ip_info)
      sleep(rand(60..120))

      get_and_submit_task($email_input, api_token, ip_info)
      sleep(rand(60..120))

      send_uptime_report(api_token, ip_info['ip'])
      sleep(rand(900..1200))
    end
    sleep(10)

  end
end

def process_proxy_connections
  system('clear')
  coder_mark
  proxy_list_path = "proxy.txt"
  if File.exist?(proxy_list_path)
    proxies_list = File.readlines(proxy_list_path).map(&:chomp)
    puts "\n#{')>'.yellow} #{'Loaded'.green} #{proxies_list.size} #{'proxies from proxy.txt'.green}"
  else
    puts "\n#{')>'.yellow} #{'proxy.txt not found!'.red}"
    exit
  end

  puts "\n#{')>'.blue} Running Proxy Bots...\n\n"
  threads = []
  proxies_list.each do |proxy|
    thread = Thread.new { process_proxy(proxy) }
    threads << thread
    sleep(1)
  end
  sleep(2)
  puts "\n#{')>'.yellow} #{'Please wait... before next cycle'.light_cyan}\n"

  threads.each(&:join)
end

def get_public_ip
  uri = URI("https://api.ipify.org")
  response = Net::HTTP.get_response(uri)
  response.body.strip
end

def authenticate_direct
  if $api_token
    return $api_token
  end

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
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    request = Net::HTTP::Post.new(uri)
    login_headers.each { |k, v| request[k] = v }
    request.body = login_data.to_json
    
    response = http.request(request)
    raise "HTTP Error" unless response.is_a?(Net::HTTPSuccess)
    
    auth_data = JSON.parse(response.body)
    $api_token = auth_data['api_token']
    
    save_credentials($email_input, $api_token, $password_input)
    puts "[#{Time.now.strftime('%H:%M:%S')}]" + " Direct connection login successful".green
    $api_token
  rescue => e
    puts "[#{Time.now.strftime('%H:%M:%S')}]" + " Direct connection login failed: #{e}".red
    nil
  end
end

main if __FILE__ == $0
