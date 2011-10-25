require 'singleton'
require 'yaml'

class Conf
  include Singleton
  attr_reader :config

  VHT = <<EOT
<VirtualHost *:80>
  ServerName $SERVER_NAME
  ProxyPass / http://127.0.0.1:$PORT/
  ProxyPassReverse / http://127.0.0.1:$PORT/
</VirtualHost>
EOT

  DEFAULT = {
    :app_server => nil,
    :app_server_options => nil,
    :port => nil,
    :ruby => 'default',
    :app_path => '/var/sites/$APP_NAME/current',
    :server_name => '$APP_NAME.local',
    :vhost_template => VHT,
    :vhost_path => '/etc/apache2/sites-available',
    :overwrite_files => false,
    :create_vhost => true,
    :enable_site => false,
    :reload_apache => false
  }

  def initialize
    load
  end

  def load
    @file = "#{Dir.home}/.magicmonkey.yml"
    if File.exist?(@file)
      @config = YAML.load_file(@file)
    else
      @config = {:default => DEFAULT}
      self.save
    end
  end

  def save
    File.open(@file, 'w') { |f| f.write(@config.to_yaml) }
    self.load
  end

  def self.[](key)
    Conf.instance.config[key.to_sym]
  end

  def self.[]=(key, value)
    Conf.instance.config[key.to_sym] = value
  end

  def self.delete(key)
    Conf.instance.config.delete(key.to_sym) if key.to_sym != :default
  end

  def self.save
    Conf.instance.save
  end

  def self.applications
    Conf.instance.config.keys.select{|k| ![:default, :uid].include?(k)}
  end

  def self.ports
    p = []
    Conf.instance.config.each do |k,v|
      p << v[:port] if ![:default, :uid].include?(k) && v[:port]
    end
    return p
  end

  def self.next_port(range = (3000..5000))
    return (range.to_a - self.ports).first
  end

end