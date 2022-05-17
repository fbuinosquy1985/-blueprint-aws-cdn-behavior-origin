# blueprint-aws-cdn-behavior-origin

Shell script to add a origin and a behavior & terraform code  , that executes the update script to modify a cloudfront distribution.

## How to use the script from terraform ?

    Example:

    Edit the variables.tf file then run

    terraform init
    terraform plan
    terraform apply

## How to use the script from a console ?

    Example:

    ./update_cdn.sh E3554BHOW3RXY2 aac5e1e3235cc4c028de730c26369163-d8052e4acdbbae74.elb.us-east-1.amazonaws.com crm-fe-prod

    Where the fields mean.

    ./update_cdn.sh CLOUDFRONT_ID LOAD_BALANCER_URL CLOUDFRONT_BEHAVIOR_PATH
