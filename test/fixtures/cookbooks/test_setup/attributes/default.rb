# Is there a better way to get the test directory?
test_dir = ENV['PWD']

# Fake out delivery attributes
normal['delivery']['workspace_path'] = test_dir
normal['delivery']['workspace']['root'] = test_dir
normal['delivery']['workspace']['repo'] = test_dir
normal['delivery']['workspace']['cache'] =
  "#{test_dir}/.chef/local-mode-cache/cache"
normal['delivery']['workspace']['chef'] = "#{test_dir}/.chef"
normal['delivery']['change']['enterprise'] = 'test'
normal['delivery']['change']['organization'] = 'test'
normal['delivery']['change']['project'] = 'lorries'
normal['delivery']['change']['pipeline'] = 'master'
normal['delivery']['change']['change_id'] =
  'ffe9d5cc-02c3-4f00-87a8-71b5caad93ad'
normal['delivery']['change']['stage'] = ENV['STAGE'] || 'acceptance'
normal['delivery']['change']['phase'] = ENV['PHASE'] || 'provision'
normal['delivery']['change']['git_url'] =
  'ssh://builder@test@myserver:8989/test/test/lorries'
normal['delivery']['change']['sha'] = 'HEAD'
normal['delivery']['change']['patchset_branch'] = 'test'
normal['delivery']['config']['version'] = '2'
normal['delivery_builder']['workspace'] = test_dir
normal['delivery_builder']['build_user'] = ENV['USER']
