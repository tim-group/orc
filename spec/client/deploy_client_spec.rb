
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

end
