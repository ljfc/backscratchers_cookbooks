name 'bs'
maintainer 'The Backscratchers'
maintainer_email 'leo@thebackscratchers.com'
description 'Manages The Backscratchers infrastructure'
long_description 'Manages infrastructure for The Backscratchers website on Amazon Web Services OpsWorks'
version '0.0.0'

depends 'apt', '~> 3.0.0' # So we can update apt and install the latest packages.

#depends 'application', '~> 5.1.0' # Used to deploy the app instead of Chef’s `deploy` resource.
depends 'application_git', '~> 1.1.0' # So we can access a private Github repository.
depends 'application_ruby', '~> 4.0.1' # So we can deploy Ruby/Rails apps.
depends 'poise-ruby-build', '~> 1.0.1' # So we can build a specific version of Ruby.
