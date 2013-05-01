
require 'orc/deploy_client'

describe Orc::DeployClient do
  def get_client(msg)
    mcollective_client = double()
    mcollective_client.stub(:status).and_return(msg)
    mcollective_client.stub(:custom_request).and_return(msg)
    Orc::DeployClient.new(
      :mcollective_client=>mcollective_client
    )
  end

  it 'Can be constructed without an application' do
    client = get_client([])
  end

  it 'handles messages correctly when the agent throws an exception' do
    client = get_client([
      {:data=>{:status=>nil}}
    ])

    expect { client.status() }.to raise_error(Orc::Exception::FailedToDiscover)
  end

  it 'process status messages from new agents' do
    client = get_client([
      {
      :data=>{:statuses=>[{:environment=>"latest",:application=>"fed"}]},
      :sender=>"mars"}
    ])

    client.status().should eql([{
      :environment=>"latest",:application=>"fed",:host=>"mars"
      }])
  end

  it 'process status messages from old agents' do
    client = get_client([
      {
      :data=>[{:environment=>"latest",:application=>"fed"}],
      :sender=>"mars"}
    ])

    client.status().should eql([{
      :environment=>"latest",:application=>"fed",:host=>"mars"
      }])
  end

  it 'returns false when a remote error is reported' do
    client = get_client([
      {:data=>{
        :logs=>{
          :infos=>[],
          :warns=>[],
          :errors=>[]
        },
        :successful=>false
      },
      :sender=>"mars"}
    ])
    client.update_to_version({:environment=>"test",:application=>"xyz"}, ["mars"],5).should eql(false)
  end

end
