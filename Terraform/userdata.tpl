#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Variables (you can replace placeholders with actual values or use environment variables)
ASG_HOOK_NAME="foobar"
ASG_GROUP_NAME="asg"
AWS_REGION="ap-southeast-2"
LOG_FILE="/var/log/cloud-init"
INSTANCE_ID=$(cloud-init query -f "{{ds.meta_data.instance_id}}")

function open_port_80 {
    # Ensure port 80 is open
    log "Configuring firewall to open port 80..."
    
    if command -v ufw >/dev/null 2>&1; then
        # Enable UFW if not already active
        if ! sudo ufw status | grep -q "Status: active"; then
            sudo ufw enable
        fi
        sudo ufw allow 80/tcp
    fi

    # Configure iptables as a fallback
    if ! sudo iptables -C INPUT -p tcp --dport 80 -j ACCEPT >/dev/null 2>&1; then
        sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    fi

    if command -v netfilter-persistent >/dev/null 2>&1; then
        sudo netfilter-persistent save
    fi
}

function log {
    local message="$1"
    echo "$(date +%Y-%m-%d\ %H:%M:%S) $${message}" | tee -a "$LOG_FILE"
}

# Redirect all output to the log file
exec > >(tee -a "$LOG_FILE") 2>&1

function install_packages {
    log "Starting bootstrap process..."
    # Update and install required packages
    sudo apt update
    sudo apt install -y python3 python3-pip python3-virtualenv nginx jq unzip
    log "install packages finshed"
}

function awscli {
    log "installing AWS CLI"
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf awscliv2.zip aws
}

function clone_repo {
    # Clone the Git repository
    log "Cloning Git repository..."
    git clone ${GitRepoURL} || { echo "Git clone failed"; exit 1; }
    cp -r chapter3/* .
    # Remove the cloned repository
    rm -rf chapter3
    cd .
}

function config_nginx {
    # Create an Nginx configuration file
    log "Configuring Nginx..."
    cat << EOF > /etc/nginx/sites-available/fastapi
server {
    listen 80;
    server_name ~.;
    location / {
        proxy_pass http://localhost:8000;
    }
}
EOF

    sudo ln -s /etc/nginx/sites-available/fastapi /etc/nginx/sites-enabled/
    sudo systemctl restart nginx
}

function virtual_env {
    # Set up a virtual environment and install dependencies
    log "Setting up virtual environment..."
    virtualenv .venv
    source .venv/bin/activate
    pip install -r requirements.txt
}

function fastapi {
    # Start the FastAPI application
    log "Starting FastAPI application..."
    python3 -m uvicorn main:app &
}

function lifecycle {
    # Notify ASG that the lifecycle action is complete
    log "Notifying ASG of lifecycle action completion..."
    local ACTION_RESULT
    if [[ "$1" == 0 ]]; then
        ACTION_RESULT="CONTINUE"
        log " Lifecycle action result: CONTINUE"
    else
        ACTION_RESULT="ABANDON"
        log " Lifecycle action result: CONTINUE"
    fi

    aws autoscaling complete-lifecycle-action \
    --lifecycle-hook-name "$ASG_HOOK_NAME" \
    --auto-scaling-group-name "$ASG_GROUP_NAME" \
    --lifecycle-action-result "$ACTION_RESULT" \
    --instance-id "$INSTANCE_ID" \
    --region "$AWS_REGION" || { echo "ASG notification failed"; exit 1; } | tee -a $LOG_FILE

    if [[ $? -ne 0 ]]; then
        log "Failed to complete lifecycle action"
        aws autoscaling describe-lifecycle-hooks \
        --auto-scaling-group-name "$ASG_GROUP_NAME" \
        --region "$AWS_REGION" | tee -a $LOG_FILE
    fi

    sleep 15

    exit "$1"

    log "Bootstrap process completed successfully."
}

function main {
    log "Starting User Data Script"
    open_port_80
    install_packages
    awscli
    clone_repo
    config_nginx
    virtual_env
    fastapi
    lifecycle "$?"
    log "[INFO] User data script completed"
}

main "$@"


# #!/bin/bash
# sudo apt update
# sudo apt install -y python3 python3-pip python3-virtualenv nginx jq

# # Clone the Git repository
# git clone ${GitRepoURL}
# cp -r $(echo "${GitRepoURL}" | sed 's/.*\///' | sed 's/\.git//')/chapter3/code/backend . 
# rm -rf $(echo "${GitRepoURL}" | sed 's/.*\///' | sed 's/\.git//') 
# cd backend

# # Replace the region placeholder in main.py
# # sed -i "s/SELECTED_REGION/$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')/g" main.py

# # Create an Nginx configuration file
# cat << EOF > /etc/nginx/sites-available/fastapi
# server {
#     listen 80;
#     server_name ~.;
#     location / {
#         proxy_pass http://localhost:8000;
#     }
# }
# EOF

# # Configure Nginx
# sudo ln -s /etc/nginx/sites-available/fastapi /etc/nginx/sites-enabled/
# sudo systemctl restart nginx

# # Set up a virtual environment and install dependencies
# virtualenv .venv
# source .venv/bin/activate
# pip install -r requirements.txt

# # Start the FastAPI application
# python3 -m uvicorn main:app &
