require 'rack'
require 'thrift'
require 'logger'

# Multiprotocol Thrift Rack application
class MultiprotocolThriftRackApp
  def initialize(
        processor,
        protocol_factory_map,
        logger: Logger.new(STDERR, level: Logger::INFO),
        buffered: false)
    @processor = processor
    @protocol_factory_map = protocol_factory_map.freeze
    @logger = logger
    @buffered = buffered
  end

  def call(env)
    request = Rack::Request.new(env)
    return failure_response('Not POST method') unless request.post?
    protocol_factory, content_type = find_protocol_factory(request)
    return failure_response('Unknown Content-Type') if protocol_factory.nil?
    successful_response(request.body, protocol_factory, content_type)
  end

  private

  CONTENT_TYPE_ENV = 'CONTENT_TYPE'

  def failure_response(error_message)
    Rack::Response.new(error_message, 400, {})
  end

  def find_protocol_factory(request)
    content_type = request.get_header(CONTENT_TYPE_ENV)
    @logger.debug("Request Content-Type #{content_type}")
    @protocol_factory_map.each do |(protocol_factory, content_types)|
      next unless content_types.include?(content_type)
      @logger.debug("Match Content-Type for #{protocol_factory}")
      return protocol_factory, content_type
    end
    nil
  end

  def successful_response(request_body, protocol_factory, content_type)
    Rack::Response.new(
      [],
      200,
      Rack::CONTENT_TYPE => content_type,
    ) do |response|
      raw_transport = Thrift::IOStreamTransport.new(request_body, response)
      transport = @buffered ? Thrift::BufferedTransport.new(raw_transport) : raw_transport
      protocol = protocol_factory.get_protocol(transport)
      @processor.process(protocol, protocol)
    end
  end
end
