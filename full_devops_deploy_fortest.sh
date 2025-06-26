#!/bin/bash

# This script automates the complete setup of a fresh Ubuntu server and
# deploys a React project to it, all from your local machine.
# It now supports selective installation of services and deployment based on arguments.

# --- Configuration Variables (REPLACE THESE) ---

# EC2 Server Details
EC2_USER="your_ssh_username" # e.g., ubuntu, ec2-user
EC2_HOST="your_ec2_ip_or_hostname" # e.g., 12.34.56.78 or ec2-xx-xx-xx-xx.compute-1.amazonaws.com
SSH_KEY_PATH="/path/to/your/ssh/key.pem" # e.g., ~/.ssh/my-ec2-key.pem (YOU MUST PROVIDE THIS)

# Local React Project Details (Sample Project from GitHub)
GIT_REPO_URL="https://github.com/aditya-sridhar/simple-reactjs-app.git"
LOCAL_PROJECT_NAME="simple-reactjs-app"
LOCAL_PROJECT_PATH="/tmp/${LOCAL_PROJECT_NAME}" # Temporary directory for cloning and building

# Remote Server Deployment Details
REMOTE_DEPLOY_PATH="/var/www/html/test-react-app" # Example: /var/www/html/test-react-app
NGINX_CONF_NAME="test-react-app.conf" # Example: test-react-app.conf
DOMAIN_NAME="testphase.com" # Example: testphase.com. Leave empty if not using a domain.

# --- Script Logic ---

# Flags for actions
INSTALL_NGINX=false
INSTALL_NODE=false
INSTALL_GIT=false
INSTALL_DOCKER=false
DO_DEPLOY=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        nginx) INSTALL_NGINX=true; shift ;;
        node) INSTALL_NODE=true; shift ;;
        git) INSTALL_GIT=true; shift ;;
        docker) INSTALL_DOCKER=true; shift ;;
        deploy) DO_DEPLOY=true; shift ;;
        all) 
            INSTALL_NGINX=true
            INSTALL_NODE=true
            INSTALL_GIT=true
            INSTALL_DOCKER=true
            DO_DEPLOY=true
            shift
            ;;
        *) 
            echo "Usage: $0 [nginx] [node] [git] [docker] [deploy] [all]"
            echo "Example: $0 nginx deploy (Installs Nginx and deploys the project)"
            echo "Example: $0 all (Installs all services and deploys the project)"
            exit 1
            ;;
    esac
done

# If no arguments are provided, default to 'all'
if [ "$#" -eq 0 ] && [ "$INSTALL_NGINX" = false ] && [ "$INSTALL_NODE" = false ] && [ "$INSTALL_GIT" = false ] && [ "$INSTALL_DOCKER" = false ] && [ "$DO_DEPLOY" = false ]; then
    INSTALL_NGINX=true
    INSTALL_NODE=true
    INSTALL_GIT=true
    INSTALL_DOCKER=true
    DO_DEPLOY=true
fi


echo "Starting comprehensive server setup and React project deployment..."

# 1. Clone or Pull the React project locally (only if deployment is requested)
if [ "$DO_DEPLOY" = true ]; then
    if [ -d "$LOCAL_PROJECT_PATH" ]; then
        echo "Local project directory exists. Performing git pull..."
        cd "$LOCAL_PROJECT_PATH" || { echo "Error: Could not change to local project directory."; exit 1; }
        git pull || { echo "Error: Git pull failed."; exit 1; }
    else
        echo "Local project directory not found. Cloning React project from GitHub..."
        git clone "$GIT_REPO_URL" "$LOCAL_PROJECT_PATH" || { echo "Error: Git clone failed."; exit 1; }
        cd "$LOCAL_PROJECT_PATH" || { echo "Error: Could not change to cloned project directory."; exit 1; }
    fi

    # 2. Build the React project locally
    echo "Building React project locally..."
    npm install || { echo "Error: npm install failed during local build."; exit 1; }
    npm run build || { echo "Error: npm run build failed during local build."; exit 1; }

    echo "React project built successfully locally."
fi

# 3. Connect to EC2 and perform server setup and deployment
echo "Connecting to EC2 instance to perform setup and deployment..."
ssh -i "$SSH_KEY_PATH" "$EC2_USER@$EC2_HOST" << EOF

    # --- Server Setup Commands ---
    echo "[REMOTE] Updating and upgrading system packages..."
    sudo apt update -y
    sudo apt upgrade -y

    # Install UFW if not present and enable it
    echo "[REMOTE] Installing and configuring UFW..."
    sudo apt install -y ufw
    sudo ufw enable
    sudo ufw allow OpenSSH # Allow SSH by default
    sudo ufw reload
    echo "[REMOTE] UFW configured."

    if [ "$INSTALL_NGINX" = true ]; then
        echo "[REMOTE] Installing Nginx..."
        sudo apt install -y nginx
        sudo ufw allow 'Nginx HTTP' # Allow Nginx through firewall
        sudo ufw allow 'Nginx HTTPS' # Allow Nginx HTTPS through firewall
        sudo systemctl enable nginx
        sudo systemctl start nginx
        echo "[REMOTE] Nginx installed and started."
    fi

    if [ "$INSTALL_NODE" = true ]; then
        echo "[REMOTE] Installing Node.js and npm using NVM..."
        # Install nvm (Node Version Manager)
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash

        # Load nvm into the current session for subsequent commands
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

        # Install the latest LTS version of Node.js
        nvm install --lts
        nvm use --lts

        # Verify Node.js and npm installation
        node -v
        npm -v
        echo "[REMOTE] Node.js and npm installed."
    fi

    if [ "$INSTALL_GIT" = true ]; then
        echo "[REMOTE] Installing Git..."
        sudo apt install -y git
        git --version
        echo "[REMOTE] Git installed."
    fi

    if [ "$INSTALL_DOCKER" = true ]; then
        echo "[REMOTE] Installing Docker..."
        # Add Docker\'s official GPG key:
        sudo apt update -y
        sudo apt install -y ca-certificates curl gnupg
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg

        # Add the repository to Apt sources:
        echo \
          "deb [arch=\"$(dpkg --print-architecture)\" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          \"$(. /etc/os-release && echo "$VERSION_CODENAME")\" stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt update -y

        # Install Docker packages
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        # Add current user to the docker group to run docker commands without sudo
        sudo usermod -aG docker $USER
        echo "[REMOTE] Docker installed. You may need to log out and log back in for Docker group changes to take effect."
    fi

    echo "[REMOTE] Server setup complete!"

    # --- Deployment Commands (only if deployment is requested) ---
    if [ "$DO_DEPLOY" = true ]; then
        # Create deployment directory if it doesn\'t exist and set permissions
        sudo mkdir -p "$REMOTE_DEPLOY_PATH"
        sudo chown -R "$EC2_USER":"$EC2_USER" "$REMOTE_DEPLOY_PATH"

        # Configure Nginx (only if Nginx is installed or already present)
        if command -v nginx &> /dev/null; then
            echo "[REMOTE] Configuring Nginx..."
            NGINX_CONFIG="/etc/nginx/sites-available/$NGINX_CONF_NAME"
            
            # Remove existing config if it exists
            if [ -f "$NGINX_CONFIG" ]; then
                sudo rm "$NGINX_CONFIG"
            fi

            # Create new Nginx config. Using \'EOL\' to prevent local shell variable expansion.
            sudo tee "$NGINX_CONFIG" > /dev/null << EOL
server {
    listen 80;
    listen [::]:80;

    root $REMOTE_DEPLOY_PATH/build;
    index index.html index.htm;

    server_name $DOMAIN_NAME;

    location / {
        try_files \$uri \$uri/ =404;
    }

    error_page 404 /index.html;
    location = /index.html {
        internal;
    }
}
EOL

            # Enable the Nginx site and remove default config
            sudo ln -sf "$NGINX_CONFIG" /etc/nginx/sites-enabled/
            if [ -f /etc/nginx/sites-enabled/default ]; then
                sudo rm /etc/nginx/sites-enabled/default
            fi

            # Test Nginx configuration and restart
            echo "[REMOTE] Testing Nginx configuration and restarting..."
            sudo nginx -t && sudo systemctl restart nginx
            if [ $? -eq 0 ]; then
                echo "[REMOTE] Nginx configured and restarted successfully."
            else
                echo "[REMOTE] Error: Nginx configuration test failed or restart failed. Check logs."
            fi
        else
            echo "[REMOTE] Nginx not found. Skipping Nginx configuration for deployment."
        fi

        echo "[REMOTE] Deployment to EC2 complete."
    fi
EOF

# 4. Transfer build files to the EC2 instance (only if deployment is requested)
if [ "$DO_DEPLOY" = true ]; then
    echo "Transferring build files to EC2 instance..."
    scp -i "$SSH_KEY_PATH" -r "$LOCAL_PROJECT_PATH/build" "$EC2_USER@$EC2_HOST:$REMOTE_DEPLOY_PATH" || { echo "Error: File transfer failed."; exit 1; }

    # Clean up temporary project directory
    echo "Cleaning up temporary local project directory: $LOCAL_PROJECT_PATH"
    rm -rf "$LOCAL_PROJECT_PATH"
fi

echo "Comprehensive setup and deployment script finished."


