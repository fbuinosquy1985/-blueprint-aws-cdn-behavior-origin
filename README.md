# blueprint-aws-cdn-behavior-origin

Shell script glue with Terraform to add a origin and a behavior & terraform code to a existing Cloudfront Distribution  , and when destroy is executed it removes the origin and behavior.


Check the aws path that is set on the script ( is hardcoded )


## How to use the script from terraform ?

    Example:

    Edit the variables.tf file then run

    terraform init
    terraform plan
    terraform apply

## How to use the add script from a console ?

    Example:

    ./update_cdn.sh E3554BHOW3RXY2 aac5e1e3235cc4c028de730c26369163-d8052e4acdbbae74.elb.us-east-1.amazonaws.com crm-fe-prod

    Where the fields mean.

    ./update_cdn.sh CLOUDFRONT_ID LOAD_BALANCER_URL CLOUDFRONT_BEHAVIOR_PATH
    

## How to use the remove script from a console ?

    Example:

    ./remove_cdn.sh E3554BHOW3RXY2 crm-fe-prod

    Where the fields mean.

    ./remove_cdn.sh CLOUDFRONT_ID CLOUDFRONT_BEHAVIOR_PATH
