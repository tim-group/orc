class TimeoutTestClass
  include Orc::Util::Timeout
  def test
    timeout(1) do
      sleep 2
    end
  end
end

describe Orc::Util::Timeout do
  it 'can be constructed' do
    i = TimeoutTestClass.new
    expect { i.test }.to raise_error(Orc::Exception::Timeout)
  end
end
