dep 'passenger deploy repo' do
  requires 'passenger deploy repo exists', 'passenger deploy repo hook'
end

dep 'passenger deploy repo hook' do
  requires 'passenger deploy repo exists'
  met? { (var(:passenger_repo_root) / '.git/hooks/post-receive').executable? }
  meet {
    in_dir var(:passenger_repo_root), :create => true do
      %w[pre-receive post-receive].each {|hook_name|
        render_erb "git/deploy-repo-#{hook_name}", :to => ".git/hooks/#{hook_name}"
        shell "chmod +x .git/hooks/#{hook_name}"
      }
    end
  }
end

dep 'passenger deploy repo exists' do
  requires 'git', 'user exists'
  define_var :passenger_repo_root, :default => :rails_root
  met? { (var(:passenger_repo_root) / '.git').dir? }
  meet {
    in_dir var(:passenger_repo_root), :create => true do
      shell "git init"
    end
  }
end
