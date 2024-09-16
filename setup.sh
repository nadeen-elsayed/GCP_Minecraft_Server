#!/bin/bash
# Create the directory /minecraft, using -p to ensure that parent directories are created if they don't exist
sudo mkdir -p /minecraft


# Create a new VM in Google Cloud with the specified configurations
gcloud compute instances create mc-server \
  --machine-type=e2-medium \
  --zone=us-central1-a \
  --image-family=debian-11 \
  --image-project=debian-cloud \
  --boot-disk-size=50GB \
  --boot-disk-type=pd-ssd \
  --boot-disk-device-name=minecraft-disk \
  --tags=minecraft-server \
  --network-interface=network-tier=PREMIUM,subnet=default \
  --create-disk=auto-delete=yes,boot=no,device-name=minecraft-disk,name=minecraft-disk,size=50,type=pd-ssd \
  --scopes=storage-rw \
  --metadata=startup-script-url=https://storage.googleapis.com/cloud-training/archinfra/mcserver/startup.sh,shutdown-script-url=https://storage.googleapis.com/cloud-training/archinfra/mcserver/shutdown.sh


gcloud compute addresses create mc-server-ip --region=us-central1


gcloud compute addresses describe mc-server-ip --region=us-central1 --format="get(address)"


gcloud compute instances network-interfaces update mc-server \
  --zone=us-central1-a \
  --network-interface=nic0 \
  --addresses=[YOUR_RESERVED_IP]

# Create a firewall rule to allow TCP traffic on port 25565 for the Minecraft server
gcloud compute firewall-rules create minecraft-rule \
  --allow tcp:25565 \
  --target-tags=minecraft-server \
  --source-ranges=0.0.0.0/0 \
  --description="Allow Minecraft server traffic on port 25565" \
  --direction=INGRESS


# Format the disk as ext4 with specific options to optimize initialization and enable discard for SSD optimization
sudo mkfs.ext4 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/disk/by-id/google-minecraft-disk


# Mount the formatted disk to the /home/minecraft directory with discard and default options
sudo mount -o discard,defaults /dev/disk/by-id/google-minecraft-disk /home/minecraft


# Update the package list to ensure you have the latest information about available packages
sudo apt-get update


# Install the default Java Runtime Environment (headless version, which is lighter as it doesn't include a GUI)
sudo apt-get install -y default-jre-headless


# Navigate to the /home/minecraft directory
cd /minecraft


# Install wget, a tool used for downloading files from the web
sudo apt-get install -y wget


# Download the Minecraft server JAR file (version 1.11.2) from Mojang's official server
sudo wget https://launcher.mojang.com/v1/objects/d0d0fe2b1dc6ab4c65554cb734270872b72dadd6/server.jar


# Initialize the Minecraft server by running the JAR file with 1 GB of allocated RAM (Xmx for max, Xms for initial)
sudo java -Xmx1024M -Xms1024M -jar server.jar nogui


# Directly write to the EULA file to accept Mojang's terms (must be set to true to run the server)
echo "eula=true" | sudo tee /minecraft/eula.txt


# Install screen, a tool that allows you to run terminal sessions in the background
sudo apt-get install -y screen


# Start the Minecraft server in a screen session named 'mcs' so it can run independently in the background
sudo screen -S mcs java -Xmx1024M -Xms1024M -jar server.jar nogui


# Set an environment variable for your Google Cloud Storage bucket name
export YOUR_BUCKET_NAME=project-cloud-25-8-2025


# Echo the bucket name to verify that it's set correctly
echo $YOUR_BUCKET_NAME


# Create a new bucket in Google Cloud Storage for Minecraft backups
gsutil mb gs://$YOUR_BUCKET_NAME-minecraft-backup


# Create the backup script that will save and back up the Minecraft world
cat << 'EOF' | sudo tee /home/minecraft/backup.sh > /dev/null
#!/bin/bash
# Send commands to the running Minecraft server to save all progress and disable saving
screen -r mcs -X stuff '/save-all\n/save-off\n'


# Copy the Minecraft world folder to Google Cloud Storage, adding a timestamp to the backup name
/usr/bin/gsutil cp -R ${BASH_SOURCE%/*}/world gs://${YOUR_BUCKET_NAME}-minecraft-backup/$(date "+%Y%m%d-%H%M%S")-world


# Re-enable saving in the Minecraft server
screen -r mcs -X stuff '/save-on\n'
EOF


# Make the backup script executable (chmod 755 gives the owner read, write, and execute permissions, and others read/execute permissions)
sudo chmod 755 /home/minecraft/backup.sh


# Schedule the backup script to run every 4 hours using crontab
(crontab -l 2>/dev/null; echo "0 */4 * * * /home/minecraft/backup.sh") | crontab -


# Output completion message
echo "Setup complete. The Minecraft server is running and backups are scheduled."
