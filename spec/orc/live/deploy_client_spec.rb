require 'orc/live/deploy_client'

describe Orc::DeployClient do
  def get_client(msg)
    mcollective_client = double
    allow(mcollective_client).to receive(:status).and_return(msg)
    allow(mcollective_client).to receive(:custom_request).and_return(msg)
    Orc::DeployClient.new(
      :mcollective_client => mcollective_client
    )
  end

  it 'Can be constructed without an application' do
    get_client([])
  end

  it 'handles messages correctly when the agent throws an exception' do
    client = get_client([{ :data => { :status => nil } }])

    expect { client.status }.to raise_error(Orc::Live::FailedToDiscover)
  end

  it 'process status messages from new agents' do
    client = get_client([
      {
        :data => { :statuses => [{ :environment => "latest", :application => "fed" }] },
        :sender => "mars" }
    ])

    expect(client.status).to eql([{ :environment => "latest", :application => "fed", :host => "mars" }])
  end

  it 'process status messages from old agents' do
    client = get_client([
      {
        :data => [{ :environment => "latest", :application => "fed" }],
        :sender => "mars" }
    ])

    expect(client.status).to eql([{ :environment => "latest", :application => "fed", :host => "mars" }])
  end

  it 'returns false when a remote error is reported' do
    client = get_client([
      { :data => {
        :logs => {
          :infos => [],
          :warns => [],
          :errors => []
        },
        :successful => false
      },
        :sender => "mars" }
    ])
    expect(client.update_to_version({ :environment => "test", :application => "xyz" }, ["mars"], 5)).to eql(false)
  end
end
