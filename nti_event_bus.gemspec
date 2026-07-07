# frozen_string_literal: true

require_relative 'lib/nti_event_bus/version'

Gem::Specification.new do |spec|
  spec.name = 'nti_event_bus'
  spec.version = NtiEventBus::VERSION
  spec.authors = ['Den Meralpis']
  spec.email = ['denmark@nueca.com.ph']

  spec.summary = 'A production-grade event bus with a Rails DSL and asynchronous ActiveJob dispatch.'
  spec.description = 'NtiEventBus is a lightweight publish/subscribe event bus. Declare `domain.action` ' \
                     'subscriptions in a small DSL, publish events, and fan them out to handler classes ' \
                     'asynchronously via ActiveJob. The subscription registry is built once and deep-frozen ' \
                     'for lock-free reads, so publishing adds no locking and no unbounded state.'
  spec.homepage = 'https://github.com/nueca-tech/nti_event_bus'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ spec/ features/ .git .rspec .rubocop.yml Gemfile])
    end
  end

  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activejob', '>= 7.1'
  spec.add_dependency 'activesupport', '>= 7.1'
end
