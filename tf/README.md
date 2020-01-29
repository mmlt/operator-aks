
## Environment variables
subscription_id 

```
terraform init
terraform plan -out=newplayground -var-file sx-playground.tfvars -state ./state/playground.tfstate
terraform apply newplayground
terraform show 
```