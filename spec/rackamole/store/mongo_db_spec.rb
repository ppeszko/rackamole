require File.join(File.dirname(__FILE__), %w[.. .. spec_helper])

describe Rackamole::Store::MongoDb do
  
  describe "#mole" do
    before( :all ) do
      @store = Rackamole::Store::MongoDb.new( 
        :host     => 'localhost', 
        :port     => 27017, 
        :database => 'test_mole_mdb',
        :logger   => Rackamole::Logger.new( :file_name => $stdout, :log_level => 'info' ) )
      @db = @store.database
    end
    
    before( :each ) do
      @store.send( :reset! )
      
      @args = OrderedHash.new
      @args[:type]         = Rackamole.feature
      @args[:app_name]     = "Test app"
      @args[:environment]  = :test
      @args[:perf_issue]   = false
      @args[:ip]           = "1.1.1.1"
      @args[:browser]      = "Ibrowse"
      @args[:user_id]      = 100
      @args[:user_name]    = "Fernand"
      @args[:request_time] = 1.0
      @args[:url]          = "http://test_me/"
      @args[:path]         = "/fred"
      @args[:method]       = 'GET'
      @args[:params]       = { :blee => "duh".to_json }
      @args[:session]      = { :fred => 10.to_json }
    end
    
    it "should mole a context based feature correctly" do
      @store.mole( @args )      
      @store.features.count.should == 1
      @store.logs.count.should     == 1
      
      feature = @store.features.find_one()
      feature.should_not be_nil
      feature['app'].should     == 'Test app'
      feature['env'].should     == 'test'
      feature['ctx'].should     == '/fred'
     
      log = @store.logs.find_one()
      log.should_not        be_nil
      log['typ'].should == Rackamole.feature  
      log['fid'].should_not be_nil
      log['par'].should     == { 'blee' => 'duh'.to_json }
      log['ip'].should      == '1.1.1.1'
      log['bro'].should     == 'Ibrowse'
      log['url'].should     == 'http://test_me/'
      log['met'].should     == 'GET'
      log['ses'].should     == { 'fred' => '10' }
      log['una'].should     == 'Fernand'
      log['uid'].should     == 100
      log['rti'].should     == 1.0
      log['did'].should_not be_nil
      log['tid'].should_not be_nil    

      @store.features.find_one( Mongo::ObjectID.from_string( log['fid'] ) )['app'].should  == 'Test app'                     
    end
    
    it "should mole a rails feature correctly" do
      @args[:path]       = '/fred/blee/duh'
      @args[:route_info] = { :controller => 'fred', :action => 'blee', :id => 'duh' }
      @store.mole( @args )
      
      @store.features.count.should == 1
      @store.logs.count.should     == 1
      
      feature = @store.features.find_one()
      feature.should_not be_nil      
      feature['ctl'].should == 'fred'
      feature['act'].should == 'blee'
      feature['ctx'].should be_nil 
      
      log = @store.logs.find_one()      
      log.should_not be_nil
      log['typ'].should == Rackamole.feature
      log['pat'].should_not be_nil
    end
    
    it "should reuse an existing feature" do
      @store.mole( @args )
      @store.mole( @args )

      @store.features.count.should == 1
      @store.logs.count.should     == 2
    end
  
    it "should mole perf correctly" do
      @args[:type]         = Rackamole.perf
      @store.mole( @args )
  
      @store.features.count.should == 1
      @store.logs.count.should     == 1
      
      feature = @store.features.find_one()
      feature.should_not be_nil      
  
      log = @store.logs.find_one()
      log.should_not be_nil
      log['typ'].should == Rackamole.perf
    end
    
    it 'should mole an exception correctly' do
      @args[:type]  = Rackamole.fault
      @args[:stack] = ['fred']
      @args[:fault] = "Oh Snap!"
      @store.mole( @args )
  
      @store.features.count.should == 1
      @store.logs.count.should     == 1
      
      feature = @store.features.find_one()
      feature.should_not be_nil
  
      log = @store.logs.find_one()
      log.should_not be_nil      
      log['typ'].should == Rackamole.fault
      log['sta'].should == ['fred']
      log['msg'].should == 'Oh Snap!'      
    end
    
    it 'should keep count an similar exceptions or perf issues' do
      pending "NYI"
    end
  end
  
end