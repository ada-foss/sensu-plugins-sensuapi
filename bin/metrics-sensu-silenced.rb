#!/ usr/bin/env ruby#
#   Stats
#
# DESCRIPTION:
#    Metrics for the sensu silenced API
# OUTPUT:
#   plain text, metric data, etc
#
# PLATFORMS:
#   Linux, Windows
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: json
#   gem: open-uri
#
# NOTES:
#
# LICENSE:
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'date'
require 'sensu-plugin/metric/cli'
require 'sensuapi.rb'

class Stats < Sensu::Plugin::Metric::CLI::Graphite
  option :protocol,
         description: 'Whether to connect to the sensu API by http/https/ftp/etc.. (Default: http)',
         long: '--protocol protocol',
         default: 'http'

  option :port,
         description: 'The port to reach the Sensu API on (Default: 4567)',
         short: '-p',
         long: '--port port',
         default: 4567

  option :host,
         description: 'The host to check the sensu API of (Default: localhost)',
         short: '-h',
         long: '--host host',
         default: 'localhost'

  option :http_basic_auth_user,
         description: 'A user for basic http authentication if any (Default: nil)',
         long: '--user http_basic_auth_user',
         default: nil

  option :http_basic_auth_password,
         description: 'A password for basic http authentication if any (Default: nil)',
         long: '--pass http_basic_auth_password',
         default: nil

  def graphite_prefix
    'sensu.silenced'
  end

  def run
    if config[:http_basic_auth_user] and config[:http_basic_auth_password]
      auth = [config[:http_basic_auth_user], config[:http_basic_auth_password]]
    else
      auth = nil
    end
    collect_metrics SensuAPI.query config[:host], ['silenced'], http_basic_auth: auth, protocol: config[:protocol], port: config[:port]
  end

  def measure_total dst, silenced_events
    dst << [ 'total', silenced_events.count ]
  end

  def measure_checks dst, silenced_events
    checks = silenced_events.map{ |e| e['check'] }

    checks.uniq.each do |c|
      name = c || 'nil'
      dst << [ "checks.#{name.gsub('.','_')}", checks.count(c) ]
    end
  end

  def measure_subscriptions dst, silenced_events
    subscriptions = silenced_events.map{ |e| e['subscription'] }

    subscriptions.uniq.each do |s|
      name = s || 'nil'
      dst << [ "subscriptions.#{name.gsub('.','_')}", subscriptions.count(s) ]
    end
  end

  #
  # collect metrics
  #
  # silenced_events should be the parsed JSON data from the sensu silenced API
  #
  def collect_metrics(silenced_events)
    mymetrics = [ ]

    measure_total mymetrics, silenced_events
    measure_checks mymetrics, silenced_events
    measure_subscriptions mymetrics, silenced_events

    unix_time_now = Time.now.to_i

    mymetrics.each do |what,how_many|
      output "#{graphite_prefix}.#{what}", how_many, unix_time_now
    end

    ok
  end
end
