require 'orc/cmdb/git'
require 'pp'

describe Orc::CMDB::Git do
  def local_git
    # Git.open(@local, :log => Logger.new(STDOUT))
    Git.open(@local, :log => nil)
  end

  def setup_alice_and_bob_repos
    FileUtils.touch("#{@origin}/alice")
    FileUtils.touch("#{@origin}/bob")
    @repo.add("#{@origin}/alice")
    @repo.add("#{@origin}/bob")
    @repo.commit_all('Initial commit')
    @repo.config('core.bare', 'true')

    alice_path = @tempdir + '/alice_clone'
    bob_path = @tempdir + '/bob_clone'

    bob = Orc::CMDB::Git.new(:local_path => bob_path, :origin => @origin)
    alice = Orc::CMDB::Git.new(:local_path => alice_path, :origin => @origin)
    bob.update
    alice.update

    [alice, bob]
  end

  before do
    @tempdir = Dir.mktmpdir(nil, "/tmp")
    @origin = "#{@tempdir}/cmdb_origin"
    @repo = Git.init(@origin)
    FileUtils.touch("#{@origin}/file")
    FileUtils.touch("#{@origin}/file2")
    @repo.add("#{@origin}/file")
    @repo.add("#{@origin}/file2")
    @repo.commit_all('Initial commit')
    @repo.config("core.bare", "true")
    @local = @tempdir + "/cmdb"
    @second_copy_of_local = @tempdir + "/cmdb2"
  end

  after do
    FileUtils.remove_dir(@tempdir)
  end

  it 'pulls or clones the cmdb' do
    gitcmdb = Orc::CMDB::Git.new(:local_path => @local, :origin => @origin)
    gitcmdb.update
    expect(gitcmdb.get_branch).to eql("master")
  end

  it 'try to commit to a repo without updating it will fail' do
    gitcmdb = Orc::CMDB::Git.new(
      :local_path => @local,
      :origin => @origin
    )

    expect { gitcmdb.commit_and_push }.to raise_error
  end

  it 'can clone a specific branch' do
    branch_name = "mybranch"
    gitcmdb = Orc::CMDB::Git.new(
      :local_path => @local,
      :origin => @origin,
      :branch => branch_name
    )
    gitcmdb.update
    expect(gitcmdb.get_branch).to eql(branch_name)
  end

  it 'pushes changes back to the origin' do
    gitcmdb = Orc::CMDB::Git.new(
      :local_path => @local,
      :origin => @origin
    )
    gitcmdb.update

    File.open(@local + '/file', "w") do |f|
      f.write("hello world")
    end

    gitcmdb.commit_and_push

    gitcmdb2 = Orc::CMDB::Git.new(
      :local_path => @second_copy_of_local,
      :origin => @origin
    )
    gitcmdb2.update

    expect(IO.read(@second_copy_of_local + '/file')).to eql("hello world")
  end

  it 'correctly merges changes when the current repo has fast-forward commits' do
    gitcmdb = Orc::CMDB::Git.new(
      :local_path => @local,
      :origin => @origin
    )
    gitcmdb.update
    gitcmdb2 = Orc::CMDB::Git.new(
      :local_path => @second_copy_of_local,
      :origin => @origin
    )
    gitcmdb2.update
    File.open(@local + '/file', "w") do |f|
      f.write("hello world")
    end
    gitcmdb.commit_and_push
    File.open(@second_copy_of_local + '/file2', "w") do |f|
      f.write("hello world")
    end
    gitcmdb2.commit_and_push
    expect(IO.read(@second_copy_of_local + '/file')).to eql("hello world")
  end

  it 'doesnt break if we commit the same tree twice' do
    gitcmdb = Orc::CMDB::Git.new(
      :local_path => @local,
      :origin => @origin
    )
    gitcmdb.update

    File.open(@local + '/file', "w") do |f|
      f.write("hello world")
    end
    gitcmdb.commit_and_push

    gitcmdb.commit_and_push

    expect(gitcmdb.get_branch).to eql("master")

    g = local_git
    commits = g.log
    expect(commits.size).to eql(2)
    expect(commits.to_a[0].parents.size).to eql(1)
    expect(commits.to_a[1].parents.size).to eql(0)
  end

  it 'doesnt merge if history is linear' do
    gitcmdb = Orc::CMDB::Git.new(
      :local_path => @local,
      :origin => @origin
    )
    gitcmdb.update

    File.open(@local + '/file', "w") do |f|
      f.write("hello world")
    end
    gitcmdb.commit_and_push

    File.open(@local + '/file', "w") do |f|
      f.write("hello mars")
    end
    gitcmdb.commit_and_push

    expect(gitcmdb.get_branch).to eql("master")

    g = local_git
    commits = g.log
    expect(commits.size).to eql(3)
    expect(commits.to_a[0].parents.size).to eql(1)
    expect(commits.to_a[1].parents.size).to eql(1)
    expect(commits.to_a[2].parents.size).to eql(0)
  end

  it 'doesnt break if we commit the same tree twice' do
    gitcmdb = Orc::CMDB::Git.new(
      :local_path => @local,
      :origin => @origin
    )
    gitcmdb.update

    File.open(@local + '/file', "w") do |f|
      f.write("hello world")
    end
    gitcmdb.commit_and_push

    File.open(@local + '/file', "w") do |f|
      f.write("hello mars")
    end
    gitcmdb.commit_and_push

    expect(gitcmdb.get_branch).to eql("master")

    g = local_git
    commits = g.log
    expect(commits.size).to eql(3)
    expect(commits.to_a[0].parents.size).to eql(1)
    expect(commits.to_a[1].parents.size).to eql(1)
    expect(commits.to_a[2].parents.size).to eql(0)
  end

  it 'can clone and then update' do
    gitcmdb = Orc::CMDB::Git.new(
      :local_path => @local,
      :origin => @origin
    )
    gitcmdb.update
    expect(gitcmdb.get_branch).to eql("master")
    gitcmdb.update
    expect(gitcmdb.get_branch).to eql("master")
  end

  it 'retries to push if there have been concurrent modifications after the initial fetching' do
    alice, bob = setup_alice_and_bob_repos

    File.open(bob.local_path + '/bob', 'w') { |f| f.write("bob's edit") }
    File.open(alice.local_path + '/alice', 'w') { |f| f.write("alice's edit") }

    alice_thread = Thread.new { alice.commit_and_push }
    bob_thread = Thread.new { bob.commit_and_push }

    alice_thread.join
    bob_thread.join

    alice.update
    bob.update

    expect(IO.read(bob.local_path + '/alice')).to eql("alice's edit")
    expect(IO.read(alice.local_path + '/bob')).to eql("bob's edit")
  end

  it 'will attempt to retry push if rejected with a git error' do
    alice, bob = setup_alice_and_bob_repos

    File.open(alice.local_path + '/alice', 'w') { |f| f.write("alice's edit") }

    number_of_attempts_to_reject = 4
    File.open("#{@origin}/attempts", 'w') { |f| f.write('0') }
    hook_path = "#{@origin}/.git/hooks/pre-receive"
    hook = %(#!/bin/sh
attempts=`cat #{@origin}/attempts`
if [ "$attempts" -lt #{number_of_attempts_to_reject} ] ; then
  echo $(( attempts + 1 )) > "#{@origin}/attempts"
  exit 1 # Reject push on the first attempts
else
  exit 0 # Eventually allow push
fi
)
    FileUtils.touch(hook_path)
    FileUtils.chmod('+x', hook_path)
    File.open(hook_path, 'w') do |f|
      f.write(hook)
    end

    alice.commit_and_push
    bob.update
    expect(IO.read(bob.local_path + '/alice')).to eql("alice's edit")
  end

  it 'will stop retries of push and fail if rejected too many times' do
    alice, _bob = setup_alice_and_bob_repos

    File.open(alice.local_path + '/alice', 'w') { |f| f.write("alice's edit") }

    File.open("#{@origin}/attempts", 'w') { |f| f.write('0') }
    hook_path = "#{@origin}/.git/hooks/pre-receive"
    hook = "#!/bin/sh\nexit 1 # Reject every push\n"
    FileUtils.touch(hook_path)
    FileUtils.chmod('+x', hook_path)
    File.open(hook_path, 'w') do |f|
      f.write(hook)
    end

    expect { alice.commit_and_push }.to raise_error(Git::GitExecuteError)
  end
end
