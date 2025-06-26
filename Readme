## Comprehensive Deployment Script: `full_devops_deploy_fortest.sh` (with Selective Actions and Smart Project Handling)

This script provides a complete solution for setting up a fresh Ubuntu server and deploying a React project to it. It is designed to be run from your **local machine** and now allows you to selectively install services (Nginx, Node.js, Git, Docker) and choose whether to deploy the React project based on command-line arguments. Crucially, it now intelligently handles your local project: if the project directory already exists, it will perform a `git pull` to update it; otherwise, it will perform a `git clone`.

### Prerequisites

Before running this script, ensure you have the following:

1.  **A Fresh Ubuntu Server**: This script is intended for a newly provisioned Ubuntu server (e.g., an AWS EC2 Ubuntu instance). While it can selectively install services, starting with a clean slate is recommended for the initial setup.
2.  **SSH Access**: You must have SSH access to your Ubuntu server with `sudo` privileges.
3.  **SSH Key Pair**: The `.pem` file (private key) associated with your EC2 instance is essential for secure SSH access. Ensure its permissions are set correctly (`chmod 400 /path/to/your/key.pem`).
4.  **Node.js and npm (Local)**: Your local machine must have Node.js and npm (or yarn) installed to build the React application before deployment.
5.  **Security Group Configuration**: Ensure your EC2 instance's security group allows inbound traffic on ports 80 (HTTP) and 443 (HTTPS, if you plan to configure SSL later) from your IP or `0.0.0.0/0` for public access.

### Script Configuration

Open the `full_devops_deploy_fortest.sh` file in a text editor. You **must** replace the placeholder values for `EC2_USER`, `EC2_HOST`, and `SSH_KEY_PATH` in the "Configuration Variables" section with your specific details. Other variables have been pre-filled with template values.

```bash
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
```

**Explanation of Variables:**

*   **`EC2_USER`**: The username used to log into your Ubuntu EC2 instance via SSH. Common usernames for Ubuntu EC2 are `ubuntu` or `ec2-user`.
*   **`EC2_HOST`**: The public IP address or public DNS name of your EC2 instance. You can find this in your AWS EC2 console.
*   **`SSH_KEY_PATH`**: The full path to your SSH private key (`.pem`) file on your local machine. Ensure this file has the correct permissions (`chmod 400 /path/to/your/ssh/key.pem`).
*   **`GIT_REPO_URL`**: The URL of the sample React project that will be cloned. (Pre-filled)
*   **`LOCAL_PROJECT_NAME`**: The name of the cloned project directory. (Pre-filled)
*   **`LOCAL_PROJECT_PATH`**: A temporary directory on your local machine where the React project will be cloned and built. (Pre-filled)
*   **`REMOTE_DEPLOY_PATH`**: The absolute path on your EC2 server where the built React application will be placed. (Pre-filled with `/var/www/html/test-react-app`)
*   **`NGINX_CONF_NAME`**: The name of the Nginx server block configuration file. (Pre-filled with `test-react-app.conf`)
*   **`DOMAIN_NAME`**: A placeholder domain name. If you have a custom domain, you can change this. If not, the application will be accessible via the EC2 public IP. (Pre-filled with `testphase.com`)

### How to Run the Script (with Selective Actions)

1.  **Save the Script**: Save the provided script content as `full_devops_deploy_fortest.sh` on your local machine.
2.  **Make Executable**: Open your local terminal, navigate to the directory where you saved the script, and make it executable:
    ```bash
    chmod +x full_devops_deploy_fortest.sh
    ```
3.  **Execute with Arguments**: Now, you can run the script with specific arguments to control its behavior. You can combine arguments as needed.

    **Available Arguments:**
    *   `nginx`: Installs Nginx on the remote server.
    *   `node`: Installs Node.js and npm (via NVM) on the remote server.
    *   `git`: Installs Git on the remote server.
    *   `docker`: Installs Docker on the remote server.
    *   `deploy`: Builds the local React project, transfers it to the remote server, and configures Nginx for deployment.
    *   `all`: Installs all services (Nginx, Node.js, Git, Docker) and deploys the project. This is the default behavior if no arguments are provided.

    **Examples:**

    *   **Install all services and deploy the project (default behavior):**
        ```bash
        ./full_devops_deploy_fortest.sh all
        # or simply
        ./full_devops_deploy_fortest.sh
        ```

    *   **Only install Nginx and deploy the project:**
        ```bash
        ./full_devops_deploy_fortest.sh nginx deploy
        ```

    *   **Only install Docker:**
        ```bash
        ./full_devops_deploy_fortest.sh docker
        ```

    *   **Only deploy the project (assuming services are already installed):**
        ```bash
        ./full_devops_deploy_fortest.sh deploy
        ```

    *   **Install Node.js and Git:**
        ```bash
        ./full_devops_deploy_fortest.sh node git
        ```

### How the Script Works

When you run `full_devops_deploy_fortest.sh` from your local machine, it performs the following sequence of operations:

1.  **Argument Parsing**: The script first parses the command-line arguments to determine which actions to perform.
2.  **Local React Project Handling (if `deploy` is requested)**: If `deploy` is specified:
    *   It checks if the `LOCAL_PROJECT_PATH` directory already exists.
    *   If it exists, it navigates into the directory and performs a `git pull` to update the project.
    *   If it does not exist, it performs a `git clone` of the `GIT_REPO_URL` into the `LOCAL_PROJECT_PATH`.
    *   After cloning/pulling, it runs `npm install` and `npm run build` to create the production-ready build files.
3.  **Remote Server Setup (via SSH)**: The script then establishes an SSH connection to your EC2 instance and executes a series of commands on the remote server based on the arguments provided:
    *   **System Update & Upgrade**: Always performs `sudo apt update -y && sudo apt upgrade -y`.
    *   **UFW Configuration**: Installs UFW (if not present), enables it, allows SSH, and opens ports for Nginx (HTTP and HTTPS) if Nginx is to be installed.
    *   **Selective Service Installation**: Installs Nginx, Node.js (via NVM), Git, and/or Docker only if their respective arguments are provided.
    *   **Deployment Commands (if `deploy` is requested)**: If `deploy` is specified, it creates the deployment directory, configures Nginx (if Nginx is installed on the server), and sets up the web server to serve your React application.
4.  **File Transfer (if `deploy` is requested)**: After the remote server setup and configuration are complete, if `deploy` is specified, the script uses `scp` to securely transfer the `build` directory from your local machine to the `REMOTE_DEPLOY_PATH` on your EC2 instance.
5.  **Local Cleanup (if `deploy` is requested)**: Removes the temporary local project directory.

### Important Notes & Troubleshooting

*   **First Run**: The first time you run this script on a new server with `all` or specific installation arguments, it will take a significant amount of time as it installs all the necessary software. Subsequent runs (e.g., just `deploy`) will be faster.
*   **SSH Key Permissions**: If you encounter `Permissions denied (publickey)` errors, ensure your `.pem` file has `chmod 400` permissions (`chmod 400 /path/to/your/key.pem`).
*   **Nginx Errors**: If Nginx fails to restart, check the error messages in the terminal. You can also SSH into your EC2 instance and check Nginx logs: `sudo tail -f /var/log/nginx/error.log`.
*   **Firewall/Security Group**: If you can't access your application in the browser, double-check your EC2 instance's security group to ensure ports 80 and 443 are open.
*   **Docker Group Membership**: After the script completes, you might need to log out of your SSH session on the EC2 instance and log back in for the `docker` group changes to take effect. This allows you to run `docker` commands without `sudo`.
*   **Error Handling**: The script includes basic error handling (`|| { echo "Error..."; exit 1; }`). If any command fails, the script will exit and print an error message.

This script provides a robust and automated way to provision your server and deploy your React application, minimizing manual intervention and offering flexibility in installation.

