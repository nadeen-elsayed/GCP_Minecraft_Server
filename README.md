# Google Cloud Minecraft Server

This script allows you to create a free Minecraft server using Google Cloud Platform. The provided script automates the creation and configuration of a VM instance, sets up the Minecraft server, and schedules regular backups. You can modify the VM details, such as machine type and disk size, to suit your specific needs.

## Features

- **Automated VM Creation:** Sets up a new VM instance in GCP with specified configurations, including machine type, disk size, and network settings.
- **Firewall Rules:** Configures firewall rules to allow incoming traffic on port 25565, which is required for Minecraft server communication.
- **Disk Formatting and Mounting:** Formats and mounts a disk to the `/home/minecraft` directory for storing Minecraft data.
- **Java Installation:** Installs the default Java Runtime Environment (headless version) required to run the Minecraft server.
- **Minecraft Server Setup:** Downloads and starts the Minecraft server (version 1.11.2) with initial memory allocation settings.
- **Server Management:** Runs the Minecraft server in a detached screen session to allow it to operate in the background.
- **Automated Backups:** Creates and schedules a backup script to save the Minecraft world data to Google Cloud Storage every 4 hours.
- **Environment Variable:** Uses an environment variable for the Google Cloud Storage bucket name to manage backups.

## How to Use

1. **Prepare the Script:**
   - Replace Windows line endings (if applicable):
     ```bash
     sed -i 's/\r$//' setup.sh
     ```
   - Make the script executable:
     ```bash
     chmod +x setup.sh
     ```

2. **Execute the Script:**
   - Run the setup:
     ```bash
     ./setup.sh
     ```

3. **Update Reserved IP:**
   - Get the IP address:
     ```bash
     gcloud compute addresses describe mc-server-ip --region=us-central1 --format="get(address)"
     ```
   - Replace `[YOUR_RESERVED_IP]` in the script and update the network interface.

4. **Verify Setup:**
   - SSH into your VM and check the Minecraft server status.

5. **Manage Backups:**
   - Ensure the backup script is scheduled:
     ```bash
     crontab -l
     ```

6. **Check Server Status:**
   - Visit [MCSrvStat](https://mcsrvstat.us/server/) and use your external IP to ensure your Minecraft server is up and running.
