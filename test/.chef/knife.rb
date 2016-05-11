current_dir = File.dirname(__FILE__)
user = ENV['USER']
home = ENV['HOME']
node_name 'fred'
chef_server_url 'http://127.0.0.1:8889'
# chef_server_url 'https://33.33.33.10/organizations/test'
# Copy key from delivery-cluster/.chef/delivery-cluster-data-test/delivery.pem
client_key "#{current_dir}/dummy.pem"
cookbook_path ["#{current_dir}/../cookbooks"]
cache_options(:path => "#{current_dir}/.chef/checksums")

# Copy certs from delivery-cluster/.chef/trusted_certs
trusted_certs_dir "#{home}/.chef/trusted_certs"

git_email = `git config user.email` || 'admin@thirdwaveinsights.com'
knife[:cookbook_copyright] = 'ThirdWave Insights, LLC'
knife[:cookbook_email] = git_email
knife[:vault_mode]='client'
