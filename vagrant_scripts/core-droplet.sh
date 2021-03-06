# TODO: Create an ansible playlist for this shell script
export DEBIAN_FRONTEND=noninteractive

while [ `pidof -d ',' apt apt-get dpkg` ]
do
  echo "Waiting for apt to finish..."
  sleep 1
done

apt-get update
apt-get upgrade -y

# Add docker repositories
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu disco stable" > /etc/apt/sources.list.d/docker-ce.list
apt-get update


echo "Installing docker..."
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
apt-get install -y docker-ce docker-ce-cli containerd.io
cp /vagrant/docker.service /usr/lib/systemd/system/docker.service
cp /vagrant/jenkins.daemon.json /etc/docker/daemon.json
systemctl daemon-reload
systemctl restart docker

echo "Installing docker compose..."
sudo curl -s -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose --version

echo "Adding user for deployments (p91challenge)..."
useradd -g docker -s /usr/bin/bash -m p91challenge
mkdir ~p91challenge/.ssh
chmod 700 ~p91challenge/.ssh
cat /vagrant/jenkins-ssh-key.pub > ~p91challenge/.ssh/authorized_keys
echo "Clonning git repository..."
cd ~p91challenge
git clone https://github.com/p91-challenge/p91-challenge.git
chown -R p91challenge p91-challenge
cd p91-challenge

echo "Setting the acme.json file"
touch acme.json # Let's encrypt certificates generated by traefik
chmod 600 acme.json

echo "Pulling the docker images (this may take up to a couple of minutes)..."
docker-compose -f docker-compose-production.yml pull -q

#docker pull p91challenge/nginx-prod

echo "Creating the database..."
docker-compose -f docker-compose-production.yml run --entrypoint '' rails rails db:create
docker-compose -f docker-compose-production.yml run --entrypoint '' rails rails db:schema:load

docker-compose -f docker-compose-production.yml up -d
