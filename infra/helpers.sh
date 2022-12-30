#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

# Update the path to your ssh private key here
ssh_private_key=$(pwd)"/keys/demo-key"

# Parameters
ACTION="$1"

deploy() {
    # Create VM
    echo "Deploy by Terraform..."
    terraform init
    terraform apply -var-file main.tfvars -auto-approve
    # Sleep 1 minutes to ensure VM is ready
    echo "Wait for VM to be ready..."
    sleep 60
    terraform refresh -var-file main.tfvars
    vm_public_ip=$(terraform output vm_public_ip)
    vm_public_ip="${vm_public_ip%\"}"
    vm_public_ip="${vm_public_ip#\"}"
    echo "VM Public IP is ${vm_public_ip}"
    echo "Copy source code to VM..."
    scp -o StrictHostKeyChecking=no -i $ssh_private_key ../app.py ubuntu@$vm_public_ip:/home/ubuntu/app.py
    scp -o StrictHostKeyChecking=no -i $ssh_private_key -r ../frontend ubuntu@$vm_public_ip:/home/ubuntu/frontend
    # Installing driver in VM
    echo "Installing driver..."
    cd startup
    rm -rf terraform*
    terraform init
    terraform apply -var="vm_public_ip=$vm_public_ip" -var="ssh_privkey_location=$ssh_private_key" -auto-approve
    ssh -i $ssh_private_key ubuntu@$vm_public_ip 'sudo reboot' || true
    echo "Wait for VM to be ready..."
    sleep 30
    echo "Access this URL to try ===>  http://${vm_public_ip}:5000"
    ssh -i $ssh_private_key ubuntu@$vm_public_ip 'flask --app app run --host 0.0.0.0'
}

connect() {
    # Get VM public ip
    vm_public_ip=$(terraform output vm_public_ip)
    vm_public_ip="${vm_public_ip%\"}"
    vm_public_ip="${vm_public_ip#\"}"
    # SSH to VM by public ip
    ssh -i $ssh_private_key ubuntu@$vm_public_ip
}

destroy() {
    terraform destroy -var-file main.tfvars -auto-approve
}

main() {
    case "$ACTION" in
    deploy)
        deploy
        ;;
    connect)
        connect
        ;;
    destroy)
        destroy
        ;;

    *)
        echo $"Usage: $0 {deploy|destroy|connect}"
        exit 1
        ;;
    esac
}

# Start main function
main
