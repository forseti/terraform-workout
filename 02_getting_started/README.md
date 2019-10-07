### 02_getting_started ###
Set the environment variables:
```console
export AWS_ACCESS_KEY_ID=<YOUR_ACCESS_KEY_ID>
export AWS_SECRET_ACCESS_KEY=<YOUR_SECRET_ACCESS_KEY>
```

#### Initialize a Terraform project ####
```console
terraform init
```

```console
terraform init <DIR_OR_PLAN>
```

Example:
```console
terraform init v01_initial
```

#### Run the plan (preview) ####
```console
terraform plan
```

```console
terraform plan <DIR_OR_PLAN>
```

Example:
```console
terraform plan v01_initial
```

#### Apply the changes ####
```console
terraform apply
```

```console
terraform apply <DIR_OR_PLAN>
```

Example:
```console
terraform apply v01_initial
```

#### To display the graph (*DOT* format) ####
```console
terraform graph
```

```console
terraform graph <DIR_OR_PLAN>
```

Example:
```console
terraform graph v03_deploy_web_server
```

An output's example:
```console
digraph {
        compound = "true"
        newrank = "true"
        subgraph "root" {
                "[root] aws_instance.example-instance" [label = "aws_instance.example-instance", shape = "box"]
                "[root] aws_security_group.example-sg" [label = "aws_security_group.example-sg", shape = "box"]
                "[root] provider.aws" [label = "provider.aws", shape = "diamond"]
                "[root] aws_instance.example-instance" -> "[root] aws_security_group.example-sg"
                "[root] aws_security_group.example-sg" -> "[root] provider.aws"
                "[root] meta.count-boundary (EachMode fixup)" -> "[root] aws_instance.example-instance"
                "[root] provider.aws (close)" -> "[root] aws_instance.example-instance"
                "[root] root" -> "[root] meta.count-boundary (EachMode fixup)"
                "[root] root" -> "[root] provider.aws (close)"
        }
}
```

The `digraph` value can be visualized in an online tool like [GraphvizOnline](http://dreampuf.github.io/GraphvizOnline/)


#### Provide an input variable using `-var` ####
```console
terraform plan -var "<VARIABLE_NAME>=<VALUE>"
```

```console
terraform plan <DIR_OR_PLAN> -var "<VARIABLE_NAME>=<VALUE>"
```

Example:
```
terraform plan 05_deploy_configurable_web_server -var "server_port=8080"
```

#### Provide an input variable using environment variables (`TF_VAR_*`) ####
```console
export TF_VAR_<VARIABLE_NAME>=<VALUE>
```

Then run a command:
```console
terraform plan
```

Or run a command with a location:

```console
terraform plan <DIR_OR_PLAN>
```

Example:
```console
export TF_VAR_server_port=8080
```

```console
terraform plan 05_deploy_configurable_web_server
```

#### Display an output variable ####
You must run `terraform apply` first before running any of the following commands:

```console
terraform output
```

```console
terraform output <OUTPUT_NAME>
```

Example:
```console
terraform apply v06_add_output
```

```console
terraform output public_ip
```