#!/bin/bash
# Lab Setup Script
wget https://raw.githubusercontent.com/dw-bg/work-experience-2022/main/01-iac/main.tf
wget https://raw.githubusercontent.com/dw-bg/work-experience-2022/main/01-iac/my-variables.tfvars
mkdir terraform
mv main.tf terraform/
mv my-variables.tfvars terraform/
rm -rf lab_1_setup.sh
