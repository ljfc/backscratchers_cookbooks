Chef::Log.info("*** Installing demo application ***")

application 'Install NetHack' do
  package 'nethack.x86_64'
end
