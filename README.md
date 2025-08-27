# Introduction
This repository serves as the foundation/the glue for out deployments. It is supposed to be the central repository for managing content delivery, scripts and more for our customers. It contains the centralized content that will be deployed to all customers, and it has logic that will enhance each step of the process of deployment. This repository is cloned into each deployment workflow from the customer specific template based repository and the code is being run in the customer context. 

# Prerequisites (Most of which could be handled by `mdr_)
- Azure Sentinel in a workspace
- Resource groups: 
  - Monitoring group
  - Automation group
- 

# Naming conventions

# Consulent work
## High overview
- Run deployment Powershell script to deploy with customer:
Enter the step to start with:
  - Add and register resource providers
  - Create Monitor and Automation Resource Groups
  - Deploy Lighthouse Template
  - Create Entra ID Groups and Assign Azure RBAC Roles
  - Invite External Users and Add Them to Groups
  - Configure Defender XDR and Custom Role Assignments
  - Provision Teams (Team and Channels)
  - Deploy Sentinel
  - Set Resource Locks and Final Cleanup
  - Create Entra Groups for the customer
- Start delivering content on CI/CD:
  - Runs on a per needed basis.

## Deploy rules and rule updates workflow
- Create a new repository based on cust_template
- Add the needed parameters into deployment_config.yml
- Run the CI/CD for the deploy content (rules, playbooks, workbooks etc)

# Very High level overview for deployment
During customer meeting:
- Fill out the parameters YAML file and talk the customer through the setup. 
- Run the deployment powershell script
- Pause the script when Sentinel Deployment is ready to be run. Use the time to discuss the content and educate the user on 


# Notes
- Please ask customer to get some hold on information for departing employees and new employees. This is needed to monitor behavior that might change in given circumstances.