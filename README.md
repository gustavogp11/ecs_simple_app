# Example deployment of ECS simple http server using terraform

## Description
Deployment of simple app on AWS using Terraform [(tested with version)](terraform_version.txt)    
The ECS will use mostly default data to create the service (security group `allow_http_80` is created using default vpc + subnets)    

_**WARNING**: this execution will cost you $$ on AWS, please be careful and make sure to execute `terraform destroy` at the end_

## Init
`terraform init`

## Apply
`terraform apply`

### Get URL after applying
```bash 
ECS_CLUSTER=container-dev
ECS_TASK_ARN=$(aws ecs list-tasks --cluster $ECS_CLUSTER --query taskArns[0] --output text)
ECS_ENI=$(aws ecs describe-tasks --tasks $ECS_TASK_ARN --cluster container-dev --query 'tasks[0].attachments[].details[][] | [?name==`networkInterfaceId`][].value | [0]' --output text)
ECS_DNS=$(aws ec2 describe-network-interfaces --network-interface-ids $ECS_ENI --query NetworkInterfaces[0].Association.PublicDnsName --output text)

# HTTP GET to the DNS
curl $ECS_DNS
```

## Plan
`terraform plan`

## Destroy
`terraform destroy`

## Generate terraform_version.txt
`terraform --version > terraform_version.txt`
