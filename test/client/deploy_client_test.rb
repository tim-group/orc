$: << File.join(File.dirname(__FILE__), "..", "../lib")

require 'test/unit'
require 'client/deploy_client'
require 'etc'


class DeployClientTest  < Test::Unit::TestCase
  def setup
    user = Etc.getlogin
    ENV['MCOLLECTIVE_SSL_PRIVATE']="test/fixtures/ci-tester-private.pem"
    ENV['MCOLLECTIVE_SSL_PUBLIC']="test/fixtures/ci-tester.pem"
  end

  def test_address_specific_environment_only
    deploy_client = Client::DeployClient.new(:environment=>"staging2", :config=>"test/fixtures/mcollective-client.cfg")
    statuses = deploy_client.status()
    assert_equal 1, statuses.count()
    assert_equal 1, statuses.unique_hosts().size()
  end

  def test_get_status_for_all_instances_of_an_application
    deploy_client = Client::DeployClient.new(:environment=>"staging", :config=>"test/fixtures/mcollective-client.cfg")
    statuses = deploy_client.status({:application=>"JavaHttpRef"})
    assert_equal 4, statuses.count()
    assert_equal 2, statuses.unique_hosts().size()
  end

  def test_get_status_for_all_instances_of_an_application_group
    deploy_client = Client::DeployClient.new(:environment=>"staging", :config=>"test/fixtures/mcollective-client.cfg")
    statuses = deploy_client.status({:group=>"blue", :application=>"JavaHttpRef"})
    assert_equal 2, statuses.count()
    assert_equal 2, statuses.unique_hosts().size()
  end

  def test_get_status_for_all_instances_of_an_application_group
    deploy_client = Client::DeployClient.new(:environment=>"staging", :config=>"test/fixtures/mcollective-client.cfg")
    statuses = deploy_client.status({:group=>"blue", :application=>"NoExist"})
    assert_equal 0, statuses.count()
  end
  #
  #  def deploy_version_to_group(environment, group, version)
  #    deploy_client = Client::DeployClient.new(:environment=>environment)
  #    deploy_client.update_to_version({:application=>"JavaHttpRef", :group=>group}, [], version)
  #    statuses = deploy_client.status(:application=>"JavaHttpRef", :group=>group)
  #    assert statuses.instances.size() >  0
  #    statuses.instances.each do |instance|
  #      assert_equal version, instance[:version]
  #    end
  #  end
  #
  #  def test_deploy_version_to_group
  #    deploy_version_to_group("staging","blue", "1.0.18")
  #  end
  #
  #  def test_deploy_version_to_group_again
  #    deploy_version_to_group("staging","blue", "1.0.19")
  #  end
  #
  #  def test_deploy_to_different_environment_again
  #    deploy_version_to_group("staging2","green", "1.0.19")
  #  end
  #
  #  def test_deploy_to_different_environment
  #    deploy_version_to_group("staging2","green", "1.0.18")
  #  end
  #
  #  def test_participation_disabled_when_enable_message_sent
  #    deploy_client = Client::DeployClient.new(:environment=>"staging")
  #    deploy_client.disable_participation({:application=>"JavaHttpRef", :group=>"blue"})
  #    statuses = deploy_client.status(:application=>"JavaHttpRef", :group=>"blue")
  #    assert statuses.instances.size() >  0
  #    statuses.instances.each do |instance|
  #      assert_equal false, instance[:participating]
  #    end
  #  end
  #
  #  def test_participation_enabled_when_enable_message_sent
  #    deploy_client = Client::DeployClient.new(:environment=>"staging")
  #    deploy_client.enable_participation({:application=>"JavaHttpRef", :group=>"blue"})
  #    statuses = deploy_client.status(:application=>"JavaHttpRef", :group=>"blue")
  #    assert statuses.instances.size() >  0
  #    statuses.instances.each do |instance|
  #      assert_equal true, instance[:participating]
  #    end
  #  end
  #
  #  def test_starts_off_disabled
  #    deploy_client = Client::DeployClient.new(:environment=>"staging")
  #    deploy_client.update_to_version({:application=>"JavaHttpRef", :group=>"blue"},"1.0.19")
  #    statuses = deploy_client.status(:application=>"JavaHttpRef", :group=>"blue")
  #    assert statuses.instances.size() >  0
  #    statuses.instances.each do |instance|
  #      assert_equal false, instance[:participating]
  #    end
  #  end

end