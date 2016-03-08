Chef::Log.info("*** Installing demo application ***")

include_recipe 'build-essential'
package node.value_for_platform(
  %w{debian ubuntu} => {default: %w{libmysqlclient-dev libpq-dev libsqlite3-dev}},
  %w{redhat centos} => {'~> 7.0' => %w{mariadb-devel postgresql-libs postgresql-devel sqlite-devel},
                        '~> 6.0' => %w{mysql-devel postgresql-libs postgresql-devel sqlite-devel}},
)

application 'Install a demo app' do
  path '/srv/demo'

  # Clone the source code from GitHub.
  git 'https://github.com/engineyard/todo.git'
  # Install Ruby.
  ruby_runtime 'any' do
    version ''
  end
  # Install node for execjs and link it globally.
  nodejs = javascript 'nodejs'
  link '/usr/bin/node' do
    to nodejs.javascript_binary
  end
  # Run `bundle install` to install dependencies.
  bundle_install
  # Handle Rails deployment.
  rails do
    database 'sqlite3:///db.sqlite3'
    secret_token 'd78fe08df56c9'
    migrate true
  end
  # Create a system service to run Unicorn on port 8000.
  unicorn do
    port 8000
  end
end
