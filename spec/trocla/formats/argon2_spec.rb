require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe 'Trocla::Format::Argon2' do
  before(:each) do
    expect_any_instance_of(Trocla).to receive(:read_config).and_return(test_config)
    @trocla = Trocla.new
  end

  describe 'default argon2' do
    it 'create a argon2 hash' do
      pass = @trocla.password('argon2_password', 'argon2', {})
      expect(pass).to match(/^\$argon2id\$v=19\$m=#{2**Argon2::Password::DEFAULT_M_COST},t=#{Argon2::Password::DEFAULT_T_COST},p=#{Argon2::Password::DEFAULT_P_COST}/)
    end
  end

  describe 'argon2 with options' do
    it 'create a argon2 with the unsafe profile' do
      pass = @trocla.password(
        'argon2_password_unsafe', 'argon2',
        { 'argon2' => { profile: :unsafe_cheapest } }
      )
      expect(pass).to match(/^\$argon2id\$v=19\$m=8,t=1,p=1\$/)
    end

    it 'create a argon2 with the specific cost options' do
      pass = @trocla.password(
        'argon2_password_specific', 'argon2',
        { 'argon2' => { t_cost: 2, m_cost: 16, p_cost: 1 }}
      )
      expect(pass).to match(/^\$argon2id\$v=19\$m=#{2**16},t=2,p=1\$/)
    end
  end
end
