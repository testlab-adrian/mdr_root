

# Very High level overview for deployment
During customer meeting:
- Fill out the parameters YAML file and talk the customer through the setup. 
- Run the deployment powershell script
- Pause the script when Sentinel Deployment is ready to be run. Use the time to discuss the content and educate the user on 

# SP for deployment

We need a SP in the customer tenant. 

```powershell
az ad sp create-for-deployment --name GitHubActionApp --role contributor --scopes /subscriptions/{sub-id}/resourceGroups/{myRg} --sdk-auth | Out-File -FilePath ./SP-Deployment.json
```