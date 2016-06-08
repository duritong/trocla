require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Trocla" do

  before(:each) do
    expect_any_instance_of(Trocla).to receive(:read_config).and_return(test_config)
  end
  context 'in normal usage with' do
    before(:each) do
      @trocla = Trocla.new
      @trocla.password('init','plain')
    end

    describe "password" do
      it "generates random passwords by default" do
        expect(@trocla.password('random1','plain')).not_to eq(@trocla.password('random2','plain'))
      end

      it "generates passwords of length #{default_config['options']['length']}" do
        expect(@trocla.password('random1','plain').length).to eq(default_config['options']['length'])
      end

      Trocla::Formats.all.each do |format|
        describe "#{format} password format" do
          it "retursn a password hashed in the #{format} format" do
            expect(@trocla.password('some_test',format,format_options[format])).not_to be_empty
          end

          it "returns the same hashed for the #{format} format on multiple invocations" do
            expect(round1=@trocla.password('some_test',format,format_options[format])).not_to be_empty
            expect(@trocla.password('some_test',format,format_options[format])).to eq(round1)
          end

          it "also stores the plain password by default" do
            pwd = @trocla.password('some_test','plain')
            expect(pwd).not_to be_empty
            expect(pwd.length).to eq(16)
          end
        end
      end

      Trocla::Formats.all.reject{|f| f == 'plain' }.each do |format|
        it "raises an exception if not a random password is asked but plain password is not present for format #{format}" do
          expect{@trocla.password('not_random',format, 'random' => false)}.to raise_error(/Password must be present as plaintext/)
        end
      end

      describe 'with profiles' do
        it 'raises an exception on unknown profile' do
          expect{@trocla.password('no profile known','plain',
            'profiles' => 'unknown_profile') }.to raise_error(/No such profile unknown_profile defined/)
        end

        it 'takes a profile and merge its options' do
          pwd = @trocla.password('some_test','plain', 'profiles' => 'rootpw')
          expect(pwd).not_to be_empty
          expect(pwd.length).to eq(32)
          expect(pwd).to_not match(/[={}\[\]\?%\*()&!]+/)
        end

        it 'is possible to combine profiles but first profile wins' do
          pwd = @trocla.password('some_test1','plain', 'profiles' => ['rootpw','login'])
          expect(pwd).not_to be_empty
          expect(pwd.length).to eq(32)
          expect(pwd).not_to match(/[={}\[\]\?%\*()&!]+/)
        end
        it 'is possible to combine profiles but first profile wins 2' do
          pwd = @trocla.password('some_test2','plain', 'profiles' => ['login','mysql'])
          expect(pwd).not_to be_empty
          expect(pwd.length).to eq(16)
          expect(pwd).not_to match(/[={}\[\]\?%\*()&!]+/)
        end
        it 'is possible to combine profiles but first profile wins 3' do
          pwd = @trocla.password('some_test3','plain', 'profiles' => ['mysql','login'])
          expect(pwd).not_to be_empty
          expect(pwd.length).to eq(32)
          expect(pwd).to match(/[+%\/@=\?_.,:]+/)
        end
      end
    end

    describe "set_password" do
      it "resets hashed passwords on a new plain password" do
        expect(@trocla.password('set_test','mysql')).not_to be_empty
        expect(@trocla.get_password('set_test','mysql')).not_to be_nil
        expect(old_plain=@trocla.password('set_test','mysql')).not_to be_empty

        expect(@trocla.set_password('set_test','plain','foobar')).not_to eq(old_plain)
        expect(@trocla.get_password('set_test','mysql')).to be_nil
      end

      it "otherwise updates only the hash" do
        expect(mysql = @trocla.password('set_test2','mysql')).not_to be_empty
        expect(md5crypt = @trocla.password('set_test2','md5crypt')).not_to be_empty
        expect(plain = @trocla.get_password('set_test2','plain')).not_to be_empty

        expect(new_mysql = @trocla.set_password('set_test2','mysql','foo')).not_to eql(mysql)
        expect(@trocla.get_password('set_test2','mysql')).to eq(new_mysql)
        expect(@trocla.get_password('set_test2','md5crypt')).to eq(md5crypt)
        expect(@trocla.get_password('set_test2','plain')).to eq(plain)
      end
    end

    describe "reset_password" do
      it "resets a password" do
        plain1 = @trocla.password('reset_pwd','plain')
        plain2 = @trocla.reset_password('reset_pwd','plain')

        expect(plain1).not_to eq(plain2)
      end

      it "does not reset other formats" do
        expect(mysql = @trocla.password('reset_pwd2','mysql')).not_to be_empty
        expect(md5crypt1 = @trocla.password('reset_pwd2','md5crypt')).not_to be_empty

        expect(md5crypt2 = @trocla.reset_password('reset_pwd2','md5crypt')).not_to be_empty
        expect(md5crypt2).not_to eq(md5crypt1)

        expect(@trocla.get_password('reset_pwd2','mysql')).to eq(mysql)
      end
    end

    describe "delete_password" do
      it "deletes all passwords if no format is given" do
        expect(@trocla.password('delete_test1','mysql')).not_to be_nil
        expect(@trocla.get_password('delete_test1','plain')).not_to be_nil

        @trocla.delete_password('delete_test1')
        expect(@trocla.get_password('delete_test1','plain')).to be_nil
        expect(@trocla.get_password('delete_test1','mysql')).to be_nil
      end

      it "deletes only a given format" do
        expect(@trocla.password('delete_test2','mysql')).not_to be_nil
        expect(@trocla.get_password('delete_test2','plain')).not_to be_nil

        @trocla.delete_password('delete_test2','plain')
        expect(@trocla.get_password('delete_test2','plain')).to be_nil
        expect(@trocla.get_password('delete_test2','mysql')).not_to be_nil
      end

      it "deletes only a given non-plain format" do
        expect(@trocla.password('delete_test3','mysql')).not_to be_nil
        expect(@trocla.get_password('delete_test3','plain')).not_to be_nil

        @trocla.delete_password('delete_test3','mysql')
        expect(@trocla.get_password('delete_test3','mysql')).to be_nil
        expect(@trocla.get_password('delete_test3','plain')).not_to be_nil
      end
    end

    context 'concurrent access' do
      context 'on expensive flagged formats' do
        before(:each) do
          expect(Trocla::Formats).to receive(:[]).with('sleep').and_return(Trocla::Formats::Sleep)
          expect(Trocla::Formats::Sleep).to receive(:expensive?).at_least(:once).and_return(true)
          expect(Trocla::Formats).to receive(:available?).with('sleep').at_least(:once).and_return(true)
        end
        it 'should not overwrite a value if it takes longer' do
          t1 = Thread.new{ @trocla.password('threadpwd','sleep','sleep' => 4) }
          t2 = Thread.new{ @trocla.password('threadpwd','sleep','sleep' => 1) }
          pwd1 = t1.value
          pwd2 = t2.value
          real_value = @trocla.password('threadpwd','sleep')
          # as t2 finished first this should win
          expect(pwd1).to eql(pwd2)
          expect(real_value).to eql(pwd1)
          expect(real_value).to eql(pwd2)
        end
      end
      context 'on inexpensive flagged formats' do
        before(:each) do
          expect(Trocla::Formats).to receive(:[]).with('sleep').and_return(Trocla::Formats::Sleep)
          expect(Trocla::Formats::Sleep).to receive(:expensive?).at_least(:once).and_return(false)
          expect(Trocla::Formats).to receive(:available?).with('sleep').at_least(:once).and_return(true)
        end
        it 'should not overwrite a value if it takes longer' do
          t1 = Thread.new{ @trocla.password('threadpwd_inexp','sleep','sleep' => 4) }
          t2 = Thread.new{ @trocla.password('threadpwd_inexp','sleep','sleep' => 1) }
          pwd1 = t1.value
          pwd2 = t2.value
          real_value = @trocla.password('threadpwd_inexp','sleep')
          # as t2 finished first but the format is inexpensive it gets overwritten
          expect(pwd1).not_to eql(pwd2)
          expect(real_value).to eql(pwd1)
          expect(real_value).not_to eql(pwd2)
        end
      end
      context 'real world example' do
        it 'should store the quicker one' do
          t1 = Thread.new{ @trocla.password('threadpwd_real','bcrypt','cost' => 17) }
          t2 = Thread.new{ @trocla.password('threadpwd_real','bcrypt') }
          pwd1 = t1.value
          pwd2 = t2.value
          real_value = @trocla.password('threadpwd_real','bcrypt')
          # t2 should still win but both should be the same
          expect(pwd1).to eql(pwd2)
          expect(real_value).to eql(pwd1)
          expect(real_value).to eql(pwd2)
        end
        it 'should store the quicker one test 2' do
          t1 = Thread.new{ @trocla.password('my_shiny_selfsigned_ca', 'x509', {
            'CN'        => 'This is my self-signed certificate',
            'become_ca' => false,
          }) }
          t2 = Thread.new{ @trocla.password('my_shiny_selfsigned_ca', 'x509', {
            'CN'        => 'This is my self-signed certificate',
            'become_ca' => false,
          }) }
          cert1 = t1.value
          cert2 = t2.value
          real_value = @trocla.password('my_shiny_selfsigned_ca','x509')
          # t2 should still win but both should be the same
          expect(cert1).to eql(cert2)
          expect(real_value).to eql(cert1)
          expect(real_value).to eql(cert2)
        end
      end
    end

  end
  context 'with .open' do
    it 'closes the connection with a block' do
      expect_any_instance_of(Trocla::Stores::Memory).to receive(:close)
      Trocla.open{|t|
        t.password('plain_open','plain')
      }
    end
    it 'keeps the connection without a block' do
      expect_any_instance_of(Trocla::Stores::Memory).not_to receive(:close)
      Trocla.open.password('plain_open','plain')
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
  it "returns a version" do
    expect(Trocla::VERSION::STRING).not_to be_empty
  end
end
