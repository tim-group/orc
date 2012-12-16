
require 'client/deploy_client'

describe Client::DeployClient do

  it 'handles messages correctly when the agent throws an exception' do
    well_formed_message =  [
      {:data=>{:status=>nil}}
    ]

    mcollective_client = double()
    mcollective_client.stub(:status).and_return(well_formed_message)

    client = Client::DeployClient.new(:mcollective_client=>mcollective_client)
    client.status().instances.should eql([])
  end

  it 'process status messages from new agents' do
    well_formed_message =  [
      {
      :data=>{:statuses=>[{:environment=>"latest",:application=>"fed"}]},
      :sender=>"mars"}
    ]

    mcollective_client = double()
    mcollective_client.stub(:status).and_return(well_formed_message)

    client = Client::DeployClient.new(:mcollective_client=>mcollective_client)
    client.status().instances.should eql([{
      :environment=>"latest",:application=>"fed",:host=>"mars"
      }])
  end

  it 'process status messages from old agents' do
    well_formed_message =  [
      {
      :data=>[{:environment=>"latest",:application=>"fed"}],
      :sender=>"mars"}
    ]

    mcollective_client = double()
    mcollective_client.stub(:status).and_return(well_formed_message)

    client = Client::DeployClient.new(:mcollective_client=>mcollective_client)
    client.status().instances.should eql([{
      :environment=>"latest",:application=>"fed",:host=>"mars"
      }])
  end

end
