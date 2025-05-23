require 'spec_helper'
require 'shared_examples_for_access_token_agent'

describe AccessTokenAgent::Connector do
  let(:host) { 'http://localhost:8012' }
  let(:options) do
    {
      host: host,
      client_id: 'test_app',
      client_secret: 'something secret'
    }
  end
  let(:agent) { described_class.new(**options) }

  describe '.token' do
    subject { agent.token }

    context 'when an access_token is known for the credentials' do
      let(:known_token) do
        AccessTokenAgent::Token.new('expires_in' => 7200,
                                    'token_type' => 'bearer',
                                    'access_token' => 'xy')
      end

      before { agent.instance_variable_set(:@known_token, known_token) }

      context 'and it is valid' do
        before { allow(known_token).to receive(:valid?).and_return(true) }

        it 'returns the known access_token' do
          expect(subject).to eq known_token.value
        end

        it 'does not call auth project' do
          expect(Net::HTTP).not_to receive(:start)
          subject
        end
      end

      context 'and it is invalid', :vcr do
        before { allow(known_token).to receive(:valid?).and_return(false) }

        context 'and the credentials are valid' do
          it 'does not return the known token value' do
            expect(subject).not_to eq known_token.value
          end

          it 'returns a new token value' do
            expect(subject).to eq 'fa9724f775c8949bb2d680c7cf11f4d40b92879' \
                                  'f16987c0929a78e7a3ce893f4'
          end

          it 'calls auth project' do
            expect(Net::HTTP).to receive(:start).and_call_original
            subject
          end
        end

        it_behaves_like 'with invalid credentials'
      end
    end

    context 'when no access_token is known for the credentials', :vcr do
      context 'and the credentials are valid' do
        it 'returns a new token value' do
          expect(subject).to eq 'b9143de417609e7302bd84fa13034c7557c1eb69a' \
                                '7aad7362b033c3b4002a858'
        end

        it 'calls auth project' do
          expect(Net::HTTP).to receive(:start).and_call_original
          subject
        end
      end

      it_behaves_like 'with invalid credentials'
    end
  end

  describe '.http_auth_header' do
    let(:token) { 'mySecretToken' }
    subject { agent.http_auth_header }

    before do
      allow(agent).to receive(:token).and_return(token)
    end

    it 'returns a hash with the Authorization header' do
      expect(subject.keys.size).to eql 1
      expect(subject.keys.first).to eql 'Authorization'
    end

    it 'uses the token as Bearer token' do
      expect(subject['Authorization']).to eql "Bearer #{token}"
    end
  end

  describe '.fetch_token_hash', :vcr do
    subject { agent.send(:fetch_token_hash) }

    context 'when credentials are valid' do
      it 'returns a Hash containing the access_token' do
        expect(subject['access_token']).to eq(
          'eeb81b0efe8d0792e8e41cd9eab6df75d68f48bbd7b600f332d9bd154981ec51'
        )
      end

      it 'returns a Hash containing expires_in' do
        expect(subject['expires_in']).to eq 7200
      end
    end

    it_behaves_like 'with invalid credentials'

    context 'when request is not successful' do
      it 'throws an Error' do
        expect { subject }.to raise_error AccessTokenAgent::Error
      end
    end

    context 'when the connection fails' do
      before do
        allow(Net::HTTP).to receive(:start).and_raise(Errno::ECONNREFUSED)
      end

      it 'throws a ConnectionError' do
        expect { subject }.to raise_error AccessTokenAgent::ConnectionError
      end
    end
  end

  describe '.perform_request' do
    let(:request_mock) { double(Net::HTTP::Post).as_null_object }
    subject { agent.send(:perform_request) }

    before do
      allow(Net::HTTP).to receive(:start)
      allow(Net::HTTP::Post).to receive(:new).and_return(request_mock)
    end

    it 'calls the expected URL' do
      expected_uri = URI("#{host}/oauth/token")
      expect(Net::HTTP::Post).to receive(:new).with(expected_uri)
      subject
    end

    it 'specifies the correct grant type' do
      expect(request_mock)
        .to receive(:form_data=)
        .with(hash_including('grant_type' => 'client_credentials'))
      subject
    end

    it 'does not pass any scopes' do
      expect(request_mock).to receive(:form_data=) do |form_hash|
        expect(form_hash.keys).not_to include('scope')
      end

      subject
    end

    context 'custom access_token_path' do
      let(:custom_path) { '/custom_path/to/token' }
      before do
        options.merge!(access_token_path: custom_path)
      end

      it 'calls the expected URL' do
        expected_uri = URI("#{host}#{custom_path}")
        expect(Net::HTTP::Post).to receive(:new).with(expected_uri)
        subject
      end
    end

    context 'when using scopes' do
      let(:scopes) { %w[scope-a scope-b] }
      let(:options) do
        {
          host: host,
          client_id: 'test_app',
          client_secret: 'something secret',
          scopes: scopes
        }
      end

      it 'passes expected scopes' do
        expect(request_mock)
          .to receive(:form_data=)
          .with(hash_including('scope' => 'scope-a scope-b'))

        subject
      end
    end
  end
end
