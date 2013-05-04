=begin
Plugin: Git Local Repositories
Description: Grabs all git commits on your machine
Author: [Lang Sharpe](http://thedataasylum.com/)
Notes:
This will find all of the commits you have made to any repository on your machine.
=end


require 'shellwords'

config = { # description and a primary key (username, url, etc.) required
  'description' => [
    'Log all commits made on your machine',
    '- All branches are looked at in all found repositories',
    'author (regex) is passed to git log --author to filter in commits',
    'basedir is the root directory of the search for repositories',
  ],
  'author' => '.*',
  'basedir' => '~/',
  'tags' => '#social #coding'
}

# Update the class key to match the unique classname below
$slog.register_plugin({ 'class' => 'LocalGitRepos', 'config' => config })

class LocalGitRepos < Slogger
  # every plugin must contain a do_log function which creates a new entry using the DayOne class (example below)
  # @config is available with all of the keys defined in "config" above
  # @timespan and @dayonepath are also available
  # returns: nothing
  def do_log
    if @config.key?(self.class.name)
      config = @config[self.class.name]
      # check for a required key to determine whether setup has been completed or not
      if !config.key?('author') || config['author'] == []
        @log.warn("LocalGitRepos has not been configured or an option is invalid, please edit your slogger_config file.")
        return
      end
    else
      @log.warn("LocalGitRepos has not been configured or an option is invalid, please edit your slogger_config file.")
      return
    end
    @log.info("Logging LocalGitRepos posts")

    tags = config['tags'] || ''
    tags = "\n\n#{@tags}\n" unless @tags == ''

    @author = config['author'] || '*'
    @dir = config['basedir'] || '~/'

    @log.warn("#{@timespan.iso8601.shellescape}")

    # Perform necessary functions to retrieve posts

    sl = DayOne.new

    @log.warn('Finding local git repositories. (This may take a few minutes)')
    for repo in repos_in_dir @dir
      @log.warn("Finding interesting commits in #{repo}")
      project_name = project_name_for_repo repo
      output = ''
      for commit in interesting_commits_in_repo(repo)
        @log.warn("Logging commit #{commit} in #{repo}")
        output += "\n * #{commit_info(repo, commit)}"
      end
      if output.strip != ""
        options = {}
        options['content'] = "## Git activity for #{project_name_for_repo(repo)}#{output}#{tags}"
        sl.to_dayone(options)
      end
    end

    return false if output.strip == ""

  end

  def repos_in_dir dir
    `find #{File.expand_path(dir).shellescape} -name ".git" -type d`.map {|x| x.strip }
  end

  def project_name_for_repo repo
    project_name = nil
    project_name = File.basename(repo)
    if project_name == '.git'
      file_name = repo[0..-5]
      project_name = File.basename(file_name)
    end
    project_name
  end

  def interesting_commits_in_repo repo
    `git --git-dir=#{repo.shellescape} log --author=#{@author.shellescape} --after=#{@timespan.iso8601.shellescape} --walk-reflogs --oneline | awk '{print $1}'`.map { |x| x.strip }
  end

  def commit_info repo, commit
    #`git --git-dir=#{repo.shellescape} show --format=short --stat #{commit.shellescape}`
    `git --git-dir=#{repo.shellescape} log -1 --pretty=format:"%s" #{commit.shellescape}`
  end

end
