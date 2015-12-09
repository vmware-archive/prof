desc 'build gem'
task :build do
  spec_path = Dir['*.gemspec'].first
  raise 'No .gemspec could be found!' unless spec_path
  gem_build_cmd_parts = [
    'gem',
    'build',
    "'#{spec_path}'",
    '--verbose',
  ]

  sh(gem_build_cmd_parts.join(' '))
end

task :bump, [:type] do |_, args|
  bump_cmd_parts = [
    'gem bump',
    '--version',
    args.type,
    '--commit',
    '--tag',
    '--push',
    '--verbose',
  ]

  sh(bump_cmd_parts.join(' '))
end

namespace :bump do
  desc 'bump patch'
  task patch: :spec do
    Rake::Task[:bump].invoke(:patch)
  end

  desc 'bump minor'
  task minor: :spec do
    Rake::Task[:bump].invoke(:minor)
  end
end

desc 'push gem'
task push: :build do
  new_gem = Dir['*.gem'].sort_by { |file| File.stat(file).ctime }.last

  raise 'Could not find newly created gem!' unless new_gem

  sh("gem push #{new_gem}")
end

task :rebase do
  sh "git pull --rebase"
end

namespace :release do
  desc 'bump patch level, build and push gem'
  task patch: %w(rebase bump:patch push)

  desc 'bump minor level, build and push gem'
  task minor: %w(rebase bump:minor push)
end
