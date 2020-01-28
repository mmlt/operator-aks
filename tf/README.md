
## Environment variables
subscription_id 

```
terraform init
terraform plan -out=newplan -var-file sx-playground.tfvars -state ./state/playground.tfstate
terraform apply newplan
terraform show 
```