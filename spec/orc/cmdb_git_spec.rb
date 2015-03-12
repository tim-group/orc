$: << File.join(File.dirname(__FILE__), "..", "../lib")
$: << File.join(File.dirname(__FILE__), "..", "../test")

require 'spec_helper'
require 'rubygems'
require 'rspec'
require 'orc/cmdb/git'
require 'tmpdir'
require 'git'

describe Orc::CMDB::Git do
  def local_git
    # Git.open(@local, :log => Logger.new(STDOUT))
    Git.open(@local, :log => nil)
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
    gitcmdb.update()
    gitcmdb.get_branch().should eql("master")
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
    gitcmdb.update()
    gitcmdb.get_branch().should eql(branch_name)
  end

  it 'pushes changes back to the origin' do
    gitcmdb = Orc::CMDB::Git.new(
      :local_path => @local,
      :origin => @origin
    )
    gitcmdb.update()

    File.open(@local + '/file', "w") do |f|
      f.write("hello world")
    end

    gitcmdb.commit_and_push

    gitcmdb2 = Orc::CMDB::Git.new(
      :local_path => @second_copy_of_local,
      :origin => @origin
    )
    gitcmdb2.update()

    IO.read(@second_copy_of_local + '/file').should eql("hello world")
  end

  it 'correctly merges changes when the current repo has fast-forward commits' do
    gitcmdb = Orc::CMDB::Git.new(
      :local_path => @local,
      :origin => @origin
    )
    gitcmdb.update()
    gitcmdb2 = Orc::CMDB::Git.new(
      :local_path => @second_copy_of_local,
      :origin => @origin
    )
    gitcmdb2.update()
    File.open(@local + '/file', "w") do |f|
      f.write("hello world")
    end
    gitcmdb.commit_and_push
    File.open(@second_copy_of_local + '/file2', "w") do |f|
      f.write("hello world")
    end
    gitcmdb2.commit_and_push
    IO.read(@second_copy_of_local + '/file').should eql("hello world")
  end

  it 'doesnt break if we commit the same tree twice' do
    gitcmdb = Orc::CMDB::Git.new(
      :local_path => @local,
      :origin => @origin
    )
    gitcmdb.update()

    File.open(@local + '/file', "w") do |f|
      f.write("hello world")
    end
    gitcmdb.commit_and_push

    gitcmdb.commit_and_push

    gitcmdb.get_branch().should eql("master")

    g = local_git
    commits = g.log
    commits.size.should eql(2)
    commits.to_a[0].parents.size.should eql(1)
    commits.to_a[1].parents.size.should eql(0)
  end

  it 'doesnt merge if history is linear' do
    gitcmdb = Orc::CMDB::Git.new(
      :local_path => @local,
      :origin => @origin
    )
    gitcmdb.update()

    File.open(@local + '/file', "w") do |f|
      f.write("hello world")
    end
    gitcmdb.commit_and_push

    File.open(@local + '/file', "w") do |f|
      f.write("hello mars")
    end
    gitcmdb.commit_and_push

    gitcmdb.get_branch().should eql("master")

    g = local_git
    commits = g.log
    commits.size.should eql(3)
    commits.to_a[0].parents.size.should eql(1)
    commits.to_a[1].parents.size.should eql(1)
    commits.to_a[2].parents.size.should eql(0)
  end

  it 'doesnt break if we commit the same tree twice' do
    gitcmdb = Orc::CMDB::Git.new(
      :local_path => @local,
      :origin => @origin
    )
    gitcmdb.update()

    File.open(@local + '/file', "w") do |f|
      f.write("hello world")
    end
    gitcmdb.commit_and_push

    File.open(@local + '/file', "w") do |f|
      f.write("hello mars")
    end
    gitcmdb.commit_and_push

    gitcmdb.get_branch().should eql("master")

    g = local_git
    commits = g.log
    commits.size.should eql(3)
    commits.to_a[0].parents.size.should eql(1)
    commits.to_a[1].parents.size.should eql(1)
    commits.to_a[2].parents.size.should eql(0)
  end

  it 'can clone and then update' do
    gitcmdb = Orc::CMDB::Git.new(
      :local_path => @local,
      :origin => @origin
    )
    gitcmdb.update()
    gitcmdb.get_branch().should eql("master")
    gitcmdb.update()
    gitcmdb.get_branch().should eql("master")
  end
end
