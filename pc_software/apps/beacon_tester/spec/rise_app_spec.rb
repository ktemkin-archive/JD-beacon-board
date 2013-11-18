
require 'bundler/setup'
require_relative '../rise_app'
require 'rack/test'


describe RiseApp do
  include Rack::Test::Methods

  def app
    RiseApp
  end

  #
  # Quick helper that retrieves the file from the local assets folder.
  #
  def asset(name)
    File::expand_path("./assets/#{name}", File::dirname(__FILE__))
  end


  describe 'post /backend/validate_bitfile' do
    subject { '/backend/validate_bitfile' }
    
    context "when the provided bit-file exists" do
      it "returns a valid value of false" do
        post subject, :path => '/path/that/does/not/exist'
        JSON::load(last_response.body).should == {'valid' => false}
      end
    end

    context "when the provided bit-file does not exist" do
      it "returns a response with valid set to true" do
        post subject, :path => asset('valid.bit')
        JSON::load(last_response.body).should == {'valid' => true}
      end
    end


  end

end
