


# SP for deployment

We need a SP in the customer tenant. 

```powershell
az ad sp create-for-deployment --name GitHubActionApp --role contributor --scopes /subscriptions/{sub-id}/resourceGroups/{myRg} --sdk-auth | Out-File -FilePath ./SP-Deployment.json
```