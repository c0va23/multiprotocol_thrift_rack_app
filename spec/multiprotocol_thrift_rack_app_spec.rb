require 'spec_helper'

RSpec.describe MultiprotocolThriftRackApp do
  describe '#call' do
    subject(:response) { rack_app.call(request_env) }

    let(:processor) { instance_double('Thrift::Processor') }

    let(:binary_protocol_factory) do
      instance_double('Thrift::BinaryProtocolFactory')
    end
    let(:json_protocol_factory) do
      instance_double('Thrift::JsonProtocolFactory')
    end

    let(:protocol_factory_map) do
      {
        binary_protocol_factory => ['application/x-thrift'],
        json_protocol_factory => ['application/json'],
      }
    end

    let(:buffered) { false }
    let(:rack_app) do
      described_class.new(
        processor,
        protocol_factory_map,
        buffered: buffered,
      )
    end

    let(:request_method) { Rack::POST }
    let(:request_body) { StringIO.new('custom request body') }
    let(:request_env) do
      {
        Rack::REQUEST_METHOD => request_method,
        'CONTENT_TYPE' => content_type,
        Rack::RACK_INPUT => request_body,
      }
    end

    context 'when request with custom content type' do
      let(:content_type) { 'text/palin' }

      it 'return response with status 400' do
        expect(response.status).to eq 400
      end

      it 'return "Unknown Content-Type"' do
        expect(response.body).to eq ['Unknown Content-Type']
      end
    end

    shared_examples 'process POST request' do
      shared_examples 'success process' do
        it 'return response with status 200' do
          expect(response.status).to eq 200
        end

        it 'return valid content type header' do
          expect(response.headers[Rack::CONTENT_TYPE]).to eq content_type
        end
      end

      context 'when reqeust with POST method' do
        let(:request_method) { Rack::POST }

        before do
          transport = instance_double('Transport')
          protocol = instance_double('Thrift::BaseProtocol')

          allow(Thrift::IOStreamTransport).to receive(:new)
            .with(request_body, kind_of(Rack::Response))
            .and_return(transport)
          allow(protocol_factory).to receive(:get_protocol)
            .with(transport)
            .and_return(protocol)
          allow(processor).to receive(:process).with(protocol, protocol)
        end

        include_examples 'success process'
      end

      context 'when reqeust with POST method and buffered' do
        let(:buffered) { true }
        let(:request_method) { Rack::POST }

        before do
          raw_transport = instance_double('Transport')
          transport = instance_double('BufferedTransport')
          protocol = instance_double('Thrift::BaseProtocol')

          allow(Thrift::IOStreamTransport).to receive(:new)
            .with(request_body, kind_of(Rack::Response))
            .and_return(raw_transport)
          allow(Thrift::BufferedTransport).to receive(:new)
            .with(raw_transport)
            .and_return(transport)
          allow(protocol_factory).to receive(:get_protocol)
            .with(transport)
            .and_return(protocol)
          allow(processor).to receive(:process).with(protocol, protocol)
        end

        include_examples 'success process'
      end

      context 'when request with GET method' do
        let(:request_method) { Rack::GET }

        it 'return response with status 400' do
          expect(response.status).to eq 400
        end

        it 'return "Not POST method" in body' do
          expect(response.body).to eq ['Not POST method']
        end
      end
    end

    context 'when request with first content type' do
      let(:content_type) { 'application/x-thrift' }
      let(:protocol_factory) { binary_protocol_factory }

      include_examples 'process POST request'
    end

    context 'when request with second content type' do
      let(:content_type) { 'application/json' }
      let(:protocol_factory) { json_protocol_factory }

      include_examples 'process POST request'
    end
  end
end
