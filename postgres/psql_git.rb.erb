#!/usr/bin/env ruby

require 'singleton'

class String
  def / other
    empty? ? other.to_s : File.join(self, other.to_s)
  end
end

class PsqlGit
  include Singleton

  PREFIX = File.expand_path("~/backups")
  REPO_PATH = File.join(PREFIX, "psql.git")
  LOG_PATH = File.join(PREFIX, "psql_git.log")
  RESERVED_DBS = %w[
    postgres
    template0
    template1
  ]

  def init!
    if File.exists?(REPO_PATH / '.git')
      true
    elsif shell("mkdir -p #{REPO_PATH}")
      Dir.chdir REPO_PATH do
        shell "git init ."
        shell "touch .gitignore"
        shell "git add .gitignore"
        shell commit_all('Added .gitignore.')
      end
    end
  end

  def backup!
    setup
    puts "\n"
    log "Starting a psql backup."
    init!
    Dir.chdir(REPO_PATH) { dump; commit; push }
  end

  private

  def setup
    @fds ||= [STDOUT, STDERR].each {|fd|
      fd.reopen(LOG_PATH, 'a').sync = true
    }
    shell "mkdir -p '#{PREFIX}'" unless File.exists?(PREFIX)
  end

  def dump
    db_names.each {|db_name|
      shell "sudo -u postgres pg_dump #{db_name} > #{db_name}.psql"
    }
  end

  def commit
    shell "git checkout -b #{branch} || git checkout #{branch}"
    shell "git add ."
    shell(commit_all('backup')).tap {|result|
      log shell("git show --stat")
      shell "git gc" if result
    }
  end

  def push
    shell('git remote').split("\n").each {|remote|
      shell "git push -f #{remote} #{branch}"
    }
  end

  def branch
    @branch ||= shell('hostname -f').chomp
  end

  def db_names
    shell('sudo -u postgres psql -l').split("\n").grep(/^ [^ ]/).map {|l|
      l.gsub(/\|.*$/, '').strip
    } - RESERVED_DBS
  end

  def commit_all message
    "git commit -a --author='PsqlGit <ben+psqlgit@hoskings.net>' -m '#{message}'"
  end

  def shell cmd
    log "$ #{cmd}"
    output = `#{cmd}`
    output if $? == 0
  end

  def log message, opts = {}
    print "#{Time.now}: #{message}#{"\n" unless opts[:newline] == false}"
  end

end

PsqlGit.instance.backup!
