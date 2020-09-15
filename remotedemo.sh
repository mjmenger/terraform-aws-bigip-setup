if [! -d ansible-uber-demo]; then
  git clone https://github.com/mjmenger/ansible-uber-demo
fi
cp inventory.yml ansible-uber-demo/ansible/inventory.yml
cd ansible-uber-demo
./install-ubuntu-dependencies.sh
./deploy.sh
