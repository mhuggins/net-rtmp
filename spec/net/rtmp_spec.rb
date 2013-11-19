require 'spec_helper'

describe Net::RTMP do
  subject { Net::RTMP.new(uri, options) }

  before { TCPSocket.stub(:new).and_return(mock_socket) }

  let(:uri) { URI.parse('http://www.example.com:2099') }
  let(:options) { {} }

  describe '.new' do
    describe 'when handshake fails' do
      before { subject.stub(:handshake).and_return(false) }

      it 'should raise HandshakeError' do
        expect { subject }.to raise_error Net::RTMP::HandshakeError
      end
    end

    describe 'when handshake succeeds' do
      before { subject.stub(:handshake).and_return(true) }

      it 'should not raise any errors' do
        expect { subject }.to_not raise_error
      end

      it 'should be connected' do
        expect { subject }.to be_connected
      end

      it 'should not be closed' do
        expect { subject }.to_not be_closed
      end
    end
  end

  describe '#uri' do
    let(:uri) { URI.parse('https://www.example.com:2099/some/path') }
    its(:uri) { should eq uri }
  end

  describe '#version' do
    describe 'included in options hash' do
      let(:options) { { :version => 0 } }
      its(:version) { should eq 0 }
    end

    describe 'excluded from options hash' do
      its(:version) { should eq 3 }
    end
  end

  describe '#disconnect' do
    it 'should not be connected' do
      expect { subject }.to_not be_connected
    end

    it 'should be closed' do
      expect { subject }.to be_closed
    end
  end

  def mock_socket(*responses)
    double('TCPSocket').tap do |socket|
      socket.stub(:setsockopt)
      socket.stub(:read).and_return(*responses) if responses.any?
    end
  end
end
