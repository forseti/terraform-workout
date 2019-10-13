#### v05_file_layout ####

We can divide our environments into their own respective folders, for example:

| Environment | Description |
|---|---|
| stage | Environment for staging/pre-production |
| prod | Environment for production |
| mgmt | Environment for DevOps tooling (e.g. jumpbox, Jenkins) |
| global | A place to put resources that are used across all environments (e.g. S3, IAM) |

Within this environment, we can have separate folders for each components. As an example, under `stage`,
we can have several folders for components:

| Component | Description |
|---|---|
| vpc | The network topology for this environment |
| services | The apps or microservices to run in this environment |
| datastores | The datastores for this environment (e.g. MySQL, Redis) |

Under each component, we can have several terraform files:

| Terraform Config | Description |
|---|---|
| main.tf | The main resources |
| variables.tf | Input variables |
| outputs.tf | Output variables |

There are few problems with these modular approach:
* We need to call `terraform apply` under each folder. The `terragrunt` command can solve this issue.
* We cannot reference attributes of a `resource` in other folders. It can be achieved using `terraform_remote_state`

##### S3/DynamoDB Terraform states (and locks) #####
Move and refactor our configuration from `v01_create_datastore_for_tfstate` to `global/s3` folder.

###### main.tf ######
```hcl
provider "aws" {
  region = "us-east-2"
}

resource "aws_s3_bucket" "tf_state" {
  bucket = "tf-up-and-running-state-20191009"

  # Prevent accidental deletion of this S3 bucket
  lifecycle {
    prevent_destroy = true
  }

  # Enable versioning so we can see the full revision history of our state files
  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "tf_locks" {
  name = "tf-up-and-running-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

###### outputs.tf ######
```hcl
output "s3_bucket_arn" {
  value = aws_s3_bucket.tf_state.arn
  description = "The ARN of the S3 bucket"
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.tf_locks.name
  description = "The name of the DynamoDB table"
}
```

##### Datastores (MySQL) #####
Next is to create MySQL's datastore under `stage/datastores/mysql`:

###### main.tf ######
```hcl
provider "aws" {
  region = "us-east-2"
}

resource "aws_db_instance" "example" {
  identifier_prefix = "terraform-up-and-running"
  engine = "mysql"
  allocated_storage = 10
  instance_class = "db.t2.micro"
  name = "example_db"
  username = "admin"

  # This is only for development
  skip_final_snapshot = true

  password = ???
}
```

There is one problem here. For security reasons, we do not want to hardcode `password` which is the master password to our database. One way to solve this issue is to read our secret from a secret store. There are few options available:

| Secret Store | Terraform Data Mapping |
|---|---|
| AWS Secrets Manager | aws_secretsmanager_secret_version |
| AWS System Manager Parameter | aws_ssm_parameter |
| AWS Key Management Service (AWS KMS) | aws_kms_secrets |
| Google Cloud KMS | google_kms_secret |
| Azure Key Vault | azurerm_key_vault_secret |
| HashiCorp Vault | vault_generic_secret |

Another way to provide password securely is by managing our secrets outside Terraform and pass them into Terraform via environment variable `TF_VAR_*`. To do that, we need to declare an input `variable` in `stage/datastores/mysql/variables.tf`:

```hcl
variable "db_password" {
  description = "The password for the database"
  type = string
}
```

Then we can pass it through `TF_VAR_db_password`:
```console
export TF_VAR_db_password=<YOUR_DB_PASSWORD>
```

Alternatively, we can also use [`pass`](https://www.passwordstore.org/), so that our secrets will not be stored accidentally in Bash `history`:
```console
export TF_VAR_db_password=$(pass database-password)
```

And finally run `terraform apply`

No matter which options we pick, our secrets will always be stored in our Terraform states, so keep that in mind (e.g. You can enable S3 encryption or use IAM permission to lock down access to your S3 bucket).

Add the terraform state to MySQL's `main.tf`:
```hcl
terraform {
  backend "s3" {
    bucket = "tf-up-and-running-state-20191009"
    key = "stage/datastores/mysql/terraform.tfstate"
    region = "us-east-2"

    dynamodb_table = "tf-up-and-running-locks"
    encrypt = true
  }
}
```

Run `terraform init` and `terraform apply` to create the backend store.

##### Services (Web Cluster) #####
Move and refactor our web cluster code from `02_getting_started/v07_load_balancer` to `stage/services/web-cluster` folder, just like what we did with S3/DynamoDB changes earlier (e.g. refactor all `output` and `variable` into `outputs.tf` and `variables.tf` respectively)

Next is to make our web cluster code to read the data from the MySQL's state file using `terraform_remote_state`. Add the following section to `stage/services/web-cluster/main.tf`

```hcl
data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = "tf-up-and-running-state-20191009"
    key = "stage/datastores/mysql/terraform.tfstate"
    region = "us-east-2"
  }
}
```

With this change, we can use the following expression:
```hcl
data.terraform_remote_state.<NAME>.outputs.<ATTRIBUTE>
```

For example to display the address and port of MySQL in our web page (configured under `aws_launch_configuration`):
```hcl
 user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              echo "${data.terraform_remote_state.db.output.address}" > index.html
              echo "${data.terraform_remote_state.db.output.port}" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF
```

As you can see, with this approach, our `user-data` script is growing longer, and adding more lines is going to make it messier. To solve this issue, we can externalize our Bash script with `file` function and `template_file` data source.

To execute built-in functions, we can use the following expression:
```hcl
function_name(...)
```

We can use `terraform console` to test these functions.

For example, with the `format` function:
```hcl
format(<FMT>, <ARGS>, ...)
```

And the following input:
```hcl
format("%.3f", 3.14159265359)
```

We will get this output:
```console
3.142
```

To externalize our Bash script, we are going to use `file` function:
```hcl
file(<PATH>)
```

Usage example:
```hcl
file("user-data.sh")
```

We also need to pass the values like `address` and `port` from MySQL's state file and `server_port` input variable into this script. To achieve this, we need to use `template_file` data source:
```hcl
data "template_file" "user_data" {
  template = file("user-data.sh")

  vars = {
    server_port = var.server_port
    db_address = data.terraform_remote_state.db.outputs.address
    db_port = data.terraform_remote_state.db.outputs.port
  }
}
```

Inside our `user-data.sh`:
```bash
#!/bin/bash
              
cat > index.html <<EOF
  <h1>Hello, World</h1>
  <p>DB address: ${db_address}</p>
  <p>DB port: ${db_port}</p>
EOF

nohup busybox httpd -f -p ${server_port} &
```

Finally, we need to update `user_data` parameter in our `aws_launch_configuration`:
```hcl
resource "aws_launch_configuration" "example" {
  image_id = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.inst.id]
  user_data = data.template_file.user_data.rendered
  
  # Required when using a launch configuration with an auto scaling group.
  # https://www.terraform.io/docs/providers/aws/r/launch_configuration.html
  lifecycle { 
    create_before_destroy = true 
  }
}
```

Then run `terraform init` and `terraform apply`.