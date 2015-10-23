require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Trocla" do

  before(:each) do
    expect_any_instance_of(Trocla).to receive(:read_config).and_return(test_config)
    @trocla = Trocla.new
  end

  describe "password" do
    it "should generate random passwords by default" do
      @trocla.password('random1','plain').should_not eql(@trocla.password('random2','plain'))
    end

    it "should generate passwords of length #{default_config['options']['length']}" do
      @trocla.password('random1','plain').length.should eql(default_config['options']['length'])
    end

    Trocla::Formats.all.each do |format|
      describe "#{format} password format" do
        it "should return a password hashed in the #{format} format" do
          @trocla.password('some_test',format,format_options[format]).should_not be_empty
        end

        it "should return the same hashed for the #{format} format on multiple invocations" do
          (round1=@trocla.password('some_test',format,format_options[format])).should_not be_empty
          @trocla.password('some_test',format,format_options[format]).should eql(round1)
        end

        it "should also store the plain password by default" do
          pwd = @trocla.password('some_test','plain')
          pwd.should_not be_empty
          pwd.length.should eql(16)
        end
      end
    end

    Trocla::Formats.all.reject{|f| f == 'plain' }.each do |format|
      it "should raise an exception if not a random password is asked but plain password is not present for format #{format}" do
        lambda{ @trocla.password('not_random',format, 'random' => false) }.should raise_error /Password must be present as plaintext/
      end
    end

    describe 'with profiles' do
      it 'should raise an exception on unknown profile' do
        lambda{ @trocla.password('no profile known','plain',
          'profiles' => 'unknown_profile') }.should raise_error /No such profile unknown_profile defined/
      end

      it 'should take a profile and merge its options' do
        pwd = @trocla.password('some_test','plain', 'profiles' => 'rootpw')
        pwd.should_not be_empty
        pwd.length.should eql(32)
        pwd.should_not =~ /[={}\[\]\?%\*()&!]+/
      end

      it 'should possible to combine profiles but first profile wins' do
        pwd = @trocla.password('some_test','plain', 'profiles' => ['rootpw','login'])
        pwd.should_not be_empty
        pwd.length.should eql(32)
        pwd.should_not =~ /[={}\[\]\?%\*()&!]+/
      end
      it 'should possible to combine profiles but first profile wins 2' do
        pwd = @trocla.password('some_test','plain', 'profiles' => ['login','mysql'])
        pwd.should_not be_empty
        pwd.length.should eql(16)
        pwd.should_not =~ /[={}\[\]\?%\*()&!]+/
      end
      it 'should possible to combine profiles but first profile wins 3' do
        pwd = @trocla.password('some_test','plain', 'profiles' => ['mysql','login'])
        pwd.should_not be_empty
        pwd.length.should eql(32)
        pwd.should =~ /[={}\[\]\?%\*()&!\,\+\.]+/
      end
    end
  end

  describe "set_password" do
    it "should reset hashed passwords on a new plain password" do
      @trocla.password('set_test','mysql').should_not be_empty
      @trocla.get_password('set_test','mysql').should_not be_nil
      (old_plain=@trocla.password('set_test','mysql')).should_not be_empty

      @trocla.set_password('set_test','plain','foobar').should_not eql(old_plain)
      @trocla.get_password('set_test','mysql').should be_nil
    end

    it "should otherwise only update the hash" do
      (mysql = @trocla.password('set_test2','mysql')).should_not be_empty
      (md5crypt = @trocla.password('set_test2','md5crypt')).should_not be_empty
      (plain = @trocla.get_password('set_test2','plain')).should_not be_empty

      (new_mysql = @trocla.set_password('set_test2','mysql','foo')).should_not eql(mysql)
      @trocla.get_password('set_test2','mysql').should eql(new_mysql)
      @trocla.get_password('set_test2','md5crypt').should eql(md5crypt)
      @trocla.get_password('set_test2','plain').should eql(plain)
    end
  end

  describe "reset_password" do
    it "should reset a password" do
      plain1 = @trocla.password('reset_pwd','plain')
      plain2 = @trocla.reset_password('reset_pwd','plain')

      plain1.should_not eql(plain2)
    end

    it "should not reset other formats" do
      (mysql = @trocla.password('reset_pwd2','mysql')).should_not be_empty
      (md5crypt1 = @trocla.password('reset_pwd2','md5crypt')).should_not be_empty

      (md5crypt2 = @trocla.reset_password('reset_pwd2','md5crypt')).should_not be_empty
      md5crypt2.should_not eql(md5crypt1)

      @trocla.get_password('reset_pwd2','mysql').should eql(mysql)
    end
  end

  describe "delete_password" do
    it "should delete all passwords if no format is given" do
      @trocla.password('delete_test1','mysql').should_not be_nil
      @trocla.get_password('delete_test1','plain').should_not be_nil

      @trocla.delete_password('delete_test1')
      @trocla.get_password('delete_test1','plain').should be_nil
      @trocla.get_password('delete_test1','mysql').should be_nil
    end

    it "should delete only a given format" do
      @trocla.password('delete_test2','mysql').should_not be_nil
      @trocla.get_password('delete_test2','plain').should_not be_nil

      @trocla.delete_password('delete_test2','plain')
      @trocla.get_password('delete_test2','plain').should be_nil
      @trocla.get_password('delete_test2','mysql').should_not be_nil
    end

    it "should delete only a given non-plain format" do
      @trocla.password('delete_test3','mysql').should_not be_nil
      @trocla.get_password('delete_test3','plain').should_not be_nil

      @trocla.delete_password('delete_test3','mysql')
      @trocla.get_password('delete_test3','mysql').should be_nil
      @trocla.get_password('delete_test3','plain').should_not be_nil
    end
  end

  def format_options
    @format_options ||= Hash.new({}).merge({
      'pgsql' => { 'username' => 'test' },
      'x509'  => { 'CN' => 'test' },
    })
  end

end

describe "VERSION" do
  it "should return a version" do
    Trocla::VERSION::STRING.should_not be_empty
  end
end
